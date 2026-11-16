// ============================================================================
// Testbench: tb_shared_vs_harvard.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Aditya Kumar (2401010029) & Kartik Mehra (2401020030)
// Description: Comparative benchmark testbench executing the identical program
//              across both Harvard Architecture and Shared-Memory (Von Neumann).
//              Measures structural hazard stalls, execution cycles, CPI, and
//              empirical speedup to validate architectural trade-offs.
// ============================================================================

`timescale 1ns / 1ps

module tb_shared_vs_harvard;

    reg clk;
    reg rst_n;

    // Harvard signals
    wire        h_halted;
    wire [31:0] h_cycle_count;
    wire [31:0] h_instr_count;
    wire [31:0] h_simul_count;
    wire [31:0] h_pc;
    wire [31:0] h_instr;

    // Shared Memory signals
    wire        s_halted;
    wire [31:0] s_cycle_count;
    wire [31:0] s_instr_count;
    wire [31:0] s_stall_cycles;
    wire [31:0] s_bus_addr;
    wire [31:0] s_bus_wdata;
    wire        s_bus_we;

    // 1. Harvard Architecture Instance
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
        .probe_pc(h_pc),
        .probe_instruction(h_instr),
        .probe_data_req(),
        .probe_data_we(),
        .probe_data_addr(),
        .probe_data_wdata(),
        .probe_data_rdata()
    );

    // 2. Shared-Memory (Von Neumann) Instance
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
        .shared_bus_addr(s_bus_addr),
        .shared_bus_wdata(s_bus_wdata),
        .shared_bus_we(s_bus_we)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        $display("==================================================================");
        $display("   ECE/CSE: Modern Computer Architecture - Project 9");
        $display("   Comparative Analysis: Harvard vs Von Neumann Architectures");
        $display("   Authors: Anant Jain, Vipul Sharma, Krishna Gehlot,");
        $display("            Aditya Kumar, Kartik Mehra");
        $display("==================================================================");

        $dumpfile("sim/comparison_sim.vcd");
        $dumpvars(0, tb_shared_vs_harvard);

        clk   = 1'b0;
        rst_n = 1'b0;

        #20;
        rst_n = 1'b1;

        // Wait until both systems finish execution
        wait (h_halted == 1'b1 && s_halted == 1'b1);
        #30;

        $display("\n==================================================================");
        $display("              ARCHITECTURE COMPARISON BENCHMARK");
        $display("==================================================================");
        $display("  Metric                          | Harvard       | Shared (Von Neumann)");
        $display("  --------------------------------+---------------+---------------------");
        $display("  Instructions Executed           | %-13d | %-13d", h_instr_count, s_instr_count);
        $display("  Total Clock Cycles              | %-13d | %-13d", h_cycle_count, s_cycle_count);
        $display("  Structural Hazard Stall Cycles  | %-13d | %-13d", 0, s_stall_cycles);
        $display("  Simultaneous Access Cycles      | %-13d | %-13d", h_simul_count, 0);
        $display("  Average CPI (Cycles/Instr)      | %-13.2f | %-13.2f", 
            (h_cycle_count * 1.0) / h_instr_count, 
            (s_cycle_count * 1.0) / s_instr_count);
        $display("  Throughput (IPC)                | %-13.2f | %-13.2f", 
            (h_instr_count * 1.0) / h_cycle_count, 
            (s_instr_count * 1.0) / s_cycle_count);
        $display("  --------------------------------+---------------+---------------------");
        $display("  Empirical Speedup (Harvard)     | %0.2fx faster than Von Neumann!", 
            (s_cycle_count * 1.0) / h_cycle_count);
        $display("==================================================================\n");

        $finish;
    end

endmodule
