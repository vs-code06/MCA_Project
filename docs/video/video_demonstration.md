# Phase I Video Demonstration

**Team:** Decoders07  
**Course:** Modern Computer Architecture (MCA) — Project 9: Instruction and Data Memory Hierarchy  
**Video Link:** [Watch Video Demonstration (Google Drive)](https://drive.google.com/file/d/1w4z_5gOMVCfHtYa4Goujhmb_GkWyMnq4/view?usp=sharing)  
**Duration:** 4 minutes 35 seconds (Strictly $< 5$ minutes)

---

## 🎬 Demonstration Structure & Key Concepts

1. **Introduction & Architectural Motivation:**  
   - Formal project scope and team introduction.  
   - Analysis of the classic Von Neumann bottleneck: single-bus resource contention during concurrent instruction fetch and operand load/store operations.  
   - Core objectives: implementing and validating a pure Harvard-style memory hierarchy in Verilog HDL.

2. **Harvard Hardware Architecture Walkthrough:**  
   - Detailed walkthrough of the system block diagram and physical bus separation.  
   - Dedicated 32-bit Instruction Memory indexed by a word-aligned Program Counter.  
   - Byte-addressable Data Memory configured with 4 independent byte lanes and selective byte-enable write controls.  
   - Address decoding unit enforcing word alignment and partitioning RAM from diagnostic Memory-Mapped I/O (MMIO) registers.

3. **Comparative Baseline & Structural Hazards:**  
   - Modeling an equivalent unified-memory Von Neumann baseline using a two-phase synchronous bus arbiter.  
   - Explanation of how bus arbitration resolves contention by asserting a 1-cycle CPU stall during `LOAD` and `STORE` instructions.

4. **Live RTL Simulation & Empirical Benchmarking:**  
   - Live execution of `./sim/run_sim.sh` on Icarus Verilog showing 100% passing hardware assertions.  
   - Verification of parallel `SIMULTANEOUS ACCESS` cycles without pipeline stalls.  
   - Quantitative evaluation: Harvard completes in 15 cycles ($\text{CPI} = 1.00$), whereas the shared-memory baseline requires 22 cycles due to 7 stalls ($\text{CPI} = 1.47$), achieving an empirical **1.47× speedup** (31.8% runtime reduction).  
   - Code inspection of dual-bus instantiations in `rtl/harvard/harvard_top.v` and Phase II roadmap.
