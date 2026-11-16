# 5-Minute Prototype Video Demonstration Script
## Project 9: Instruction and Data Memory Hierarchy
**Course:** Modern Computer Architecture (MCA) — Phase I Evaluation (15 Marks)  
**Total Target Duration:** 4 minutes 35 seconds (Strictly $< 5$ minutes)

---

## 👥 Video Team Roles (3 Presenters)
1. **Anant Jain** (Roll: `2401010066`) — **Speaker 1: Introduction, Group Roster & Project Motivation** [0:00 – 1:20]
2. **Kartik Mehra** (Roll: `2401020030`) — **Speaker 2: Harvard Architecture Overview & Block Diagram** [1:20 – 2:45] *(Intuitive & High-Level)*
3. **Vipul Sharma** (Roll: `2401010505`) — **Speaker 3: Shared Memory Comparison, Live Simulation & Waveforms** [2:45 – 4:35] *(Technical Demo & Results)*

> **Note for Evaluation:** As required by the course guidelines, all 5 project members (Anant Jain, Vipul Sharma, Krishna Gehlot, Aditya Kumar, and Kartik Mehra) are formally introduced in the opening by Anant.

---

## 🎬 Timed Speaking Script

---

### [0:00 – 1:20] Part 1: Project Overview & Group Introduction
**Speaker:** Anant Jain  
**Visual on Screen:** Title Slide with Project Name, Newton School of Technology / Rishihood University, and the names & roll numbers of all 5 members.

> *"Hello everyone! Welcome to our Phase I project demonstration for Modern Computer Architecture.*
>
> *Our project is **Project 9: Instruction and Data Memory Hierarchy**.*
>
> *Before we begin, let me introduce our entire team of 5 members from Newton School of Technology, Rishihood University:*
> - *First is myself, **Anant Jain** (Roll 2401010066),*
> - *Second is **Vipul Sharma** (Roll 2401010505),*
> - *Third is **Krishna Gehlot** (Roll 2401010236),*
> - *Fourth is **Aditya Kumar** (Roll 2401010029), and*
> - *Fifth is **Kartik Mehra** (Roll 2401020030).*
>
> *In computer systems, memory organization is one of the most critical factors deciding overall processor speed. In the traditional **Von Neumann architecture**, program instructions and data live in a single unified memory and share a single bus. Because there is only one bus, the CPU cannot fetch an instruction and read or write data at the same time—creating the classical 'Von Neumann Bottleneck'.*
>
> *To solve this, our project implements a **Harvard-style memory organization** in Verilog HDL. In Harvard architecture, we separate instruction memory and data memory onto completely independent buses, allowing simultaneous accesses.*
>
> *Now, I will hand over to Kartik, who will walk you through the Harvard architecture design."*

---

### [1:20 – 2:45] Part 2: Harvard Architecture Block Diagram Walkthrough
**Speaker:** Kartik Mehra  
**Visual on Screen:** Slide showing `docs/diagrams/harvard_architecture_block_diagram.png` (or showing the diagram image fullscreen).

> *"Thank you, Anant! I am Kartik Mehra.*
>
> *Let's look at the block diagram of our Harvard memory architecture on the screen.*
>
> *The big advantage here is simple: **two separate paths instead of one**.*
>
> *On the left, we have our **Processor Core**. It has a 16-register register file, an ALU, and a Program Counter.*
>
> *Notice that coming out of the processor, we have two completely independent paths:*
> 1. *At the top in green, we have the dedicated **Instruction Bus** connected to our **Instruction Memory**. The Program Counter increments by 4 to fetch a new 32-bit instruction every cycle.*
> 2. *At the bottom in orange, we have the separate **Data Bus** connected to our **Data Memory Subsystem**.*
>
> *Our Data Memory is 1024 bytes, and it is cleverly organized into **four byte-wide lanes**. This means our processor can write individual 8-bit bytes, 16-bit half-words, or full 32-bit words simply using 4 write-enable signals.*
>
> *We also have an **Address Decoder** that checks every data address to make sure it's valid and word-aligned, and routes accesses either to RAM or to diagnostic I/O registers.*
>
> *Because these two memories have their own dedicated wires, the processor never has to wait. While it's writing an answer to Data Memory, it can fetch the next instruction from Instruction Memory at the exact same clock tick!*
>
> *Now, Vipul will show how this compares to a shared memory system and run our live simulation demo."*

---

### [2:45 – 4:35] Part 3: Von Neumann Comparison, Live Simulation & Results
**Speaker:** Vipul Sharma  
**Visual on Screen:** Slide showing `docs/diagrams/von_neumann_comparison_diagram.png`, then switch to live Terminal and run `./sim/run_sim.sh`.

> *"Thank you, Kartik! I am Vipul Sharma.*
>
> *To prove that the Harvard architecture is actually faster, we also designed a comparative **Shared-Memory Von Neumann baseline** in Verilog.*
>
> *In our shared-memory module, code and data are placed in a single unified memory. We added a **Bus Arbiter**: whenever a `LOAD` or `STORE` instruction occurs, the single bus is busy transferring data. The arbiter is forced to stall the CPU and Program Counter for one extra clock cycle.*
>
> *Now, let's watch the live simulation in the terminal!*
>
> *(Speaker runs command on screen: `./sim/run_sim.sh`)*
>
> *Here you can see our automated simulation running on Icarus Verilog:*
> - *First, all self-checking assertions **PASS 100%**: the values stored into memory and loaded into registers match our expected math perfectly.*
> - *Now look at this **Benchmark Comparison Table**:*
>   - *On the **Harvard Architecture**, our 15-instruction program finishes in **exactly 15 clock cycles**. There are **7 simultaneous access cycles** where instruction fetch and data read/write happen together, giving an ideal **CPI of 1.00**.*
>   - *On the **Shared-Memory system**, the exact same 15 instructions take **22 clock cycles** because it suffered **7 structural hazard stall cycles**! That increases the CPI to **1.47**.*
>
> *This empirically demonstrates that the Harvard architecture provides a **1.47x speedup**, saving over 31% of execution time!*
>
> *In Phase II, we will take this foundation further by adding simple Level-1 cache controllers and analyzing memory hierarchy behavior.*
>
> *Thank you very much for listening!"*

---

## 💡 Quick Tips for Recording
- **Platform:** Use Google Meet, Zoom, or OBS Studio to record.
- **Kartik's Part:** Keep the block diagram on screen. Kartik just needs to point to the green box (Instruction Memory) and orange box (Data Memory) and explain the separation clearly.
- **Vipul's Part:** Keep the terminal open and run `./sim/run_sim.sh` live so the professors can see the clean output and the comparison table.
