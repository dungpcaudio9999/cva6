# Frontend và controller

Nguồn [frontend](../../../core/frontend/frontend.sv#L347), [controller](../../../core/controller.sv#L88). FLOW-01/04/05. Controller sở hữu `fence_active_q`, `fence_i_active_q`; frontend sở hữu NPC/reset-load/prediction và fetch queue state. Hai khối không phải một FIFO handshake đơn giản.

## Priority của control

Frontend khởi NPC từ boot_addr khi reset-load flag; sau đó combinational next-PC xem prediction/sequential fetch, replay, branch mispredict, eret, exception, set_pc_commit, cuối cùng debug PC. Khi guards cùng true, assignment phía sau thắng; controller có trách nhiệm không đưa set_pc_commit sai lúc exception/eret/debug bằng cách clear nó trong nhánh sau.

Controller mặc định mọi flush thấp, rồi thêm theo sự kiện:

- Mispredict: flush IF và unissued instructions, không tự flush mọi issued entry.
- FENCE: set PC từ commit và flush IF/ID/EX/unissued; D-cache flush chỉ khi DcacheFlushOnFence.
- FENCE.I: thêm I-cache flush; tùy DcacheFlushOnFenceI mà giữ fence state đợi D-cache ack.
- SFENCE.VMA: thêm TLB flush theo supervisor/virtualization configuration.
- CSR/accelerator/AMO flush: restart qua commit PC với guards.
- Exception/eret/debug: cuối block clear set_pc_commit, flush pipeline và predictor; frontend nhận trap/return/debug target.

CFG-01 có hai D-cache fence flush flags=0 nên các pending D-cache fence-state paths bị điều kiện vô hiệu; không mô tả chúng như latency thực của WT CFG-01. Vẫn phải drain WT write buffer ở commit trước phát fence event.

## Invariants và dự đoán

**INV-CTRL-01:** exception/eret/debug cùng fence không được chọn stale commit restart PC; source priority hỗ trợ `set_pc_commit_o=0` cuối controller block. Safety cần cover simultaneous triggers, không phải liveness.

**INV-CTRL-02:** FENCE.I không cho instruction stale retire sau khi fence completion/recovery được áp dụng. Đây là system property phụ thuộc stores/WB drain, I-cache invalidation/refill cancellation, frontend queue flush và scoreboard; source của controller đơn lẻ không chứng minh được. PROP-FENCE-01 NOT-RUN, OQ-03.

**INV-FE-01:** replay do fetch queue full phải giữ instruction stream không mất/duplication sau khi downstream tiếp tục. Cần PC/opcode architectural scoreboard và random stalls; không có witness.

**Quantitative:** Không có branch penalty cố định từ source này; penalty phụ thuộc resolved timing, queue occupancy, I-cache/translation state và response service. Predictor depths không phải accuracy measurement.

**Change impact:** Đổi thứ tự if/assignment có thể đổi exception/fence/debug priority mà không đổi interface. Đổi I-cache flush ack/latency ảnh hưởng halt frontend và self-modifying code. Tests cần cùng-cycle triggers, I-fill in-flight, D-store stalled, debug/interrupt trong fence; cần xác nhận thực sự kích hoạt antecedent.
