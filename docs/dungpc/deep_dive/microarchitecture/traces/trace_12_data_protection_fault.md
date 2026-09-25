# Trace 12 — Data Page Fault or PMP Rejection

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: perform load and store accesses that separately fail page permissions and PMP.

Observe: effective privilege, DTLB/PTW result, PMP allow, downstream cache request, load/store exception, scoreboard/commit state, cause/tval and register/memory effects.

Expected RTL relation: denied access issues no normal cache request; fault metadata stays with the instruction owner; load destination and store queues remain unchanged.

Pass: correct fault class/address and zero normal side effects.
