`timescale 1ns/1ps
import nibble_cpu_tb_pkg::*;

//=============================================================================
// Generator Class
// Generates random transactions and sends them to driver and scoreboard.
// Uses two mailboxes: one for driver, one for scoreboard (expected).
//=============================================================================
class Generator;

//*****************************************************************************
 // To Do:  2.1: Declare two mailboxes parameterized to Transaction (one for driver, one for scoreboard) 
//*****************************************************************************

 // 2.1.1   Mailbox for driver
 mailbox #(Transactor) drv_mbx;

 // 2.1.2   Mailbox for scoreboard (expected)
 mailbox #(Transactor) scb_mbx;
 
  mailbox #(Transactor) cov_mbx;


  // Number of transactions to generate
  int repeat_count;

  // Transaction handle (can be overridden in derived tests)
  Transactor trans,tr;

  // Event to signal end of generation
  event ended;


// Constructor
function new(mailbox #(Transactor) drv_mbx,
               mailbox #(Transactor) scb_mbx,
			   mailbox #(Transactor) cov_mbx);
//*****************************************************************************
// To Do:  2.2: Assign mailbox handles and instantiate the default transaction
//*****************************************************************************

this.drv_mbx = drv_mbx;
this.scb_mbx = scb_mbx;
this.cov_mbx = cov_mbx;

trans = new();

  endfunction

// Main task: generate and send transactions
   task main();
    $display("[Generator] repeat_count = %0d", repeat_count);
    repeat (repeat_count)
    begin
	//*****************************************************************************
	// To Do:  2.3: Randomize the 'trans' object. Throw a $fatal error if randomization fails 
	//*****************************************************************************
	if(!trans.randomize()) $fatal("Randomization Failed");

	//*****************************************************************************
	// To Do:  2.4: Perform a deep copy of 'trans' into 'tr' using your do_copy() method
	//*****************************************************************************
	tr = trans.do_copy();

	//*****************************************************************************
	// To Do:  2.5: Put 'tr' into both the driver and scoreboard mailboxes
	//*****************************************************************************
	drv_mbx.put(tr);
	scb_mbx.put(tr);
	cov_mbx.put(tr);

    end
    -> ended;  // signal completion
  endtask

endclass
