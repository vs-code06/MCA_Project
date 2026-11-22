// ============================================================================
// Module: main_memory.v
// Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
// Team: Decoders07
// Team Member: Krishna Gehlot (2401010236)
// Description: Multi-Cycle Shared Main Memory Subsystem.
//              Provides backing physical memory array with configurable
//              wait-state latency counter to simulate memory wall penalty.
// ============================================================================

`timescale 1ns / 1ps

module main_memory #(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter MEM_DEPTH    = 1024,
    parameter LATENCY      = 2,
    parameter INIT_FILE    = ""
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // I-Cache Port (Read Only)
    input  wire                  icache_req,
    input  wire [ADDR_WIDTH-1:0] icache_addr,
    output reg                   icache_ready,
    output wire [DATA_WIDTH-1:0] icache_rdata,

    // D-Cache Port (Read / Write)
    input  wire                  dcache_req,
    input  wire                  dcache_we,
    input  wire [3:0]            dcache_be,
    input  wire [ADDR_WIDTH-1:0] dcache_addr,
    input  wire [DATA_WIDTH-1:0] dcache_wdata,
    output reg                   dcache_ready,
    output wire [DATA_WIDTH-1:0] dcache_rdata,

    // Telemetry
    output reg  [31:0]           total_trans_count,
    output reg  [31:0]           total_wait_cycles
);

    reg [DATA_WIDTH-1:0] mem_array [0:MEM_DEPTH-1];
    reg [ADDR_WIDTH-1:0] active_addr;
    wire [$clog2(MEM_DEPTH)-1:0] word_idx = active_addr[$clog2(MEM_DEPTH)+1:2];
    assign icache_rdata = mem_array[word_idx];
    assign dcache_rdata = mem_array[word_idx];

    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem_array[i] = 32'h00000013;
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem_array);
        end
    end

endmodule
