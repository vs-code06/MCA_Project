// ============================================================================
// Testbench: tb_harvard_memory.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Kartik Mehra (2401020030)
// Description: Comprehensive testbench for Harvard Architecture RTL.
//              Validates independent instruction and data path operations,
//              verifies simultaneous access cycles, performs automated assertions
//              on register and memory contents, and dumps VCD waveforms.
// ============================================================================

`timescale 1ns / 1ps

module tb_harvard_memory;

    reg clk;
    reg rst_n;

    wire        halted;
    wire [31:0] cycle_count;
    wire [31:0] instr_count;
    wire [31:0] simultaneous_access_count;
    wire [31:0] mmio_leds;
    wire [31:0] mmio_out_char;
    wire        proc_fault;

    wire [31:0] probe_pc;
    wire [31:0] probe_instruction;
    wire        probe_data_req;
    wire        probe_data_we;
    wire [31:0] probe_data_addr;
    wire [31:0] probe_data_wdata;
    wire [31:0] probe_data_rdata;

    // Instantiate Harvard Top
    harvard_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .IMEM_DEPTH(256),
        .DMEM_DEPTH(256),
        .IMEM_INIT("tb/program.mem"),
        .DMEM_INIT("")
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .halted(halted),
        .cycle_count(cycle_count),
        .instr_count(instr_count),
        .simultaneous_access_count(simultaneous_access_count),
        .mmio_leds(mmio_leds),
        .mmio_out_char(mmio_out_char),
        .proc_fault(proc_fault),
        .probe_pc(probe_pc),
        .probe_instruction(probe_instruction),
        .probe_data_req(probe_data_req),
        .probe_data_we(probe_data_we),
        .probe_data_addr(probe_data_addr),
        .probe_data_wdata(probe_data_wdata),
        .probe_data_rdata(probe_data_rdata)
    );

    // 100 MHz clock generation (Period = 10 ns)
    always #5 clk = ~clk;

    // Cycle-by-cycle trace logger
    always @(posedge clk) begin
        if (rst_n && !halted) begin
            $display("[Cycle %02d | Time %0t ps] PC=0x%08X | Instr=0x%08X | DataReq=%b | WE=%b | DataAddr=0x%08X | WData=0x%08X | RData=0x%08X %s",
                cycle_count, $time, probe_pc, probe_instruction,
                probe_data_req, probe_data_we, probe_data_addr, probe_data_wdata, probe_data_rdata,
                (probe_data_req ? "--> [SIMULTANEOUS ACCESS!]" : "")
            );
        end
    end

    initial begin
        $display("==================================================================");
        $display("  ECE/CSE: Modern Computer Architecture - Project 9 (Decoders07)");
        $display("  Harvard Architecture RTL Simulation & Verification");
        $display("  Authors: Anant Jain, Vipul Sharma, Krishna Gehlot,");
        $display("           Aditya Kumar, Kartik Mehra");
        $display("==================================================================");

        // VCD Waveform dump setup
        $dumpfile("sim/harvard_sim.vcd");
        $dumpvars(0, tb_harvard_memory);

        // Initialize signals
        clk   = 1'b0;
        rst_n = 1'b0;

        // Apply Reset for 20 ns
        #20;
        rst_n = 1'b1;
        $display("[INFO] System released from reset at %0t ps", $time);

        // Wait until CPU halts or timeout occurs
        fork : wait_block
            begin
                wait (halted == 1'b1);
                $display("\n[INFO] Processor HALT instruction executed at %0t ps!", $time);
                disable wait_block;
            end
            begin
                #2000;
                $display("\n[ERROR] Simulation TIMEOUT occurred!");
                disable wait_block;
            end
        join

        // Allow 2 settling cycles
        #20;

        // Verification of Final Register and Memory State
        $display("\n==================================================================");
        $display("                     VERIFICATION RESULTS");
        $display("==================================================================");

        // Assert memory values (Word 64 = 0x100, Word 65 = 0x104, Word 66 = 0x108, Word 67 = 0x10C)
        if (u_dut.u_dmem.mem_b0[64] == 8'd30) begin
            $display("  [PASS] Data Memory[0x0000_0100] = %0d (Expected: 30)", u_dut.u_dmem.mem_b0[64]);
        end else begin
            $display("  [FAIL] Data Memory[0x0000_0100] = %0d (Expected: 30)", u_dut.u_dmem.mem_b0[64]);
        end

        if (u_dut.u_dmem.mem_b0[65] == 8'd5) begin
            $display("  [PASS] Data Memory[0x0000_0104] = %0d (Expected: 5)", u_dut.u_dmem.mem_b0[65]);
        end else begin
            $display("  [FAIL] Data Memory[0x0000_0104] = %0d (Expected: 5)", u_dut.u_dmem.mem_b0[65]);
        end

        if (u_dut.u_dmem.mem_b0[66] == 8'd35) begin
            $display("  [PASS] Data Memory[0x0000_0108] = %0d (Expected: 35)", u_dut.u_dmem.mem_b0[66]);
        end else begin
            $display("  [FAIL] Data Memory[0x0000_0108] = %0d (Expected: 35)", u_dut.u_dmem.mem_b0[66]);
        end

        if (u_dut.u_dmem.mem_b0[67] == 8'd25) begin
            $display("  [PASS] Data Memory[0x0000_010C] = %0d (Expected: 25)", u_dut.u_dmem.mem_b0[67]);
        end else begin
            $display("  [FAIL] Data Memory[0x0000_010C] = %0d (Expected: 25)", u_dut.u_dmem.mem_b0[67]);
        end

        // Check Registers
        $display("  [INFO] Register R10 (Base)  = 0x%04X (%0d)", u_dut.u_cpu.reg_file[10], u_dut.u_cpu.reg_file[10]);
        $display("  [INFO] Register R1  (Val1)  = %0d", u_dut.u_cpu.reg_file[1]);
        $display("  [INFO] Register R2  (Val2)  = %0d", u_dut.u_cpu.reg_file[2]);
        $display("  [INFO] Register R3  (Sum1)  = %0d", u_dut.u_cpu.reg_file[3]);
        $display("  [INFO] Register R5  (Load1) = %0d", u_dut.u_cpu.reg_file[5]);
        $display("  [INFO] Register R6  (Load2) = %0d", u_dut.u_cpu.reg_file[6]);
        $display("  [INFO] Register R7  (Sum2)  = %0d", u_dut.u_cpu.reg_file[7]);
        $display("  [INFO] Register R8  (Load3) = %0d", u_dut.u_cpu.reg_file[8]);
        $display("  [INFO] Register R9  (Sub)   = %0d", u_dut.u_cpu.reg_file[9]);

        $display("\n==================================================================");
        $display("               HARVARD PERFORMANCE METRICS");
        $display("==================================================================");
        $display("  Total Instructions Executed : %0d", instr_count);
        $display("  Total Clock Cycles Taken    : %0d", cycle_count);
        $display("  Simultaneous Access Cycles  : %0d", simultaneous_access_count);
        $display("  Cycles Per Instruction (CPI): %0.2f", (cycle_count * 1.0) / instr_count);
        $display("  Instruction Throughput (IPC): %0.2f", (instr_count * 1.0) / cycle_count);
        $display("==================================================================\n");

        $finish;
    end

endmodule
