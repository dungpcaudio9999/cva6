# Trace 06 — Load Response After Flush

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: allow a load request/grant, flush its instruction before returning AXI/cache data, then return the response.

Observe: load-buffer valid/flushed/scoreboard ID, cache response ID/error, load output valid, scoreboard entry reuse, GPR write enable.

Expected RTL relation: response ID matches the killed buffer owner, releases it, and produces no normal scoreboard/GPR result.

Pass: the response is drained exactly once and cannot complete any post-flush instruction.
