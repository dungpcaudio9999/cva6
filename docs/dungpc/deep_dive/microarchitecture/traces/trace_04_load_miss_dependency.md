# Trace 04 — Load Miss Dependency

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: invalidate the target D-cache line; issue a load and its immediate dependent ALU instruction while delaying AXI R.

Observe: load-buffer owner, D-cache controller `MISS_REQ/MISS_WAIT`, miss-unit MSHR, AXI AR/R beats, RAW stall duration, response/writeback/commit.

Expected RTL relation: consumer remains blocked through the miss; MSHR and load-buffer IDs stay stable under AXI backpressure; final refill response releases the dependency.

Pass: all stalled cycles are recorded, only the matching response completes the load, and the dependent result is correct.
