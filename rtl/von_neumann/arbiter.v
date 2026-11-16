// ============================================================================
// Module: arbiter.v (Refined)
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Aditya Kumar (2401010029)
// Description: Multi-cycle Shared-Bus Arbiter for Von Neumann Architecture.
//              Handles the Von Neumann structural hazard:
//              When a memory-access instruction (LOAD/STORE) is fetched,
//              it captures the instruction, yields the bus to data access in
//              Phase 2, and stalls the PC for 1 cycle.
// ============================================================================

`timescale 1ns / 1ps

module arbiter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [5:0]  opcode,          // Current instruction opcode
    input  wire        halted,
    output reg         bus_select_data, // 0 = Instruction Fetch, 1 = Data Access
    output reg         cpu_stall        // 1 = Stall processor PC & state advance
);

    // State 0: FETCH/EXECUTE
    // State 1: MEMORY_ACCESS (Stall cycle for LOAD/STORE)
    reg state;
    localparam S_FETCH = 1'b0;
    localparam S_MEM   = 1'b1;

    wire is_mem_instr = (opcode == 6'h08 || opcode == 6'h09); // LOAD or STORE

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_FETCH;
        end else if (!halted) begin
            case (state)
                S_FETCH: begin
                    if (is_mem_instr) begin
                        // Transition to Phase 2 for data access
                        state <= S_MEM;
                    end else begin
                        state <= S_FETCH;
                    end
                end
                S_MEM: begin
                    // After servicing memory access, return to instruction fetch
                    state <= S_FETCH;
                end
            endcase
        end
    end

    always @(*) begin
        case (state)
            S_FETCH: begin
                // In fetch state, bus is used for instruction fetch
                bus_select_data = 1'b0;
                cpu_stall       = is_mem_instr; // Assert stall if this instruction needs a 2nd cycle
            end
            S_MEM: begin
                // In memory state, bus is given to data read/write
                bus_select_data = 1'b1;
                cpu_stall       = 1'b0; // Release stall so execution finishes
            end
            default: begin
                bus_select_data = 1'b0;
                cpu_stall       = 1'b0;
            end
        endcase
    end

endmodule
