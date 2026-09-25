# Trace 10 — Store Flushed Before Commit

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: allocate a younger store in the speculative queue, then resolve an older branch misprediction or exception before store commit.

Observe: speculative queue valid/count/pointers, `flush_i`, `commit_i`, committed queue, D-cache request, AXI write channels.

Expected RTL relation: flush clears the speculative entry; commit and flush are never asserted together; no committed-queue, cache, or AXI ownership is created.

Pass: memory remains unchanged and source assertions report no violation.
