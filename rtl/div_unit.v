
module div_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    input  wire [1:0]  mode,       // 00: DIV, 01: DIVU, 10: REM, 11: REMU
    output reg  [31:0] div_result,
    output reg         done
);
    
    localparam DIV  = 2'b00; // DIV
    localparam DIVU = 2'b01; // DIVU
    localparam REM  = 2'b10; // REM
    localparam REMU = 2'b11; // REMU
    
    reg        busy;
    reg [5:0]  count;
    reg [31:0] divisor_abs;
    reg [63:0] remainder_reg;
    reg [31:0] quotient_reg;
    reg        sign_a, sign_b;

    // ========== KHỐI DATAPATH (wire - combinational) ==========
    wire [63:0] remainder_shifted = remainder_reg << 1;
    wire [31:0] sub_res = remainder_shifted[63:32] - divisor_abs;
    wire        sub_ok  = !sub_res[31];

    wire [63:0] remainder_next = sub_ok ? {sub_res, remainder_shifted[31:0]} : remainder_shifted;

    wire [31:0] quotient_next ={quotient_reg[30:0], sub_ok};

    // ==========================================================
    // KHỐI SEQUENTIAL: FSM + cập nhật thanh ghi
    // ==========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy         <= 0;
            done         <= 0;
            count        <= 0;
            quotient_reg <= 0;
            remainder_reg<= 0;
            div_result   <= 0;
            sign_a       <= 0;
            sign_b       <= 0;
            divisor_abs  <= 0;
        end else begin
            if (start && !busy) begin
                done <= 0;

                    // ======================================================
                    // TRƯỜNG HỢP CHIA CHO 0 (DIVISION BY ZERO)
                    // ======================================================
                if (divisor == 0) begin
                    case (mode)
                        DIV:  div_result <= 32'hFFFFFFFF;    // DIV  signed
                        DIVU: div_result <= 32'hFFFFFFFF;    // DIVU unsigned
                        REM:  div_result <= dividend;        // REM  signed
                        REMU: div_result <= dividend;        // REMU unsigned
                    endcase
                    done <= 1;
                    busy <= 0;

                end else begin
                    // ======================================================
                    // TRƯỜNG HỢP CHIA BÌNH THƯỜNG
                    // ======================================================
                    busy         <= 1;
                    done         <= 0;
                    count        <= 6'd32;
                    quotient_reg <= 0;
                    sign_a       <= dividend[31];
                    sign_b       <= divisor[31];

                    // Nếu mode[0]==0 → signed; nếu ==1 → unsigned
                    divisor_abs  <= (mode[0] == 1'b0) ?
                                     (divisor[31] ? -divisor : divisor) :
                                     divisor;

                    remainder_reg <= {32'b0, ((mode[0] == 1'b0) && dividend[31]) ? -dividend : dividend};
                end
            end else if (busy) begin

                // ======================================================
                // CẬP NHẬT DATAPATH
                // ======================================================
                remainder_reg <= remainder_next;
                quotient_reg  <= quotient_next;
                count <= count - 1;

                // ======================================================
                // KẾT THÚC PHÉP CHIA
                // ======================================================
                if (count == 1) begin
                    busy <= 0;
                    done <= 1;

                    case (mode)
                        DIV:  div_result <= (sign_a ^ sign_b) ? -quotient_next : quotient_next;  
                        DIVU: div_result <= quotient_next;                                       
                        REM:  div_result <= sign_a ? -remainder_next[63:32] : remainder_next[63:32]; 
                        REMU: div_result <= remainder_next[63:32];                              
                    endcase
                end
            end else begin
                done <= 0;
            end
        end
    end

endmodule
