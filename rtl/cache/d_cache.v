// ============================================================================
// Module: d_cache.v
// Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
// Team: Decoders07
// Description: Direct-Mapped Level-1 Data Cache (L1 D-Cache).
//              Features Write-Through policy with No-Write-Allocate,
//              4-bit byte-enable masking, single-cycle hit path,
//              autonomous line refill on read miss, write-through to main memory,
//              and comprehensive read/write hit telemetry.
// ============================================================================

`timescale 1ns / 1ps

module d_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_LINES  = 16,            // 16 lines (Index: bits [5:2])
    parameter TAG_WIDTH  = 26             // Tag: bits [31:6]
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // CPU Data Bus Interface
    input  wire [ADDR_WIDTH-1:0] cpu_addr,
    input  wire                  cpu_req,
    input  wire                  cpu_we,         // 1 = Write (STORE), 0 = Read (LOAD)
    input  wire [3:0]            cpu_be,         // Byte enables
    input  wire [DATA_WIDTH-1:0] cpu_wdata,
    output reg  [DATA_WIDTH-1:0] cpu_rdata,
    output wire                  cpu_hit,
    output wire                  cpu_stall,
    output wire                  cpu_ready,

    // Shared Main Memory Interface
    output reg                   mem_req,
    output reg                   mem_we,
    output reg  [3:0]            mem_be,
    output reg  [ADDR_WIDTH-1:0] mem_addr,
    output reg  [DATA_WIDTH-1:0] mem_wdata,
    input  wire                  mem_ready,
    input  wire [DATA_WIDTH-1:0] mem_rdata,

    // Performance Telemetry Counters
    output reg  [31:0]           read_hit_count,
    output reg  [31:0]           read_miss_count,
    output reg  [31:0]           write_hit_count,
    output reg  [31:0]           write_miss_count,
    output reg  [31:0]           access_count
);

    wire [3:0]           line_index = cpu_addr[5:2];
    wire [TAG_WIDTH-1:0] line_tag   = cpu_addr[31:6];

    // Cache Storage Arrays
    reg                  valid_array [0:NUM_LINES-1];
    reg [TAG_WIDTH-1:0]  tag_array   [0:NUM_LINES-1];
    reg [DATA_WIDTH-1:0] data_array  [0:NUM_LINES-1];

    // FSM States
    localparam S_IDLE       = 2'b00;
    localparam S_READ_WAIT  = 2'b01;
    localparam S_WRITE_WAIT = 2'b10;
    reg [1:0] state;

    reg [ADDR_WIDTH-1:0] latched_addr;
    reg [DATA_WIDTH-1:0] latched_wdata;
    reg [3:0]            latched_be;

    // Hit Detection
    wire tag_match = (valid_array[line_index] == 1'b1) && (tag_array[line_index] == line_tag);
    wire read_hit  = (state == S_IDLE) && cpu_req && !cpu_we && tag_match;
    wire read_miss = (state == S_IDLE) && cpu_req && !cpu_we && !tag_match;
    wire write_hit = (state == S_IDLE) && cpu_req && cpu_we && tag_match;
    wire write_miss= (state == S_IDLE) && cpu_req && cpu_we && !tag_match;

    assign cpu_hit   = read_hit || write_hit;
    assign cpu_stall = read_miss || write_hit || write_miss || 
                       (state == S_READ_WAIT && !mem_ready) || 
                       (state == S_WRITE_WAIT && !mem_ready);
    assign cpu_ready = read_hit || ((state == S_READ_WAIT || state == S_WRITE_WAIT) && mem_ready);

    // Combinational Read Output
    always @(*) begin
        if (state == S_IDLE) begin
            cpu_rdata = read_hit ? data_array[line_index] : 32'd0;
        end else if (state == S_READ_WAIT) begin
            cpu_rdata = mem_ready ? mem_rdata : 32'd0;
        end else begin
            cpu_rdata = 32'd0;
        end
    end

    // Helper function: byte-enabled word merge
    function [31:0] apply_byte_en;
        input [31:0] old_val;
        input [31:0] new_val;
        input [3:0]  be;
        begin
            apply_byte_en[7:0]   = be[0] ? new_val[7:0]   : old_val[7:0];
            apply_byte_en[15:8]  = be[1] ? new_val[15:8]  : old_val[15:8];
            apply_byte_en[23:16] = be[2] ? new_val[23:16] : old_val[23:16];
            apply_byte_en[31:24] = be[3] ? new_val[31:24] : old_val[31:24];
        end
    endfunction

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= S_IDLE;
            mem_req          <= 1'b0;
            mem_we           <= 1'b0;
            mem_be           <= 4'b1111;
            mem_addr         <= 32'd0;
            mem_wdata        <= 32'd0;
            latched_addr     <= 32'd0;
            latched_wdata    <= 32'd0;
            latched_be       <= 4'b1111;
            read_hit_count   <= 32'd0;
            read_miss_count  <= 32'd0;
            write_hit_count  <= 32'd0;
            write_miss_count <= 32'd0;
            access_count     <= 32'd0;

            for (i = 0; i < NUM_LINES; i = i + 1) begin
                valid_array[i] <= 1'b0;
                tag_array[i]   <= {TAG_WIDTH{1'b0}};
                data_array[i]  <= 32'd0;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (cpu_req) begin
                        access_count  <= access_count + 32'd1;
                        latched_addr  <= cpu_addr;
                        latched_wdata <= cpu_wdata;
                        latched_be    <= cpu_be;

                        if (!cpu_we) begin
                            // --- LOAD (Read) ---
                            if (tag_match) begin
                                read_hit_count <= read_hit_count + 32'd1;
                                mem_req        <= 1'b0;
                                state          <= S_IDLE;
                            end else begin
                                read_miss_count <= read_miss_count + 32'd1;
                                mem_req         <= 1'b1;
                                mem_we          <= 1'b0;
                                mem_addr        <= cpu_addr;
                                state           <= S_READ_WAIT;
                            end
                        end else begin
                            // --- STORE (Write-Through) ---
                            mem_req   <= 1'b1;
                            mem_we    <= 1'b1;
                            mem_be    <= cpu_be;
                            mem_addr  <= cpu_addr;
                            mem_wdata <= cpu_wdata;

                            if (tag_match) begin
                                write_hit_count        <= write_hit_count + 32'd1;
                                data_array[line_index] <= apply_byte_en(data_array[line_index], cpu_wdata, cpu_be);
                            end else begin
                                write_miss_count <= write_miss_count + 32'd1;
                            end
                            state <= S_WRITE_WAIT;
                        end
                    end else begin
                        mem_req <= 1'b0;
                    end
                end

                S_READ_WAIT: begin
                    mem_addr <= latched_addr;
                    mem_req  <= 1'b1;
                    mem_we   <= 1'b0;

                    if (mem_ready) begin
                        valid_array[latched_addr[5:2]] <= 1'b1;
                        tag_array[latched_addr[5:2]]   <= latched_addr[31:6];
                        data_array[latched_addr[5:2]]  <= mem_rdata;
                        mem_req                        <= 1'b0;
                        state                          <= S_IDLE;
                    end
                end

                S_WRITE_WAIT: begin
                    mem_addr  <= latched_addr;
                    mem_wdata <= latched_wdata;
                    mem_be    <= latched_be;
                    mem_req   <= 1'b1;
                    mem_we    <= 1'b1;

                    if (mem_ready) begin
                        mem_req <= 1'b0;
                        mem_we  <= 1'b0;
                        state   <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
