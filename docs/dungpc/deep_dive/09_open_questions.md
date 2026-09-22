# 09 — Câu hỏi mở và gate hoàn thành

| ID | Chưa đủ chứng cứ | Thí nghiệm / artifact cần |
|---|---|---|
| OQ-01 | Cấu hình thực sự được elaborated cho target, defines/overrides và hierarchy active | Lưu command/env, Verilator hoặc simulator elaboration log, parameter dump; đối chiếu [source config](00_scope_and_configuration.md). |
| OQ-02 | Full dependency/IP, ROM/ELF và boot end-to-end | Resolve submodules, build/sim harness, boot signature và trace reset→first retire. |
| OQ-03 | Precise exception toàn đường, đặc biệt load response sau flush và ID reuse | Directed race test + assertions theo [07](07_corner_cases.md); waveform kèm issue ID, flushed bit, writeback và commit. |
| OQ-04 | Error mapping/visibility cho AXI read/write, nhất là B sau store retire | Inject R/B error từng tầng WT adapter/AXI shim; ghi trap hoặc contract “imprecise/unsupported” từ spec integration. |
| OQ-05 | Ưu tiên debug/IRQ/trap/eret khi đồng thời và trong WFI/halt | Pairwise event matrix theo privilege/debug mode, waveform CSR cause/EPC/DPC, PC mux. |
| OQ-06 | Worst-case backpressure/throughput/latency, fence drain tới tầng nào | Performance counters + waveform request/grant/response dưới tải hit/miss/PTW/AXI. |
| OQ-07 | CSR inventory đầy đủ với reset value, field mask, WARL/WPRI và simultaneous update | Script trích CSR case + review từng register, ISA privileged model compliance. |
| OQ-08 | PMP/translation permit-deny cho fetch/load/store, MPRV và locked region | Directed permission matrix và MMU/PMP signal traces; đặc biệt crossing, superpage, A/D bits. |
| OQ-09 | Clock gating, reset release/CDC, partial reset và outstanding AXI isolation | Integration elaboration, reset-domain review, reset-mid-transaction sim. |
| OQ-10 | Instruction semantic coverage đầy đủ cho B/ZKN/Zcb/F/D/AMO/CVXIF | Decode coverage report + ISA tests + RVFI comparison; target name không đủ làm chứng chỉ compliance. |
| OQ-11 | Phiên bản chính xác của ISA, privileged, debug và memory model specs dùng làm chuẩn | Pin tài liệu/commit/spec section cho từng requirement trước khi gọi architectural compliance. |

**Định nghĩa đóng:** mỗi claim có spec/config/RTL/test link, bốn trace ALU/load/branch/exception có waveform marker và checker pass, từng class lệnh có semantic model, mọi PC source và architectural state có update/priority, memory/protection/error contract được xác nhận. Hiện hồ sơ là phân tích source với các proof obligation cụ thể, chưa đạt tất cả gate động của guide.
