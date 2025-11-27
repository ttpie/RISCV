	.file	"test_rv32im_v3.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_zmmul1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	results
	.bss
	.align	2
	.type	results, @object
	.size	results, 64
results:
	.zero	64
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	li	a5,12288
	addi	a5,a5,57
	sw	a5,-24(s0)
	li	a5,-8192
	addi	a5,a5,1403
	sw	a5,-28(s0)
	li	a5,42
	sw	a5,-32(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	add	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,0(a5)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	sub	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,4(a5)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	and	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,8(a5)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	or	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,12(a5)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	xor	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,16(a5)
	lw	a5,-24(s0)
	slli	a4,a5,3
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,20(a5)
	lw	a5,-24(s0)
	srai	a4,a5,2
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,24(a5)
	lw	a5,-28(s0)
	srai	a4,a5,2
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,28(a5)
	lw	a5,-28(s0)
	srai	a4,a5,2
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,32(a5)
	lw	a5,-28(s0)
	srai	a4,a5,2
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,36(a5)
	lw	a5,-24(s0)
	addi	a5,a5,100
	xori	a4,a5,85
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,40(a5)
	lw	a5,-28(s0)
	andi	a5,a5,255
	ori	a4,a5,240
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,44(a5)
	lw	a4,-24(s0)
	lw	a5,-32(s0)
	mul	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,48(a5)
	lw	a4,-24(s0)
	lw	a5,-32(s0)
	div	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,52(a5)
	lw	a4,-24(s0)
	lw	a5,-32(s0)
	rem	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,56(a5)
	lw	a4,-28(s0)
	lw	a5,-32(s0)
	div	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,60(a5)
	sw	zero,-20(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	ble	a4,a5,.L2
	li	a5,1
	sw	a5,-20(s0)
	j	.L3
.L2:
	li	a5,2
	sw	a5,-20(s0)
.L3:
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	lw	a4,0(a5)
	lw	a5,-20(s0)
	add	a4,a4,a5
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	sw	a4,0(a5)
	lui	a5,%hi(results)
	addi	a5,a5,%lo(results)
	lw	a5,0(a5)
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g1b306039a) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
