// ============================================================================
// Module: modified_harvard_top.v
// Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
// Team: Decoders07
// Description: Top-Level Modified Harvard Architecture System.
//              Integrates:
//              1. RISC Controller Core (simple_processor.v)
//              2. L1 Instruction Cache (i_cache.v)
//              3. L1 Data Cache (d_cache.v, Write-Through)
//              4. Multi-Cycle Shared Main Memory (main_memory.v)
//              Demonstrates realistic memory hierarchy latency, cold misses,
//              high loop hit rates, and AMAT (Average Memory Access Time) metrics.
// ============================================================================

`timescale 1ns / 1ps

module modified_harvard_top #(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter ICACHE_LINES = 16,
    parameter DCACHE_LINES = 16,
    parameter MAIN_MEM_DEPTH = 1024,
    parameter MAIN_MEM_LATENCY = 2,
    parameter INIT_FILE    = ""
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Status and Telemetry
    output wire                  halted,
    output wire [31:0]           cycle_count,
    output wire [31:0]           instr_count,
    output wire [31:0]           simultaneous_access_count,

    // I-Cache Performance Metrics
    output wire [31:0]           icache_hits,
    output wire [31:0]           icache_misses,
    output wire [31:0]           icache_accesses,

    // D-Cache Performance Metrics
    output wire [31:0]           dcache_read_hits,
    output wire [31:0]           dcache_read_misses,
    output wire [31:0]           dcache_write_hits,
    output wire [31:0]           dcache_write_misses,
    output wire [31:0]           dcache_accesses,

    // Main Memory Telemetry
    output wire [31:0]           mem_trans_count,
    output wire [31:0]           mem_wait_cycles,

    // Overall CPU Stall Status
    output wire                  cpu_stall,

    // Diagnostic Probes
    output wire [ADDR_WIDTH-1:0] probe_pc,
    output wire [DATA_WIDTH-1:0] probe_instruction,
    output wire                  probe_data_req,
    output wire                  probe_data_we,
    output wire [ADDR_WIDTH-1:0] probe_data_addr,
    output wire [DATA_WIDTH-1:0] probe_data_wdata,
    output wire [DATA_WIDTH-1:0] probe_data_rdata
);

    // CPU Interconnect Wires
    wire [ADDR_WIDTH-1:0] cpu_pc;
    wire                  cpu_instr_read_en;
    wire [DATA_WIDTH-1:0] cpu_instruction;

    wire                  cpu_data_req;
    wire                  cpu_data_we;
    wire [3:0]            cpu_data_be;
    wire [ADDR_WIDTH-1:0] cpu_data_addr;
    wire [DATA_WIDTH-1:0] cpu_data_wdata;
    wire [DATA_WIDTH-1:0] cpu_data_rdata;
    wire                  cpu_data_ready;

    // Cache Stalls
    wire                  icache_stall;
    wire                  dcache_stall;
    wire                  icache_hit;
    wire                  dcache_hit;

    // Composite CPU Stall: Processor freezes if either cache experiences a miss/busy state
    assign cpu_stall = icache_stall || dcache_stall;

    // Main Memory Wires
    wire                  mem_ireq;
    wire [ADDR_WIDTH-1:0] mem_iaddr;
    wire                  mem_iready;
    wire [DATA_WIDTH-1:0] mem_irdata;

    wire                  mem_dreq;
    wire                  mem_dwe;
    wire [3:0]            mem_dbe;
    wire [ADDR_WIDTH-1:0] mem_daddr;
    wire [DATA_WIDTH-1:0] mem_dwdata;
    wire                  mem_dready;
    wire [DATA_WIDTH-1:0] mem_drdata;

    // Probe Assignments
    assign probe_pc           = cpu_pc;
    assign probe_instruction  = cpu_instruction;
    assign probe_data_req     = cpu_data_req;
    assign probe_data_we      = cpu_data_we;
    assign probe_data_addr    = cpu_data_addr;
    assign probe_data_wdata   = cpu_data_wdata;
    assign probe_data_rdata   = cpu_data_rdata;

    // 1. Instantiate RISC Processor Core
    simple_processor #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .instr_addr(cpu_pc),
        .instr_read_en(cpu_instr_read_en),
        .instruction(cpu_instruction),
        .data_req(cpu_data_req),
        .data_we(cpu_data_we),
        .data_be(cpu_data_be),
        .data_addr(cpu_data_addr),
        .data_wdata(cpu_data_wdata),
        .data_rdata(cpu_data_rdata),
        .data_ready(cpu_data_ready),
        .external_stall(cpu_stall),
        .halted(halted),
        .cycle_count(cycle_count),
        .instr_count(instr_count),
        .simultaneous_access_count(simultaneous_access_count)
    );

    // 2. Instantiate Level-1 Instruction Cache (L1 I-Cache)
    i_cache #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_LINES(ICACHE_LINES)
    ) u_icache (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_pc),
        .cpu_req(cpu_instr_read_en && !halted),
        .cpu_instruction(cpu_instruction),
        .cpu_hit(icache_hit),
        .cpu_stall(icache_stall),
        .mem_req(mem_ireq),
        .mem_addr(mem_iaddr),
        .mem_ready(mem_iready),
        .mem_rdata(mem_irdata),
        .hit_count(icache_hits),
        .miss_count(icache_misses),
        .access_count(icache_accesses)
    );

    // 3. Instantiate Level-1 Data Cache (L1 D-Cache)
    d_cache #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_LINES(DCACHE_LINES)
    ) u_dcache (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_data_addr),
        .cpu_req(cpu_data_req && !halted),
        .cpu_we(cpu_data_we),
        .cpu_be(cpu_data_be),
        .cpu_wdata(cpu_data_wdata),
        .cpu_rdata(cpu_data_rdata),
        .cpu_hit(dcache_hit),
        .cpu_stall(dcache_stall),
        .cpu_ready(cpu_data_ready),
        .mem_req(mem_dreq),
        .mem_we(mem_dwe),
        .mem_be(mem_dbe),
        .mem_addr(mem_daddr),
        .mem_wdata(mem_dwdata),
        .mem_ready(mem_dready),
        .mem_rdata(mem_drdata),
        .read_hit_count(dcache_read_hits),
        .read_miss_count(dcache_read_misses),
        .write_hit_count(dcache_write_hits),
        .write_miss_count(dcache_write_misses),
        .access_count(dcache_accesses)
    );

    // 4. Instantiate Shared Multi-Cycle Main Memory
    main_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(MAIN_MEM_DEPTH),
        .LATENCY(MAIN_MEM_LATENCY),
        .INIT_FILE(INIT_FILE)
    ) u_main_mem (
        .clk(clk),
        .rst_n(rst_n),
        .icache_req(mem_ireq),
        .icache_addr(mem_iaddr),
        .icache_ready(mem_iready),
        .icache_rdata(mem_irdata),
        .dcache_req(mem_dreq),
        .dcache_we(mem_dwe),
        .dcache_be(mem_dbe),
        .dcache_addr(mem_daddr),
        .dcache_wdata(mem_dwdata),
        .dcache_ready(mem_dready),
        .dcache_rdata(mem_drdata),
        .total_trans_count(mem_trans_count),
        .total_wait_cycles(mem_wait_cycles)
    );

endmodule
