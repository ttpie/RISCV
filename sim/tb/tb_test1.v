`timescale 1ns/1ps
module tb_core_test1;
  
  parameter START_PC = 32'h80000000;
  reg clk, reset_n;
  integer cycle;

  // --- Golden file ---
  reg [31:0] pc_commit;
  reg [31:0] instr_commit;
  integer fd_golden, ret, pass_count, mismatch_count, nfields;
  reg [1023:0] line, line_next;
  reg [31:0] g_pc, g_instr, g_val, g_addr, rf_val, g_pc_next, g_instr_next;
  reg [255:0] g_token, g_memtoken, s_pc, s_instr, s_val, s_addr, s_pc_next, s_instr_next;
  integer g_rd, ret2;
  reg is_branch_instr, is_jalr_instr;
  integer commits_this_cycle;
  
  // --- DUT ---
  top_module dut (
    .clk(clk),
    .reset_n(reset_n)
  );

  // Clock
  always #5 clk = ~clk;

  initial begin
        clk = 1;
        reset_n = 0;
        cycle = 0;
        mismatch_count = 0;
        pass_count  = 0;
        nfields = 0;

        $dumpfile("tb_test1.vcd");
        $dumpvars(0, tb_core_test1);
        $readmemh("data/hex/imem_test_full.hex", dut.IMEM.memory, 0, 1023);
        $readmemh("data/hex/init_dmem.hex", dut.DMEM.memory, 0, 1023);
         
        fd_golden = $fopen("data/golden/golden_test_full_filtered.txt", "r");
        if (fd_golden == 0) begin
          $display("❌ Cannot open golden trace file");
          $finish;
        end

        #20 reset_n = 1;
  end

  always @(posedge clk) begin
    cycle <= cycle + 1;
  end

  // Commit events
      wire wb_event  = (dut.MEMWB_regWEn_out && (dut.MEMWB_addr_rd_out != 0)); // register, load
      wire mem_event = dut.EXMEM_MemRW_out; // store
      wire branch_event = dut.IDEX_branch_out;
      wire jalr_event = (dut.is_jalr);
      wire commit_event = wb_event || mem_event;

  //--------------------------------------------------------------------------------    
      reg                have_buffered_line;
      reg [1023:0]       buffered_line;
      initial begin
          have_buffered_line = 0;
      end
      always @(posedge clk or negedge reset_n) begin
          if (!reset_n)
              have_buffered_line <= 1'b0;
      end

  //---------------------------------------------------------------------------------
    task parse_and_check(input [1023:0] line);
    begin
          s_pc = 0; s_instr = 0; s_val = 0; s_addr = 0;
          g_token = 0; g_memtoken = 0;
          g_pc = 0; g_instr = 0; g_val = 0; g_addr = 0; g_rd = 0;

          nfields = $sscanf(line, "%s %s %s %s %s %s",
                            s_pc, s_instr, g_token, s_val, g_memtoken, s_addr);

          if ($sscanf(s_pc, "0x%h", g_pc) != 1) g_pc = 0;
          if ($sscanf(s_instr, "0x%h", g_instr) != 1) g_instr = 0;

          is_branch_instr = (g_instr[6:0] == 7'b1100011);
          is_jalr_instr = (g_instr[6:0] == 7'b1100111);

        //========================================================
        // ---------------------- JALR case -----------------------
        if (is_jalr_instr) begin
              buffered_line = "";
              ret2 = $fgets(buffered_line, fd_golden);
              if (ret2 == 0) begin
                 $display("❌ Unexpected EOF while reading jalr next-line");
                 $finish;
              end

            have_buffered_line = 1;
            nfields = $sscanf(buffered_line, "%s %s %s %s %s %s",
                        s_pc_next, s_instr_next, g_token, s_val,
                        g_memtoken, s_addr);

            if ($sscanf(s_pc_next, "0x%h", g_pc_next) != 1) g_pc_next = 0;
            // so khớp PC nhảy
              if (dut.PC_next !== g_pc_next) begin
                  $display("❌ JALR mismatch at   PC = 0x%h: DUT next = 0x%h, GOLDEN next = 0x%h",
                            g_pc, dut.PC_next, g_pc_next);
                  mismatch_count++;
              end else begin
                  $display("✅ JALR match at      PC = 0x%h -> next PC = 0x%h",
                          g_pc, g_pc_next);
                    pass_count++;
              end
        end

          //===========================================================
          // ---------------------- Branch case -----------------------

          else if (is_branch_instr) begin
              buffered_line = "";
              ret2 = $fgets(buffered_line, fd_golden);
            
            if (ret2 == 0) begin
                      $display("❌ Unexpected EOF while reading branch next-line");
                      $finish;
                    end
            have_buffered_line = 1;

            nfields = $sscanf(buffered_line, "%s %s %s %s %s %s",
                            s_pc_next, s_instr_next, g_token, s_val, g_memtoken, s_addr);

            if ($sscanf(s_pc_next, "0x%h", g_pc_next) != 1) g_pc_next = 0;
            if ($sscanf(s_instr_next, "0x%h", g_instr_next) != 1) g_instr_next = 0;

            if (dut.take_branch) begin
                if (dut.PC_next !== g_pc_next) begin
                  $display("❌ BRANCH mismatch at PC = 0x%h: DUT next = 0x%h, GOLDEN next = 0x%h",
                            g_pc, dut.PC_next, g_pc_next);
                            mismatch_count++;
                end else begin
                            $display("✅ BRANCH match at    PC = 0x%h -> next PC = 0x%h", g_pc, g_pc_next);
                            pass_count++;
                          end

                  end else begin
                        if (g_pc_next !== (g_pc + 32'h4)) begin
                          $display("❌ BRANCH mismatch at PC = 0x%h: expected next = 0x%h, GOLDEN next = 0x%h",
                                g_pc, g_pc + 32'h4, g_pc_next);
                                mismatch_count++;
                          end else begin
                                $display("✅ BRANCH (no_taken) match at    PC = 0x%h -> next PC = 0x%h", g_pc, g_pc_next);
                                pass_count++;
                        end
                  end
            end

           //=====================================================================
           // ------------------------ STORE case --------------------------------

           else if (g_token == "mem") begin
              if ($sscanf(s_val,   "0x%h", g_addr) != 1) g_addr = 0;
              if ($sscanf(g_memtoken,"0x%h", g_val)  != 1) g_val  = 0;

                if (dut.DMEM.address !== g_addr || dut.DMEM.write_data !== g_val) begin
                            $display("❌ STORE mismatch at  PC = 0x%h: DUT addr=%h data=%h, GOLDEN addr=%h data=%h",
                                    g_pc, dut.EXMEM_ALU_res_out, dut.EXMEM_rs2_out, g_addr, g_val);
                            mismatch_count++;
                    end else begin
                            $display("✅ STORE match at     PC = 0x%h: addr=%h data=%h", g_pc, g_addr, g_val);
                            pass_count++;
                    end
            end

           //===================================================================
           // ---------------------------- LOAD case ---------------------------

            else if (g_memtoken == "mem") begin
                  if ($sscanf(g_token,  "x%d", g_rd)   != 1) g_rd   = 0;
                  if ($sscanf(s_val,  "0x%h", g_val) != 1) g_val  = 0;
                  if ($sscanf(s_addr, "0x%h", g_addr)!= 1) g_addr = 0;

                  rf_val = dut.RF.data_in;

                  if (dut.RF.Addr_rd !== g_rd || rf_val !== g_val) begin
                              $display("❌ LOAD mismatch at   PC = 0x%h: DUT x%0d=%h, GOLDEN x%0d=%h (from mem[%h])",
                                      g_pc, dut.MEMWB_addr_rd_out, rf_val, g_rd, g_val, g_addr);
                              mismatch_count++;
                      end else begin
                              $display("✅ LOAD match at      PC = 0x%h: x%0d=%h (from mem[%h])",
                                      g_pc, g_rd, g_val, g_addr);
                              pass_count++;
                    end
                end

             //=================================================================
             // ----------------------- REG WRITE case -------------------------

            else begin
                  if ($sscanf(g_token, "x%d", g_rd)   != 1) g_rd   = 0;
                  if ($sscanf(s_val, "0x%h", g_val) != 1) g_val  = 0;

                      if (dut.MEMWB_addr_rd_out !== g_rd || dut.data_in !== g_val) begin
                              $display("❌ REG mismatch at    PC = 0x%h: DUT x%0d=%h, GOLDEN x%0d=%h",
                                        g_pc, dut.MEMWB_addr_rd_out, dut.data_in, g_rd, g_val);
                              mismatch_count++;
                      end else begin
                              $display("✅ REG match at       PC = 0x%h: x%0d=%h", g_pc, g_rd, g_val);
                              pass_count++;
                      end
               end
         end
  endtask


  // ========================================
  //             Main compare loop
  // ========================================

    always @(posedge clk) begin
        if (!reset_n) begin
          pass_count     <= 0;
          mismatch_count <= 0;
        end
        else if (commit_event) begin
            commits_this_cycle = 0;
            if (wb_event)  commits_this_cycle++;
            if (mem_event) commits_this_cycle++;
            //---------------------------------------------------------
            // 1) So khớp riêng cho branch hoặc jalr (không ghi reg)
            //---------------------------------------------------------
              if (branch_event || jalr_event) begin
                  if (have_buffered_line) begin
                    line = buffered_line;
                    have_buffered_line = 0;
                  end
                  else begin
                    ret = $fgets(line, fd_golden);
                    if (ret == 0) $finish;
                  end
                  parse_and_check(line);
              end
              //---------------------------------------------------------
              // 2) So khớp cho các lệnh commit ghi reg / store
              //---------------------------------------------------------
                for (integer i = 0; i < commits_this_cycle; i++) begin
                    if (have_buffered_line) begin
                      line = buffered_line;
                      have_buffered_line = 0;
                    end
                    else begin
                      ret = $fgets(line, fd_golden);
                      if (ret == 0) $finish;
                    end
                    parse_and_check(line);
                end
            end
     end


    always @(posedge clk) begin
        if (dut.MEMWB_trapReq_out) begin
            $display("⚠️  ECALL/EBREAK detected - stop simulation \n");
            $display("✅ Pass = %0d, ❌ Mismatch = %0d \n", pass_count, mismatch_count);
            $finish;         
        end
    end


  initial begin 
      #2000; 
      $display("\n-------------------Simulation Summary -----------------");
      $display("✅ Pass = %0d, ❌ Mismatch = %0d", pass_count, mismatch_count);
      if (mismatch_count==0) $display("🎉  TEST PASS");
      else                   $display("⚠️  TEST FAIL");
      $display("-------------------------------------------------------");
      $finish;
  end

endmodule

