.section ".text.swinit"
.globl _start
_start:
    .cfi_startproc
    .cfi_undefined ra

_initbss:
    la t1, _bss_vma_start
    la t2, _bss_vma_end
    beq t1, t2, _setup
_initbss_loop:
    sw x0, 0(t1)
    addi t1, t1, 4
    bltu t1, t2, _initbss_loop

_setup:
    # .option push
    # .option norelax
    # la gp, __global_pointer$
    # .option pop
    la sp, _stack_top
    add s0, sp, zero
    call accel
    li  t0, 1
    la  t1, tohost
    sw  t0, 0(t1)
    sw  x0, 4(t1)
    call _fini
    nop
    nop
    .cfi_endproc

.section ".text.swfin"
.globl _fini
_fini:
    .cfi_startproc
    beq zero, zero, _fini
    nop
    nop
    .cfi_endproc


.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
