# 5-Minute Prototype Video Demonstration Script
## Project 9: Instruction and Data Memory Hierarchy
**Course:** Modern Computer Architecture (MCA) — Phase I Evaluation (15 Marks)  
**Total Target Duration:** 4 minutes 35 seconds (Strictly $< 5$ minutes)  
**Video Recording Link:** [https://drive.google.com/file/d/1w4z_5gOMVCfHtYa4Goujhmb_GkWyMnq4/view?usp=sharing](https://drive.google.com/file/d/1w4z_5gOMVCfHtYa4Goujhmb_GkWyMnq4/view?usp=sharing)

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

### [2:45 – 4:35] Part 3: Von Neumann Comparison, Live Simulation & Code Walkthrough
**Speaker:** Vipul Sharma  
**Visual on Screen:** 
1. Show slide or image `docs/diagrams/von_neumann_comparison_diagram.png`.
2. Switch to Terminal window and run `./sim/run_sim.sh`.
3. Switch to VS Code and show `rtl/harvard/harvard_top.v` (lines 43–60).

> *"Thank you, Kartik! I am Vipul Sharma.*
>
> *(Pointing to `von_neumann_comparison_diagram.png`)*  
> *To prove the real benefit of Harvard architecture, we also designed an equivalent shared-memory Von Neumann baseline in Verilog.*
>
> *As you can see in this diagram, code and data share a single memory and a single 32-bit bus. When an instruction like a LOAD or STORE executes, the bus is occupied by the data. The CPU cannot fetch the next instruction at the same time. This creates a structural hazard, and our bus arbiter is forced to stall the CPU for one extra clock cycle.*
>
> *(Switch to Terminal and run `./sim/run_sim.sh`)*  
> *Now, let's verify this live in the terminal by running `./sim/run_sim.sh`.*
>
> *First, all self-checking assertions pass 100%—the expected values 30, 5, 35, and 25 are stored accurately in memory.*
>
> *In the Harvard execution log, you can see the tag `SIMULTANEOUS ACCESS` across 7 cycles, proving that instruction fetch and data operand access happen at the exact same clock edge.*
>
> *Now, looking at the final Architecture Comparison table:*
> - *Both architectures run the exact same 15 benchmark instructions.*
> - *Our Harvard architecture finishes in 15 clock cycles with zero stalls, achieving an ideal CPI of 1.00.*
> - *The Von Neumann architecture takes 22 clock cycles because of 7 structural hazard stalls—one stall for every single load and store! This pushes its CPI to 1.47.*
>
> *This empirically demonstrates a 1.47x speedup, reducing total execution time by nearly 32%.*
>
> *(Switch to VS Code showing `rtl/harvard/harvard_top.v`)*  
> *In `harvard_top.v`, you can see how this is implemented in Verilog:*  
> *We instantiate two completely independent modules—a dedicated `instruction_memory` on its own bus, and a separate `data_memory` with 4-bit byte enables. Because they don't share wires, the processor can fetch instructions and access data in the exact same clock cycle.*
>
> *This successfully concludes Phase 1. In Phase 2, our team will build upon this foundation by integrating Level-1 caches. The complete codebase and project report are documented in our repository.*
>
> *Thank you!"*

---

## 💡 Quick Tips for Recording
- **Platform:** Use Google Meet, Zoom, or OBS Studio to record.
- **Kartik's Part:** Keep the block diagram on screen. Kartik just needs to point to the green box (Instruction Memory) and orange box (Data Memory) and explain the separation clearly.
- **Vipul's Part:** Keep the terminal open and run `./sim/run_sim.sh` live so the professors can see the clean output and the comparison table.
