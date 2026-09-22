# Phân tích nguồn CVA6

Phân tích ngày 2026-09-08 theo [RTL Analysis Guide revision 3.1](rtl_analysis.md). Mục tiêu: hiểu kiến trúc, quyền sở hữu state và các luồng quan trọng của cấu hình mặc định `cv64a6_imafdc_sv39`, với APU testharness làm ngữ cảnh tích hợp. Kết quả là **phân tích nguồn có giới hạn kiểm chứng**, không phải xác nhận CPU đã chạy đúng.

## Baseline và kết quả chính

- `BASE-01`: commit `f591a3972e65c22ff1b79c9aab955784e6916151`; không có tracked source diff trước phân tích. SHA-256 từng nguồn và gitlink nằm trong [evidence/BASE-01](evidence/BASE-01/baseline.json).
- `CFG-01`: cấu hình dự kiến từ Makefile → `core/Flist.cva6` → package → `build_config()` → `ariane_testharness`. **Chưa có hierarchy elaborated của CPU.**
- Issue width = 1, commit ports = 2, scoreboard = 8; cache WT; CV-X-IF bật nhưng wrapper chọn `COPRO_NONE`. Tên target không mô tả hết các feature bit.
- Phải phân biệt store retirement, grant vào D-cache và write response ngoài AXI. Fence dùng điều kiện drain kết hợp LSU và WT write buffer.
- Cửa sổ DRAM của harness là 1 GiB, nhưng SRAM mặc định là 256 MiB; địa chỉ bị cắt khi vào SRAM, tạo alias ở mức đường địa chỉ.
- 18 submodule chưa khởi tạo; preflight `core/Flist.cva6` thiếu 63/182 file nguồn. Make dry-run trả 2 vì `RISCV` chưa đặt. Questa 10.7c compile probe cấu hình thành công, nhưng `vsim` trả 4 do license; chưa có kết quả simulation.

## Trạng thái tài liệu

`COMPLETE-WITH-LIMITATIONS` mô tả phần việc phân tích đã ghi nhận đầy đủ giới hạn; không có nghĩa các gate verification đã đạt. Tất cả tài liệu áp dụng `BASE-01/CFG-01`, freshness `CURRENT` cho snapshot; thứ tự ưu tiên nguồn là actual RTL, cấu hình/build, rồi tài liệu mô tả.

| Tài liệu | Applicability và lý do | Trạng thái | Gate/hạn chế chính |
|---|---|---|---|
| [00 Scope](00_scope.md) | REQUIRED — mọi mục tiêu | COMPLETE | Scope do người phân tích chọn và công khai |
| [01 Baseline](01_repository_baseline.md) | REQUIRED — mọi mục tiêu | COMPLETE-WITH-LIMITATIONS | Chưa có execution baseline |
| [02 Inventory](02_source_inventory.md) | REQUIRED — kiến trúc | COMPLETE-WITH-LIMITATIONS | IP vắng mặt, activation chưa elaborated |
| [03 Build/config](03_build_and_configuration.md) | REQUIRED — kiến trúc | COMPLETE-WITH-LIMITATIONS | Compile package có log, CPU chưa elaborated |
| [04 Architecture](04_architecture.md) | REQUIRED — kiến trúc | COMPLETE-WITH-LIMITATIONS | Topology suy từ source |
| [05 Interfaces](05_interfaces.md) | REQUIRED — kiến trúc | COMPLETE-WITH-LIMITATIONS | Contract source, chưa có waveform |
| [06 Clock/reset](06_clock_reset_and_power.md) | REQUIRED — RTC/JTAG/reset | COMPLETE-WITH-LIMITATIONS | Chưa CDC/RDC/STA |
| [07 Memory](07_memory_and_address_map.md) | REQUIRED — CPU/APU | COMPLETE-WITH-LIMITATIONS | Alias/error/boot chưa chạy |
| [08 CSR/IRQ](08_registers_and_interrupts.md) | REQUIRED — trap/boot/timer | COMPLETE-WITH-LIMITATIONS | Các field trọng tâm; PLIC IP vắng |
| [09 Flows](09_system_flows.md) | REQUIRED — kiến trúc | COMPLETE-WITH-LIMITATIONS | 7 luồng, chưa đo cycle |
| [10 Modules](10_module_analysis/README.md) | CONDITIONAL — state/flush rủi ro | COMPLETE-WITH-LIMITATIONS | 6 bài phân tích nhóm module |
| [11 Verification](11_verification_analysis.md) | CONDITIONAL — review checker/gap | COMPLETE-WITH-LIMITATIONS | Không có coverage run |
| [12 Experiments](12_experiments.md) | CONDITIONAL — kiểm tra giả thuyết | COMPLETE-WITH-LIMITATIONS | Preflight/compile/model, runtime bị chặn |
| [13 Questions](13_open_questions.md) | REQUIRED — mọi mục tiêu | COMPLETE-WITH-LIMITATIONS | Còn HIGH, chưa có waiver |
| [14 Change impact](14_change_impact.md) | CONDITIONAL — hướng dẫn tái phân tích | COMPLETE | Không có RTL change được đề xuất áp dụng |
| [15 Glossary](15_glossary.md) | REQUIRED — mọi mục tiêu | COMPLETE | Có namespace và ranh giới thuật ngữ |
| [16 Summary](16_final_summary.md) | REQUIRED — mọi mục tiêu | COMPLETE-WITH-LIMITATIONS | Architecture gate LIMITED |

Không tạo kết luận NOT-APPLICABLE chỉ vì thiếu công cụ. Power gating/retention không được thiết lập trong boundary harness này; platform physical sign-off nằm ngoài scope.

## Thứ tự đọc

Đọc [tóm tắt](16_final_summary.md), [kiến trúc](04_architecture.md), [cấu hình](03_build_and_configuration.md), [luồng](09_system_flows.md), rồi các [module ưu tiên](10_module_analysis/README.md). Khi dùng kết quả để tích hợp/sửa RTL, bắt đầu từ [open questions](13_open_questions.md).

## Evidence và tái lập

[Evidence index](evidence/README.md) chứa command, log, hashes và các script chạy lại. Không cần sửa source để chạy preflight. Kết quả mới phải lưu vào thư mục mới để giữ lịch sử `BASE-01`. [12_experiments.md](12_experiments.md) phân biệt expected/observed và compile/simulation.
