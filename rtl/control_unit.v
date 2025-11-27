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
    output reg csr_we, // CSR write enable
    output reg [11 : 0] csr_addr,
    output reg [2 : 0] csr_op,
    output reg trapReq,  //trap_taken 
    output reg [31:0] trap_cause,
    output reg [31:0] trap_tval,
    output reg mret_exec,
    output reg [1:0] div_mode, // 00:DIV, 01:DIVU, 10:REM, 11:REMU
    output reg [1 : 0] WBSel,  // 00: from memory, 01: from ALU, 10: PC+4, 11: csr_rdata
    output reg [4 : 0] ALUSel
);

localparam CSR_NOP   = 3'b000;
localparam CSRRW     = 3'b001;
localparam CSRRS     = 3'b010;
localparam CSRRC     = 3'b011;
localparam CSRRWI    = 3'b100;
localparam CSRRSI    = 3'b101;
localparam CSRRCI    = 3'b110;

always @(*) begin

   case (instruction[6 : 0]) // opcode

   // R-type instructions
   7'b0110011: begin
       is_div = 1'b0;
       div_mode = 2'b00;
       csr_we = 1'b0;
       csr_addr = 12'b0;
       csr_op = CSR_NOP;
       trap_cause = 32'd0;
       trap_tval  = 32'd0;
       mret_exec  = 1'b0;
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
                  default: ALUSel = 5'b11111;
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
                     default: ALUSel = 5'b11111;
                  
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
                     default: ALUSel = 5'b11111;
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
                  default: ALUSel = 5'b11111;
               endcase
            end
            
            3'b011: begin
               case (instruction[31 : 25]) // funct7
                  7'b0000000: ALUSel = 5'b01001; // SLTU
                  7'b0000001: ALUSel = 5'b01110; // MULHU
                  default:    ALUSel = 5'b11111;
               endcase
            end
            default: begin 
                   ALUSel = 5'b11111;
                   is_div = 1'b0;
            end
         endcase
   end
   
   // I-type bitwise, shift, immediate
   7'b0010011: begin
         
         is_div = 1'b0;
         div_mode = 2'b00;
         csr_we = 1'b0;
         csr_addr = 12'b0;
         csr_op = CSR_NOP;
         trap_cause = 32'd0;
         trap_tval  = 32'd0;
         mret_exec  = 1'b0;
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
         csr_we = 1'b0;
         csr_addr = 12'b0;
         csr_op = CSR_NOP;
         trap_cause = 32'd0;
         trap_tval  = 32'd0;
         mret_exec  = 1'b0;
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
         csr_we = 1'b0;
         csr_addr = 12'b0;
         csr_op = CSR_NOP;
         trap_cause = 32'd0;
         trap_tval  = 32'd0;
         mret_exec  = 1'b0;
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
         csr_we = 1'b0;
         csr_addr = 12'b0;
         csr_op = CSR_NOP;
         trap_cause = 32'd0;
         trap_tval  = 32'd0;
         mret_exec  = 1'b0;
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
         WBSel  = 2'b00;
   end

   // U-type: AUIPC
   7'b0010111: begin
         is_div = 1'b0;
         div_mode = 2'b00;
         csr_we = 1'b0;
         csr_addr = 12'b0;
         csr_op = CSR_NOP;
         trap_cause = 32'd0;
         trap_tval  = 32'd0;
         mret_exec  = 1'b0;
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
         csr_we = 1'b0;
         csr_addr = 12'b0;
         csr_op = CSR_NOP;
         trap_cause = 32'd0;
         trap_tval  = 32'd0;
         mret_exec  = 1'b0;
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
         csr_we = 1'b0;
         csr_addr = 12'b0;
         csr_op = CSR_NOP;
         trap_cause = 32'd0;
         trap_tval  = 32'd0;
         mret_exec  = 1'b0;
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
      csr_we = 1'b0;
      csr_addr = 12'b0;
      csr_op = CSR_NOP;
      trap_cause = 32'd0;
      trap_tval  = 32'd0;
      mret_exec  = 1'b0;
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
         is_jalr = 1'b0;
         branch  = 1'b0;
         MemW   = 1'b0;
         memRead = 1'b0;
         BSel    = 1'b0;
         ASel    = 1'b0;
         ALUSel  = 5'b11111;

            case (instruction[14:12])
                  3'b000: begin // ECALL or MRET
                  if (instruction[31:20] == 12'b000000000000) begin
                        // ECALL
                        trap_cause = 32'd11; // Environment call from M-mode
                        trap_tval  = 32'd0;
                        trapReq    = 1'b1;
                        mret_exec  = 1'b0;
                        csr_addr    = 12'b0;
                        csr_op      = CSR_NOP;
                        csr_we      = 1'b0;
                        flush       = 1'b1;
                        regWEn     = 1'b0;
                        WBSel       = 2'b00;
                  end
                  else if (instruction[31:20] == 12'b001100000010) begin
                        // MRET
                        mret_exec = 1'b1;
                        trapReq   = 1'b0;
                        trap_cause = 32'd0;
                        trap_tval  = 32'd0;
                        csr_addr    = 12'b0;
                        csr_op      = CSR_NOP;
                        csr_we      = 1'b0;
                        flush       = 1'b1;
                        regWEn     = 1'b0;
                        WBSel       = 2'b00;
                  end
                  end

                  3'b001: begin // CSRRW
                     if (instruction[11:7] != 5'b00000) begin
                           regWEn   = 1'b1;
                           WBSel    = 2'b11; // from csr_rdata
                        end else begin
                           regWEn   = 1'b0;
                     end
                     csr_we   = 1'b1;
                     csr_addr = instruction[31:20];
                     csr_op   = CSRRW;
                     trap_cause = 32'd0;
                     trap_tval  = 32'd0;
                     mret_exec  = 1'b0;
                     trapReq    = 1'b0;
                     flush      = 1'b0;
                  end

                  3'b010: begin // CSRRS
                     if (instruction[19:15] != 5'b00000) begin
                           csr_we   = 1'b1;
                        end else begin
                           csr_we   = 1'b0;
                     end
                     csr_addr = instruction[31:20];
                     csr_op   = CSRRS;
                     trap_cause = 32'd0;
                     trap_tval  = 32'd0;
                     mret_exec  = 1'b0;
                     trapReq    = 1'b0;
                     flush      = 1'b0;
                     regWEn   = 1'b1;
                     WBSel    = 2'b11; // from csr_rdata
                  end

                  3'b011: begin // CSRRC
                     if (instruction[19:15] != 5'b00000) begin
                           csr_we   = 1'b1;
                        end else begin
                           csr_we   = 1'b0;
                     end
                     csr_addr = instruction[31:20];
                     csr_op   = CSRRC;
                     trap_cause = 32'd0;
                     trap_tval  = 32'd0;
                     mret_exec  = 1'b0;
                     trapReq    = 1'b0;
                     flush      = 1'b0;
                     regWEn   = 1'b1;
                     WBSel    = 2'b11; // from csr_rdata
                  end

                  3'b101: begin // CSRRWI
                     if (instruction[11:7] != 5'b00000) begin
                           regWEn   = 1'b1;
                           WBSel    = 2'b11; // from csr_rdata
                        end else begin
                           regWEn   = 1'b0;
                     end
                     csr_we   = 1'b1;
                     csr_addr = instruction[31:20];
                     csr_op   = CSRRWI; // CSRRWI with immediate
                     trap_cause = 32'd0;
                     trap_tval  = 32'd0;
                     mret_exec  = 1'b0;
                     trapReq    = 1'b0;
                     flush      = 1'b0;
                  end

                  3'b110: begin // CSRRSI
                     if (instruction[19:15] != 5'b00000) begin
                           csr_we   = 1'b1;
                        end else begin
                           csr_we   = 1'b0;
                     end
                     csr_addr = instruction[31:20];
                     csr_op   = CSRRSI; // CSRRSI with immediate
                     trap_cause = 32'd0;
                     trap_tval  = 32'd0;
                     mret_exec  = 1'b0;
                     trapReq    = 1'b0;
                     flush      = 1'b0;
                     regWEn   = 1'b1;
                     WBSel    = 2'b11; // from csr_rdata
                  end

                  3'b111: begin // CSRRCI
                     if (instruction[19:15] != 5'b00000) begin
                           csr_we   = 1'b1;
                        end else begin
                           csr_we   = 1'b0;
                     end
                     csr_addr = instruction[31:20];
                     csr_op   = CSRRCI; // CSRRCI with immediate
                     trap_cause = 32'd0;
                     trap_tval  = 32'd0;
                     mret_exec  = 1'b0;
                     trapReq    = 1'b0;
                     flush      = 1'b0;
                     regWEn   = 1'b1;
                     WBSel    = 2'b11; // from csr_rdata
                  end

                  default: begin
                     csr_we = 1'b0;
                     csr_addr = 12'b0;
                     csr_op = CSR_NOP;
                     trap_cause = 32'd0;
                     trap_tval  = 32'd0;
                     mret_exec  = 1'b0;
                     trapReq = 1'b0;
                  end
            endcase
      end

   endcase
end
endmodule