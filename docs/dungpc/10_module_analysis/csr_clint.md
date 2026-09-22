# CSR regfile và CLINT

Nguồn [CSR](../../../core/csr_regfile.sv#L274), [CLINT](../../../corev_apu/clint/clint.sv#L38); FLOW-06/07. Không ghép hai block thành cùng một register file: CLINT là MMIO platform timer trên AXI boundary, CSR là instruction-visible state trong CPU.

## State và priority

CSR giữ privilege, status/interrupt masks/pending, trap vectors/epcs/causes, satp, FP control, debug và WFI. Reset đưa privilege=M, mip/mie=0, satp=0, WFI=0; mtvec=0 tại reset rồi boot+0x40 bằng init flag. Outputs/read views có legal/derived fields nên reset whole-word statement không thay thế field-level read semantics.

CSR writes đi qua access permission/op mask/legalization; trap/return sửa privilege stack; machine pending bits được gán từ IRQ inputs sau write cases. SEIP còn có combinational merge vào CSR read. Do đó không có một ưu tiên set/clear áp dụng đồng loạt mọi field.

CLINT giữ `mtime_q[63:0]`, `mtimecmp_q[NR_CORES][63:0]`, `msip_q[NR_CORES]`. Với NR_CORES=1, ba state reset bằng 0. Khi không reset:

```text
mtime_next = mtime + increase_timer (modulo 2^64)
if accepted internal write to mtime:
    mtime_next = wdata             // RV64 branch, thắng RTC increment
timer_irq = (mtime_q >= mtimecmp_q)
ipi = msip_q
```

`increase_timer` từ edge detector của RTC synchronized level, không phải clock mtime độc lập. Counter wrap là arithmetic RTL, chưa đo real-time accuracy. RV64 partial writes không được per-byte mask trong branch mtime/mtimecmp; supported software access width cần quyết định.

## Properties và corner cases

- **INV-CLINT-01:** Write mtime cùng increment lấy write value sau edge. Source argument SUPPORTED; testbench chưa chạy, không có SIM result.
- **INV-CLINT-02:** timer_irq tương đương unsigned comparator của state; reset-zero gây high sau reset state settled. Không đồng nghĩa CPU nhận interrupt khi mie=0.
- **INV-CSR-01:** Machine IRQ pending không bị software write xóa khi external level còn high; cần test source+CSR write simultaneous, privilege masks và trap observation.
- **INV-WFI-01:** Wake condition cùng WFI command không đưa core vào wait, theo if/else priority. Cần witness pending-enabled, raw SEIP, debug request và no-event wait.

Properties là safety/local control trong ASM-01/04; assertion/formal/SIM đều NOT-RUN. PLIC claim/complete semantics nằm ngoài nguồn hiện có, không suy từ CLINT.

**Change impact:** Sửa timer reset comparator làm thay boot IRQ visibility; đổi MTIMECMP width/partial access ảnh hưởng RV32/64 driver; đổi mip write priority ảnh hưởng masking/event retention; đổi mtvec init ảnh hưởng early trap trước firmware setup. Regression phải check write-versus-increment, reset while IRQ high, WFI races, privilege/delegation và field reserved behavior. Xem [08](../08_registers_and_interrupts.md) và OQ-05/08.
