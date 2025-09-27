#Step 3: run simulation and open GTKWave
# Usage: python3 run_sim.py <testbench_file.v>
import os
import glob
import subprocess
import shutil
import sys

# --- Cấu hình thư mục ---
BASE_DIR     = os.getcwd()
RTL_DIR      = os.path.join(BASE_DIR, "rtl")
TB_DIR       = os.path.join(BASE_DIR, "sim", "tb")
SIM_DIR      = os.path.join(BASE_DIR, "sim")               # cwd khi chạy vvp → để đọc data/input_imem.hex
GTKWAVE_DIR  = os.path.join(BASE_DIR, "sim", "gtkwave")

# Tạo thư mục gtkwave nếu chưa có
os.makedirs(GTKWAVE_DIR, exist_ok=True)

# --- Lấy tất cả file RTL ---
rtl_files = sorted(glob.glob(os.path.join(RTL_DIR, "*.v")))
if not rtl_files:
    raise FileNotFoundError("Không tìm thấy file RTL (*.v) trong thư mục rtl/")

# --- Chọn 1 file testbench ---
if len(sys.argv) > 1:
    tb_file = os.path.join(TB_DIR, sys.argv[1])
else:
    pref = os.path.join(TB_DIR, "tb_top_module.v")
    tb_file = pref if os.path.exists(pref) else (sorted(glob.glob(os.path.join(TB_DIR, "tb_*.v"))) or [None])[0]

if not tb_file or not os.path.exists(tb_file):
    raise FileNotFoundError("Không tìm thấy testbench trong sim/tb (vd: tb_top_module.v hoặc tb_*.v)")

tb_name = os.path.splitext(os.path.basename(tb_file))[0]
print(f"🧪 Testbench: {tb_name}")

# --- Đường dẫn output ---
exe_path = os.path.join(GTKWAVE_DIR, f"{tb_name}.out")     # file .out để vvp chạy
vcd_expect_in_sim = os.path.join(SIM_DIR, f"{tb_name}.vcd")  # TB hay dump 'tb_name.vcd'
vcd_final = os.path.join(GTKWAVE_DIR, f"{tb_name}.vcd")

# --- Biên dịch với iverilog ---
compile_cmd = ["iverilog", "-o", exe_path] + rtl_files + [tb_file]
#print("🔨 Biên dịch:\n ", " ".join(compile_cmd))
subprocess.run(compile_cmd, check=True)

# --- Chạy mô phỏng (cwd=sim để đọc 'data/input_imem.hex') ---
print("▶️  Chạy mô phỏng...")

subprocess.run(["vvp", exe_path], check=True, cwd=SIM_DIR)

# --- Lấy file VCD: ưu tiên đúng tên tb_name.vcd; nếu không có thì lấy .vcd mới nhất trong sim/ ---
if not os.path.exists(vcd_expect_in_sim):
    vcd_candidates = sorted(glob.glob(os.path.join(SIM_DIR, "*.vcd")), key=os.path.getmtime, reverse=True)
    if vcd_candidates:
        vcd_expect_in_sim = vcd_candidates[0]
    else:
        raise FileNotFoundError("Không tìm thấy file .vcd nào sau khi chạy mô phỏng trong thư mục sim/")

# Di chuyển .vcd sang sim/gtkwave rồi mở GTKWave
shutil.move(vcd_expect_in_sim, vcd_final)

print("🌊 Mở GTKWave...")
subprocess.run(["gtkwave", vcd_final], check=True)

print("✅ Hoàn tất.")
