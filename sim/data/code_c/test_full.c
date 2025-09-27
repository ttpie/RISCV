// int main() {
//     int a = 12;
//     int b = 10;
//     int c = a + b;      // ADD
//     int d = a - b;      // SUB
//     int e = a & b;      // AND
//     int f = a | b;      // OR
//     int g = a ^ b;      // XOR
//     int h = a << 2;     // SLL (shift left logical)
//     int i = b >> 1;     // SRL (shift right logical)
//     int j = b >> 3;     // có thể dịch arithmetic (SRA) nếu b là signed
//     int k = (a < b);    // SLT
//     int l = (unsigned)a < (unsigned)b; // SLTU

//     int arr[4];
//     arr[0] = c;         // SW (store word)
//     int m = arr[0];     // LW (load word)

//     if (a == b) {       // BEQ
//         m = m + 1;
//     } else if (a != b) { // BNE
//         m = m - 1;
//     }

//     if (a < b) {        // BLT
//         m++;
//     } else if (a >= b) { // BGE
//         m--;
//     }

//     // dùng vòng lặp để ép compiler sinh branch + addi
//     for (int n = 0; n < 5; n++) {
//         m += n;
//     }

//     return m;
// }
//-----------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>

volatile int sink = 0;

int add_func(int x, int y) {
    return x + y;   // sẽ sinh jal/jalr khi được gọi
}

int main() {
    int a = 1234;
    int b = 5678;
    int c;

    // R-type
    c = a + b;       // add
    c = a - b;       // sub
    c = a & b;       // and
    c = a | b;       // or
    c = a ^ b;       // xor
    c = a << 2;      // sll
    c = a >> 2;      // srl (logical)
    c = (a < b);     // slt
    c = ((unsigned)a < (unsigned)b); // sltu
    c = b >> 31;     // sra (arithmetic shift)

    // I-type immediates
    c = a + 100;     // addi
    c = a & 0x55;    // andi
    c = a | 0xAA;    // ori
    c = a ^ 0xFF;    // xori
    c = (a < 2000);  // slti
    c = ((unsigned)a < (unsigned)2000); // sltiu
    c = a << 3;      // slli
    c = a >> 3;      // srli
    c = a >> 7;      // srai

    // Memory (array để ép load/store)
    char  arrb[8];
    short arrh[8];
    int   arrw[8];

    arrb[0] = (char)c;     // sb
    arrh[0] = (short)c;    // sh
    arrw[0] = c;           // sw

    c = arrb[0];           // lb
    c = arrh[0];           // lh
    c = arrw[0];           // lw
    c = (unsigned char)arrb[0]; // lbu
    c = (unsigned short)arrh[0]; // lhu

    // Branches
    if (a == b) c++;   // beq
    if (a != b) c--;   // bne
    if (a < b)  c++;   // blt
    if (a >= b) c--;   // bge
    if ((unsigned)a < (unsigned)b) c++;  // bltu
    if ((unsigned)a >= (unsigned)b) c--; // bgeu

    // Jumps
    c = add_func(a, b);  // jal + jalr

    // Upper immediates (ép compiler dùng lui/auipc)
    int big = 0x12345678; // hằng 32-bit sẽ sinh lui + ori/auipc

    // System instructions (bắt buộc inline một dòng)
    asm volatile("ecall");
    asm volatile("ebreak");

    sink = c + big;
    return sink;
}
