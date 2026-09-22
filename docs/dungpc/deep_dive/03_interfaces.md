# 03 — Giao tiếp và handshake

| Ranh giới | Handshake / payload | Completion thực sự |
|---|---|---|
| Frontend ↔ I-cache | `icache_dreq_o.req`, `icache_dreq_i.ready/valid`, `kill_s1/s2`, VA; [frontend](../../../core/frontend/frontend.sv#L310) | `valid` tạo instruction cho queue; fetch không phải retire. |
| Decode ↔ issue | fetch entry valid/ready; issue valid/ack; [ID](../../../core/id_stage.sv#L381), [scoreboard](../../../core/scoreboard.sv#L149) | Ack cấp transaction ID, FU chưa xong. |
| FU ↔ scoreboard | writeback `wt_valid`, `trans_id`, result/exception; [scoreboard](../../../core/scoreboard.sv#L195) | Entry `.valid` đủ điều kiện xét commit, vẫn phải chờ head. |
| Commit ↔ regfile/CSR/LSU | `commit_ack`, `we_gpr/fpr`, `commit_csr`, `commit_lsu`; [commit](../../../core/commit_stage.sv#L145) | Architectural retirement/side effect theo class. |
| Load/store ↔ D-cache | `data_req/data_gnt`, `data_rvalid`, `data_error`, ID; [load](../../../core/load_unit.sv#L210), [store buffer](../../../core/store_buffer.sv#L140) | Grant chỉ nhận request; load cần response; store thường pop committed queue ở grant. |
| Cache ↔ AXI | WT adapter/shim AR/R, AW/W/B; [WT subsystem](../../../core/cache_subsystem/wt_cache_subsystem.sv), [axi_shim](../../../core/axi_shim.sv) | B là phản hồi write bus, không đồng nhất với store retire. |
| Environment ↔ core | boot address, hart ID, IRQ, debug request, AXI, reset; [cva6 ports](../../../core/cva6.sv#L18) | Wrapper cấp nguồn và định tuyến, không phải core tự quyết định toàn bộ map. |

`ready` và `valid` phải quan sát cùng cạnh clock theo giao thức riêng của interface; không suy acceptance từ một signal đơn lẻ. `kill_s1/s2` là hủy đường I-cache theo stage, không phải xóa request AXI đã được downstream chấp nhận. `data_id` của load là index load buffer; scoreboard `trans_id` là slot lệnh; AXI ID là namespace khác. [Load metadata](../../../core/load_unit.sv#L124), [scoreboard ID](../../../core/scoreboard.sv#L155), [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L28).

## Kết nối integration cần chụp khi mô phỏng

Ghi `boot_addr_i`, IRQ input, `debug_req_i`, `rst_ni`, AXI channel readiness, reset generator và memory model được chọn. Harness dùng ROM/behavioral memory, nên tính sẵn sàng của một peripheral thực tế không suy từ core RTL. [Testharness](../../../corev_apu/tb/ariane_testharness.sv), [APU wrapper](../../../corev_apu/src/ariane.sv).
