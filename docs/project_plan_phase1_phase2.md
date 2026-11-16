# Project Plan & Milestone Roadmap: Phase 1 & Phase 2
## Project 9: Instruction and Data Memory Hierarchy
**Team:** Decoders07  
**Course:** Modern Computer Architecture (MCA)  
**Team Members:**
1. **Anant Jain** (2401010066)
2. **Vipul Sharma** (2401010505)
3. **Krishna Gehlot** (2401010236)
4. **Aditya Kumar** (2401010029)
5. **Kartik Mehra** (2401020030)

---

## 1. Project Overview & Scope Division

The project evaluates the classical architectural trade-off between the **Harvard Memory Organization** (independent instruction and data paths) and the **Von Neumann Architecture** (shared bus and unified memory).

To balance the workload and ensure a clean, manageable progression without excessive complexity, the project is structured as follows:

| Metric | Phase 1 (Completed | 30% Weightage) | Phase 2 (Future Work | 70% Weightage) |
|---|---|---|
| **Core Goal** | Synthesizable Harvard architecture RTL, separate I-Mem & D-Mem, address decoder, MMIO, comparative shared memory baseline. | Simple **Direct-Mapped L1 Caches** (I-Cache & D-Cache) backed by a **Shared Main Memory** (Modified Harvard). |
| **Processor Model** | Single-cycle controller core with 16 registers, ALU, and dual memory buses. | Simple pipelined controller with basic Load-Use hazard stalling. |
| **Memory Hierarchy** | Level-1 Dedicated I-Mem (1 KB) and D-Mem (1 KB). | Split Level-1 Caches with Hit/Miss FSM connected to a Shared Lower-Level Memory. |
| **Metrics Evaluated** | Execution Cycles, Structural Hazard Stalls, CPI ($1.00$ vs $1.47$), Empirical Speedup ($1.47\times$). | Cache Hit Rates, Miss Penalties, Average Memory Access Time (AMAT), CPI under cache latency. |
| **Deliverables** | Interim IEEE Report, 5-Minute Video, RTL & Testbenches. | Final IEEE Report, Interview Viva Defense, and Cache Evaluation. |

---

## 2. Phase 2: Manageable & Realistic Architecture Plan

To ensure Phase 2 is well-scoped, achievable, and easy to explain during the final project interview, Phase 2 focuses on four clear, student-friendly milestones:

### Milestone 1: Simple Direct-Mapped L1 Caches
- **L1 Instruction Cache (I-Cache):**
  - Small direct-mapped cache (e.g. 8 lines, 1 word per line).
  - Includes a Valid Bit array and Tag comparison logic.
  - Generates `hit` or `miss` signal. On hit: returns instruction in 1 cycle.
- **L1 Data Cache (D-Cache):**
  - Small direct-mapped cache with Write-Through policy (simple and robust, avoids complex dirty-bit evictions).
  - On write: updates cache and forwards write to main memory.

### Milestone 2: Shared Lower-Level Memory (Modified Harvard Model)
- A shared Main Memory (e.g. 512 words) backing both L1 I-Cache and L1 D-Cache.
- When an I-Cache or D-Cache miss occurs, a simple 2-state memory controller refills the line from Main Memory (taking 2 wait-state cycles).

### Milestone 3: AMAT & Cache Performance Benchmarking
- Measure empirical cache performance metrics:
  $$\text{AMAT} = \text{Hit Time} + (\text{Miss Rate} \times \text{Miss Penalty})$$
- Demonstrate how spatial and temporal locality in small loops yields high cache hit rates ($>85\%$), preserving CPI close to $1.0$.

### Milestone 4: Final Deliverables & Interview Preparation
- Update the final IEEE Project Report with cache architecture diagrams, hit/miss equations, and waveform traces.
- Prepare an interview defense guide so all five members can answer common viva questions with ease.

---

## 3. Phase 1 Checklist (Complete)

- [x] Independent instruction memory (`rtl/harvard/instruction_memory.v`)
- [x] Byte-addressable data memory with 4 byte lanes (`rtl/harvard/data_memory.v`)
- [x] Address decoder with memory mapping & alignment check (`rtl/common/address_decoder.v`)
- [x] Read/Write control unit with MMIO registers (`rtl/harvard/memory_controller.v`)
- [x] 16-register RISC controller core (`rtl/common/simple_processor.v`)
- [x] Harvard top-level system (`rtl/harvard/harvard_top.v`)
- [x] Comparative Von Neumann unified baseline with bus arbiter (`rtl/von_neumann/`)
- [x] Automated testbenches & self-checking assertions (`tb/`)
- [x] Clean one-click compilation script (`sim/run_sim.sh`)
- [x] IEEE Project Report source ([IEEE_Project_Report_Phase1.tex](docs/report/IEEE_Project_Report_Phase1.tex)) and compiled PDF ([Project_Report_Phase1.pdf](docs/report/Project_Report_Phase1.pdf))
- [x] Prototype Video Demonstration ([docs/video/video_demonstration.md](docs/video/video_demonstration.md) & [Google Drive Link](https://drive.google.com/file/d/1w4z_5gOMVCfHtYa4Goujhmb_GkWyMnq4/view?usp=sharing))
