#!/usr/bin/env python3
"""
gen_golden_imem_asm.py
Usage: python3 gen_golden_imem_asm.py <input.S>

Generates:
  sim/data/hex/imem_<base>.hex
  sim/data/hex/dmem_<base>.hex
  sim/data/hex/full_<base>.hex
  sim/data/disasm/disasm_<base>.txt
  sim/data/golden/golden_<base>.txt  (via spike)
"""

import os
import sys
import subprocess

def run_cmd(cmd, desc, capture=False):
    print(f">> {desc} ...")
    if capture:
        return subprocess.check_output(cmd, text=True)
    else:
        subprocess.run(cmd, check=True)

if len(sys.argv) != 2:
    print("Usage: python3 gen_golden_imem_asm.py <input.S>")
    sys.exit(1)

asm_input = sys.argv[1]
base = os.path.splitext(os.path.basename(asm_input))[0]

# Directories
build_dir   = "sim/build"
asm_dir     = "sim/data/assembly"
hex_dir     = "sim/data/hex"
golden_dir  = "sim/data/golden"
disasm_dir  = "sim/data/disasm"
linker_script = os.path.join(build_dir, "link.ld")

# ensure directories
os.makedirs(build_dir, exist_ok=True)
os.makedirs(asm_dir, exist_ok=True)
os.makedirs(golden_dir, exist_ok=True)
os.makedirs(hex_dir, exist_ok=True)
os.makedirs(disasm_dir, exist_ok=True)

asm_file = os.path.join(asm_dir, f"{base}.S")
start_s  = os.path.join(asm_dir, "start.S")
start_o  = os.path.join(asm_dir, "start.o")
test_o   = os.path.join(build_dir, base + ".o")
elf_file = os.path.join(build_dir, base + ".elf")
golden_file = os.path.join(golden_dir, f"golden_{base}.txt")

# Tools
CC = "riscv32-unknown-elf-gcc"
LD = "riscv32-unknown-elf-ld"
OBJCOPY = "riscv32-unknown-elf-objcopy"
OBJDUMP = "riscv32-unknown-elf-objdump"
READELF = "riscv32-unknown-elf-readelf"
SPIKE = "spike"

# 1. Compile start.S
run_cmd([CC, "-c", start_s, "-o", start_o, "-march=rv32im", "-mabi=ilp32"], "Compiling start.S")

# 2. Assemble input .S -> .o
run_cmd([CC, "-c", asm_input, "-o", test_o, "-march=rv32im_zicsr", "-mabi=ilp32"], f"Assembling {asm_input}")

# 3. Link to ELF
run_cmd([LD, "-T", linker_script, "-e", "_start", test_o, "-o", elf_file], "Linking ELF")

# 4. Disassemble
disasm_file = os.path.join(disasm_dir, f"disasm_{base}.txt")
with open(disasm_file, "w") as f:
    subprocess.run([OBJDUMP, "-d", elf_file], stdout=f, check=True)
print(f">> Wrote disassembly to {disasm_file}")

# 5. Generate hex files
def read_words_le(path):
    with open(path, "rb") as f:
        b = f.read()
    if len(b) % 4:
        b += b"\x00" * (4 - len(b) % 4)
    return [int.from_bytes(b[i:i+4], "little") for i in range(0, len(b), 4)]

def write_hex(words, path):
    with open(path, "w") as f:
        for w in words:
            f.write(f"{w:08x}\n")
    print(f">> Wrote {path} ({len(words)} words)")

raw_bin = os.path.join(hex_dir, base + ".bin")
text_bin = os.path.join(hex_dir, base + ".text.bin")
run_cmd([OBJCOPY, "-O", "binary", elf_file, raw_bin], "Generating full binary")
run_cmd([OBJCOPY, "-O", "binary", "--only-section=.text", elf_file, text_bin], "Generating .text binary")

text_words = read_words_le(text_bin)
write_hex(text_words, os.path.join(hex_dir, f"imem_{base}.hex"))

full_words = read_words_le(raw_bin)
write_hex(full_words, os.path.join(hex_dir, f"full_{base}.hex"))

# 6. Run spike to create golden
try:
    with open(golden_file, "w") as f:
        subprocess.run([SPIKE, "--isa=rv32im", "--log-commits", elf_file], stderr=f, check=True)
    print(f">> Golden log written to {golden_file}")
except subprocess.CalledProcessError:
    print("Spike failed to run. Check ELF validity.")
