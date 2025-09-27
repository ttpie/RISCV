
# Step 1: gen imem.hex and golden trace from C source file
# Usage: python3 gen_golden_imem.py <input.c>
import os
import sys
import subprocess
import re

def run_cmd(cmd, desc):
    print(f">> {desc} ...")
    subprocess.run(cmd, check=True)

if len(sys.argv) != 2:
    print("Usage: python3 gen_golden.py <input.c>")
    sys.exit(1)

c_file = sys.argv[1]
base = os.path.splitext(os.path.basename(c_file))[0]

# Paths
build_dir   = "sim/build"
asm_dir     = "sim/data/assembly"
hex_dir     = "sim/data/hex"
golden_dir  = "sim/data/golden"
linker_script = os.path.join(build_dir, "link.ld")

os.makedirs(build_dir, exist_ok=True)
os.makedirs(asm_dir, exist_ok=True)
os.makedirs(golden_dir, exist_ok=True)
os.makedirs(hex_dir, exist_ok=True)

asm_file = os.path.join(asm_dir, f"{base}.S")
start_s = os.path.join(asm_dir, "start.S")
start_o = os.path.join(asm_dir, "start.o")
test_o  = os.path.join(build_dir, base + ".o")
elf_file = os.path.join(build_dir, base + ".elf")
golden_file = os.path.join(golden_dir, f"golden_{base}.txt")
imem_hex = os.path.join(hex_dir, "imem_" + base + ".hex")

# 1. Compile start.S
run_cmd([
    "riscv32-unknown-elf-gcc", "-c", start_s, "-o", start_o,
    "-march=rv32i", "-mabi=ilp32"
], "Compiling start.S")

# 2. Compile C program -> Assembly
run_cmd([
    "riscv32-unknown-elf-gcc", "-S", c_file, "-o", asm_file,
    "-march=rv32i", "-mabi=ilp32"
], f"Compiling {c_file} to assembly")

# 3. Compile C program -> Object
run_cmd([
    "riscv32-unknown-elf-gcc", "-c", c_file, "-o", test_o,
    "-march=rv32i", "-mabi=ilp32"
], f"Compiling {c_file} to object")

# 4. Link objects into ELF with -e _start
run_cmd([
    "riscv32-unknown-elf-ld", "-T", linker_script, "-e", "_start",
    start_o, test_o, "-o", elf_file
], "Linking ELF")

# 5. Dump ELF info (disassembly)
run_cmd([
    "riscv32-unknown-elf-objdump", "-d", elf_file
], "Dumping ELF info")

# 6. Generate imem.hex (32-bit instruction hex)
raw_bin = os.path.join(hex_dir, base + ".bin")

# Dump binary (raw machine code)
run_cmd([
    "riscv32-unknown-elf-objcopy", "-O", "binary", elf_file, raw_bin
], "Generating raw binary")

# Convert to 32-bit hex (1 instruction per line)
with open(raw_bin, "rb") as f_in, open(imem_hex, "w") as f_out:
    while True:
        bytes4 = f_in.read(4)
        if not bytes4:
            break
        val = int.from_bytes(bytes4, byteorder="little")  # RISC-V little endian
        f_out.write(f"{val:08x}\n")

print(f">> imem.hex saved to {imem_hex}")

# 7. Run Spike to generate golden trace
with open(golden_file, "w") as f:
    subprocess.run([
    "spike", "--isa=rv32i", "--log-commits", elf_file
], stderr=f, check=True)
print(f">> Golden trace saved to {golden_file}")

