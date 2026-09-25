# Cycle Trace Specifications

## Status

All 18 required traces are **NOT EXECUTED**. Questa compiled the complete core, but `vsim` could not check out a license. Verilator and Icarus are not installed. [Run log](../evidence/build/config_run.log)

No table in this directory contains invented cycle numbers. Each file defines the stimulus, observation set, expected RTL relationships, pass criteria, and current blocker. When a simulator is available, replace the empty template rows with every cycle from first request through architectural/external completion, including idle and stalled cycles.

## Common columns

| Cycle | Fetch PC | Commit PC | Instruction | Scoreboard ID/state | Queue/FU valid | Stall/forward source | Redirect/exception | Load/store/cache/PTW state | AXI AR/R/AW/W/B | Commit ack | Architectural effect |
|---:|---|---|---|---|---|---|---|---|---|---|---|
| _pending_ | | | | | | | | | | | |

## Trace list

1. [ALU writeback forwarding](trace_01_alu_writeback_forwarding.md)
2. [Scoreboard forwarding](trace_02_scoreboard_forwarding.md)
3. [Load hit dependency](trace_03_load_hit_dependency.md)
4. [Load miss dependency](trace_04_load_miss_dependency.md)
5. [Load grant with flush](trace_05_load_grant_with_flush.md)
6. [Load response after flush](trace_06_load_response_after_flush.md)
7. [Correct branch prediction](trace_07_correct_branch_prediction.md)
8. [Branch misprediction](trace_08_branch_misprediction.md)
9. [Store to AXI completion](trace_09_store_to_axi_completion.md)
10. [Store flush before commit](trace_10_store_flush_before_commit.md)
11. [Instruction fault](trace_11_instruction_fault.md)
12. [Data protection fault](trace_12_data_protection_fault.md)
13. [Interrupt during memory stall](trace_13_interrupt_during_memory_stall.md)
14. [Debug and interrupt concurrency](trace_14_debug_interrupt_concurrency.md)
15. [FENCE.I and self-modifying code](trace_15_fence_i_self_modifying_code.md)
16. [SFENCE during PTW](trace_16_sfence_during_ptw.md)
17. [Atomic operation](trace_17_atomic_operation.md)
18. [Reset during AXI transaction](trace_18_reset_during_axi_transaction.md)
