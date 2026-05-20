module done_generator (
    input         clk,
    input         rst_n,
    input         cmd_start,
    input         cmd_busy,
    input         cmd_error,
    input  [1:0]  cmd_error_type,
    output        prog_done
);

    reg done_reg;
    reg [1:0] pulse_counter;
    reg error_pulse;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_reg <= 1'b0;
            pulse_counter <= 2'd0;
            error_pulse <= 1'b0;
        end
        else begin
            // Detect end of command execution
            if (cmd_busy && !cmd_start) begin
                // Command is finishing
                if (cmd_error) begin
                    // Error: 2-cycle pulse
                    error_pulse <= 1'b1;
                    pulse_counter <= 2'd2;
                    done_reg <= 1'b1;
                end
                else begin
                    // Success: 1-cycle pulse
                   //done_reg <= 1'b1;
                    pulse_counter <= 2'd1;
                end
            end
            else if (pulse_counter > 0) begin
                pulse_counter <= pulse_counter - 2'd1;
                if (pulse_counter == 2'd1) begin
                    done_reg <= 1'b1;
                    error_pulse <= 1'b0;
                end
            end
            else begin
                done_reg <= 1'b0;
            end
        end
    end
    
    assign prog_done = done_reg;

endmodule