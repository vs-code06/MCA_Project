// ============================================================================
// Module: instruction_memory.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Anant Jain (2401010066)
// Description: Dedicated Instruction Memory (I-Mem) for Harvard Architecture.
//              Provides conflict-free instruction fetching parallel to data accesses.
//              Supports word-aligned addressing and hexadecimal initialization.
// ============================================================================

`timescale 1ns / 1ps

module instruction_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256,       // 256 words = 1024 bytes
    parameter INIT_FILE  = ""         // Hex initialization file path
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  read_en,
    input  wire [ADDR_WIDTH-1:0] addr,         // Byte address from PC
    output wire [DATA_WIDTH-1:0] instruction,  // Fetched 32-bit instruction
    output reg                   ready         // Memory ready handshake
);

    // Internal memory array (word-addressed: 32-bit wide)
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    // Word index derived from byte address (addr >> 2)
    wire [$clog2(MEM_DEPTH)-1:0] word_idx;
    assign word_idx = addr[$clog2(MEM_DEPTH)+1:2];

    integer i;
    initial begin
        // Default clear memory
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h00000013; // Default NOP (RISC-V style: addi x0, x0, 0)
        end
        // If an initialization file is specified, load it
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // Instruction output: combinational read for single-cycle controller,
    // with ready flag assertion.
    assign instruction = (read_en && (addr < (MEM_DEPTH * 4))) ? mem[word_idx] : 32'h00000000;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
        end else begin
            ready <= read_en;
        end
    end

endmodule
