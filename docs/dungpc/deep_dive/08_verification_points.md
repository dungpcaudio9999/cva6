# 08 — Kế hoạch kiểm chứng

## Checker boundary

Dùng RVFI/commit làm biên so ISA reference model: PC, instruction, privilege, source/destination, trap, memory mask/data theo thứ tự retirement. Dùng internal assertions cho protocol/stall/flush/ID ownership; đừng ép latency cố định cho cache/PTW/FU. [RVFI hookup](../../../core/cva6.sv#L1824), [commit](../../../core/commit_stage.sv#L145). Trước khi dựa vào SVA có sẵn, kiểm compiler flags cuối vì không phải mọi flow bật assertions; [scoreboard SVA](../../../core/scoreboard.sv#L321), [store SVA](../../../core/store_buffer.sv#L297).

| Obligation | Stimulus | Checker / coverage |
|---|---|---|
| ALU + RAW | ADD producer rồi dependent ADD, interleave FU latency | `trans_id` đúng, forwarded operand hoặc stall; GPR chỉ ghi ở retire; cover bypass từ writeback và scoreboard. |
| Load-use | Load hit/miss, response delay và immediate dependent | Dependent không đọc stale data; cover stall release và flush cùng response. |
| Store precision | Store rồi younger trap/branch, backpressure ở committed queue/WT/AXI | Chỉ store đã commit có downstream request; younger store không xuất hiện; cover từng ownership point. |
| Redirect | Taken correct/mispredicted branch, JALR, trap, eret, debug | Retired PC chain/reference target; không younger side effect; cover redirect × stall. |
| Memory faults | ITLB/DTLB miss, PMP deny fetch/load/store, data error, misalign | Cause/EPC/tval, không normal write; cover access type × privilege × page size × permission. |
| Privilege/CSR | CSR read/write/illegal, trap delegation, MRET/SRET, satp/PMP lock | Model CSR mask/WARL/reset/priority; cover simultaneous CSR write × trap/IRQ. |
| Ordering | FENCE, FENCE.I, SFENCE.VMA, self-modifying code | Store drain, I-cache/TLB invalidation và đúng fetch/data sau fence; cover PTW outstanding. |
| Async | IRQ trong load stall/WFI, debug+IRQ, reset giữa AXI | Delivery point và pending semantics; không duplicate/lost retire hoặc stale response. |

## Assertions gắn signal thật

1. `commit_ack_o[p] -> commit_instr_i[p].valid` đã có trong [scoreboard](../../../core/scoreboard.sv#L326); bổ sung `we_gpr/we_fpr/commit_csr/commit_lsu` chỉ khi entry hợp lệ, không drop và không exception, với ngoại lệ CSR/AMO theo class.
2. Khi `flush_i` tại FU issue, `*_valid_n=0` đã thấy ở [issue combinational](../../../core/issue_read_operands.sv#L787); assert next-cycle valid cùng reset guard.
3. Khi load response `data_rvalid`, load buffer slot phải outstanding; nếu `ldbuf_flushed_q[id]`, không có normal load writeback. [Load](../../../core/load_unit.sv#L477).
4. Store buffer: `flush_i -> !commit_i`, full count -> no valid/commit đã có [assertions](../../../core/store_buffer.sv#L297); thêm kiểm flush giữ committed queue và queue count nhất quán.
5. `commit_ack[1] -> commit_ack[0]` và port 1 FU thuộc allowlist theo [commit](../../../core/commit_stage.sv#L317).

Coverage phải lưu waveform markers cho 4 trace bắt buộc ALU/load/branch/exception và 10 bài tập trong [guide](09_open_questions.md). Chưa có test run mới trong hồ sơ này, nên mọi item ở đây là **kế hoạch**, không phải pass result.
