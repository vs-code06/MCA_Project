// ============================================================================
// Module: main_memory.v
// Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
// Team: Decoders07
// Description: Multi-Cycle Shared Main Memory Subsystem.
//              Backs both Level-1 Instruction Cache (refills) and Level-1
//              Data Cache (refills & write-through transactions).
//              Features configurable memory wait-state latency, 4-byte-lane
//              write masking, dual-port arbiter with D-Cache priority,
//              and zero-skew combinational read data output.
// ============================================================================

`timescale 1ns / 1ps

module main_memory #(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter MEM_DEPTH    = 1024,        // 1024 words = 4096 bytes
    parameter LATENCY      = 2,           // 2 wait-state cycles (total 3 cycles)
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

    // Unified 32-bit Memory Array
    reg [DATA_WIDTH-1:0] mem_array [0:MEM_DEPTH-1];

    // Arbiter States
    localparam S_IDLE = 2'b00;
    localparam S_WAIT = 2'b01;
    localparam S_DONE = 2'b10;
    reg [1:0] state;

    // Active transaction tracking
    reg                  active_client;   // 0 = I-Cache, 1 = D-Cache
    reg                  active_we;
    reg [3:0]            active_be;
    reg [ADDR_WIDTH-1:0] active_addr;
    reg [DATA_WIDTH-1:0] active_wdata;
    reg [3:0]            wait_timer;

    wire [$clog2(MEM_DEPTH)-1:0] word_idx = active_addr[$clog2(MEM_DEPTH)+1:2];

    // Combinational read data driven directly from indexed memory word
    assign icache_rdata = mem_array[word_idx];
    assign dcache_rdata = mem_array[word_idx];

    // Helper: Byte-enable write merge
    function [31:0] apply_be;
        input [31:0] old_word;
        input [31:0] new_word;
        input [3:0]  be;
        begin
            apply_be[7:0]   = be[0] ? new_word[7:0]   : old_word[7:0];
            apply_be[15:8]  = be[1] ? new_word[15:8]  : old_word[15:8];
            apply_be[23:16] = be[2] ? new_word[23:16] : old_word[23:16];
            apply_be[31:24] = be[3] ? new_word[31:24] : old_word[31:24];
        end
    endfunction

    // Initialization
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem_array[i] = 32'h00000013; // NOP default
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem_array);
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state             <= S_IDLE;
            icache_ready      <= 1'b0;
            dcache_ready      <= 1'b0;
            active_client     <= 1'b0;
            active_we         <= 1'b0;
            active_be         <= 4'b1111;
            active_addr       <= 32'd0;
            active_wdata      <= 32'd0;
            wait_timer        <= 4'd0;
            total_trans_count <= 32'd0;
            total_wait_cycles <= 32'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    icache_ready <= 1'b0;
                    dcache_ready <= 1'b0;

                    // Priority Arbiter: D-Cache has higher priority than I-Cache
                    if (dcache_req) begin
                        active_client     <= 1'b1; // D-Cache
                        active_we         <= dcache_we;
                        active_be         <= dcache_be;
                        active_addr       <= dcache_addr;
                        active_wdata      <= dcache_wdata;
                        wait_timer        <= LATENCY;
                        total_trans_count <= total_trans_count + 32'd1;
                        if (LATENCY == 0) begin
                            dcache_ready <= 1'b1;
                            if (dcache_we) begin
                                mem_array[dcache_addr[$clog2(MEM_DEPTH)+1:2]] <= apply_be(mem_array[dcache_addr[$clog2(MEM_DEPTH)+1:2]], dcache_wdata, dcache_be);
                            end
                            state <= S_DONE;
                        end else begin
                            state <= S_WAIT;
                        end
                    end else if (icache_req) begin
                        active_client     <= 1'b0; // I-Cache
                        active_we         <= 1'b0;
                        active_be         <= 4'b1111;
                        active_addr       <= icache_addr;
                        active_wdata      <= 32'd0;
                        wait_timer        <= LATENCY;
                        total_trans_count <= total_trans_count + 32'd1;
                        if (LATENCY == 0) begin
                            icache_ready <= 1'b1;
                            state <= S_DONE;
                        end else begin
                            state <= S_WAIT;
                        end
                    end
                end

                S_WAIT: begin
                    total_wait_cycles <= total_wait_cycles + 32'd1;
                    if (wait_timer <= 4'd1) begin
                        state <= S_DONE;
                        if (active_client == 1'b1) begin
                            dcache_ready <= 1'b1;
                            if (active_we) begin
                                mem_array[word_idx] <= apply_be(mem_array[word_idx], active_wdata, active_be);
                            end
                        end else begin
                            icache_ready <= 1'b1;
                        end
                    end else begin
                        wait_timer <= wait_timer - 4'd1;
                    end
                end

                S_DONE: begin
                    icache_ready <= 1'b0;
                    dcache_ready <= 1'b0;
                    state        <= S_IDLE;
                end
            endcase
        end
    end

endmodule
