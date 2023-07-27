OUTPUT_ARCH( "riscv" )
ENTRY(_start)

_ram0_start = 0x00000060;

_stack_top = 0xf0000000;

SECTIONS
{

  . = _ram0_start;

  .text.swinit :
  {
    . = ALIGN(4);
    *(.text.swinit)
  }

  . = .;

  .text.swfin :
  {
    . = ALIGN(4);
    *(.text.swfin)
  }

  . = .;

  .tohost :
  {
    . = ALIGN(8);
    *(.tohost)
  }

  . = .;

  .fromhost :
  {
    . = ALIGN(8);
    *(.fromhost)
  }

  . = .;

  .text :
  {
    . = ALIGN(4);
    _text_vma_start = .;

    *(.text)
    *(.text*)

    . = ALIGN(4);
    _text_vma_end = .;
  }

  . = .;

  .data :
  {
    . = ALIGN(4);
    _data_vma_start = .;

    *(.*data*)

    . = ALIGN(4);
    _data_vma_end = .;
  }

  . = .;

  .bss :
  {
    . = ALIGN(4);
    _bss_vma_start = .;

    *(.*bss*)

    . = ALIGN(4);
    _bss_vma_end = .;
  }

  _end = .;

  /DISCARD/ :
  {
    *(.eh_frame)
    *(.riscv.attributes)
    *(.comment)
    *(.debug*)
  }
}
