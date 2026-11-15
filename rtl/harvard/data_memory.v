// ============================================================================
// Module: data_memory.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Vipul Sharma (2401010505)
// Description: Dedicated Data Memory (D-Mem) for Harvard Architecture.
//              Provides independent read and write ports for operand data,
//              enabling simultaneous data manipulation during instruction fetches.
//              Supports 4-bit byte enables for fine-grained byte/word writes.
// ============================================================================

`timescale 1ns / 1ps

module data_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256,       // 256 words = 1024 bytes
    parameter INIT_FILE  = ""         // Hex initialization file path
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  read_en,
    input  wire                  write_en,
    input  wire [3:0]            byte_en,      // Byte write masks [3:Byte3, 2:Byte2, 1:Byte1, 0:Byte0]
    input  wire [ADDR_WIDTH-1:0] addr,         // Byte address
    input  wire [DATA_WIDTH-1:0] write_data,   // Data to store
    output wire [DATA_WIDTH-1:0] read_data,    // Loaded data
    output reg                   ready         // Memory access ready acknowledgment
);

    // Memory array arranged as 4 byte-wide lanes for byte enables
    reg [7:0] mem_b0 [0:MEM_DEPTH-1];
    reg [7:0] mem_b1 [0:MEM_DEPTH-1];
    reg [7:0] mem_b2 [0:MEM_DEPTH-1];
    reg [7:0] mem_b3 [0:MEM_DEPTH-1];

    wire [$clog2(MEM_DEPTH)-1:0] word_idx;
    assign word_idx = addr[$clog2(MEM_DEPTH)+1:2];

    wire addr_valid;
    assign addr_valid = (addr < (MEM_DEPTH * 4));

    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem_b0[i] = 8'h00;
            mem_b1[i] = 8'h00;
            mem_b2[i] = 8'h00;
            mem_b3[i] = 8'h00;
        end
        // If an initial file is given, we can load word array
    end

    // Synchronous Write Operation with Byte Enables
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
        end else begin
            ready <= (read_en || write_en) && addr_valid;
            if (write_en && addr_valid) begin
                if (byte_en[0]) mem_b0[word_idx] <= write_data[7:0];
                if (byte_en[1]) mem_b1[word_idx] <= write_data[15:8];
                if (byte_en[2]) mem_b2[word_idx] <= write_data[23:16];
                if (byte_en[3]) mem_b3[word_idx] <= write_data[31:24];
            end
        end
    end

    // Combinational Read Operation (fast load path for single-cycle processor)
    assign read_data = (read_en && addr_valid) ? 
                       {mem_b3[word_idx], mem_b2[word_idx], mem_b1[word_idx], mem_b0[word_idx]} : 
                       32'h00000000;

endmodule
