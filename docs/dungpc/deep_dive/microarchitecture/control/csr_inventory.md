# CSR Inventory for CFG-01

**Evidence level:** RTL-established inventory. Reset and update rules refer to the central read/update/sequential blocks in [csr_regfile](../../../../../core/csr_regfile.sv#L412).

Legend: **SW** is a legal CSR instruction update; **HW** is a trap, interrupt, return, counter, FP, debug, or external update. Unimplemented fields read zero; writes are masked/WARL by the typed next-state assignment. An illegal address, insufficient privilege, read-only write, or disabled feature produces an illegal-instruction exception.

| CSR group | Addresses / names | Reset | Privilege and implemented behavior | Update priority / side effects |
|---|---|---|---|---|
| Machine identity/ISA | `mvendorid`, `marchid`, `mimpid`, `mhartid`, `misa` | configured constants | M read-only; `misa` reports CFG-01 A/B/C/D/F/I/M/S/U and supported Z-related integration | writes illegal or ignored per decode; no state side effect. |
| Machine status | `mstatus`, `mstatush` | 0 | M; implemented interrupt stack, MPP, MPRV, SUM, MXR, FS, TVM/TW/TSR, endianness fields as configured | trap/return HW updates override conflicting ordinary state according to `csr_update`. |
| Machine trap setup | `medeleg`, `mideleg`, `mie`, `mtvec`, `mcounteren` | 0; `mtvec` boot-loaded | M; delegation and interrupt masks are bit-masked, vector mode WARL | affects trap target/eligibility immediately after commit restart. |
| Machine trap handling | `mscratch`, `mepc`, `mcause`, `mtval`, `mip` | 0 | M; EPC alignment/WARL; pending bits combine SW state and external IRQ inputs | accepted trap HW capture has priority; `mip` external portions are not freely writable. |
| Machine counters | `mcycle`, `minstret`, `mhpmcounter3..`, high halves where applicable | 0 | M; six HPM counters selected, inhibition through `mcountinhibit` | HW increment plus SW write priority is encoded in counter module/update logic; retirement drives `minstret`. |
| Counter controls | `mcountinhibit`, `mhpmevent3..` | 0 | M; implemented counters only | changes subsequent event counting. |
| Supervisor status | `sstatus` | masked view of `mstatus` | S; fields limited by `SMODE_STATUS_READ_MASK` | aliases selected `mstatus` fields. |
| Supervisor trap setup | `sie`, `stvec`, `scounteren` | 0 | S; interrupt bits limited by delegation, vector mode WARL | `sie` aliases delegated `mie` bits. |
| Supervisor trap handling | `sscratch`, `sepc`, `scause`, `stval`, `sip` | 0 | S; EPC alignment; pending view limited by delegation | delegated trap HW captures; `sip` combines external SEIP on read. |
| Address translation | `satp` | 0/Bare | S; Sv39 mode, ASID, root PPN WARL | legal write changes translation context and requests pipeline serialization/flush. |
| Floating point | `fflags`, `frm`, `fcsr` | 0 | U-visible when FP state permitted | committed FP flags OR/update state; CSR write and HW flag collision priority follows `csr_update`. |
| Counters visible below M | `cycle`, `time`, `instret`, `hpmcounter*` | derived counters | S/U reads gated by `mcounteren/scounteren` | read-only; denied access is illegal instruction. |
| Debug | `dcsr`, `dpc`, `dscratch0`, `dscratch1` | DCSR version 4/prv=M; others 0 | debug mode only | debug entry captures cause/prv/DPC; DRET consumes state. |
| PMP config | `pmpcfg0..`, `pmpaddr0..7` | 0 | M; eight entries, lock and address-mode semantics | locked entries reject later SW changes until reset. |
| Cache controls | implementation-specific I/D cache and acceleration CSRs | I/D cache enabled; accelerator disabled | M, masks from config | committed changes can request pipeline restart; disabled feature fields read fixed values. |

## Update priority method

For any collision, use the last assignment to the corresponding `_d` field in `csr_update`, followed by the sequential sampling at [CSR registers](../../../../../core/csr_regfile.sv#L2830). The most consequential collision classes are:

- accepted trap versus SW write to EPC/cause/status;
- MRET/SRET/DRET versus SW status write;
- external interrupt pending versus SW `mip/sip` change;
- FP completion flags versus SW `fflags/fcsr` write;
- counter increment versus SW counter write.

These classes require directed tests because the table summarizes fields rather than reproducing the complete 1,800-line next-state block.

## Inactive CSR families

Hypervisor/virtual supervisor CSRs, vector CSRs, Zcmt JVT state, CBO controls, and trigger CSRs are inactive or read as fixed/illegal according to CFG-01 feature gates. Their source branches compile but are outside the selected architectural state.
