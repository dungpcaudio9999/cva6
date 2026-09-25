# Store Ownership Model

**Evidence level:** RTL-established through D-cache acceptance. AXI response timing is structurally established and not dynamically observed.

```mermaid
sequenceDiagram
  participant EX as store_unit
  participant SQ as speculative queue (4)
  participant C as commit stage
  participant CQ as committed queue (4)
  participant DC as WT D-cache
  participant WB as WT write buffer (8)
  participant AX as AXI
  EX->>SQ: valid store accepted
  Note over SQ: cancelable by pipeline flush
  C->>SQ: commit_i for oldest store
  SQ->>CQ: copy entry; invalidate speculative head
  Note over CQ: architectural ownership; survives ordinary flush
  CQ->>DC: req until data_gnt
  DC->>WB: allocate/merge bytes
  WB->>AX: write request (AW/W)
  AX-->>WB: B response
```

## Ownership boundaries

1. **Issue to speculative queue:** translation/protection succeeded and `store_buffer.ready_o` accepted the entry. The scoreboard can then complete the store instruction.
2. **Architectural commit:** `commit_stage` receives `commit_ready_o` and asserts `commit_i`; `store_buffer` copies the speculative head into the committed tail. This is the point after which pipeline flush does not cancel the store.
3. **D-cache acceptance:** the committed head asserts its request until `data_gnt`; normal stores are then removed from the committed queue. CBO entries, inactive in CFG-01, can wait for `data_rvalid`.
4. **Write-buffer ownership:** the WT cache holds address, bytes, data, and memory transaction identity, merging compatible writes when allowed.
5. **External completion:** AW/W acceptance creates an AXI outstanding write; B reports bus completion. The core's earlier retirement does not wait for this response.

## Flush/error consequences

`flush_i` clears speculative valid bits and leaves committed queue state intact. Source assertions forbid commit and flush together and check queue overflow/underflow. [Store buffer](../../../../../core/store_buffer.sv#L90) [Assertions](../../../../../core/store_buffer.sv#L298)

Late AXI write errors occur after architectural retirement. The static path exposes response status inside the cache/adapter plumbing, but a precise rollback mechanism is not established. Platform-visible handling of late store errors remains open.
