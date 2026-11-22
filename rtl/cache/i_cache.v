// ============================================================================
// Module: i_cache.v
// Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
// Team: Decoders07
// Description: Direct-Mapped Level-1 Instruction Cache (L1 I-Cache).
//              Features 16 cache lines, valid array, tag comparison,
//              single-cycle hit access, autonomous line refill on miss,
//              and hardware performance telemetry counters.
// ============================================================================

`timescale 1ns / 1ps

module i_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_LINES  = 16,            // 16 lines (Index: bits [5:2])
    parameter TAG_WIDTH  = 26             // Tag: bits [31:6]
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // CPU Instruction Fetch Interface
    input  wire [ADDR_WIDTH-1:0] cpu_addr,
    input  wire                  cpu_req,
    output reg  [DATA_WIDTH-1:0] cpu_instruction,
    output wire                  cpu_hit,
    output wire                  cpu_stall,

    // Shared Main Memory Refill Interface
    output reg                   mem_req,
    output reg  [ADDR_WIDTH-1:0] mem_addr,
    input  wire                  mem_ready,
    input  wire [DATA_WIDTH-1:0] mem_rdata,

    // Performance Telemetry Counters
    output reg  [31:0]           hit_count,
    output reg  [31:0]           miss_count,
    output reg  [31:0]           access_count
);

    wire [3:0]           line_index = cpu_addr[5:2];
    wire [TAG_WIDTH-1:0] line_tag   = cpu_addr[31:6];

    // Cache Storage Arrays
    reg                  valid_array [0:NUM_LINES-1];
    reg [TAG_WIDTH-1:0]  tag_array   [0:NUM_LINES-1];
    reg [DATA_WIDTH-1:0] data_array  [0:NUM_LINES-1];

    // FSM States
    localparam S_IDLE   = 1'b0;
    localparam S_REFILL = 1'b1;
    reg state;

    reg [ADDR_WIDTH-1:0] latched_addr;

    wire tag_match = (valid_array[line_index] == 1'b1) && (tag_array[line_index] == line_tag);
    wire is_hit    = (state == S_IDLE) && cpu_req && tag_match;
    wire is_miss   = (state == S_IDLE) && cpu_req && !tag_match;

    assign cpu_hit   = is_hit;
    assign cpu_stall = is_miss || (state == S_REFILL && !mem_ready);

    // Combinational instruction delivery
    always @(*) begin
        if (state == S_IDLE) begin
            if (is_hit) begin
                cpu_instruction = data_array[line_index];
            end else begin
                cpu_instruction = 32'h00000013; // NOP while waiting
            end
        end else if (state == S_REFILL) begin
            if (mem_ready) begin
                cpu_instruction = mem_rdata;     // Bypass fetched instruction directly
            end else begin
                cpu_instruction = 32'h00000013;
            end
        end else begin
            cpu_instruction = 32'h00000013;
        end
    end

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            mem_req      <= 1'b0;
            mem_addr     <= 32'd0;
            latched_addr <= 32'd0;
            hit_count    <= 32'd0;
            miss_count   <= 32'd0;
            access_count <= 32'd0;

            for (i = 0; i < NUM_LINES; i = i + 1) begin
                valid_array[i] <= 1'b0;
                tag_array[i]   <= {TAG_WIDTH{1'b0}};
                data_array[i]  <= 32'h00000013;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (cpu_req) begin
                        if (tag_match) begin
                            // Single-Cycle Cache Hit
                            hit_count    <= hit_count + 32'd1;
                            access_count <= access_count + 32'd1;
                            mem_req      <= 1'b0;
                            state        <= S_IDLE;
                        end else begin
                            // Compulsory / Capacity Miss -> Initiate Memory Refill
                            miss_count   <= miss_count + 32'd1;
                            access_count <= access_count + 32'd1;
                            mem_req      <= 1'b1;
                            mem_addr     <= cpu_addr;
                            latched_addr <= cpu_addr;
                            state        <= S_REFILL;
                        end
                    end else begin
                        mem_req <= 1'b0;
                    end
                end

                S_REFILL: begin
                    mem_addr <= latched_addr;
                    if (mem_ready) begin
                        // Refill line into cache array
                        valid_array[latched_addr[5:2]] <= 1'b1;
                        tag_array[latched_addr[5:2]]   <= latched_addr[31:6];
                        data_array[latched_addr[5:2]]  <= mem_rdata;
                        mem_req                        <= 1'b0;
                        state                          <= S_IDLE;
                    end else begin
                        mem_req <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
