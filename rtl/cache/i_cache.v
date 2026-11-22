// ============================================================================
// Module: i_cache.v
// Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
// Team: Decoders07
// Team Member: Anant Jain (2401010066)
// Description: Direct-Mapped Level-1 Instruction Cache (L1 I-Cache).
//              Directly indexes 16 cache lines. Tag comparison is combinational,
//              providing single-cycle instruction delivery on hit.
// ============================================================================

`timescale 1ns / 1ps

module i_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_LINES  = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Core Interface
    input  wire [ADDR_WIDTH-1:0] cpu_addr,
    input  wire                  cpu_req,
    output reg  [DATA_WIDTH-1:0] cpu_instruction,
    output wire                  cpu_hit,
    output wire                  cpu_stall,

    // Main Memory Interface
    output reg                   mem_req,
    output reg  [ADDR_WIDTH-1:0] mem_addr,
    input  wire                  mem_ready,
    input  wire [DATA_WIDTH-1:0] mem_rdata,

    // Performance Telemetry
    output reg  [31:0]           hit_count,
    output reg  [31:0]           miss_count,
    output reg  [31:0]           access_count
);

    localparam INDEX_WIDTH = $clog2(NUM_LINES);
    localparam OFFSET_BITS = 2;
    localparam TAG_WIDTH   = ADDR_WIDTH - INDEX_WIDTH - OFFSET_BITS;

    wire [INDEX_WIDTH-1:0] line_index = cpu_addr[INDEX_WIDTH+OFFSET_BITS-1:OFFSET_BITS];
    wire [TAG_WIDTH-1:0]   line_tag   = cpu_addr[ADDR_WIDTH-1:INDEX_WIDTH+OFFSET_BITS];

    reg                  valid_array [0:NUM_LINES-1];
    reg [TAG_WIDTH-1:0]  tag_array   [0:NUM_LINES-1];
    reg [DATA_WIDTH-1:0] data_array  [0:NUM_LINES-1];

    wire tag_match = (valid_array[line_index] == 1'b1) && (tag_array[line_index] == line_tag);
    assign cpu_hit = tag_match && cpu_req;
    assign cpu_stall = !tag_match && cpu_req;

    always @(*) begin
        if (tag_match) begin
            cpu_instruction = data_array[line_index];
        end else begin
            cpu_instruction = 32'h00000013; // NOP
        end
    end

endmodule
