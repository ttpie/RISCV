	.file	"diag_loop.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_zmmul1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	lui	a5,%hi(op_n)
	lw	a3,%lo(op_n)(a5)
	li	a4,-1431654400
	li	a5,-2147483648
	addi	a4,a4,-1375
	sw	a4,16(a5)
	li	a5,1
	bleu	a3,a5,.L4
	li	a2,-2147483648
	addi	a2,a2,4
	li	a4,0
	li	a1,-2147483648
.L3:
	add	a4,a4,a5
	sw	a5,0(a1)
	sw	a4,0(a2)
	addi	a5,a5,1
	bne	a3,a5,.L3
.L2:
	li	a5,-2147483648
	sw	a4,8(a5)
	li	a4,1431654400
	sw	a3,12(a5)
	addi	a4,a4,1361
	sw	a4,16(a5)
	li	a0,0
	ret
.L4:
	li	a4,0
	j	.L2
	.size	main, .-main
	.globl	op_n
	.section	.sdata,"aw"
	.align	2
	.type	op_n, @object
	.size	op_n, 4
op_n:
	.word	5
	.ident	"GCC: (g1b306039a) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
