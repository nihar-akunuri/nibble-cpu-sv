module output_serializer (
    input         clk,
    input         rst_n,
    input  [31:0] data_in,
    input         data_valid,
    input         cmd_busy,
    output [3:0]  serial_out,
    output        serial_valid,
    output        serializer_busy
);

    reg [2:0]  nibble_counter;
    reg [31:0] data_reg;
    reg        valid_reg;
    reg        busy_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nibble_counter <= 3'd0;
            data_reg <= 32'd0;
            valid_reg <= 1'b0;
            busy_reg <= 1'b0;
        end
        else begin
            if (data_valid && !busy_reg) begin
                // Start serialization
                data_reg <= data_in;
                nibble_counter <= 3'd0;
                valid_reg <= 1'b1;
                busy_reg <= 1'b1;
            end
          //  else if (busy_reg && !cmd_busy) begin
  	    else if (busy_reg ) begin


                // Continue serialization
                if (nibble_counter == 3'd7) begin
                    // Last nibble
                    nibble_counter <= 3'd0;
                    valid_reg <= 1'b0;
                    busy_reg <= 1'b0;
                end
                else begin
                    nibble_counter <= nibble_counter + 3'd1;
                    valid_reg <= 1'b1;
                end
                
                // Rotate data for next nibble
                data_reg <= {4'd0, data_reg[31:4]};
            end
            else begin
                valid_reg <= 1'b0;
            end
        end
    end
    
    // Output current nibble (LSB first)
    assign serial_out = data_reg[3:0];
    assign serial_valid = valid_reg;
    assign serializer_busy = busy_reg;

endmodule