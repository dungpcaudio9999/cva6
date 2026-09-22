# Câu hỏi còn mở

Baseline `BASE-01`; cấu hình dự kiến `CFG-01 = cv64a6_imafdc_sv39`, Makefile/Verilator APU harness. Đây là sổ theo dõi đang được cập nhật trong quá trình đọc nguồn.

- **OQ-01 — HIGH, OPEN:** Chưa có elaboration của target. Cần khôi phục dependency, simulator và toolchain rồi lưu command, hierarchy, parameters và log. Chặn kết luận về hierarchy thực tế và execution baseline.
- **OQ-02 — HIGH, OPEN:** Các submodule chưa khởi tạo. Cần kiểm tra recursive dependency đúng gitlink trước build; không suy ra hành vi nội bộ IP chưa có nguồn.
- **OQ-03 — HIGH, OPEN:** Chưa có simulation, formal, CDC/RDC hoặc STA cho snapshot này. Cần kiểm chứng các luồng reset/flush, store/fence, ngắt và lỗi bộ nhớ.

Owner quyết định/waiver: người dùng hoặc maintainer được chỉ định; chưa có waiver nào được phê duyệt. Người lập phân tích chỉ ghi nhận hạn chế, không tự chấp thuận bỏ qua gate.
