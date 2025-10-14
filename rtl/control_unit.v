module control_unit(
    input wire [31 : 0] instruction,
    input wire BrEq,
    input wire BrLt,
    output reg BrUn,
    output reg regWEn,
    output reg MemW,
    output reg BSel,
    output reg ASel,
    output reg flush,
    output reg is_jalr,
    output reg is_div,
    output reg memRead,
    output reg branch,
    output reg trapReq,
    output reg [1:0] div_mode, // 00:DIV, 01:DIVU, 10:REM, 11:REMU
    output reg [1 : 0] WBSel,
    output reg [4 : 0] ALUSel
);

always @(*) begin

   case (instruction[6 : 0]) // opcode

   // R-type instructions
   7'b0110011: begin
       trapReq = 1'b0;
       is_jalr = 1'b0;
       branch  = 1'b0;
       flush   = 1'b0;
       regWEn = 1'b1; // ghi vào register
       WBSel  = 2'b01; // ALU result
       memRead = 1'b0;
       MemW  = 1'b0;
       BSel   = 1'b0; // rs2
       ASel   = 1'b0; // rs1
       case (instruction[14 : 12]) // funct3
            3'b000: begin
               case (instruction[31 : 25]) // funct7
                  7'b0000000: ALUSel = 5'b00000; // ADD
                  7'b0100000: ALUSel = 5'b00001; // SUB
                  7'b0000001: ALUSel = 5'b01011; // MUL
                  default:    ALUSel = 5'b11111;
               endcase
            end

            3'b111: begin 
                  case (instruction[31 : 25]) // funct7
                     7'b0000000: ALUSel = 5'b00010; // AND
                     7'b0000001: begin
                        is_div = 1'b1;
                        div_mode = 2'b11; // REMU
                     end
                     default: ALUSel = 5'b11111;
                  endcase
            end

            3'b110: begin
                  case (instruction[31 : 25]) // funct7
                     7'b0000000: ALUSel = 5'b00011; // OR
                     7'b0000001: begin
                        is_div = 1'b1;
                        div_mode = 2'b10; // REM
                     end
                     default:    ALUSel = 5'b11111;
                  endcase
            end

            3'b100: begin
                  case (instruction[31 : 25]) // funct7
                     7'b0000000: ALUSel = 5'b00100; // XOR
                     7'b0000001: begin
                        is_div = 1'b1;
                        div_mode = 2'b00; // DIV
                     end
                     default:    ALUSel = 5'b11111;
                  endcase
            end

            3'b001: begin
                  case (instruction[31 : 25]) // funct7
                     7'b0000000: ALUSel = 5'b00101; // SLL
                     7'b0000001: ALUSel = 5'b01100; // MULH
                     default:    ALUSel = 5'b11111;
                  endcase
            end

            3'b101: begin
               case (instruction[31 : 25]) // funct7
                  7'b0000000: ALUSel = 5'b00110; // SRL
                  7'b0100000: ALUSel = 5'b00111; // SRA
                  7'b0000001: begin
                     is_div = 1'b1;
                     div_mode = 2'b01; // DIVU
                  end
                  default:    ALUSel = 5'b11111;
               endcase
            end 

            3'b010: begin
               case (instruction[31 : 25]) // funct7
                  7'b0000000: ALUSel = 5'b01000; // SLT
                  7'b0000001: ALUSel = 5'b01101; // MULHSU
                  default:    ALUSel = 5'b11111;
               endcase
            end
            
            3'b011: begin
               case (instruction[31 : 25]) // funct7
                  7'b0000000: ALUSel = 5'b01001; // SLTU
                  7'b0000001: ALUSel = 5'b01110; // MULHU
                  default:    ALUSel = 5'b11111;
               endcase
            end
            default: ALUSel = 5'b11111;
         endcase
   end
   
   // I-type bitwise, shift, immediate
   7'b0010011: begin
         is_div = 1'b0;
         div_mode = 2'b00;
         trapReq = 1'b0;
         is_jalr = 1'b0;
         branch  = 1'b0;
         flush   = 1'b0;
         regWEn = 1'b1;
         BSel   = 1'b1; // chọn immediate
         ASel   = 1'b0;
         WBSel  = 2'b01; // ALU result
         MemW  = 1'b0;
         memRead = 1'b0;

         case (instruction[14 : 12])
             3'b000: ALUSel = 5'b00000; // ADDI
             3'b111: ALUSel = 5'b00010; // ANDI
             3'b110: ALUSel = 5'b00011; // ORI
             3'b100: ALUSel = 5'b00100; // XORI
             3'b001: ALUSel = 5'b00101; // SLLI
             3'b101: begin
                case (instruction[31 : 25])
                    7'b0000000: ALUSel = 5'b00110; // SRLI
                    7'b0100000: ALUSel = 5'b00111; // SRAI
                    default:    ALUSel = 5'b11111;
                endcase
             end
             3'b010: ALUSel = 5'b01000; // SLTI
             3'b011: ALUSel = 5'b01001; // SLTIU
             default: ALUSel = 5'b11111;
         endcase
   end

   // I-type load
   7'b0000011: begin
         is_div = 1'b0;
         div_mode = 2'b00;
         trapReq = 1'b0;
         is_jalr = 1'b0;
         branch  = 1'b0;
         flush   = 1'b0;
         regWEn = 1'b1;
         BSel   = 1'b1;
         ASel   = 1'b0;
         MemW  = 1'b0;
         memRead = 1'b1;
         ALUSel = 5'b00000; // ADD
         WBSel  = 2'b00;   // data from memory
   end

   // I-type JALR
   7'b1100111: begin
         is_div = 1'b0;
         div_mode = 2'b00;
         trapReq = 1'b0;
         is_jalr = 1'b1;
         branch  = 1'b0;
         flush   = 1'b1; // Flush the next instruction
         regWEn  = 1'b1;
         BSel    = 1'b1;
         ASel    = 1'b0;
         MemW   = 1'b0;
         memRead = 1'b0;
         ALUSel  = 5'b00000;
         WBSel   = 2'b10; // PC+4
   end

   // S-type store
   7'b0100011: begin
         is_div = 1'b0;
         div_mode = 2'b00;
         trapReq = 1'b0;
         is_jalr = 1'b0;
         branch  = 1'b0;
         flush   = 1'b0;
         regWEn = 1'b0;
         BSel   = 1'b1;
         ASel   = 1'b0;
         MemW  = 1'b1;
         memRead = 1'b0;
         ALUSel = 5'b00000;
   end

   // U-type: AUIPC
   7'b0010111: begin
         is_div = 1'b0;
         div_mode = 2'b00;
         trapReq = 1'b0;
         is_jalr = 1'b0;
         branch  = 1'b0;
         flush   = 1'b0;
         regWEn = 1'b1;
         BSel   = 1'b1; // imm
         ASel   = 1'b1; // PC
         MemW  = 1'b0;
         memRead = 1'b0;
         ALUSel = 5'b00000; // pc + imm
         WBSel  = 2'b01; // ALU result
   end

   // U-type: LUI
   7'b0110111: begin
         is_div = 1'b0;
         div_mode = 2'b00;
         trapReq = 1'b0;
         is_jalr = 1'b0;
         branch  = 1'b0;
         flush   = 1'b0;
         regWEn = 1'b1;
         BSel   = 1'b1;
         ASel   = 1'b0; // lấy imm << 12, không quan tâm rs1
         MemW  = 1'b0;
         memRead = 1'b0;
         ALUSel = 5'b01010; // LUI: imm << 12
         WBSel  = 2'b01; // ALU result
     end

   // J-type: JAL
   7'b1101111: begin
         is_div = 1'b0;
         div_mode = 2'b00;
         trapReq = 1'b0;
         is_jalr = 1'b0;
         branch  = 1'b0;
         flush   = 1'b1; // Flush the next instruction
         regWEn = 1'b1;
         BSel   = 1'b1; // lấy imm
         ASel   = 1'b1; // PC
         MemW  = 1'b0;
         memRead = 1'b0;
         ALUSel = 5'b00000; // ADD
         WBSel  = 2'b10; // PC+4
   end
   // B-type branch
   7'b1100011: begin
      is_div = 1'b0;
      div_mode = 2'b00;
      trapReq  = 1'b0;
      is_jalr = 1'b0;
      branch   = 1'b1;
      flush    = 1'b0;
      regWEn   = 1'b0;
      BSel     = 1'b1; // imm
      ASel     = 1'b1; // pc
      MemW    = 1'b0;
      memRead  = 1'b0;
      ALUSel   = 5'b00000; // ADD

      case (instruction[14:12]) 
         3'b100: begin
            BrUn = 1'b0; 
         end
         3'b101: begin
            BrUn = 1'b0; 
         end
         3'b110: begin
            BrUn = 1'b1; 
         end
         3'b111: begin
            BrUn = 1'b1; 
         end
         default:begin
            BrUn = 1'b0;
         end 
      endcase
   end

   7'b1110011: begin // system (ecall, ebreak)
         is_div = 1'b0;
         div_mode = 2'b00;
         trapReq = 1'b1;
         is_jalr = 1'b0;
         branch  = 1'b0;
         flush   = 1'b0;
         regWEn  = 1'b0;
         MemW   = 1'b0;
         memRead = 1'b0;
         BSel    = 1'b0;
         ASel    = 1'b0;
         ALUSel  = 5'b11111;
         WBSel   = 2'b00;
   end

   endcase
end
endmodule