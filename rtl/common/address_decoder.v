// ============================================================================
// Module: address_decoder.v
// Project: Project 9 - Instruction and Data Memory Hierarchy
// Team Member: Krishna Gehlot (2401010236)
// Description: Memory Address Decoder and Address Space Partitioning.
//              Decodes processor byte addresses to generate chip-select lines
//              for Data RAM, Memory-Mapped I/O, and catches invalid addresses /
//              misalignment exceptions.
// ============================================================================

`timescale 1ns / 1ps

module address_decoder #(
    parameter ADDR_WIDTH = 32
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  mem_req,        // Active high memory request strobe
    output reg                   cs_ram,         // Chip select for Main Data RAM
    output reg                   cs_io,          // Chip select for Memory-Mapped I/O
    output reg                   addr_error,     // Out-of-bounds / Unmapped space
    output wire                  unaligned_error,// Misaligned 32-bit word access
    output wire [ADDR_WIDTH-1:0] local_addr      // Offset-adjusted address for target device
);

    // Address space definitions:
    // 0x0000_0000 - 0x0000_0FFF : Data RAM (4 KB window)
    // 0x0000_F000 - 0x0000_FFFF : Memory-Mapped I/O (MMIO)
    localparam RAM_BASE = 32'h0000_0000;
    localparam RAM_HIGH = 32'h0000_0FFF;
    localparam IO_BASE  = 32'h0000_F000;
    localparam IO_HIGH  = 32'h0000_FFFF;

    // Check for word alignment (bottom 2 bits must be zero for 32-bit words)
    assign unaligned_error = mem_req && (addr[1:0] != 2'b00);

    // Local address offset
    assign local_addr = (addr >= IO_BASE && addr <= IO_HIGH) ? (addr - IO_BASE) :
                        (addr >= RAM_BASE && addr <= RAM_HIGH) ? (addr - RAM_BASE) :
                        addr;

    always @(*) begin
        cs_ram     = 1'b0;
        cs_io      = 1'b0;
        addr_error = 1'b0;

        if (mem_req) begin
            if (addr >= RAM_BASE && addr <= RAM_HIGH) begin
                cs_ram = 1'b1;
            end else if (addr >= IO_BASE && addr <= IO_HIGH) begin
                cs_io = 1'b1;
            end else begin
                addr_error = 1'b1;
            end
        end
    end

endmodule
