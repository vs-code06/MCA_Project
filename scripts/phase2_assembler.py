#!/usr/bin/env python3
"""
============================================================================
Script: phase2_assembler.py
Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
Team: Decoders07
Description: Assembles Phase 2 benchmark programs (linear and iterative loop)
             into hexadecimal memory images for L1 Cache and Main Memory.
============================================================================
"""

import os

def encode_r(opcode, rd, rs1, rs2):
    return (opcode << 26) | (rd << 22) | (rs1 << 18) | (rs2 << 14)

def encode_i(opcode, rd, rs1, imm):
    imm14 = imm & 0x3FFF
    return (opcode << 26) | (rd << 22) | (rs1 << 18) | imm14

def encode_j(opcode, target):
    return (opcode << 26) | (target & 0x03FFFFFF)

# ============================================================================
# Benchmark 1: Phase 1 Linear Arithmetic Benchmark (15 instructions)
# Used for direct 3-way architecture comparison
# ============================================================================
linear_program = [
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

# ============================================================================
# Benchmark 2: Iterative Loop Benchmark
# Designed to showcase temporal locality (Cache Hit Rate > 85%)
# Computes triangular sum: 5 + 4 + 3 + 2 + 1 = 15
# Interleaves LOAD and STORE to test D-Cache locality
# ============================================================================
# Registers:
# R10 = Base Address (0x100)
# R1  = Loop Counter (initially 5, decrements to 0)
# R2  = Running Sum (initially 0, accumulates to 15)
# R3  = Temporary loaded value
loop_program = [
    # 0x00: ADDI R10, R0, 256     (R10 = 0x0100)
    encode_i(0x03, 10, 0, 256),
    # 0x04: ADDI R1, R0, 5        (R1 = 5, counter)
    encode_i(0x03, 1, 0, 5),
    # 0x08: ADDI R2, R0, 0        (R2 = 0, accumulator)
    encode_i(0x03, 2, 0, 0),
    
    # --- LOOP BODY (Addresses 0x0C to 0x20) ---
    # 0x0C: ADD  R2, R2, R1       (R2 = R2 + R1)
    encode_r(0x01, 2, 2, 1),
    # 0x10: STORE R2, 0(R10)      (Mem[0x100] = Running Sum)
    encode_i(0x09, 0, 10, 0) | (2 << 14),
    # 0x14: LOAD  R3, 0(R10)      (R3 = Mem[0x100], tests D-Cache hit)
    encode_i(0x08, 3, 10, 0),
    # 0x18: ADDI R1, R1, -1       (R1 = R1 - 1)
    encode_i(0x03, 1, 1, -1),
    # 0x1C: BNE  R1, R0, -4       (If R1 != 0, branch back to 0x0C. Offset = -4 instructions)
    encode_i(0x11, 0, 1, -4),

    # --- LOOP EXIT ---
    # 0x20: STORE R2, 4(R10)      (Mem[0x104] = Final Sum = 15)
    encode_i(0x09, 0, 10, 4) | (2 << 14),
    # 0x24: HALT
    (0x3F << 26)
]

def write_mem_file(filename, instructions, total_words=1024):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "w") as f:
        for i in range(total_words):
            word = instructions[i] if i < len(instructions) else 0x00000013 # NOP
            f.write(f"{word:08X}\n")

if __name__ == "__main__":
    write_mem_file("tb/phase2_linear_main_mem.mem", linear_program, 1024)
    write_mem_file("tb/phase2_loop_main_mem.mem", loop_program, 1024)
    print("Generated Phase 2 memory files:")
    print("  - tb/phase2_linear_main_mem.mem (Linear benchmark)")
    print("  - tb/phase2_loop_main_mem.mem   (Iterative loop benchmark)")
