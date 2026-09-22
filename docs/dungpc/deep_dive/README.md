# CVA6 RTL deep dive — CFG-01

Phân tích tĩnh tại commit `f591a3972e65c22ff1b79c9aab955784e6916151`, theo `CPU_RTL_Analysis_Guide.md`. Cấu hình chọn: `cv64a6_imafdc_sv39`, đường Makefile → `core/Flist.cva6` → `cva6_config_pkg::cva6_cfg` → `build_config_pkg::build_config`. Kết luận áp dụng cho source và lựa chọn cấu hình này; chưa có elaboration đầy đủ, waveform, hay ISA compliance run. Ký hiệu **RTL** là suy ra trực tiếp từ source, **suy luận** là hệ quả cần xác minh động, **chưa xác minh** là chỗ không có chứng cứ đủ mạnh. Xem [phạm vi](00_scope_and_configuration.md) và [câu hỏi mở](09_open_questions.md).

## Bộ hồ sơ

1. [00 Phạm vi và cấu hình](00_scope_and_configuration.md)
2. [01 Bản đồ repository](01_repository_map.md)
3. [02 Kiến trúc](02_architecture.md)
4. [03 Giao tiếp](03_interfaces.md)
5. [04 Luồng lệnh chính](04_dominant_flow.md)
6. [05 Control và state](05_control_and_state.md)
7. [06 Clock và reset](06_clock_reset.md)
8. [07 Corner cases](07_corner_cases.md)
9. [08 Điểm kiểm chứng](08_verification_points.md)
10. [09 Câu hỏi mở](09_open_questions.md)
11. [cpu_01 Pipeline map](cpu_01_pipeline_map.md)
12. [cpu_02 Instruction classes](cpu_02_instruction_classes.md)
13. [cpu_03 Hazard và forwarding](cpu_03_hazard_and_forwarding.md)
14. [cpu_04 Exception, interrupt, debug](cpu_04_exception_interrupt_debug.md)
15. [cpu_05 CSR, privilege, protection](cpu_05_csr_privilege_protection.md)
16. [cpu_06 Memory system](cpu_06_memory_system.md)
17. [cpu_07 Retirement model](cpu_07_retirement_model.md)
18. [cpu_08 Performance model](cpu_08_performance_model.md)
19. [cpu_09 Worked trace records](cpu_09_trace_records.md)

## Kết luận cốt lõi

Instruction đi từ frontend/queue qua decode, issue, FU, scoreboard rồi commit theo thứ tự. `NrIssuePorts=1`, `NrCommitPorts=2`; cổng commit 1 chỉ hoạt động sau cổng 0 và chỉ cho tập FU có điều kiện. Scoreboard writeback là hoàn thành tính toán, chưa phải retirement. Store retirement chuyển entry speculative sang committed queue; AXI `B` là mốc muộn hơn. Trap và redirect đòi hỏi dọn việc trẻ hơn, trong khi load đã gửi request còn phải nhận response và suppress writeback nếu đã flush. Các ranh giới này được dùng làm checker trong [08](08_verification_points.md).

## Giới hạn chứng cứ

Các bảng theo chu kỳ trong hồ sơ là **mẫu quan hệ có điều kiện**, không phải waveform hay latency đo được. Không gắn nhãn “đã chứng minh” cho ưu tiên sự kiện đồng thời, tính chính xác exception toàn hệ, hoặc phản hồi lỗi write muộn trước khi có simulation/formal. Tài liệu nền trong thư mục cha vẫn là nguồn bổ sung, đặc biệt [build/config](../03_build_and_configuration.md) và [system flows](../09_system_flows.md).
