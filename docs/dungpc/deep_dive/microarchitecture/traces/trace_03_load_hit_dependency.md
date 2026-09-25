# Trace 03 — Load Hit Dependency

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: preload a cacheable line, execute `ld x5,0(x1)` then `add x6,x5,x2`.

Observe: DTLB hit, load FSM, D-cache grant/response ID, two load-buffer valid bits and stored scoreboard ID, load writeback, RAW stall and forwarding, commits.

Expected RTL relation: the dependent instruction stalls until load result validity, then consumes the load writeback or completed scoreboard value. Load-buffer allocation precedes matching response and is released exactly once.

Pass: x6 receives loaded data, no ID reuse while live, retirement is load then add.
