    .section .text
    .globl _start
_start:
    # gọi main()
    call main

    # exit(0)
    li a7, 93      # syscall exit
    li a0, 0
    ecall
