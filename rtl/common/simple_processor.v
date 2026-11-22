// ============================================================================
// Module: simple_processor.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Anant Jain (2401010066) & Vipul Sharma (2401010505)
// Description: Simple RISC-style controller / processor core.
//              Contains a 16-register register file, ALU, PC generation, and
//              dual memory ports (Instruction bus and Data bus).
//              Demonstrates simultaneous instruction fetch and operand load/store.
// ============================================================================

`timescale 1ns / 1ps

module simple_processor #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Instruction Memory Interface (Fetch Path)
    output wire [ADDR_WIDTH-1:0] instr_addr,
    output wire                  instr_read_en,
    input  wire [DATA_WIDTH-1:0] instruction,

    // Data Memory Interface (Load/Store Path)
    output reg                   data_req,
    output reg                   data_we,
    output reg  [3:0]            data_be,
    output reg  [ADDR_WIDTH-1:0] data_addr,
    output reg  [DATA_WIDTH-1:0] data_wdata,
    input  wire [DATA_WIDTH-1:0] data_rdata,
    input  wire                  data_ready,

    // External Stall (e.g. from shared memory arbiter)
    input  wire                  external_stall,

    // Status and Performance Counters
    output reg                   halted,
    output reg  [31:0]           cycle_count,
    output reg  [31:0]           instr_count,
    output reg  [31:0]           simultaneous_access_count
);

    // Register File: 16 general-purpose 32-bit registers (R0 is hardwired to 0)
    reg [DATA_WIDTH-1:0] reg_file [0:15];

    // Program Counter signals
    wire [ADDR_WIDTH-1:0] pc_curr;
    wire [ADDR_WIDTH-1:0] pc_plus_4;
    reg                   jump_en;
    reg  [ADDR_WIDTH-1:0] jump_addr;
    wire                  pc_stall;

    assign pc_stall = external_stall || halted;

    // Instantiate Program Counter
    program_counter #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .RESET_ADDR(32'h0000_0000)
    ) u_pc (
        .clk(clk),
        .rst_n(rst_n),
        .pc_en(1'b1),
        .stall(pc_stall),
        .jump_en(jump_en),
        .jump_addr(jump_addr),
        .pc(pc_curr),
        .pc_plus_4(pc_plus_4)
    );

    assign instr_addr    = pc_curr;
    assign instr_read_en = !halted;

    // Instruction Decode Fields
    wire [5:0]  opcode   = instruction[31:26];
    wire [3:0]  rd_idx   = instruction[25:22];
    wire [3:0]  rs1_idx  = instruction[21:18];
    wire [3:0]  rs2_idx  = instruction[17:14];
    wire [13:0] imm14    = instruction[13:0];
    wire [31:0] imm_sign_ext = {{18{imm14[13]}}, imm14};

    // Register read operands
    wire [31:0] rs1_val = (rs1_idx == 4'd0) ? 32'd0 : reg_file[rs1_idx];
    wire [31:0] rs2_val = (rs2_idx == 4'd0) ? 32'd0 : reg_file[rs2_idx];

    // ALU output
    reg [31:0] alu_result;
    always @(*) begin
        case (opcode)
            6'h01: alu_result = rs1_val + rs2_val;       // ADD
            6'h02: alu_result = rs1_val - rs2_val;       // SUB
            6'h03: alu_result = rs1_val + imm_sign_ext;  // ADDI
            6'h04: alu_result = rs1_val & rs2_val;       // AND
            6'h05: alu_result = rs1_val | rs2_val;       // OR
            6'h06: alu_result = rs1_val ^ rs2_val;       // XOR
            6'h08: alu_result = rs1_val + imm_sign_ext;  // LOAD (effective address)
            6'h09: alu_result = rs1_val + imm_sign_ext;  // STORE (effective address)
            default: alu_result = 32'd0;
        endcase
    end

    // Data memory control generation
    always @(*) begin
        data_req   = 1'b0;
        data_we    = 1'b0;
        data_be    = 4'b1111;
        data_addr  = alu_result;
        data_wdata = rs2_val;

        if (!halted) begin
            if (opcode == 6'h08) begin // LOAD
                data_req = 1'b1;
                data_we  = 1'b0;
            end else if (opcode == 6'h09) begin // STORE
                data_req = 1'b1;
                data_we  = 1'b1;
            end
        end
    end

    // Branch / Jump control logic
    always @(*) begin
        jump_en   = 1'b0;
        jump_addr = 32'd0;

        if (!halted && !external_stall) begin
            case (opcode)
                6'h10: begin // BEQ
                    if (rs1_val == rs2_val) begin
                        jump_en   = 1'b1;
                        jump_addr = pc_curr + (imm_sign_ext << 2);
                    end
                end
                6'h11: begin // BNE
                    if (rs1_val != rs2_val) begin
                        jump_en   = 1'b1;
                        jump_addr = pc_curr + (imm_sign_ext << 2);
                    end
                end
                6'h12: begin // JUMP
                    jump_en   = 1'b1;
                    jump_addr = {instruction[25:0], 2'b00};
                end
                default: ;
            endcase
        end
    end

    // Register File Write & Execution State Update
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halted      <= 1'b0;
            cycle_count <= 32'd0;
            instr_count <= 32'd0;
            simultaneous_access_count <= 32'd0;

            for (i = 0; i < 16; i = i + 1) begin
                reg_file[i] <= 32'd0;
            end
        end else if (!halted) begin
            cycle_count <= cycle_count + 32'd1;

            if (!external_stall) begin
                instr_count <= instr_count + 32'd1;

                // Track simultaneous memory access event (Fetch + Data load/store)
                if (data_req && instr_read_en) begin
                    simultaneous_access_count <= simultaneous_access_count + 32'd1;
                end

                case (opcode)
                    6'h00: begin // NOP
                        // No operation
                    end
                    6'h01, 6'h02, 6'h03, 6'h04, 6'h05, 6'h06: begin // ALU instructions
                        if (rd_idx != 4'd0) begin
                            reg_file[rd_idx] <= alu_result;
                        end
                    end
                    6'h08: begin // LOAD
                        if (rd_idx != 4'd0) begin
                            reg_file[rd_idx] <= data_rdata;
                        end
                    end
                    6'h09: begin // STORE
                        // Data written to memory via data bus
                    end
                    6'h3F: begin // HALT
                        halted <= 1'b1;
                    end
                    default: ;
                endcase
            end
        end
    end

endmodule
