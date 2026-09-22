# CPU 05 — CSR, privilege, translation và PMP

## Architectural state chính

| CSR/state (địa chỉ theo `riscv_pkg`) | Reset thấy trong RTL | Software/hardware update và quan sát |
|---|---|---|
| `mstatus`, privilege | `mstatus_q=0`, `priv_lvl_q=M` [reset](../../../core/csr_regfile.sv#L2831) | CSR writes bị mask các field unsupported; trap lưu `mie→mpie`, prior mode→`mpp`; MRET khôi phục. [write](../../../core/csr_regfile.sv#L1597), [trap](../../../core/csr_regfile.sv#L2182), [return](../../../core/csr_regfile.sv#L2387). |
| `mepc`, `mcause` | 0 [reset](../../../core/csr_regfile.sv#L2853) | software read/write có alignment/mask; trap ghi PC/cause của event. [read](../../../core/csr_regfile.sv#L661), [write](../../../core/csr_regfile.sv#L1741), [trap](../../../core/csr_regfile.sv#L2188). |
| `sstatus`, `sepc`, `scause`, delegation | reset ở CSR sequential block; S enabled CFG-01 | `sstatus` là subset mask của `mstatus`; delegation quyết định M/S trap target và EPC/cause tương ứng. [S read](../../../core/csr_regfile.sv#L532), [delegation](../../../core/csr_regfile.sv#L2094). |
| `satp` | 0 / translation off [reset](../../../core/csr_regfile.sv#L2877) | mode chỉ nhận Off hoặc configured Sv39; ASID mask; S-mode TVM có thể gây illegal CSR access. [write](../../../core/csr_regfile.sv#L1436), [enable](../../../core/csr_regfile.sv#L2781). |
| `pmpcfg`, `pmpaddr` | config reset values, CFG-01 đều zero [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L117) | locked entry chặn config/address write; TOR lock có tác động entry trước. [PMP writes](../../../core/csr_regfile.sv#L1914), [PMP outputs](../../../core/csr_regfile.sv#L381). |
| `mip/mie`, `mtvec/stvec` | reset ở CSR block | IRQ input cập nhật pending, software enable/mask và trap vector select. [pending](../../../core/csr_regfile.sv#L2079), [IRQ controls](../../../core/csr_regfile.sv#L2507). |
| `dcsr/dpc`, debug mode | reset ở CSR block | breakpoint/debug request entry, return; effective privilege xuất M trong debug. [debug](../../../core/csr_regfile.sv#L2249), [privilege output](../../../core/csr_regfile.sv#L2743). |
| `mcycle/minstret`, HPM | `instret=0` [reset](../../../core/csr_regfile.sv#L2915) | update theo clock/commit ack và inhibit; [performance](cpu_08_performance_model.md). |

Đây là **inventory theo nhóm**, chưa là bảng từng CSR address/field/reset/WARL đầy đủ theo yêu cầu cuối của guide; [OQ-07](09_open_questions.md) ghi gate còn lại. Không chốt CSR privilege compliance chỉ từ `case` read/write.

## Effective privilege và protection path

Instruction fetch dùng privilege/translation control từ CSR qua I-TLB/MMU; data load/store có thể dùng MPRV và `mstatus.mpp` thay current privilege. [CSR effective data privilege](../../../core/csr_regfile.sv#L2332), [translation enable](../../../core/csr_regfile.sv#L2781). MMU có I/D TLB, shared lookup/PTW; fetch và load/store kiểm page permissions/canonical address rồi PMP trên physical access. [MMU](../../../core/cva6_mmu/cva6_mmu.sv#L179), [data permissions](../../../core/cva6_mmu/cva6_mmu.sv#L525), [LSU PMP](../../../core/load_store_unit.sv#L393). PTW đọc PTE cũng qua PMP như S-mode read; denied PTW chuyển access exception. [PTW PMP](../../../core/cva6_mmu/cva6_ptw.sv#L251), [error](../../../core/cva6_mmu/cva6_ptw.sv#L603).

Directed matrix: fetch/load/store × M/S/U × paging on/off × PMP locked/unlocked/overlap × aligned/misaligned. Ghi effective privilege, VA→PA, PTE bits, PMP match/allow, exception cause/tval và không memory request khi denied. [OQ-08](09_open_questions.md).
