module EX_MEM(
  input wire        clk, reset,
  input wire [31:0] ALU_res_in, rs2_in, pc_in, instr_in,
  input wire [4:0]  addr_rd_in,
  input wire [2:0]  funct3_in,
  input wire        BrEq_in, BrLT_in,
  input wire        MemW_in, PCSel_in, regWEn_in, trapReq_in, memRead_in, is_jalr_in, is_div_in, 
  input wire [1:0]  WBSel_in,

  output reg [31:0] ALU_res_out, rs2_out, pc_out, instr_out,
  output reg [4:0]  addr_rd_out,
  output reg [2:0]  funct3_out,
  output reg        BrEq_out, BrLT_out,
  output reg        MemW_out, regWEn_out, trapReq_out, memRead_out,is_jalr_out, is_div_out,
  output reg [1:0]  WBSel_out
);

 always @(posedge clk or negedge reset) begin
    if (!reset) begin
        ALU_res_out <= 32'b0;
        rs2_out     <= 32'b0;
        pc_out      <= 32'b0;
        instr_out   <= 32'b0;
        addr_rd_out <= 5'b0;
        funct3_out  <= 3'b0;
        trapReq_out <= 1'b0;
        BrEq_out    <= 1'b0;
        is_jalr_out <= 1'b0;
        is_div_out  <= 1'b0;
        BrLT_out    <= 1'b0;
        MemW_out    <= 1'b0;
        memRead_out <= 1'b0;
        regWEn_out  <= 1'b0;
        WBSel_out   <= 2'b0;
    end else begin
        ALU_res_out <= ALU_res_in;
        rs2_out     <= rs2_in;
        pc_out      <= pc_in;
        instr_out   <= instr_in;
        addr_rd_out <= addr_rd_in;
        funct3_out  <= funct3_in;
        trapReq_out <= trapReq_in;
        BrEq_out    <= BrEq_in;
        BrLT_out    <= BrLT_in;
        is_jalr_out <= is_jalr_in;
        is_div_out  <= is_div_in;
        MemW_out    <= MemW_in;
        memRead_out <= memRead_in;
        regWEn_out  <= regWEn_in;
        WBSel_out   <= WBSel_in;
    end
 end
endmodule