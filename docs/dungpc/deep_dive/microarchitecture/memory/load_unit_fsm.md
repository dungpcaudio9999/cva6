# Load Unit FSM

**Evidence level:** RTL-established for state transitions and ownership; latency remains open.

## Request and identity flow

The load unit receives an effective address, size/sign control, and scoreboard transaction ID. It coordinates translation/PMP results and the D-cache request port. Two load-buffer entries hold the cache response identity and corresponding scoreboard ID. [Load unit](../../../../../core/load_unit.sv#L16)

```mermaid
stateDiagram-v2
  [*] --> IDLE
  IDLE --> WAIT_GNT: request cannot obtain grant
  IDLE --> WAIT_PAGE_OFFSET: page offset dependency
  IDLE --> WAIT_SPEC_LOAD: speculative-load restriction
  IDLE --> ABORT_TRANSACTION: translation unresolved after speculative request
  WAIT_GNT --> IDLE: cache grant / terminal exception
  ABORT_TRANSACTION --> WAIT_TRANSLATION: killed cache request drained
  ABORT_TRANSACTION_NI --> WAIT_WB_EMPTY: non-idempotent path
  WAIT_WB_EMPTY --> WAIT_TRANSLATION: WT buffer condition met
  WAIT_TRANSLATION --> WAIT_GNT: DTLB hit, retry request
  WAIT_TRANSLATION --> IDLE: translation exception
  WAIT_FLUSH --> IDLE: outstanding flushed ownership drained
  IDLE --> WAIT_FLUSH: flush with outstanding work
```

CFG-01 has `NonIdemPotenceEn=0` and `SpeculativeSb=0`; `ABORT_TRANSACTION_NI`, `WAIT_WB_EMPTY`, and speculative scoreboard behavior compile but are inactive after constant propagation. State declarations and transition logic are at [state enum](../../../../../core/load_unit.sv#L89) and [FSM](../../../../../core/load_unit.sv#L263).

## Acceptance and buffer allocation

An accepted D-cache grant allocates a free load-buffer slot and records the scoreboard ID plus operation metadata. The cache-side ID selects that slot. A response releases it and reconstructs the scoreboard writeback. Load extraction shifts by address offset, then applies sign or zero extension based on operation/size.

```mermaid
sequenceDiagram
  participant I as issue/load_unit
  participant T as DTLB/PMP
  participant D as WT D-cache
  participant B as load buffer[2]
  participant S as scoreboard
  I->>T: vaddr, access type, valid
  T-->>I: translation_valid, paddr or exception
  I->>D: data_req, address, load-buffer ID
  D-->>I: data_gnt
  I->>B: allocate {scoreboard trans_id, control}
  D-->>B: data_rvalid, data_rid, data/error
  B->>S: load_valid, scoreboard trans_id, result/exception
```

## Flush and faults

Flush marks live load-buffer entries flushed. A later cache response still releases the resource, while normal writeback is suppressed for the flushed owner. A same-cycle accepted grant and flush is resolved by the next-state assignment order so the new ownership is also marked flushed. Translation, alignment, PMP, and bus/cache errors become load exceptions attached to the scoreboard owner.

Required checks: no response without a live buffer ID, no ID reuse before response drain, grant-plus-flush suppression, and response-after-flush resource release without writeback.
