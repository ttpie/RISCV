module MEM_WB(
   input wire        clk, reset,
   input wire [31:0] mem_data_in, ALU_res_in, pc_in, instr_in, data_write_in,
   input wire [4:0]  addr_rd_in,
   input wire [1:0]  WBSel_in,
   input wire        PCSel_in, regWEn_in, trapReq_in, is_jalr_in,

   output reg [31:0] mem_data_out, ALU_res_out, pc_out, instr_out,
   output reg [4:0]  addr_rd_out,
   output reg [1:0]  WBSel_out,
   output reg        regWEn_out, trapReq_out, is_jalr_out
);
  always @(posedge clk or negedge reset) begin
     if(!reset) begin
         mem_data_out <= 32'b0;
         ALU_res_out  <= 32'b0;
         pc_out       <= 32'b0;
         instr_out    <= 32'b0;
         addr_rd_out  <= 5'b0;
         WBSel_out    <= 2'b0;
         trapReq_out  <= 1'b0;
         regWEn_out   <= 1'b0;
         is_jalr_out  <= 1'b0;

     end else begin
         mem_data_out <= mem_data_in;
         ALU_res_out  <= ALU_res_in;
         pc_out       <= pc_in;
         instr_out    <= instr_in;
         addr_rd_out  <= addr_rd_in;
         WBSel_out    <= WBSel_in;
         trapReq_out  <= trapReq_in;
         regWEn_out   <= regWEn_in; 
         is_jalr_out  <= is_jalr_in;
     end
  end
endmodule