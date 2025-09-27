module ID_EX (
   input wire clk, reset, IDEX_write, flush_branch,
   input wire [31:0] pc_in, rs1_in, rs2_in, imm_in, instr_in,
   input wire        BrUn_in, regWEn_in, MemRW_in, BSel_in, ASel_in, trapReq_in, memRead_in, branch_in, is_jalr_in,
   input wire [1:0]  WBSel_in,
   input wire [2:0] funct3_in,
   input wire [4:0]  ALUSel_in,
   input wire [4:0]  addr_rd_in, addr_rs1_in, addr_rs2_in,

   output reg [31:0] pc_out, rs1_out, rs2_out, imm_out, instr_out,
   output reg        BrUn_out, regWEn_out, MemRW_out, BSel_out, ASel_out, trapReq_out, memRead_out, branch_out, is_jalr_out,
   output reg [1:0]  WBSel_out,
   output reg [2:0]  funct3_out,
   output reg [4:0]  ALUSel_out,
   output reg [4:0]  addr_rd_out, addr_rs1_out, addr_rs2_out   
);
 
  always @(posedge clk or negedge reset ) begin
      if(!reset) begin
           pc_out <= 32'b0;
           instr_out <= 32'b0;
           addr_rd_out <= 5'b0;
           addr_rs1_out <= 5'b0;
           addr_rs2_out <= 5'b0;
           funct3_out <= 3'b0;
           rs1_out <= 32'b0;
           rs2_out <= 32'b0;
           imm_out <= 32'b0;
           is_jalr_out <= 1'b0;
           trapReq_out <= 1'b0;
           branch_out <= 1'b0;
           BrUn_out <= 1'b0;
           regWEn_out <= 1'b0;
           MemRW_out <= 1'b0;
           memRead_out <= 1'b0;
           BSel_out <= 1'b0;
           ASel_out <= 1'b0;
           WBSel_out <= 2'b0;
           ALUSel_out <= 5'b0;
      end else if (flush_branch) begin // Flush if branch taken --- IGNORE ---
           pc_out <= 32'b0;
           instr_out <= 32'b0;
           addr_rd_out <= 5'b0;
           addr_rs1_out <= 5'b0;
           addr_rs2_out <= 5'b0;
           funct3_out <= 3'b0;
           rs1_out <= 32'b0;
           rs2_out <= 32'b0;
           imm_out <= 32'b0;
           trapReq_out <= 1'b0;
           is_jalr_out <= 1'b0;
           branch_out <= 1'b0;
           BrUn_out <= 1'b0;
           regWEn_out <= 1'b0;
           MemRW_out <= 1'b0;
           memRead_out <= 1'b0;
           BSel_out <= 1'b0;
           ASel_out <= 1'b0;
           WBSel_out <= 2'b0;
           ALUSel_out <= 5'b0;   

      end else if (IDEX_write) begin 
           pc_out <= pc_in;
           instr_out <= instr_in;
           addr_rd_out <= addr_rd_in;
           addr_rs1_out <= addr_rs1_in;
           addr_rs2_out <= addr_rs2_in;
           funct3_out <= funct3_in;
           rs1_out <= rs1_in;
           rs2_out <= rs2_in;
           imm_out <= imm_in;
           trapReq_out <= trapReq_in;
           branch_out <= branch_in;
           is_jalr_out <= is_jalr_in;
           BrUn_out <= BrUn_in;
           regWEn_out <= regWEn_in;
           MemRW_out <= MemRW_in;
           memRead_out <= memRead_in;
           BSel_out <= BSel_in;
           ASel_out <= ASel_in;
           WBSel_out <= WBSel_in;
           ALUSel_out <= ALUSel_in;

      end else begin // stall, giữ nguyên giá trị cũ
           pc_out <= 32'b0;
           instr_out <= 32'b0;
           addr_rd_out <= 5'b0;
           addr_rs1_out <= 5'b0;
           addr_rs2_out <= 5'b0;
           funct3_out <= 3'b0;
           rs1_out <= 32'b0;
           rs2_out <= 32'b0;
           imm_out <= 32'b0;
           trapReq_out <= 1'b0;
           branch_out <= 1'b0;
           BrUn_out <= 1'b0;
           regWEn_out <= 1'b0;
           MemRW_out <= 1'b0;
           memRead_out <= 1'b0;
           BSel_out <= 1'b0;
           ASel_out <= 1'b0;
           WBSel_out <= 2'b0;
           ALUSel_out <= 5'b0;
      end
   end

endmodule