# CPU 09 — Bốn worked traces để gắn waveform

Các mốc `T0…` là **sự kiện logic**, không phải cycle liền nhau hay waveform đã chạy. Khi mô phỏng, đánh số cycle thực cho mọi hàng, kể cả idle/stall, và ghi marker cùng `trans_id`. CFG-01, no reset, no unrelated older trap trừ khi nêu rõ. Các trace dùng checker ở [08](08_verification_points.md).

## T1 — `ADD x5,x1,x2`; dependent `ADD x6,x5,x3`

**Yêu cầu:** x5 nhận phép cộng modulo XLEN; dependent đọc giá trị x5 mới; commit theo thứ tự. **Entry/decode:** instruction fetch, opcode integer → `fu=ALU`, `op=ADD`, rs1/rs2/rd; issue ack cấp slot ID. [Decoder](../../../core/decoder.sv#L175), [scoreboard issue](../../../core/scoreboard.sv#L149). **Path:** regfile/forward mux → ALU → writeback `wt_valid/trans_id/result` → scoreboard `.valid` → head `commit_ack/we_gpr`. [Operand mux](../../../core/issue_read_operands.sv#L680), [scoreboard writeback](../../../core/scoreboard.sv#L195), [commit](../../../core/commit_stage.sv#L169).

| Mốc | Producer x5 | Consumer x6 | Stall/forward | Kiến trúc |
|---|---|---|---|---|
| T0 fetch/ID | decoded | chờ queue | none | chưa đổi |
| T1 issue | slot P issued | ID/queue | P chưa valid | chưa đổi |
| T2 issue thử | FU/result có thể chưa sẵn | RAW tới x5 | `stall_raw` nếu P chưa valid | chưa đổi |
| T3 writeback | P result valid | issue được ack | `forward_rs1` lấy WB hoặc stored result | chưa đổi |
| T4 commit | P head ack | Q có thể đang FU/scoreboard | order P trước Q | x5 mới; x6 chỉ khi Q ack |

**Failure/recovery:** fault/flush loại P/Q theo tuổi; killed Q không ghi x6. **Waveform markers cần:** `issue_instr_valid/ack`, `trans_id`, `idx_hzd_rs1`, `fwd_res_valid`, `stall_raw`, `forward_rs1`, `fu_data_n.operand_a`, `wt_valid`, `commit_ack`, `we_gpr`. **Assertions/coverage:** RAW stall iff result chưa sẵn trong điều kiện không stall khác; forward chọn đúng P; cover same-cycle WB và stored-scoreboard bypass. [Hazard logic](../../../core/issue_read_operands.sv#L536).

## T2 — `LW x5,0(x1)` rồi `ADD x6,x5,x3`

**Yêu cầu:** load lấy đúng 32-bit word và sign-extend lên XLEN; dependent không dùng stale x5. **Entry:** `LOAD` vào LSU; address/alignment, MMU/PMP, D-cache request. **Stored state:** load FSM, `ldbuf_valid/flushed`, VA/op/scoreboard ID, PTW/TLB/cache state, scoreboard slot. [LSU](../../../core/load_store_unit.sv#L733), [load buffer](../../../core/load_unit.sv#L104). **Completion:** response `data_rvalid` với `data_rid` đúng và `!flushed` → scoreboard writeback → GPR commit. [Load response](../../../core/load_unit.sv#L473).

| Mốc | Load | Dependent | Memory | Kiến trúc |
|---|---|---|---|---|
| T0 issue | slot P issued | chờ | translation bắt đầu | chưa đổi |
| T1 request | đang đợi | RAW stall | req có thể chờ gnt | chưa đổi |
| T2 grant | load metadata vào slot L | vẫn stall | L outstanding | chưa đổi |
| T3 response | L chưa flushed → writeback P | bypass có thể release | `data_rvalid/data_rid` | chưa đổi |
| T4 retire | P head ack | Q về sau | response đã xử lý | x5, rồi x6 cập nhật theo order |

**Failure/recovery:** misalign/page/PMP/data error → P exception, không GPR write; flush ở T2 đồng cycle grant phải đặt `ldbuf_flushed`, response vẫn drain và không normal writeback. [Flush priority](../../../core/load_unit.sv#L160). **Markers:** VA/PA, permission, `data_req/gnt/rvalid/rid/error`, ldbuf slot/flags, scoreboard ID, stall/forward, commit. **Coverage:** hit/miss, delay 0/n cycles, flush×grant, flush×response, ID reuse, exception cause. Không khẳng định load response ở T3 sau đúng một cycle.

## T3 — `BEQ x1,x2,target` dự đoán sai với younger store

**Yêu cầu:** PC chọn resolved target; younger store không thành architectural memory effect. **Entry:** frontend prediction/BHT, fetch younger; branch issue vào branch unit. [Frontend prediction](../../../core/frontend/frontend.sv#L223), [branch unit](../../../core/branch_unit.sv). **Path:** resolved branch `valid/is_mispredict/target_address` → controller IF/unissued flush → frontend NPC target; branch scoreboard entry vẫn retire đúng thứ tự. [Frontend NPC](../../../core/frontend/frontend.sv#L386), [controller](../../../core/controller.sv#L112). **Stored state:** queue/ID valid, scoreboard issued, predictor tables, speculative store queue nếu younger đã đến LSU.

| Mốc | Branch | Younger | Control | Kiến trúc |
|---|---|---|---|---|
| T0 prediction | fetch branch | fetch predicted path | predicted NPC | chưa đổi |
| T1 issue/resolve | FU branch valid | queue/ID có thể chứa younger | compare target/prediction | chưa đổi |
| T2 mispredict | result vào scoreboard | unissued bị flush; speculative store phải bị kill trước commit | `is_mispredict`, redirect target | chưa đổi |
| T3 refetch | chờ/đã commit | instruction ở target | I-cache kill/refetch | chỉ older + branch effect |

**Failure/recovery:** target instruction access fault đi exception path; redirect không được hủy committed older store. **Markers:** predicted/resolved PC, queue/ID/FU valid, `flush_if/unissued/id/ex`, speculative/committed store counts, `commit_lsu`, RVFI order. **Assertion:** không younger store chuyển committed queue; first post-redirect retire thuộc target path. Mispredict path chỉ flush unissued theo [controller](../../../core/controller.sv#L112), nên phải chứng minh tuổi của instruction đã issue trong trường hợp cụ thể, không giả định mọi EX bị xoá.

## T4 — Instruction page fault → trap handler

**Yêu cầu:** lệnh faulting không normal retire, older instructions hoàn tất, `mepc/scause` hoặc `mepc/mcause` và trap PC đúng theo delegation/privilege; younger không side effect. **Entry:** I-cache/MMU phát exception metadata cho fetch; decode/issue giữ exception để đưa qua scoreboard; commit chọn head exception; CSR ghi trap state; controller flush; frontend lấy vector. [MMU fetch](../../../core/cva6_mmu/cva6_mmu.sv#L375), [commit exception](../../../core/commit_stage.sv#L405), [CSR trap](../../../core/csr_regfile.sv#L2094).

| Mốc | Faulting instruction | Older/younger | Control | Kiến trúc |
|---|---|---|---|---|
| T0 fetch | fault metadata valid | older có thể pending | IF response fault | chưa đổi |
| T1 issue/scoreboard | slot P có `ex.valid` | older phải về head trước P | FU không được bật cho P | chưa đổi |
| T2 head | P exception được chọn | older đã xử lý; younger killed | CSR trap, flush | EPC/cause/status cập nhật |
| T3 handler fetch | không normal retire | new epoch tại trap vector | NPC/vector | first handler instruction |

**Failure/recovery:** nếu IRQ/debug đồng thời, phải dùng event matrix của [cpu_04](cpu_04_exception_interrupt_debug.md); chưa chứng nhận priority cuối bằng waveform. **Markers:** `fetch_ex`, decoded `ex`, scoreboard head, `commit_ack/we_gpr/commit_csr/commit_lsu`, privilege/delegation, EPC/cause/tval, `ex_valid`, flushes, trap vector, first handler fetch. **Assertions/coverage:** no normal write của P/younger; EPC=PC faulting theo chosen delegation; cover I-TLB miss, PMP deny, fetch AXI error và fault during stall. [Controller](../../../core/controller.sv#L236).
