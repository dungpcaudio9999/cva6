# Trace 18 — Reset During Outstanding AXI Transaction

**Status: NOT EXECUTED.** Simulator license unavailable. Integration behavior is open.

Stimulus: accept an AXI read and separately a write, assert core reset before R/B response, then release reset and deliver a delayed response.

Observe: AXI outstanding-ID FIFOs, cache MSHR/write-buffer ownership, load/scoreboard IDs, reset signals to core/cache/adapter, delayed R/B acceptance and all post-reset write enables.

Expected safety requirement: a pre-reset response cannot complete a post-reset instruction or create an architectural write. This requires either shared reset/quiescence of the fabric or explicit response isolation/epoch behavior.

Pass: delayed responses are blocked/drained safely and no new owner is aliased. Current RTL-only analysis does not establish this integration guarantee.
