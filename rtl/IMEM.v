module IMEM(
    input wire [31 : 0] address,
    output reg [31 : 0] instruction
);

  reg [31 : 0] memory [1023:0]; 
  always @(*) begin
         instruction = memory[address[10 : 2]]; 
  end
  
endmodule
