module branch_control(
    input wire [31:0] rs1,
    input wire [31:0] rs2,
    input wire BrUn,
    output reg  BrEq,
    output reg  BrLt
);
 
    wire eq = (rs1 == rs2);
    wire lt_signed = ($signed(rs1) < $signed(rs2));
    wire lt_unsigned = (rs1 < rs2);

    // Combinational logic for branch control signals
        always @(*) begin
                BrEq = eq;                                // BEQ
                BrLt = (BrUn) ? lt_unsigned : lt_signed;  // BLT or BLTU
        end

endmodule
