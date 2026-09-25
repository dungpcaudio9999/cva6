# 04 — Pipeline and Ownership Register Inventory

| Owner | Registered state | Reset | Update and visibility |
|---|---|---|---|
| `frontend` | `npc_q`, reset-load flag, speculation flag, cached response payload/metadata, saved BHT/BTB prediction | metadata cleared; `npc_q=0`; reset-load set | `npc_q<=npc_d` each cycle; cached response fields update on I-cache valid. [RTL](../../../../core/frontend/frontend.sv#L421) |
| `instr_queue` | instruction FIFO payload/valid, address FIFO, read/write indices | valid/index state cleared | push from fetch packet; pop from ID ready; replay preserves an unaccepted address. [RTL](../../../../core/frontend/instr_queue.sv#L300) |
| `id_stage` | `issue_q[0]`: valid, scoreboard entry, original instruction, control-flow flag | zero | ack/replacement/flush priority described in [pipeline model](03_pipeline_occupancy_model.md). |
| `scoreboard` | eight `mem_q` records; issue pointer; two precomputed commit pointers | all zero | issue sets ownership; writeback sets completion; commit releases; flush clears. [RTL](../../../../core/scoreboard.sv#L162) |
| `issue_read_operands` | `fu_data_q`; valid vectors for ALU, branch, LSU, CSR, mult, FPU, AES, CV-X-IF; FP format/RM; optional bypass metadata | zero valid/data | dispatch next values; flush clears valid; no queue behind each one-cycle input register. [RTL](../../../../core/issue_read_operands.sv#L737) |
| `mult/serdiv` | multiplier/divider pipeline or iterative state | unit-specific reset | structural busy feeds issue admission; result returns with transaction ID. |
| `fpu_wrap` | FP unit pipelines and arbitration metadata | unit-specific reset | ready/valid protocol; flags travel in exception metadata to commit. |
| `load_unit` | 10-state FSM; two load-buffer entries; valid/flushed bits; last allocated ID | FSM IDLE; buffers zero | cache grant allocates; response releases; flush marks all allocated entries flushed. [RTL](../../../../core/load_unit.sv#L95) |
| `store_unit` | 4-state FSM; translated data, byte enable, size, AMO/CBO op, transaction ID | FSM IDLE; payload zero | translation/request sequencing; accepted ordinary store moves to speculative store buffer. [RTL](../../../../core/store_unit.sv#L126) |
| `store_buffer` | four-entry speculative queue and pointers/count; four-entry committed queue and pointers/count | all zero | LSU allocates speculative; commit transfers oldest; flush clears only speculative; D-cache grant releases committed normal store. [RTL](../../../../core/store_buffer.sv#L75) |
| `cva6_mmu` | registered LSU request/translation metadata; TLB arrays in submodules; PTW state | invalid/IDLE | TLB hit is lookup result; PTW fills; SFENCE invalidates matching entries. |
| `cva6_ptw` | state, walking level, addresses/PTE, request/kill/error metadata | IDLE/zero | one active walk; request/grant/response advance FSM; flush can force drain/kill behavior. [RTL](../../../../core/cva6_mmu/cva6_ptw.sv#L116) |
| `cva6_icache` | six-state FSM, request address/tag/offset, replacement way, flush counter, valid arrays | state FLUSH; metadata zero | reset deliberately walks FLUSH before normal fetch use. [RTL](../../../../core/cache_subsystem/cva6_icache.sv#L507) |
| `wt_dcache_ctrl` | per-port eight-state FSM and saved tag/index/offset/ID/size | IDLE/zero | grant captures request identity; tag phase decides hit/miss; kill paths drain misses. [RTL](../../../../core/cache_subsystem/wt_dcache_ctrl.sv#L61) |
| `wt_dcache_missunit` | seven-state FSM, one read MSHR, flush counter, arbitration/collision state, AMO state | IDLE/zero | at most one outstanding read MSHR; WT transaction slots separately track writes. [RTL](../../../../core/cache_subsystem/wt_dcache_missunit.sv#L110) |
| `wt_dcache_wbuffer` | eight word entries with valid/dirty byte state; four transaction status slots; pointers/arbiters | zero | stores merge/allocate; dirty bytes launch memory writes; response clears transaction/bytes subject to rewrites. |
| `commit_stage` | no ordinary retirement register; optional delayed trigger exception register | optional trigger state reset | commit is combinational over ordered scoreboard heads; architectural owners register effects on the edge. [RTL](../../../../core/commit_stage.sv#L145) |
| `csr_regfile` | privilege, status, EPC/cause/tval, delegation, interrupt, satp, PMP, debug, counters | specified per field; privilege M | one large next-state process combines software write, counters, interrupts, trap, debug, and return updates. |
| `controller` | fence-active, fence-I-active, registered D-cache flush request | zero | combinational event decoding; fence state remains until cache acknowledgement when configured. [RTL](../../../../core/controller.sv#L255) |

## Ownership rule

A register is considered part of instruction lifetime only while its associated valid, issued, outstanding, or queue-count metadata grants ownership. Payload bits may remain unchanged after release and must not be interpreted without that metadata.
