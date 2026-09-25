# 06 — Plan Completion and Evidence Matrix

## Phase status

| Plan phase | Deliverables | Status | Evidence / limitation |
|---|---:|---|---|
| 1. Baseline and elaboration | 3 root documents + build evidence | Partial gate | Target packages and whole core compile; hierarchy loaded, but `vopt` backend failed and `vsim` lacks a license. |
| 2. Pipeline and occupancy | 3 root documents | Complete at static level 3 | Storage owners, update/hold/flush rules, stall matrix, redirect scope. |
| 3. Detailed blocks | 12 analyses + index | Complete at static level 3 | Active frontend through CSR/commit paths; operation latency remains dynamic. |
| 4. Memory microarchitecture | 10 analyses + index | Complete at static level 3 | Load/store ownership, FSMs, Sv39/PTW/PMP, WT caches, AXI, fences. |
| 5. Exceptional control | 7 analyses + index | Complete at static level 3 | Redirect matrix, precise exception argument, IRQ/debug/privilege, CSR/PMP inventory. |
| 6. Cycle traces | 18 specifications + index | Blocked from execution | No observed cycles; each file states `NOT EXECUTED` and defines the run/check plan. |
| 7. Verification closure | 4 documents + index | Specified, not run | Pseudo-SVA, coverage plan, trace mapping, and risk register. |

## Target maturity

| Target | Result |
|---|---|
| Level 3 for selected core | Achieved for principal active RTL paths. Integration-dependent reset and late-error semantics remain level 2 to 3. |
| Level 4: ALU forwarding | Open; traces 01/02 and assertions specified. |
| Level 4: load-use hazards | Open; traces 03/04 and assertions specified. |
| Level 4: branch recovery | Open; traces 07/08 and assertions specified. |
| Level 4: store ownership | Open; traces 09/10 and assertions specified. |
| Level 4: precise exceptions | Open; traces 11–14 and assertions specified. |

## Quantitative completeness

- All filenames requested by the plan exist.
- The required minimum of 20 diagrams is exceeded with 37 Mermaid diagrams.
- All internal Markdown link targets resolve.
- Complete core source compilation reports 0 errors and 1,275 warnings.
- Configuration package compilation reports 0 errors and 0 warnings.
- Dynamic trace evidence count is 0 of 18, explicitly disclosed in every trace.

## Review focus

Review the [remaining risks](verification/remaining_risks.md) first. The highest-value next action is to restore a simulator license or provide a supported Verilator plus RISC-V toolchain environment, then execute traces 05, 06, 10, 16, and 18 before performance-oriented traces.
