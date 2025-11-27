module IF_ID(
    input wire clk, reset,
    input wire IFID_write,
    input wire flush_trap, flush_jal, flush_branch,
    input wire [31:0] pc_in, instr_in,
    output reg [31:0] pc_out, instr_out
);
  localparam NOP = 32'h00000013; // addi x0, x0, 0

  always @(posedge clk or negedge reset) begin
      if (!reset) begin
          pc_out    <= 32'b0;
          instr_out <= NOP;
      end 
      // ===== ƯU TIÊN 1: TRAP =====
      else if (flush_trap) begin
          pc_out    <= 32'b0; 
          instr_out <= NOP;
      end
      // ===== ƯU TIÊN 2: BRANCH hoặc JAL =====
      else if (flush_branch || flush_jal) begin
          pc_out    <= pc_in;
          instr_out <= NOP;
      end 
      // ===== ƯU TIÊN 3: BÌNH THƯỜNG =====
      else if (IFID_write) begin
          pc_out    <= pc_in;
          instr_out <= instr_in;
      end 
      // ===== ƯU TIÊN 4: STALL =====
      else begin
          // giữ nguyên pc_out, instr_out
      end
  end
endmodule
