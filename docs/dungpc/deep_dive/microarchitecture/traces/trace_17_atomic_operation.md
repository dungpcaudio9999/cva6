# Trace 17 — Atomic Memory Operation

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: execute LR/SC and one AMO arithmetic operation with cache hit and external backpressure variants.

Observe: LSU/AMO request, miss-unit `AMO/AMO_WAIT`, AXI lock/ATOP and read/write responses, scoreboard result, commit AMO acknowledge, pipeline flush/restart.

Expected RTL relation: the operation remains one scoreboard owner, memory update and returned old value stay coupled, and commit waits for AMO completion before the configured pipeline flush.

Pass: correct old/new values, SC status, no duplicate request, and no younger side effect before restart.
