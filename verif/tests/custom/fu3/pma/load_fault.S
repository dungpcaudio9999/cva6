# FU3 CVA6 directed test: data-access exceptions must be precise on the
# cacheless AXI bridge.
#
# The load unit kills a granted load when translation/PMP reports an
# exception, and expects the response for that killed request in the same
# cycle to retire the exception. The bridge must neither drop the exception
# nor turn the killed load into a real bus read.
#
#  1. Locked PMP entry 0 (applies to M-mode) denies R/W/X on the 4 KiB device
#     page 0x4000_0000 (AES window). lw must trap with mcause 5 and must not
#     write its destination register; sw must trap with mcause 7.
#  2. Locked PMP entry 1 denies the unused CVA6_ISRAM page 0x0001_E000, which
#     answers with AXI OKAY: lw must still trap with mcause 5 (the bridge must
#     not return the memory data as a successful load).
#  3. A misaligned lw on DSRAM must trap with mcause 4.
#
# The harness device checker prints device_axi_reads/device_axi_writes; both
# must be 0 for this test.
#
# Exit codes: 0 pass, 1 PMP load not trapped, 3 PMP store not trapped,
#             4 misaligned load not trapped, 5 rd written by a
#             faulting load, 6 unexpected trap cause, 7 PMP load on
#             OKAY memory not trapped.

  .globl main
main:
  la t0, fu3_trap
  csrw mtvec, t0

  # pmpaddr0: NAPOT 4 KiB at 0x4000_0000; pmpcfg0[7:0] = L | NAPOT, no RWX.
  li t0, 0x100001FF
  csrw pmpaddr0, t0
  # pmpaddr1: NAPOT 4 KiB at 0x0001_E000 (unused top of the 60 KiB image).
  li t0, 0x000079FF
  csrw pmpaddr1, t0
  li t0, 0x9898
  csrw pmpcfg0, t0

  li s6, 0x40000000

  # 1a. PMP-denied load.
  li s2, 0                  # trap counter
  li s3, 5                  # expected mcause
  li t1, 0x5A5A5A5A         # destination sentinel
  .option push
  .option norvc
  lw t1, 0(s6)
  .option pop
  beqz s2, pmp_ld_no_trap
  li t2, 0x5A5A5A5A
  bne t1, t2, rd_written

  # 1b. PMP-denied store.
  li s2, 0
  li s3, 7
  .option push
  .option norvc
  sw zero, 0(s6)
  .option pop
  beqz s2, pmp_st_no_trap

  # 2. PMP-denied load on memory that would answer OKAY.
  li s2, 0
  li s3, 5
  li t0, 0x0001E000
  li t1, 0x5A5A5A5A
  .option push
  .option norvc
  lw t1, 0(t0)
  .option pop
  beqz s2, pmp_mem_no_trap
  li t2, 0x5A5A5A5A
  bne t1, t2, rd_written

  # 3. Misaligned load on DSRAM.
  li s2, 0
  li s3, 4
  la t0, scratch
  .option push
  .option norvc
  lw t1, 1(t0)
  .option pop
  beqz s2, mis_no_trap

  li a0, 0
  jal exit

pmp_ld_no_trap:
  li a0, 1
  j fail
pmp_st_no_trap:
  li a0, 3
  j fail
mis_no_trap:
  li a0, 4
  j fail
pmp_mem_no_trap:
  li a0, 7
  j fail
rd_written:
  li a0, 5
fail:
  jal exit

  .balign 4
fu3_trap:
  csrr t0, mcause
  bne t0, s3, trap_bad
  addi s2, s2, 1
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
  mret
trap_bad:
  li a0, 6
  jal exit

  .section .data
  .balign 8
scratch:
  .word 0x11223344
  .word 0x55667788
