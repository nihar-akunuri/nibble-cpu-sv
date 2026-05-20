`timescale 1ns/1ps
import nibble_cpu_tb_pkg::*;

//=============================================================================
// Scoreboard Class
// Receives expected transactions from generator and actual observations from monitor.
// Predicts the expected result using a reference model and compares.
//=============================================================================
class Scoreboard;

  // Mailboxes
  mailbox #(Transactor) exp_mbx;   // from generator (expected)
  mailbox #(Transactor) obs_mbx;   // from monitor (actual)

  // Counters
  int no_transactions;
  int error_cnt;

  // Constructor
  function new(mailbox #(Transactor) exp_mbx,
               mailbox #(Transactor) obs_mbx);
    this.exp_mbx = exp_mbx;
    this.obs_mbx = obs_mbx;
    no_transactions = 0;
    error_cnt = 0;
  endfunction

  // Predict expected result from stimulus (reference model)
  function logic [31:0] predict(Transactor stim);
	//**************************************************************************************************
	// To Do: 5.1: Write a case statement based on stim.op to calculate and return the expected result
	//**************************************************************************************************
	case(stim.op)
		OP_ADD: return stim.operand1 + stim.operand2;
		OP_SUB: return stim.operand1 - stim.operand2;
		OP_MUL: return stim.operand1 * stim.operand2;
		OP_DIV: begin
			if(stim.operand2!=0)
				return stim.operand1 / stim.operand2;
			else
				return 32'dx;
		end
		OP_INV: return ~stim.operand1;
		OP_AND: return stim.operand1 & stim.operand2;
		OP_OR:  return stim.operand1 | stim.operand2;
		OP_XOR: return stim.operand1 ^ stim.operand2;
		OP_WRITE: return stim.operand1;
		OP_READ: return stim.operand1;
		OP_FILL1: return 32'hFFFFFFFF;
		OP_FILL0: return 0;
		OP_INC_ACC: return stim.operand1 + 1;
	endcase
	endfunction

  // Main comparison task
  task main();
  	Transactor exp, obs;
	logic [31:0] exp_val;

    forever begin
	//**************************************************************************************************
	// To Do: 5.2: Get transactions from both mailboxes
	//**************************************************************************************************
	exp_mbx.get(exp);
	obs_mbx.get(obs);
	//**************************************************************************************************
	// To Do: 5.3: Call predict() using the expected transaction
	//**************************************************************************************************
	exp_val = predict(exp);
	//**************************************************************************************************
	// To Do: 5.4: Compare predicted value against obs.actual_result. Increment error_cnt if they don't match, and an else for the passing message
	//************************************************************************************************** 
	if($isunknown(exp_val))
		$display("Pass");
	else if(exp_val == obs.actual_value)
		$display("Pass");
	else begin
		$display("Fail Expected: %0d Actual: %0d",exp_val,obs.actual_value);
		error_cnt++;
	end
	no_transactions++;
      exp.display("[ Scoreboard Expected ]");
      obs.display("[ Scoreboard Actual ]");
    end
	
  endtask
endclass
