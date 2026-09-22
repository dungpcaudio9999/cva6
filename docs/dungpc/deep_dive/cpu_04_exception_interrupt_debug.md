# CPU 04 — Exception, interrupt, debug và PC redirect

## Detection → acceptance

Synchronous fault có thể xuất phát từ fetch, decode, branch, LSU/MMU hoặc CSR. Entry mang `ex` qua scoreboard; commit chọn exception của head và ưu tiên exception đã phát sinh sớm hơn CSR exception. [Scoreboard writeback](../../../core/scoreboard.sv#L195), [commit exception](../../../core/commit_stage.sv#L379). IRQ pending đến CSR (`mip` từ external/software/timer), decoder chọn cause từ enabled pending với global/delegation/privilege, rồi exception metadata cũng đi tới head. [CSR pending](../../../core/csr_regfile.sv#L2079), [decoder IRQ](../../../core/decoder.sv#L1907). **Pending** có thể tồn tại nhiều cycle; chỉ khi trap được chấp nhận mới cập nhật EPC/cause/status và đổi PC. [CSR trap](../../../core/csr_regfile.sv#L2094).

| Event pair/source | Priority hoặc điều kiện RTL thấy được | Lưu ý |
|---|---|---|
| Reset vs all | Async `!rst_ni` reset state flops; `npc_rst_load_q` chọn boot address khi release. [Frontend](../../../core/frontend/frontend.sv#L421) | Reset-domain của AXI/wrapper chưa chứng minh. |
| Debug request vs decoded interrupt | Debug cause được gán cuối decoder block [decoder](../../../core/decoder.sv#L1995) | Trên đường này debug ghi đè `ex`; acceptance còn tùy debug mode, head và CSR. |
| Existing head exception vs CSR exception | `commit_instr[0].ex.valid` ghi đè `csr_exception_i` [commit](../../../core/commit_stage.sv#L405) | Faulting instruction không normal retire. |
| M external/software/timer | Decoder kiểm timer, software rồi external; assignment sau có ưu tiên cao hơn [decoder](../../../core/decoder.sv#L1948) | S delegated và privilege rules phải xét riêng; không lập một thứ tự toàn cục. |
| Branch vs eret/trap/commit flush/debug PC | Trong frontend `npc_select` assignment sau thắng: branch < eret < trap < commit PC < debug. [Frontend](../../../core/frontend/frontend.sv#L386) | Đây là mux priority; cần kiểm mutual exclusion và state capture đồng cycle. |

Controller mispredict flush IF/unissued; exception/eret/debug flush IF, unissued, ID, EX và predictor. [Controller](../../../core/controller.sv#L112), [exception flush](../../../core/controller.sv#L236). CSR xử lý delegation M/S, ghi EPC/cause/status, trap vector; debug path DPC/DCSR/mode riêng. [CSR trap](../../../core/csr_regfile.sv#L2094), [debug](../../../core/csr_regfile.sv#L2249). `MRET/SRET` phải trả privilege và PC theo CSR, không chỉ `npc_d=epc_i`.

## Trace thử bắt buộc

1. Instruction access fault: IF exception metadata → issue/scoreboard → head exception → CSR EPC/cause → controller flush → first handler fetch; không retire instruction lỗi.
2. IRQ trong load stall: pending level set, head load hoàn tất hoặc fault, sau đó trap tại acceptance point; kiểm EPC của instruction đúng và store cũ đã commit.
3. Debug+IRQ: cause/DPC, pending IRQ sau debug exit, `set_debug_pc_i` và `eret_i` tương tác.

Waveform cần PC fetch/retire, `ex.valid/cause/tval`, `commit_ack`, `mepc/sepc`, `mcause/scause`, `mstatus`, privilege, debug mode/DPC, flush signals. Chưa có waveform; các pair priority còn [OQ-05](09_open_questions.md).
