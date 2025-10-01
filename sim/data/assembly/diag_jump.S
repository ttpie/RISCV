	.file	"diag_jump.c"
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
	li	a5,-2147483648
	sw	zero,20(a5)
	li	a5,-2147483648
	sw	zero,16(a5)
	li	a5,-2147483648
	sw	zero,12(a5)
	li	a5,-2147483648
	sw	zero,8(a5)
	li	a5,-2147483648
	sw	zero,4(a5)
	li	a2,-2147483648
	sw	zero,0(a2)
	sw	zero,28(a2)
	li	a4,-1432289280
	sw	zero,0(a2)
	addi	a4,a4,1
	sw	a4,28(a2)
	sw	a4,0(a2)
	lui	a4,%hi(g_one)
	lw	a4,%lo(g_one)(a4)
	addi	a5,a5,4
	bne	a4,zero,.L2
	li	a4,-1160773632
	sw	a4,0(a5)
	addi	a3,a4,1
	sw	a3,0(a5)
	addi	a4,a4,2
	sw	a4,0(a5)
.L2:
	li	a4,1431502848
	li	a5,-2147483648
	addi	a4,a4,3
	li	a3,1431371776
	sw	a4,4(a5)
	addi	a3,a3,1
	li	a4,-2147483648
	sw	a3,28(a4)
	li	a5,-1432223744
	sw	a3,0(a4)
	addi	a5,a5,2
	sw	a5,28(a4)
	sw	a5,0(a4)
	lui	a5,%hi(g_flag)
	lw	a5,%lo(g_flag)(a5)
	mv	a2,a4
	beq	a5,zero,.L3
	li	a4,572653568
	addi	a4,a4,2
	sw	a4,8(a2)
.L4:
	li	a3,1431437312
	li	a5,-2147483648
	addi	a3,a3,2
	sw	a3,28(a5)
	sw	a3,0(a5)
	li	a3,-1432158208
	addi	a3,a3,3
	sw	a3,28(a5)
	li	a2,305418240
	sw	a3,0(a5)
	addi	a2,a2,1656
	sw	a2,16(a5)
	lw	a1,16(a5)
	li	a3,1431502848
	addi	a3,a3,3
	sw	a1,12(a5)
	sw	a3,28(a5)
	sw	a3,0(a5)
	li	a3,-1432092672
	addi	a3,a3,4
	sw	a3,28(a5)
	sw	a3,0(a5)
	li	a1,3
	li	a2,1431568384
	sw	a1,20(a5)
	addi	a2,a2,4
	sw	a2,28(a5)
	li	a3,-559067136
	sw	a2,0(a5)
	addi	a3,a3,256
	sw	a3,28(a5)
	sw	a3,0(a5)
	li	a0,0
	ret
.L3:
	li	a4,572719104
	li	a5,-2147483648
	addi	a4,a4,-16
	sw	a4,8(a5)
	j	.L4
	.size	main, .-main
	.section	.sdata,"aw"
	.align	2
	.type	g_flag, @object
	.size	g_flag, 4
g_flag:
	.word	1
	.type	g_one, @object
	.size	g_one, 4
g_one:
	.word	1
	.ident	"GCC: (g1b306039a) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
