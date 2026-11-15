# Instruction and Data Memory Hierarchy (Project 9)
### Modern Computer Architecture (MCA) — Phase I Project

[![Verilog HDL](https://img.shields.io/badge/Language-Verilog%20HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog%20%2B%20GTKWave-brightgreen.svg)](https://steveicarus.github.io/iverilog/)
[![Status](https://img.shields.io/badge/Phase%20I-100%25%20Completed-success.svg)]()

---

## 👥 Team Members & Roles

| Name | Roll Number | Individual Project Role |
|---|---|---|
| **Anant Jain** | `2401010066` | System Architecture & Instruction Memory Subsystem Lead |
| **Vipul Sharma** | `2401010505` | Data Memory Subsystem & Controller Integration Lead |
| **Krishna Gehlot** | `2401010236` | Address Decoding & Interconnect Engineer |
| **Aditya Kumar** | `2401010029` | Shared Memory Baseline & Comparative Benchmark Engineer |
| **Kartik Mehra** | `2401020030` | Verification, Testbench Development & Documentation Lead |

*Newton School of Technology, Rishihood University, Sonipat, India*

---

## 🎥 Phase I Prototype Video Demonstration (15 Marks)
- **Demo Video Link:** `[Click Here to Watch Video Demonstration]` *(Add your unlisted YouTube or Google Drive link here)*
- **Duration:** Strictly $\le 5$ minutes
- **3-Speaker Video Script:** [docs/video/video_presentation_script.md](docs/video/video_presentation_script.md)
  - **Speaker 1 (Start):** Anant Jain — Project overview, introduces all 5 team members, and explains motivation.
  - **Speaker 2 (Middle):** Kartik Mehra — Easy, high-level walkthrough of the Harvard block diagram and separate memory paths.
  - **Speaker 3 (End):** Vipul Sharma — Shared-memory comparison, terminal demo running `./sim/run_sim.sh`, and benchmark results.
- **Slide Deck Outline:** [docs/video/presentation_slides_outline.md](docs/video/presentation_slides_outline.md)

---

## 📑 IEEE Project Report (10 Marks)
- **Overleaf-Ready LaTeX Source:** [docs/report/IEEE_Project_Report_Phase1.tex](docs/report/IEEE_Project_Report_Phase1.tex)
- **Comprehensive Markdown Report:** [docs/report/IEEE_Project_Report_Phase1.md](docs/report/IEEE_Project_Report_Phase1.md)
- Contains Abstract, Literature Review, Proposed Solution, Hardware RTL Architecture, Verification Results, Individual Contributions, and IEEE References.

---

## 📌 Project Objective & Overview

The objective of this project is to implement, evaluate, and benchmark a **Harvard-style memory organization** with completely separate instruction and data paths against an equivalent **Von Neumann (Shared Memory) baseline**, analyzing timing, structural hazards, bus arbitration, and simultaneous access opportunities.

### Key Concepts:
1. **Harvard Architecture:** Segregated storage arrays and independent buses for instructions and data allow the CPU to fetch instructions while concurrently reading or writing data in the same clock cycle ($\text{CPI} = 1.00$).
2. **Von Neumann Architecture (Shared Memory):** A unified bus and memory array forces serialization between instruction fetch and data operand access, causing a **structural hazard** during memory operations (`LOAD`/`STORE`) and degrading performance ($\text{CPI} > 1.00$).

---

## 🏛️ Architectural Block Diagrams

### 1. Harvard Memory Architecture (Parallel Buses)
```
                               +------------------------------------+
                               |           PROCESSOR CORE           |
                               |   (PC, Registers, ALU, Control)    |
                               +--------+------------------+--------+
                                        |                  |
                      Instruction Bus   |                  |   Data Bus
                        [31:0]          |                  |    [31:0]
                                        v                  v
                               +----------------+  +----------------+
                               |  INSTRUCTION   |  |  DATA MEMORY   |
                               |  MEMORY (1 KB) |  |  SUBSYSTEM     |
                               | (Dedicated RO) |  | (RAM + MMIO)   |
                               +----------------+  +----------------+
                               Simultaneous Fetch & Data Access (CPI = 1.00)
```
*(High-resolution publication diagram: [docs/diagrams/harvard_architecture_block_diagram.png](docs/diagrams/harvard_architecture_block_diagram.png))*

### 2. Von Neumann Comparative Baseline (Unified Bus & Arbiter)
```
                               +------------------------------------+
                               |           PROCESSOR CORE           |
                               |  (Stalls 1 cycle on LOAD/STORE)    |
                               +-----------------+------------------+
                                                 |
                                     Fetch & Data Requests
                                                 |
                                                 v
                               +------------------------------------+
                               |        2-PHASE BUS ARBITER         |
                               |   (Phase 1: Fetch | Phase 2: Data) |
                               +-----------------+------------------+
                                                 |
                                        Shared 32-bit Bus
                                                 |
                                                 v
                               +------------------------------------+
                               |     SHARED UNIFIED MEMORY (2 KB)   |
                               |       (Code + Application Data)    |
                               +------------------------------------+
                               Structural Hazard Stalls (CPI = 1.47)
```
*(High-resolution publication diagram: [docs/diagrams/von_neumann_comparison_diagram.png](docs/diagrams/von_neumann_comparison_diagram.png))*

---

## 🗺️ System Memory Map & Address Partitioning

The `address_decoder.v` module partitions the 32-bit address space and validates word alignment:

| Address Range | Target Subsystem | Functionality |
|---|---|---|
| `0x0000_0000` – `0x0000_0FFF` | **Data RAM (1 KB)** | Primary application operand storage |
| `0x0000_F000` | **MMIO: LED Register** | Hardware status & diagnostic LED outputs |
| `0x0000_F004` | **MMIO: Console Char** | Simulated ASCII character telemetry |
| `0x0000_F008` | **MMIO: Cycle Counter** | High-precision hardware performance counter |
| Others | **Invalid Address Space** | Asserts `addr_error` bus fault |

- **Misalignment Protection:** Checks if $\text{addr}[1:0] \neq 2\text{'b00}$ during word access, asserting `unaligned_error`.

---

## 📊 Empirical Verification & Benchmark Results

The benchmark program (15 instructions: ALU arithmetic, register moves, and interleaved `STORE` and `LOAD` operations) was executed across both systems under a 100 MHz clock ($T = 10\text{ ns}$):

| Performance Metric | Harvard Architecture | Shared Memory (Von Neumann) | Impact / Observations |
|---|---|---|---|
| **Instructions Executed** | 15 | 15 | Identical instruction workload |
| **Total Clock Cycles** | **15 Cycles** | **22 Cycles** | **Harvard saves 7 clock cycles (31.8% faster)** |
| **Structural Hazard Stalls** | **0 Cycles** | **7 Cycles** | Von Neumann stalls 1 cycle per `LOAD`/`STORE` |
| **Simultaneous Accesses** | **7 Cycles** | **0 Cycles** | Concurrent instruction fetch & data access |
| **Cycles Per Instruction (CPI)** | **1.00** | **1.47** | Harvard achieves ideal single-cycle execution |
| **Throughput (IPC)** | **1.00** | **0.68** | Higher instruction-level throughput |
| **Execution Time (@100 MHz)** | **150 ns** | **220 ns** | **1.47x empirical speedup!** |

### Automated Assertion Checks (100% PASS)
- `[PASS] Data Memory[0x0000_0100] = 30` (Expected: 30)
- `[PASS] Data Memory[0x0000_0104] = 5`  (Expected: 5)
- `[PASS] Data Memory[0x0000_0108] = 35` (Expected: 35)
- `[PASS] Data Memory[0x0000_010C] = 25` (Expected: 25)
- `[PASS] Register File R1=10, R2=20, R3=30, R5=30, R6=5, R7=35, R8=35, R9=25`

---

## 📁 Repository Directory Structure

```text
Mca_project/
├── rtl/
│   ├── common/                       # Shared Foundation Modules
│   │   ├── program_counter.v         # 32-bit PC with +4 increment and branch redirection
│   │   ├── address_decoder.v         # Memory mapping and word alignment checker
│   │   └── simple_processor.v        # 16-register RISC controller core with ALU
│   ├── harvard/                      # Harvard Architecture Subsystem
│   │   ├── instruction_memory.v     # Dedicated 1 KB instruction memory (ROM/RAM)
│   │   ├── data_memory.v            # Dedicated 1 KB data memory with 4-byte lanes
│   │   ├── memory_controller.v      # Read/write control unit & MMIO registers
│   │   └── harvard_top.v            # Top-level Harvard architecture integration
│   └── von_neumann/                  # Comparative Von Neumann Subsystem
│       ├── arbiter.v                # 2-phase bus arbiter for structural hazard resolution
│       └── shared_memory_top.v      # Comparative Von Neumann unified-memory baseline
├── tb/                                # Verification & Testbenches
│   ├── tb_harvard_memory.v          # Harvard verification testbench with assertions
│   ├── tb_shared_vs_harvard.v       # Comparative benchmark testbench (speedup & CPI)
│   ├── tb_shared_memory.v           # Standalone shared memory debug testbench
│   ├── program.mem                  # Assembled machine code for instruction memory
│   └── shared_program.mem           # Unified memory hexadecimal image
├── sim/                               # Simulation Scripts & Waveforms
│   ├── run_sim.sh                   # Automated compile & run script (Icarus Verilog)
│   ├── generate_waves.sh            # GTKWave launcher
│   ├── harvard_sim.vcd              # Generated Harvard VCD waveform trace
│   └── comparison_sim.vcd           # Generated comparative benchmark VCD trace
├── docs/                              # Project Documentation & Deliverables
│   ├── report/
│   │   ├── IEEE_Project_Report_Phase1.tex # Overleaf-ready IEEE LaTeX report
│   │   └── IEEE_Project_Report_Phase1.md  # Comprehensive Markdown report
│   ├── diagrams/                    # Publication-quality architectural diagrams (PNG only)
│   │   ├── harvard_architecture_block_diagram.png
│   │   ├── von_neumann_comparison_diagram.png
│   │   ├── benchmark_comparison_chart.png
│   │   └── timing_diagram.md        # Cycle-by-cycle bus activity analysis
│   ├── video/                       # Video demonstration assets (15 Marks)
│   │   ├── video_presentation_script.md   # 3-speaker timed script (Anant, Kartik, Vipul)
│   │   └── presentation_slides_outline.md # Slide deck presentation outline
│   └── project_plan_phase1_phase2.md # Clean Phase 1 vs Phase 2 roadmap
├── scripts/
│   ├── assembler.py                 # Python assembler for generating .mem files
│   └── generate_diagrams.py         # Python matplotlib diagram generator (PNG only)
└── README.md                        # Root repository documentation
```

---

## 🚀 How to Run the Simulations

### Prerequisites
- **Icarus Verilog (`iverilog`)** and **`vvp`** runtime
- **Python 3**
- *(Optional)* **GTKWave** for inspecting `.vcd` waveform traces

On macOS (via Homebrew):
```bash
brew install icarus-verilog gtkwave
```

### 1. One-Click Automated Simulation
Run the automated simulation script from the repository root:
```bash
./sim/run_sim.sh
```
This script will:
1. Run `scripts/assembler.py` to assemble the benchmark instructions.
2. Compile and execute `tb_harvard_memory.v`, verifying all memory and register assertions.
3. Compile and execute `tb_shared_vs_harvard.v`, outputting the side-by-side performance benchmark table.
4. Output VCD waveform files into `sim/`.

### 2. Viewing Waveforms in GTKWave
```bash
./sim/generate_waves.sh
```
Or open directly:
```bash
gtkwave sim/harvard_sim.vcd
gtkwave sim/comparison_sim.vcd
```

---

## 🗓️ Phase 1 vs Phase 2 Division

| Dimension | Phase 1 (Completed — 30% Weightage) | Phase 2 (Future Work — 70% Weightage) |
|---|---|---|
| **Core Architecture** | Pure Harvard architecture with separate 1 KB I-Mem and D-Mem. | **Simple Direct-Mapped L1 Caches** (I-Cache & D-Cache) backed by a **Shared Main Memory** (Modified Harvard). |
| **Processor Core** | Single-cycle RISC controller core with 16 registers & ALU. | Simple pipelined controller with basic Load-Use hazard stalling. |
| **Comparative Study** | Empirical comparison against single-port Von Neumann memory. | Simple Cache Hit/Miss evaluation and Average Memory Access Time (AMAT). |
| **Deliverables** | Interim IEEE Report, 5-Min Video, GitHub Repository. | Final IEEE Report, Interview Defense, and Cache Performance Analysis. |
