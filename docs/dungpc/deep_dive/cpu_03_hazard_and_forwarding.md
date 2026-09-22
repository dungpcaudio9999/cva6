# CPU 03 — Hazard, forwarding và stall

## RAW path

Scoreboard cung cấp `still_issued`, entry result/valid và các writeback port kèm `trans_id`. [Scoreboard forwarding](../../../core/scoreboard.sv#L287). Operand read chọn producer index từ hazard comparison, lấy result đã lưu hoặc ưu tiên writeback cùng cycle; result chỉ forward nếu entry valid và không exception. [Forward values](../../../core/issue_read_operands.sv#L536). `rs1/rs2/rs3` có RAW mà result chưa valid thì `stall_raw` bật; đã valid thì `forward_rs*` chọn result thay regfile. CSR producer bị loại khỏi thông thường `rs*_valid` để giữ serialization, ngoại lệ SFENCE.VMA. [Availability](../../../core/issue_read_operands.sv#L549), [operand mux](../../../core/issue_read_operands.sv#L680).

| Producer → consumer | Detection/decision | Release / flush |
|---|---|---|
| ALU writeback → next ALU | RAW comparator chọn scoreboard slot; `fwd_i.wb` có thể override stored result [issue](../../../core/issue_read_operands.sv#L536) | valid result cho forward; flush clear issue/FU valid, scoreboard issued. |
| Load outstanding → dependent ALU | load slot chưa `.valid`, `stall_rs*`/`stall_raw` [issue](../../../core/issue_read_operands.sv#L585) | `data_rvalid` chưa flushed → scoreboard writeback; dependent nhận bypass. |
| CSR producer → GPR consumer | `rs*_is_not_csr` chặn forward thông thường [issue](../../../core/issue_read_operands.sv#L549) | CSR commit/serialization rồi regfile-visible value. |
| Mult/div/FPU → dependent | producer result chưa valid nên RAW stall; FU structural hazard còn có ở [structural_hazards](../../../core/issue_read_operands.sv#L330) | FU writeback hoặc flush/reset. |
| Store queue → load cùng offset | `[11:3]` compare với speculative/committed entries [store buffer](../../../core/store_buffer.sv#L237) | load chờ conflict drain; chưa thấy chứng cứ full PA store-to-load forwarding trong path này. |

Với CFG-01, dual-issue lane 1/ALU same-cycle bypass không active vì `SuperscalarEn=0`. [Config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L89), [dual issue clause](../../../core/issue_read_operands.sv#L633). `stall_issue_o=stall_raw[0]` chỉ là một chỉ dấu; structural hazard có thể còn ngăn ack trong `issue_scoreboard`. [Issue ack](../../../core/issue_read_operands.sv#L862).

## Trace kiểm chứng RAW

Cho `ADD x5,x1,x2` rồi `ADD x6,x5,x3`; đánh dấu slot producer, `idx_hzd_rs1`, `fwd_res_valid`, `forward_rs1`, `fu_data_n.operand_a`, `issue_ack`, và commit order. Lặp với `LW x5,...` response delay để buộc stall và response sau flush để chứng minh không forward stale. [Operand select](../../../core/issue_read_operands.sv#L704), [load flushed](../../../core/load_unit.sv#L492).
