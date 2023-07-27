#  mp4-cp1.s version 4.0
temp_test.s:
.align 4
.section .text
.globl _start
_start:
/*
    addi x1, x1, 4
    addi x2, x2, 5
    add x3, x1, x2
	bne x1, x2, branch
	addi x7, x7, 50
branch: 
	addi x8, x8, 19
*/

/*
	lw x1,bad
	la x10,bad
	lh x2,0(x10)
	lh x3,2(x10)

	lb x4,0(x10)
	lb x5,1(x10)
	lb x6,2(x10)
	lb x7,3(x10)
*/

	
	call test_function
	j deadloop

/*
	lw x1,threshold
	lw x2,bad

	la x10,threshold
	sh x2,2(x10)

	lw x3,threshold
*/


deadloop:
    beq x8, x8, deadloop


test_function:
    addi x11, x11, 4
    addi x12, x12, 5
    add x13, x12, x11
	ret

.section .rodata


bad:        .word 0xdeadbeef
threshold:  .word 0x12345678
