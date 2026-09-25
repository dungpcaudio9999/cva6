# Trace 08 — Branch Misprediction

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: create a wrong direction or target prediction with younger instructions resident in queue/ID and at least one older issued instruction.

Observe: `resolved_branch_i`, frontend NPC, `flush_if`, `flush_unissued_instr`, queue/ID valids, older scoreboard entries, younger side-effect enables.

Expected RTL relation: target becomes the resolved address; frontend and unissued younger state clear; older issued ownership remains; no wrong-path architectural effect occurs.

Pass: first retained instruction is from correct target and every wrong-path valid disappears before side effect.
