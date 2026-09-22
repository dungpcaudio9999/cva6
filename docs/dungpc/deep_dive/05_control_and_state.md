# 05 — Control path và state path

## Bốn góc nhìn

Datapath: operand mux/ALU/branch/FPU/LSU ở [issue_read_operands](../../../core/issue_read_operands.sv#L680) và [ex_stage](../../../core/ex_stage.sv). Control: decode, hazard, controller redirect/flush và commit gates ở [decoder](../../../core/decoder.sv#L175), [controller](../../../core/controller.sv#L95), [commit](../../../core/commit_stage.sv#L145). State: `npc_q`, ID issue register, FU valid registers, scoreboard entries/pointers, load/store queues, TLB/cache, CSR. Side effects: GPR/FPR write, CSR update, committed store, AXI traffic và counters. AXI request có thể bắt đầu trước retirement đối với load; store path cần tách mốc như [cpu_06](cpu_06_memory_system.md).

## Các update equation quan trọng

- Frontend: reset đặt `npc_rst_load_q=1`; cycle sau `npc_d` bắt đầu từ boot address. Trong `npc_select`, assignment về sau ghi đè assignment trước: prediction → sequential/replay → mispredict → eret → trap → commit PC+4 → debug. Đây là **priority của mux** khi signal đồng thời; controller có thể bảo đảm mutual exclusion khác và chưa được chứng minh. [Frontend](../../../core/frontend/frontend.sv#L355), [NPC flops](../../../core/frontend/frontend.sv#L421).
- ID: `issue_n` nhận decoded instruction khi handshake; `flush_i` hạ valid. `always_ff` giữ `issue_q`. [ID comb](../../../core/id_stage.sv#L442), [ID flop](../../../core/id_stage.sv#L473).
- FU dispatch: `*_valid_n` mặc định 0, chỉ lên khi issue valid+ack và không có preexisting exception; flush hạ toàn bộ valid trước khi vào `*_valid_q`. [Issue comb](../../../core/issue_read_operands.sv#L737), [FU valid flops](../../../core/issue_read_operands.sv#L802).
- Scoreboard: issue ack cấp slot; writeback theo ID làm `.valid=1`/lưu result hoặc exception; commit ack giải phóng slot; flush đặt pointer lại. [Scoreboard issue](../../../core/scoreboard.sv#L162), [writeback](../../../core/scoreboard.sv#L195), [pointers/flops](../../../core/scoreboard.sv#L238).
- Load buffer: grant cấp slot; flush ghi flushed mask **sau** allocation trong combinational block, nên flush thắng grant đồng cycle. Response chỉ tạo normal writeback nếu slot không marked flushed. [Load metadata](../../../core/load_unit.sv#L160), [response](../../../core/load_unit.sv#L477).
- Store buffer: flush xóa speculative valid/count; committed queue có flop riêng và không bị flush đó xóa. [Store speculative](../../../core/store_buffer.sv#L87), [committed](../../../core/store_buffer.sv#L161), [flops](../../../core/store_buffer.sv#L263).

## Redirect/flush scope

Mispredict kích IF + unissued flush. Trap/eret/debug kích IF, unissued, ID, EX và predictor flush. Fence/CSR flush dùng các tập signal riêng; reset tác động trực tiếp các flop async-low. [Controller](../../../core/controller.sv#L112), [trap flush](../../../core/controller.sv#L236). Không gộp các trường hợp thành một signal `kill` giả định; monitor phải dùng signal thật và kiểm từng owner state.

## Quy tắc side effect

Tại commit, default `we_gpr`, `commit_lsu`, `commit_csr` đều 0. Lệnh head cần valid và không halt; exception chặn normal ack/write (trừ drop path có ack để loại entry). Store còn cần `commit_lsu_ready_i`, CSR còn cần không có `csr_exception_i`, AMO cần `amo_resp_i.ack`; cổng 1 phụ thuộc cổng 0. [Commit](../../../core/commit_stage.sv#L145). Đây là tập điều kiện phân tán, không nên thay bằng `commit_ack` đơn thuần cho mọi side effect. [Retirement model](cpu_07_retirement_model.md).
