# 04 — Luồng chính: một lệnh tới retirement

## Trace ALU `ADD x3,x1,x2`

**Intent/preconditions:** reset đã nhả, hai source GPR sẵn, không redirect/halt, queue và scoreboard còn chỗ. Instruction fetch từ `frontend.npc_q`, I-cache response vào instruction queue; ID giải nén/giải mã; issue nhận ack và cấp `trans_id`; operand mux chọn GPR hoặc bypass; ALU tạo result; writeback đặt result và `.valid` cho scoreboard slot; head commit ack và ghi GPR x3. [Frontend](../../../core/frontend/frontend.sv#L355), [ID](../../../core/id_stage.sv#L299), [decoder defaults](../../../core/decoder.sv#L175), [operand select](../../../core/issue_read_operands.sv#L680), [scoreboard](../../../core/scoreboard.sv#L162), [commit](../../../core/commit_stage.sv#L169). Completion quan sát tại `commit_ack`/GPR write hoặc RVFI retire, không tại FU writeback. Failure: I-cache fault, illegal instruction, interrupt/debug, flush hoặc stall; chỉ instruction còn sống tới head mới có side effect.

**Mô hình occupancy có điều kiện, không phải waveform:** `C0` có fetch request; `C1` là cycle bất kỳ response valid; `C2` là cycle ID/issue ack; `C3` là cycle FU writeback; `C4` là cycle head commit. Các mốc có thể trùng hoặc cách nhiều cycle, tùy cache/queue/FU/older instructions. Không được lấy C4−C0 làm latency đo được.

| Mốc sự kiện | IF/ID | Issue/FU | Scoreboard/commit | State kiến trúc |
|---|---|---|---|---|
| `C0` | fetch request | rỗng | rỗng | không đổi |
| `C1` | response vào queue | rỗng | rỗng | không đổi |
| `C2` | decode valid được ack | cấp ID | entry issued | không đổi |
| `C3` | có thể fetch lệnh khác | result writeback | entry valid; chờ head | không đổi |
| `C4` | bất kỳ | bất kỳ | head ack | x3 cập nhật |

## Trace load có dependency

Load được issue → LSU kiểm alignment/translation/PMP → request D-cache được grant và load buffer lưu ID → response `data_rvalid` hợp lệ, chưa flushed → sign/zero extension/writeback → scoreboard head commit. Lệnh trẻ dùng `rd` load phải stall khi kết quả chưa valid; sau writeback có thể bypass. [Load FSM](../../../core/load_unit.sv#L242), [flushed response guard](../../../core/load_unit.sv#L477), [operand availability](../../../core/issue_read_operands.sv#L573). Exception MMU/cache đi theo `ex`, không được ghi GPR load. Test cần cùng `trans_id` ở issue/writeback/commit và chứng minh lệnh phụ thuộc dùng đúng data.

## Trace taken branch và trap

Branch được dự đoán ở frontend; branch unit resolve, sai dự đoán kích `flush_unissued_instr` và sửa NPC. Lệnh trẻ đã fetch/decode bị hủy; lệnh già hơn vẫn có thể commit. [Prediction](../../../core/frontend/frontend.sv#L223), [NPC](../../../core/frontend/frontend.sv#L386), [controller](../../../core/controller.sv#L112). Với exception ở head, commit không phát architectural write của lệnh lỗi, CSR bắt cause/EPC và controller flush rộng; frontend chọn trap vector. [Commit](../../../core/commit_stage.sv#L379), [CSR trap](../../../core/csr_regfile.sv#L2094), [controller](../../../core/controller.sv#L236). Mốc cycle và ưu tiên nếu branch/trap cùng cycle cần waveform/formal, xem [cpu_04](cpu_04_exception_interrupt_debug.md).

## Hệ quả kiểm chứng

Gắn monitor ở fetch PC, decode valid/ack, issue `trans_id`, FU writeback, scoreboard head, `commit_ack`, GPR/CSR write và RVFI. Mỗi lệnh phải có ID/order ổn định; killed entry không được tạo retire hoặc memory/CSR write. Gắn response ID/load flushed bit để phát hiện response cũ sau redirect. [08](08_verification_points.md).
