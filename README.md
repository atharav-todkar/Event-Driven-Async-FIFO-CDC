# Asynchronous FIFO with Clock Domain Crossing (CDC) Stress Analyzer

> **RTL Design & Verification Project** | Xilinx Artix-7 (xc7a35ticsg324-1L) | Vivado 2023.x  
> Targeted toward graduate-level digital design for VLSI/Nanoelectronics MS applications

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Motivation & Problem Statement](#motivation--problem-statement)
3. [Architecture](#architecture)
4. [CDC Methodology](#cdc-methodology)
5. [Simulation & Verification](#simulation--verification)
6. [Synthesis Results](#synthesis-results)
7. [Timing Analysis](#timing-analysis)
8. [CDC Stress Test Results](#cdc-stress-test-results)
9. [File Structure](#file-structure)
10. [How to Reproduce](#how-to-reproduce)
11. [Key Learnings & Design Decisions](#key-learnings--design-decisions)
12. [Future Work](#future-work)

---

## Project Overview

This project implements a **parameterized, synthesis-ready Asynchronous FIFO** from scratch — without using any Xilinx IP cores — with a dedicated **Clock Domain Crossing (CDC) Stress Analyzer** testbench.

The design demonstrates:
- First-principles understanding of metastability and synchronization failure
- Gray code pointer arithmetic for safe multi-bit CDC transfer
- Constraint-driven timing closure using a custom `.xdc` file
- Functional verification through both deterministic and randomized stimulus

**This is not a textbook copy.** Every architectural decision made here reflects reasoning about *why*, not just *what*.

---

## Motivation & Problem Statement

In modern SoC designs, data must often cross between independently clocked domains — a CPU interface running at 100 MHz writing to a sensor block running at 37 MHz, for example. A naive dual-port RAM implementation would produce **metastable outputs** that corrupt data unpredictably — a failure mode that cannot be caught by conventional simulation.

The challenge: **Design a reliable, synthesizable FIFO that safely passes data between two unrelated clock domains, and prove it works under worst-case asynchronous conditions.**

Key constraints imposed on this design:
- No Xilinx FIFO Generator IP (defeats the learning purpose)
- Both clocks must be truly asynchronous (no common source)
- Full/empty flags must be glitch-free under simultaneous read/write pressure
- Timing must close on a real FPGA target with zero failing endpoints

---

## Architecture

```
                    ┌─────────────────────────────────────────────────┐
                    │              async_fifo_top                      │
                    │                                                  │
  wr_clk ──────────►│  ┌─────────────┐      ┌──────────────────────┐  │
  wr_en  ──────────►│  │ wr_ptr_ctrl │─────►│      fifo_mem        │  │
  wr_data ─────────►│  │  (binary +  │      │  (dual-port BRAM     │  │
                    │  │  gray conv) │      │   inferred)          │  │
                    │  └──────┬──────┘      └──────────┬───────────┘  │
                    │         │ gray_wr_ptr             │ rd_data      │
                    │  ┌──────▼──────┐                 │              │◄──── rd_data
                    │  │  gray_sync  │ (2-FF)           │              │
                    │  │  [wr→rd]    │                 │              │
                    │  └──────┬──────┘      ┌──────────▼───────────┐  │
  rd_clk ──────────►│         │             │      rd_ptr_ctrl      │  │◄─── rd_en
  rd_en  ──────────►│  ┌──────▼──────┐      │  (binary + gray conv)│  │
                    │  │  gray_sync  │      └──────────┬───────────┘  │
                    │  │  [rd→wr]    │ (2-FF)          │ gray_rd_ptr  │
                    │  └─────────────┘      ┌──────────▼───────────┐  │
                    │                        │  gray_sync [rd→wr]   │  │
                    │                        └──────────────────────┘  │
                    │                                                  │
                    │  Outputs: full, empty, overflow, underflow       │
                    └─────────────────────────────────────────────────┘
```

### Module Breakdown

| Module | Function | Clock Domain |
|---|---|---|
| `async_fifo_top` | Top-level integration, flag generation | Both |
| `fifo_mem` | Dual-port synchronous RAM | wr_clk (write), rd_clk (read) |
| `wr_ptr_ctrl` | Binary write pointer + Gray conversion + full detection | wr_clk |
| `rd_ptr_ctrl` | Binary read pointer + Gray conversion + empty detection | rd_clk |
| `gray_sync` (×2) | 2-FF synchronizer for CDC pointer transfer | Destination clock |
| `cdc_stress_tb` | Randomized + deterministic verification testbench | Both (async) |

---

## CDC Methodology

### Why Gray Code?

Binary pointers change multiple bits simultaneously when incrementing (e.g., 0111 → 1000 flips 4 bits). When sampled asynchronously, intermediate glitch states are possible. **Gray code changes exactly one bit per increment**, making it safe to sample across clock domains — a metastable capture of any single transition still resolves to either the old or new valid pointer value.

### 2-FF Synchronizer

```verilog
// gray_sync.v — Standard 2-FF metastability synchronizer
module gray_sync #(parameter WIDTH = 4) (
    input  wire             clk,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    reg [WIDTH-1:0] sync_ff1;

    always @(posedge clk) begin
        sync_ff1 <= d;   // FF1: may capture metastable state
        q        <= sync_ff1;  // FF2: resolves before use
    end
endmodule
```

The synchronizer adds **2 destination-clock cycles of latency** per pointer transfer. This is intentional and accounted for in flag generation — the FIFO will appear "more full" or "more empty" than it truly is, which is the **safe** conservative behavior.

### Timing Constraint (cdc_fifo.xdc)

```tcl
# Declare independent clock domains — Vivado will not attempt to time paths crossing these
create_clock -period 10.000 -name wr_clk [get_ports wr_clk]
create_clock -period 27.000 -name rd_clk [get_ports rd_clk]
set_clock_groups -asynchronous -group [get_clocks wr_clk] -group [get_clocks rd_clk]
```

Without `set_clock_groups -asynchronous`, Vivado would flag every CDC path as a timing violation. This constraint correctly tells the tool these clocks are unrelated — the synchronizer FFs are the only legal crossing points.

---

## Simulation & Verification

### Test 1 — Deterministic Write/Read Sequence

Writes sequential values `0x00 → 0x01 → 0x02 → ... → 0x06` using `wr_clk`.  
Reads back using `rd_clk` (asynchronous, slower).

**Result:** `rd_data` correctly reproduces write sequence with visible CDC latency — the synchronizer delay is observable in simulation, confirming the 2-FF pipeline is active.

### Test 2 — Functional Correctness (PASS Verification)

Writes `AA → BB → CC → DD`, then reads back independently.

```
TEST 1: Write 4 values
TEST 2: Read 4 values
data_error_count = 00000000
total_writes     = 4
```

`data_error_count = 0` across all read operations confirms zero data corruption across the clock boundary.

**Waveform evidence:** `rd_data` sequence `AA → BB → CC → DD` matches `wr_data` with correct synchronization delay. `empty` flag deasserts correctly after each write propagates through the synchronizer chain.

### Test 3 — CDC Stress Test (Randomized)

Random `wr_en`/`rd_en` toggling with asynchronous clocks. Stress timeline extended to **240 ns** to cover multiple clock-domain interaction scenarios.

**Key observations:**
- `overflow = 0` throughout entire stress test (no write-when-full events corrupted memory)
- `underflow` counter incremented to **5** — correctly detected and flagged read-when-empty attempts
- No `data_error_count` increments during random traffic

This demonstrates **fault-tolerant flag behavior**: the design doesn't crash on illegal operations, it reports them.

---

## Synthesis Results

**Target Device:** Xilinx Artix-7 `xc7a35ticsg324-1L`  
**Tool:** Vivado (synthesis + implementation)

| Resource | Used | Available | Utilization |
|---|---|---|---|
| Slice LUTs | 26 | 20,800 | **0.13%** |
| Slice Registers (FFs) | 38 | 41,600 | **0.09%** |
| Bonded IOBs | 24 | 250 | **9.60%** |
| BUFGCTRL (clock buffers) | 2 | 32 | **6.25%** |

**Interpretation:** The 2 BUFGCTRL instantiations directly confirm Vivado correctly inferred two independent global clock trees for `wr_clk` and `rd_clk`. This is expected and correct for an asynchronous design.

The minimal LUT/FF count reflects a clean RTL implementation — no logic redundancy, no unintended latches.

---

## Timing Analysis

**Timing Summary (post-implementation):**

| Metric | Value | Status |
|---|---|---|
| Worst Negative Slack (WNS) | **+6.310 ns** | ✅ MET |
| Worst Hold Slack (WHS) | **+0.045 ns** | ✅ MET |
| Failing Setup Endpoints | **0** | ✅ |
| Failing Hold Endpoints | **0** | ✅ |

> *"All user specified timing constraints are met."* — Vivado Timing Summary

**WNS = +6.31 ns** on a 10 ns period clock means the critical path uses only ~3.69 ns of the available 10 ns budget — **63% timing margin**. This indicates the design is well within timing for this device and could tolerate a significantly higher clock frequency, or a slower/cheaper device grade.

The CDC paths are correctly excluded from timing analysis by `set_clock_groups -asynchronous`, meaning these results reflect only the intra-domain paths — which is the correct interpretation.

---

## CDC Stress Test Results

| Test Condition | overflow | underflow | data_error_count | Result |
|---|---|---|---|---|
| Deterministic (4 writes, 4 reads) | 0 | 0 | 0 | ✅ PASS |
| Sequential increment (0x00→0x06) | 0 | 0 | 0 | ✅ PASS |
| Randomized stress (240 ns) | **0** | 5 | 0 | ✅ PASS |

`underflow = 5` in the stress test is **expected and correct** behavior — the randomized testbench intentionally issues reads when the FIFO may be empty. The flag fires, the read is suppressed, and no data corruption occurs. This is the design working correctly, not a failure.

---

## File Structure

```
async_fifo_cdc/
├── rtl/
│   ├── async_fifo_top.v       # Top-level integration
│   ├── fifo_mem.v             # Dual-port synchronous RAM
│   ├── wr_ptr_ctrl.v          # Write pointer + Gray conversion + full flag
│   ├── rd_ptr_ctrl.v          # Read pointer + Gray conversion + empty flag
│   └── gray_sync.v            # 2-FF metastability synchronizer
├── constraints/
│   └── cdc_fifo.xdc           # Async clock group constraints
├── sim/
│   ├── cdc_stress_tb.v        # Randomized + deterministic testbench
│   └── run_sim.tcl            # Vivado simulation script
├── results/
│   ├── utilization_report.png
│   ├── timing_summary.png
│   ├── waveform_pass_test.png
│   ├── waveform_cdc_stress.png
│   ├── waveform_deterministic.png
│   └── device_floorplan.png
└── README.md
```

---

## How to Reproduce

### Prerequisites
- Xilinx Vivado 2022.x or later (free WebPACK edition is sufficient)
- No additional IP licenses required

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/async_fifo_cdc.git
cd async_fifo_cdc

# 2. Open Vivado and create a new project targeting xc7a35ticsg324-1L

# 3. Add all RTL sources from /rtl/
# 4. Add constraint file from /constraints/cdc_fifo.xdc
# 5. Add testbench from /sim/

# 6. Run Behavioral Simulation → observe waveforms matching /results/
# 7. Run Synthesis + Implementation → verify timing summary matches /results/
```

### Expected Outputs
- Simulation: `data_error_count = 00000000`, `total_writes = 4` in TCL console
- Timing: WNS ≥ +6.0 ns, zero failing endpoints
- Utilization: ~26 LUTs, ~38 FFs, 2 BUFGCTRLs

---

## Key Learnings & Design Decisions

**1. Why not use Xilinx FIFO Generator?**  
IP cores abstract away the problem. This implementation was built from scratch to understand *what the IP is actually doing* — Gray code conversion, synchronizer chains, flag timing — and why each piece exists. Understanding this is essential for debugging CDC failures in real SoC designs.

**2. Why Gray code instead of a handshake?**  
A 4-phase handshake achieves CDC with zero metastability risk but at the cost of throughput (one transfer per 4 clock edges minimum). For a FIFO, we need burst throughput. Gray-coded pointers give us near-full throughput at the cost of conservatism in flag timing — a well-understood, accepted tradeoff in industry.

**3. Why are CDC paths excluded from timing report?**  
Because they *should* be. The 2-FF synchronizer handles metastability resolution in the time domain, not through combinational path optimization. Trying to "meet timing" on a CDC path is a category error — the correct fix is a properly constructed synchronizer, not a faster path.

**4. Conservative flag behavior**  
`full` and `empty` flags are intentionally conservative: the FIFO may report "full" when one slot is still available, or "empty" when one word is in transit. This is *by design* — it prevents overflow/underflow at the cost of minor throughput reduction, which is the correct tradeoff for reliable operation.

---

## Future Work

- [ ] **Parameterize depth and width** — Currently fixed at 8-deep, 8-bit. Generalize to `DEPTH` and `WIDTH` parameters with automatic Gray code width calculation
- [ ] **Add formal verification** — Use SymbiYosys/Yosys to prove the no-overflow/no-underflow properties formally, not just by simulation
- [ ] **AXI-Stream wrapper** — Wrap the FIFO with AXI4-Stream slave/master interfaces to make it SoC-integrable
- [ ] **Low-power variant** — Add clock gating on the memory array for power-aware implementation (relevant for embedded/IoT targets)
- [ ] **Silicon estimation** — Run through a standard-cell synthesis flow (e.g., OpenLane/Sky130) to estimate area and power at the gate level

---

## References & Further Reading

1. Cummings, C.E. — *"Simulation and Synthesis Techniques for Asynchronous FIFO Design"* (SNUG 2002) — the foundational paper this design is based on
2. Xilinx UG901 — *Vivado Design Suite User Guide: Synthesis*
3. Xilinx UG949 — *UltraFast Design Methodology Guide* (CDC methodology section)
4. Patterson & Hennessy — *Computer Organization and Design* (Chapter on memory hierarchies)

---

## About This Project

This project was developed as a self-directed hardware engineering study targeting graduate-level competency in digital design and verification methodology. It demonstrates the ability to:
- Identify a real reliability problem (CDC metastability) and solve it from first principles
- Write synthesizable, constraint-driven RTL that meets timing on physical hardware
- Design a verification environment that tests both correct and incorrect operation
- Document design decisions with engineering rationale, not just descriptions

**Skills demonstrated:** SystemVerilog/Verilog RTL, FPGA synthesis, static timing analysis, CDC methodology, simulation-based verification, constraint engineering

---

*If you have questions about this project or want to discuss the design decisions, feel free to open an issue or reach out.*
