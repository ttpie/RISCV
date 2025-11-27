//---------------------------------------------------------------
//             CSR Unit for RISC-V RV32IM (M-mode only)
//---------------------------------------------------------------
module csr_unit (
    input  wire         clk,
    input  wire         rst_n,

    // === CSR access interface ===
    input  wire         csr_we,          // CSR write enable
    input  wire [11:0]  csr_addr,        // CSR address (bits [31:20])
    input  wire [31:0]  csr_wdata,       // Data from instruction
    input  wire [2:0]   csr_op,          // 001=CSRRW, 010=CSRRS, 011=CSRRC
    output reg  [31:0]  csr_rdata,       // CSR read data back to pipeline

    // === Trap/Exception interface ===
    input  wire         trap_taken,      // Assert when exception/interrupt occurs
    input  wire [31:0]  trap_pc,         // PC where trap occurred
    input  wire [31:0]  trap_cause,      // Cause code
    input  wire [31:0]  trap_tval,       // Additional info (bad addr, etc.)

    // === MRET instruction ===
    input  wire         mret_exec,       // Assert when "MRET" executed

    // === Outputs to control/pipeline ===
    output wire [31:0]  mtvec_base_o,    // Base address of trap vector
    output wire [1:0]   mtvec_mode_o,    // Mode (00=direct, 01=vector)
    output wire [31:0]  mepc_o,          // Machine Exception Program Counter
    output wire [31:0]  mcause_o,        // Trap cause code
    output wire [31:0]  mstatus_o,       // Machine status (for debug)
    output wire [31:0]  mstatush_o,      // Machine status high (for debug)
    output wire [31:0]  mtval_o          // Trap value (for debug)
);

    //-----------------------------------------------------------
    // CSR opcodes
    //-----------------------------------------------------------
    localparam CSRRW  = 3'b001;
    localparam CSRRS  = 3'b010;
    localparam CSRRC  = 3'b011;
    localparam CSRRWI = 3'b100;
    localparam CSRRSI = 3'b101;
    localparam CSRRCI = 3'b110;

    //-----------------------------------------------------------
    // Internal CSR Registers (M-mode only)
    //-----------------------------------------------------------
    reg [31:0] mstatus;
    reg [31:0] mstatush;
    reg [31:0] misa;
    reg [31:0] mie;
    reg [31:0] mtvec;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mtval;
    reg [31:0] mip;

    //-----------------------------------------------------------
    // Reset initialization + synchronous CSR write/update
    //-----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus  <= 32'h0000_0000;
            mstatush <= 32'h0000_0000;
            misa     <= 32'h4000_0110;  // RV32IM
            mie      <= 32'h0000_0000;
            mtvec    <= 32'h0000_0000;
            mepc     <= 32'h0000_0000;
            mcause   <= 32'h0000_0000;
            mtval    <= 32'h0000_0000;
            mip      <= 32'h0000_0000;
        end else begin
            //---------------------------------------------------
            // Trap or Exception Entry
            //---------------------------------------------------
            if (trap_taken) begin
                mepc   <= trap_pc;
                mcause <= trap_cause;
                mtval  <= trap_tval;

                mstatus[7]     <= mstatus[3];  // MPIE ← MIE
                mstatus[3]     <= 1'b0;        // MIE ← 0
                mstatus[12:11] <= 2'b11;       // MPP ← M-mode
            end
            //---------------------------------------------------
            // Return from trap (MRET)
            //---------------------------------------------------
            else if (mret_exec) begin
                mstatus[3]     <= mstatus[7];  // MIE ← MPIE
                mstatus[7]     <= 1'b1;        // MPIE ← 1
                mstatus[12:11] <= 2'b00;       // MPP ← U-mode
            end
            //---------------------------------------------------
            // CSR Write Instructions (CSRRW / CSRRS / CSRRC)
            //---------------------------------------------------
            else if (csr_we) begin
                case (csr_addr)
                    12'h300: begin // mstatus
                        case (csr_op)
                            CSRRW, CSRRWI: mstatus <= csr_wdata;
                            CSRRS, CSRRSI: mstatus <= mstatus | csr_wdata;
                            CSRRC, CSRRCI: mstatus <= mstatus & ~csr_wdata;
                        endcase
                    end
                    12'h310: begin // mstatush
                        case (csr_op)
                            CSRRW, CSRRWI: mstatush <= csr_wdata;
                            CSRRS, CSRRSI: mstatush <= mstatush | csr_wdata;
                            CSRRC, CSRRCI: mstatush <= mstatush & ~csr_wdata;
                        endcase
                    end
                    12'h301: misa <= misa; // Read-only
                    12'h304: begin // mie
                        case (csr_op)
                            CSRRW, CSRRWI: mie <= csr_wdata;
                            CSRRS, CSRRSI: mie <= mie | csr_wdata;
                            CSRRC, CSRRCI: mie <= mie & ~csr_wdata;   
                        endcase
                    end
                    12'h305: begin // mtvec
                        case (csr_op)
                            CSRRW, CSRRWI: mtvec <= csr_wdata;
                            CSRRS, CSRRSI: mtvec <= mtvec | csr_wdata;
                            CSRRC, CSRRCI: mtvec <= mtvec & ~csr_wdata;
                        endcase
                    end
                    12'h341: begin // mepc
                        case (csr_op)
                            CSRRW, CSRRWI: mepc <= csr_wdata;
                            CSRRS, CSRRSI: mepc <= mepc | csr_wdata;
                            CSRRC, CSRRCI: mepc <= mepc & ~csr_wdata;
                        endcase
                    end
                    12'h342: begin // mcause
                        case (csr_op)
                            CSRRW, CSRRWI: mcause <= csr_wdata;
                            CSRRS, CSRRSI: mcause <= mcause | csr_wdata;
                            CSRRC, CSRRCI: mcause <= mcause & ~csr_wdata;
                        endcase
                    end
                    12'h343: begin // mtval
                        case (csr_op)
                            CSRRW, CSRRWI: mtval <= csr_wdata;
                            CSRRS, CSRRSI: mtval <= mtval | csr_wdata;
                            CSRRC, CSRRCI: mtval <= mtval & ~csr_wdata;
                        endcase
                    end
                    12'h344: begin // mip
                        case (csr_op)
                            CSRRW, CSRRWI: mip <= csr_wdata;
                            CSRRS, CSRRSI: mip <= mip | csr_wdata;
                            CSRRC, CSRRCI: mip <= mip & ~csr_wdata;
                        endcase
                    end
                endcase
            end
        end
    end

    //-----------------------------------------------------------
    // === Bypass for mtvec ===
    // Nếu cùng chu kỳ có csr_we và csr_addr==mtvec,
    // bypass csr_wdata ra ngoài để trap dùng ngay.
    //-----------------------------------------------------------
    wire write_mtvec_now   = csr_we && (csr_addr == 12'h305);
    wire [31:0] mtvec_eff  = write_mtvec_now ? csr_wdata : mtvec;

    wire write_mepc_now    = csr_we && (csr_addr == 12'h341);
    wire [31:0] mepc_eff   = trap_taken ? trap_pc : (write_mepc_now ? csr_wdata : mepc);

    wire [31:0] mstatus_after_mret;

    assign mstatus_after_mret = {
                                    mstatus[31:13],
                                    2'b00,        // MPP ← U-mode
                                    mstatus[10:8],
                                    1'b1,         // MPIE ← 1
                                    mstatus[6:4],
                                    mstatus[7],   // MIE ← MPIE
                                    mstatus[2:0]
                                };
    
    wire [31:0] mstatus_read = mret_exec ? mstatus_after_mret : 
                               (csr_we && csr_addr == 12'h300) ? csr_wdata : mstatus;





    //-----------------------------------------------------------
    // CSR Read Logic (có bypass cho mtvec)
    //-----------------------------------------------------------
    always @(*) begin
        case (csr_addr)
            12'h300: csr_rdata = mstatus;
            12'h310: csr_rdata = mstatush;
            12'h301: csr_rdata = misa;
            12'h304: csr_rdata = mie;
            12'h305: csr_rdata = mtvec_eff;   // bypass for mtvec
            12'h341: csr_rdata = mepc_eff;    // bypass for mepc
            12'h342: csr_rdata = mcause;
            12'h343: csr_rdata = mtval;
            12'h344: csr_rdata = mip;
            default: csr_rdata = 32'h0;
        endcase
    end

    //-----------------------------------------------------------
    // Decode mtvec (split into base + mode, with bypass)
    //-----------------------------------------------------------
    wire [31:0] mtvec_base = { mtvec_eff[31:2], 2'b00 };
    wire [1:0]  mtvec_mode = mtvec_eff[1:0];

    //-----------------------------------------------------------
    // Outputs
    //-----------------------------------------------------------
    assign mtvec_base_o = mtvec_base;
    assign mtvec_mode_o = mtvec_mode;
    assign mepc_o       = mepc;
    assign mcause_o     = mcause;
    assign mstatus_o    = mstatus_read;
    assign mtval_o      = mtval;
    assign mstatush_o   = mstatush;

endmodule
