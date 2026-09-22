# 08 — CSR và ngắt

## Nguồn và boundary

CSR number lấy từ [riscv_pkg.sv](../../core/include/riscv_pkg.sv#L393), read/write/side effects từ [csr_regfile.sv](../../core/csr_regfile.sv#L410). Đây là review các register/field liên quan flow; chưa phải toàn bộ normative ISA CSR map hay register-description generation audit. PLIC/debug/peripheral field maps chưa có đủ source (OQ-08).

| CSR | Field trọng tâm | Reset/initialization trong source | Access và side effect |
|---|---|---|---|
| mstatus 0x300 | MIE/SIE, MPIE/SPIE, MPP/SPP, FS, MPRV, SUM/MXR, TVM/TW/TSR | `mstatus_q=0`; legal/read-derived bits được xử lý riêng | Mask/WARL theo write cases; trap/return sửa privilege stack; write có thể flush |
| mie 0x304 | interrupt enable bits | 0 | Masked RW theo supported IRQ; pending không biến mất chỉ vì tắt enable |
| mip 0x344 | MEIP[11], MTIP[7], MSIP[3], SEIP[9]/SSIP[1] | 0 | Machine external/timer/software overwritten từ input; S pending có masked software/read merge paths; không generic W1C |
| mtvec 0x305 | base, mode | Async reset 0; first reset-load đưa `boot_addr_i+0x40` | CFG-01 dự kiến 0x10040 khi init; mode/base writes lọc riêng |
| mepc 0x341 | exception PC | 0 | Trap capture/CSR writes; alignment handling phụ thuộc compressed support |
| mcause 0x342, mtval 0x343 | cause/interrupt indication, fault info | 0 | Hardware trap update; mtval phụ thuộc TvalEn=1 |
| satp 0x180 | MODE, ASID, PPN | 0/Bare | S-mode/TVM access guard và supported mode; translation consumers ở MMU; TLB maintenance cần SFENCE.VMA flow |
| fcsr 0x003 | fflags[4:0], frm[7:5] | 0; FS initially Off | Access bị chặn khi FP state Off; flags có hardware OR update; rounding/status writes có side effects |
| icache 0x7C0, dcache 0x7C1 | cache enable/control | cache enable=1 | Custom CSR; không là MMIO; muốn tắt cache phải review drain/flush path |
| dcsr 0x7B0 | debug controls, single-step, prv | xdebugver=4, prv=M, còn lại 0 theo struct | Debug access/entry rules; bazı unsupported fields bị hardwire; không coi raw RW toàn word |

Toàn bộ bit reserved/legal masks không liệt kê lại ở đây. Những field còn thiếu và races ngoài bảng không được mặc nhiên cho là đúng; OQ-08 yêu cầu inventory đầy đủ trước driver/ISA sign-off. Không có nguồn RAL/generated description được chứng minh là authority cho CFG-01.

## Các priority quan trọng

- **FND-CSR-01:** mtvec reset state khác trạng thái sau init. [RTL:ESTABLISHED] `mtvec_rst_load_q=1`, `mtvec_q=0` ở [reset](../../core/csr_regfile.sv#L2847); [reset-load](../../core/csr_regfile.sv#L1099) dùng **+0x40**. Comment “4 byte offset” cạnh reset không khớp literal, nên theo RTL chứ không chép comment. Support SUPPORTED/source-only.
- Machine IRQ assignments ở [2079](../../core/csr_regfile.sv#L2079) nằm sau CSR write handling: ghi mip không clear được nguồn external/timer/software đang high. Xử lý clear ở CLINT/peripheral, không chỉ xóa bit pending CSR.
- fflags hardware commit update dùng `csr_wdata_i[4:0] | fcsr_q.fflags` trong [2061](../../core/csr_regfile.sv#L2061). Simultaneous CSR write/FP commit cần kiểm tra schedule ở commit; không suy chung rằng “mọi bit HW set thắng SW clear” cho mọi CSR.
- WFI wake branch đứng trước branch đặt WFI: pending enabled IRQ, debug request hoặc SEIP đánh thức ưu tiên hơn entering wait. Không đồng nhất wake với trap taken.

## CLINT: field và semantics trực tiếp từ RTL

Nguồn [clint.sv](../../corev_apu/clint/clint.sv#L38), NR_CORES=1 ở harness. Offsets dưới đây cộng `0x02000000`.

| Offset | Register | Field/access/reset | Cập nhật/side effect |
|---|---|---|---|
| 0x0000 | msip hart 0 | bit 0, RW, reset 0 | `en && we` gán từ wdata; output ipi=msip_q; không read-clear |
| 0x4000 | mtimecmp hart 0 | 64-bit RW, reset 0 | RV64 write gán full wdata; compare cập nhật IRQ level |
| 0xBFF8 | mtime | 64-bit RW, reset 0 | RTC edge increment; SW write cùng cycle có lexical priority; read không clear |

Đối với RV64, implementation write của mtime/mtimecmp không mask từng byte theo be trong nhánh này; nên chưa hứa partial-write semantics. RV32 xử lý hai nửa theo nhánh riêng ngoài CFG-01. Decode dùng inclusive `case inside` range; các offset biên/reserved cần directed test, không tự mở rộng hợp đồng driver từ kích thước region.

**FND-IRQ-01:** `timer_irq=(mtime_q>=mtimecmp_q)` và cả hai reset 0 ⇒ comparator high tại state reset settled; CPU `mie=0` nên không đồng nghĩa lập tức trap. **Support:** SUPPORTED; [irq_gen/reset](../../corev_apu/clint/clint.sv#L185). [RTL:ESTABLISHED] Muốn deassert level, software đặt compare lớn hơn current time; nếu thời gian đã vượt compare, viết lại giá trị nhỏ không clear.

## Đường IRQ tới core

- CLINT msip → `ipi_i` → mip MSIP; RTC → sync+edge → mtime/compare → `time_irq_i` → mip MTIP.
- `ariane_peripherals.irq_sources[0]` UART; [1] SPI; [2] Ethernet branch; [6:3] timer; [29:7] zero. PLIC đưa hai target outputs vào core `irq_i[1:0]` (machine/supervisor boundary).
- Trong Verilator harness, InclUART=0 nên source[0]=0 và mock UART phục vụ console; SPI/Ethernet cũng disabled. Không suy console output chứng minh PLIC UART IRQ.
- PLIC source **vector index** chưa được chuyển thành software interrupt ID nếu chưa đọc `plic_top`/gateway: IP chưa initialized. Claim/complete priority/mask/race và clear-before-complete sequence còn UNKNOWN, OQ-08.
- Core privilege/global enable/delegation quyết định interrupt delivery; decode/ex metadata đi tới commit, CSR cập nhật trap context, controller flush, frontend chọn vector. `MIP pending`, `MIE enabled`, `WFI wake` và `trap committed` là bốn trạng thái khác nhau.

Không có waveform kiểm tra masked event retention, simultaneous set/clear, reset khi IRQ high hoặc debug trong WFI. Gate LIMITED; test plan ở [11](11_verification_analysis.md).
