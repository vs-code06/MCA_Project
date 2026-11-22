// ============================================================================
// Testbench: tb_cache_system.v
// Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
// Team: Decoders07
// Description: Verification testbench for Level-1 Cache Subsystems in Modified
//              Harvard Architecture. Tests compulsory (cold) misses, iterative
//              loop hit behavior, write-through integrity, self-checking assertions,
//              and computes empirical AMAT (Average Memory Access Time).
// ============================================================================

`timescale 1ns / 1ps

module tb_cache_system;

    reg clk;
    reg rst_n;

    // Status and Telemetry Wires
    wire        halted;
    wire [31:0] cycle_count;
    wire [31:0] instr_count;
    wire [31:0] simultaneous_access_count;

    wire [31:0] icache_hits;
    wire [31:0] icache_misses;
    wire [31:0] icache_accesses;

    wire [31:0] dcache_read_hits;
    wire [31:0] dcache_read_misses;
    wire [31:0] dcache_write_hits;
    wire [31:0] dcache_write_misses;
    wire [31:0] dcache_accesses;

    wire [31:0] mem_trans_count;
    wire [31:0] mem_wait_cycles;
    wire        cpu_stall;

    wire [31:0] probe_pc;
    wire [31:0] probe_instruction;
    wire        probe_data_req;
    wire        probe_data_we;
    wire [31:0] probe_data_addr;
    wire [31:0] probe_data_wdata;
    wire [31:0] probe_data_rdata;

    // Instantiate Top-Level Modified Harvard System
    modified_harvard_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .ICACHE_LINES(16),
        .DCACHE_LINES(16),
        .MAIN_MEM_DEPTH(1024),
        .MAIN_MEM_LATENCY(2),          // 2 wait states (total 3 cycles per memory access)
        .INIT_FILE("tb/phase2_loop_main_mem.mem")
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .halted(halted),
        .cycle_count(cycle_count),
        .instr_count(instr_count),
        .simultaneous_access_count(simultaneous_access_count),
        .icache_hits(icache_hits),
        .icache_misses(icache_misses),
        .icache_accesses(icache_accesses),
        .dcache_read_hits(dcache_read_hits),
        .dcache_read_misses(dcache_read_misses),
        .dcache_write_hits(dcache_write_hits),
        .dcache_write_misses(dcache_write_misses),
        .dcache_accesses(dcache_accesses),
        .mem_trans_count(mem_trans_count),
        .mem_wait_cycles(mem_wait_cycles),
        .cpu_stall(cpu_stall),
        .probe_pc(probe_pc),
        .probe_instruction(probe_instruction),
        .probe_data_req(probe_data_req),
        .probe_data_we(probe_data_we),
        .probe_data_addr(probe_data_addr),
        .probe_data_wdata(probe_data_wdata),
        .probe_data_rdata(probe_data_rdata)
    );

    // 100 MHz Clock Generation (10 ns period)
    always #5 clk = ~clk;

    // Real-time trace logger
    always @(posedge clk) begin
        if (rst_n && !halted) begin
            $display("[Cycle %02d | Time %0t ps] PC=0x%08X | Instr=0x%08X | Stall=%b | DReq=%b WE=%b Addr=0x%08X WData=0x%08X | IHits=%0d IMiss=%0d DHits=%0d",
                cycle_count, $time, probe_pc, probe_instruction, cpu_stall,
                probe_data_req, probe_data_we, probe_data_addr, probe_data_wdata,
                icache_hits, icache_misses, (dcache_read_hits + dcache_write_hits)
            );
        end
    end

    // Real calculations for floating-point AMAT display
    real i_hit_rate, i_miss_rate, amat_i;
    real d_hit_rate, d_miss_rate, amat_d;
    real avg_cpi;

    initial begin
        $display("==================================================================");
        $display("  ECE/CSE: Modern Computer Architecture - Project 9 (Decoders07)");
        $display("  Phase 2: L1 Cache Hierarchy & AMAT Verification");
        $display("  Authors: Anant Jain, Vipul Sharma, Krishna Gehlot,");
        $display("           Aditya Kumar, Kartik Mehra");
        $display("==================================================================");

        $dumpfile("sim/phase2_cache.vcd");
        $dumpvars(0, tb_cache_system);

        clk   = 1'b0;
        rst_n = 1'b0;

        #20;
        rst_n = 1'b1;
        $display("[INFO] System released from reset at %0t ps", $time);

        // Wait until processor halts or timeout
        fork : wait_or_timeout
            begin
                wait (halted == 1'b1);
                $display("\n[INFO] Processor HALT executed at %0t ps!", $time);
                disable wait_or_timeout;
            end
            begin
                #1000000; // 1 us timeout
                $display("\n[ERROR] Simulation timeout reached at %0t ps!", $time);
                $finish;
            end
        join

        #20;

        // ====================================================================
        // Self-Checking Verification Assertions
        // ====================================================================
        $display("\n==================================================================");
        $display("             PHASE 2 HARDWARE VERIFICATION RESULTS");
        $display("==================================================================");

        // Final accumulated sum at Mem[0x100] and Mem[0x104]
        // Triangular sum 5+4+3+2+1 = 15
        if (u_dut.u_main_mem.mem_array[32'h0000_0100 >> 2] == 32'd15) begin
            $display("  [PASS] Main Memory[0x0000_0100] (Running Sum) = %0d (Expected: 15)", 
                     u_dut.u_main_mem.mem_array[32'h0000_0100 >> 2]);
        end else begin
            $display("  [FAIL] Main Memory[0x0000_0100] = %0d (Expected: 15)", 
                     u_dut.u_main_mem.mem_array[32'h0000_0100 >> 2]);
        end

        if (u_dut.u_main_mem.mem_array[32'h0000_0104 >> 2] == 32'd15) begin
            $display("  [PASS] Main Memory[0x0000_0104] (Final Sum)   = %0d (Expected: 15)", 
                     u_dut.u_main_mem.mem_array[32'h0000_0104 >> 2]);
        end else begin
            $display("  [FAIL] Main Memory[0x0000_0104] = %0d (Expected: 15)", 
                     u_dut.u_main_mem.mem_array[32'h0000_0104 >> 2]);
        end

        // Register values
        if (u_dut.u_core.reg_file[1] == 32'd0) begin
            $display("  [PASS] Register R1 (Loop Counter) = 0 (Terminated cleanly)");
        end else begin
            $display("  [FAIL] Register R1 = %0d (Expected: 0)", u_dut.u_core.reg_file[1]);
        end

        if (u_dut.u_core.reg_file[2] == 32'd15) begin
            $display("  [PASS] Register R2 (Accumulator)  = 15 (Expected: 15)");
        end else begin
            $display("  [FAIL] Register R2 = %0d (Expected: 15)", u_dut.u_core.reg_file[2]);
        end

        if (u_dut.u_core.reg_file[3] == 32'd15) begin
            $display("  [PASS] Register R3 (Last Loaded)  = 15 (Expected: 15)");
        end else begin
            $display("  [FAIL] Register R3 = %0d (Expected: 15)", u_dut.u_core.reg_file[3]);
        end

        // Assert Cache Hits
        if (icache_hits > 0) begin
            $display("  [PASS] L1 I-Cache hit detection verified (%0d hits recorded)", icache_hits);
        end else begin
            $display("  [FAIL] No I-Cache hits recorded!");
        end

        if (dcache_read_hits > 0 || dcache_write_hits > 0) begin
            $display("  [PASS] L1 D-Cache hit detection verified (%0d read hits, %0d write hits)", 
                     dcache_read_hits, dcache_write_hits);
        end else begin
            $display("  [FAIL] No D-Cache hits recorded!");
        end

        // ====================================================================
        // AMAT & Performance Metrics Computation
        // ====================================================================
        i_hit_rate  = (icache_accesses > 0) ? (real'(icache_hits) / real'(icache_accesses)) * 100.0 : 0.0;
        i_miss_rate = (icache_accesses > 0) ? (real'(icache_misses) / real'(icache_accesses)) * 100.0 : 0.0;
        amat_i      = 1.0 + ((real'(icache_misses) / real'(icache_accesses)) * 3.0); // HitTime=1, Penalty=3

        d_hit_rate  = (dcache_accesses > 0) ? (real'(dcache_read_hits + dcache_write_hits) / real'(dcache_accesses)) * 100.0 : 0.0;
        d_miss_rate = (dcache_accesses > 0) ? (real'(dcache_read_misses + dcache_write_misses) / real'(dcache_accesses)) * 100.0 : 0.0;
        amat_d      = 1.0 + ((d_miss_rate / 100.0) * 3.0);

        avg_cpi     = (instr_count > 0) ? (real'(cycle_count) / real'(instr_count)) : 0.0;

        $display("\n==================================================================");
        $display("           L1 CACHE & MEMORY HIERARCHY METRICS");
        $display("==================================================================");
        $display("  Total Instructions Executed    : %0d", instr_count);
        $display("  Total Clock Cycles Taken       : %0d", cycle_count);
        $display("  Average CPI (Cycles/Instr)     : %0.2f", avg_cpi);
        $display("  Main Memory Latency (Penalty)  : 3 cycles (1 req + 2 wait states)");
        $display("  ----------------------------------------------------------------");
        $display("  L1 Instruction Cache (I-Cache) :");
        $display("    - Total Accesses             : %0d", icache_accesses);
        $display("    - Hits (Single-Cycle)        : %0d", icache_hits);
        $display("    - Misses (Main Mem Refills)  : %0d", icache_misses);
        $display("    - Hit Rate                   : %0.2f %%", i_hit_rate);
        $display("    - Miss Rate                  : %0.2f %%", i_miss_rate);
        $display("    - AMAT (Instruction Fetch)   : %0.2f cycles", amat_i);
        $display("  ----------------------------------------------------------------");
        $display("  L1 Data Cache (D-Cache, Write-Through) :");
        $display("    - Total Accesses             : %0d", dcache_accesses);
        $display("    - Read Hits / Read Misses    : %0d / %0d", dcache_read_hits, dcache_read_misses);
        $display("    - Write Hits / Write Misses  : %0d / %0d", dcache_write_hits, dcache_write_misses);
        $display("    - Overall Hit Rate           : %0.2f %%", d_hit_rate);
        $display("    - Overall Miss Rate          : %0.2f %%", d_miss_rate);
        $display("    - AMAT (Data Memory Access)  : %0.2f cycles", amat_d);
        $display("  ----------------------------------------------------------------");
        $display("  Main Memory Refill Transactions: %0d", mem_trans_count);
        $display("  Total Memory Wait Cycles       : %0d", mem_wait_cycles);
        $display("==================================================================\n");

        $finish;
    end

endmodule
