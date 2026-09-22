# 10 — Module analysis index

Mỗi bài áp dụng BASE-01/CFG-01, work status COMPLETE-WITH-LIMITATIONS, evidence CURRENT cho nguồn đã hash. Instance paths dưới đây là **source candidates**, chưa elaborated hierarchy. Chọn theo state ownership và ảnh hưởng recovery thay vì số dòng code.

| Bài | Boundary/instance dự kiến | Ưu tiên và flow |
|---|---|---|
| [scoreboard_commit](scoreboard_commit.md) | cva6 → issue_stage/scoreboard, commit_stage | Architectural order, full queue, double retirement; FLOW-01/05 |
| [load_store](load_store.md) | ex_stage → LSU → load_unit/store_buffer | Transaction ownership, flush races, finite buffers; FLOW-02/03/05 |
| [frontend_controller](frontend_controller.md) | cva6 → frontend/controller | Redirect priority, fence and recovery; FLOW-01/04/05 |
| [mmu_ptw](mmu_ptw.md) | LSU/MMU → TLB/PTW/PMP | Translation fault và shared resource; FLOW-02/04 |
| [wt_cache_axi](wt_cache_axi.md) | cva6.gen_cache_wt → WT adapter/axi_shim | Completion/error path, byte merge, outstanding slots; FLOW-02/03/04 |
| [csr_clint](csr_clint.md) | CSR regfile và harness CLINT | Trap state, timer/reset/software races; FLOW-06/07 |

FPU implementation, PLIC/debug internal, complete decoder instruction audit, arithmetic correctness và alternative cache branches chưa đọc ở module-depth; xem OQ-02/08 và scope. Invariant dưới đây là đề xuất property/source argument, không có formal proof hoặc assertion activation result.
