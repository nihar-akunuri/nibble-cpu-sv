`timescale 1ns/1ps
import nibble_cpu_tb_pkg::*;

//=============================================================================
// Transactor Class ? CPU Testbench (Skeleton)
//=============================================================================
class Transactor;

  // Test parameters (stimulus)
  rand logic [11:0] address;
  rand opcode_t     op;
  rand logic [31:0] operand1;
  rand logic [31:0] operand2;
  
  constraint valid{address inside {[0:4095]};
				   operand1 inside {[0:MAX]};
				   operand2 inside {[0:MAX]};
				   //(op == OP_DIV) -> operand2!=0;
				   (op inside {OP_MUL,OP_DIV}) -> (address inside {[0:4094]});
				   (op inside {OP_ADD,OP_SUB,OP_AND,OP_OR,OP_XOR}) -> (address inside {[0:4094]});
				   //op inside {OP_READ,OP_WRITE,OP_ADD,OP_SUB,OP_MUL,OP_DIV,OP_INV,OP_AND,OP_OR,OP_XOR,OP_FILL0,OP_FILL1,OP_WRITE_INC,OP_INC_ACC,OP_READ_SEQ};
				   op inside {OP_ADD,OP_SUB,OP_MUL,OP_DIV,OP_AND,OP_OR,OP_XOR,OP_WRITE,OP_READ,OP_FILL0,OP_FILL1};
				   }
				   
	constraint op_weight{ op dist {
								   OP_ADD := 10,
								   OP_SUB := 10,
								   OP_MUL := 10,
								   OP_DIV := 10,
								   OP_INV :=7,
								   OP_AND := 7,
								   OP_OR  := 7,
								   OP_XOR := 7,
								   OP_READ:=4,
								   OP_WRITE:=4,
								   OP_WRITE_INC:=4,
								   OP_FILL0:=4,
								   OP_FILL1:=4,
								   OP_INC_ACC:=4,
								   OP_READ_SEQ:=4
								   };
								   
						  operand1 dist {
										 0:=5,
										 1:=5,
										 [2:10]:/10,
										 [100:1000]:/10,
										 [10000:MAX-3]:/10,
										 MAX-2:=3,
										 MAX-1:=3,
										 MAX:=3,
										 32'h11111111:=1,
										 32'hAAAAAAAA:=1,
										 32'hF0F0F0F0:=1,
										 32'h0F0F0F0F:=1,
										 32'hFF00FF00:=1,
										 32'h00FF00FF:=1
										 };
										 
						  operand2 dist {
										 0:=5,
										 1:=5,
										 [2:10]:/10,
										 [100:1000]:/10,
										 [10000:MAX-3]:/10,
										 MAX-2:=3,
										 MAX-1:=3,
										 MAX:=3
										 };
										 
						  address dist {
										0:=5,
										[1:100]:/5,
										[1000:2000]:/5,
										[4000:4091]:/5,
										4092:=2,
										4093:=2,
										4094:=2,
										4095:=2
										};

						}
						
	static int arithmetic_count = 0;
	static int logical_count = 0;
						
  // Expected results
  logic [11:0] expected_address;
  logic [31:0] expected_value;

  // Execution results
  bit passed;
  logic [31:0] actual_value;

  //===========================================================================
  // Constructor ? used for deterministic tests
  //===========================================================================
  function new(
    input logic [11:0] addr = 0,
    input opcode_t     opcode = OP_ADD,
    input logic [31:0] op1 = 0,
    input logic [31:0] op2 = 0,
    input logic [11:0] exp_addr = 0,
    input logic [31:0] exp_val = 0
  );
    // TODO:
    // Assign inputs to class properties
	address = addr;
	op = opcode;
	operand1 = op1;
	operand2 = op2;
	expected_address = exp_addr;
	expected_value = exp_val;
    // Initialize passed and actual_value to 0
	passed = 0;
	actual_value = 0;
  endfunction
  
  function Transactor do_copy();
	Transactor tr = new();
	
	tr.op = this.op;
	tr.address = this.address;
	tr.operand1 = this.operand1;
	tr.operand2 = this.operand2;
	
	return tr;
	
  endfunction

  //===========================================================================
  // Build a frame_t for the interface task
  //===========================================================================
  function frame_t get_frame();
    frame_t f;

    // TODO:
    // Assign class fields to frame structure
	f.addr = address;
	f.opcode = op;
	f.op1 = operand1;
	f.op2 = operand2;

    return f;
  endfunction

  //===========================================================================
  // Check result
  //===========================================================================
  /* function bit check_result(logic [31:0] actual);
//Purpose: Compares DUT output with the expected value and updates pass/fail status.

	if($isunknown(expected_value)) begin
		passed = 1;
		return passed;
	end
		
	
	if(op==OP_DIV) begin
		if(operand2==0) begin
			passed = 1;
			return passed;
		end
	end
    // TODO:
    // Store actual DUT output in actual_value.
	actual_value = actual;
    // Compare with expected_value using case equality (===)
    //  Set passed flag based on comparison.
	if(actual_value === expected_value)
		passed = 1;
	else
		passed = 0;
    // Return the comparison result (1 = pass, 0 = fail).
	return passed;
  endfunction */

  //===========================================================================
  // Display
  //===========================================================================
  function void display(input string prefix = "");
    // TODO:
    // Display:
    //  Operation name
    //  Address
    //  Operand1 and Operand2
    //  Expected address and value
    //  Actual value and PASS/FAIL status
// Use the prefix string before each line.
	$display("[%s]: Operation: %s, Address: %h, Operand1: %h,Operand2: %h"
													,prefix,op.name,address,operand1,operand2);

  endfunction
  
function void post_randomize();
	case(op)
	OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_AND, OP_OR, OP_XOR: expected_address = address + 2;
	OP_INV: expected_address = address + 1;
	OP_READ, OP_WRITE, OP_INC_ACC, OP_WRITE_INC: expected_address = address;
	OP_FILL1, OP_FILL0, OP_READ_SEQ: expected_address = $urandom_range(4095,address);
	endcase
	
	case(op)
	OP_ADD: expected_value = operand1 + operand2;
	OP_SUB: expected_value = operand1 - operand2;
	OP_MUL: expected_value = operand1 * operand2;
	OP_DIV: begin
		if(operand2==0) expected_value = 0;
		else expected_value = operand1 / operand2;
	end
	OP_INV: expected_value = (~operand1);
	OP_AND: expected_value = operand1 & operand2;
	OP_OR: expected_value = operand1 | operand2;
	OP_XOR: expected_value = operand1 ^ operand2;
	OP_READ, OP_WRITE: expected_value = operand1;
	OP_INC_ACC: expected_value = (operand1 + 1);
	OP_FILL0: expected_value = 0;
	OP_FILL1, OP_READ_SEQ: expected_value = 32'hFFFFFFFF;
	OP_WRITE_INC: expected_value = operand1;
	default: expected_value = 0;
	endcase
	
	case(op)
	OP_ADD, OP_SUB, OP_MUL, OP_DIV: arithmetic_count++;
	OP_INV, OP_AND, OP_OR, OP_XOR: logical_count++;
	endcase
	
	if(op inside {OP_ADD,OP_SUB,OP_MUL,OP_DIV,OP_AND,OP_OR,OP_XOR})
		if(address>4092)
			expected_value = 32'dx;
	
endfunction

endclass