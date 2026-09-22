# 05 — Contract giao tiếp

Tất cả sự kiện đồng bộ dưới đây lấy giá trị **trước cạnh lên `clk_i`**, ngoài reset; cập nhật state có hiệu lực sau NBA. Đây là contract tái dựng từ nguồn CFG-01, không phải chứng nhận tuân thủ toàn bộ protocol spec.

| Boundary | Bắt đầu / accepted | Completion / ownership | Backpressure / lỗi |
|---|---|---|---|
| Decoder → issue/scoreboard | decoded valid và decoded ack; allocation thêm điều kiện `!flush_unissued_instr_i` | Ghi slot, gán `trans_id` từ issue pointer | Full/hazard/FU busy ngăn ack; không tính presented thành issued |
| FU → scoreboard | `wt_valid_i` cùng ID, entry `issued` | Cập nhật result/exception và ready-to-commit | Không generic ready/valid; stale response cần epoch/flush handling ở producer |
| Scoreboard → commit | `commit_instr_i[p].valid` | `commit_ack_o[p]` trả slot, register/CSR/store side effect theo instruction | Port 1 không ack khi port 0 chưa ack; halt/exception/CSR/store/fence có guards |
| LSU → store buffer | `valid_i` là pulse đã được producer cho phép | Enqueue speculative; `commit_i` chuyển queue | `ready_o` không được AND thêm trong buffer; caller phải tuân thủ |
| Committed stores → D-cache | `data_req && data_gnt` | Với CBO_NONE, local committed entry được lấy ra | Grant không phải B response; WT buffer giữ trách nhiệm tiếp |
| Load/PTW → D-cache | `data_req && data_gnt`, index/byte metadata; tag/kill phase riêng | `data_rvalid` và transaction metadata, hoặc fault/kill recovery | Phải đọc SEND_TAG/ABORT/WAIT; không rút gọn thành bus AXI trực tiếp |
| Core → AXI | AR/AW/W: valid && ready **từng kênh** | R beat acceptance; read completion với RLAST; B acceptance cho write | READY có thể thấp vô hạn; không có bounded completion nếu không có service assumption |
| CLINT internal memory access | `en && we` hoặc `en && !we` từ bridge | Cập nhật hoặc read state | External AXI handshake do bridge, không đồng nhất `en` với AW |
| IRQ/debug → core | Level/condition nhận bởi CSR/decode/debug logic | Trap/entry ở architectural boundary | Không có generic ready/ack output để xác nhận mỗi pulse |
| CV-X-IF | issue valid/ready và response accept riêng | Accepted extension mới sinh nghĩa vụ result | Wrapper COPRO_NONE: ready=1, accept=0; không tính ready là accept |

Nguồn: [scoreboard 145–260](../../core/scoreboard.sv#L145), [commit 146–346](../../core/commit_stage.sv#L146), [store_buffer 94–225](../../core/store_buffer.sv#L94), [load_unit](../../core/load_unit.sv#L246), [axi_shim](../../core/axi_shim.sv#L109), [ariane wrapper](../../corev_apu/src/ariane.sv#L122).

## AXI channel independence và tracking

`axi_shim` có các trạng thái `IDLE`, `WAIT_AW_READY`, `WAIT_LAST_W_READY`, `WAIT_LAST_W_READY_AW_READY`, `WAIT_AW_READY_BURST`; logic xử lý address/data acceptance lệch nhau. Không giả định AW phải được chấp nhận trước W. Read grant `rd_req_i & ar_ready`; upstream request tạo ARVALID. Response ID trả qua adapter/FIFO để chọn instruction/data transaction.

AXI ID 4-bit chỉ biểu diễn 16 mã. WT adapter dựng read ID theo arbiter index, có bits phục vụ exclusive/atomic; `MemTidWidth=2` tạo 4 slot **vì** `DCACHE_MAX_TX=2**MemTidWidth` thật sự được dùng khai báo `tx_stat`. Khác biệt này được xác lập từ [build_config](../../core/include/build_config_pkg.sv#L173) và [WT buffer](../../core/cache_subsystem/wt_dcache_wbuffer.sv#L169), không suy từ protocol ID width.

### FND-AXI-01 — Ranh giới truyền lỗi bị thu hẹp

**Support:** SUPPORTED ở source boundary; system-level exception behavior chưa được mô phỏng.  
**Scope/evidence:** WT → `wt_axi_adapter.i_axi_shim` tại [adapter](../../core/cache_subsystem/wt_axi_adapter.sv#L738); `axi_shim` chỉ xuất `rd_exokay_o`/`wr_exokay_o` bằng so sánh response với EXOKAY tại [109](../../core/axi_shim.sv#L109) và [267](../../core/axi_shim.sv#L267). Không có output mang nguyên response code hay riêng SLVERR/DECERR. [RTL:ESTABLISHED]  
**Hệ quả:** Không được hứa “bus DECERR chắc chắn biến thành precise load/store access fault” trên path này. Cần yêu cầu hệ thống, trace return path và directed error injection trước integration (OQ-04). Không kết luận mọi cache/config cùng hành vi.

## Assumption–guarantee

- **ASM-01:** Clock chạy, reset assert/release hợp lệ; request/control không X tại sampling. Assumption cho source reasoning, chưa có owner waiver; [OQ-03](13_open_questions.md).
- **ASM-02:** Producer giữ payload/metadata cần thiết khi stalled và chỉ enqueue/commit theo guards. Buffer có assertions overflow/underflow/commit-versus-flush, nhưng chưa chạy. Vi phạm có thể corrupt queue; [OQ-03](13_open_questions.md).
- **ASM-03:** Memory service trả đúng transaction, không mất response; nếu muốn tiến triển phải có downstream eventually-ready/response. Chưa có bound cycle; [OQ-06](13_open_questions.md).
- **ASM-04:** IRQ ngoài core được giữ đủ lâu/đồng bộ theo integration contract; comment “async” không tự cung cấp CDC safety. [OQ-05](13_open_questions.md).
- **ASM-05:** Firmware không phụ thuộc non-idempotent-load guard mặc định khi region lengths bằng 0; cần platform PMA quyết định. Đây là điều kiện cần review, chưa được chấp thuận; [OQ-07](13_open_questions.md).

## Minh họa backpressure (dự đoán, chưa waveform)

| Cạnh | VALID | READY | Payload | Sự kiện |
|---|---:|---:|---|---|
| t0 | 1 | 0 | A | Chưa transfer, producer giữ A |
| t1 | 1 | 0 | A | Chưa transfer |
| t2 | 1 | 1 | A | Accept A |
| t3 | 1 | 1 | B | Accept B nếu có transaction kế tiếp |

Đây là ví dụ contract từng AXI channel dưới ASM-02; không áp thời gian cố định cho toàn bộ load/store hoặc pulse `valid_i` nội bộ.
