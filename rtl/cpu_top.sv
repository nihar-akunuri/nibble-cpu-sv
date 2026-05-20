`timescale 1ns/1ps

module cpu_top (
    // Global Interface
    input         clk,
    input         rst_n,
    
    // Programming Interface
    input  [3:0]  prog_nibble_in,
    input prog_nibble_in_valid,
    output [3:0]  prog_nibble_out,
    output        prog_out_valid,
    output        prog_done,
    
    // Memory Interface
    output [11:0] mem_addr,
    output [31:0] mem_wdata,
    input  [31:0] mem_rdata,
    output        mem_wen,
    output        mem_cen
);

    // Internal signals
    wire [11:0] frame_addr;
    wire [7:0]  frame_cmd;
    wire [31:0] frame_wdata;
    wire        frame_valid;
    wire        frame_ready;
    
    wire        cmd_start;
    wire        cmd_busy;
    wire [31:0] cmd_result;
    wire        cmd_result_valid;
    wire        cmd_error;
    wire [1:0]  cmd_error_type;
    
    wire        serializer_busy;
    
    // Serial Interface
    serial_interface u_serial_if (
        .clk            (clk),
        .rst_n          (rst_n),
        .prog_nibble_in (prog_nibble_in),
        .prog_nibble_in_valid (prog_nibble_in_valid),
        .frame_addr     (frame_addr),
        .frame_cmd      (frame_cmd),
        .frame_wdata    (frame_wdata),
        .frame_valid    (frame_valid),
        .frame_ready    (frame_ready)
    );
    
    // Command Decoder & Controller
    cmd_controller u_cmd_ctrl (
        .clk                (clk),
        .rst_n              (rst_n),
        .frame_valid        (frame_valid),
        .frame_addr         (frame_addr),
        .frame_cmd          (frame_cmd),
        .frame_wdata        (frame_wdata),
        .frame_ready        (frame_ready),
        .cmd_start          (cmd_start),
        .cmd_busy           (cmd_busy),
        .cmd_result         (cmd_result),
        .cmd_result_valid   (cmd_result_valid),
        .cmd_error          (cmd_error),
        .cmd_error_type     (cmd_error_type),
	.serializer_busy    (serializer_busy),
        .mem_addr           (mem_addr),
        .mem_wdata          (mem_wdata),
        .mem_rdata          (mem_rdata),
        .mem_wen            (mem_wen),
        .mem_cen            (mem_cen)
    );
    
    // Output Serializer
    output_serializer u_out_serializer (
        .clk                (clk),
        .rst_n              (rst_n),
        .data_in            (cmd_result),
        .data_valid         (cmd_result_valid),
        .cmd_busy           (cmd_busy),
        .serial_out         (prog_nibble_out),
        .serial_valid       (prog_out_valid),
        .serializer_busy    (serializer_busy)
    );
    
    // Done Signal Generator
    done_generator u_done_gen (
        .clk            (clk),
        .rst_n          (rst_n),
        .cmd_start      (cmd_start),
        .cmd_busy       (cmd_busy),
        .cmd_error      (cmd_error),
        .cmd_error_type (cmd_error_type),
        .prog_done      (prog_done)
    );

endmodule