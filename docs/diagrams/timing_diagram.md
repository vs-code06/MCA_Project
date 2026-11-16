# Timing Diagrams & Bus Activity Analysis
## Project 9: Instruction and Data Memory Hierarchy
**Authors:** Anant Jain, Vipul Sharma, Krishna Gehlot, Aditya Kumar, Kartik Mehra

---

## 1. Harvard Architecture: Parallel Execution (CPI = 1.00)

In the Harvard architecture, the processor benefits from independent instruction and data buses. During memory instructions (`LOAD` and `STORE`), the Instruction Fetch (IF) of instruction $I_{k+1}$ occurs **simultaneously** with the Data Memory access (MEM) of instruction $I_k$.

### Waveform View (Cycles 3 to 7)

```text
Clock Cycle:       |   Cycle 3   |   Cycle 4   |   Cycle 5   |   Cycle 6   |   Cycle 7   |
-------------------+-------------+-------------+-------------+-------------+-------------+
CLK                |  __        |  __        |  __        |  __        |  __        |
                   |_/  \________|_/  \________|_/  \________|_/  \________|_/  \________|
PC                 | 0x0000000C  | 0x00000010  | 0x00000014  | 0x00000018  | 0x0000001C  |
Instruction Read   | ADD R3,R1,R2| STORE R3,0  | ADDI R4,5   | STORE R4,4  | LOAD R5,0   |
Instr Data Bus     | 0x04C48000  | 0x2428C000  | 0x0D000005  | 0x24290004  | 0x21680000  |
-------------------+-------------+-------------+-------------+-------------+-------------+
Data Addr Bus      |    --       | 0x00000100  |    --       | 0x00000104  | 0x00000100  |
Data Write Data    |    --       | 0x0000001E  |    --       | 0x00000005  |    --       |
Data Write Enable  |     0       |      1      |     0       |      1      |     0       |
Data Read Enable   |     0       |      0      |     0       |      0      |     1       |
Data Read Data     |    --       |    --       |    --       |    --       | 0x0000001E  |
-------------------+-------------+-------------+-------------+-------------+-------------+
Simultaneous Event |    None     | [FETCH+WR]  |    None     | [FETCH+WR]  | [FETCH+RD]  |
Pipeline Stall     |     0       |      0      |     0       |      0      |     0       |
Completed Instr    | ADD (R3=30) | STORE (Mem) | ADDI(R4=5)  | STORE (Mem) | LOAD (R5=30)|
```

### Key Architectural Observation:
- At **Cycle 4**, while the CPU is writing `30` (`0x1E`) to Data Memory address `0x0100`, the Instruction Memory port is concurrently fetching `ADDI R4, R0, 5` from address `0x0014`.
- **Zero stall cycles are introduced.**

---

## 2. Von Neumann (Shared Memory) Architecture: Serialized Access (CPI = 1.47)

In the shared-memory organization, only one physical memory port exists. When a `LOAD` or `STORE` instruction is decoded, a **structural hazard** occurs: the bus cannot service the instruction fetch for the next instruction and the data operand access at the same time. The Arbiter asserts `cpu_stall = 1`, serializing the access into two distinct phases.

### Waveform View (Cycles 3 to 8)

```text
Clock Cycle:       |   Cycle 3   |   Cycle 4   |   Cycle 5   |   Cycle 6   |   Cycle 7   |   Cycle 8   |
-------------------+-------------+-------------+-------------+-------------+-------------+-------------+
CLK                |  __        |  __        |  __        |  __        |  __        |  __        |
                   |_/  \________|_/  \________|_/  \________|_/  \________|_/  \________|_/  \________|
PC                 | 0x0000000C  | 0x00000010  | 0x00000010  | 0x00000014  | 0x00000018  | 0x00000018  |
Arbiter State      |   S_FETCH   |   S_FETCH   |    S_MEM    |   S_FETCH   |   S_FETCH   |    S_MEM    |
Bus Owner          | Instruction | Instruction |    Data     | Instruction | Instruction |    Data     |
Shared Bus Addr    | 0x0000000C  | 0x00000010  | 0x00000100  | 0x00000014  | 0x00000018  | 0x00000104  |
Shared Bus WE      |      0      |      0      |      1      |      0      |      0      |      1      |
Shared Bus Data    | ADD R3,R1,R2| STORE R3,0  | 0x0000001E  | ADDI R4,5   | STORE R4,4  | 0x00000005  |
-------------------+-------------+-------------+-------------+-------------+-------------+-------------+
CPU Stall Signal   |      0      |      1      |      0      |      0      |      1      |      0      |
Pipeline State     | Executing   |   STALLED   |   Writing   | Executing   |   STALLED   |   Writing   |
                   |   (ADD)     |  (Hazard)   |   (STORE)   |   (ADDI)    |  (Hazard)   |   (STORE)   |
-------------------+-------------+-------------+-------------+-------------+-------------+-------------+
Cycles per Instr   |   1 Cycle   | <------- 2 Cycles -------> |   1 Cycle   | <------- 2 Cycles -------> |
```

### Quantitative Summary:
- **Harvard Execution:** 15 instructions in **15 clock cycles** ($CPI = 1.00$).
- **Von Neumann Execution:** 15 instructions in **22 clock cycles** ($CPI = 1.47$), with **7 structural hazard stall cycles**.
- **Performance Advantage:** The Harvard architecture yields a **1.47x speedup** (31.8% reduction in runtime) on this memory-intensive benchmark.
