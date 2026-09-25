# Trace 11 — Instruction Page or Access Fault

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: fetch from a page with invalid PTE, then from a physical address denied for execute by PMP.

Observe: ITLB miss/PTW/PMP path, I-cache exception metadata, instruction queue exception entry, scoreboard head, commit exception, EPC/cause/tval, trap target and flush.

Expected RTL relation: no normal instruction side effect occurs; cause distinguishes page fault from access fault; EPC/tval identify faulting fetch address.

Pass: handler fetch begins at the selected vector and younger work is invalidated.
