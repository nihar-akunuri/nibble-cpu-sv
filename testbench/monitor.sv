`timescale 1ns/1ps
import nibble_cpu_tb_pkg::*;

class Monitor;

  virtual prog_if vif;
  mailbox #(Transactor) mon2scb;

  // Constructor
  function new(virtual prog_if vif,
               mailbox #(Transactor) mon2scb
               );
    this.vif = vif;
    this.mon2scb = mon2scb;
  endfunction

  task main();
    logic [31:0] result;
    int nibble_count;
    bit token;
    Transactor obs;

    forever begin
      @(posedge vif.prog_out_valid);
      result = 0;
      nibble_count = 0;

      //****************************************************************************
      // To Do: 4.1: Write a while loop that executes 8 times (to capture 8 nibbles)
      //****************************************************************************
      	      // Inside the loop:
	      // 1. Shift the current 'vif.prog_nibble_out' into the 'result' register.
	      // 2. Increment 'nibble_count'.
	      // 3. Wait for the next positive edge of the clock (vif.clk).
		  
		while(nibble_count<8) begin
			@(posedge vif.clk);
			result = {vif.prog_nibble_out,result[31:4]};
			nibble_count++;
			
		end
		
		//result = result >> 4;
      

      // Create a new observation transaction object
      obs = new();
      
      //****************************************************************************
      // To Do: 4.2: Assign the captured 'result' to 'obs.actual_result'
      //****************************************************************************
	  obs.actual_value = result;

      //****************************************************************************
      // To Do: 4.3: Put the 'obs' transaction into the 'mon2scb' mailbox
      //****************************************************************************
	  mon2scb.put(obs);
      
	  
      
      $display("[ Monitor ] %0t,  Captured result: 0x%h", $time, result);
    end
  endtask

endclass
