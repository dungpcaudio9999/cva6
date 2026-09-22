# Load unit và store buffer

## Hai loại transaction ownership

[load_unit](../../../core/load_unit.sv#L90) giữ hai outstanding-load slots của CFG-01, metadata và `ldbuf_valid/flushed`. [store_buffer](../../../core/store_buffer.sv#L62) dùng hai queue depths từ [ariane_pkg](../../../core/include/ariane_pkg.sv#L35): speculative=4, committed=4. Đây không phải WT cache write buffer depth=8.

## Load FSM và flush

| State/group | Điều kiện/chức năng | Next/recovery chính |
|---|---|---|
| IDLE | Có thể nhận load; xét offset hazard, speculation, resource | WAIT_PAGE_OFFSET, WAIT_GNT, SEND_TAG hoặc abort tùy grant/translation |
| WAIT_PAGE_OFFSET | Store cùng page offset chưa drain | Hết conflict → WAIT_GNT |
| WAIT_GNT | Giữ request khi cache chưa grant | Grant/translation outcome → SEND_TAG hoặc abort |
| SEND_TAG | Gửi tag/kill phase cho lookup trước | Có thể nhận request tiếp; exception/flush ưu tiên |
| ABORT_TRANSACTION/WAIT_TRANSLATION | Hủy speculative cache lookup, đợi MMU outcome | Translation ready → retry hoặc exception |
| WAIT_FLUSH | Hấp thụ flush/recovery | Trở lại nhận việc theo guards trong RTL |
| WAIT_WB_EMPTY/ABORT_TRANSACTION_NI | Non-idempotent serialization | Source có nhánh, nhưng NonIdemPotenceEn=0 ở CFG-01 |
| WAIT_SPEC_LOAD | Speculative load sequencing | SpeculativeSb=0 ở CFG-01, không suy behavior superscalar |

Đây là state grouping có guard chi tiết tại [246–465](../../../core/load_unit.sv#L246), không reachability proof. Data path là VA/op → translate/tag/index → cache data → select byte/sign/zero extension → WB trans_id.

**FND-LSU-01:** flush thắng load allocation khi cùng cycle. **Support:** SUPPORTED. **Evidence:** [160–181](../../../core/load_unit.sv#L160) clear/set slot khi ldbuf_w trước, cuối block `if(flush_i) ldbuf_flushed_d='1`. [RTL:ESTABLISHED] Response guard [492](../../../core/load_unit.sv#L492) dùng flushed_q để suppress normal load writeback. Claim chỉ nói priority và guard; chưa chứng minh toàn load FSM đúng.

**INV-LD-01:** Nếu flush và grant cùng edge, newly allocated slot phải mang flushed=1 sau edge. **INV-LD-02:** Response gắn slot flushed không được phát normal result của instruction bị hủy. Safety, reset epoch ASM-01/02; chưa formal/SIM. Cần cover grant×flush, delayed response, index reuse và concurrent exception. [EXP-04](../12_experiments.md) chỉ kiểm abstract assignment model, không DUT.

## Store queue equations

Đặt S/C là occupancy trước edge, v=`valid_i`, k=`commit_i`, g=ordinary committed head accepted bởi cache (`data_req && data_gnt`, CBO_NONE). Với legal handshake, không reset/flush:

```text
S_next = S + v - k
C_next = C + k - g
0 <= S,C <= 4
commit_ready_o = (C < 4)
no_st_pending_o = (C == 0)
```

`valid_i` không được buffer tự gate bằng `ready_o`; đây là producer-qualified pulse. `ready_o` dùng speculative next-count và commit_i, nên không thay bằng generic FIFO `(S<4)` mà bỏ caller timing. Store source assertions cấm commit khi empty, input khi full và commit cùng flush.

Flush đặt S_next=0 và invalidates speculative entries; **giữ committed queue**. Async reset clears cả queue state/pointers/counts. Do assertion cấm flush+k, không dùng queue equation như bằng chứng xử lý hợp lệ tổ hợp đó. CBO khác CBO_NONE có wait_rvalid state, nhưng RVZiCbom=0 trong CFG-01.

**FND-ST-01:** store_buffer pop ordinary committed store tại cache grant, bỏ qua data_rvalid cho ordinary store; write response tiếp tục do WT path sở hữu. **Support:** SUPPORTED, [store_if](../../../core/store_buffer.sv#L165). [RTL:ESTABLISHED]

**INV-ST-01:** Committed store không bị speculative flush loại bỏ. **INV-ST-02:** Không underflow/overflow dưới ASM-02; full+pop không tự đảm bảo same-edge new commit vì commit_ready dùng pre-edge C. **INV-ST-03:** Data/address/be của committed head phải giữ khi cache stalled. Source queue/pointer guards hỗ trợ; chưa simulator/assertion result.

Offset conflict so `[11:3]` với valid speculative/committed entries; hai địa chỉ khác page nhưng cùng offset có thể stall nhau. Đây là conservative hazard, không full physical forwarding. Thay depths ảnh hưởng pointer modulo, counter width, assertions và latency; thay flush priority ảnh hưởng cả system FLOW-03/05. OQ-03/06.
