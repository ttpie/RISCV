module ALU_RV32IM(
    input wire [31 : 0] A, B,
    input wire [4 : 0] ALU_Sel,
    output reg [31 : 0] ALU_Out
);  
    reg signed [63:0] product;
    always @(*) begin
       case(ALU_Sel)   
            5'b00000: ALU_Out = A + B; //ADD, addi, auipc, load, store,
            5'b00001: ALU_Out = A - B; //SUB
            5'b00010: ALU_Out = A & B; //and, andi
            5'b00011: ALU_Out = A | B; //OR, ori
            5'b00100: ALU_Out = A ^ B; //XOR, xori
            5'b00101: ALU_Out = A << B; //SLL, slli
            5'b00110: ALU_Out = A >> B; //SRL, srli
            5'b00111: ALU_Out = $signed(A) >>> B[4 : 0]; //SRA, srai
            5'b01000: ALU_Out = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; //SLT, slti
            5'b01001: ALU_Out = (A < B) ? 32'b1 : 32'b0; //sltu, sltiu
            5'b01010: ALU_Out = B; // LUI: imm << 12
            5'b01011: ALU_Out = $signed(A) * $signed(B); // MUL
            5'b01100: begin // MULH
                        product = $signed(A) * $signed(B);
                        ALU_Out = product[63:32];
                     end
            5'b01101: begin // MULHSU
                        product = $signed(A) * $unsigned(B);
                        ALU_Out = product[63:32];
                     end
            5'b01110: begin // MULHU
                        product = $unsigned(A) * $unsigned(B);
                        ALU_Out = product[63:32];
                     end
            // 5'b01111: ALU_Out = $signed(A) / $signed(B); //div
            // 5'b10000: ALU_Out = A / B; //DIVU 
            // 5'b10001: ALU_Out = $signed(A) % $signed(B); // REM
            // 5'b10010: ALU_Out = A % B; //REMU
            5'b11111: ALU_Out = 32'b0; 
            default: ALU_Out = 32'b0;
       endcase
    end
endmodule

