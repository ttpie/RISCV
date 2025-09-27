module hazard_detection_unit (
  input wire [4:0] IDEX_Rd, IFID_RS1, IFID_RS2,
  input wire IDEX_MemRead,
  output reg pc_write,
  output reg IFID_write,
  output reg IDEX_write,
  output reg control_MuxSel
  );

always @(*) begin
    if (IDEX_MemRead  && ((IDEX_Rd == IFID_RS1) || (IDEX_Rd == IFID_RS2)))
    begin
        //hazard detected -> stall pipeline
        pc_write = 1'b0;
        IFID_write = 1'b0;
        IDEX_write = 1'b0;
        control_MuxSel = 1'b1; // select NOP 
    end else begin
        // No hazard
        pc_write = 1'b1;
        IFID_write = 1'b1;
        IDEX_write = 1'b1;
        control_MuxSel = 1'b0;
    end
end
endmodule
