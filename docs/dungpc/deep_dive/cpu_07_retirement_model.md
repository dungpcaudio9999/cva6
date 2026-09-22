# CPU 07 — Retirement và side-effect proof

**Logical retirement:** một scoreboard head entry hợp lệ, không bị halt/drop/exception và class-specific prerequisites xong thì `commit_ack` giải phóng slot; architectural write có gate riêng. [Scoreboard head](../../../core/scoreboard.sv#L135), [commit defaults/conditions](../../../core/commit_stage.sv#L145), [clear slot](../../../core/scoreboard.sv#L238). `writeback valid` chỉ là FU completion, không phải retire. Entry bị `commit_drop` có thể ack để loại khỏi scoreboard nhưng không tạo normal architectural effect; do đó checker cần phân biệt `ack` và retired instruction semantically.

| Side effect | Gate theo RTL | Ngoại lệ / nghĩa vụ |
|---|---|---|
| GPR/FPR write | head valid, no halt/ex/drop, destination class; port 1 có điều kiện [commit](../../../core/commit_stage.sv#L169) | `rd=x0` cần regfile gate; CSR/AMO thay data/ack riêng. |
| CSR write/readback | head `fu=CSR`, no drop, `!csr_exception_i.valid`; `commit_csr_o` [commit](../../../core/commit_stage.sv#L217) | CSR exception xoá ack/GPR write; trap hardware update ở CSR path riêng. |
| FPU `fflags` | FPU/FPU_VEC retired không drop; hai port OR flags [commit](../../../core/commit_stage.sv#L204) | Phải check không cộng flags của killed/exception instruction. |
| Store ownership | head STORE, committed queue ready, `commit_lsu_o`; nếu full thì ack=0 [commit](../../../core/commit_stage.sv#L194) | AXI write hoàn tất sau retire; committed queue không bị normal flush. |
| AMO | `amo_resp_i.ack` làm commit ack, GPR result và flush [commit](../../../core/commit_stage.sv#L303) | Atomicity phải xác minh tại cache/bus adapter. |
| Fence/TLB maintenance | no pending stores, có thể đợi shared TLB flush idle; phát controller flush [commit](../../../core/commit_stage.sv#L235) | Không có GPR effect nhưng vẫn retire/order effect. |
| Trap/privilege | head exception/IRQ accepted → CSR trap state, PC redirect [commit](../../../core/commit_stage.sv#L379), [CSR](../../../core/csr_regfile.sv#L2094) | Lệnh faulting không normal retire; EPC/cause đúng và younger killed. |

Cổng 1 cần `commit_ack[0]`, entry 1 valid, không halt, cổng 0 không CSR/AMO, không single step/flush D-cache; entry 1 không exception và FU thuộc `ALU, LOAD, CTRL_FLOW, MULT, FPU, FPU_VEC`. [Port 1 gate](../../../core/commit_stage.sv#L317). Vì issue 1/cycle, một cycle retire 2 có thể drain backlog; không suy sustained IPC 2 từ đó.

## Precise exception proof obligations

Theo order scoreboard: older entries có side effect đúng; head faulting entry không `we_gpr/fpr`, `commit_csr` hay `commit_lsu`; younger entries/requests bị flush hoặc response suppressed. Các mảnh RTL: [commit gates](../../../core/commit_stage.sv#L169), [scoreboard flush](../../../core/scoreboard.sv#L251), [load flushed guard](../../../core/load_unit.sv#L492), [store speculative flush](../../../core/store_buffer.sv#L122). Chưa có formal/waveform xuyên modules chứng minh mọi tổ hợp concurrent event; [08](08_verification_points.md) là kế hoạch discharge.
