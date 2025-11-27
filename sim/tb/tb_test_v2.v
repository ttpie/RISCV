`timescale 1ns/1ps
module tb_core_test;

      localparam STRLEN = 64;
      parameter MAX_GOLDEN = 4096;
      parameter LINE_LEN   = 1024;

      // ====== MẢNG LƯU GOLDEN ======
      reg [31:0] g_pc    [0:MAX_GOLDEN-1];
      reg [31:0] g_instr [0:MAX_GOLDEN-1];
      reg [31:0] g_value [0:MAX_GOLDEN-1];
      reg [31:0] g_addr  [0:MAX_GOLDEN-1];
      reg [4:0]  g_rd    [0:MAX_GOLDEN-1];
      reg [2:0]  g_type  [0:MAX_GOLDEN-1]; // 0 = reg, 1 = store, 2 = load, 3 = branch/jalr/jal
      reg        matched_flag [0:MAX_GOLDEN-1];

      reg clk, reset_n;
      reg [8*LINE_LEN-1:0] line;
      reg [8*STRLEN-1:0] s_pc, s_instr, s_t3, s_t4, s_t5, s_t6;
      reg read_ok, found_local;
      reg handled_wb, handled_mem, handled_br, handled_jalr_pc, handled_br_not_taken, handled_jal_pc;
      reg [31:0] pc_commit, instr_commit;

      integer pass_count = 0;
      integer mismatch_count = 0;
      integer i, j;
      integer commits_this_cycle;
      integer fd_golden, ret, golden_cnt, rdnum, n;


      // =================== DUT =====================
      top_module dut(
            .clk    (clk),
            .reset_n(reset_n)
      );
      // ============== Tín hiệu commit ================
      wire wb_event               = dut.MEMWB_regWEn_out && (dut.MEMWB_addr_rd_out != 0);
      wire mem_event              = dut.EXMEM_MemW_out;
      wire branch_event           = dut.take_branch;
      wire branch_not_taken_event = dut.IDEX_branch_out && !dut.take_branch;
      wire jalr_pc_event          = dut.is_jalr && dut.Addr_rd == 1'h0; // opcode 0x67 and rd == x0
      wire jal_pc_event           = dut.IFID_instr_out[6:0] == 7'b1101111 && dut.Addr_rd == 1'h0; // opcode 0x6F and rd == x0
      
      // ============ Clock ============
      always #5 clk = ~clk;
      // ============ Khởi tạo, đọc golden =============
      initial begin
            clk = 1'b1;
            reset_n = 1'b0;
            n = 0;

            $dumpfile("tb_test_v2.vcd");
            $dumpvars(0, tb_core_test);
            $readmemh("data/hex/imem_test_rv32im.hex", dut.IMEM.memory, 0, 1023);
            $readmemh("data/hex/dmem_test_rv32im.hex", dut.DMEM.memory, 0, 1023);

            golden_cnt = 0;
            fd_golden = $fopen("data/golden/golden_test_rv32im_filtered.txt","r");
            if (fd_golden == 0) begin
            $display("❌ Cannot open golden trace file");
            $finish;
            end else begin
            $display("Opened golden fd = %0d", fd_golden);
            end

            #1;
            read_ok = 1;

            while (!$feof(fd_golden) && golden_cnt < MAX_GOLDEN && read_ok) begin

                  ret = $fgets(line, fd_golden);
                  if (ret == 0) begin
                        $display("⚠️  fgets returned 0 at golden_cnt = %0d", golden_cnt);
                        read_ok = 0;
                  end else begin
                        n = $sscanf(line, "%s %s %s %s %s %s",
                                    s_pc, s_instr, s_t3, s_t4, s_t5, s_t6);

                        if ($sscanf(s_pc, "0x%h", g_pc[golden_cnt])    != 1) g_pc[golden_cnt]    = 0;
                        if ($sscanf(s_instr,"0x%h", g_instr[golden_cnt])!= 1) g_instr[golden_cnt] = 0;

                        if (n >= 2) begin
                              if (n == 2) begin
                                    //--------branch/jalr---------
                                    g_rd[golden_cnt] = 0;
                                    g_value[golden_cnt] = 0;
                                    g_type[golden_cnt] = 3;

                              end else if (n == 5) begin
                                    //---------- store ---------
                                    if ($sscanf(s_t4, "%h", g_addr[golden_cnt])  != 1) g_addr[golden_cnt]  = 0;
                                    if ($sscanf(s_t5, "0x%h", g_value[golden_cnt]) != 1) g_value[golden_cnt] = 0;
                                    g_type[golden_cnt] = 1;

                              end else if (n == 6) begin
                                    //------------- Load -------------
                                    if ($sscanf(s_t3, "x%d", rdnum) != 1) rdnum = 0;
                                        g_rd[golden_cnt] = rdnum[4:0];
                                    if ($sscanf(s_t4, "0x%h", g_value[golden_cnt]) != 1) g_value[golden_cnt] = 0;
                                    if ($sscanf(s_t6, "%h", g_addr[golden_cnt])  != 1) g_addr[golden_cnt]  = 0;
                                    g_type[golden_cnt] = 2;

                              end else if (n == 4) begin
                                    //------------- Register or JALR/jal -----------
                                    if ($sscanf(s_t3, "x%d", rdnum) != 1) rdnum = 0;
                                        g_rd[golden_cnt] = rdnum[4:0];
                                    if ($sscanf(s_t4, "0x%h", g_value[golden_cnt]) != 1) g_value[golden_cnt] = 0;
                                          g_type[golden_cnt] = 0; 
                              end 

                              matched_flag[golden_cnt] = 1'b0; 
                              golden_cnt = golden_cnt + 1;
                        end
                  end
            end

            $fclose(fd_golden);
            $display("Đọc golden xong: %0d dòng", golden_cnt);
            #19 reset_n = 1'b1;
     end

   // ===== So khớp: hỗ trợ nhiều commit trong 1 cycle =====
   always @(posedge clk ) begin
      if (!reset_n) begin
            pass_count     <= 0;
            mismatch_count <= 0;
        end
      else begin

            // Đếm số commit trong cycle
            commits_this_cycle = 0;
            if (wb_event)                    commits_this_cycle++;
            if (mem_event)                   commits_this_cycle++;
            if (branch_event)                commits_this_cycle++;
            if (jalr_pc_event)               commits_this_cycle++;
            if (jal_pc_event)                commits_this_cycle++;
            if (branch_not_taken_event)      commits_this_cycle++;

            handled_wb   = 1'b0;
            handled_mem  = 1'b0;
            handled_br   = 1'b0;
            handled_br_not_taken = 1'b0;
            handled_jalr_pc = 1'b0;
            handled_jal_pc  = 1'b0;

            for (j = 0; j < commits_this_cycle; j = j + 1) begin
               
                  if (wb_event && !handled_wb) begin
                        pc_commit    = dut.MEMWB_pc_out;
                        instr_commit = dut.MEMWB_instr_out;
                        handled_wb   = 1'b1;
                  end
                  else if (mem_event && !handled_mem) begin
                        pc_commit    = dut.EXMEM_pc_out;
                        instr_commit = dut.EXMEM_instr_out;
                        handled_mem  = 1'b1;
                  end
                  else if (branch_event && !handled_br) begin
                        pc_commit    = dut.IDEX_pc_out;          
                        instr_commit = dut.IDEX_instr_out;
                        handled_br   = 1'b1;
                  end 
                  else if (jalr_pc_event && !handled_jalr_pc) begin
                       pc_commit    = dut.IFID_pc_out;     
                       instr_commit = dut.IFID_instr_out;
                       handled_jalr_pc = 1'b1;
                  end
                  else if (jal_pc_event && !handled_jal_pc) begin
                        pc_commit   = dut.IFID_pc_out;
                        instr_commit= dut.IFID_instr_out;
                        handled_jal_pc = 1'b1;
                  end
                  else if (branch_not_taken_event && !handled_br_not_taken) begin
                        pc_commit    = dut.IDEX_pc_out;          
                        instr_commit = dut.IDEX_instr_out;
                        handled_br_not_taken   = 1'b1;
                  end
                    
                 
                  found_local = 1'b0;
                  for (i = 0; i < golden_cnt && !found_local; i = i + 1) begin
                      if (!matched_flag[i] && g_pc[i] == pc_commit && g_instr[i] == instr_commit) begin
                              matched_flag[i] <= 1'b1;
                              found_local     = 1'b1;

                              case (g_type[i])
                                    //----------------- Register ----------------
                                    0: begin
                                           // các lệnh ghi thanh ghi bình thường
                                          if (dut.RF.data_in == g_value[i] && dut.MEMWB_addr_rd_out == g_rd[i]) begin
                                                if (dut.MEMWB_is_jalr_out) begin
                                                      $display("✅ PASS JALR   pc = 0x%h instr = 0x%h x%0d = %h                        (golden_idx = %0d)",
                                                                  g_pc[i], g_instr[i], g_rd[i], g_value[i], i+1);
                                                      pass_count = pass_count + 1;
                                                end else if (dut.MEMWB_instr_out[6:0] == 7'b1101111) begin
                                                      $display("✅ PASS JAL    pc = 0x%h instr = 0x%h x%0d = %h                        (golden_idx = %0d)",
                                                                  g_pc[i], g_instr[i], g_rd[i], g_value[i], i+1);
                                                      pass_count = pass_count + 1;
                                                end else begin
                                                      $display("✅ PASS REG   pc = 0x%h instr = 0x%h x%0d = %h                        (golden_idx = %0d)",
                                                                  g_pc[i], g_instr[i], g_rd[i], g_value[i], i+1);
                                                      pass_count = pass_count + 1;
                                                end
                                          end else begin
                                                $display("❌ FAIL REG   pc = 0x%h instr = 0x%h | EXP x%0d = 0x%h | GOT x%0d = 0x%h",
                                                            g_pc[i], g_instr[i], g_rd[i], g_value[i], dut.MEMWB_addr_rd_out, dut.RF.data_in);
                                                mismatch_count = mismatch_count + 1;
                                          end
                                    end


                                    //------------------ Store ------------------- 
                                    1: if (dut.DMEM.write_data == g_value[i] && dut.DMEM.address == g_addr[i]) begin
                                                $display("✅ PASS STORE pc = 0x%h instr = 0x%h addr = 0x%h value = 0x%h  (golden_idx = %0d)",
                                                         g_pc[i], g_instr[i], g_addr[i], g_value[i], i+1);
                                                pass_count = pass_count + 1;         
                                       end else begin
                                                $display("❌ FAIL STORE pc = 0x%h instr = 0x%h | EXP addr = 0x%h value = 0x%h | GOT addr = 0x%h value = 0x%h |(golden_idx = %0d)", 
                                                         g_pc[i], g_instr[i], g_addr[i],g_value[i], dut.EXMEM_ALU_res_out ,dut.EXMEM_rs2_out, i+1);
                                                mismatch_count = mismatch_count + 1;
                                          end


                                    //------------------ Load ----------------  
                                    2: if (dut.RF.data_in == g_value[i] && dut.RF.Addr_rd == g_rd[i]) begin
                                                $display("✅ PASS LOAD  pc = 0x%h instr = 0x%h x%0d = 0x%h (addr = 0x%h)  (golden_idx = %0d)",
                                                         g_pc[i], g_instr[i], g_rd[i], g_value[i], g_addr[i], i+1);
                                                pass_count = pass_count + 1;         
                                       end else begin
                                                $display("❌ FAIL LOAD  pc = 0x%h instr = 0x%h | EXP x%0d = 0x%h | GOT x%0d = 0x%h (addr = 0x%h) | (golden_idx = %0d)",
                                                         g_pc[i], g_instr[i], g_rd[i], g_value[i], dut.MEMWB_addr_rd_out ,dut.RF.data_in, g_addr[i], i+1);
                                                mismatch_count = mismatch_count + 1;
                                       end


                                    //-------------- Branch and jalr/jal only jump-----------------
                                    3: 
                                          if (jalr_pc_event) begin
                                                      $display("✅ PASS JALR  pc = 0x%h instr = 0x%h => PC_next = 0x%h              (golden_idx = %0d)",
                                                                  g_pc[i], g_instr[i], dut.pc_jump_jalr, i+1);
                                                      pass_count = pass_count + 1; 
                                          end else if (jal_pc_event) begin
                                                      $display("✅ PASS JAL  pc = 0x%h instr = 0x%h => PC_next = 0x%h                (golden_idx = %0d)",
                                                                  g_pc[i], g_instr[i], dut.pc_jump_jal, i+1);
                                                      pass_count = pass_count + 1;                         

                                          end else if (branch_event) begin
                                                      $display("✅ PASS BRANCH pc = 0x%h instr = 0x%h => PC_next = 0x%h              (golden_idx = %0d)",
                                                                  g_pc[i], g_instr[i], dut.alu_out, i+1);
                                                      pass_count = pass_count + 1;            

                                          end else if(branch_not_taken_event) begin
                                                      $display("✅ PASS BR. not taken  pc = 0x%h  instr = 0x%h                             (golden_idx = %0d)",
                                                                  g_pc[i], g_instr[i], i+1);
                                                      pass_count = pass_count + 1;            
                                          end
                                      
                               endcase
                              
                      end
                  end
             end
       end
  end

    always @(posedge clk) begin
        if (dut.MEMWB_trapReq_out) begin
            $display("⚠️  ECALL/EBREAK detected - stop simulation \n");
            $display("✅ Pass = %0d, ❌ Mismatch = %0d", pass_count, mismatch_count);
            if (mismatch_count==0) $display("🎉  TEST PASS");
            else                   $display("⚠️  TEST FAIL");
            $display("------------------------------------------------------------------------------------------------------");
            $finish;         
        end
    end

  // ===== KẾT THÚC =====
  initial begin
      #26000;
      $display("\n-------------------Simulation Summary -----------------");
            $display("✅ Pass = %0d, ❌ Mismatch = %0d", pass_count, mismatch_count);
            if (mismatch_count==0) $display("🎉  TEST PASS");
            else                   $display("⚠️  TEST FAIL");
      $display("------------------------------------------------------------------------------------------------------------");
      $finish;
  end

endmodule
