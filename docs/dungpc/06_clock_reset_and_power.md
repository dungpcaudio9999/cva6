# 06 — Clock, reset và power

## Domain và mode

| Domain/signal | Nguồn → đích | Structure có trong source | Contract/gap |
|---|---|---|---|
| `clk_i` | Harness → core, AXI, CLINT/peripherals | Core pipeline cùng clock boundary | Không có STA/Fmax; không suy clock sản phẩm từ TB |
| `rtc_i` | RTC ngoài → CLINT trên clk_i | `clint_sync` 2 stages + edge detect register | Pulse/level phải đủ thời gian lấy mẫu, reset/clock chạy; chưa CDC/MTBF |
| JTAG TCK/DMI | JTAG driver → debug transport → system | Harness instantiate DMI/JTAG IP | Nội bộ submodule thiếu, crossing chưa xác lập |
| External IRQ/debug | Top → CSR/decode | Các đường level trực tiếp tới logic core | Không có bằng chứng synchronizer đủ cho mọi đường async |
| `rst_ni` | Test/system reset | Asynchronous active low ở nhiều core always_ff | Mỗi integrator phải bảo đảm release và recovery |
| `ndmreset_n` | `rst_ni & ~ndmreset` → rstgen | Reset của core/xbar/đa số peripherals | Debug module giữ system reset riêng; partial reset cần drain/cancel contract |

Nguồn: [harness reset](../../corev_apu/tb/ariane_testharness.sv#L103), [rstgen](../../vendor/pulp-platform/common_cells/src/rstgen.sv#L14), [rstgen_bypass](../../vendor/pulp-platform/common_cells/src/rstgen_bypass.sv#L14), [CLINT sync](../../corev_apu/clint/clint.sv#L199), [CSR IRQ](../../core/csr_regfile.sv#L2079).

Trong functional mode `test_en=0`, rstgen_bypass dùng chuỗi register đưa 1 vào sau reset; asynchronous assertion, clocked release. Test mode bypass chuyển hành vi reset. Không mô tả trễ release cố định mà không xét parameter `NumRegs`, sampling đầu vào và tool implementation.

## FND-RST-01 — Reset phân vùng thực sự khác nhau

**Support:** SUPPORTED. **Scope/evidence:** harness CFG-01: core reset bằng `ndmreset_n` ở [643](../../corev_apu/tb/ariane_testharness.sv#L643), SRAM nối `rst_ni` ở [480](../../corev_apu/tb/ariane_testharness.sv#L480), debug adapter giữ system reset ở [320](../../corev_apu/tb/ariane_testharness.sv#L320). [RTL:ESTABLISHED]

`ndmreset` có thể reset core/xbar trong khi debug path hoặc SRAM boundary không cùng reset. Cần xem nghĩa vụ transaction trước reset, dọn responses cũ, memory retained state và cách software restart. Kết nối reset khác nhau được xác lập; chưa chứng minh recovery đúng hoặc SRAM payload bị/không bị xóa bởi reset. [OQ-05](13_open_questions.md).

## Bốn lớp bằng chứng crossing

1. **Structure:** RTC có chain 2 FF và 1 FF lưu previous synchronized value; IRQ vào `mip_d`/SEIP read merge không tương đương chain đồng bộ. Debug CDC submodule chưa có.
2. **Operating contract:** RTC cần giữ mức đủ dài để tránh bỏ cạnh; IRQ cần level retention/clear tại nguồn; boot address/hart ID coi như static quanh reset; clock dừng sẽ ngừng nhận sự kiện.
3. **Setup/constraints:** Có Xilinx `ariane.xdc` khai báo TCK 100 ns và clock khác; Altera SDC khai báo false paths giữa clocks. Đây là platform khác, chưa apply vào CFG-01 harness, chưa có matched endpoint report.
4. **Verification/physical:** Không có CDC/RDC report, pulse-loss scenario, synchronizer placement, skew/MTBF/corner analysis; tất cả NOT-RUN. Không chuyển false-path declaration thành kết luận crossing safe.

## WFI, power và DFT

`wfi_q` điều khiển `halt_csr_o`; wake khi enabled pending IRQ, debug request hoặc S external input theo [wfi_ctrl](../../core/csr_regfile.sv#L2662). Đây là **halt state**, không phải bằng chứng đã tắt clock hay nguồn điện. Controller kết hợp halt và fence activity.

Boundary harness không cung cấp switchable power-domain/isolation/retention sequencing được phân tích. Power-off protocol/UPF sign-off nằm ngoài scope, không tuyên bố SoC không có khả năng power management trên mọi platform. JTAG functional debug được xét; scan-chain insertion, ATPG, test clock frequency và silicon power NOT-RUN. Test-mode bypass cần review riêng khi chuyển platform.

**Gate:** LIMITED. Clock/reset structure có nguồn, còn CDC/RDC operating assumptions chưa discharge. [OQ-05](13_open_questions.md).
