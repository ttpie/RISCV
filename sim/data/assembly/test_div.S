	.file	"test_div.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_zmmul1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	a_signed
	.data
	.align	2
	.type	a_signed, @object
	.size	a_signed, 28
a_signed:
	.word	123456
	.word	-123456
	.word	100
	.word	-100
	.word	2147483647
	.word	-2147483648
	.word	0
	.globl	b_signed
	.align	2
	.type	b_signed, @object
	.size	b_signed, 28
b_signed:
	.word	1
	.word	2
	.word	-3
	.word	5
	.word	-7
	.word	0
	.word	9
	.globl	a_unsigned
	.align	2
	.type	a_unsigned, @object
	.size	a_unsigned, 28
a_unsigned:
	.word	0
	.word	1
	.word	100
	.word	-1
	.word	2147483647
	.word	-2147483648
	.word	12345
	.globl	b_unsigned
	.align	2
	.type	b_unsigned, @object
	.size	b_unsigned, 28
b_unsigned:
	.word	1
	.word	2
	.word	5
	.word	0
	.word	-16
	.word	123456
	.word	9
	.globl	result_signed_q
	.bss
	.align	2
	.type	result_signed_q, @object
	.size	result_signed_q, 196
result_signed_q:
	.zero	196
	.globl	result_signed_r
	.align	2
	.type	result_signed_r, @object
	.size	result_signed_r, 196
result_signed_r:
	.zero	196
	.globl	result_unsigned_q
	.align	2
	.type	result_unsigned_q, @object
	.size	result_unsigned_q, 196
result_unsigned_q:
	.zero	196
	.globl	result_unsigned_r
	.align	2
	.type	result_unsigned_r, @object
	.size	result_unsigned_r, 196
result_unsigned_r:
	.zero	196
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-80
	sw	ra,76(sp)
	sw	s0,72(sp)
	addi	s0,sp,80
	sw	zero,-20(s0)
	sw	zero,-24(s0)
	j	.L2
.L10:
	sw	zero,-28(s0)
	j	.L3
.L9:
	lui	a5,%hi(a_signed)
	addi	a4,a5,%lo(a_signed)
	lw	a5,-24(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a5,0(a5)
	sw	a5,-64(s0)
	lui	a5,%hi(b_signed)
	addi	a4,a5,%lo(b_signed)
	lw	a5,-28(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a5,0(a5)
	sw	a5,-68(s0)
	sw	zero,-32(s0)
	sw	zero,-36(s0)
	lw	a5,-68(s0)
	bne	a5,zero,.L4
	lw	a5,-64(s0)
	blt	a5,zero,.L5
	li	a5,-2147483648
	addi	a5,a5,-1
	sw	a5,-32(s0)
	j	.L6
.L5:
	li	a5,-1
	sw	a5,-32(s0)
.L6:
	lw	a5,-64(s0)
	sw	a5,-36(s0)
	j	.L7
.L4:
	lw	a4,-64(s0)
	li	a5,-2147483648
	bne	a4,a5,.L8
	lw	a4,-68(s0)
	li	a5,-1
	bne	a4,a5,.L8
	li	a5,-2147483648
	sw	a5,-32(s0)
	sw	zero,-36(s0)
	j	.L7
.L8:
	lw	a4,-64(s0)
	lw	a5,-68(s0)
	div	a5,a4,a5
	sw	a5,-32(s0)
	lw	a4,-64(s0)
	lw	a5,-68(s0)
	rem	a5,a4,a5
	sw	a5,-36(s0)
.L7:
	lw	a4,-32(s0)
	lui	a5,%hi(result_signed_q)
	addi	a3,a5,%lo(result_signed_q)
	lw	a5,-20(s0)
	slli	a5,a5,2
	add	a5,a3,a5
	sw	a4,0(a5)
	lw	a4,-36(s0)
	lui	a5,%hi(result_signed_r)
	addi	a3,a5,%lo(result_signed_r)
	lw	a5,-20(s0)
	slli	a5,a5,2
	add	a5,a3,a5
	sw	a4,0(a5)
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	lw	a5,-28(s0)
	addi	a5,a5,1
	sw	a5,-28(s0)
.L3:
	lw	a4,-28(s0)
	li	a5,6
	ble	a4,a5,.L9
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L2:
	lw	a4,-24(s0)
	li	a5,6
	ble	a4,a5,.L10
	sw	zero,-20(s0)
	sw	zero,-40(s0)
	j	.L11
.L16:
	sw	zero,-44(s0)
	j	.L12
.L15:
	lui	a5,%hi(a_unsigned)
	addi	a4,a5,%lo(a_unsigned)
	lw	a5,-40(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a5,0(a5)
	sw	a5,-56(s0)
	lui	a5,%hi(b_unsigned)
	addi	a4,a5,%lo(b_unsigned)
	lw	a5,-44(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a5,0(a5)
	sw	a5,-60(s0)
	sw	zero,-48(s0)
	sw	zero,-52(s0)
	lw	a5,-60(s0)
	bne	a5,zero,.L13
	li	a5,-1
	sw	a5,-48(s0)
	lw	a5,-56(s0)
	sw	a5,-52(s0)
	j	.L14
.L13:
	lw	a4,-56(s0)
	lw	a5,-60(s0)
	divu	a5,a4,a5
	sw	a5,-48(s0)
	lw	a4,-56(s0)
	lw	a5,-60(s0)
	remu	a5,a4,a5
	sw	a5,-52(s0)
.L14:
	lui	a5,%hi(result_unsigned_q)
	addi	a4,a5,%lo(result_unsigned_q)
	lw	a5,-20(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a4,-48(s0)
	sw	a4,0(a5)
	lui	a5,%hi(result_unsigned_r)
	addi	a4,a5,%lo(result_unsigned_r)
	lw	a5,-20(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a4,-52(s0)
	sw	a4,0(a5)
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	lw	a5,-44(s0)
	addi	a5,a5,1
	sw	a5,-44(s0)
.L12:
	lw	a4,-44(s0)
	li	a5,6
	ble	a4,a5,.L15
	lw	a5,-40(s0)
	addi	a5,a5,1
	sw	a5,-40(s0)
.L11:
	lw	a4,-40(s0)
	li	a5,6
	ble	a4,a5,.L16
.L17:
	j	.L17
	.size	main, .-main
	.ident	"GCC: (g1b306039a) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
