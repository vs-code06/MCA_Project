#!/usr/bin/env python3
"""
Diagram and Chart Generator for MCA Project 9 IEEE Report & Documentation
Generates publication-quality architectural block diagrams and benchmark charts.
Authors: Anant Jain, Vipul Sharma, Krishna Gehlot, Aditya Kumar, Kartik Mehra
"""

import os
os.environ['MPLCONFIGDIR'] = '/tmp/matplotlib_cache'
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# ----------------------------------------------------------------------
# 1. Harvard Architecture Block Diagram
# ----------------------------------------------------------------------
def draw_harvard_block_diagram(output_path):
    fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 60)
    ax.axis('off')

    # CPU Block
    cpu = patches.FancyBboxPatch((5, 10), 32, 42, boxstyle="round,pad=1",
                                 facecolor="#E1F5FE", edgecolor="#0288D1", linewidth=2.5)
    ax.add_patch(cpu)
    ax.text(21, 48, "PROCESSOR CORE\n(RISC Controller)", fontsize=12, fontweight='bold', ha='center', color="#01579B")

    # Internal CPU blocks
    pc = patches.Rectangle((8, 32), 12, 10, facecolor="#B3E5FC", edgecolor="#0288D1", linewidth=1.5)
    ax.add_patch(pc)
    ax.text(14, 37, "Program\nCounter", fontsize=9, fontweight='bold', ha='center', va='center')

    reg = patches.Rectangle((22, 32), 12, 10, facecolor="#B3E5FC", edgecolor="#0288D1", linewidth=1.5)
    ax.add_patch(reg)
    ax.text(28, 37, "Register\nFile (R0-R15)", fontsize=9, fontweight='bold', ha='center', va='center')

    alu = patches.Rectangle((8, 14), 26, 12, facecolor="#B3E5FC", edgecolor="#0288D1", linewidth=1.5)
    ax.add_patch(alu)
    ax.text(21, 20, "Arithmetic Logic Unit (ALU) &\nControl Unit", fontsize=9, fontweight='bold', ha='center', va='center')

    # Instruction Memory Block
    imem = patches.FancyBboxPatch((58, 34), 36, 18, boxstyle="round,pad=1",
                                  facecolor="#E8F5E9", edgecolor="#388E3C", linewidth=2.5)
    ax.add_patch(imem)
    ax.text(76, 47, "INSTRUCTION MEMORY", fontsize=11, fontweight='bold', ha='center', color="#1B5E20")
    ax.text(76, 42, "Dedicated Read-Only / ROM (1 KB)\nWord-Aligned Byte Addressing", fontsize=8.5, ha='center', color="#2E7D32")
    ax.text(76, 37, "Independent Instruction Port", fontsize=8, style='italic', ha='center', color="#388E3C")

    # Data Memory Subsystem Block
    dmem = patches.FancyBboxPatch((58, 6), 36, 22, boxstyle="round,pad=1",
                                  facecolor="#FFF3E0", edgecolor="#F57C00", linewidth=2.5)
    ax.add_patch(dmem)
    ax.text(76, 23, "DATA MEMORY SUBSYSTEM", fontsize=11, fontweight='bold', ha='center', color="#E65100")
    ax.text(76, 18, "Address Decoder (CS_RAM, CS_IO)\nRead/Write Controller + MMIO", fontsize=8.5, ha='center', color="#EF6C00")
    ax.text(76, 12, "Dedicated Data RAM (1 KB)\n4-Bit Byte Enables (Byte/Word RW)", fontsize=8, style='italic', ha='center', color="#F57C00")

    # Buses
    # 1. Instruction Address Bus (CPU -> IMEM)
    ax.annotate('', xy=(58, 44), xytext=(37, 44),
                arrowprops=dict(facecolor='#2E7D32', edgecolor='#2E7D32', width=2, headwidth=8))
    ax.text(47.5, 46, "Instr Addr [31:0]", fontsize=8.5, fontweight='bold', color="#2E7D32", ha='center')

    # 2. Instruction Data Bus (IMEM -> CPU)
    ax.annotate('', xy=(37, 38), xytext=(58, 38),
                arrowprops=dict(facecolor='#1B5E20', edgecolor='#1B5E20', width=2, headwidth=8))
    ax.text(47.5, 35, "Instruction [31:0]", fontsize=8.5, fontweight='bold', color="#1B5E20", ha='center')

    # 3. Data Address & Control Bus (CPU -> DMEM)
    ax.annotate('', xy=(58, 18), xytext=(37, 18),
                arrowprops=dict(facecolor='#D84315', edgecolor='#D84315', width=2, headwidth=8))
    ax.text(47.5, 20, "Data Addr + WE + BE", fontsize=8.5, fontweight='bold', color="#D84315", ha='center')

    # 4. Data Read/Write Bus (Bidirectional CPU <-> DMEM)
    ax.annotate('', xy=(58, 11), xytext=(37, 11),
                arrowprops=dict(facecolor='#E65100', edgecolor='#E65100', width=2, headwidth=8))
    ax.annotate('', xy=(37, 11), xytext=(58, 11),
                arrowprops=dict(facecolor='#E65100', edgecolor='#E65100', width=2, headwidth=8))
    ax.text(47.5, 8, "Data Read/Write [31:0]", fontsize=8.5, fontweight='bold', color="#E65100", ha='center')

    # Annotation highlight
    ax.text(50, 56, "HARVARD ARCHITECTURE: SIMULTANEOUS FETCH & DATA ACCESS (CPI = 1.0)",
            fontsize=12, fontweight='bold', ha='center', color="#0D47A1",
            bbox=dict(boxstyle="square,pad=0.4", facecolor="#E3F2FD", edgecolor="#90CAF9"))

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Generated {output_path}")

# ----------------------------------------------------------------------
# 2. Von Neumann Architecture Block Diagram
# ----------------------------------------------------------------------
def draw_von_neumann_diagram(output_path):
    fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 60)
    ax.axis('off')

    # CPU Block
    cpu = patches.FancyBboxPatch((5, 12), 30, 38, boxstyle="round,pad=1",
                                 facecolor="#E1F5FE", edgecolor="#0288D1", linewidth=2.5)
    ax.add_patch(cpu)
    ax.text(20, 44, "PROCESSOR CORE\n(RISC Controller)", fontsize=11, fontweight='bold', ha='center', color="#01579B")

    ax.text(20, 30, "Program Counter\nRegister File\nALU", fontsize=9, ha='center', color="#0277BD")
    ax.text(20, 18, "[Stalls during Data Cycle]", fontsize=8.5, fontweight='bold', ha='center', color="#C62828")

    # Arbiter Block
    arb = patches.FancyBboxPatch((42, 16), 18, 30, boxstyle="round,pad=1",
                                 facecolor="#FCE4EC", edgecolor="#C2185B", linewidth=2)
    ax.add_patch(arb)
    ax.text(51, 40, "BUS ARBITER", fontsize=10, fontweight='bold', ha='center', color="#880E4F")
    ax.text(51, 31, "Resolves Structural\nConflict:\nFetch vs Load/Store\n(Injects 1-Cycle Stall)", fontsize=8, ha='center', color="#AD1457")

    # Shared Memory Block
    smem = patches.FancyBboxPatch((68, 12), 28, 38, boxstyle="round,pad=1",
                                  facecolor="#EDE7F6", edgecolor="#512DA8", linewidth=2.5)
    ax.add_patch(smem)
    ax.text(82, 44, "SHARED MEMORY", fontsize=11, fontweight='bold', ha='center', color="#311B92")
    ax.text(82, 34, "Single Unified\nPhysical Port\n(Holds Code & Data)", fontsize=9, ha='center', color="#4527A0")
    ax.text(82, 20, "Von Neumann Bottleneck:\nSerializes Access", fontsize=8.5, fontweight='bold', ha='center', color="#B71C1C")

    # Buses
    ax.annotate('', xy=(42, 38), xytext=(35, 38),
                arrowprops=dict(facecolor='#0288D1', edgecolor='#0288D1', width=1.5, headwidth=6))
    ax.text(38.5, 40, "Fetch Req", fontsize=7.5, ha='center')

    ax.annotate('', xy=(42, 24), xytext=(35, 24),
                arrowprops=dict(facecolor='#0288D1', edgecolor='#0288D1', width=1.5, headwidth=6))
    ax.text(38.5, 26, "Data Req", fontsize=7.5, ha='center')

    ax.annotate('', xy=(35, 18), xytext=(42, 18),
                arrowprops=dict(facecolor='#C2185B', edgecolor='#C2185B', width=1.5, headwidth=6))
    ax.text(38.5, 14, "Stall", fontsize=8, fontweight='bold', color="#C2185B", ha='center')

    # Single Bus from Arbiter to Shared Memory
    ax.annotate('', xy=(68, 31), xytext=(60, 31),
                arrowprops=dict(facecolor='#311B92', edgecolor='#311B92', width=3, headwidth=8))
    ax.annotate('', xy=(60, 31), xytext=(68, 31),
                arrowprops=dict(facecolor='#311B92', edgecolor='#311B92', width=3, headwidth=8))
    ax.text(64, 35, "Shared Address & Data Bus\n(Time-Multiplexed)", fontsize=8, fontweight='bold', ha='center', color="#311B92")

    # Title Banner
    ax.text(50, 55, "VON NEUMANN ARCHITECTURE: UNIFIED BUS & STRUCTURAL HAZARDS (CPI > 1.0)",
            fontsize=11.5, fontweight='bold', ha='center', color="#B71C1C",
            bbox=dict(boxstyle="square,pad=0.4", facecolor="#FFEBEE", edgecolor="#EF9A9A"))

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Generated {output_path}")

# ----------------------------------------------------------------------
# 3. Performance Benchmark Comparison Chart
# ----------------------------------------------------------------------
def draw_benchmark_chart(output_path):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 4.5), dpi=300)

    categories = ['Harvard\nArchitecture', 'Von Neumann\n(Shared Memory)']
    cycles = [15, 22]
    stalls = [0, 7]
    cpi = [1.00, 1.47]

    colors_cycles = ['#2E7D32', '#C62828']
    colors_cpi = ['#1565C0', '#D84315']

    # Subplot 1: Total Cycles & Stalls
    bars1 = ax1.bar(categories, cycles, color=colors_cycles, width=0.45, edgecolor='black', linewidth=1.2)
    ax1.set_ylabel('Clock Cycles', fontsize=11, fontweight='bold')
    ax1.set_title('Execution Clock Cycles\n(15 Benchmark Instructions)', fontsize=11, fontweight='bold')
    ax1.set_ylim(0, 26)
    ax1.grid(axis='y', linestyle='--', alpha=0.6)

    for bar in bars1:
        yval = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2.0, yval + 0.6, f"{int(yval)} Cycles", ha='center', va='bottom', fontweight='bold')

    ax1.text(1, 14, "(Includes 7\nStall Cycles)", ha='center', color='white', fontweight='bold', fontsize=9)

    # Subplot 2: Cycles Per Instruction (CPI)
    bars2 = ax2.bar(categories, cpi, color=colors_cpi, width=0.45, edgecolor='black', linewidth=1.2)
    ax2.set_ylabel('CPI (Cycles Per Instruction)', fontsize=11, fontweight='bold')
    ax2.set_title('Average CPI Comparison\n(Lower is Better)', fontsize=11, fontweight='bold')
    ax2.set_ylim(0, 1.8)
    ax2.grid(axis='y', linestyle='--', alpha=0.6)

    for bar in bars2:
        yval = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2.0, yval + 0.04, f"{yval:.2f} CPI", ha='center', va='bottom', fontweight='bold')

    # Add speedup annotation
    fig.suptitle('Empirical Benchmark: Harvard Architecture Achieves 1.47x Speedup (31.8% Fewer Cycles)',
                 fontsize=12, fontweight='bold', y=1.02, color='#0D47A1')

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Generated {output_path}")

if __name__ == '__main__':
    os.makedirs('docs/diagrams', exist_ok=True)
    draw_harvard_block_diagram('docs/diagrams/harvard_architecture_block_diagram.png')
    draw_von_neumann_diagram('docs/diagrams/von_neumann_comparison_diagram.png')
    draw_benchmark_chart('docs/diagrams/benchmark_comparison_chart.png')
