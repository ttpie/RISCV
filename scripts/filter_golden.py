# Step 2: filter golden trace to keep only relevant lines
# Usage: python3 filter_golden.py <golden_file>
#!/usr/bin/env python3
import sys
import os
import re

if len(sys.argv) != 2:
    print("Usage: python3 filter_golden.py <golden_file>")
    sys.exit(1)

input_file = sys.argv[1]

# Thư mục đầu ra
output_dir = "./sim/data/golden"
os.makedirs(output_dir, exist_ok=True)

# Tạo tên file đầu ra dựa trên file đầu vào
base_name = os.path.splitext(os.path.basename(input_file))[0]
output_file = os.path.join(output_dir, f"{base_name}_filtered.txt")

copying = False

# Regex đơn giản hơn: bắt đầu bằng 'core', có địa chỉ hex (0x...)
line_regex = re.compile(r"^core\s+\d+:.*?(0x[0-9a-fA-F]+)\s*\((0x[0-9a-fA-F]+)\)(.*)$")

with open(input_file, "r") as f_in, open(output_file, "w") as f_out:
    for line in f_in:
        line_strip = line.strip()
        
        # Bắt đầu sao chép từ dòng sau lệnh 0x00028067
        if "0x00028067" in line_strip:
            copying = True
            continue
        
        # Nếu có dòng (spike) thì dừng, còn không thì copy tới hết file
        if "(spike)" in line_strip:
            copying = False
            continue
        
        if copying:
            m = line_regex.match(line_strip)
            if m:
                addr, instr, rest = m.groups()
                f_out.write(f"{addr} {instr}{rest}\n")  # giữ nguyên spacing trong rest

print(f"Filtered golden saved to {output_file}")
