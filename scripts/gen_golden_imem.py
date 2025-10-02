#!/usr/bin/env python3
"""
gen_golden_imem.py
Usage: python3 gen_golden_imem.py <input.c>

Generates:
  sim/data/hex/imem_<base>.hex   -> .text only (word per line, little-endian)
  sim/data/hex/dmem_<base>.hex   -> padded .sdata/.data so that DMEM index 0 maps to VMA .text
  sim/data/hex/full_<base>.hex   -> full image (word per line)
  sim/data/disasm/disasm_<base>.txt -> disassembly (objdump -d)
Also creates sim/data/golden/golden_<base>.txt via spike (pk preferred).
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
    print("Usage: python3 gen_golden_imem.py <input.c>")
    sys.exit(1)

c_file = sys.argv[1]
base = os.path.splitext(os.path.basename(c_file))[0]

# Paths
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

# Tools (assume in PATH)
CC = "riscv32-unknown-elf-gcc"
LD = "riscv32-unknown-elf-ld"
OBJCOPY = "riscv32-unknown-elf-objcopy"
OBJDUMP = "riscv32-unknown-elf-objdump"
READELF = "riscv32-unknown-elf-readelf"
SPIKE = "spike"

# 1. Compile start.S
run_cmd([CC, "-c", start_s, "-o", start_o, "-march=rv32im", "-mabi=ilp32"], "Compiling start.S")

# 2. Compile C -> Assembly (.S)
#run_cmd([CC, "-O2", "-S", c_file, "-o", asm_file, "-march=rv32im", "-mabi=ilp32"], f"Compiling {c_file} to assembly with -O2")
run_cmd([CC, "-S", c_file, "-o", asm_file, "-march=rv32im", "-mabi=ilp32"], f"Compiling {c_file} to assembly")

# 3. Compile C -> Object (.o)
#run_cmd([CC, "-O2", "-c", c_file, "-o", test_o, "-march=rv32im", "-mabi=ilp32"], f"Compiling {c_file} to object with -O2")
run_cmd([CC, "-c", c_file, "-o", test_o, "-march=rv32im", "-mabi=ilp32"], f"Compiling {c_file} to object")

# 4. Link
run_cmd([LD, "-T", linker_script, "-e", "_start", start_o, test_o, "-o", elf_file], "Linking ELF")

# 5. Dump disassembly to sim/data/disasm/disasm_<base>.txt
disasm_file = os.path.join(disasm_dir, f"disasm_{base}.txt")
with open(disasm_file, "w") as f:
    print(f">> Writing disassembly to {disasm_file} ...")
    subprocess.run([OBJDUMP, "-d", elf_file], stdout=f, check=True)

# 6. Create binaries
raw_bin = os.path.join(hex_dir, base + ".bin")
text_bin = os.path.join(hex_dir, base + ".text.bin")
sdata_bin = os.path.join(hex_dir, base + ".sdata.bin")

run_cmd([OBJCOPY, "-O", "binary", elf_file, raw_bin], "Generating raw binary (full image)")
run_cmd([OBJCOPY, "-O", "binary", "--only-section=.text", elf_file, text_bin], "Generating .text binary")

# prefer .sdata, fallback to .data, else empty
sdata_section = ".sdata"
try:
    run_cmd([OBJCOPY, "-O", "binary", "--only-section=.sdata", elf_file, sdata_bin], "Generating .sdata binary")
except subprocess.CalledProcessError:
    try:
        sdata_section = ".data"
        run_cmd([OBJCOPY, "-O", "binary", "--only-section=.data", elf_file, sdata_bin], "Generating .data binary (fallback)")
    except subprocess.CalledProcessError:
        # create empty sdata_bin
        open(sdata_bin, "wb").close()
        print("No .sdata/.data present; created empty sdata binary.")
        sdata_section = None

# helper to convert binary -> list of 32-bit words (little-endian)
def read_words_le(bin_path):
    with open(bin_path, "rb") as f:
        b = f.read()
    # pad to 4
    if len(b) % 4:
        b += b"\x00" * (4 - (len(b) % 4))
    words = []
    for i in range(0, len(b), 4):
        words.append(int.from_bytes(b[i:i+4], "little"))
    return words

# write word-per-line hex file
def write_wordhex(words, hex_path):
    with open(hex_path, "w") as out:
        for w in words:
            out.write(f"{w:08x}\n")
    print(f">> Wrote {hex_path} ({len(words)} words)")

# Build imem hex from text_bin
imem_hex = os.path.join(hex_dir, "imem_" + base + ".hex")
text_words = read_words_le(text_bin)
write_wordhex(text_words, imem_hex)

# Get VMA of .text and .sdata/.data using readelf -S
readelf_out = run_cmd([READELF, "-S", elf_file], "Reading section headers", capture=True)
# parse lines for .text and selected sdata_section
text_vma = None
sdata_vma = None
for line in readelf_out.splitlines():
    line = line.strip()
    # lines look like: [ 1] .text PROGBITS 80000000 001000 00007c 00 AX 0 0 4
    if " .text " in line and text_vma is None:
        parts = line.split()
        for p in parts:
            if len(p) >= 8 and all(ch in "0123456789abcdefABCDEF" for ch in p):
                text_vma = int(p, 16)
                break
    if sdata_section and f" {sdata_section} " in line and sdata_vma is None:
        parts = line.split()
        for p in parts:
            if len(p) >= 8 and all(ch in "0123456789abcdefABCDEF" for ch in p):
                sdata_vma = int(p, 16)
                break

# Fallback parsing if needed
if text_vma is None:
    for line in readelf_out.splitlines():
        if ".text" in line:
            toks = line.split()
            try:
                addr = toks[3]
                text_vma = int(addr, 16)
                break
            except:
                pass

if sdata_section and sdata_vma is None:
    for line in readelf_out.splitlines():
        if sdata_section in line:
            toks = line.split()
            try:
                addr = toks[3]
                sdata_vma = int(addr, 16)
                break
            except:
                pass

if text_vma is None:
    print("ERROR: failed to determine .text VMA from ELF. Aborting.")
    sys.exit(1)

print(f">> VMA .text = 0x{text_vma:08x}")
if sdata_section:
    print(f">> Using section {sdata_section}, VMA = 0x{sdata_vma:08x}" if sdata_vma else f">> Section {sdata_section} not found in ELF.")
else:
    print(">> No sdata/data section found.")

# Create dmem hex padded so that DMEM index 0 == .text VMA
dmem_hex = os.path.join(hex_dir, "dmem_" + base + ".hex")
dmem_words = []

if sdata_vma is None:
    dmem_words = [0]
    write_wordhex(dmem_words, dmem_hex)
else:
    if sdata_vma < text_vma:
        print("Warning: sdata VMA < text VMA. This is unusual. We'll set offset 0.")
        offset_words = 0
    else:
        offset_words = (sdata_vma - text_vma) // 4

    print(f">> sdata offset in words from .text = {offset_words}")

    dmem_words = [0] * offset_words
    sdata_words = read_words_le(sdata_bin)
    if len(sdata_words) == 0:
        print(">> .sdata/.data binary empty (no data).")
    dmem_words.extend(sdata_words)
    write_wordhex(dmem_words, dmem_hex)

# create full image hex (optional)
full_hex = os.path.join(hex_dir, "full_" + base + ".hex")
full_words = read_words_le(raw_bin)
write_wordhex(full_words, full_hex)

print(f">> Files generated:\n   {imem_hex}\n   {dmem_hex}\n   {full_hex}\n   {disasm_file}")

# 7. Run spike to generate golden trace (try pk first)
def run_spike_golden(elf, out_file):
    try:
        with open(out_file, "w") as f:
            subprocess.run([SPIKE, "--isa=rv32im", "pk", "--log-commits", elf],
                           stderr=f, check=True)
        return
    except subprocess.CalledProcessError:
        print("`spike pk` failed, trying `spike` (no pk).")
    with open(out_file, "w") as f:
        subprocess.run([SPIKE, "--isa=rv32im", "--log-commits", elf],
                       stderr=f, check=True)

run_spike_golden(elf_file, golden_file)
print(f">> Golden trace saved to {golden_file}")
