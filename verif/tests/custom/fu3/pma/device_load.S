# FU3 CVA6 PMA directed test: loads to the spec v2.0 device windows.
#
# Each device load is issued right behind a long-latency divide, so it is
# not yet the oldest instruction when it reaches the load unit. Device
# windows are non-idempotent: the load must wait until commit time before
# going to the bus. The CVA6_RTOS_MEM_MAP checker in ariane_testharness.sv
# compares every committed load with the spec device map and stops the
# simulation with $fatal on a mismatch or a speculative device load; it
# prints "[FU3_NI_CHECK] ... device_loads=N ni_hold_cycles=M" at the end.
#
# Most device windows are unmapped in the core testharness and answer with
# an AXI error. This CVA6 release reports a load bus error as mcause 19
# (HARDWARE_ERROR) rather than 5 (load access fault); both are accepted and
# the faulting load is skipped.
#
# Exit codes: 0 pass, 2 unexpected trap cause, 3 divide result corrupted.

  .globl main
main:
  la t0, fu3_trap
  csrw mtvec, t0

  la s4, dev_addrs
  la s5, dev_addrs_end
  li t4, 0x7FFFFFFF        # 31 quotient bits: the slowest serial divide
  li t5, 1
next_dev:
  lw s0, 0(s4)
  add t2, s0, zero         # in-order issue: wait until s0 is available
  .option push
  .option norvc
  div t3, t4, t5           # older, long-latency instruction
  lw t1, 0(s0)             # device load must wait for commit
  .option pop
  bne t3, t4, bad_div
  addi s4, s4, 4
  bltu s4, s5, next_dev

  # Idempotent control: the same pattern on DSRAM must not wait.
  la s0, scratch
  .option push
  .option norvc
  div t3, t4, t5
  lw t1, 0(s0)
  .option pop

  li a0, 0
  jal exit

bad_div:
  li a0, 3
  jal exit

  .balign 4
fu3_trap:
  csrr t0, mcause
  li t1, 5                 # load access fault
  beq t0, t1, trap_skip
  li t1, 19                # CVA6 HARDWARE_ERROR: AXI error on a load
  bne t0, t1, trap_bad
trap_skip:
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
  mret
trap_bad:
  li a0, 2
  jal exit

  .section .rodata
  .balign 4
dev_addrs:
  .word 0x1A110000         # Ibex Debug Module
  .word 0x1A110FFC
  .word 0x30100000         # EDHOC OSCORE
  .word 0x3010FFFC
  .word 0x40000000         # AES
  .word 0x4000FFFC
  .word 0x40100000         # PLIC
  .word 0x4010FFFC
  .word 0x44000000         # PERIBUS_0 first window (AP_QSPIC)
  .word 0x440F0000         # PERIBUS_0 last window (GPIOC)
  .word 0x50010000         # PERIBUS_1 first window (CRM)
  .word 0x50100000         # PERIBUS_1 last window
dev_addrs_end:

  .section .data
  .balign 4
scratch:
  .word 0x12345678
