# CPU 08 — Performance model và giới hạn suy luận

CFG-01 là single issue (`NrIssuePorts=1`) nhưng có 2 commit ports. Scoreboard 8 entries giữ nhiều lệnh đã issue/writeback, cho phép head chờ cache/FU mà lệnh trẻ có thể hoàn thành; head chưa `.valid` chặn retire. [Build config](../../../core/include/build_config_pkg.sv#L55), [scoreboard](../../../core/scoreboard.sv#L125). Một cycle có thể retire 2 entry đủ điều kiện theo [commit port 1 gate](../../../core/commit_stage.sv#L317), song tốc độ phát dài hạn của luồng thông thường bị giới hạn bởi 1 issue/cycle; không có số IPC đo được ở đây.

| Resource | CFG-01 / bottleneck khả dĩ | Không nên suy |
|---|---|---|
| Frontend prediction | RAS 2, BTB 32, BHT 128; I-cache 16 KiB/4-way [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L33) | Accuracy, mispredict penalty cố định. |
| Scoreboard | 8 slots, 3-bit slot ID; full chặn issue [scoreboard](../../../core/scoreboard.sv#L125) | 8 lệnh retirement/cycle. |
| Load buffer | 2 entries; DTLB/PTW/cache response có thể kéo dài [load](../../../core/load_unit.sv#L104) | 2-cycle load latency hoặc 2 AXI IDs. |
| Spec/committed store | 4 + 4 entries từ [ariane_pkg](../../../core/include/ariane_pkg.sv#L35) | WT write buffer depth 8 là cùng queue. |
| WT write buffer | 8 word entries, `DCACHE_MAX_TX=4` slots [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L53), [buffer](../../../core/cache_subsystem/wt_dcache_wbuffer.sv#L231) | 4 outstanding stores ở bus trong mọi traffic mix. |
| MMU/TLB | ITLB/DTLB 16 entries; miss PTW dùng D-cache [MMU](../../../core/cva6_mmu/cva6_mmu.sv#L179) | PTW 3 cycles vì Sv39 3 levels. |

`perf_counters` chọn event bằng `mhpmevent`: I/D cache miss, I/D TLB miss, load/store/branch retirement, branch mispredict, scoreboard full, fetch empty, D-cache access, issue bubbles. [Event mux](../../../core/perf_counters.sv#L85). Các class retire event dùng OR qua commit ports, nên **một event/cycle** có thể đại diện cho ít nhất một lệnh cùng class, không nhất thiết đếm 2 nếu hai cổng cùng class. [Event OR](../../../core/perf_counters.sv#L96). `minstret` trong CSR tăng theo từng `commit_ack` khi không exception và không inhibit; `mcycle` tăng theo cycle khi không inhibit. [CSR counters](../../../core/csr_regfile.sv#L1030). Cần xác nhận RVFI/retirement nghĩa của dropped entries và macro instructions khi so với `minstret`.

Kế hoạch đo: cold/warm I/D cache, DTLB/ITLB miss, RAW/load-use, branch correct/mispredict, store saturation, fence drain, AXI backpressure. Ghi cycles, instructions retired, event counter selectors và waveform cùng một build/env. Không có benchmark hoặc timing run trong phân tích này; PPA và latency bound còn [OQ-06](09_open_questions.md).
