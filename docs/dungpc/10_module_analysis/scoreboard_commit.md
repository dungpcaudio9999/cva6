# Scoreboard và commit

## Contract và state

Nguồn [scoreboard.sv](../../../core/scoreboard.sv#L93), [commit_stage.sv](../../../core/commit_stage.sv#L143). Scope source CFG-01: 8 slots, issue 1, commit 2, WB ports 5; FLOW-01/05.

Mỗi entry giữ issued/cancelled, register class flag và sbe chứa PC, FU/op, result, exception. `issued=1` nghĩa đã cấp slot; `sbe.valid=1` nghĩa có thể đưa kết quả tới commit, không phải cùng một trạng thái. Issue pointer 3 bits quay vòng modulo 8; commit pointers chọn các entry theo thứ tự.

Allocation guard: `decoded_instr_valid_i && decoded_instr_ack_o && !flush_unissued_instr_i`. `issue_full[0]` lấy reduction các issued bits của cả even/odd partitions; decode ack bị mask bởi full. ID cấp bằng issue pointer, không dùng AXI ID.

## Priority và phương trình

Combinational `issue_fifo` cập nhật lần lượt allocation → FU NONE completion → writeback → optional cancel → commit clears → full flush. Vì vậy full flush thắng valid/issued updates; commit clears thắng WB ready bit cho slot đang retirement. Nếu không flush, pointer issue cộng số allocation, pointer commit cộng số ack; full flush reset pointers về base/offsets.

Writeback chỉ nhận nếu `wt_valid && mem_q[id].issued`; lưu result/ex ở đúng ID. Không đưa một completion trở thành architectural GPR write ngay. Port 1 commit yêu cầu port 0 ack, valid instruction, không halt/CSR đầu/AMO đầu/single-step/flush condition, và FU port 1 thuộc ALU/LOAD/CTRL_FLOW/MULT/FPU/FPU_VEC. STORE/CSR không được retire qua port 1 theo guard đã đọc.

## FND-PIPE-01

**Claim:** single issue kết hợp dual commit trong CFG-01 là cấu hình được source mô tả; không phải mâu thuẫn. **Support:** SUPPORTED. **Evidence:** build_config NrIssuePorts/NrCommitPorts và commit guards [317](../../../core/commit_stage.sv#L317). [RTL:ESTABLISHED] **Freshness:** CURRENT, phụ thuộc SuperscalarEn, NrCommitPorts, scoreboard layout, commit logic.

## Invariants và corner cases

- **INV-SB-01 (safety):** Trong reset epoch, commit ack chỉ khi corresponding commit output valid. RTL có SVA cho port 0/1 cuối scoreboard; NOT-RUN, trigger coverage chưa có. Vi phạm làm retire dữ liệu chưa hoàn thành.
- **INV-SB-02 (order):** Port 1 ack ⇒ port 0 ack; commit sequence tiến theo pointer. Source guard hỗ trợ mệnh đề; cần assertion/witness với hai ready entries và exceptions trên từng port.
- **INV-SB-03 (accounting):** Không flush, số issued entry sau edge = trước edge + accepted allocations − commit acks, dưới ASM-02 và không double allocation/alias. Flush bắt đầu epoch/cancel mọi outstanding scoreboard slots; equation phải thêm cancelled nếu đếm xuyên flush.
- **INV-SB-04 (ownership):** Response sau flush không được ghi kết quả vào ID đã tái cấp cho instruction khác. Source issued guard chỉ là một phần; phải kiểm producer load/FU cancellation và ID reuse; OQ-03.

Boundary 8→0 pointer wrap, full+commit đồng thời, WB+commit, flush+WB, exception port 0/1 cần directed scenario. Parameter assertion yêu cầu `NR_SB_ENTRIES == 2**TRANS_ID_BITS`; không assume depth bất kỳ đều legal. No frequency claim từ 3-bit pointer hay 8-entry capacity.

**Change impact:** đổi scoreboard depth kéo theo ID widths của LSU/FU/CVXIF/RVFI, forwarding và pointer layout. Đổi commit width ảnh hưởng register-file write ports, CSR/exception ordering và reference-model retirement packets. Regression phải bao gồm wrap/full, long-latency older instruction và simultaneous completion.
