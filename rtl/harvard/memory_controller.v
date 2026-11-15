// ============================================================================
// Module: memory_controller.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Vipul Sharma (2401010505) & Krishna Gehlot (2401010236)
// Description: Read/Write Control Unit and MMIO Arbiter.
//              Routes memory requests to either internal SRAM or Memory-Mapped
//              peripherals based on address decode signals. Manages wait states,
//              ready assertions, and bus fault reporting.
// ============================================================================

`timescale 1ns / 1ps

module memory_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Processor Core Interface (Data bus)
    input  wire                  proc_req,
    input  wire                  proc_we,        // 1 = Write, 0 = Read
    input  wire [3:0]            proc_be,        // Byte enables
    input  wire [ADDR_WIDTH-1:0] proc_addr,
    input  wire [DATA_WIDTH-1:0] proc_wdata,
    output reg  [DATA_WIDTH-1:0] proc_rdata,
    output wire                  proc_ready,
    output wire                  proc_fault,

    // SRAM Interface
    output wire                  sram_cs,
    output wire                  sram_we,
    output wire [3:0]            sram_be,
    output wire [ADDR_WIDTH-1:0] sram_addr,
    output wire [DATA_WIDTH-1:0] sram_wdata,
    input  wire [DATA_WIDTH-1:0] sram_rdata,
    input  wire                  sram_ready,

    // MMIO Peripheral Registers
    output reg  [31:0]           mmio_leds,
    output reg  [31:0]           mmio_out_char
);

    // Address decoder signals
    wire cs_ram;
    wire cs_io;
    wire addr_error;
    wire unaligned_error;
    wire [ADDR_WIDTH-1:0] local_addr;

    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_decoder (
        .addr(proc_addr),
        .mem_req(proc_req),
        .cs_ram(cs_ram),
        .cs_io(cs_io),
        .addr_error(addr_error),
        .unaligned_error(unaligned_error),
        .local_addr(local_addr)
    );

    // Pass signals to SRAM
    assign sram_cs    = cs_ram;
    assign sram_we    = proc_we && cs_ram;
    assign sram_be    = proc_be;
    assign sram_addr  = local_addr;
    assign sram_wdata = proc_wdata;

    // Fault signal asserted if illegal address or misaligned access
    assign proc_fault = addr_error || unaligned_error;
    assign proc_ready = (cs_ram && sram_ready) || cs_io || proc_fault;

    // Cycle counter for performance metrics
    reg [31:0] cycle_counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cycle_counter <= 32'd0;
        else cycle_counter <= cycle_counter + 32'd1;
    end

    // MMIO Registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mmio_leds     <= 32'h0000_0000;
            mmio_out_char <= 32'h0000_0000;
        end else if (proc_req && proc_we && cs_io) begin
            case (local_addr[7:0])
                8'h00: mmio_leds     <= proc_wdata;       // 0xF000: LED display
                8'h04: mmio_out_char <= proc_wdata;       // 0xF004: Console character output
                default: ;
            endcase
        end
    end

    // Read Data Muxing
    always @(*) begin
        if (cs_ram) begin
            proc_rdata = sram_rdata;
        end else if (cs_io) begin
            case (local_addr[7:0])
                8'h00: proc_rdata = mmio_leds;
                8'h04: proc_rdata = mmio_out_char;
                8'h08: proc_rdata = cycle_counter;       // 0xF008: Read cycle count
                default: proc_rdata = 32'hDEAD_BEEF;
            endcase
        end else begin
            proc_rdata = 32'h0000_0000;
        end
    end

endmodule
