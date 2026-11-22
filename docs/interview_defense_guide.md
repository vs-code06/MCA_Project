# Phase 1 & Phase 2 Viva Defense & Interview Guide
### Modern Computer Architecture (MCA) — Project 9
**Team: Decoders07**  
*Newton School of Technology, Rishihood University*

---

## 👥 Team Roster & Individual Specializations

| Team Member | Roll Number | Phase 1 Specialization | Phase 2 Specialization |
|---|---|---|---|
| **Anant Jain** | `2401010066` | Program Counter & Instruction Memory Subsystem | L1 Instruction Cache (I-Cache), Tag Checking FSM & Hit/Miss Counters |
| **Vipul Sharma** | `2401010505` | Data Memory Subsystem & Controller Integration | L1 Data Cache (D-Cache), Write-Through FSM, Byte Enables & Core Stall Coupling |
| **Krishna Gehlot** | `2401010236` | Address Decoder & MMIO Interconnect | Shared Main Memory Priority Arbiter ($D > I$) & Wait-State Generator |
| **Aditya Kumar** | `2401010029` | Shared-Memory Baseline & Structural Hazard Modeling | Benchmark Assembler (`phase2_assembler.py`), 3-Way Comparative Benchmark & AMAT |
| **Kartik Mehra** | `2401020030` | Verification Suite, Testbenches & Documentation | Self-Checking Assertions (`tb_cache_system.v`), Waveform Verification & IEEE Report |

---

## 🎓 Part 1: High-Level Architectural Viva Questions (Any Member)

### Q1: What is the primary difference between Pure Harvard, Von Neumann, and Modified Harvard architectures?
**Answer:**
- **Pure Harvard (Phase 1):** Provides physically separate memory arrays and completely independent 32-bit buses for instructions and data. The CPU fetches instructions and accesses operands concurrently in the same clock cycle with zero stalls ($\text{CPI} = 1.00$).
- **Von Neumann (Phase 1):** Uses a single unified memory and a single shared bus for both instructions and data. When a `LOAD` or `STORE` occurs, data occupies the shared bus, causing a **structural hazard**. Instruction fetch must stall for 1 cycle, resulting in a higher CPI ($1.47$).
- **Modified Harvard (Phase 2):** Combines the advantages of both. At the core boundary (Level 1), it provides separate L1 I-Cache and L1 D-Cache for conflict-free concurrent access. Behind the caches, a unified multi-cycle main memory provides high capacity over an arbitrated bus.

### Q2: Why is a Pure Harvard architecture not used for off-chip main memory in modern general-purpose computers?
**Answer:**
1. **Pin Count & Wiring Cost:** Doubling the address and data buses off-chip requires twice as many CPU pins and motherboard traces, vastly increasing hardware cost and package complexity.
2. **Memory Fragmentation & Inflexibility:** If physical RAM is statically partitioned into instruction RAM and data RAM, unused instruction memory cannot be allocated to data-heavy programs (e.g., video processing, databases), wasting expensive memory capacity.
3. **Physical Capacitive Delays:** Off-chip memory cannot operate at single-cycle processor clock frequencies (e.g., 3–5 GHz) due to transmission line propagation delays and DRAM capacitor refresh latencies.

### Q3: What is Average Memory Access Time (AMAT) and how does caching improve it?
**Answer:**
$$\text{AMAT} = \text{Hit Time} + (\text{Miss Rate} \times \text{Miss Penalty})$$
- In an un-cached multi-cycle memory system with a 3-cycle penalty, every single memory access takes 3 cycles ($\text{AMAT} = 3.0$).
- With an L1 cache providing a 1-cycle hit time and an $85\%$ hit rate ($\text{Miss Rate} = 0.15$):
  $$\text{AMAT} = 1 + (0.15 \times 3) = 1.45\text{ cycles}$$
- Caching leverages **temporal locality** (reusing recently fetched instructions/data in loops) and **spatial locality** to keep the effective access time close to 1 cycle.

---

## 🔬 Part 2: Individual Technical Deep-Dive Viva Questions

---

### 👤 Anant Jain (Roll: 2401010066)
**Focus Area:** Program Counter, L1 Instruction Cache (I-Cache), Line Refill FSM & Address Slicing

#### Q1: How does your L1 I-Cache decompose the 32-bit address into Tag, Index, and Offset?
**Answer:**
Our L1 I-Cache has 16 lines, and each line holds 1 32-bit word (4 bytes):
- **Byte Offset (`cpu_addr[1:0]`):** 2 bits to identify byte positions within the 4-byte word (aligned instructions have `offset = 00`).
- **Line Index (`cpu_addr[5:2]`):** $\log_2(16) = 4$ bits, directly indexing lines `0` to `15` in the cache array.
- **Tag (`cpu_addr[31:6]`):** The upper $32 - 4 - 2 = 26$ bits, stored in `tag_array` to uniquely identify the memory block mapped to that line.

#### Q2: Walk us through the I-Cache FSM transitions during a cache miss.
**Answer:**
1. In state `S_IDLE`, when `cpu_req = 1`, the cache compares `tag_array[line_index]` against `cpu_addr[31:6]`.
2. If `valid_array[line_index] == 0` or the tags do not match, a miss occurs:
   - `cpu_stall` is asserted high combinational to freeze the CPU Program Counter and instruction decoder.
   - The cache transitions to `S_REFILL`, latches `cpu_addr`, and raises `mem_req = 1` to the shared main memory.
3. When main memory finishes after wait states and asserts `mem_ready = 1`:
   - The incoming `mem_rdata` is written into `data_array[line_index]`.
   - `tag_array[line_index]` is updated with the latched tag, and `valid_array[line_index] <= 1'b1`.
   - The refilled instruction is bypassed directly onto `cpu_instruction`, `cpu_stall` is released to $0$, and the FSM returns to `S_IDLE`.

#### Q3: Why is instruction cache coherence simpler than data cache coherence?
**Answer:**
Instruction cache is strictly **read-only** in normal program execution (assuming non-self-modifying code). Because the processor core never writes to instruction memory, there are no dirty lines, no write-back buffers, and no memory consistency hazards between the I-cache and main memory.

---

### 👤 Vipul Sharma (Roll: 2401010505)
**Focus Area:** L1 Data Cache (D-Cache), Write-Through Policy, Byte-Enable Masking & CPU Stall Interconnect

#### Q1: Why did you choose a Write-Through policy with No-Write-Allocate for the L1 Data Cache?
**Answer:**
- **Write-Through:** Every `STORE` instruction updates the L1 D-Cache (if hit) and is immediately forwarded to main memory. This ensures main memory always holds fresh, consistent data at all times, drastically simplifying memory consistency and error recovery.
- **No-Write-Allocate:** When a write miss occurs, the data is written directly to main memory without evicting an existing cache line or fetching the line into cache. This avoids displacing active cache lines for one-off write operations.
- For an embedded or single-core architecture, this avoids complex dirty-bit tracking, write-back flush states, and replacement logic while guaranteeing $100\%$ data integrity.

#### Q2: How does your D-Cache implement sub-word byte writing using `cpu_be[3:0]`?
**Answer:**
In `d_cache.v`, we implemented the `apply_byte_en` helper function:
```verilog
function [31:0] apply_byte_en;
    input [31:0] old_val, new_val;
    input [3:0]  be;
    begin
        apply_byte_en[7:0]   = be[0] ? new_val[7:0]   : old_val[7:0];
        apply_byte_en[15:8]  = be[1] ? new_val[15:8]  : old_val[15:8];
        apply_byte_en[23:16] = be[2] ? new_val[23:16] : old_val[23:16];
        apply_byte_en[31:24] = be[3] ? new_val[31:24] : old_val[31:24];
    end
endfunction
```
When writing an 8-bit byte or 16-bit halfword, only the enabled byte lanes are overwritten; the remaining bytes in the 32-bit word remain intact.

#### Q3: How do cache stalls connect to the processor core without causing combinational oscillation loops?
**Answer:**
In `modified_harvard_top.v`:
$$\text{cpu\_stall} = \text{icache\_stall} \lor \text{dcache\_stall}$$
- Inside `simple_processor.v`, `cpu_stall` freezes the Program Counter (`pc_stall = cpu_stall || halted`) and disables register updates (`if (!external_stall) reg_file[rd] <= ...`).
- Critically, the memory control generation (`data_req`, `data_we`) depends **only on the decoded opcode**, NOT on `external_stall`. This breaks the feedback loop between the core request output and the cache stall input, ensuring clean, stable signal transitions.

---

### 👤 Krishna Gehlot (Roll: 2401010236)
**Focus Area:** Shared Main Memory Subsystem, Priority Bus Arbiter ($D > I$) & Wait-State Generator

#### Q1: Why does your Main Memory Arbiter prioritize D-Cache over I-Cache ($D > I$)?
**Answer:**
1. **Instruction Execution Flow:** A data memory request (`LOAD` or `STORE`) is generated by an instruction that has **already been fetched** into the processor core and is occupying the execution stage. Completing this active instruction frees up processor resources and prevents pipeline stalls.
2. **Write Commitment:** In a write-through architecture, storing data operands to main memory is time-critical to avoid buffer backpressure. Prioritizing D-cache guarantees quick memory updates.

#### Q2: How does the wait-state generator in `main_memory.v` model memory latency?
**Answer:**
`main_memory.v` features an FSM with three states: `S_IDLE`, `S_WAIT`, and `S_DONE`:
- When an access request arrives in `S_IDLE`, the arbiter latches the client (`active_client`), address, and write data, and sets `wait_timer <= LATENCY` (parameterized to `2`).
- In `S_WAIT`, the module counts down `wait_timer <= wait_timer - 1` on each clock edge while accumulating telemetry (`total_wait_cycles`).
- When `wait_timer <= 1`, the FSM transitions to `S_DONE`, where it pulses `ready = 1` for exactly one cycle and commits byte-enabled writes into `mem_array`.
- This creates an exact, deterministic 3-cycle memory access penalty (1 request cycle + 2 wait-state cycles).

#### Q3: How do you prevent duplicate/phantom memory requests when `ready` is pulsed?
**Answer:**
In `S_DONE`, `icache_ready` or `dcache_ready` is asserted high. On the clock edge where `main_memory` exits `S_DONE` to `S_IDLE`, the client cache detects `mem_ready == 1` and simultaneously resets its `mem_req <= 0`. Because `main_memory` only accepts new transactions when in `S_IDLE` with `req == 1`, no spurious re-triggering occurs.

---

### 👤 Aditya Kumar (Roll: 2401010029)
**Focus Area:** Multi-Benchmark Assembler, 3-Way Comparative Benchmark & Performance Modeling

#### Q1: Explain the design of the Iterative Loop Benchmark in `scripts/phase2_assembler.py`.
**Answer:**
The loop benchmark computes the triangular sum:
$$\sum_{k=1}^{5} k = 5 + 4 + 3 + 2 + 1 = 15$$
It tests both instruction and data cache locality:
1. Addresses `0x0C` to `0x1C` constitute the loop body:
   - `0x0C: ADD R2, R2, R1` (Accumulates running sum)
   - `0x10: STORE R2, 0(R10)` (Write-through to `Mem[0x100]`)
   - `0x14: LOAD R3, 0(R10)` (Reads back `Mem[0x100]`, testing D-Cache hits)
   - `0x18: ADDI R1, R1, -1` (Decrements loop counter)
   - `0x1C: BNE R1, R0, -4` (Branches back to `0x0C` if $R1 \neq 0$)
2. On iteration 1, cold misses occur to refill the lines.
3. On iterations 2 through 5, all 5 instructions and the load hit in L1 caches, demonstrating temporal locality with $>82\%$ hit rate.

#### Q2: Analyze the 3-way comparative benchmark results. Why did Modified Harvard have higher total cycles on linear code?
**Answer:**
- In the 15-instruction **linear benchmark**:
  - **Pure Harvard:** Finished in 15 cycles ($\text{CPI} = 1.00$) because every memory is ideal 1-cycle.
  - **Von Neumann:** Finished in 22 cycles ($\text{CPI} = 1.47$) due to 7 structural hazard stalls.
  - **Modified Harvard:** Took 103 cycles because linear code has **zero temporal reuse** (every instruction is executed once, causing 15 cold misses of 3 cycles each) plus write-through stalls.
- This highlights a fundamental law of computer architecture: **Caches benefit programs with locality (loops, subroutines, reused data arrays)**. In loop workloads, the hit rate rises to $>82\%$, shielding the CPU from slow memory.

#### Q3: How is instruction throughput (IPC) related to CPI?
**Answer:**
$$\text{IPC} = \frac{1}{\text{CPI}} = \frac{\text{Instructions Executed}}{\text{Clock Cycles}}$$
- Pure Harvard achieves the theoretical peak throughput of $\text{IPC} = 1.00$ instruction per cycle.
- Von Neumann throughput drops to $\text{IPC} = 0.68$ due to bus arbitration serialization.
- Modified Harvard throughput on loops reaches $\text{IPC} = 0.31$ even under a severe 3-cycle memory wait-state penalty.

---

### 👤 Kartik Mehra (Roll: 2401020030)
**Focus Area:** Verification Assertions (`tb_cache_system.v`), Waveforms, Telemetry & Documentation

#### Q1: What automated self-checking assertions were implemented in `tb_cache_system.v`?
**Answer:**
We implemented exhaustive, automated self-checking assertions:
1. `u_dut.u_main_mem.mem_array[0x100 >> 2] == 15`: Verifies that the running sum written through D-Cache into main memory matches 15.
2. `u_dut.u_main_mem.mem_array[0x104 >> 2] == 15`: Verifies post-loop final sum commit.
3. Register Assertions:
   - `R1 == 0`: Loop counter terminated cleanly.
   - `R2 == 15`: Accumulator correct.
   - `R3 == 15`: Last loaded operand matches.
4. Telemetry Assertions:
   - `icache_hits > 0` (recorded 48 hits).
   - `dcache_read_hits > 0` (recorded 4 read hits, 4 write hits).
All assertions passed $100\%$ with zero manual inspection needed.

#### Q2: How did you calculate real-time floating-point AMAT inside SystemVerilog?
**Answer:**
Inside `tb_cache_system.v`:
```verilog
i_hit_rate  = (icache_accesses > 0) ? (real'(icache_hits) / real'(icache_accesses)) * 100.0 : 0.0;
amat_i      = 1.0 + ((real'(icache_misses) / real'(icache_accesses)) * 3.0);

d_hit_rate  = (dcache_accesses > 0) ? (real'(dcache_read_hits + dcache_write_hits) / real'(dcache_accesses)) * 100.0 : 0.0;
amat_d      = 1.0 + ((real'(dcache_read_misses + dcache_write_misses) / real'(dcache_accesses)) * 3.0);
```
Using the `real'(...)` cast allows Icarus Verilog to compute accurate floating-point rates printed directly in the console report.

#### Q3: How do you inspect signal transitions in GTKWave to confirm simultaneous fetch and cache hits?
**Answer:**
By opening `sim/phase2_cache.vcd` in GTKWave:
1. Add signals: `clk`, `probe_pc`, `cpu_stall`, `u_icache.cpu_hit`, `u_dcache.cpu_hit`, `u_main_mem.state`.
2. Locate cycles in loop iterations 2–5:
   - Observe `cpu_stall = 0`.
   - `u_icache.cpu_hit = 1` while PC advances sequentially every clock tick.
   - During `STORE R2, 0(R10)`, notice `u_dcache.cpu_stall` asserts for 3 cycles while `u_main_mem.state` transitions through `S_WAIT` to commit the write-through, after which execution seamlessly resumes.

---

## 🎯 Summary Takeaways for Faculty Evaluation
- **Team Name:** Decoders07
- **Course:** Modern Computer Architecture (MCA), Project 9
- **Institution:** Newton School of Technology, Rishihood University
- **Core Results:**
  - Pure Harvard Speedup: **1.47x** over Von Neumann ($\text{CPI} = 1.00$ vs $1.47$).
  - Phase 2 L1 Caching: **$82.8\%$ I-Cache Hit Rate**, **$72.7\%$ D-Cache Hit Rate**.
  - Verified 3-way benchmark and 100% assertion pass in Verilog simulation.
