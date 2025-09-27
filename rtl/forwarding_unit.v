module forwarding (
   input wire ExMem_regWEn, MemWb_regWEn,
   input wire [4:0] IdEx_regRs1, IdEx_regRs2, MemWb_regRd, ExMem_regRd,
   output reg [1:0] forwardA, forwardB
   );
 always @(*) begin
 
 // Forwarding logic for Rs1
 if (ExMem_regWEn && (ExMem_regRd != 0) && (ExMem_regRd == IdEx_regRs1)) 
    begin
        forwardA = 2'b10; // từ EXMEM
    end else if (MemWb_regWEn && (MemWb_regRd != 0) && 
                !(ExMem_regWEn && (ExMem_regRd != 0) && (ExMem_regRd == IdEx_regRs1))
                 && (MemWb_regRd == IdEx_regRs1))
            begin
                  forwardA = 2'b01; // từ MEMWB
            end else begin
                  forwardA = 2'b00; //không forward
            end

 // Forwarding logic for Rs2
 if (ExMem_regWEn && (ExMem_regRd != 0) && (ExMem_regRd == IdEx_regRs2)) 
    begin
         forwardB = 2'b10; // từ EXMEM
    end else if (MemWb_regWEn && (MemWb_regRd != 0) && 
                !(ExMem_regWEn && (ExMem_regRd != 0) && (ExMem_regRd == IdEx_regRs2)) 
                && (MemWb_regRd == IdEx_regRs2)) 
             begin
                  forwardB = 2'b01; // từ MEMWB
             end else begin
                  forwardB = 2'b00; //không forward
             end
 end

endmodule