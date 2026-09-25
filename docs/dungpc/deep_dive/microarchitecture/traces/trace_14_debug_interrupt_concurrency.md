# Trace 14 — Debug Request Concurrent with Interrupt

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: assert `debug_req_i` with an enabled interrupt at a controllable precise boundary; repeat during WFI and during a memory stall.

Observe: interrupt pending/accept, `set_debug_pc_i`, debug mode, DPC/DCSR cause/prv, trap CSRs, frontend NPC and flushes.

Expected RTL relation: when debug entry is accepted, debug PC has frontend mux priority and interrupts are disabled in debug; a level/pending interrupt is preserved or represented according to `mip` state for later service.

Pass: one entry path wins without double CSR capture; DRET resumes at the recorded DPC and pending interrupt behavior matches CSR state.
