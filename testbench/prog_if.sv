`timescale 1ns/1ps
`include "nibble_cpu_tb_pkg.sv"


interface prog_if(input logic clk);
    import nibble_cpu_tb_pkg::*;

    logic rst_n;
    logic [3:0] prog_nibble_in;
    logic prog_nibble_in_valid;
    logic [3:0] prog_nibble_out;
    logic prog_out_valid;
    logic prog_done;
    
    initial begin
        rst_n = 1'b1;
        prog_nibble_in = 4'h0;
        prog_nibble_in_valid = 1'b0;
    end

    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        output rst_n, prog_nibble_in, prog_nibble_in_valid;
        input  prog_nibble_out, prog_out_valid, prog_done;
    endclocking

    modport dut (
        input rst_n, prog_nibble_in, prog_nibble_in_valid,
        output prog_nibble_out, prog_out_valid, prog_done
    );

    task automatic apply_reset();
        cb.rst_n <= 0;
        cb.prog_nibble_in <= 0;
        cb.prog_nibble_in_valid <= 0;
        repeat (5) @(cb);
        cb.rst_n <= 1;
        @(cb);
    endtask
	
	task automatic cpu_operation(input frame_t f,output logic [31:0] r[$]);
		frame_c frame;
		logic [31:0] temp;
		//$display("CPU operation Start %s",f.opcode.name());
		
		case(f.opcode)
			OP_ADD, 
			OP_SUB,
			OP_MUL,
			OP_DIV,
			OP_AND,
			OP_OR,
			OP_XOR:
			begin
				frame.addr = f.addr; frame.opcode = OP_WRITE; frame.data = f.op1;
				send_frame(frame);
				//$display("First frame sent");
				frame.addr = f.addr+1; frame.opcode = OP_WRITE; frame.data = f.op2;
				send_frame(frame);
				//$display("Second frame sent");
				frame.addr = f.addr; frame.opcode = f.opcode; frame.data = 0;
				send_frame(frame);
				//$display("Third frame sent %d",f.addr+2);
				if(f.addr!=4095)
					read_data(f.addr+2,temp);
				else begin
					temp = 32'dx;
					@(negedge cb.prog_done);
					$display("Prog done falls");
				end
				//$display("Read data done");
			end
			
			OP_INV: begin
				frame.addr = f.addr; frame.opcode = OP_WRITE; frame.data = f.op1;
				send_frame(frame);
				frame.addr = f.addr; frame.opcode = f.opcode; frame.data = 0;
				send_frame(frame);
				read_data(f.addr+1,temp);
			end
			
			OP_FILL1,
			OP_FILL0: begin
			    frame.addr = f.addr; frame.opcode = f.opcode; frame.data = 0;
			    send_frame(frame);
			    read_data(f.addr,temp);
			end
			
			OP_WRITE: begin
			    frame.addr = f.addr; frame.opcode = OP_WRITE; frame.data = f.op1;
			    send_frame(frame);
			    read_data(f.addr,temp);
			end 
			
			OP_READ: begin
			    frame.addr = f.addr; frame.opcode = OP_WRITE; frame.data = f.op1;
			    send_frame(frame);
			    read_data(f.addr,temp);
			end
			
			OP_WRITE_INC: begin
			    frame.addr = f.addr; frame.opcode = f.opcode; frame.data = f.op1;
			    send_frame(frame);
			    read_data(f.addr,temp);
			end 
			
			OP_READ_SEQ: begin
			    frame.addr = f.addr; frame.opcode = OP_FILL1; frame.data = 0;
			    send_frame(frame);
				frame.addr = f.addr; frame.opcode = OP_READ_SEQ; frame.data = 0;
				send_frame(frame);
			    read_data($urandom_range(4095,f.addr),temp);
			end
			
			OP_INC_ACC: begin
			    frame.addr = f.addr; frame.opcode = OP_WRITE; frame.data = f.op1;
			    send_frame(frame);
			    frame.addr = f.addr; frame.opcode = f.opcode; frame.data = 0;
			    send_frame(frame);
			    read_data(f.addr,temp);
			end
		endcase
		
		r.push_back(temp);
	
	endtask

    task automatic send_nibble(input logic [3:0] nibble);
        cb.prog_nibble_in <= nibble;
        @(cb); 
    endtask

    task automatic send_frame(input frame_c framee);
        logic [51:0] frame_bits;
        frame_bits = {framee.data, framee.opcode, framee.addr};
        cb.prog_nibble_in_valid <= 1;

        for(int i=0; i<13; i=i+1) begin
            send_nibble(frame_bits[3:0]);
            frame_bits = frame_bits >> 4;
        end
		
        cb.prog_nibble_in_valid <= 0;
        wait(cb.prog_done === 1'b1);
		//@(posedge cb.prog_done);
		//$display("Prog done rose");
        @(cb);
    endtask

    task automatic wait_for_output(output logic [31:0] received_data);
        received_data = 32'd0;
		//$display("WFO start");
		
        //wait(cb.prog_out_valid === 1'b1);
		@(posedge cb.prog_out_valid);
		//$display("Prog out valid seen");
        for (int i = 0; i < 8; i = i + 1) begin         
            received_data = {cb.prog_nibble_out, received_data[31:4]};
            @(cb);
        end
		
		
    endtask
    
    task automatic read_data(input logic [11:0] addr, output logic [31:0] data_out);
        frame_c frame;
        frame.addr = addr;
        frame.opcode = OP_READ;
        frame.data = 0;
		//$display("Read Data Start %d",frame.addr);
        fork
            send_frame(frame);
            wait_for_output(data_out);
        join
		//$display("Read Data End");
    endtask

endinterface