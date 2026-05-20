interface mem_if(input logic clk);
    logic [11:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic        mem_wen;
    logic        mem_cen;

    // Modport for the CPU (Master)
    modport cpu_side (
        output mem_addr, mem_wdata, mem_wen, mem_cen,
        input  mem_rdata
    );

    // Modport for the Memory (Slave)
    modport mem_side (
        input  mem_addr, mem_wdata, mem_wen, mem_cen,
        output mem_rdata
    );
endinterface