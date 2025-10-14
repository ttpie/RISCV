
#include <stdint.h>
#include <stddef.h>

volatile int32_t sink_i32 = 0;
volatile uint32_t sink_u32 = 0;
volatile int64_t  sink_i64 = 0;

__attribute__((noinline)) int32_t call_target(int32_t x, int32_t y) {
    // hàm để ép JAL/JALR khi gọi
    return x - y + 42;
}

int main(void) {
    // R-type (ALU)
    int32_t a = 0x12345678;
    int32_t b = -98765;
    int32_t r;

    r = a + b;    // add
    r = a - b;    // sub
    r = a & b;    // and
    r = a | b;    // or
    r = a ^ b;    // xor
    r = a << 3;   // sll (may compile to slli)
    r = (int32_t)((uint32_t)a >> 3); // srl (logical)
    r = a >> 3;   // sra candidate (signed arithmetic)
    r = (a < b) ? 1 : 0;   // slt
    r = ((uint32_t)a < (uint32_t)b) ? 1 : 0; // sltu

    // M-extension: multiply, divide, remainder (sử dụng toán tử C)
    int32_t mm1 = 12345;
    int32_t mm2 = -54321;
    int32_t mul_s = mm1 * mm2;              // mul
    uint32_t mul_u = (uint32_t)mm1 * (uint32_t)12345u;
    int32_t div_s = mm2 / mm1;              // div
    uint32_t div_u = (uint32_t)mm2 / (uint32_t)mm1; // divu
    int32_t rem_s = mm2 % mm1;              // rem
    uint32_t rem_u = (uint32_t)mm2 % (uint32_t)mm1; // remu

    // I-type immediates
    r = a + 100;      // addi
    r = a & 0x5555;   // andi
    r = a | 0xAAAA;   // ori
    r = a ^ 0xFF;     // xori
    r = (a < 200000) ? 1 : 0;    // slti
    r = ((uint32_t)a < (uint32_t)200000u) ? 1 : 0; // sltiu
    r = a << 5;       // slli
    r = (int32_t)((uint32_t)a >> 5); // srli
    r = a >> 7;       // srai candidate

    // Loads / Stores
    volatile uint8_t  vb[16];
    volatile uint16_t vh[16];
    volatile uint32_t vw[16];

    vb[0] = (uint8_t)r;   // sb
    vh[0] = (uint16_t)r;  // sh
    vw[0] = (uint32_t)r;  // sw

    r = (int8_t)vb[0];    // lb
    r = (int16_t)vh[0];   // lh
    r = (int32_t)vw[0];   // lw
    r = (int32_t)(uint8_t)vb[0];  // lbu
    r = (int32_t)(uint16_t)vh[0]; // lhu

    // Branches
    if (a == b) r += 1;   // beq
    if (a != b) r -= 1;   // bne
    if (a < b)  r += 2;   // blt
    if (a >= b) r -= 2;   // bge
    if ((uint32_t)a < (uint32_t)b) r += 3; // bltu
    if ((uint32_t)a >= (uint32_t)b) r -= 3; // bgeu

    // Loop (branch + addi)
    for (int i = 0; i < 8; ++i) {
        r += i;
    }

    // Jumps (JAL / JALR)
    int32_t ret = call_target(a, b);
    int32_t (*fp)(int32_t, int32_t) = call_target;
    ret += fp(5, 7); // jalr via function pointer

    // AUIPC / LUI style constant
    const uint32_t big_const = 0xFEDC1234u;
    uint32_t up = big_const + 100;

    // Một vài phép toán bit để nới ví dụ
    r = (~a);
    r = (a & (~b)) | ((~a) & b);

    uint32_t arr[4];
    arr[1] = 0xDEADBEEF;
    uint32_t *p = arr + 1;
    r = p[0];

    // Volatile sinks
    sink_i32 = r + mul_s + div_s + rem_s;
    sink_u32 = up + (uint32_t)mul_u + (uint32_t)div_u + (uint32_t)rem_u;
    sink_i64 = (int64_t)mm1 * (int64_t)mm2;

    return (int)(sink_i32 ^ (int32_t)sink_u32);
}
