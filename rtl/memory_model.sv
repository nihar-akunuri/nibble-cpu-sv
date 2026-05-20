module memory_model (
    input          clk,
    input   [11:0]  mem_addr,
    input   [31:0]  mem_wdata,
    input          mem_wen,
    input          mem_cen,
    output reg [31:0]  mem_rdata
);

  
  reg [31:0] mem[0:4095]; 
  always @(posedge clk) begin
    if (mem_cen) begin

      if (mem_wen) begin
        mem[mem_addr] <= mem_wdata; 
      end
      else
      mem_rdata <= mem[mem_addr]; 
       
    end
  end
  
  

endmodule
