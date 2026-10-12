OUTPUT_ARCH("riscv")
ENTRY(_start)

/* FU3 CVA6 RTOS v1 core-level verification map (cacheless), spec v2.0:
 * CVA6_ISRAM 0x0001_0000-0x0001_FFFF holds a 60 KiB program image and, in its
 * top 4 KiB, the CVA6 debug code (halt 0x0001_F000, exception 0x0001_F008). */
MEMORY
{
  ISRAM (rwx) : ORIGIN = 0x00010000, LENGTH = 60K
  DBG   (rx)  : ORIGIN = 0x0001F000, LENGTH = 4K
  DSRAM (rw)  : ORIGIN = 0x01000000, LENGTH = 64K
}

SECTIONS
{
  .text :
  {
    _start_text = .;
    KEEP(*(.text.init))
    *(.text .text.*)
    *(.text.startup .text.startup.*)
    *(.rodata .rodata.*)
    . = ALIGN(8);
    _end_text = .;
  } > ISRAM

  /* Optional debug-mode code placed by tests at the debug entry points. */
  .debug_code :
  {
    KEEP(*(.debug_code))
  } > DBG

  .data :
  {
    . = ALIGN(8);
    *(.data .data.*)
    *(.sdata2 .sdata2.*)
    *(.sdata .sdata.*)
    *(.gnu.linkonce.s.*)
    *(.page_table)
    *(.user_stack)
    *(.kernel_data)
    *(.kernel_stack)
  } > DSRAM

  .tohost :
  {
    . = ALIGN(64);
    KEEP(*(.tohost))
  } > DSRAM

  .uvmif :
  {
    . = ALIGN(64);
    KEEP(*(.uvmif))
  } > DSRAM

  .bss (NOLOAD) :
  {
    . = ALIGN(8);
    __global_pointer$ = . + 0x800;
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    *(.bss .bss.* COMMON)
  } > DSRAM

  .tdata :
  {
    _tdata_begin = .;
    *(.tdata .tdata.*)
    _tdata_end = .;
  } > DSRAM

  .tbss (NOLOAD) :
  {
    *(.tbss .tbss.*)
    _tbss_end = .;
  } > DSRAM

  . = ALIGN(64);
  _end = .;
  _stack_top = ORIGIN(DSRAM) + LENGTH(DSRAM);

  /DISCARD/ : { *(.comment) *(.note*) }
}

ASSERT(_end_text <= ORIGIN(ISRAM) + LENGTH(ISRAM), "FU3 ISRAM overflow")
ASSERT(_end + 0x4000 <= _stack_top, "FU3 DSRAM data/TLS/stack overflow")
