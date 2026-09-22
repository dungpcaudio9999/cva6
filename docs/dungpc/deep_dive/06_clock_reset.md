# 06 — Clock, reset và low power

Core state chủ yếu dùng `always_ff @(posedge clk_i or negedge rst_ni)`: frontend PC/valid, ID register, issue FU valid, scoreboard, load metadata, store queues, controller fence state. [Frontend](../../../core/frontend/frontend.sv#L421), [ID](../../../core/id_stage.sv#L473), [issue](../../../core/issue_read_operands.sv#L802), [scoreboard](../../../core/scoreboard.sv#L304), [load](../../../core/load_unit.sv#L185), [store](../../../core/store_buffer.sv#L263), [controller](../../../core/controller.sv#L265). Đây là reset bất đồng bộ active-low theo RTL; release synchronization ở integration phải kiểm riêng.

`npc_q` reset về 0 nhưng `npc_rst_load_q=1`; logic next-PC mới nạp `boot_addr_i` ở cycle hoạt động tiếp theo. Do đó không gọi 0 là reset vector kiến trúc. [Frontend](../../../core/frontend/frontend.sv#L355). Scoreboard reset entries/pointers, load buffer valid/flushed và store queues/count về 0, ngăn transaction metadata cũ tạo retire sau reset. AXI transaction đã ra wrapper/downstream cần kiểm reset domain và response cũ; core flop reset đơn lẻ chưa chứng minh không có stale response. [Câu hỏi mở](09_open_questions.md).

`WFI` được decode/CSR điều khiển halt/wake; controller `halt_o` kết hợp `halt_csr_i`, `halt_acc_i`, fence-active, còn `halt_frontend_o` dùng `fence_i_active_q`. [Decoder WFI](../../../core/decoder.sv#L276), [controller halt](../../../core/controller.sv#L255). Chưa tìm thấy clock gating cell được chứng nhận active cho CFG-01 trong đường core đã chọn; không đồng nhất `halt` với gated clock. Để đóng mục power, cần waveform clock enable, WFI→IRQ wake, debug wake, fence.i đang active và reset giữa outstanding AXI.

## Check reset tối thiểu

1. Assert reset trong lúc load outstanding và committed store/write buffer không rỗng; ghi transaction ID và AXI response epoch trước/sau reset.
2. Sau release, xác nhận PC đầu lấy `boot_addr_i`, scoreboard rỗng, load/store metadata rỗng, privilege/CSR reset theo [csr_regfile](../../../core/csr_regfile.sv).
3. Không so sánh GPR payload chưa khởi tạo trước software write; so sánh valid/commit/write enable và CSR reset được đặc tả.
