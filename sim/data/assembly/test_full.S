	.file	"test_full.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	sink
	.section	.sbss,"aw",@nobits
	.align	2
	.type	sink, @object
	.size	sink, 4
sink:
	.zero	4
	.text
	.align	2
	.globl	add_func
	.type	add_func, @function
add_func:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	sw	a1,-24(s0)
	lw	a4,-20(s0)
	lw	a5,-24(s0)
	add	a5,a4,a5
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	add_func, .-add_func
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-96
	sw	ra,92(sp)
	sw	s0,88(sp)
	addi	s0,sp,96
	li	a5,1234
	sw	a5,-24(s0)
	li	a5,4096
	addi	a5,a5,1582
	sw	a5,-28(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	add	a5,a4,a5
	sw	a5,-20(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	sub	a5,a4,a5
	sw	a5,-20(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	and	a5,a4,a5
	sw	a5,-20(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	or	a5,a4,a5
	sw	a5,-20(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	slli	a5,a5,2
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	srai	a5,a5,2
	sw	a5,-20(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	slt	a5,a4,a5
	andi	a5,a5,0xff
	sw	a5,-20(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	sltu	a5,a4,a5
	andi	a5,a5,0xff
	sw	a5,-20(s0)
	lw	a5,-28(s0)
	srai	a5,a5,31
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	addi	a5,a5,100
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	andi	a5,a5,85
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	ori	a5,a5,170
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	xori	a5,a5,255
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	slti	a5,a5,2000
	andi	a5,a5,0xff
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	sltiu	a5,a5,2000
	andi	a5,a5,0xff
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	slli	a5,a5,3
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	srai	a5,a5,3
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	srai	a5,a5,7
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	andi	a5,a5,0xff
	sb	a5,-40(s0)
	lw	a5,-20(s0)
	slli	a5,a5,16
	srai	a5,a5,16
	sh	a5,-56(s0)
	lw	a5,-20(s0)
	sw	a5,-88(s0)
	lbu	a5,-40(s0)
	sw	a5,-20(s0)
	lh	a5,-56(s0)
	sw	a5,-20(s0)
	lw	a5,-88(s0)
	sw	a5,-20(s0)
	lbu	a5,-40(s0)
	sw	a5,-20(s0)
	lh	a5,-56(s0)
	slli	a5,a5,16
	srli	a5,a5,16
	sw	a5,-20(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	bne	a4,a5,.L4
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L4:
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	beq	a4,a5,.L5
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
.L5:
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	bge	a4,a5,.L6
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L6:
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	blt	a4,a5,.L7
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
.L7:
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	bgeu	a4,a5,.L8
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L8:
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	bltu	a4,a5,.L9
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
.L9:
	lw	a1,-28(s0)
	lw	a0,-24(s0)
	call	add_func
	sw	a0,-20(s0)
	li	a5,305418240
	addi	a5,a5,1656
	sw	a5,-32(s0)
 #APP
# 106 "./sim/data/code_c/test_full.c" 1
	ecall
# 0 "" 2
# 107 "./sim/data/code_c/test_full.c" 1
	ebreak
# 0 "" 2
 #NO_APP
	lw	a4,-20(s0)
	lw	a5,-32(s0)
	add	a4,a4,a5
	lui	a5,%hi(sink)
	sw	a4,%lo(sink)(a5)
	lui	a5,%hi(sink)
	lw	a5,%lo(sink)(a5)
	mv	a0,a5
	lw	ra,92(sp)
	lw	s0,88(sp)
	addi	sp,sp,96
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g1b306039a) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
