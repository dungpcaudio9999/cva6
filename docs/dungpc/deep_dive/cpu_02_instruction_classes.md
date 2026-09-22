# CPU 02 — Instruction semantics và decode trace

`decoder` mặc định `fu=NONE`, `op=ADD`, `rd=0`, `use_pc=0`; chỉ nhánh opcode hợp lệ đổi control. Illegal/privilege exception đi trong `instruction_o.ex`; FU issue chỉ bật khi instruction valid+ack và chưa có exception. [Defaults](../../../core/decoder.sv#L175), [issue gate](../../../core/issue_read_operands.sv#L749). Bảng là map class theo CFG-01, **không phải** báo cáo mọi opcode đã pass ISA test.

| Class | Decode → unit → retirement / trap |
|---|---|
| Integer ALU, B/ZKN/ZiCond | GPR/immediate → ALU/AES/mult tùy op → GPR tại commit; illegal encoding → exception. [Decoder](../../../core/decoder.sv), [issue FU](../../../core/issue_read_operands.sv#L749), [commit](../../../core/commit_stage.sv#L184). |
| Conditional branch | 2 operands → branch unit resolve; PC sequential/target; không GPR trừ link jump; alignment/fetch fault theo exception path. [Prediction](../../../core/frontend/frontend.sv#L223), [branch unit](../../../core/branch_unit.sv). |
| JAL/JALR | PC + immediate hoặc `rs1+imm` → branch unit; link `rd` khi retired; mispredict sửa frontend. [Branch unit](../../../core/branch_unit.sv), [NPC](../../../core/frontend/frontend.sv#L386). |
| Load | base+imm → LSU/MMU/cache → sign/zero extended result → GPR/FPR commit; misalign/page/access/data error chặn normal write. [LSU](../../../core/load_store_unit.sv#L648), [load](../../../core/load_unit.sv#L477). |
| Store | base+imm/data → LSU speculative queue → commit chuyển committed queue; fault không chuyển ownership. [Store unit](../../../core/store_unit.sv#L155), [buffer](../../../core/store_buffer.sv#L87). |
| CSR/system | CSR decode và privilege check → CSR đọc/ghi tại commit; `MRET/SRET/WFI` đổi control/privilege theo CSR. [Decoder system](../../../core/decoder.sv#L207), [commit CSR](../../../core/commit_stage.sv#L217), [CSR](../../../core/csr_regfile.sv). |
| MUL/DIV | GPR operands → mult/div unit; variable latency có scoreboard giữ thứ tự; GPR tại commit. [Mult](../../../core/mult.sv), [divider](../../../core/serdiv.sv). |
| AMO | A enabled; LSU/AMO path, head commit chờ `amo_resp_i.ack`, flush pipeline. [Commit](../../../core/commit_stage.sv#L303), [AMO buffer](../../../core/amo_buffer.sv). |
| Compressed/Zcb | frontend/ID decompress → normal decoded op; PC length 2 hoặc 4; Zcmp/Zcmt tắt CFG-01. [Compressed decoder](../../../core/compressed_decoder.sv), [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L20). |
| F/D | FPR operand/result, fflags tại commit; FS=Off gây illegal path; no vector in CFG-01. [FPU](../../../core/fpu_wrap.sv), [fflags](../../../core/commit_stage.sv#L204). |
| FENCE/FENCE.I/SFENCE.VMA | serialized ở head; chờ store drain, controller flush cache/TLB/front-end theo loại. [Commit](../../../core/commit_stage.sv#L235), [controller](../../../core/controller.sv#L123). |

## Trace decode→control mẫu

`ADD`: raw opcode/funct → `fu=ALU`, `op=ADD`, rs1/rs2/rd → operand mux GPR hoặc forwarding → `alu_valid_q` → result/ID writeback → head `commit_ack` và `we_gpr` (regfile phải suppress x0). `LW`: `fu=LOAD` → `lsu_valid_q` → address/translation/request/response → scoreboard → commit. `BEQ`: `fu=CTRL_FLOW` → `branch_valid_q`, resolve target/mispredict → frontend redirect; branch entry retire theo thứ tự. `illegal`: `ex.valid` nên FU valid không bật; head exception đi CSR/trap, không normal side effect. [Decoder](../../../core/decoder.sv#L175), [dispatch](../../../core/issue_read_operands.sv#L737), [commit exception](../../../core/commit_stage.sv#L379).

Các class B/ZKN/Zcb có nhiều sub-op và rule riêng: cần generated instruction coverage/cross, không suy tất cả hợp lệ chỉ vì feature bit bật. [OQ-10](09_open_questions.md).
