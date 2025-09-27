`timescale 1ns / 1ps

module tb_top_module;

    reg clk;
    reg reset_n;
    integer instr_count;
    integer fd;
    reg [8*128-1:0] line;  // Buffer for reading lines
    integer addr, expected, actual;
    integer code;  
    integer err_count; 

    // Instantiate DUT
    top_module dut (
        .clk(clk),
        .reset_n(reset_n)
    );

    // Clock: 100MHz
    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, tb_top_module);

        $readmemh("data/hex/input_imem.hex", dut.IMEM.memory, 0, 1023);
        $readmemh("data/hex/init_dmem.hex", dut.DMEM.memory, 0, 1023);


        $display("\n ============================== Start Simulation ==================================");
        
        instr_count = 1;

        reset_n = 0;
        err_count = 0;
        #20;
        reset_n = 1;

        #1400;

        // Open and verify Data Memory
        $display("\n--- Verifying Data Memory ---");
        fd = $fopen("data/golden/golden_output.txt", "r");
        if (fd == 0) begin
            $display(" ERROR: Cannot open golden_output.txt");
            $finish;
        end

        while (!$feof(fd)) begin
            line = "";
            code = $fgets(line, fd);

            if (code > 0) begin
                if ($sscanf(line, "Dmem[%d] = %d", addr, expected) == 2) begin
                    actual = dut.DMEM.memory[addr >> 2];

                    if (actual !== expected) begin
                        $display(" Mismatch at Dmem[%0d]: expected %0d, got %0d", addr, expected, actual);
                        err_count++;
                    end else begin
                        $display(" Dmem[%0d] = %0d OK", addr, actual);
                    end
                end
            end
        end
        
        $fclose(fd);

        if (err_count == 0)
            $display("All memory contents match golden output! All tests passed. \n");
        else
            $display("❗ Found %0d mismatches in Data Memory.\n", err_count);

        $display("============================== End Simulation ====================================");
        $finish;
    end

endmodule
