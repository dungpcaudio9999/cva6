# Trace 07 — Correct Branch Prediction

**Status: NOT EXECUTED.** Simulator license unavailable.

Stimulus: train a conditional branch, then execute it with the predicted outcome and target.

Observe: BHT/BTB prediction, `bp_valid`, frontend kill_s2, resolved branch fields, BHT update, controller flush outputs, fetch PCs and commit.

Expected RTL relation: prediction redirects fetch and cancels the fall-through cache stage; resolution updates BHT but `is_mispredict=0`, so no recovery flush occurs.

Pass: predicted target instructions remain valid and branch retires once.
