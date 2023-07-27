.section ".text.accel"
.globl accel

accel:
	la x10, CT0
	la x11, CT0_OUT
// funct3 will have the multiple of arrays to skip from rs1 to get the output (compiler generated)
.word 0b00000000101101010100001001111111 # r1 = 10, r2 = 11, funct3 = 4 (C1)
	ret

.section ".data.input_arrays"
.align 10
.globl A1

CT0:
.rept 2
	.rept 512
		.word 0x11111111
		.word 0x11111111
	.endr
.endr

CT1:
.rept 2
	.rept 512
		.word 0x22222222
		.word 0x22222222
	.endr
.endr


RLN0:
.rept 8
	.rept 512
		.word 0x33333332
		.word 0x33333332
	.endr
.endr

RLN1:
.rept 8
	.rept 512
		.word 0x33333332
		.word 0x33333332
	.endr
.endr

CT0_OUT:
.rept 2
	.rept 512
		.word 0x00000000
		.word 0x00000000
	.endr
.endr

CT1_OUT:
.rept 2
	.rept 512
		.word 0x00000000
		.word 0x00000000
	.endr
.endr
