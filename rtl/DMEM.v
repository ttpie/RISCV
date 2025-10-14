module data_memory(
   input wire clk,
   input wire [31 : 0] address,
   input wire [31 : 0] write_data,
   input wire MemW, memRead, 
   input wire [2 : 0] funct3, // For load/store type
   output reg [31 : 0] read_data
);

    reg [31 : 0] memory [1023:0]; // 1024 words of memory
    wire [9 : 0] word_address = address[11 : 2];// Address in words

    integer i;  
    always @(posedge clk) begin
        if (MemW == 1) begin
            case (funct3)
                3'b000: begin //sb
                    case (address[1 : 0])
                        2'b00: memory[word_address][7 : 0] <= write_data[7 : 0]; // sb lower byte
                        2'b01: memory[word_address][15 : 8] <= write_data[7 : 0]; // sb middle byte
                        2'b10: memory[word_address][23 : 16] <= write_data[7 : 0]; // sb upper byte
                        2'b11: memory[word_address][31 : 24] <= write_data[7 : 0]; // sb highest byte
                    endcase
                end

                3'b001:  begin //sh
                    case (address[1])
                    1'b0: memory[word_address][15 : 0] <= write_data[15 : 0]; // sh lower half
                    1'b1: memory[word_address][31 : 16] <= write_data[15 : 0]; // sh upper half
                endcase
                end

                3'b010: begin //sw
                    memory[word_address] <= write_data; // sw   
                end
        
            endcase
        end
    end
    
    always @(*) begin
        if (memRead == 1) begin
            case (funct3)
                3'b000: begin // lb
                    case (address[1 : 0])
                        2'b00: read_data = {{24{memory[word_address][7]}}, memory[word_address][7 : 0]}; // lb lower byte
                        2'b01: read_data = {{24{memory[word_address][15]}}, memory[word_address][15 : 8]}; // lb middle byte
                        2'b10: read_data = {{24{memory[word_address][23]}}, memory[word_address][23 : 16]}; // lb upper byte
                        2'b11: read_data = {{24{memory[word_address][31]}}, memory[word_address][31 : 24]}; // lb highest byte
                    endcase
                end 

                3'b100: begin //lbu
                    case (address[1 : 0])
                        2'b00: read_data = {{24{1'b0}}, memory[word_address][7 : 0]}; // lbu lower byte
                        2'b01: read_data = {{24{1'b0}}, memory[word_address][15 : 8]}; // lbu middle byte
                        2'b10: read_data = {{24{1'b0}}, memory[word_address][23 : 16]}; // lbu upper byte
                        2'b11: read_data = {{24{1'b0}}, memory[word_address][31 : 24]}; // lbu highest byte
                    endcase
                end

                3'b001:begin // lh
                    case (address[1])
                        1'b0: read_data = {{16{memory[word_address][15]}}, memory[word_address][15 : 0]}; // lh lower half
                        1'b1: read_data = {{16{memory[word_address][31]}}, memory[word_address][31 : 16]}; // lh upper half
                    endcase
                end
                
                3'b101:begin // lhu
                    case (address[1])
                        1'b0: read_data = {{16{1'b0}}, memory[word_address][15 : 0]}; // lhu lower half
                        1'b1: read_data = {{16{1'b0}}, memory[word_address][31 : 16]}; // lhu upper half
                    endcase
                end

                3'b010: read_data = memory[word_address]; // lw

                default: read_data = 32'b0;
            endcase
        end else begin
            read_data = 32'b0; 
        end
    end

endmodule