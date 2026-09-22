# 00 — Phạm vi và tiêu chí hoàn thành

## Mục tiêu

**Basic architectural understanding** theo guide revision 3.1: người đọc có thể tìm nguồn đúng cấu hình, giải thích datapath/control/state, lần theo boot–retire, load/store–memory, flush/fence và ngắt, đồng thời biết cần kiểm chứng gì trước tích hợp hoặc sửa RTL.

Người dùng yêu cầu phân tích repository, chưa chỉ định target. Chọn default Makefile `cv64a6_imafdc_sv39` là quyết định scope của người phân tích, không phải xác nhận target sản phẩm của người dùng. Khảo sát các cấu hình khác ở mức inventory; không gộp các nhánh WT/WB/HPDCache, RV32/RV64 hay FPGA vào một thiết kế.

## Boundary

- Trong phạm vi: core `cva6`, wrapper `ariane`, `ariane_testharness`; pipeline, scoreboard/commit, LSU, MMU/PTW, WT cache/AXI; reset, boot ROM, SRAM, CLINT và kết nối peripheral/PLIC/debug.
- CSR có độ sâu field-level cho các field phục vụ reset, trap, interrupt, translation, cache enable và FP status. Toàn bộ CSR/peripheral inventory chi tiết là gap được ghi ở OQ-08, không phải đã audit xong.
- Ngoài phạm vi triển khai chi tiết: mọi phép toán FPU/crypto, HPDCache/WB, vector/hypervisor, mọi target FPGA/ASIC, physical timing/power, security/ISA compliance sign-off, toàn bộ UVM regression và sửa RTL.
- PLIC/debug/FPU là boundary phụ thuộc có thật; thiếu submodule được ghi là hạn chế, không đánh dấu tính năng không tồn tại.

## Ưu tiên rủi ro

Ưu tiên target selection và dependency; sau đó speculative versus architectural state, load response sau flush, committed store/fence, bus error propagation, memory alias, reset độc lập và IRQ. Đây là các điểm có thể làm thay đổi kết luận tích hợp dù module không lớn.

Stages và lý do áp dụng có trong [bảng entry point](README.md#trạng-thái-tài-liệu). Stage 14 chỉ là hướng dẫn impact, không thực hiện thay đổi. Độ sâu Stage 10 tập trung 6 nhóm module; Stage 11 là review verification, không phải nhiệm vụ xây dựng verification hoàn chỉnh.

## Evidence cần có và gate

| Gate | Điều kiện | Đánh giá hiện tại |
|---|---|---|
| G-01 | Commit, local diff, dependency, config nhận diện được | MET cho source snapshot; dependency bytes chưa có |
| G-02 | File list/top/parameters actual từ elaboration | LIMITED — chỉ source intent và package compile |
| G-03 | Giải thích block, state, selected interfaces/flows với nguồn | MET ở source level |
| G-04 | Có command/log, prediction/result, nguồn kiểm tra lại được | MET cho các kiểm tra đã thực hiện |
| G-05 | Critical unknown được giải quyết hoặc owner chấp nhận | NOT-MET — chưa có waiver cho OQ HIGH |
| G-06 | Behavior/coverage/timing được kiểm chứng | NOT-MET; không phải gate sign-off được thực hiện trong nhiệm vụ này |

**Mức kết thúc:** bàn giao phân tích nguồn `COMPLETE-WITH-LIMITATIONS`, architecture objective `LIMITED` theo gate của guide. Không tuyên bố build/simulate objective đã hoàn thành.

## Công cụ, effort và owner

Công cụ dùng: Git, Python 3, GNU Make, Questa compiler/simulator có trên PATH. Không tìm thấy Verilator/Icarus/Yosys/SBY/Bender trên PATH. Không cài tool, tải submodule hay thay license trong phiên này; nhu cầu đó được liệt kê để tái lập.

Effort chọn cho phiên: một vòng baseline → đọc dependency/flow/state → kiểm tra cục bộ → viết và kiểm tra tài liệu; không chạy cài đặt/regression nhiều giờ ngoài mục tiêu phân tích. Review tại thời điểm bàn giao 2026-09-08. Decision owner: người dùng/maintainer; chưa chỉ định reviewer hay chấp nhận waiver. Khi target hoặc độ sâu cần thiết thay đổi, cập nhật scope và freshness trước mở rộng kết luận.
