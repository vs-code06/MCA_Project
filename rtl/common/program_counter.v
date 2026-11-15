// ============================================================================
// Module: program_counter.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Anant Jain (2401010066)
// Description: Program Counter (PC) module for the Harvard Architecture.
//              Generates sequential 32-bit instruction addresses (increment by 4)
//              with support for branch/jump redirection and pipeline stall.
// ============================================================================

`timescale 1ns / 1ps

module program_counter #(
    parameter ADDR_WIDTH = 32,
    parameter RESET_ADDR = 32'h0000_0000
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  pc_en,        // Clock enable for PC advancement
    input  wire                  stall,        // Freeze PC when stalled
    input  wire                  jump_en,      // Redirection / Branch enable
    input  wire [ADDR_WIDTH-1:0] jump_addr,    // Target address for branch/jump
    output reg  [ADDR_WIDTH-1:0] pc,           // Current Program Counter
    output wire [ADDR_WIDTH-1:0] pc_plus_4     // Next sequential address
);

    assign pc_plus_4 = pc + 32'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= RESET_ADDR;
        end else if (pc_en && !stall) begin
            if (jump_en) begin
                pc <= jump_addr;
            end else begin
                pc <= pc_plus_4;
            end
        end
    end

endmodule
