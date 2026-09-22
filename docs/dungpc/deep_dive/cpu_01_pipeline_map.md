# CPU 01 — Pipeline và occupancy

CFG-01 có 1 issue port, 2 commit ports. Stage names dưới đây là ranh giới state/handshake thực, không áp một pipeline 5 tầng cứng cho cache miss/PTW/multicycle. [Build config](../../../core/include/build_config_pkg.sv#L55), [core](../../../core/cva6.sv#L705).

| Slot/stage | Entry và payload | Register/advance | Stall/kill |
|---|---|---|---|
| PC + fetch | `npc_q`, I-cache req/valid, prediction | `npc_d` trong `npc_select`; [flop](../../../core/frontend/frontend.sv#L421) | queue full, I-cache not ready; `kill_s1/s2`, redirect/flush. |
| Instr queue + ID | instruction/PC/exception/prediction | fetch valid/ready → `issue_n`; `issue_q<=issue_n` [ID](../../../core/id_stage.sv#L442) | issue không ack hoặc macro stall giữ valid; flush hạ `issue_n.valid`. |
| Issue/operand | decoded op, `trans_id`, GPR/FPR operands | scoreboard issue ack tạo issued slot; FU `*_valid_n→*_valid_q` [issue](../../../core/issue_read_operands.sv#L737) | RAW, structural busy, global stall; flush hạ FU valid. |
| Execute/writeback | ALU/branch/mult/FPU/LSU | FU valid/result/ex/ID → `wt_valid` [ex_stage](../../../core/ex_stage.sv) | FU riêng có latency/ready; load chờ MMU/cache response. |
| Scoreboard | `mem_q[].issued`, `.sbe.valid/result/ex`; issue/commit pointers | issue cấp; writeback marks valid; ack giải phóng; [flop](../../../core/scoreboard.sv#L304) | full chặn issue; head chưa valid chặn commit; flush clear issued/valid. |
| Commit | head `commit_instr[0]`, có thể head+1 | combinational `commit_ack/we/commit_lsu/commit_csr`; scoreboard pointer tiến [commit](../../../core/commit_stage.sv#L145) | halt, exception, store queue full, CSR error, AMO/fence pending. |

## Occupancy equations theo RTL

ID single issue: `issue_n=issue_q`; ack xoá valid; nếu slot sau ack trống và fetch valid thì nhận payload mới; flush cuối block đặt valid=0. [ID](../../../core/id_stage.sv#L442). FU dispatch: tất cả `*_valid_n=0` mặc định; valid+ack+`!ex.valid` chọn FU, flush cuối block clear; flop nhận next values. [Issue](../../../core/issue_read_operands.sv#L737). Scoreboard: `mem_n=mem_q`; issue ack ghi issued=1, writeback theo ID ghi `.valid/result/ex`; commit ack clear; flush cuối block clear mọi issued/valid/ex.valid. [Scoreboard](../../../core/scoreboard.sv#L162), [flush](../../../core/scoreboard.sv#L251).

Head-of-line blocking là hệ quả trực tiếp: commit nhìn `mem_q[commit_pointer_q]`, nên entry trẻ đã writeback vẫn chờ head chưa valid. [Scoreboard commit ports](../../../core/scoreboard.sv#L135). Port 1 chỉ ack sau port 0 và chỉ một số FU, chi tiết [cpu_07](cpu_07_retirement_model.md). Mẫu cycle có điều kiện và marker ở [04](04_dominant_flow.md); chưa có waveform đo chính xác occupancy mỗi cycle.
