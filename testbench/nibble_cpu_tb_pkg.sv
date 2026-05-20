`timescale 1ns/1ps

package nibble_cpu_tb_pkg;

parameter MAX = 32'hFFFFFFFF;
parameter AMAX = 4095;

typedef enum logic [7:0] {
    OP_FILL0 = 8'h00,
    OP_FILL1 = 8'h01,
    OP_WRITE = 8'h02,
    OP_READ  = 8'h03,
    
    OP_WRITE_INC = 8'h04,
    OP_READ_SEQ = 8'h05,
    OP_INC_ACC = 8'h06,

    OP_ADD   = 8'h10,
    OP_SUB   = 8'h11,
    OP_MUL   = 8'h12,
    OP_DIV   = 8'h13,
    
    OP_INV   = 8'h14,
    OP_AND   = 8'h15,
    OP_OR    = 8'h16,
    OP_XOR   = 8'h17,
	
	OP_RES	 = 8'hFF
    
} opcode_t;

typedef struct packed {
    logic [11:0] addr;
    opcode_t     opcode;
    logic [31:0] op1;
	logic [31:0] op2;
} frame_t;

typedef struct packed {
    logic [11:0] addr;
    opcode_t     opcode;
    logic [31:0] data;
} frame_c;

`include "transactor.sv"
`include "generator.sv"
`include "scoreboard.sv"
`include "coverage.sv"
`include "monitor.sv"
`include "driver.sv"
`include "environment.sv"
`include "test_random.sv"

endpackage	