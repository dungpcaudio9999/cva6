# MMU, TLB, PTW và PMP

Nguồn [cva6_mmu](../../../core/cva6_mmu/cva6_mmu.sv), [PTW](../../../core/cva6_mmu/cva6_ptw.sv#L94), [build_config](../../../core/include/build_config_pkg.sv#L29), [PMP](../../../core/pmp/src/pmp.sv). CFG-01: RV64/Sv39, PLEN=56, ASID_WIDTH=16, PtLevels=3, ITLB/DTLB=16 mỗi phía, UseSharedTlb=0, RVH=0, 8 PMP entries.

## State và data path

MMU chọn bypass/translation theo privilege/satp/status, nhận virtual fetch/load-store addresses. TLB hit cung cấp cached PTE/translation/permissions; miss chuyển tới PTW. PTW giữ `vaddr_q`, `tlb_update_asid_q`, `ptw_pptr_q`, level, loại instruction/data walk, mapping flags và PTE data q. Các state `IDLE`, `WAIT_GRANT`, `WAIT_RVALID` và check/update/error/kill stages quản lý request và kết quả.

PTW request đi vào D-cache bằng split physical index/tag, `data_req/data_gnt`, `tag_valid/kill_req`, response data. PTE được cast từ data_rdata_q, kiểm invalid/leaf/permission/alignment và xác định next-level pointer hoặc TLB update. PMP áp lên địa chỉ walk trước khi tin dữ liệu. TLB miss không đồng nghĩa ngoại lệ ngay; PTW fault cũng không đồng nghĩa AXI SLVERR đã được preserve.

`UseSharedTlb=0` là tắt shared TLB capacity option theo config, không đủ để khẳng định module mang tên shared_tlb/logic điều phối PTW không instantiate; phải xem generate/elaboration. Không gộp GPLEN/SVX dùng cho virtualization vào physical width PLEN của CFG-01.

## Contract và performance

Request accepted tại cache grant; response có thể đến trễ trong lúc flush. TLB update phải đi kèm VA/ASID và permissions của đúng walk. Không được phát stale update sau SFENCE thay context; liveness cần D-cache/AXI service và không reset/flush mãi.

Sv39 có tối đa 3 PTE levels cho walk thông thường, leaf có thể kết thúc sớm; walk có thể tốn nhiều cycles do arbitration/cache misses/stalls. Không có số TLB hit latency hoặc maximum miss penalty đã đo. Root PPN/satp không tự thay software TLB invalidation obligation.

## Properties cần kiểm

- **INV-MMU-01:** Successful translation không bỏ qua applicable permission/PMP faults; property cần độc lập PTE/PMP reference, không chỉ so signal của cùng RTL. Type safety, NOT-RUN.
- **INV-PTW-01:** Một granted PTE read chỉ được consume như response của walk sở hữu nó; flush/reset không gán response cũ cho VA/ASID mới. Type identity/epoch, NOT-RUN.
- **INV-TLB-01:** SFENCE.VMA completion không để entry cần invalidation phục vụ instruction/load trẻ hơn sai context. Scope satp/ASID/global/page-size operands; NOT-RUN.

Cases: ITLB và DTLB miss cạnh tranh, leaf lớn misaligned, invalid PTE, permission fault, PMP deny trên PTE fetch, SFENCE khi WAIT_RVALID, response sau kill. RVH two-stage walk, Sv32, page variants cần config-specific checks riêng; chưa được cover bởi CFG-01.

**Change impact:** Đổi TLB entries/UseSharedTlb thay replacement/arbitration và throughput; đổi PA/ASID widths thay PTE slicing, CSR và AXI extension; đổi flush priority ảnh hưởng FLOW-02/04/05. OQ-03/04/06/08 ghi các validation gaps.
