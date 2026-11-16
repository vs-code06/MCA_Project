// ============================================================================
// Module: shared_memory_top.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Aditya Kumar (2401010029)
// Description: Shared-Memory (Von Neumann) Architecture Baseline.
//              Contains a single unified physical memory array for both instructions
//              and data. Employs a bus arbiter that detects data access instructions
//              and stalls the CPU for 1 cycle to time-multiplex the shared memory bus.
// ============================================================================

`timescale 1ns / 1ps

module shared_memory_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 512,        // Unified memory: holds both code and data
    parameter INIT_FILE  = ""
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Status and Telemetry
    output wire                  halted,
    output wire [31:0]           cycle_count,
    output wire [31:0]           instr_count,
    output reg  [31:0]           stall_cycles_count,
    output wire [31:0]           mmio_leds,
    output wire [31:0]           mmio_out_char,
    output wire                  proc_fault,

    // Shared bus probe
    output wire [ADDR_WIDTH-1:0] shared_bus_addr,
    output wire [DATA_WIDTH-1:0] shared_bus_wdata,
    output wire                  shared_bus_we
);

    // Processor interfaces
    wire [ADDR_WIDTH-1:0] instr_addr;
    wire                  instr_read_en;
    wire [DATA_WIDTH-1:0] instruction_to_cpu;

    wire                  data_req;
    wire                  data_we;
    wire [3:0]            data_be;
    wire [ADDR_WIDTH-1:0] data_addr;
    wire [DATA_WIDTH-1:0] data_wdata;
    wire [DATA_WIDTH-1:0] data_rdata;
    wire                  data_ready;

    // Arbiter control
    wire bus_select_data;
    wire cpu_stall;

    // Unified Physical Memory
    reg [DATA_WIDTH-1:0] unified_mem [0:MEM_DEPTH-1];

    // Muxed shared memory bus signals
    wire [ADDR_WIDTH-1:0] active_addr  = bus_select_data ? data_addr : instr_addr;
    wire [DATA_WIDTH-1:0] active_wdata = data_wdata;
    wire                  active_we    = bus_select_data && data_we;
    wire                  active_req   = bus_select_data ? data_req : instr_read_en;

    assign shared_bus_addr  = active_addr;
    assign shared_bus_wdata = active_wdata;
    assign shared_bus_we    = active_we;

    wire [$clog2(MEM_DEPTH)-1:0] word_idx = active_addr[$clog2(MEM_DEPTH)+1:2];
    wire addr_valid = (active_addr < (MEM_DEPTH * 4));

    // Memory initialization
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            unified_mem[i] = 32'h00000013; // default NOP
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, unified_mem);
        end
    end

    // Memory write
    always @(posedge clk) begin
        if (active_we && addr_valid) begin
            unified_mem[word_idx] <= active_wdata;
        end
    end

    // Memory read
    wire [DATA_WIDTH-1:0] mem_rdata = (active_req && addr_valid) ? unified_mem[word_idx] : 32'd0;

    // Instruction Register to hold instruction during stall / Phase 2
    reg [DATA_WIDTH-1:0] held_instr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            held_instr <= 32'h00000013;
        end else if (!bus_select_data) begin
            held_instr <= mem_rdata;
        end
    end

    assign instruction_to_cpu = bus_select_data ? held_instr : mem_rdata;
    assign data_rdata         = bus_select_data ? mem_rdata : 32'd0;
    assign data_ready         = bus_select_data;

    // Arbiter Instance
    arbiter u_arbiter (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(instruction_to_cpu[31:26]),
        .halted(halted),
        .bus_select_data(bus_select_data),
        .cpu_stall(cpu_stall)
    );

    // Track total stall cycles
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stall_cycles_count <= 32'd0;
        end else if (!halted && cpu_stall) begin
            stall_cycles_count <= stall_cycles_count + 32'd1;
        end
    end

    // Processor Core Instance
    simple_processor #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .instr_addr(instr_addr),
        .instr_read_en(instr_read_en),
        .instruction(instruction_to_cpu),
        .data_req(data_req),
        .data_we(data_we),
        .data_be(data_be),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .data_rdata(data_rdata),
        .data_ready(data_ready),
        .external_stall(cpu_stall),
        .halted(halted),
        .cycle_count(cycle_count),
        .instr_count(instr_count),
        .simultaneous_access_count() // Zero simultaneous accesses possible on unified memory
    );

    assign mmio_leds     = 32'd0;
    assign mmio_out_char = 32'd0;
    assign proc_fault    = 1'b0;

endmodule
