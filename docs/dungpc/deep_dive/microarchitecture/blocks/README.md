# Detailed Block Analyses

These documents apply the common analysis contract to the active CFG-01 hierarchy. Each file separates **RTL-established** behavior from behavior that remains **open** because no licensed simulator run was available.

- [Frontend](frontend.md)
- [Instruction queue](instruction_queue.md)
- [Decode and ID](decode_and_id.md)
- [Scoreboard](scoreboard.md)
- [Issue and operands](issue_and_operands.md)
- [ALU and branch](alu_and_branch.md)
- [Multiplier and divider](multiplier_divider.md)
- [FPU](fpu.md)
- [Writeback](writeback.md)
- [Commit](commit.md)
- [Controller](controller.md)
- [CSR register file](csr_regfile.md)

The common pipeline context is in [pipeline occupancy](../03_pipeline_occupancy_model.md), [register inventory](../04_pipeline_register_inventory.md), and [stall/flush matrix](../05_global_stall_flush_matrix.md).
