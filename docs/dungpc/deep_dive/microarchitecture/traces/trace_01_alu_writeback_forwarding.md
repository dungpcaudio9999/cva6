# Trace 01 — ALU Writeback Forwarding

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: issue `add x5,x1,x2` followed immediately by `xor x6,x5,x3`, with all source registers initialized and no cache/control stalls.

Observe: ID/scoreboard allocation IDs; `idx_hzd_rs1`; `fwd_res_valid`; FLU `wt_valid_i`, result and ID; issue acknowledge; operand selected for x5; both commit acknowledgements and GPR writes.

Expected RTL relation: the consumer owner search points to the producer; if producer writeback and consumer issue coincide, forwarded operand equals that writeback result. The consumer can issue before producer retirement. Both retire in scoreboard order.

Pass: every cycle captured, exactly one producer and consumer architectural write, x6 uses computed x5, no RAW stall after writeback availability.
