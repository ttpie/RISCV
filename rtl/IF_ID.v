
module IF_ID(
    input wire clk, reset,
    input wire write_enable,
    input wire flush_jal, flush_branch,
    input wire [31:0] pc_in, instr_in,
    output reg [31:0] pc_out, instr_out
);
  localparam NOP = 32'h00000013; // addi x0, x0, 0

  always @(posedge clk or negedge reset) begin
    if (!reset) begin
        pc_out    <= 32'b0;
        instr_out <= NOP;
    end 
    else if (flush_jal || flush_branch) begin
        pc_out    <= pc_in;
        instr_out <= NOP;
    end else if (write_enable) begin
        pc_out    <= pc_in;
        instr_out <= instr_in;
    end else begin
      // Stall → giữ nguyên pipeline và instruction 

    end
  end
endmodule
