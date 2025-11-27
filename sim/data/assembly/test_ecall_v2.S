    .section .text
    .globl _start

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    ecall

    addi a0, zero, 10
    addi a1, zero, 20
    add  a2, a0, a1

    addi a3, zero, 50
    sub  a4, a3, a1
    mul  a5, a0, a1
    div  a6, a3, a0
    rem  a7, a3, a0

    and  t2, a0, a1
    or   t3, a0, a1
    xor  t4, a0, a1

    sll  t5, a0, a1
    srl  t6, a3, a1
    sra  s0, a3, a1

    slt  s1, a0, a1
    sltu s2, a0, a1

    beq  a0, a1, skip
    nop
skip:

loop:
    j loop

trap_handler:
    csrr t0, mcause
    csrr t1, mepc
    addi t1, t1, 4
    csrw mepc, t1
    mret
