# 02 — Kiến trúc và trạng thái quan sát được

## Ranh giới kiến trúc

Phần mềm quan sát PC/retirement, GPR/FPR, CSR/privilege, memory operations, traps/debug và counters. Pipeline, scoreboard, predictor, caches và số cổng writeback là vi kiến trúc. CFG-01 issue theo thứ tự, FU có latency khác nhau, scoreboard thu kết quả, commit theo thứ tự từ head. [Scoreboard](../../../core/scoreboard.sv#L135), [commit](../../../core/commit_stage.sv#L145). RISC-V ISA/privilege/debug specification là nguồn yêu cầu; tài liệu này chỉ xác nhận đường hiện thực RTL, chưa chứng nhận compliance theo phiên bản spec cụ thể.

## Inventory trạng thái kiến trúc

| Nhóm | Owner / cập nhật | Điểm quan sát và ưu tiên cần kiểm |
|---|---|---|
| PC/control flow | `frontend.npc_q`, redirect từ branch/eret/trap/CSR/debug | PC fetch mang tính speculative; PC retired quan sát qua commit/RVFI. Assignment cuối trong [NPC select](../../../core/frontend/frontend.sv#L355) thắng khi nhiều nguồn cùng active. |
| GPR/FPR | regfile ghi bằng `we_gpr_o/we_fpr_o` của commit | `rd=x0` cần kiểm gate ở regfile, exception/kill không được write; [commit](../../../core/commit_stage.sv#L184). |
| Privilege/trap | `csr_regfile`: `mstatus`, `mepc`, `mcause`, S equivalents, `satp` | CSR software update và trap/return có thứ tự trong next-state logic; [CSR state](../../../core/csr_regfile.sv#L274), [trap update](../../../core/csr_regfile.sv#L2094). |
| Memory store | speculative store queue → committed queue → WT buffer | Commit chuyển ownership; AXI B hoàn tất muộn hơn. [store buffer](../../../core/store_buffer.sv#L110). |
| Protection/translation | PMP config/address, `satp`; TLB là state vi kiến trúc | CSR/PMP writes bị lock/mask; translation/permission cần kiểm theo effective privilege. [PMP](../../../core/csr_regfile.sv#L1914), [MMU](../../../core/cva6_mmu/cva6_mmu.sv). |
| Debug | debug mode, DPC/DCSR | Entry/exit tách với normal trap; [debug](../../../core/csr_regfile.sv#L2249). |
| Performance | cycle/instret và HPM selectors/counters | `minstret` dùng commit ack với inhibit, custom events có pulse hoặc OR nhiều cổng; [CSR](../../../core/csr_regfile.sv#L1030), [perf](../../../core/perf_counters.sv#L85). |

Reset của GPR payload không nhất thiết xác định; chỉ đọc một register sau khi đã được software khởi tạo. Reset của CSR và privilege cần lấy từ block reset cụ thể, không suy theo reset của `npc_q`. Xem [06](06_clock_reset.md).

## Nghĩa vụ precise exception

Với lệnh lỗi `I`: các lệnh già hơn hoàn tất kiến trúc, `I` chỉ cập nhật trap state theo spec, lệnh trẻ hơn không đổi GPR/FPR/CSR/memory. RTL đóng gate GPR/CSR/store ở [commit](../../../core/commit_stage.sv#L169), lưu exception trong [scoreboard](../../../core/scoreboard.sv#L195), flush ở [controller](../../../core/controller.sv#L236). Đó là cơ chế hỗ trợ, chưa phải bằng chứng end-to-end cho mọi race; đặc biệt load response sau flush và write error muộn cần test/formal. [07](07_corner_cases.md).
