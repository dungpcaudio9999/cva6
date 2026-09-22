# 07 — Corner cases và nghĩa vụ proof

| Tình huống | Cơ chế RTL thấy được | Cần quan sát để đóng |
|---|---|---|
| Flush cùng cycle D-cache grant load | `ldbuf_flushed_d='1` đặt sau allocation; response guard kiểm flushed bit. [Load](../../../core/load_unit.sv#L160), [response](../../../core/load_unit.sv#L492) | Response được drain đúng ID; không writeback/retire; ID không bị dùng lại sớm. |
| Branch mispredict khi younger đã decode | Controller flush IF/unissued; `issue_n.valid` hạ khi ID flush theo loại event. [Controller](../../../core/controller.sv#L112), [ID](../../../core/id_stage.sv#L467) | Không younger GPR/CSR/store side effect; đúng target fetch. |
| Exception ở head + CSR error | Commit ưu tiên exception đã lưu trong entry hơn CSR exception được phát hiện muộn. [Commit](../../../core/commit_stage.sv#L405) | Cause/EPC/tval đúng lệnh; normal CSR/GPR write bị chặn. |
| Store committed, AXI chậm hoặc B error | Committed queue pop tại cache `data_gnt` cho normal store; WT buffer còn giữ traffic. [Store buffer](../../../core/store_buffer.sv#L177), [WT buffer](../../../core/cache_subsystem/wt_dcache_wbuffer.sv) | FENCE drain đến đúng tầng; lỗi write muộn có được báo hay không, theo contract integration. |
| FENCE.I sau self-modifying code | Commit chờ `no_st_pending_i`; controller flush I-cache. [Commit](../../../core/commit_stage.sv#L278), [controller](../../../core/controller.sv#L142) | Fetch sau fence thấy bytes mới trong cache và downstream. |
| SFENCE.VMA cùng PTW | Commit chờ `!shared_tlb_flush_busy_i`; TLB selective flush theo ASID/VA. [Commit](../../../core/commit_stage.sv#L142), [TLB](../../../core/cva6_mmu/cva6_tlb.sv#L298) | Không stale translation sau completion, PTE walk cũ không fill lại sai. |
| Debug request + IRQ | Decoder ghi debug cause cuối block, nhưng acceptance ở commit/CSR phụ thuộc trạng thái. [Decoder](../../../core/decoder.sv#L1995), [CSR debug](../../../core/csr_regfile.sv#L2249) | Ưu tiên thực tế theo mode/stall/exception; DPC/cause và pending IRQ. |
| Reset giữa bus transaction | Core reset metadata, bus có thể còn response. [Scoreboard](../../../core/scoreboard.sv#L304), [AXI shim](../../../core/axi_shim.sv) | Reset domain wrapper, epoch isolation, không response cũ cấp cho lệnh mới. |
| Illegal encoding hoặc privilege denied | Decoder defaults `fu=NONE`, `rd=0`; exception flow chặn FU valid. [Decoder](../../../core/decoder.sv#L175), [issue gate](../../../core/issue_read_operands.sv#L749) | Không GPR/CSR/store write, đúng trap cause/tval. |

Điểm trọng yếu: “request được accept” không đồng nghĩa “instruction retire”; “scoreboard entry valid” cũng không đồng nghĩa “architectural write”. Khi test concurrent event, bắt cả lệnh già hơn và trẻ hơn cùng với transaction bên ngoài. [Luồng chính](04_dominant_flow.md), [retirement](cpu_07_retirement_model.md).
