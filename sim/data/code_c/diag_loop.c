#include <stdint.h>

#define DM_BASE   0x80000000u
#define OUT(x)    (*(volatile uint32_t*)(DM_BASE + (x)))

volatile uint32_t op_n = 5;

int main(void) {
    uint32_t sum = 0;
    uint32_t i   = 1;
    uint32_t n   = op_n;

    OUT(0x10) = 0xAAAAAAA1;

    while (i < n) {
        sum = sum + i;     // load + add
        OUT(0x00) = i;     // store i
        OUT(0x04) = sum;   // store sum
        i++;
    }

    OUT(0x08) = sum;
    OUT(0x0C) = n;
    OUT(0x10) = 0x55555551;

    return 0;
}