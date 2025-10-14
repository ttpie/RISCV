ENTRY(_start)

SECTIONS
{
  /* Code section */
  . = 0x80000000;
  .text : { *(.text*) }

  /* Data section - đặt sau vùng code */
  . = 0x80001000;
  .data : { *(.data*) }
  .sdata : { *(.sdata*) }

  /* Read-only data */
  .rodata : { *(.rodata*) }

  /* BSS section */
  . = ALIGN(4);
  .bss : { *(.bss*) *(COMMON) }
}

