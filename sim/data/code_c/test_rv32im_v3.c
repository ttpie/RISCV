volatile int results[16];

int main() {
    int a = 12345;
    int b = -6789;
    int c = 42;
    int d;

    // --- R-type (ALU) ---
    results[0]  = a + b;      // ADD
    results[1]  = a - b;      // SUB
    results[2]  = a & b;      // AND
    results[3]  = a | b;      // OR
    results[4]  = a ^ b;      // XOR
    results[5]  = a << 3;     // SLL
    results[6]  = a >> 2;     // SRL
    results[7]  = b >> 2;     // SRL (negative)
    results[8]  = b >> 2;     // SRL test (unsigned)
    results[9]  = b >> 2;     // SRA test (signed)

    // --- I-type ---
    results[10] = (a + 100) ^ 0x55; // ADDI + XORI
    results[11] = (b & 0xFF) | 0xF0; // ANDI + ORI

    // --- MUL/DIV/MOD (M-extension) ---
    results[12] = a * c;      // MUL
    results[13] = a / c;      // DIV
    results[14] = a % c;      // REM
    results[15] = b / c;      // DIV negative

    // --- Branch test ---
    d = 0;
    if (a > b)
        d = 1;
    else
        d = 2;

    // store result
    results[0] += d;

    return results[0];
}
