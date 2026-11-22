#!/usr/bin/env python3
"""
============================================================================
Script: generate_phase2_diagrams.py
Project: Project 9 - Instruction and Data Memory Hierarchy (Phase 2)
Team: Decoders07
Authors: Anant Jain, Vipul Sharma, Krishna Gehlot, Aditya Kumar, Kartik Mehra
Description: Generates publication-quality architectural diagrams and
             performance benchmark charts for Phase 2 deliverables:
             1. Modified Harvard Cache Architecture Block Diagram
             2. Cache & Memory Controller FSM State Diagram
             3. Phase 2 AMAT & Cache Hit Rate Benchmark Charts
============================================================================
"""

import os
os.environ['MPLCONFIGDIR'] = '/tmp/matplotlib_cache'
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# ----------------------------------------------------------------------
# 1. Modified Harvard Architecture with L1 Caches Block Diagram
# ----------------------------------------------------------------------
def draw_modified_harvard_diagram(output_path):
    fig, ax = plt.subplots(figsize=(12, 7), dpi=300)
    ax.set_xlim(0, 120)
    ax.set_ylim(0, 70)
    ax.axis('off')

    # Title Banner
    ax.text(60, 66, "MODIFIED HARVARD ARCHITECTURE: LEVEL-1 CACHES & SHARED MAIN MEMORY",
            fontsize=12, fontweight='bold', ha='center', color="#0D47A1",
            bbox=dict(boxstyle="square,pad=0.4", facecolor="#E3F2FD", edgecolor="#90CAF9", linewidth=1.5))
    ax.text(60, 62.5, "Team Decoders07 | ECE/CSE Modern Computer Architecture | Project 9",
            fontsize=9, style='italic', ha='center', color="#1565C0")

    # 1. Processor Core Box
    core = patches.FancyBboxPatch((4, 12), 26, 46, boxstyle="round,pad=1",
                                  facecolor="#E1F5FE", edgecolor="#0288D1", linewidth=2.5)
    ax.add_patch(core)
    ax.text(17, 54, "PROCESSOR CORE\n(RISC Controller)", fontsize=10.5, fontweight='bold', ha='center', color="#01579B")

    # Internal Core Sub-modules
    pc = patches.Rectangle((6, 38), 10, 9, facecolor="#B3E5FC", edgecolor="#0288D1", linewidth=1.2)
    ax.add_patch(pc)
    ax.text(11, 42.5, "Program\nCounter", fontsize=8, fontweight='bold', ha='center', va='center')

    reg = patches.Rectangle((18, 38), 10, 9, facecolor="#B3E5FC", edgecolor="#0288D1", linewidth=1.2)
    ax.add_patch(reg)
    ax.text(23, 42.5, "Register\nFile (R0-15)", fontsize=8, fontweight='bold', ha='center', va='center')

    alu = patches.Rectangle((6, 18), 22, 13, facecolor="#B3E5FC", edgecolor="#0288D1", linewidth=1.2)
    ax.add_patch(alu)
    ax.text(17, 24.5, "ALU & Control Unit\n(Single-Cycle Execution)", fontsize=8.5, fontweight='bold', ha='center', va='center')

    # Core Stall logic annotation
    ax.text(17, 14, "Freeze when: CPU_STALL = 1", fontsize=7.5, fontweight='bold', ha='center', color="#C62828")

    # 2. Level-1 Instruction Cache (I-Cache)
    icache = patches.FancyBboxPatch((40, 38), 32, 20, boxstyle="round,pad=1",
                                    facecolor="#E8F5E9", edgecolor="#2E7D32", linewidth=2.5)
    ax.add_patch(icache)
    ax.text(56, 54, "LEVEL-1 INSTRUCTION CACHE", fontsize=10, fontweight='bold', ha='center', color="#1B5E20")
    ax.text(56, 49, "Direct-Mapped | 16 Lines | Tag: [31:6], Idx: [5:2]\nSingle-Cycle Hit Output (100% On-Chip)", fontsize=7.5, ha='center', color="#2E7D32")
    ax.text(56, 42, "Refill FSM: Cold/Capacity Miss Penalty = 3 Cycles\nHardware Telemetry: Hits, Misses, AMAT", fontsize=7.5, style='italic', ha='center', color="#388E3C")

    # 3. Level-1 Data Cache (D-Cache, Write-Through)
    dcache = patches.FancyBboxPatch((40, 10), 32, 22, boxstyle="round,pad=1",
                                    facecolor="#FFF3E0", edgecolor="#EF6C00", linewidth=2.5)
    ax.add_patch(dcache)
    ax.text(56, 28, "LEVEL-1 DATA CACHE", fontsize=10, fontweight='bold', ha='center', color="#E65100")
    ax.text(56, 23, "Direct-Mapped | 16 Lines | Write-Through Policy\nNo-Write-Allocate | 4-Byte Lane Masking", fontsize=7.5, ha='center', color="#E65100")
    ax.text(56, 15, "Read Hit: 1 Cycle (Cache Data)\nWrite Hit/Miss: 3 Cycles (Main Mem Write-Through)", fontsize=7.5, style='italic', ha='center', color="#D84315")

    # 4. Multi-Cycle Shared Main Memory
    mmem = patches.FancyBboxPatch((85, 10), 31, 48, boxstyle="round,pad=1",
                                  facecolor="#EDE7F6", edgecolor="#512DA8", linewidth=2.5)
    ax.add_patch(mmem)
    ax.text(100.5, 54, "SHARED MAIN MEMORY", fontsize=11, fontweight='bold', ha='center', color="#311B92")
    ax.text(100.5, 48, "Unified 4 KB Physical Storage\n(1024 Words x 32-bit)", fontsize=8.5, ha='center', color="#4527A0")

    # Arbiter inside Main Memory
    arb_box = patches.Rectangle((88, 30), 25, 13, facecolor="#D1C4E9", edgecolor="#512DA8", linewidth=1.5)
    ax.add_patch(arb_box)
    ax.text(100.5, 38.5, "Priority Bus Arbiter", fontsize=9, fontweight='bold', ha='center', color="#311B92")
    ax.text(100.5, 33, "D-Cache > I-Cache Priority\nWait-State Counter (LATENCY=2)", fontsize=7.5, ha='center', color="#4527A0")

    ax.text(100.5, 22, "Shared Backing Store\nRead/Write Zero-Skew Memory Array\nByte-Enabled Write Commit", fontsize=8, ha='center', color="#512DA8")
    ax.text(100.5, 13, "Access Penalty: 3 Cycles\n(1 Request + 2 Wait States)", fontsize=7.5, fontweight='bold', ha='center', color="#B71C1C")

    # ---------------- Connectors / Buses ----------------
    # CPU <-> I-Cache
    ax.annotate('', xy=(40, 50), xytext=(30, 50),
                arrowprops=dict(facecolor='#2E7D32', edgecolor='#2E7D32', width=1.5, headwidth=6))
    ax.text(35, 51.5, "PC [31:0]", fontsize=7, fontweight='bold', color="#2E7D32", ha='center')

    ax.annotate('', xy=(30, 44), xytext=(40, 44),
                arrowprops=dict(facecolor='#1B5E20', edgecolor='#1B5E20', width=1.5, headwidth=6))
    ax.text(35, 41.5, "Instr [31:0]", fontsize=7, fontweight='bold', color="#1B5E20", ha='center')

    # CPU <-> D-Cache
    ax.annotate('', xy=(40, 24), xytext=(30, 24),
                arrowprops=dict(facecolor='#D84315', edgecolor='#D84315', width=1.5, headwidth=6))
    ax.text(35, 25.5, "Addr, WData, BE", fontsize=7, fontweight='bold', color="#D84315", ha='center')

    ax.annotate('', xy=(30, 18), xytext=(40, 18),
                arrowprops=dict(facecolor='#E65100', edgecolor='#E65100', width=1.5, headwidth=6))
    ax.text(35, 15.5, "RData [31:0]", fontsize=7, fontweight='bold', color="#E65100", ha='center')

    # Stall Signals to CPU Core
    ax.annotate('', xy=(30, 33), xytext=(40, 40),
                arrowprops=dict(facecolor='#C62828', edgecolor='#C62828', width=1.2, headwidth=5, linestyle='--'))
    ax.annotate('', xy=(30, 31), xytext=(40, 28),
                arrowprops=dict(facecolor='#C62828', edgecolor='#C62828', width=1.2, headwidth=5, linestyle='--'))
    ax.text(35, 33.5, "CPU_STALL", fontsize=7.5, fontweight='bold', color="#C62828", ha='center')

    # I-Cache <-> Main Memory (Refill Bus)
    ax.annotate('', xy=(85, 47), xytext=(72, 47),
                arrowprops=dict(facecolor='#2E7D32', edgecolor='#2E7D32', width=2, headwidth=7))
    ax.text(78.5, 49, "I_Refill_Req", fontsize=7.5, fontweight='bold', color="#2E7D32", ha='center')

    ax.annotate('', xy=(72, 42), xytext=(85, 42),
                arrowprops=dict(facecolor='#1B5E20', edgecolor='#1B5E20', width=2, headwidth=7))
    ax.text(78.5, 39, "I_Line_Data+Rdy", fontsize=7.5, fontweight='bold', color="#1B5E20", ha='center')

    # D-Cache <-> Main Memory (Read/Write Bus)
    ax.annotate('', xy=(85, 23), xytext=(72, 23),
                arrowprops=dict(facecolor='#D84315', edgecolor='#D84315', width=2, headwidth=7))
    ax.text(78.5, 25, "D_Req+WriteThru", fontsize=7.5, fontweight='bold', color="#D84315", ha='center')

    ax.annotate('', xy=(72, 17), xytext=(85, 17),
                arrowprops=dict(facecolor='#E65100', edgecolor='#E65100', width=2, headwidth=7))
    ax.text(78.5, 14, "D_RData+Rdy", fontsize=7.5, fontweight='bold', color="#E65100", ha='center')

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Generated {output_path}")

# ----------------------------------------------------------------------
# 2. Cache & Memory Controller FSM State Diagram
# ----------------------------------------------------------------------
def draw_fsm_diagram(output_path):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5.5), dpi=300)

    # Subplot 1: L1 Instruction Cache & D-Cache FSM
    ax1.set_xlim(0, 100)
    ax1.set_ylim(0, 100)
    ax1.axis('off')
    ax1.set_title("L1 Cache Controller FSMs\n(I-Cache Refill & D-Cache Write-Through)", fontsize=11, fontweight='bold', color="#0D47A1")

    # State: S_IDLE
    idle = patches.Circle((30, 65), 16, facecolor="#E8F5E9", edgecolor="#2E7D32", linewidth=2.5)
    ax1.add_patch(idle)
    ax1.text(30, 68, "S_IDLE", fontsize=10, fontweight='bold', ha='center', color="#1B5E20")
    ax1.text(30, 60, "Hit Check\nSingle-Cycle\n(cpu_stall = 0)", fontsize=7, ha='center', color="#2E7D32")

    # State: S_REFILL (I-Cache)
    refill = patches.Circle((80, 75), 15, facecolor="#C8E6C9", edgecolor="#388E3C", linewidth=2)
    ax1.add_patch(refill)
    ax1.text(80, 78, "S_REFILL", fontsize=9.5, fontweight='bold', ha='center', color="#1B5E20")
    ax1.text(80, 70, "Wait for Mem Rdy\nRefill Tag/Data\n(I-Cache Miss)", fontsize=7, ha='center', color="#2E7D32")

    # State: S_WRITE_WAIT (D-Cache)
    wwait = patches.Circle((80, 30), 15, facecolor="#FFE0B2", edgecolor="#E65100", linewidth=2)
    ax1.add_patch(wwait)
    ax1.text(80, 33, "S_WRITE_WAIT", fontsize=8.5, fontweight='bold', ha='center', color="#BF360C")
    ax1.text(80, 25, "Mem Write-Thru\nWait for Mem Rdy\n(D-Cache Store)", fontsize=7, ha='center', color="#E65100")

    # State: S_READ_WAIT (D-Cache)
    rwait = patches.Circle((30, 20), 14, facecolor="#FFF3E0", edgecolor="#F57C00", linewidth=2)
    ax1.add_patch(rwait)
    ax1.text(30, 23, "S_READ_WAIT", fontsize=8.5, fontweight='bold', ha='center', color="#E65100")
    ax1.text(30, 16, "Refill on Load Miss\nWait for Mem Rdy", fontsize=7, ha='center', color="#EF6C00")

    # Transitions
    ax1.annotate('I-Miss: mem_req=1', xy=(65, 75), xytext=(45, 72),
                 arrowprops=dict(facecolor='#2E7D32', edgecolor='#2E7D32', width=1.5, headwidth=6),
                 fontsize=7.5, fontweight='bold', color="#2E7D32")

    ax1.annotate('mem_ready: refill line', xy=(44, 60), xytext=(65, 65),
                 arrowprops=dict(facecolor='#1B5E20', edgecolor='#1B5E20', width=1.5, headwidth=6),
                 fontsize=7.5, fontweight='bold', color="#1B5E20")

    ax1.annotate('Store: mem_we=1', xy=(65, 33), xytext=(42, 53),
                 arrowprops=dict(facecolor='#E65100', edgecolor='#E65100', width=1.5, headwidth=6),
                 fontsize=7.5, fontweight='bold', color="#E65100")

    ax1.annotate('mem_ready: ack', xy=(38, 52), xytext=(66, 25),
                 arrowprops=dict(facecolor='#BF360C', edgecolor='#BF360C', width=1.5, headwidth=6),
                 fontsize=7.5, fontweight='bold', color="#BF360C")

    # Subplot 2: Main Memory Arbiter FSM
    ax2.set_xlim(0, 100)
    ax2.set_ylim(0, 100)
    ax2.axis('off')
    ax2.set_title("Shared Main Memory Arbiter FSM\n(Priority Arbitration & Wait-State Latency)", fontsize=11, fontweight='bold', color="#311B92")

    m_idle = patches.Circle((25, 50), 16, facecolor="#EDE7F6", edgecolor="#512DA8", linewidth=2.5)
    ax2.add_patch(m_idle)
    ax2.text(25, 54, "S_IDLE", fontsize=10, fontweight='bold', ha='center', color="#311B92")
    ax2.text(25, 44, "Poll Requests\nPriority: D > I\nTimer <= LATENCY", fontsize=7.5, ha='center', color="#4527A0")

    m_wait = patches.Circle((75, 70), 16, facecolor="#D1C4E9", edgecolor="#512DA8", linewidth=2.5)
    ax2.add_patch(m_wait)
    ax2.text(75, 74, "S_WAIT", fontsize=10, fontweight='bold', ha='center', color="#311B92")
    ax2.text(75, 64, "Wait States\nTimer <= Timer - 1\n(Penalty Sim)", fontsize=7.5, ha='center', color="#512DA8")

    m_done = patches.Circle((75, 30), 16, facecolor="#B39DDB", edgecolor="#512DA8", linewidth=2.5)
    ax2.add_patch(m_done)
    ax2.text(75, 34, "S_DONE", fontsize=10, fontweight='bold', ha='center', color="#311B92")
    ax2.text(75, 24, "Assert Ready=1\nCommit Write (BE)\nZero-Skew Data", fontsize=7.5, ha='center', color="#311B92")

    # Transitions for Arbiter
    ax2.annotate('Req: Latch Client & Addr', xy=(60, 68), xytext=(38, 59),
                 arrowprops=dict(facecolor='#512DA8', edgecolor='#512DA8', width=1.5, headwidth=6),
                 fontsize=7.5, fontweight='bold', color="#512DA8")

    ax2.annotate('wait_timer <= 1', xy=(75, 46), xytext=(75, 54),
                 arrowprops=dict(facecolor='#512DA8', edgecolor='#512DA8', width=1.5, headwidth=6),
                 fontsize=7.5, fontweight='bold', color="#512DA8")

    ax2.annotate('Single-cycle Ready Pulse -> Deassert', xy=(39, 44), xytext=(60, 31),
                 arrowprops=dict(facecolor='#311B92', edgecolor='#311B92', width=1.5, headwidth=6),
                 fontsize=7.5, fontweight='bold', color="#311B92")

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Generated {output_path}")

# ----------------------------------------------------------------------
# 3. Phase 2 AMAT & Cache Hit Rate Benchmark Charts
# ----------------------------------------------------------------------
def draw_phase2_amat_charts(output_path):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5), dpi=300)

    # Chart 1: AMAT Comparison across Architectures
    labels = ['Pure Harvard\n(Phase 1)', 'Von Neumann\n(Phase 1)', 'Modified Harvard\n(Phase 2 Loop)']
    amat_i = [1.00, 1.47, 1.52]
    amat_d = [1.00, 1.47, 1.82]

    x = range(len(labels))
    width = 0.35

    rects1 = ax1.bar([p - width/2 for p in x], amat_i, width, label='Instruction AMAT', color='#1B5E20', edgecolor='black')
    rects2 = ax1.bar([p + width/2 for p in x], amat_d, width, label='Data AMAT', color='#E65100', edgecolor='black')

    ax1.set_ylabel('AMAT (Cycles per Access)', fontsize=11, fontweight='bold')
    ax1.set_title('Average Memory Access Time (AMAT)\n(Lower is Better)', fontsize=11, fontweight='bold')
    ax1.set_xticks(x)
    ax1.set_xticklabels(labels, fontsize=9.5, fontweight='bold')
    ax1.set_ylim(0, 2.5)
    ax1.legend(loc='upper left', frameon=True)
    ax1.grid(axis='y', linestyle='--', alpha=0.5)

    for r in rects1:
        h = r.get_height()
        ax1.text(r.get_x() + r.get_width()/2., h + 0.05, f"{h:.2f}", ha='center', va='bottom', fontsize=8.5, fontweight='bold')
    for r in rects2:
        h = r.get_height()
        ax1.text(r.get_x() + r.get_width()/2., h + 0.05, f"{h:.2f}", ha='center', va='bottom', fontsize=8.5, fontweight='bold')

    # Chart 2: Cache Hit Rates & Locality
    cache_types = ['L1 I-Cache\n(Instructions)', 'L1 D-Cache\n(Write-Through Data)']
    hit_rates = [82.76, 72.73]
    miss_rates = [17.24, 27.27]

    b1 = ax2.bar(cache_types, hit_rates, width=0.45, label='Hit Rate (%)', color='#2E7D32', edgecolor='black')
    b2 = ax2.bar(cache_types, miss_rates, width=0.45, bottom=hit_rates, label='Miss Rate (%)', color='#C62828', edgecolor='black')

    ax2.set_ylabel('Access Percentage (%)', fontsize=11, fontweight='bold')
    ax2.set_title('Phase 2 Cache Hit vs Miss Rates\n(Iterative Loop Benchmark: 5 Iterations)', fontsize=11, fontweight='bold')
    ax2.set_ylim(0, 115)
    ax2.legend(loc='upper right', frameon=True)
    ax2.grid(axis='y', linestyle='--', alpha=0.5)

    for i, (h, m) in enumerate(zip(hit_rates, miss_rates)):
        ax2.text(i, h/2, f"Hit: {h:.1f}%", ha='center', va='center', color='white', fontweight='bold', fontsize=9.5)
        ax2.text(i, h + m/2, f"Miss: {m:.1f}%", ha='center', va='center', color='white', fontweight='bold', fontsize=9.5)

    fig.suptitle('Decoders07 Phase 2 Performance: High Cache Locality Bridges Multi-Cycle Memory Penalty',
                 fontsize=12, fontweight='bold', y=1.02, color='#0D47A1')

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Generated {output_path}")

if __name__ == '__main__':
    os.makedirs('docs/diagrams', exist_ok=True)
    draw_modified_harvard_diagram('docs/diagrams/modified_harvard_cache_architecture.png')
    draw_fsm_diagram('docs/diagrams/cache_fsm_state_diagram.png')
    draw_phase2_amat_charts('docs/diagrams/phase2_amat_comparison_chart.png')
