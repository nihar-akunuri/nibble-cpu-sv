`timescale 1ns/1ps
import nibble_cpu_tb_pkg::*;

class test_random;
  Environment env;

  function new(virtual prog_if vif);
    env = new(vif);
  endfunction

  task run();
    $display("Starting Basic Random Test (No Constraints)...");
    // The generator inside the environment will randomize transactions,
    env.gen.repeat_count = 1000; //using repeat_count variable inside generator we control the number of transactions
    // but without explicit test-level constraints here.
    env.run();
  endtask

endclass
