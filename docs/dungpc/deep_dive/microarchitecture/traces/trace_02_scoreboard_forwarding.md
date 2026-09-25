# Trace 02 — Completed-Scoreboard Forwarding

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: hold commit or create an older head blocker so `add x5,x1,x2` completes into its scoreboard entry; then issue a dependent `xor x6,x5,x3` after the writeback pulse has passed.

Observe: producer entry `issued/valid/result`; owner index for consumer rs1; forwarding-source selection; commit pointer; FU valid/ack.

Expected RTL relation: dependency remains mapped to the live producer, `fwd_res_valid` comes from the completed scoreboard value, and operand data equals stored result. Retirement remains ordered behind the blocker.

Pass: forwarding occurs without relying on a simultaneous writeback pulse; no duplicate completion or early owner release.
