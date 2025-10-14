`timescale 1ns/1ps
module tb_div_unit;

    // --- tín hiệu ---
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] dividend;
    reg [31:0] divisor;
    reg [1:0] mode;
    wire [31:0] div_result;
    wire done;

    // --- kết nối DUT ---
    div_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .mode(mode),
        .div_result(div_result),
        .done(done)
    );
    
    // Clock
    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    // --- Test vector ---
    reg [1:0] mode_vec   [0:15];
    reg [31:0] dividend_vec [0:15];
    reg [31:0] divisor_vec  [0:15];
    reg [31:0] expected_vec [0:15];

    integer i;

    initial begin
        // --- Dump file cho GTKWave ---
        $dumpfile("div_unit.vcd");  
        $dumpvars(0, tb_div_unit);
        $display("\n =============================== START TEST ================================");

        rst_n = 0;
        start = 1'b0;
        #20 
        rst_n = 1;

        // ====== CÁC TESTCASE CỤ THỂ ======
        // mode: 00=DIV, 01=DIVU, 10=REM, 11=REMU

        // --- DIV (signed) ---
        mode_vec[0]  = 2'b00; dividend_vec[0] = 32'd7;        divisor_vec[0] = 32'd2;          expected_vec[0] = 32'd3;
        mode_vec[1]  = 2'b00; dividend_vec[1] = -32'd100;       divisor_vec[1] = 32'd7;          expected_vec[1] = -32'd14;
        mode_vec[2]  = 2'b00; dividend_vec[2] = 32'd1234;       divisor_vec[2] = -32'd11;        expected_vec[2] = -32'd112;
        mode_vec[3]  = 2'b00; dividend_vec[3] = 32'h80000000;   divisor_vec[3] = -32'd1;         expected_vec[3] = 32'h80000000;
        mode_vec[4]  = 2'b00; dividend_vec[4] = 32'd55;         divisor_vec[4] = 32'd0;          expected_vec[4] = 32'h7fffffff;

        // --- DIVU (unsigned) ---
        mode_vec[5]  = 2'b01; dividend_vec[5] = 32'hffffffff;   divisor_vec[5] = 32'd2;          expected_vec[5] = 32'h7fffffff;
        mode_vec[6]  = 2'b01; dividend_vec[6] = 32'd100;        divisor_vec[6] = 32'd0;          expected_vec[6] = 32'hffffffff;
        mode_vec[7]  = 2'b01; dividend_vec[7] = 32'd300;        divisor_vec[7] = 32'd10;         expected_vec[7] = 32'd30;

        // --- REM (signed) ---
        mode_vec[8]  = 2'b10; dividend_vec[8] = 32'd100;        divisor_vec[8] = 32'd7;          expected_vec[8] = 32'd2;
        mode_vec[9]  = 2'b10; dividend_vec[9] = -32'd100;       divisor_vec[9] = 32'd7;          expected_vec[9] = -32'd2;
        mode_vec[10] = 2'b10; dividend_vec[10]= 32'h80000000;   divisor_vec[10]= -32'd1;         expected_vec[10]= 32'd0;
        mode_vec[11] = 2'b10; dividend_vec[11]= 32'd50;         divisor_vec[11]= 32'd0;          expected_vec[11]= 32'd50;

        // --- REMU (unsigned) ---
        mode_vec[12] = 2'b11; dividend_vec[12]= 32'd100;        divisor_vec[12]= 32'd9;          expected_vec[12]= 32'd1;
        mode_vec[13] = 2'b11; dividend_vec[13]= 32'hffffffff;   divisor_vec[13]= 32'd5;          expected_vec[13]= 32'd0;
        mode_vec[14] = 2'b11; dividend_vec[14]= 32'd0;          divisor_vec[14]= 32'd9;          expected_vec[14]= 32'd0;
        mode_vec[15] = 2'b11; dividend_vec[15]= 32'habcdef00;   divisor_vec[15]= 32'h00001000;   expected_vec[15]= 32'h00000f00;
        
        for (i = 0; i < 16; i = i + 1) begin
            run_case(i);
        end

        $display("================================= TEST DONE ==================================\n");
        #50 $finish;
    end

    // --- Task thực hiện 1 test ---
    task run_case;
        input integer idx;
        integer timeout;
        begin
            // --- thiết lập input ---
            mode = mode_vec[idx];
            dividend = dividend_vec[idx];
            divisor = divisor_vec[idx];

            start = 1;
            #10;              
            start = 0;
            #10;

            timeout = 0;
            while (done == 0 && timeout < 3000) begin
                #10;           // mỗi lần tương ứng 1 chu kỳ clock
                timeout = timeout + 1;
            end

            // --- kiểm tra kết quả ---
            if (timeout == 2000) begin
                $display("⏱️ Test %0d TIMEOUT | mode=%b | a=%h b=%h | got=%h expected=%h",
                        idx, mode, dividend, divisor, div_result, expected_vec[idx]);
            end else if (div_result !== expected_vec[idx]) begin
                $display("❌ Test %0d FAIL | mode=%b | a=%h b=%h | got=%h expected=%h",
                        idx, mode, dividend, divisor, div_result, expected_vec[idx]);
            end else begin
                $display("✅ Test %0d PASS | mode=%b | a=%h b=%h | result=%h",
                        idx, mode, dividend, divisor, div_result);
            end

            #10;
        end
    endtask



endmodule
