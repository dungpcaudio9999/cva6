# CPU 06 — Load/store, cache, MMU và ordering

## Load transaction

1. Issue `LOAD` với base+offset; LSU tạo VA/byte enable, kiểm misalignment, translation/PMP. [LSU decode](../../../core/load_store_unit.sv#L648), [alignment](../../../core/load_store_unit.sv#L733), [MMU](../../../core/cva6_mmu/cva6_mmu.sv#L525).
2. DTLB hit cho PA; miss kích PTW, có `WAIT_GRANT/WAIT_RVALID/PTE_LOOKUP` và error path, không quy đổi “3-level walk” thành 3 cycles. [PTW](../../../core/cva6_mmu/cva6_ptw.sv#L301).
3. D-cache grant cấp load buffer entry: `ldbuf_w=data_req & data_gnt`, lưu scoreboard `trans_id`, VA/op và request ID. [Load buffer](../../../core/load_unit.sv#L104), [grant](../../../core/load_unit.sv#L467).
4. `data_rvalid` dùng `data_rid` tìm metadata; nếu không flushed/killed thì tạo result hoặc `HARDWARE_ERROR` exception, writeback vào scoreboard; chỉ head commit mới ghi GPR. [Load response](../../../core/load_unit.sv#L473), [commit](../../../core/commit_stage.sv#L169).

FSM load có `IDLE`, translation, request, abort/flush/wait states; lưu cả state_q và ldbuf. Grant không chứng minh load đã xong; flush không được xóa nghĩa vụ nhận response đã accept. [Load FSM](../../../core/load_unit.sv#L242), [flushed bits](../../../core/load_unit.sv#L160).

## Store transaction và mốc irreversible

Store unit tính address/data rồi đẩy speculative queue khi hợp lệ; exception/flush trước commit phải ngăn normal store. [Store unit](../../../core/store_unit.sv#L155), [spec queue](../../../core/store_buffer.sv#L87). Head commit chỉ bật `commit_lsu_o` khi committed queue ready; `commit_i` chuyển entry speculative→committed. Flush xóa speculative queue, giữ committed queue. [Commit](../../../core/commit_stage.sv#L194), [store transfer](../../../core/store_buffer.sv#L212). **Mốc architectural ownership** là transfer khi commit; sau đó store buffer phát D-cache request. Normal store được pop khỏi committed queue khi cache `data_gnt`; WT buffer/AXI còn nghĩa vụ đưa write ra memory và nhận B. [Store queue](../../../core/store_buffer.sv#L177), [WT buffer](../../../core/cache_subsystem/wt_dcache_wbuffer.sv#L503). Không khẳng định write đã đạt physical memory ở `commit_ack` hay D-cache grant.

## Cache/ordering/protection

CFG-01 chọn WT subsystem: I-cache, D-cache, write buffer, AXI adapter. I-cache 16 KiB/4-way, D-cache 32 KiB/8-way, line 16 B; mỗi cache có 256 sets theo phép tính từ config, không phải latency. [Config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L33), [WT hierarchy](../../../core/cache_subsystem/wt_cache_subsystem.sv#L120). Store buffer kiểm alias page offset `[11:3]` để interlock load; chưa có chứng cứ store-to-load forwarding full address. [Address checker](../../../core/store_buffer.sv#L237).

`no_st_pending_commit = no_st_pending_ex & dcache_commit_wbuffer_empty`; FENCE/FENCE.I đợi cả committed queue và WT buffer rỗng trước ack. FENCE.I còn flush I-cache; SFENCE.VMA đợi shared TLB flush idle rồi flush translation state. [Core wiring](../../../core/cva6.sv#L1149), [commit fences](../../../core/commit_stage.sv#L235), [controller](../../../core/controller.sv#L123). AXI R/B error mapping và completion contract còn [OQ-04](09_open_questions.md). Không suy RVWMO compliance đầy đủ chỉ từ fence drain.
