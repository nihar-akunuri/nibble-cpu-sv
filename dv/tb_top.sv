`timescale 1ns/1ps
import nibble_cpu_tb_pkg::*;

module tb_top;

  bit clk;
  
  initial clk = 0;

  // Clock generation
  always #5 clk = ~clk;

  // Interface instantiation
  prog_if vif(clk);
  mem_if mif(clk);

  //-------------------------------------------------------
  // Instantiate DUT here and connect to vif
  //-------------------------------------------------------
  cpu_top dut(clk,vif.rst_n,
                vif.prog_nibble_in,vif.prog_nibble_in_valid,vif.prog_nibble_out,
                vif.prog_out_valid,vif.prog_done,
                mif.mem_addr,mif.mem_wdata,mif.mem_rdata,mif.mem_wen,mif.mem_cen);
     
  memory_model duut(clk,mif.mem_addr,mif.mem_wdata,mif.mem_wen,mif.mem_cen,mif.mem_rdata); 

  // Reset generation
/*   initial begin
    clk = 0;
    reset = 1;
    #20 reset = 0;
  end */

  // Run the test
  
  
  test_random test;
	
  initial begin
    test = new(vif);

    // Wait for reset to deassert before starting
   // @(negedge reset);
    test.run();
  end

  // Optional: Dump waves
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end

endmodule


