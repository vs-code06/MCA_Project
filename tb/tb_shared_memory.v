// ============================================================================
// Testbench: tb_shared_memory.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Aditya Kumar (2401010029)
// ============================================================================

`timescale 1ns / 1ps

module tb_shared_memory;

    reg clk;
    reg rst_n;

    wire        halted;
    wire [31:0] cycle_count;
    wire [31:0] instr_count;
    wire [31:0] stall_cycles_count;
    wire [31:0] mmio_leds;
    wire [31:0] mmio_out_char;
    wire        proc_fault;
    wire [31:0] shared_bus_addr;
    wire [31:0] shared_bus_wdata;
    wire        shared_bus_we;

    shared_memory_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MEM_DEPTH(512),
        .INIT_FILE("tb/shared_program.mem")
    ) u_shared (
        .clk(clk),
        .rst_n(rst_n),
        .halted(halted),
        .cycle_count(cycle_count),
        .instr_count(instr_count),
        .stall_cycles_count(stall_cycles_count),
        .mmio_leds(mmio_leds),
        .mmio_out_char(mmio_out_char),
        .proc_fault(proc_fault),
        .shared_bus_addr(shared_bus_addr),
        .shared_bus_wdata(shared_bus_wdata),
        .shared_bus_we(shared_bus_we)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n && !halted) begin
            $display("[Cycle %02d | Time %0t ps] PC=0x%08X | Instr=0x%08X | Stall=%b | BusSelData=%b | Addr=0x%08X | WE=%b",
                cycle_count, $time, u_shared.instr_addr, u_shared.instruction_to_cpu,
                u_shared.cpu_stall, u_shared.bus_select_data, shared_bus_addr, shared_bus_we
            );
        end
    end

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        fork : wait_shared
            begin
                wait (halted == 1'b1);
                $display("\n[INFO] Shared Memory CPU Halted at %0t ps!", $time);
                disable wait_shared;
            end
            begin
                #1000;
                $display("\n[TIMEOUT] Shared Memory CPU did not halt!");
                disable wait_shared;
            end
        join

        #20;
        $display("Instructions: %0d, Cycles: %0d, Stalls: %0d", instr_count, cycle_count, stall_cycles_count);
        $finish;
    end

endmodule
