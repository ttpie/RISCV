`timescale 1ns/1ps
module tb_core_test1;

  parameter MAX_GOLDEN = 4096;
  parameter LINE_LEN   = 1024;

  reg clk, reset_n;
  integer fd_golden, ret;

  // ====== MẢNG LƯU GOLDEN ======
  reg [31:0] g_pc    [0:MAX_GOLDEN-1];
  reg [31:0] g_instr [0:MAX_GOLDEN-1];
  reg [31:0] g_value [0:MAX_GOLDEN-1];
  reg [31:0] g_addr  [0:MAX_GOLDEN-1];
  reg [4:0]  g_rd    [0:MAX_GOLDEN-1];
  reg [2:0]  g_type  [0:MAX_GOLDEN-1]; // 0=reg,1=store,2=load,3=branch/jalr
  integer golden_cnt;

  // ========== DUT ==========
  top_module dut(
    .clk    (clk),
    .reset_n(reset_n)
  );

  // ====== Tín hiệu commit ======
      wire wb_event  = (dut.MEMWB_regWEn_out && (dut.MEMWB_addr_rd_out != 0)); // register, load
      wire mem_event = dut.EXMEM_MemRW_out; // store
      wire branch_event = dut.IDEX_branch_out;
      wire jalr_event = (dut.is_jalr);

  // PC & Instr commit
     wire [31:0] pc_commit =
       wb_event     ? dut.MEMWB_PC_out :
       mem_event    ? dut.EXMEM_PC_out :
       branch_event ? dut.EX_PC_out    :
       jalr_event   ? dut.ID_PC_out    : 32'hx;

      wire [31:0] instr_commit =
       wb_event     ? dut.MEMWB_instr_out :
       mem_event    ? dut.EXMEM_instr_out :
       branch_event ? dut.EX_instr_out    :
       jalr_event   ? dut.ID_instr_out    : 32'hx;

    // ====== Đọc GOLDEN ======
    reg [8*LINE_LEN-1:0] line;
    reg [8*16-1:0] t3, t4, t5, t6;

  initial begin
        // ---- Waveform ----
        $dumpfile("tb_test1.vcd");
        $dumpvars(0, tb_core_test1);

        // ---- Load memory ----
        $readmemh("data/hex/imem_test_full.hex", dut.IMEM.memory, 0, 1023);
        $readmemh("data/hex/init_dmem.hex",     dut.DMEM.memory, 0, 1023);

        // ---- Đọc golden ----
        golden_cnt = 0;
        fd_golden = $fopen("data/golden/golden_test_full_filtered.txt","r");
        if (fd_golden == 0) begin
            $display("❌ Cannot open golden trace file");
            $finish;
        end

        while (!$feof(fd_golden) && golden_cnt < MAX_GOLDEN) begin
            line = "";
            ret = $fgets(line, fd_golden);
            if (ret == 0) disable read_done;

            integer n = $sscanf(line, "%h (0x%h) %s %s %s %s",
                                g_pc[golden_cnt], g_instr[golden_cnt],
                                t3, t4, t5, t6);

            if (n >= 2) begin
                if (n == 2) begin
                    g_type[golden_cnt] = 3; // branch/jalr
                    golden_cnt = golden_cnt + 1;
                disable next_line;
                end

                if (t3 == "mem") begin
                    $sscanf(t4,"%h", g_addr[golden_cnt]);
                    $sscanf(t5,"%h", g_value[golden_cnt]);
                    g_type[golden_cnt] = 1; // store
                    golden_cnt = golden_cnt + 1;
                disable next_line;
                end

                if (t5 == "mem") begin
                    integer rdnum;
                    $sscanf(t3,"x%d", rdnum);
                    g_rd[golden_cnt] = rdnum[4:0];
                    $sscanf(t4,"%h", g_value[golden_cnt]);
                    $sscanf(t6,"%h", g_addr[golden_cnt]);
                    g_type[golden_cnt] = 2; // load
                    golden_cnt = golden_cnt + 1;
                disable next_line;
                end

                begin
                    integer rdnum;
                    $sscanf(t3,"x%d", rdnum);
                    g_rd[golden_cnt] = rdnum[4:0];
                    $sscanf(t4,"%h", g_value[golden_cnt]);
                    g_type[golden_cnt] = 0; // register write
                    golden_cnt = golden_cnt + 1;
                end
            end
            next_line: ;
        end
        read_done: $fclose(fd_golden);
        $display("Đọc golden xong: %0d dòng", golden_cnt);
  end

  // ===== CLOCK / RESET =====
  initial begin clk = 0; forever #5 clk = ~clk; end
  initial begin reset_n = 0; #20 reset_n = 1; end

  // ===== SO KHỚP =====
  integer pass_count = 0;
  integer mismatch_count = 0;

  always @(posedge clk) begin
    if (!reset_n) begin
      pass_count     <= 0;
      mismatch_count <= 0;
    end
    else if (wb_event || mem_event || branch_event || jalr_event) begin
      integer i;
      for (i = 0; i < golden_cnt; i = i + 1) begin
        if (g_pc[i] == pc_commit && g_instr[i] == instr_commit) begin
          case (g_type[i])
            // ===== Register ghi =====
            0: begin
                 if (dut.RF.registers[g_rd[i]] === g_value[i]) begin
                   $display("PASS  REG  pc=%h instr=%h x%0d=%h",
                            g_pc[i], g_instr[i], g_rd[i], g_value[i]);
                   pass_count = pass_count + 1;
                 end else begin
                   $display("FAIL  REG  pc=%h instr=%h x%0d expected=%h got=%h",
                            g_pc[i], g_instr[i], g_rd[i],
                            g_value[i], dut.RF.registers[g_rd[i]]);
                   mismatch_count = mismatch_count + 1;
                 end
               end

            // ===== Store =====
            1: begin
                 if (dut.DMEM.memory[g_addr[i]>>2] === g_value[i]) begin
                   $display("PASS STORE pc=%h instr=%h addr=%h value=%h",
                            g_pc[i], g_instr[i], g_addr[i], g_value[i]);
                   pass_count = pass_count + 1;
                 end else begin
                   $display("FAIL STORE pc=%h instr=%h addr=%h expected=%h got=%h",
                            g_pc[i], g_instr[i], g_addr[i],
                            g_value[i], dut.DMEM.memory[g_addr[i]>>2]);
                   mismatch_count = mismatch_count + 1;
                 end
               end

            // ===== Load =====
            2: begin
                 if (dut.RF.registers[g_rd[i]] === g_value[i]) begin
                   $display("PASS  LOAD pc=%h instr=%h x%0d=%h (addr=%h)",
                            g_pc[i], g_instr[i], g_rd[i], g_value[i], g_addr[i]);
                   pass_count = pass_count + 1;
                 end else begin
                   $display("FAIL  LOAD pc=%h instr=%h x%0d expected=%h got=%h (addr=%h)",
                            g_pc[i], g_instr[i], g_rd[i],
                            g_value[i], dut.RF.registers[g_rd[i]], g_addr[i]);
                   mismatch_count = mismatch_count + 1;
                 end
               end

            // ===== Branch / Jalr =====
            3: begin
                 $display("PASS BR/JALR pc=%h instr=%h", g_pc[i], g_instr[i]);
                 pass_count = pass_count + 1;
               end
          endcase
          disable found_match;
        end
      end
      found_match: ;
    end
  end

  // ===== KẾT THÚC =====
  initial begin
    #20000;
    $display("==== TỔNG KẾT ====");
    $display("✅ Pass = %0d", pass_count);
    $display("❌ Mismatch = %0d", mismatch_count);
    $finish;
  end

endmodule
