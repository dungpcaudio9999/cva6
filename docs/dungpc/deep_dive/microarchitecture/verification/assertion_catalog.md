# Assertion Catalog

**Status:** proposals only; not compiled or run. Signal names are taken from RTL, while bind paths and clock/reset aliases require the final testbench hierarchy.

## Retirement and side effects

```systemverilog
// Port 1 is subordinate to port 0.
assert property (@(posedge clk_i) disable iff (!rst_ni)
  commit_ack_o[1] |-> commit_ack_o[0]);

// A head exception excludes its normal architectural destinations.
assert property (@(posedge clk_i) disable iff (!rst_ni)
  exception_o.valid |-> !(we_gpr_o || we_fpr_o || commit_store_o));

// A dropped instruction has no normal register side effect.
assert property (@(posedge clk_i) disable iff (!rst_ni)
  (commit_drop_i[0] || commit_drop_i[1]) |-> !(we_gpr_o || we_fpr_o));
```

Adapt vector/scalar output widths to the commit-stage bind scope. Port-1 FU restrictions should be duplicated directly from the commit equation and asserted as implications.

## Pipeline control

```systemverilog
assert property (@(posedge clk_i) disable iff (!rst_ni)
  flush_i |=> !issue_q[0].valid);

assert property (@(posedge clk_i) disable iff (!rst_ni)
  issue_q[0].valid && !issue_instr_ack_i[0] && !flush_i
  |=> $stable(issue_q[0]));

assert property (@(posedge clk_i) disable iff (!rst_ni)
  resolved_branch_i.valid && resolved_branch_i.is_mispredict
  |-> flush_if_o && flush_unissued_instr_o);
```

## Scoreboard and forwarding

```systemverilog
assert property (@(posedge clk_i) disable iff (!rst_ni)
  wt_valid_i[p] |-> scoreboard_q[wt_trans_id_i[p]].valid &&
                    scoreboard_q[wt_trans_id_i[p]].issued);

assert property (@(posedge clk_i) disable iff (!rst_ni)
  rs1_valid[i] |-> operand_a_forwarded[i] == fwd_res[idx_hzd_rs1[i]]);
```

Generate the first property across all five writeback ports and add pairwise exclusion for ports targeting the same ID.

## Loads and stores

```systemverilog
assert property (@(posedge clk_i) disable iff (!rst_ni)
  req_port_i.data_rvalid |-> load_buffer_q[req_port_i.data_rid].valid);

assert property (@(posedge clk_i) disable iff (!rst_ni)
  req_port_i.data_rvalid && load_buffer_q[req_port_i.data_rid].flushed
  |-> !valid_o);

assert property (@(posedge clk_i) disable iff (!rst_ni)
  flush_i |-> !commit_i); // already represented in store_buffer source

assert property (@(posedge clk_i) disable iff (!rst_ni)
  flush_i |=> $stable(commit_queue_q));
```

The last property needs an exception for legitimate D-cache dequeue on the flush edge; implement it as per-entry conservation rather than literal stability.

## Translation and protection

```systemverilog
assert property (@(posedge clk_i) disable iff (!rst_ni)
  pmp_exception.valid |-> !normal_dcache_request_accept);

assert property (@(posedge clk_i) disable iff (!rst_ni)
  ptw_tlb_update_valid |-> ptw_request_epoch == current_tlb_epoch);

assert property (@(posedge clk_i) disable iff (!rst_ni)
  flush_tlb_i && ptw_active |=> !stale_ptw_fill);
```

The epoch signals are proposed checker state, not current design signals. The checker increments an epoch on relevant TLB flush and tags a walk at acceptance.

## AXI and reset

```systemverilog
assert property (@(posedge clk_i) disable iff (!rst_ni)
  axi.aw_valid && !axi.aw_ready |=> $stable(axi.aw));
assert property (@(posedge clk_i) disable iff (!rst_ni)
  axi.w_valid && !axi.w_ready |=> $stable(axi.w));
assert property (@(posedge clk_i) disable iff (!rst_ni)
  axi.ar_valid && !axi.ar_ready |=> $stable(axi.ar));
```

Add a scoreboard in the checker for accepted AR/AW/W and R/B responses. A reset epoch must prevent a pre-reset response from matching post-reset ownership.

## Ordering

```systemverilog
assert property (@(posedge clk_i) disable iff (!rst_ni)
  commit_fence_ack |-> no_st_pending_commit);
assert property (@(posedge clk_i) disable iff (!rst_ni)
  commit_sfence_ack |-> !shared_tlb_flush_busy_o);
```

Exact fence opcode qualifiers should be bound at the commit operation decode.
