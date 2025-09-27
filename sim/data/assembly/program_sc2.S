    .text
    .globl _start
_start:
    lui x1, 0
    addi x1, x1, 0
    addi x2, x0, 5
    addi x3, x0, 10
    add x4, x2, x3
    sub x4, x3, x2
    and x4, x2, x3
    or x4, x2, x3
    sll x4, x2, x3
    srl x4, x3, x2
    slt x5, x2, x3
    sltu x5, x3, x2
    addi x2, x0, 15
    addi x3, x2, -5
    andi x3, x2, 15
    ori x3, x2, 240
    xori x3, x2, 255
    slli x3, x2, 2
    srli x3, x2, 2
    srai x3, x2, 2
    addi x2, x2, -20
    slti x3, x2, 20
    sltiu x3, x2, 20
    addi x10, x0, 0
    addi x11, x0, 10
    add x12, x0, x1
    lui x13, 65793
    addi x13, x13, 16
    lui x14, 4112
    addi x14, x14, 257
    sw x13, 0(x12)
    addi x10, x10, 1
    addi x12, x12, 4
    add x13, x13, x14
    bne x10, x11, -16
    lw x2, 0(x1)
    addi x2, x0, 128
    sb x2, 1(x1)
    lb x3, 1(x1)
    lbu x4, 1(x1)
    lui x2, 8
    sh x2, 0(x1)
    lh x3, 0(x1)
    lhu x4, 0(x1)
    addi x2, x0, 5
    addi x3, x0, 10
    addi x4, x0, 0
    beq x2, x2, 8
    addi x4, x0, -1107
    bne x2, x3, 8
    addi x4, x0, -1106
    addi x2, x2, -10
    blt x2, x3, 8
    addi x4, x0, -1105
    bge x3, x2, 8
    addi x4, x0, -1104
    bltu x2, x3, 8
    addi x4, x0, -1103
    bgeu x2, x3, 8
    addi x4, x0, -1102
    addi x3, x0, 10
    addi x4, x0, 11
    jal x2, 16
    auipc x6, 4660
    sw x6, 4(x1)
    beq x0, x0, 0
    add x5, x3, x4
    jalr x3, x2, 0
    addi x0, x0, 0
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
