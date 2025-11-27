    .section .text
    .globl _start

_start:
    # 1. Đăng ký handler vào mtvec
    la   t0, trap_handler        # t0 = địa chỉ trap_handler
    csrw mtvec, t0               # ghi vào CSR 0x305

    # 2. Gọi ecall để tạo trap
    ecall                        # gọi hệ thống (sinh trap môi trường)

    # 3. Lệnh tiếp theo sau ecall (sẽ chạy sau khi handler mret)
    addi a0, zero, 10            # a0 = 10
    addi a1, zero, 20            # a1 = 20
    add  a2, a0, a1              # a2 = a0 + a1 = 30

    loop:
        j loop                       # vòng lặp vô hạn

    # -----------------------------
    # Trap handler (địa chỉ được gán vào mtvec)
    # -----------------------------
    
    trap_handler:
        csrr t0, mcause              # đọc nguyên nhân trap
        csrr t1, mepc                # đọc địa chỉ lệnh gây trap
        addi t1, t1, 4               # bỏ qua lệnh ecall (PC + 4)
        csrw mepc, t1                # cập nhật lại mepc
        mret                         # quay về chương trình chính
