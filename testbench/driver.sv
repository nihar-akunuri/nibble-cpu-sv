`timescale 1ns/1ps
import nibble_cpu_tb_pkg::*;

class Driver;

  virtual prog_if vif;
  mailbox #(Transactor) drv_mbx;

  // Constructor
  function new(virtual prog_if vif, mailbox #(Transactor) drv_mbx);
    this.vif = vif;
    this.drv_mbx = drv_mbx;
  endfunction

  task reset();
    $display("[ Driver ] ----- Reset Started -----");
	//******************************************************************
	// To Do:  3.1: Call the apply_reset() task from the virtual interface
	//******************************************************************
	vif.apply_reset();

    $display("[ Driver ] ----- Reset Ended -----");
  endtask

  task main();
    Transactor tr;
    forever begin
	//******************************************************************
	// To Do:  3.2.1: Get a transaction from the driver mailbox
	//******************************************************************
	drv_mbx.get(tr);

	//******************************************************************
	// To Do:  3.2.2: Pass the transaction to the drive_transaction() task
	//******************************************************************
	drive_transaction(tr);
	


      tr.display("[ Driver ]");
    end
  endtask

  local task drive_transaction(Transactor tr);
    logic [11:0] res_addr;
	frame_c frame;


	//******************************************************************
	// To Do:  3.3: Write a case statement to map the transaction 'op' (e.g., OP_ADD, OP_SUB)
	//******************************************************************
	//to the corresponding 8-bit instruction command 'cmd' (e.g., 8'h10, 8'h11)

    case (tr.op)
      // Map OP_ADD through OP_XOR here
	  OP_ADD,
	  OP_SUB,
	  OP_MUL,
	  OP_DIV,
	  OP_AND,
	  OP_OR,
	  OP_XOR: begin
		frame.addr=tr.address; frame.opcode=OP_WRITE; frame.data=tr.operand1;
		vif.send_frame(frame);
		frame.addr=tr.address+1; frame.opcode=OP_WRITE; frame.data=tr.operand2;
		vif.send_frame(frame);
		frame.addr=tr.address; frame.opcode=tr.op; frame.data=0;
		vif.send_frame(frame);
		res_addr = tr.address + 2;
	  end
	  OP_INV: begin
		frame.addr=tr.address; frame.opcode=OP_WRITE; frame.data=tr.operand1;
		vif.send_frame(frame);
		frame.addr=tr.address; frame.opcode=tr.op; frame.data=0;
		vif.send_frame(frame);
		res_addr = tr.address + 1;
	  end
	  OP_WRITE, OP_READ: begin
		frame.addr=tr.address; frame.opcode=OP_WRITE; frame.data=tr.operand1;
		vif.send_frame(frame);
		res_addr = tr.address;
	  end
	  OP_FILL0: begin
		frame.addr=tr.address; frame.opcode=OP_FILL0; frame.data=0;
		vif.send_frame(frame);
		res_addr=$urandom_range(4095,tr.address);
	  end
	  OP_FILL1: begin
		frame.addr=tr.address; frame.opcode=OP_FILL1; frame.data=0;
		vif.send_frame(frame);
		res_addr = $urandom_range(4095,tr.address);
	  end
	  OP_INC_ACC: begin
		frame.addr=tr.address; frame.opcode=OP_WRITE; frame.data=tr.operand1;
		vif.send_frame(frame);
		frame.addr=tr.address; frame.opcode=OP_INC_ACC; frame.data=0;
		vif.send_frame(frame);
		res_addr = tr.address;
	  end
    endcase
		
	frame.addr=res_addr; frame.opcode=OP_READ; frame.data=0;
    vif.send_frame(frame);
    //$display("Driver sent transaction OP %0h at %0t", tr.op, $time);
    repeat (50) @vif.cb;
  endtask

endclass
