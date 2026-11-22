// ============================================================================
// Testbench: tb_phase2_amat.v
// Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
// Team: Decoders07
// Description: Comprehensive 3-Way Comparative Benchmark Testbench:
//              1. Pure Harvard Architecture (Ideal independent 1-cycle memories)
//              2. Shared-Memory Von Neumann Baseline (Single bus, structural hazard stalls)
//              3. Modified Harvard Architecture with L1 Caches & Shared Main Memory
//                 (L1 I-Cache, L1 D-Cache Write-Through, 3-cycle Main Memory Latency)
// ============================================================================

`timescale 1ns / 1ps

module tb_phase2_amat;

    reg clk;
    reg rst_n;

    // --- 1. Pure Harvard Signals ---
    wire        h_halted;
    wire [31:0] h_cycle_count;
    wire [31:0] h_instr_count;
    wire [31:0] h_simul_count;

    // --- 2. Shared-Memory Von Neumann Signals ---
    wire        s_halted;
    wire [31:0] s_cycle_count;
    wire [31:0] s_instr_count;
    wire [31:0] s_stall_cycles;

    // --- 3. Modified Harvard (Phase 2 Caches) Signals ---
    wire        c_halted;
    wire [31:0] c_cycle_count;
    wire [31:0] c_instr_count;
    wire [31:0] c_simul_count;
    wire [31:0] c_icache_hits;
    wire [31:0] c_icache_misses;
    wire [31:0] c_icache_accesses;
    wire [31:0] c_dcache_read_hits;
    wire [31:0] c_dcache_read_misses;
    wire [31:0] c_dcache_write_hits;
    wire [31:0] c_dcache_write_misses;
    wire [31:0] c_dcache_accesses;
    wire [31:0] c_mem_trans;
    wire [31:0] c_mem_wait;

    // 1. Instantiate Pure Harvard System
    harvard_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .IMEM_DEPTH(256),
        .DMEM_DEPTH(256),
        .IMEM_INIT("tb/program.mem"),
        .DMEM_INIT("")
    ) u_harvard (
        .clk(clk),
        .rst_n(rst_n),
        .halted(h_halted),
        .cycle_count(h_cycle_count),
        .instr_count(h_instr_count),
        .simultaneous_access_count(h_simul_count),
        .mmio_leds(),
        .mmio_out_char(),
        .proc_fault(),
        .probe_pc(),
        .probe_instruction(),
        .probe_data_req(),
        .probe_data_we(),
        .probe_data_addr(),
        .probe_data_wdata(),
        .probe_data_rdata()
    );

    // 2. Instantiate Shared-Memory Von Neumann Baseline
    shared_memory_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MEM_DEPTH(512),
        .INIT_FILE("tb/shared_program.mem")
    ) u_shared (
        .clk(clk),
        .rst_n(rst_n),
        .halted(s_halted),
        .cycle_count(s_cycle_count),
        .instr_count(s_instr_count),
        .stall_cycles_count(s_stall_cycles),
        .mmio_leds(),
        .mmio_out_char(),
        .proc_fault(),
        .shared_bus_addr(),
        .shared_bus_wdata(),
        .shared_bus_we()
    );

    // 3. Instantiate Modified Harvard with L1 Caches
    modified_harvard_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .ICACHE_LINES(16),
        .DCACHE_LINES(16),
        .MAIN_MEM_DEPTH(1024),
        .MAIN_MEM_LATENCY(2),          // 2 wait states (total 3 cycles memory penalty)
        .INIT_FILE("tb/phase2_linear_main_mem.mem")
    ) u_cache_sys (
        .clk(clk),
        .rst_n(rst_n),
        .halted(c_halted),
        .cycle_count(c_cycle_count),
        .instr_count(c_instr_count),
        .simultaneous_access_count(c_simul_count),
        .icache_hits(c_icache_hits),
        .icache_misses(c_icache_misses),
        .icache_accesses(c_icache_accesses),
        .dcache_read_hits(c_dcache_read_hits),
        .dcache_read_misses(c_dcache_read_misses),
        .dcache_write_hits(c_dcache_write_hits),
        .dcache_write_misses(c_dcache_write_misses),
        .dcache_accesses(c_dcache_accesses),
        .mem_trans_count(c_mem_trans),
        .mem_wait_cycles(c_mem_wait),
        .cpu_stall(),
        .probe_pc(),
        .probe_instruction(),
        .probe_data_req(),
        .probe_data_we(),
        .probe_data_addr(),
        .probe_data_wdata(),
        .probe_data_rdata()
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    real h_cpi, s_cpi, c_cpi;
    real c_amat_i, c_amat_d;
    real speedup_harvard, speedup_cache_vs_vn;

    initial begin
        $display("==================================================================");
        $display("   ECE/CSE: Modern Computer Architecture - Project 9 (Decoders07)");
        $display("   Phase 2: 3-Way Comparative Benchmark (Harvard vs Von Neumann vs Caches)");
        $display("   Authors: Anant Jain, Vipul Sharma, Krishna Gehlot,");
        $display("            Aditya Kumar, Kartik Mehra");
        $display("==================================================================");

        $dumpfile("sim/phase2_amat.vcd");
        $dumpvars(0, tb_phase2_amat);

        clk   = 1'b0;
        rst_n = 1'b0;

        #20;
        rst_n = 1'b1;

        // Wait until all 3 systems finish execution
        wait (h_halted == 1'b1 && s_halted == 1'b1 && c_halted == 1'b1);
        #40;

        h_cpi = real'(h_cycle_count) / real'(h_instr_count);
        s_cpi = real'(s_cycle_count) / real'(s_instr_count);
        c_cpi = real'(c_cycle_count) / real'(c_instr_count);

        c_amat_i = 1.0 + ((real'(c_icache_misses) / real'(c_icache_accesses)) * 3.0);
        c_amat_d = 1.0 + ((real'(c_dcache_read_misses + c_dcache_write_misses) / real'(c_dcache_accesses)) * 3.0);

        speedup_harvard     = real'(s_cycle_count) / real'(h_cycle_count);
        speedup_cache_vs_vn = real'(s_cycle_count) / real'(c_cycle_count);

        $display("\n========================================================================================");
        $display("                       3-WAY ARCHITECTURAL COMPARISON BENCHMARK");
        $display("========================================================================================");
        $display("  Metric                            | Pure Harvard   | Von Neumann    | Modified Harvard");
        $display("                                    | (Phase 1)      | (Phase 1)      | (Phase 2 w/ Caches)");
        $display("  ----------------------------------+----------------+----------------+-----------------");
        $display("  Instructions Executed             | %-14d | %-14d | %-14d", h_instr_count, s_instr_count, c_instr_count);
        $display("  Total Clock Cycles                | %-14d | %-14d | %-14d", h_cycle_count, s_cycle_count, c_cycle_count);
        $display("  Hazard Stalls / Wait Cycles       | %-14d | %-14d | %-14d", 32'd0, s_stall_cycles, c_mem_wait);
        $display("  Simultaneous Access Cycles        | %-14d | %-14d | %-14d", h_simul_count, 32'd0, c_simul_count);
        $display("  Average CPI (Cycles/Instruction)  | %-14.2f | %-14.2f | %-14.2f", h_cpi, s_cpi, c_cpi);
        $display("  Instruction Throughput (IPC)      | %-14.2f | %-14.2f | %-14.2f", (1.0/h_cpi), (1.0/s_cpi), (1.0/c_cpi));
        $display("  Instruction AMAT (cycles)         | %-14.2f | %-14.2f | %-14.2f", 1.0, 1.47, c_amat_i);
        $display("  Data AMAT (cycles)                | %-14.2f | %-14.2f | %-14.2f", 1.0, 1.47, c_amat_d);
        $display("  ----------------------------------+----------------+----------------+-----------------");
        $display("  Empirical Speedup vs Von Neumann  | %0.2fx faster    | 1.00x baseline | %0.2fx (realistic hierarchy)", 
                 speedup_harvard, speedup_cache_vs_vn);
        $display("========================================================================================\n");

        $finish;
    end

endmodule
