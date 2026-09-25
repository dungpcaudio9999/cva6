# Memory Microarchitecture

The memory analysis tracks separate acceptance, ownership, architectural completion, external completion, error, flush, and recovery points.

- [Load unit FSM](load_unit_fsm.md)
- [Store unit FSM](store_unit_fsm.md)
- [Store ownership](store_ownership_model.md)
- [MMU, TLB, and PTW](mmu_tlb_ptw.md)
- [PMP checks](pmp_checks.md)
- [Instruction cache](icache.md)
- [Write-through D-cache](wt_dcache.md)
- [Write buffer](write_buffer.md)
- [AXI transactions](axi_transactions.md)
- [Fences and ordering](fence_and_ordering.md)

All descriptions target the active WT cache path in CFG-01. HPDCache and standard write-back cache modules are outside this configuration.
