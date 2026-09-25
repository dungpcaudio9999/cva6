# Trace 15 — FENCE.I After Self-Modifying Code

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: store new instruction bytes to a previously fetched line, execute FENCE.I, then branch/fall through to the modified address.

Observe: store queues, WT buffer empty, fence commit gate, I-cache flush state/ack, frontend restart PC, refill data and retired instruction bits.

Expected RTL relation: FENCE.I waits for the documented store drain, invalidates instruction-cache state, restarts fetch, and the next execution observes the modified bytes.

Pass: stale instruction never retires after fence completion.
