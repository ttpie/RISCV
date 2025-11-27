
.section .text
.globl _start


_start:
# Cài trap handler
la   x5, trap_handler       # t0 -> x5
csrw mtvec, x5

# Gọi ecall để test trap
ecall

# --- I-type arithmetic ---
addi x10, x0, 10            # a0 -> x10
addi x11, x0, 20            # a1 -> x11
addi x13, x0, 550            # a3 -> x13
addi x14, x0, -5            # a4 -> x14
addi x15, x10, 15           # a5 -> x15

# --- R-type arithmetic ---
add  x12, x10, x11          # a2
sub  x13, x13, x11          # a6
mul  x15, x10, x11          # a7
mulh x10, x13, x11          # a0
mulhsu x11, x13, x10        # a1
mulhu x12, x13, x11         # a2
div  x13, x13, x10          # a3
divu x14, x13, x10          # a4
rem  x15, x13, x10          # a5
remu x13, x13, x10          # a6

and  x5, x10, x11           # t0
or   x6, x10, x11           # t1
xor  x7, x10, x11           # t2
sll  x8, x10, x11           # t3
srl  x9, x13, x11           # t4
sra  x18, x13, x11          # t5 -> x18
slt  x19, x10, x11          # t6 -> x19
sltu x28, x10, x11          # t7 -> x28

# --- I-type shift / logic ---
andi x8, x10, 0xF           # s0 -> x8
ori  x9, x11, 0xF0          # s1 -> x9
xori x10, x11, 0xFF         # s2 -> x10
slli x11, x10, 2            # s3 -> x11
srli x12, x11, 1            # s4 -> x12
srai x13, x13, 1            # s5 -> x13
slti x14, x10, 100          # s6 -> x14
sltiu x15, x11, 200         # s7 -> x15

# --- S-type store ---
la   x5, mem_data
sw   x10, 0(x5)
sh   x11, 4(x5)
sb   x12, 6(x5)

# --- I-type load ---
lw   x5, 0(x5)
lh   x6, 4(x5)
lb   x7, 6(x5)
lbu  x8, 6(x5)
lhu  x9, 4(x5)

# --- B-type branch ---
beq  x10, x11, skip1
bne  x10, x11, skip2
blt  x10, x11, skip3
bge  x10, x11, skip4
bltu x10, x11, skip5
bgeu x10, x11, skip6


skip1: nop
skip2: nop
skip3: nop
skip4: nop
skip5: nop
skip6: nop

# --- J-type and U-type ---
auipc x5, 0x1
lui   x6, 0x12345
jal   x7, loop
jalr  x8, x5, 4


loop:
addi x9, x9, 1
j loop

# --- Trap handler ---

trap_handler:
csrr x5, mcause
csrr x6, mepc
addi x6, x6, 4
csrw mepc, x6
mret

.section .data

mem_data:
.word 0
.half 0
.byte 0
