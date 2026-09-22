# WT cache, write buffer và AXI adapter

Nguồn [WT subsystem](../../../core/cache_subsystem/wt_cache_subsystem.sv), [WT write buffer](../../../core/cache_subsystem/wt_dcache_wbuffer.sv#L160), [adapter](../../../core/cache_subsystem/wt_axi_adapter.sv#L20), [axi_shim](../../../core/axi_shim.sv#L69). Source branch `cva6.gen_cache_wt`; CFG-01/FLOW-02/03/04.

## State, buffering và đường return

I-cache/D-cache giữ tag/data/valid và miss state. WT write buffer có 8 entries theo word, mỗi byte có valid/dirty/txblock; `tx_stat` có 4 slots do DCACHE_MAX_TX=2**MemTidWidth=4. Byte states cho phép viết lại một word trong khi transaction trước vẫn outstanding; chỉ đếm word entries không đủ chứng minh no-loss.

`empty_o=!(|valid)` ở [514](../../../core/cache_subsystem/wt_dcache_wbuffer.sv#L514); return logic clear valid bytes khi response được xử lý và byte không bị dirty rewrite. Dirty/txblock quyết định byte nào có thể đưa ra tiếp. Cache-side data_gnt chuyển ownership khỏi store_buffer; request/metadata FIFOs và AXI shim giữ trách nhiệm tới response.

WT adapter có ReqFifoDepth default 2 và MetaFifoDepth=DCACHE_MAX_TX; request arbitration dựng IDs và response FIFOs giữ mapping TID. Read reply phải tách instruction/data route; atomic/exclusive dùng additional encoding. Không giả định request arbitration một chiều là đủ hiểu ordering; return FIFOs/pop/ID phối hợp cũng là state.

Write shim quản lý AW/W acceptance độc lập bằng state machine; read side đưa AR request và trả R data/id/last/EXOKAY. ID width 4 không quyết định số outstanding; xbar params=1 còn có thể giới hạn effective memory traffic. Không xác lập global maximum concurrent transactions chỉ bằng cộng các queue depths.

## Quan hệ với fence và error

Commit fence nhìn `no_st_pending_ex && dcache_commit_wbuffer_empty`, không chỉ committed store queue. Trong WT configuration, explicit D-cache flush flags=0 nhưng vẫn cần WB drain và I-cache invalidation đối với FENCE.I.

FND-AXI-01 được xác lập tại shim: normal read/write status chỉ còn EXOKAY equality, không có SLVERR/DECERR output. Cần directed invalid-region/error-target test và specification về error visibility; không có precise-exception guarantee trong phân tích này.

## Invariants, performance và change impact

- **INV-WB-01:** Accepted store bytes không mất khi merge cùng word và response+new write đồng thời. Identity là address+byte enable+ordering, không chỉ FIFO count. Safety/data integrity, NOT-RUN.
- **INV-WB-02:** Fence drain condition không true khi accepted write còn trách nhiệm trong WB. Cần response bookkeeping/source proof đầy đủ và B-stall witness, NOT-RUN.
- **INV-AXI-01:** Payload/ID/last ổn định cho mỗi VALID&&!READY trừ reset contract; accepted response ID phải thuộc outstanding request. SVA activation chưa có.
- **INV-AXI-02:** AW/W accepted độc lập vẫn sinh đúng một completion bookkeeping, không double-pop; cần AW-first/W-first/both-stalled/B-delayed combinations.

Line width 128/AXI64=2 beats cho full line; effective bandwidth phụ thuộc bus contention, refill, write merging, outstanding limit, backend và pattern. Không có hit rate/Fmax/IPC đo được.

Đổi cache line/associativity kéo theo index/tag widths, SRAM organization, AXI burst length và refill beat counters. Đổi WB depth/transaction width kéo theo pointer/reduction/metadata FIFOs/response paths. Thêm propagation RRESP/BRESP là thay đổi contract xuyên shim→WT adapter→cache→LSU/commit; store late faults cần policy riêng. Chưa áp dụng sửa đổi nào.
