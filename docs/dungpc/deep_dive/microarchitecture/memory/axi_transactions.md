# AXI Transactions

**Evidence level:** RTL-established for adapter protocol structure; no external timing was observed.

`wt_axi_adapter` arbitrates I-cache reads and D-cache reads/writes, maps internal memory transaction IDs into AXI IDs, records outstanding IDs in FIFOs, assembles line beats, and returns responses to the requesting cache. [AXI adapter](../../../../../core/cache_subsystem/wt_axi_adapter.sv#L17)

## Read transaction

```mermaid
sequenceDiagram
  participant C as I$/D$ request
  participant A as wt_axi_adapter
  participant X as AXI fabric
  C->>A: data_req {addr,id,size,len}
  A->>X: ARVALID + AR payload
  X-->>A: ARREADY
  Note over A: store internal requester ID in read FIFO
  loop each beat
    X-->>A: RVALID + RDATA + RRESP + RLAST
    A->>X: RREADY
  end
  A-->>C: return valid, original ID, line/data, error
```

## Write transaction

```mermaid
sequenceDiagram
  participant W as D$ write/miss unit
  participant A as wt_axi_adapter
  participant X as AXI fabric
  W->>A: write request {addr,data,be,id,amo}
  A->>X: AWVALID + address/ID/ATOP
  A->>X: WVALID + data/strobe/last
  X-->>A: independent AWREADY and WREADY
  Note over A: request completes only after required channel handshakes
  X-->>A: BVALID + BRESP + BID
  A->>X: BREADY
  A-->>W: write completion/error for saved ID
```

AW and W are independent AXI channels; reasoning must use their individual handshakes rather than assume same-cycle acceptance. The adapter has outstanding-ID FIFOs for I-cache reads, D-cache reads, and D-cache writes, plus a B-response FIFO. [ID FIFOs](../../../../../core/cache_subsystem/wt_axi_adapter.sv#L376)

AXI errors are converted into cache return status. AMOs can use AXI atomic encodings and may synthesize/read returned data according to operation. Progress has no bounded latency because the external fabric may backpressure any channel.

Reset safety is open: adapter FIFOs reset locally, but a response from a separately reset external fabric could reuse an ID. Integration must reset/quiesce the fabric or provide an epoch/isolation guarantee.
