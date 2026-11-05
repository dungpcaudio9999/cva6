# FU3 CVA6 PMA directed test: instruction fetch outside the executable regions.
#
# FU3 spec v2.3 allows CVA6 to execute only from CVA6_ISRAM
# (0x0001_0000-0x0004_0FFF). Every target below must raise an instruction
# access fault (mcause = 1) with mepc equal to the target,
# before any bus access is made.
#
# Positive controls: code linked in ISRAM runs, and code written at the end of
# the 192 KiB program image and at the end of the 4 KiB debug-code area runs.
#
# Exit codes: 0 pass, 1 no trap taken, 2 wrong mcause, 3 wrong mepc,
#             4 call into ISRAM failed, 5 call to written ISRAM code failed.

  .globl main
main:
  la t0, fu3_trap
  csrw mtvec, t0

  la s4, targets
  la s5, targets_end
next_target:
  lw s0, 0(s4)            # expected faulting PC
  la s1, resume           # where the handler returns to
  li s2, 0                # trap-seen flag
  jalr zero, 0(s0)        # must fault on fetch
  li a0, 1                # fell through: no trap
  j fail
resume:
  beqz s2, no_trap
  addi s4, s4, 4
  bltu s4, s5, next_target

  # Positive control: executing inside CVA6_ISRAM still works.
  li a0, 0
  jal isram_func
  li t0, 0x5a
  bne a0, t0, isram_bad

  # Write "li a0, 0x5a; ret" at the top of each executable ISRAM area and call it.
  la s4, exec_ok
  la s5, exec_ok_end
next_exec:
  lw s0, 0(s4)
  li t0, 0x05a00513       # addi a0, zero, 0x5a
  sw t0, 0(s0)
  li t0, 0x00008067       # jalr zero, 0(ra)
  sw t0, 4(s0)
  fence.i
  li a0, 0
  jalr ra, 0(s0)
  li t0, 0x5a
  bne a0, t0, exec_bad
  addi s4, s4, 4
  bltu s4, s5, next_exec

  li a0, 0
  jal exit

no_trap:
  li a0, 1
  j fail
isram_bad:
  li a0, 4
  j fail
exec_bad:
  li a0, 5
fail:
  jal exit

isram_func:
  li a0, 0x5a
  ret

  .balign 4
fu3_trap:
  csrr t0, mcause
  li t1, 1                # instruction access fault
  bne t0, t1, trap_bad_cause
  csrr t0, mepc
  bne t0, s0, trap_bad_epc
  li s2, 1
  csrw mepc, s1
  mret
trap_bad_cause:
  li a0, 2
  jal exit
trap_bad_epc:
  li a0, 3
  jal exit

  .section .rodata
  .balign 4
targets:
  .word 0x00000000        # Ibex-only boot ROM
  .word 0x00000FFC        # boot ROM, last word
  .word 0x00001800        # former CVA6 debug window (reserved)
  .word 0x0000FFFC        # reserved, just below CVA6_ISRAM
  .word 0x00041000        # reserved, just past the CVA6 debug code
  .word 0x0004FFFC        # reserved, just below IBEX_ISRAM
  .word 0x00050000        # IBEX_ISRAM
  .word 0x00060000        # IBEX_ISRAM debug code
  .word 0x01000000        # DSRAM (non-executable)
  .word 0x0103FFFC        # DSRAM, last word
  .word 0x1A110000        # Ibex Debug Module aperture
  .word 0x30000000        # QSPI XIP base (not executable)
  .word 0x30FFFFFC        # QSPI XIP, last word
  .word 0x31000000        # reserved gap
  .word 0x31010000        # EDHOC OSCORE
  .word 0x40100000        # PLIC
  .word 0x44000000        # PERIBUS_0
  .word 0x50010000        # PERIBUS_1
  .word 0x60000000        # HyperRAM (data-only)
  .word 0x61FFFFFC        # HyperRAM, last word
targets_end:

exec_ok:
  .word 0x0003FFF8        # last 8 bytes of the 192 KiB program image
  .word 0x00040FF8        # last 8 bytes of the 4 KiB debug-code area
exec_ok_end:
