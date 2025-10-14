// rv32im_test_nosys.c
// Phiên bản không dùng system/fence instructions.
// Mục đích: chạm vào nhiều lệnh RV32IM để test core risvc.

#include <stdint.h>
#include <stddef.h>

volatile int32_t sink_i32 = 0;
volatile uint32_t sink_u32 = 0;
volatile int64_t  sink_i64 = 0;

// Ép jal/jalr khi gọi
__attribute__((noinline)) int32_t call_target(int32_t x, int32_t y) {
    // Một vài phép toán để chắc chắn có use của các thanh ghi
    int32_t t = x + y;
    t = (t << 3) ^ (t >> 2);
    return t + 0x2A;
}

__attribute__((noinline)) int32_t call_target2(int32_t x) {
    // dùng cho jal
    return x * 3 - 7;
}

int main(void) {
    // --- R-type ALU cơ bản ---
    volatile int32_t a = 0x12345678;
    volatile int32_t b = -98765;
    volatile int32_t r = 0;

    // Cố tình tách từng phép để compiler thường sinh ra R-type
    r = a + b;                // add
    r = a - b;                // sub
    r = a & b;                // and
    r = a | b;                // or
    r = a ^ b;                // xor
    r = a << 3;               // sll (thường slli)
    r = (int32_t)((uint32_t)a >> 3); // srl / srli
    r = a >> 3;               // sra candidate
    r = (a < b) ? 1 : 0;      // slt
    r = ((uint32_t)a < (uint32_t)b) ? 1 : 0; // sltu

    // --- M-extension (mul, div, rem) ---
    volatile int32_t mm1 = 12345;
    volatile int32_t mm2 = -54321;
    volatile int32_t mul_s = mm1 * mm2;                 // mul
    volatile int32_t mulh_s = (int32_t)(((int64_t)mm1 * (int64_t)mm2) >> 32); // mulh (may be optimized)
    volatile uint32_t mulhu = (uint32_t)(((uint64_t)(uint32_t)mm1 * (uint64_t)(uint32_t)mm2) >> 32); // mulhu
    volatile int32_t div_s = mm2 / mm1;                 // div
    volatile uint32_t div_u = (uint32_t)((uint32_t)mm2 / (uint32_t)mm1); // divu
    volatile int32_t rem_s = mm2 % mm1;                 // rem
    volatile uint32_t rem_u = (uint32_t)((uint32_t)mm2 % (uint32_t)mm1); // remu

    // Thêm vài phép nhân/chia nữa để tăng tần suất xuất hiện
    for (int i = 1; i <= 5; ++i) {
        mm1 = mm1 * (i + 3);    // mul
        mm2 = mm2 / (i + 1);    // div
        rem_s = mm2 % (i + 7);  // rem
    }

    // --- I-type immediates ---
    r = a + 100;         // addi
    r = a & 0x5555;      // andi
    r = a | 0xAAAA;      // ori
    r = a ^ 0xFF;        // xori
    r = (a < 200000) ? 1 : 0;   // slti
    r = ((uint32_t)a < (uint32_t)200000u) ? 1 : 0; // sltiu
    r = a << 5;          // slli (khi hợp lý)
    r = (int32_t)((uint32_t)a >> 5); // srli
    r = a >> 7;          // srai candidate

    // --- Loads / Stores (S-type và I-type loads) ---
    // dùng các mảng volatile để tránh tối ưu
    volatile uint8_t  vb[32];
    volatile uint16_t vh[32];
    volatile uint32_t vw[32];

    // stores (sb, sh, sw)
    vb[0] = (uint8_t)r;    // sb
    vh[0] = (uint16_t)r;   // sh
    vw[0] = (uint32_t)r;   // sw

    // loads (lb, lh, lw, lbu, lhu)
    r = (int8_t)vb[0];     // lb
    r = (int16_t)vh[0];    // lh
    r = (int32_t)vw[0];    // lw
    r = (int32_t)(uint8_t)vb[0];  // lbu
    r = (int32_t)(uint16_t)vh[0]; // lhu

    // unaligned accesses (nếu core hỗ trợ) - làm vài offset khác
    vw[1] = 0xA5A5A5A5u;
    r = (int32_t)vw[1];

    // --- Branches (B-type) ---
    // Những điều kiện khác nhau để bắt beq,bne,blt,bge,bltu,bgeu
    if (a == b) r += 1;      // beq
    if (a != b) r -= 1;      // bne
    if (a < b)  r += 2;      // blt
    if (a >= b) r -= 2;      // bge
    if ((uint32_t)a < (uint32_t)b) r += 3; // bltu
    if ((uint32_t)a >= (uint32_t)b) r -= 3; // bgeu

    // Loop kết hợp thêm branch và addi (để tạo vài trình phân nhánh ngắn)
    volatile int32_t acc = 0;
    for (int i = 0; i < 16; ++i) {
        acc += i;           // addi trong vòng lặp
        if ((acc & 1) == 0) {
            acc ^= (i << 1); // to exercise branching
        } else {
            acc += (i >> 1);
        }
    }

    // --- Jumps: JAL và JALR ---
    int32_t ret1 = call_target((int32_t)a, (int32_t)b); // jal (call)
    int32_t (*fp)(int32_t, int32_t) = call_target;
    int32_t ret2 = fp(5, 7);            // jalr via function pointer
    (void)ret1; (void)ret2;

    // direct jal usage (thường do compiler implement as call)
    int32_t got = call_target2(1234);   // jal

    // JALR to computed address: emulate via pointer arithmetic
    // (tạo nhiều trường hợp để compiler có thể phát sinh jalr)
    int32_t (*fp2)(int32_t) = call_target2;
    got += fp2(2);                      // jalr candidate

    // --- U-type: LUI / AUIPC style constants ---
    // Sử dụng các hằng lớn để kích LUI/AUIPC sequence
    const uint32_t big_const = 0xFEDC1234u;
    uint32_t up = big_const + 100; // compiler thường dùng lui/auipc + addi
    (void)up;

    // --- Một số thao tác bit nữa để tăng coverage ---
    r = ~a;
    r = (a & (~b)) | ((~a) & b);
    r ^= 0xCAFEBABE;

    // Truy cập mảng và con trỏ để cover AMO? (AMO not in I)
    uint32_t arr[8];
    arr[1] = 0xDEADBEEF;
    uint32_t *p = arr + 1;
    r = (int32_t)p[0];

    for (int j = 1; j <= 10; ++j) {
        int32_t vv = (int32_t)(mm1 + j);
        volatile int32_t q = mm2 / vv;   // div
        volatile int32_t rem = mm2 % vv; // rem
        sink_i32 += q + rem;
    }

        // trước khi return:
    volatile int32_t temp_sink = r + mul_s + div_s + rem_s + acc;
    sink_i32 = temp_sink;                // buộc store 32-bit
    asm volatile ("" ::: "memory");      // prevent reordering
    volatile int32_t read_back = sink_i32; // buộc load 32-bit

    sink_u32 = up + (uint32_t)mulhu + (uint32_t)div_u + (uint32_t)rem_u;
    sink_i64 = (int64_t)mm1 * (int64_t)mm2;
    
    return (int)(read_back ^ (int32_t)sink_u32 ^ (int32_t)(sink_i64 & 0xFFFFFFFF));


    // // Ghi vào sink volatile để compiler không loại bỏ
    // sink_i32 = r + mul_s + div_s + rem_s + acc;
    // sink_u32 = up + (uint32_t)mulhu + (uint32_t)div_u + (uint32_t)rem_u;
    // sink_i64 = (int64_t)mm1 * (int64_t)mm2;

    // // Trả về một giá trị dựa trên sink để làm kết quả cuối cùng
    // return (int)(sink_i32 ^ (int32_t)sink_u32 ^ (int32_t)(sink_i64 & 0xFFFFFFFF));
}
