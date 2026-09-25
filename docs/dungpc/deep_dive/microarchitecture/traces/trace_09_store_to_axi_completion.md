# Trace 09 — Store Through AXI B Completion

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: execute a cacheable store while independently backpressuring AXI AW, W, and B channels.

Observe: store FSM; speculative/committed queue pointers/counts; D-cache grant; WT-buffer entry/merge; AW/W valid-ready; saved write ID; B valid-ready/response; fence-visible emptiness.

Expected RTL relation: ownership moves in order from speculative queue to committed queue to WT buffer to outstanding AXI write. AW and W may handshake on different cycles. B releases the external outstanding identity.

Pass: data/strobes/address remain stable under backpressure, store is never lost/duplicated, and every ownership transfer has one predecessor/successor.
