module cmd_controller (
    input         clk,
    input         rst_n,
    input         frame_valid,
    input  [11:0] frame_addr,
    input  [7:0]  frame_cmd,
    input  [31:0] frame_wdata,
    output        frame_ready,
    
    output        cmd_start,
    output        cmd_busy,
    output [31:0] cmd_result,
    output        cmd_result_valid,
    output        cmd_error,
    output [1:0]  cmd_error_type,	
    input         serializer_busy,
    
    output [11:0] mem_addr,
    output [31:0] mem_wdata,
    input  [31:0] mem_rdata,
    output        mem_wen,
    output        mem_cen
);

    // =========================================================================
    // PARAMETERS DEFINITION
    // =========================================================================
    
    // FSM States Definition
    parameter [2:0] STATE_IDLE                  = 3'b000;
    parameter [2:0] STATE_DECODE                = 3'b001;
    parameter [2:0] STATE_EXECUTE               = 3'b010;
    parameter [2:0] STATE_MEM_ACCESS            = 3'b011;
    parameter [2:0] STATE_WAIT                  = 3'b100;
    parameter [2:0] STATE_DONE                  = 3'b101; 
    parameter [2:0] STATE_WAIT_SERIALIZER_DONE1 = 3'b110;
    parameter [2:0] STATE_WAIT_SERIALIZER_DONE2 = 3'b111;
    
    // Error Types Definition
    parameter [1:0] ERR_ADDR_OOR      = 2'b00;  // Address out of range
    parameter [1:0] ERR_DIV_ZERO      = 2'b01;  // Division by zero
    parameter [1:0] ERR_CMP_MISMATCH  = 2'b10;  // Compare mismatch
    
    // Command Opcodes Definition
    parameter [7:0] CMD_FILL0    = 8'h00;  // Fill memory with 0s starting from address
    parameter [7:0] CMD_FILL1    = 8'h01;  // Fill memory with 1s starting from address
    parameter [7:0] CMD_WRITE    = 8'h02;  // Write data to specific address
    parameter [7:0] CMD_READ     = 8'h03;  // Read data from specific address
    parameter [7:0] CMD_WRITE_INC= 8'h04;  // Write and increment data
    parameter [7:0] CMD_READ_SEQ = 8'h05;  // Read sequential addresses
    parameter [7:0] CMD_INC_ACC  = 8'h06;  // Increment accumulator
    parameter [7:0] CMD_ADD      = 8'h10;  // Addition operation
    parameter [7:0] CMD_SUB      = 8'h11;  // Subtraction operation
    parameter [7:0] CMD_MUL      = 8'h12;  // Multiplication operation
    parameter [7:0] CMD_DIV      = 8'h13;  // Division operation
    parameter [7:0] CMD_INV      = 8'h14;  // Bitwise inversion
    parameter [7:0] CMD_AND      = 8'h15;  // Bitwise AND
    parameter [7:0] CMD_OR       = 8'h16;  // Bitwise OR
    parameter [7:0] CMD_XOR      = 8'h17;  // Bitwise XOR
    
    // Memory and Address Parameters
    parameter ADDR_WIDTH         = 12;     // Address bus width
    parameter DATA_WIDTH         = 32;     // Data bus width
    parameter MAX_MEM_ADDR       = 12'hFFF; // Maximum memory address (4095)
    parameter ADDR_LIMIT_PLUS   = 12'hFFE; // Address limit for +/- operations (needs 3 locations)
    parameter ADDR_LIMIT_MULT   = 12'hFFD; // Address limit for */ operations (needs 4 locations)
    
    // =========================================================================
    // INTERNAL REGISTERS
    // =========================================================================
    
    // FSM State Registers
    reg [2:0]  state, next_state;
    
    // Command and Data Registers
    reg [ADDR_WIDTH-1:0] addr_reg;        // Stored frame address
    reg [7:0]            cmd_reg;         // Stored frame command
    reg [DATA_WIDTH-1:0] wdata_reg;       // Stored write data
    reg [63:0]           result_reg;      // 64-bit result register for intermediate calculations
    reg                  result_valid_reg; // Result valid flag
    reg                  error_reg;        // Error flag
    reg [1:0]            error_type_reg;  // Error type
    reg                  busy_reg;         // Controller busy flag
    
    // Control and Counter Registers
    reg [ADDR_WIDTH-1:0] counter;         // Address counter for sequential operations
    reg [DATA_WIDTH-1:0] divident;        // Dividend register for division operation
    
    // Memory Interface Registers
    reg [ADDR_WIDTH-1:0] mem_addr_reg;    // Memory address
    reg [DATA_WIDTH-1:0] mem_wdata_reg;   // Memory write data
    reg                  mem_wen_reg;     // Memory write enable
    reg                  mem_cen_reg;     // Memory chip enable
    
    // =========================================================================
    // STATE MACHINE - SYNCHRONOUS PROCESS
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            state <= STATE_IDLE;
            addr_reg <= {ADDR_WIDTH{1'b0}};
            cmd_reg <= 8'd0;
            wdata_reg <= {DATA_WIDTH{1'b0}};
            result_reg <= 64'd0;
            result_valid_reg <= 1'b0;
            error_reg <= 1'b0;
            error_type_reg <= 2'd0;
            busy_reg <= 1'b0;
            counter <= {ADDR_WIDTH{1'b0}};
            mem_addr_reg <= {ADDR_WIDTH{1'b0}};
            mem_wdata_reg <= {DATA_WIDTH{1'b0}};
            mem_wen_reg <= 1'b0;
            mem_cen_reg <= 1'b0;
            divident <= {DATA_WIDTH{1'b0}};
        end
        else begin
            state <= next_state;  // Update state
            
            case (state)
                // -------------------------------------------------------------
                // IDLE STATE: Wait for frame valid signal
                // -------------------------------------------------------------
                STATE_IDLE: begin
                    if (frame_valid) begin
                        // Store incoming command and data
                        addr_reg <= frame_addr;
                        cmd_reg <= frame_cmd;
                        wdata_reg <= frame_wdata;
                        busy_reg <= 1'b1;                // Set busy flag
                        result_reg <= 64'd0;             // Clear result
                        result_valid_reg <= 1'b0;        // Clear valid flag
                        error_reg <= 1'b0;               // Clear error flag
                        divident <= {DATA_WIDTH{1'b0}};  // Clear dividend
                        counter <= frame_addr;           // Initialize counter with start address
                    end
                end
                
                // -------------------------------------------------------------
                // DECODE STATE: Validate command and check for errors
                // -------------------------------------------------------------
                STATE_DECODE: begin
                    // Check for address out of range for arithmetic operations
                    // ADD/SUB need 3 locations (2 operands + 1 result)
                    if (addr_reg >= ADDR_LIMIT_PLUS && 
                       (cmd_reg == CMD_ADD || cmd_reg == CMD_SUB)) begin
                        error_reg <= 1'b1;
                        error_type_reg <= ERR_ADDR_OOR;
                    end
                    // MUL/DIV need 4 locations (2 operands + quotient + remainder for DIV)
                    else if (addr_reg >= ADDR_LIMIT_MULT && 
                            (cmd_reg == CMD_MUL || cmd_reg == CMD_DIV)) begin
                        error_reg <= 1'b1;
                        error_type_reg <= ERR_ADDR_OOR;
                    end
                    
                    // Note: Division by zero check will be performed in EXECUTE state
                    // when we read the divisor from memory
                end
                
                // -------------------------------------------------------------
                // EXECUTE STATE: Setup memory operations based on command
                // -------------------------------------------------------------
                STATE_EXECUTE: begin
                    // Process different commands
                    case (cmd_reg)
                        CMD_FILL0: begin  // Fill memory with zeros
                            mem_addr_reg <= counter;
                            mem_wdata_reg <= {DATA_WIDTH{1'b0}};
                            mem_wen_reg <= 1'b1;
                            mem_cen_reg <= 1'b1;
                            counter <= counter + 1'b1;
                        end
                        
                        CMD_FILL1: begin  // Fill memory with ones
                            mem_addr_reg <= counter;
                            mem_wdata_reg <= {DATA_WIDTH{1'b1}};
                            mem_wen_reg <= 1'b1;
                            mem_cen_reg <= 1'b1;
                            counter <= counter + 1'b1;
                        end
                        
                        CMD_WRITE: begin  // Write to specific address
                            mem_addr_reg <= addr_reg;
                            mem_wdata_reg <= wdata_reg;
                            mem_wen_reg <= 1'b1;
                            mem_cen_reg <= 1'b1;
                        end
                        
                        CMD_READ: begin  // Read from specific address
                            mem_addr_reg <= addr_reg;
                            mem_wen_reg <= 1'b0;  // Read operation
                            mem_cen_reg <= 1'b1;
                        end

                        CMD_WRITE_INC: begin  // Write and increment
                            mem_addr_reg <= counter;
                            mem_wdata_reg <= wdata_reg;
                            mem_wen_reg <= 1'b1;
                            mem_cen_reg <= 1'b1;
                            counter <= counter + 1'b1;
                            wdata_reg <= wdata_reg + 1'b1;  // Increment data for next write
                        end
                        
                        CMD_READ_SEQ: begin  // Read sequential addresses
                            mem_addr_reg <= counter;
                            mem_wen_reg <= 1'b0;  // Read operation
                            mem_cen_reg <= 1'b1;
                            counter <= counter + 1'b1;
                        end
                        
                        CMD_INC_ACC: begin  // Increment accumulator
                            mem_addr_reg <= addr_reg;
                            mem_wen_reg <= 1'b0;  // First read, then write
                            mem_cen_reg <= 1'b1;
                        end
                        
                        // Arithmetic operations: ADD, SUB, AND, OR, XOR
                        CMD_ADD, CMD_SUB, CMD_AND, CMD_OR, CMD_XOR: begin
                            mem_addr_reg <= counter;
                            mem_wen_reg <= 1'b0;  // Read operation
                            // Enable chip select only during operand read phase
                            if (counter <= addr_reg + 1) begin
                                mem_cen_reg <= 1'b1;
                            end
                            else begin
                                mem_cen_reg <= 1'b0;
                            end
                            counter <= counter + 1'b1;
                        end
                        
                        // Multiplication and Division operations
                        CMD_MUL, CMD_DIV: begin
                            mem_addr_reg <= counter;
                            mem_wen_reg <= 1'b0;  // Read operation
                            mem_cen_reg <= 1'b1;
                            counter <= counter + 1'b1;
                        end
                        
                        CMD_INV: begin  // Bitwise inversion
                            mem_addr_reg <= addr_reg;
                            mem_wen_reg <= 1'b0;  // First read, then write
                            mem_cen_reg <= 1'b1;
                        end
                    endcase
                end
                
                // -------------------------------------------------------------
                // MEM_ACCESS STATE: Process memory read results
                // -------------------------------------------------------------
                STATE_MEM_ACCESS: begin
                    // Deassert memory control signals after access
                    mem_wen_reg <= 1'b0;
                    mem_cen_reg <= 1'b0;
                    
                    // Accumulate results for arithmetic operations
                    if (cmd_reg == CMD_ADD || cmd_reg == CMD_SUB || cmd_reg == CMD_MUL || 
                        cmd_reg == CMD_AND || cmd_reg == CMD_OR || cmd_reg == CMD_XOR) begin
                        result_reg <= result_reg + mem_rdata;  // Accumulate operands
                    end
                    else if (cmd_reg == CMD_DIV) begin
                        result_reg <= result_reg + mem_rdata;  // Accumulate operands
                        
                        // Store first operand as dividend
                        if (counter == addr_reg + 2) begin
                            divident <= mem_rdata;
                        end
                    end 
                end
                
                // -------------------------------------------------------------
                // WAIT STATE: Process operation results and prepare next steps
                // -------------------------------------------------------------
                STATE_WAIT: begin
                    case (cmd_reg)
                        CMD_READ: begin  // Simple read operation
                            result_reg <= {32'd0, mem_rdata};
                            result_valid_reg <= 1'b1;
                        end
                        
                        CMD_READ_SEQ: begin  // Sequential read
                            result_reg <= {32'd0, mem_rdata};
                            result_valid_reg <= 1'b1;
                        end
                        
                        CMD_INC_ACC: begin  // Increment and write back
                            result_reg <= {32'd0, mem_rdata + 1'b1};
                            result_valid_reg <= 1'b1;
                            mem_wdata_reg <= mem_rdata + 1'b1;
                            mem_addr_reg <= addr_reg;
                            mem_wen_reg <= 1'b1;
                            mem_cen_reg <= 1'b1;
                        end
                        
                        CMD_ADD: begin  // Addition operation completion
                            if (counter == addr_reg + 2) begin
                                mem_addr_reg <= addr_reg + 2;
                                mem_wdata_reg <= result_reg[31:0] + mem_rdata;
                                mem_wen_reg <= 1'b1;
                                mem_cen_reg <= 1'b1;
                            end
                        end
                        
                        CMD_SUB: begin  // Subtraction operation completion
                            if (counter == addr_reg + 2) begin
                                mem_addr_reg <= addr_reg + 2;
                                mem_wdata_reg <= result_reg[31:0] - mem_rdata;
                                mem_wen_reg <= 1'b1;
                                mem_cen_reg <= 1'b1;
                            end
                        end
                        
                        CMD_MUL: begin  // Multiplication operation
                            if (counter == addr_reg + 2) begin
                                // Write lower 32 bits of product
                                mem_addr_reg <= addr_reg + 2;
                                mem_wdata_reg <= result_reg[31:0] * mem_rdata;
                                result_reg <= result_reg * mem_rdata;  // Full 64-bit result
                                mem_wen_reg <= 1'b1;
                                mem_cen_reg <= 1'b1;
                            end
                            else if (counter == addr_reg + 3) begin
                                // Write upper 32 bits of product
                                mem_addr_reg <= addr_reg + 3;
                                mem_wdata_reg <= result_reg[63:32];
                                mem_wen_reg <= 1'b1;
                                mem_cen_reg <= 1'b1;
                            end
                        end
                        
                        CMD_DIV: begin  // Division operation
                            if (counter == addr_reg + 2 && !error_reg) begin
                                // Check for division by zero
                                if (mem_rdata == {DATA_WIDTH{1'b0}}) begin
                                    error_reg <= 1'b1;
                                    error_type_reg <= ERR_DIV_ZERO;
                                end
                                else begin
                                    // Write quotient
                                    mem_addr_reg <= addr_reg + 2;
                                    mem_wdata_reg <= result_reg[31:0] / mem_rdata;
                                    result_reg[63:32] <= result_reg[31:0];  // Save for remainder calculation
                                    mem_wen_reg <= 1'b1;
                                    mem_cen_reg <= 1'b1;
                                end
                            end
                            else if (counter == addr_reg + 3 && !error_reg) begin
                                // Write remainder
                                mem_addr_reg <= addr_reg + 3;
                                mem_wdata_reg <= result_reg[63:32] % mem_rdata;
                                mem_wen_reg <= 1'b1;
                                mem_cen_reg <= 1'b1;
                            end
                        end
                        
                        CMD_INV: begin  // Bitwise inversion
                            result_reg <= {32'd0, ~mem_rdata};
                            result_valid_reg <= 1'b1;
                            mem_wdata_reg <= ~mem_rdata;
                            mem_addr_reg <= addr_reg+1;
                            mem_wen_reg <= 1'b1;
                            mem_cen_reg <= 1'b1;
                        end
                        
                        CMD_AND: begin  // Bitwise AND
                            if (counter == addr_reg + 2) begin
                                mem_addr_reg <= addr_reg + 2;
                                mem_wdata_reg <= result_reg[31:0] & mem_rdata;
                                mem_wen_reg <= 1'b1;
                                mem_cen_reg <= 1'b1;
                            end
                        end
                        
                        CMD_OR: begin  // Bitwise OR
                            if (counter == addr_reg + 2) begin
                                mem_addr_reg <= addr_reg + 2;
                                mem_wdata_reg <= result_reg[31:0] | mem_rdata;
                                mem_wen_reg <= 1'b1;
                                mem_cen_reg <= 1'b1;
                            end
                        end
                        
                        CMD_XOR: begin  // Bitwise XOR
                            if (counter == addr_reg + 2) begin
                                mem_addr_reg <= addr_reg + 2;
                                mem_wdata_reg <= result_reg[31:0] ^ mem_rdata;
                                mem_wen_reg <= 1'b1;
                                mem_cen_reg <= 1'b1;
                            end
                        end
                    endcase
                end
                
                // -------------------------------------------------------------
                // SERIALIZER WAIT STATES: Wait for serializer to finish
                // -------------------------------------------------------------
                STATE_WAIT_SERIALIZER_DONE1: begin
                    result_valid_reg <= 1'b0;  // Clear result valid flag
                end
                
                STATE_WAIT_SERIALIZER_DONE2: begin
                    // Wait for serializer_busy signal to go low
                    // No actions needed here
                end
                
                // -------------------------------------------------------------
                // DONE STATE: Finalize operation and clear control signals
                // -------------------------------------------------------------
                STATE_DONE: begin
                    result_valid_reg <= 1'b0;  // Clear result valid
                    busy_reg <= 1'b0;          // Clear busy flag
                    mem_wen_reg <= 1'b0;       // Clear memory write enable
                    mem_cen_reg <= 1'b0;       // Clear memory chip enable
                end
            endcase
        end
    end
    
    // =========================================================================
    // NEXT STATE LOGIC - COMBINATIONAL PROCESS
    // =========================================================================
    always @(*) begin
        next_state = state;  // Default: stay in current state
        
        case (state)
            STATE_IDLE: 
                if (frame_valid) 
                    next_state = STATE_DECODE;
            
            STATE_DECODE: 
                next_state = STATE_EXECUTE;
            
            STATE_EXECUTE: 
                // Check if we need to continue execution or move to next state
                if ((cmd_reg == CMD_FILL0 || cmd_reg == CMD_FILL1) && 
                    counter < MAX_MEM_ADDR) 
                    next_state = STATE_EXECUTE;
                else if (cmd_reg == CMD_WRITE_INC && counter < MAX_MEM_ADDR)
                    next_state = STATE_EXECUTE;
                else if ((cmd_reg == CMD_ADD || cmd_reg == CMD_SUB || cmd_reg == CMD_MUL || 
                         cmd_reg == CMD_DIV || cmd_reg == CMD_AND || cmd_reg == CMD_OR || 
                         cmd_reg == CMD_XOR) && counter < addr_reg + 1)
                    next_state = STATE_EXECUTE;
                else
                    next_state = STATE_MEM_ACCESS;
            
            STATE_MEM_ACCESS: 
                next_state = STATE_WAIT;
            
            STATE_WAIT: 
                // Handle different command completion scenarios
                if (cmd_reg == CMD_READ_SEQ && counter <= MAX_MEM_ADDR && counter != 0)
                    next_state = STATE_WAIT_SERIALIZER_DONE1;
                else if ((cmd_reg == CMD_ADD || cmd_reg == CMD_SUB || cmd_reg == CMD_MUL || 
                         cmd_reg == CMD_DIV || cmd_reg == CMD_AND || cmd_reg == CMD_OR || 
                         cmd_reg == CMD_XOR) && counter == addr_reg + 2)
                    next_state = STATE_EXECUTE;
                else if (cmd_reg == CMD_MUL && counter == addr_reg + 3)
                    next_state = STATE_EXECUTE;
                else if (cmd_reg == CMD_DIV && counter == addr_reg + 3 && !error_reg)
                    next_state = STATE_EXECUTE;
                else
                    next_state = STATE_DONE;
            
            STATE_WAIT_SERIALIZER_DONE1:
                next_state = STATE_WAIT_SERIALIZER_DONE2;
            
            STATE_WAIT_SERIALIZER_DONE2:
                if (!serializer_busy)
                    next_state = STATE_EXECUTE;
            
            STATE_DONE: 
                next_state = STATE_IDLE;
                
            default:
                next_state = STATE_IDLE;
        endcase
    end
    
    // =========================================================================
    // OUTPUT ASSIGNMENTS
    // =========================================================================
    
    assign frame_ready = (state == STATE_IDLE);      // Ready when idle
    assign cmd_start = (state == STATE_DECODE);      // Command starts in decode state
    assign cmd_busy = busy_reg;                      // Controller busy flag
    assign cmd_result = result_reg[31:0];            // 32-bit result output
    assign cmd_result_valid = result_valid_reg;      // Result valid flag
    assign cmd_error = error_reg;                    // Error flag
    assign cmd_error_type = error_type_reg;          // Error type
    
    // Memory interface outputs
    assign mem_addr = mem_addr_reg;
    assign mem_wdata = mem_wdata_reg;
    assign mem_wen = mem_wen_reg;
    assign mem_cen = mem_cen_reg;

endmodule