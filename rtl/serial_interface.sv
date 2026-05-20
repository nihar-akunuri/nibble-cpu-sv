module serial_interface (
    input         clk,
    input         rst_n,
    input  [3:0]  prog_nibble_in,
    input prog_nibble_in_valid,
    output [11:0] frame_addr,
    output [7:0]  frame_cmd,
    output [31:0] frame_wdata,
    output        frame_valid,
    input         frame_ready
);

    reg [3:0]  nibble_counter;
    reg [11:0] addr_reg;
    reg [7:0]  cmd_reg;
    reg [31:0] wdata_reg;
    reg        valid_reg;
    
    // Nibble shift registers
    reg [3:0]  addr_nibbles [2:0];
    reg [3:0]  cmd_nibbles  [1:0];
    reg [3:0]  data_nibbles [7:0];
     
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nibble_counter <= 4'd0;
            valid_reg <= 1'b0;
            for (i = 0; i < 3; i = i + 1) addr_nibbles[i] <= 4'd0;
            for (i = 0; i < 2; i = i + 1) cmd_nibbles[i] <= 4'd0;
            for (i = 0; i < 8; i = i + 1) data_nibbles[i] <= 4'd0;
        end
        else if (frame_ready || !valid_reg) begin
            if (nibble_counter > 4'd12) begin
                // Complete frame received
                nibble_counter <= 4'd0;
                valid_reg <= 1'b1;
                
                // Assemble address (LSB nibble first)
                addr_reg <= {addr_nibbles[2], addr_nibbles[1], addr_nibbles[0]};
                
                // Assemble command
                cmd_reg <= {cmd_nibbles[1], cmd_nibbles[0]};
                
                // Assemble write data
                wdata_reg <= {
                    data_nibbles[7], data_nibbles[6], data_nibbles[5], data_nibbles[4],
                    data_nibbles[3], data_nibbles[2], data_nibbles[1], data_nibbles[0]
                };
            end
            else begin
                // Shift in new nibble
                if (prog_nibble_in_valid) 
                nibble_counter <= nibble_counter + 4'd1;
                valid_reg <= 1'b0;
                
                case (nibble_counter)
                    // Address nibbles
                    4'd0: addr_nibbles[0] <= prog_nibble_in;
                    4'd1: addr_nibbles[1] <= prog_nibble_in;
                    4'd2: addr_nibbles[2] <= prog_nibble_in;
                    
                    // Command nibbles
                    4'd3: cmd_nibbles[0] <= prog_nibble_in;
                    4'd4: cmd_nibbles[1] <= prog_nibble_in;
                    
                    // Data nibbles
                    4'd5: data_nibbles[0] <= prog_nibble_in;
                    4'd6: data_nibbles[1] <= prog_nibble_in;
                    4'd7: data_nibbles[2] <= prog_nibble_in;
                    4'd8: data_nibbles[3] <= prog_nibble_in;
                    4'd9: data_nibbles[4] <= prog_nibble_in;
                    4'd10: data_nibbles[5] <= prog_nibble_in;
                    4'd11: data_nibbles[6] <= prog_nibble_in;
                    4'd12: data_nibbles[7] <= prog_nibble_in;
                endcase
                
            end
        end
    end
    
    assign frame_addr  = addr_reg;
    assign frame_cmd   = cmd_reg;
    assign frame_wdata = wdata_reg;
    assign frame_valid = valid_reg;

endmodule