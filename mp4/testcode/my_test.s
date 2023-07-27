my_test.s:
.align 4
.section .text
.globl _start

    # Note that one/two/eight are data labels
    auipc x7, 8         # X7 <= PC + 8
    la x20,result
    la x1,bad
    lh x2,2(x1)
    lw x5,bad
    sb x2,0(x20)
    lh x2,0(x1)
    lb x2,0(x1)
    lb x2,1(x1)
    lb x2,2(x1)
    lb x2,3(x1)
    la x3,threshold
    sb x5,0(x3)
    sb x2,1(x3)
    sb x2,2(x3)
    sb x2,3(x3)
    sh x2,0(x3)
    sb x2,2(x3)
    sh x2,0(x3)
    sh x2,2(x3)
    lw x8, good         # X8 <= 0x600d600d
    la x10, result      # X10 <= Addr[result]
    sw x8, 0(x10)       # [Result] <= 0x600d600d
    lw x9, result       # X9 <= [Result]
    bne x8, x9, deadend # PC <= bad if x8 != x9
halt:    
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop



.section .rodata


bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x12345678
good:       .word 0x123467F4
one:        .word 0x01
