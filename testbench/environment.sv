`timescale 1ns/1ps
import nibble_cpu_tb_pkg::*;

class Environment;

  virtual prog_if vif;

  //***************************************************************************************************
  // To Do:  6.1: Declare handles for Generator, Driver, Monitor, Scoreboard, and Coverage
  //***************************************************************************************************
  Generator gen;
  Driver drv;
  Monitor mon;
  Scoreboard scb;
  Coverage cov;

  //***************************************************************************************************
  // To Do:  6.2: Declare necessary mailboxes to connect the components (gen2drv, gen2scb, mon2scb, gen2cov)
  //***************************************************************************************************
  mailbox #(Transactor) gen2drv;
  mailbox #(Transactor) gen2scb;
  mailbox #(Transactor) mon2scb;
  mailbox #(Transactor) gen2cov;


  function new(virtual prog_if vif);
    this.vif = vif;
  //***************************************************************************************************
  // To Do:  6.3: Instantiate all mailboxes
  //***************************************************************************************************
  gen2drv = new();
  gen2scb = new();
  mon2scb = new();
  gen2cov = new();

  //***************************************************************************************************
  // To Do:  6.4: Instantiate all components (gen, drv, mon, scb, cov), passing the correct virtual interface and mailboxes to their constructors
  //***************************************************************************************************
  
  gen = new(gen2drv,gen2scb,gen2cov);
  drv = new(vif,gen2drv);
  mon = new(vif,mon2scb);
  scb = new(gen2scb,mon2scb);
  cov = new(gen2cov);
  endfunction

  task pre_test();
    drv.reset();
  endtask

  task test();
    fork
  //***************************************************************************************************
  // To Do:  6.5: Call the main() task of all instantiated components concurrently
  //***************************************************************************************************
	gen.main();
	drv.main();
	mon.main();
	scb.main();
	cov.main();
    join_any
  endtask

  task post_test();
    wait(gen.ended.triggered);
    wait(gen.repeat_count == scb.no_transactions);
    $display("------------------------------------------------");
    if (scb.error_cnt == 0)
      $display("TEST PASSED after %0d transactions", scb.no_transactions);
    else
      $display("TEST FAILED with %0d errors out of %0d transactions", scb.error_cnt, scb.no_transactions);
    $display("------------------------------------------------");
  endtask

  task run();
    pre_test();
    test();
    post_test();
    $finish;
  endtask

endclass
