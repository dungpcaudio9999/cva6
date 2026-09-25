# Trace 13 — Interrupt During Memory Stall

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: delay a load miss at the oldest scoreboard entry, assert an enabled interrupt, then release AXI response.

Observe: `irq_i`, `mip/mie/global_enable`, commit head/ack, load state, exception output, saved EPC/cause, flush and handler PC.

Expected RTL relation: interrupt becomes pending while the older memory instruction retains precise ownership; acceptance occurs only at a legal commit boundary. Saved EPC corresponds to the next nonretired instruction.

Pass: older operation has a single defined outcome and no younger instruction retires before the handler transition.
