# FU3 CVA6 debug-entry directed test (spec v2.0).
#
# CVA6 debug code lives in the top 4 KiB of CVA6_ISRAM:
#   halt entry      = 0x0001_F000 (DmBaseAddress + HaltAddress)
#   exception entry = 0x0001_F008 (DmBaseAddress + ExceptionAddress)
#
# The FU3 testharness raises debug_req when mscratch holds 0xFD0B_0001
# (see CVA6_RTOS_MEM_MAP in ariane_testharness.sv). The halt handler logs its
# state, then executes an illegal instruction in Debug Mode, which must vector
# to the exception entry. The exception handler resumes with dret.
#
# Exit codes: 0 pass, 1 debug entry timeout, 2 unexpected M-mode trap,
#             3 debug entries not linked at spec addresses, 4 halt entry not
#             taken, 5 exception entry not taken, 6 dcsr.cause != haltreq,
#             7 dpc outside the polling window, 8 handler PC mismatch.

#define FU3_DEBUG_REQ_MAGIC 0xFD0B0001

  .globl main
main:
  la t0, unexpected_trap
  csrw mtvec, t0

  # The linker must place the handlers at the spec entry addresses.
  la t0, dbg_halt_entry
  li t1, 0x0001F000
  bne t0, t1, bad_link
  la t0, dbg_exc_entry
  li t1, 0x0001F008
  bne t0, t1, bad_link

  la s0, dbg_log
  li t0, FU3_DEBUG_REQ_MAGIC
  csrw mscratch, t0
dbg_window_start:
  li s1, 20000
poll:
  lw t1, 20(s0)            # exception-entry flag, set last
  bnez t1, poll_done
  addi s1, s1, -1
  bnez s1, poll
dbg_window_end:
  li a0, 1
  j fail

poll_done:
  csrw mscratch, zero

  lw t1, 12(s0)            # halt-entry flag
  beqz t1, no_halt
  lw t1, 20(s0)
  beqz t1, no_exc

  lw t1, 4(s0)             # dcsr.cause[8:6] must be 3 (haltreq)
  srli t1, t1, 6
  andi t1, t1, 7
  li t2, 3
  bne t1, t2, bad_cause

  lw t1, 8(s0)             # dpc inside [dbg_window_start, dbg_window_end)
  la t2, dbg_window_start
  bltu t1, t2, bad_dpc
  la t2, dbg_window_end
  bgeu t1, t2, bad_dpc

  lw t1, 0(s0)             # PCs recorded by the handlers
  la t2, dbg_halt_pc
  bne t1, t2, bad_pc
  lw t1, 16(s0)
  la t2, dbg_exc_pc
  bne t1, t2, bad_pc

  li a0, 0
  jal exit

unexpected_trap:
  li a0, 2
  j fail
bad_link:
  li a0, 3
  j fail
no_halt:
  li a0, 4
  j fail
no_exc:
  li a0, 5
  j fail
bad_cause:
  li a0, 6
  j fail
bad_dpc:
  li a0, 7
  j fail
bad_pc:
  li a0, 8
fail:
  jal exit

# ---------------------------------------------------------------------------
# Debug-mode code, linked into the DBG region (0x0001_F000) by link.ld.
# ---------------------------------------------------------------------------
  .section .debug_code,"ax",@progbits
  .option push
  .option norvc
  .globl dbg_halt_entry
dbg_halt_entry:            # 0x0001_F000
  j dbg_halt
  nop
  .globl dbg_exc_entry
dbg_exc_entry:             # 0x0001_F008
  j dbg_exc

dbg_halt:
  csrw dscratch0, t0
  csrw dscratch1, t1
  la t0, dbg_log
dbg_halt_pc:
  auipc t1, 0
  sw t1, 0(t0)
  csrr t1, dcsr
  sw t1, 4(t0)
  csrr t1, dpc
  sw t1, 8(t0)
  li t1, 1
  sw t1, 12(t0)
  .word 0x00000000         # illegal in Debug Mode -> exception entry

dbg_exc:
dbg_exc_pc:
  auipc t1, 0              # t0 still points at dbg_log
  sw t1, 16(t0)
  li t1, 1
  sw t1, 20(t0)
  csrr t1, dscratch1
  csrr t0, dscratch0
  dret
  .option pop

  .section .data
  .balign 4
dbg_log:
  .word 0                  # 0: PC in halt handler
  .word 0                  # 4: dcsr
  .word 0                  # 8: dpc
  .word 0                  # 12: halt-entry flag
  .word 0                  # 16: PC in exception handler
  .word 0                  # 20: exception-entry flag
