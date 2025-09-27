module register(
   input wire clk,
   input wire reset,
   input wire regWEn,
   input wire [4 : 0] Addr_rs1,
   input wire [4 : 0] Addr_rs2,
   input wire [4 : 0] Addr_rd,
   input wire [31 : 0] data_in,
   output reg [31 : 0] rs1,
   output reg [31 : 0] rs2
);

    reg [31 : 0] registers [31 : 0]; 
    integer i;


    // write data to the registers
    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (regWEn && Addr_rd != 5'b00000) begin
            registers[Addr_rd] <= data_in;
        end
    end

    // READ logic: combinational
    always @(*) begin
        if (^Addr_rs1 === 1'bx) begin
             rs1 = 32'h00000000;
        end else begin
              rs1 = registers[Addr_rs1];
        end

        if (^Addr_rs2 === 1'bx) begin
              rs2 = 32'h00000000;
        end else begin
             rs2 = registers[Addr_rs2];
        end
    end
endmodule