# Phase I Video Demonstration

**Course:** Modern Computer Architecture (MCA) — Project 9: Instruction and Data Memory Hierarchy  
**Video Link:** [Watch Video Demonstration (Google Drive)](https://drive.google.com/file/d/1w4z_5gOMVCfHtYa4Goujhmb_GkWyMnq4/view?usp=sharing)  
**Duration:** 4 minutes 35 seconds (Strictly $< 5$ minutes)

---

## 👥 Presenters & Structure

1. **Introduction & Motivation:**  
   - **Speaker:** Anant Jain  
   - Introduces the 5-member team (Anant Jain, Vipul Sharma, Krishna Gehlot, Aditya Kumar, and Kartik Mehra).  
   - Outlines the classical Von Neumann structural bottleneck and project objectives.

2. **Harvard Architecture Walkthrough:**  
   - **Speaker:** Kartik Mehra  
   - Explains the architectural block diagram, highlighting the separate Instruction Memory and 4-byte-lane Data Memory paths.

3. **Simulation Demo & Empirical Benchmark:**  
   - **Speaker:** Vipul Sharma  
   - Walks through the shared-memory Von Neumann comparison and runs `./sim/run_sim.sh` live.  
   - Demonstrates 100% assertion pass and empirical benchmark results (Harvard achieves an ideal 1.00 CPI vs 1.47 CPI on Von Neumann, yielding a 1.47x speedup).  
   - Reviews the dual-bus instantiation in `rtl/harvard/harvard_top.v` and concludes Phase 1.
