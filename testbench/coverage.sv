class Coverage;

	mailbox #(Transactor) mon2cov;

	opcode_t op;
	logic [31:0] operand1;
	logic [31:0] operand2;
	logic [11:0] address;
	logic overflow;

	// Opcodes Covergroup
	covergroup cg_ops;
		option.per_instance = 1;
		coverpoint op {
			bins write_bin = {OP_WRITE};
			bins read_bin = {OP_READ};
			bins fill0_bin = {OP_FILL0};
			bins fill1_bin = {OP_FILL1};
			bins add_bin = {OP_ADD};
			bins sub_bin = {OP_SUB};
			bins mul_bin = {OP_MUL};
			bins div_bin = {OP_DIV};
			bins and_bin = {OP_AND};
			bins or_bin = {OP_OR};
			bins xor_bin = {OP_XOR};	
			}
	endgroup
	
	// Operand 1 Covergroup
	covergroup cg_operand1;
		option.per_instance = 1;
		coverpoint operand1 {
			bins zero_bin = {0};
			bins one_bin = {1};
			bins small_bin = {[2:10]};
			bins medium_bin = {[100:1000]};
			bins large_bin = {[10000:MAX-3]};
			bins max2_bin = {MAX-2};
			bins max1_bin = {MAX-1};
			bins max0_bin = {32'hFFFFFFFF};
			bins patterns_bin = {32'h11111111,32'hAAAAAAAA,32'hF0F0F0F0,32'h0F0F0F0F,32'hFF00FF00,32'h00FF00FF};
			}
	endgroup
	
	//Operand 2 Covergroup
	covergroup cg_operand2;
		option.per_instance = 1;
		coverpoint operand2 {
			bins zero_bin = {0};
			bins one_bin = {1};
			bins small_bin = {[2:10]};
			bins medium_bin = {[100:1000]};
			bins large_bin = {[10000:MAX-3]};
			bins max2_bin = {MAX-2};
			bins max1_bin = {MAX-1};
			bins max0_bin = {MAX};
			}
	endgroup
	
	// Address Covergroup
	covergroup cg_address;
		option.per_instance = 1;
		coverpoint address {
			bins zero_bin = {0};
			bins low_bin = {[1:100]};
			bins mid_bin = {[1000:2000]};
			bins high_bin = {[4000:AMAX-4]};
			bins max3_bin = {AMAX-3};
			bins max2_bin = {AMAX-2};
			bins max1_bin = {AMAX-1};
			bins max0_bin = {AMAX};
			}
	endgroup
	
	// Data Covergroup
	covergroup cg_data;
		option.per_instance = 1;
		coverpoint operand1 {
			bins zeros_bin = {0};
			bins ones_bin = {32'h11111111};
			bins as_bin = {32'hAAAAAAAA};
			bins fs_bin = {32'hFFFFFFFF};
			bins patterns_bin = {32'hF0F0F0F0,32'h0F0F0F0F,32'hFF00FF00,32'h00FF00FF};
			}
	endgroup
	
	// Errors Covergroup
	covergroup cg_errors;
		option.per_instance = 1;
		coverpoint operand2 iff (op==OP_DIV) {
			bins div_zero = {0};
			}
		
		coverpoint address {
			bins out_of_range = {[4096:$]};
			}
	endgroup
	
	// Overflow Covergroup
	covergroup cg_overflow;
		option.per_instance = 1;
		coverpoint overflow{
			bins overflow = {1};
			}
	endgroup
	
	// Opcode cross Operand 1 Covergroup
	covergroup cg_cross_op_operand1;
		option.per_instance = 1;
		coverpoint op {
			bins write_bin = {OP_WRITE};
			bins read_bin = {OP_READ};
			bins add_bin = {OP_ADD};
			bins sub_bin = {OP_SUB};
			bins mul_bin = {OP_MUL};
			bins div_bin = {OP_DIV};
			bins and_bin = {OP_AND};
			bins or_bin = {OP_OR};
			bins xor_bin = {OP_XOR};	
			}
		
		coverpoint operand1 {
			bins zero_bin = {0};
			bins one_bin = {1};
			bins small_bin = {[2:10]};
			bins medium_bin = {[100:1000]};
			bins large_bin = {[10000:MAX-3]};
			bins max2_bin = {MAX-2};
			bins max1_bin = {MAX-1};
			bins max_bin = {MAX};
			}
			
		cross op, operand1;
	endgroup
	
	// Opcode cross Operand 2 Covergroup
	covergroup cg_cross_op_operand2;
		option.per_instance = 1;
		coverpoint op {
			bins add_bin = {OP_ADD};
			bins sub_bin = {OP_SUB};
			bins mul_bin = {OP_MUL};
			bins div_bin = {OP_DIV};
			bins and_bin = {OP_AND};
			bins or_bin = {OP_OR};
			bins xor_bin = {OP_XOR};	
			}
		
		coverpoint operand2 {
			bins zero_bin = {0};
			bins one_bin = {1};
			bins small_bin = {[2:10]};
			bins medium_bin = {[100:1000]};
			bins large_bin = {[10000:MAX-3]};
			bins max2_bin = {MAX-2};
			bins max1_bin = {MAX-1};
			bins max_bin = {MAX};
			}
			
		cross op, operand2;
	endgroup
	
	// Opcode cross address Covergroup
	covergroup cg_cross_op_address;
		option.per_instance = 1;
		coverpoint op {
			bins write_bin = {OP_WRITE};
			bins read_bin = {OP_READ};
			bins fill0_bin = {OP_FILL0};
			bins fill1_bin = {OP_FILL1};
			bins add_bin = {OP_ADD};
			bins sub_bin = {OP_SUB};
			bins mul_bin = {OP_MUL};
			bins div_bin = {OP_DIV};
			bins and_bin = {OP_AND};
			bins or_bin = {OP_OR};
			bins xor_bin = {OP_XOR};	
			}
		
		coverpoint address {
			bins zero_bin = {0};
			bins low_bin = {[1:100]};
			bins mid_bin = {[1000:2000]};
			bins high_bin = {[4000:AMAX-4]};
			bins max3_bin = {AMAX-3};
			bins max2_bin = {AMAX-2};
			bins max1_bin = {AMAX-1};
			bins max_bin = {AMAX};
			}
			
		cross op, address;
	endgroup

	// Constructor
	function new(mailbox #(Transactor) mon2cov);
		this.mon2cov = mon2cov;
		cg_ops = new();
		cg_operand1 = new();
		cg_operand2 = new();
		cg_address = new();
		cg_data = new();
		cg_errors = new();
		cg_overflow = new();
		cg_cross_op_operand1 = new();
		cg_cross_op_operand2 = new();
		cg_cross_op_address = new();
	endfunction

	// Sample function
	function void sample(Transactor t);
		op = t.op;
		operand1 = t.operand1;
		operand2 = t.operand2;
		address = t.address;
		case (op)
			OP_ADD: overflow = (operand1+operand2>MAX);
			OP_SUB: overflow = (operand1<operand2);
			default: overflow = 0;
		endcase
		
		cg_ops.sample();
		cg_operand1.sample();
		cg_operand2.sample();
		cg_address.sample();
		cg_data.sample();
		cg_errors.sample();
		cg_overflow.sample();
		cg_cross_op_operand1.sample();
		cg_cross_op_operand2.sample();
		cg_cross_op_address.sample();
	endfunction
	
	task main();
		Transactor t;
		
		forever begin
			mon2cov.get(t);
			sample(t);
		end
	endtask

endclass