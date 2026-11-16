#!/usr/bin/env python3
"""
Simple Assembler for Project 9 Harvard & Shared Memory Processor
Author: Kartik Mehra (2401020030)
"""

def encode_r(opcode, rd, rs1, rs2):
    return (opcode << 26) | (rd << 22) | (rs1 << 18) | (rs2 << 14)

def encode_i(opcode, rd, rs1, imm):
    imm14 = imm & 0x3FFF
    return (opcode << 26) | (rd << 22) | (rs1 << 18) | imm14

def encode_j(opcode, target):
    return (opcode << 26) | (target & 0x03FFFFFF)

# Program instructions:
# R10 will hold data base address 0x0100 (256)
program = [
    # 0x00: ADDI R10, R0, 256  (Data Base Address = 0x0100)
    encode_i(0x03, 10, 0, 256),
    # 0x04: ADDI R1, R0, 10    (R1 = 10)
    encode_i(0x03, 1, 0, 10),
    # 0x08: ADDI R2, R0, 20    (R2 = 20)
    encode_i(0x03, 2, 0, 20),
    # 0x0C: ADD  R3, R1, R2    (R3 = 30)
    encode_r(0x01, 3, 1, 2),
    # 0x10: STORE R3, 0(R10)   (Mem[0x100] = 30)
    encode_i(0x09, 0, 10, 0) | (3 << 14),
    # 0x14: ADDI R4, R0, 5     (R4 = 5)
    encode_i(0x03, 4, 0, 5),
    # 0x18: STORE R4, 4(R10)   (Mem[0x104] = 5)
    encode_i(0x09, 0, 10, 4) | (4 << 14),
    # 0x1C: LOAD  R5, 0(R10)   (R5 = Mem[0x100] = 30)
    encode_i(0x08, 5, 10, 0),
    # 0x20: LOAD  R6, 4(R10)   (R6 = Mem[0x104] = 5)
    encode_i(0x08, 6, 10, 4),
    # 0x24: ADD   R7, R5, R6   (R7 = 35)
    encode_r(0x01, 7, 5, 6),
    # 0x28: STORE R7, 8(R10)   (Mem[0x108] = 35)
    encode_i(0x09, 0, 10, 8) | (7 << 14),
    # 0x2C: LOAD  R8, 8(R10)   (R8 = Mem[0x108] = 35)
    encode_i(0x08, 8, 10, 8),
    # 0x30: SUB   R9, R8, R1   (R9 = 35 - 10 = 25)
    encode_r(0x02, 9, 8, 1),
    # 0x34: STORE R9, 12(R10)  (Mem[0x10C] = 25)
    encode_i(0x09, 0, 10, 12) | (9 << 14),
    # 0x38: HALT
    (0x3F << 26)
]

# Write padded memory image for 256 words
with open("tb/program.mem", "w") as f:
    for i in range(256):
        word = program[i] if i < len(program) else 0x00000013
        f.write(f"{word:08X}\n")

# Write padded memory image for 512 words
with open("tb/shared_program.mem", "w") as f:
    for i in range(512):
        word = program[i] if i < len(program) else 0x00000013
        f.write(f"{word:08X}\n")

print(f"Generated clean padded memory images for tb/program.mem and tb/shared_program.mem")
