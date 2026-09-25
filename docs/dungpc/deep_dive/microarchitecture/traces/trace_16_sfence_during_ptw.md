# Trace 16 — SFENCE.VMA During Active PTW

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: start a TLB miss walk, then bring an older/legal SFENCE.VMA to commit while delaying the PTE response.

Observe: PTW state/request/grant/response, captured rs1/rs2, TLB flush signals/busy, TLB update valid, commit ack and frontend restart.

Expected RTL relation: the old walk is killed or drained; it cannot refill an entry invalidated by the SFENCE. Completion waits for the relevant flush coordination.

Pass: a subsequent lookup misses or uses only a post-fence translation.
