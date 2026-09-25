# Trace 05 — Load Grant Concurrent with Flush

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: arrange a D-cache `data_gnt` for a younger load on the same edge that an older branch/trap asserts the relevant flush.

Observe: load FSM state, request/grant, allocated buffer index, stored scoreboard ID, buffer `flushed` bit, controller flush signals, later response and writeback valid.

Expected RTL relation: accepted traffic remains owned and drainable; flush marks the newly allocated entry killed. Its later response frees the slot and cannot assert normal load writeback.

Pass: no lost response, no architectural update, no early ID reuse.
