// ============================================================================
// Module: harvard_top.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Vipul Sharma (2401010505)
// Description: Top-Level Harvard Architecture System.
//              Integrates independent Instruction Memory and Data Memory subsystems
//              with a RISC controller core. Demonstrates parallel, simultaneous
//              instruction fetch and data operand read/write without structural hazards.
// ============================================================================

`timescale 1ns / 1ps

module harvard_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter IMEM_DEPTH = 256,
    parameter DMEM_DEPTH = 256,
    parameter IMEM_INIT  = "",
    parameter DMEM_INIT  = ""
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Status and Telemetry
    output wire                  halted,
    output wire [31:0]           cycle_count,
    output wire [31:0]           instr_count,
    output wire [31:0]           simultaneous_access_count,
    output wire [31:0]           mmio_leds,
    output wire [31:0]           mmio_out_char,
    output wire                  proc_fault,

    // Probe buses for simulation inspection
    output wire [ADDR_WIDTH-1:0] probe_pc,
    output wire [DATA_WIDTH-1:0] probe_instruction,
    output wire                  probe_data_req,
    output wire                  probe_data_we,
    output wire [ADDR_WIDTH-1:0] probe_data_addr,
    output wire [DATA_WIDTH-1:0] probe_data_wdata,
    output wire [DATA_WIDTH-1:0] probe_data_rdata
);

    // Instruction bus wires
    wire [ADDR_WIDTH-1:0] instr_addr;
    wire                  instr_read_en;
    wire [DATA_WIDTH-1:0] instruction;
    wire                  imem_ready;

    // Data bus wires (Processor to Controller)
    wire                  data_req;
    wire                  data_we;
    wire [3:0]            data_be;
    wire [ADDR_WIDTH-1:0] data_addr;
    wire [DATA_WIDTH-1:0] data_wdata;
    wire [DATA_WIDTH-1:0] data_rdata;
    wire                  data_ready;

    // SRAM interface wires (Controller to Data Memory)
    wire                  sram_cs;
    wire                  sram_we;
    wire [3:0]            sram_be;
    wire [ADDR_WIDTH-1:0] sram_addr;
    wire [DATA_WIDTH-1:0] sram_wdata;
    wire [DATA_WIDTH-1:0] sram_rdata;
    wire                  sram_ready;

    // Probe assignments
    assign probe_pc          = instr_addr;
    assign probe_instruction = instruction;
    assign probe_data_req    = data_req;
    assign probe_data_we     = data_we;
    assign probe_data_addr   = data_addr;
    assign probe_data_wdata  = data_wdata;
    assign probe_data_rdata  = data_rdata;

    // 1. Processor Core Instance
    simple_processor #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .instr_addr(instr_addr),
        .instr_read_en(instr_read_en),
        .instruction(instruction),
        .data_req(data_req),
        .data_we(data_we),
        .data_be(data_be),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .data_rdata(data_rdata),
        .data_ready(data_ready),
        .external_stall(1'b0), // No stalls in pure Harvard architecture!
        .halted(halted),
        .cycle_count(cycle_count),
        .instr_count(instr_count),
        .simultaneous_access_count(simultaneous_access_count)
    );

    // 2. Dedicated Instruction Memory (I-Mem)
    instruction_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(IMEM_DEPTH),
        .INIT_FILE(IMEM_INIT)
    ) u_imem (
        .clk(clk),
        .rst_n(rst_n),
        .read_en(instr_read_en),
        .addr(instr_addr),
        .instruction(instruction),
        .ready(imem_ready)
    );

    // 3. Memory Controller (Address Decoding & MMIO)
    memory_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_mem_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .proc_req(data_req),
        .proc_we(data_we),
        .proc_be(data_be),
        .proc_addr(data_addr),
        .proc_wdata(data_wdata),
        .proc_rdata(data_rdata),
        .proc_ready(data_ready),
        .proc_fault(proc_fault),
        .sram_cs(sram_cs),
        .sram_we(sram_we),
        .sram_be(sram_be),
        .sram_addr(sram_addr),
        .sram_wdata(sram_wdata),
        .sram_rdata(sram_rdata),
        .sram_ready(sram_ready),
        .mmio_leds(mmio_leds),
        .mmio_out_char(mmio_out_char)
    );

    // 4. Dedicated Data Memory (D-Mem)
    data_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(DMEM_DEPTH),
        .INIT_FILE(DMEM_INIT)
    ) u_dmem (
        .clk(clk),
        .rst_n(rst_n),
        .read_en(sram_cs && !sram_we),
        .write_en(sram_cs && sram_we),
        .byte_en(sram_be),
        .addr(sram_addr),
        .write_data(sram_wdata),
        .read_data(sram_rdata),
        .ready(sram_ready)
    );

endmodule
