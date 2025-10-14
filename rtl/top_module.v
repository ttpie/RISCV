`define START_PC_ADDRESS 32'h80000000
`define NOP 32'h00000013 // addi x0, x0, 0

module top_module (
    input clk,
    input reset_n
);

    // === Wires & Registers ===
    wire [31:0] address; // PC output
    wire [31:0] instruction; 
    wire [31:0] pc_jump_jal, pc_branch, pc_jump_jalr; // pc for jal

    wire [4:0]  Addr_rs1, Addr_rs2, Addr_rd;
    wire [2:0]  funct3;
    wire [31:0] imm;

    wire        regWEn, BSel, ASel, flush, trapReq, branch, is_jalr, is_div, start_div;
    reg         PCSel_src, take_branch;
    wire        MemW, memRead;
    wire [1:0]  WBSel, div_mode;
    wire [4:0]  ALUSel;
    wire        BrUn, BrEq, BrLt;

    wire [31:0] rs1_data, rs2_data, rs1_data_src, rs2_data_src;
    wire [31:0] alu_a, alu_b, alu_out, alu_src;
    wire [31:0] read_data;
    wire [31:0] write_data;
    wire [31:0] data_in;  // data to write back to register

    wire [31:0] IFID_pc_out, IFID_instr_out;        // output reg IF ID
    wire        IFID_valid_out;

    wire [31:0] IDEX_pc_out, IDEX_rs1_out, IDEX_rs2_out, IDEX_imm_out, IDEX_instr_out;     // output reg ID EX
    wire        IDEX_BrUn_out, IDEX_regWEn_out, IDEX_MemW_out, IDEX_BSel_out, 
                IDEX_ASel_out, IDEX_trapReq_out, IDEX_memRead_out, IDEX_branch_out, IDEX_is_jalr_out, IDEX_is_div_out;
    wire [2:0]  IDEX_funct3_out;
    wire [1:0]  IDEX_WBSel_out, IDEX_div_mode_out;
    wire [4:0]  IDEX_ALUSel_out;
    wire [4:0]  IDEX_addr_rd_out, IDEX_addr_rs1_out, IDEX_addr_rs2_out;
  
    wire [31:0] EXMEM_ALU_res_out, EXMEM_rs2_out, EXMEM_pc_out, EXMEM_instr_out;  // output reg EX MEM 
    wire [2:0]  EXMEM_funct3_out;
    wire [4:0]  EXMEM_addr_rd_out;
    wire        EXMEM_BrEq_out, EXMEM_BrLT_out, EXMEM_is_div_out;
    wire        EXMEM_MemW_out, EXMEM_PCSel_out, EXMEM_regWEn_out, EXMEM_trapReq_out, EXMEM_memRead_out, EXMEM_is_jalr_out;
    wire [1:0]  EXMEM_WBSel_out;

    wire [31:0] MEMWB_mem_data_out, MEMWB_ALU_res_out, MEMWB_pc_out, MEMWB_instr_out; // output reg MEM WB
    wire [4:0]  MEMWB_addr_rd_out;
    wire [1:0]  MEMWB_WBSel_out;
    wire        MEMWB_regWEn_out, MEMWB_trapReq_out, MEMWB_PCSel_out, MEMWB_is_jalr_out, MEMWB_is_div_out;

    wire [31:0] div_result;
    wire        div_done;

    wire [1:0] forwardA, forwardB, forwardA_ID, forwardB_ID; // Forwarding 
    
    // hazard detection signals
    wire pc_write, IFID_write, control_MuxSel, IDEX_write;
    wire BrUn_mux, regWEn_mux, MemW_mux, PCSel_mux, BSel_mux, ASel_mux, memRead_mux;
    wire [1:0] WBSel_mux;
    wire [4:0] ALUSel_mux;
    
 
    // === Hazard Detection Unit ===
    hazard_detection_unit hazard_detection_unit (
        .IDEX_Rd(IDEX_addr_rd_out),
        .IFID_RS1(Addr_rs1),
        .IFID_RS2(Addr_rs2),
        .IDEX_MemRead(IDEX_memRead_out),
        .is_div(IDEX_is_div_out),
        .div_done(div_done),
        .pc_write(pc_write),
        .IFID_write(IFID_write),
        .IDEX_write(IDEX_write),
        .control_MuxSel(control_MuxSel)
    );
  
    assign BrUn_mux   = control_MuxSel ? 1'b0    : BrUn;
    assign regWEn_mux = control_MuxSel ? 1'b0    : regWEn;
    assign MemW_mux   = control_MuxSel ? 1'b0    : MemW;
    assign BSel_mux   = control_MuxSel ? 1'b0    : BSel;
    assign ASel_mux   = control_MuxSel ? 1'b0    : ASel;
    assign WBSel_mux  = control_MuxSel ? 2'b00   : WBSel;
    assign ALUSel_mux = control_MuxSel ? 5'b00000: ALUSel;
    assign memRead_mux= control_MuxSel ? 1'b0    : memRead;
  
    // === Forwarding Unit ===
    forwarding forwarding_unit (
        .ExMem_regWEn(EXMEM_regWEn_out),
        .MemWb_regWEn(MEMWB_regWEn_out),
        .IdEx_regRs1(IDEX_addr_rs1_out),
        .IdEx_regRs2(IDEX_addr_rs2_out),
        .MemWb_regRd(MEMWB_addr_rd_out),
        .ExMem_regRd(EXMEM_addr_rd_out),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
     
    
    MEM_WB MEM_WB (
       .clk(clk),
       .reset(reset_n),
       .mem_data_in(read_data),
       .ALU_res_in(EXMEM_ALU_res_out),
       .pc_in (EXMEM_pc_out),
       .is_jalr_in(EXMEM_is_jalr_out),
       .is_div_in(EXMEM_is_div_out),
       .instr_in(EXMEM_instr_out),
       .addr_rd_in(EXMEM_addr_rd_out),
       .WBSel_in(EXMEM_WBSel_out),
       .trapReq_in(EXMEM_trapReq_out),
       .regWEn_in(EXMEM_regWEn_out),
       .mem_data_out(MEMWB_mem_data_out),
       .ALU_res_out(MEMWB_ALU_res_out),
       .pc_out (MEMWB_pc_out),
       .instr_out(MEMWB_instr_out),
       .addr_rd_out(MEMWB_addr_rd_out),
       .WBSel_out(MEMWB_WBSel_out),
       .is_jalr_out(MEMWB_is_jalr_out),
       .is_div_out(MEMWB_is_div_out),
       .trapReq_out(MEMWB_trapReq_out),
       .regWEn_out(MEMWB_regWEn_out)
    );
    
    assign data_in = (MEMWB_WBSel_out == 2'b00)? MEMWB_mem_data_out : (MEMWB_WBSel_out == 2'b01)? MEMWB_ALU_res_out : (MEMWB_pc_out + 4);

    wire [31:0] alu_a_src = (forwardA == 2'b10) ? EXMEM_ALU_res_out : (forwardA == 2'b01) ? data_in : IDEX_rs1_out; //muxA
    assign alu_a = IDEX_ASel_out ? IDEX_pc_out : alu_a_src;

    wire [31:0] alu_b_src = (forwardB == 2'b10) ? EXMEM_ALU_res_out : (forwardB == 2'b01) ? data_in : IDEX_rs2_out; //muxB
    assign alu_b = IDEX_BSel_out ? IDEX_imm_out : alu_b_src;

    assign funct3   = IFID_instr_out[14:12];
    assign Addr_rd  = IFID_instr_out[11:7];
    assign Addr_rs1 = IFID_instr_out[19:15];
    assign Addr_rs2 = IFID_instr_out[24:20];

    wire regWEn_src = IDEX_is_div_out ? (div_done && IDEX_regWEn_out) : IDEX_regWEn_out;

    EX_MEM EX_MEM(
        .clk(clk),
        .reset(reset_n),
        .funct3_in(IDEX_funct3_out),
        .ALU_res_in(alu_src),
        .rs2_in(alu_b_src),
        .pc_in(IDEX_pc_out),
        .instr_in(IDEX_instr_out),
        .addr_rd_in(IDEX_addr_rd_out),
        .is_jalr_in(IDEX_is_jalr_out),
        .is_div_in(IDEX_is_div_out),
        .trapReq_in(IDEX_trapReq_out),
        .BrEq_in(BrEq),
        .BrLT_in(BrLt),
        .regWEn_in(regWEn_src),
        .memRead_in(IDEX_memRead_out),
        .MemW_in(IDEX_MemW_out),
        .WBSel_in(IDEX_WBSel_out),
        .ALU_res_out(EXMEM_ALU_res_out),
        .pc_out(EXMEM_pc_out),
        .instr_out(EXMEM_instr_out),
        .rs2_out(EXMEM_rs2_out),
        .funct3_out(EXMEM_funct3_out),
        .addr_rd_out(EXMEM_addr_rd_out),
        .trapReq_out(EXMEM_trapReq_out),
        .BrEq_out(EXMEM_BrEq_out),
        .BrLT_out(EXMEM_BrLT_out),
        .regWEn_out(EXMEM_regWEn_out),
        .MemW_out(EXMEM_MemW_out),
        .memRead_out(EXMEM_memRead_out),
        .is_jalr_out(EXMEM_is_jalr_out),
        .is_div_out(EXMEM_is_div_out),
        .WBSel_out(EXMEM_WBSel_out)
    );
    
    assign rs1_data_src = (MEMWB_regWEn_out && MEMWB_addr_rd_out!=0 && MEMWB_addr_rd_out == Addr_rs1)? data_in : rs1_data;
    assign rs2_data_src = (MEMWB_regWEn_out && MEMWB_addr_rd_out!=0 && MEMWB_addr_rd_out == Addr_rs2)? data_in : rs2_data;

   ID_EX ID_EX(
       .clk(clk),
       .reset(reset_n),
       .flush_branch(take_branch), 
       .IDEX_write(IDEX_write),
       .pc_in(IFID_pc_out),
       .is_jalr_in(is_jalr),
       .is_div_in(is_div),
       .div_mode_in(div_mode),
       .instr_in(IFID_instr_out),
       .rs1_in(rs1_data_src),
       .rs2_in(rs2_data_src),
       .funct3_in(funct3),
       .imm_in(imm),
       .trapReq_in(trapReq),
       .branch_in(branch),
       .BrUn_in(BrUn_mux),
       .regWEn_in(regWEn_mux),
       .BSel_in(BSel_mux),
       .ASel_in(ASel_mux),
       .WBSel_in(WBSel_mux),
       .ALUSel_in(ALUSel_mux),
       .MemW_in(MemW_mux),
       .memRead_in(memRead_mux),
       .addr_rd_in(Addr_rd),
       .addr_rs1_in(Addr_rs1),
       .addr_rs2_in(Addr_rs2),
       .pc_out(IDEX_pc_out),
       .instr_out(IDEX_instr_out),
       .rs1_out(IDEX_rs1_out),
       .rs2_out(IDEX_rs2_out),
       .funct3_out(IDEX_funct3_out),
       .imm_out(IDEX_imm_out),
       .trapReq_out(IDEX_trapReq_out),
       .is_jalr_out(IDEX_is_jalr_out),
       .is_div_out(IDEX_is_div_out),
       .div_mode_out(IDEX_div_mode_out),
       .branch_out(IDEX_branch_out),
       .BrUn_out(IDEX_BrUn_out),
       .regWEn_out(IDEX_regWEn_out),
       .MemW_out(IDEX_MemW_out),
       .memRead_out(IDEX_memRead_out),
       .BSel_out(IDEX_BSel_out),
       .ASel_out(IDEX_ASel_out),
       .WBSel_out(IDEX_WBSel_out),
       .ALUSel_out(IDEX_ALUSel_out),
       .addr_rd_out(IDEX_addr_rd_out),
       .addr_rs1_out(IDEX_addr_rs1_out),
       .addr_rs2_out(IDEX_addr_rs2_out)
   );

    IF_ID IF_ID (
        .clk(clk),
        .reset(reset_n),
        .flush_jal(flush),           
        .flush_branch(take_branch), 
        .IFID_write(IFID_write), 
        .pc_in(address),
        .instr_in(instruction),
        .pc_out(IFID_pc_out),
        .instr_out(IFID_instr_out)
    );

     // === Control Unit ===
    control_unit Control_unit (
        .instruction(IFID_instr_out),
        .BrEq(EXMEM_BrEq_out),
        .BrLt(EXMEM_BrLT_out),
        .is_jalr(is_jalr),
        .is_div(is_div),
        .div_mode(div_mode),
        .BrUn(BrUn),
        .branch(branch),
        .trapReq(trapReq),
        .regWEn(regWEn),
        .MemW(MemW),
        .memRead(memRead),
        .BSel(BSel),
        .ASel(ASel),
        .flush(flush),
        .WBSel(WBSel),
        .ALUSel(ALUSel)
    );

   
    // ============================ PC ================================
    reg [31:0] PC;
    wire [31:0] PC_next;

    assign pc_jump_jal = IFID_pc_out + imm;   //stage ID
    assign pc_jump_jalr = rs1_data_src + imm; // stage ID

     assign PC_next = trapReq ?  PC :
                 is_jalr ?  (pc_jump_jalr & 32'hFFFF_FFFC) :
                 flush       ?  pc_jump_jal :
                 take_branch ?  (alu_out & 32'hFFFF_FFFC) :
                 pc_write    ? (PC + 4) : PC;


    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            PC <= `START_PC_ADDRESS;
        else
            PC <= PC_next;
    end
    assign address = PC; 

    // === Instruction Memory ===
    IMEM IMEM (
        .address(address),
        .instruction(instruction)
    );
    
    // ======== Register File ==========
    register RF (
        .clk(clk),
        .reset(reset_n),
        .regWEn(MEMWB_regWEn_out),
        .data_in(data_in),
        .Addr_rd(MEMWB_addr_rd_out),
        .Addr_rs1(Addr_rs1),
        .Addr_rs2(Addr_rs2),
        .rs1(rs1_data),
        .rs2(rs2_data)
    );

    // === Immediate Generator ===
    immediate_generator imm_gen (
        .instruction(IFID_instr_out),
        .imm_out(imm)
    );

      //------------------------branch decision------------------------

    always @(*) begin
        if (IDEX_branch_out) begin
            case (IDEX_funct3_out)
            3'b000: take_branch = BrEq;
            3'b001: take_branch = ~BrEq;
            3'b100: take_branch = BrLt;
            3'b101: take_branch = ~BrLt;
            3'b110: take_branch = BrLt;
            3'b111: take_branch = ~BrLt;
            default: take_branch = 1'b0;
        endcase
    end else begin
        take_branch = 1'b0;
    end
  end
    
    // === Branch Comparator ===
    branch_control Branch (
        .rs1(alu_a_src),
        .rs2(alu_b_src),
        .BrUn(IDEX_BrUn_out),
        .BrEq(BrEq),
        .BrLt(BrLt)
    );

    // === ALU ===
    ALU_RV32IM ALU (
        .A(alu_a),
        .B(alu_b),
        .ALU_Sel(IDEX_ALUSel_out),
        .ALU_Out(alu_out)
    );
    
    assign alu_src = div_done ? div_result : alu_out;

    reg IDEX_is_div_dly;
    
    always @(posedge clk or negedge reset_n) begin
            if (!reset_n) IDEX_is_div_dly <= 1'b0;
            else IDEX_is_div_dly <= IDEX_is_div_out;
    end
    wire div_start_pulse = IDEX_is_div_out & ~IDEX_is_div_dly;

    // === Division Unit ===
    div_unit DIV (
        .clk(clk),
        .rst_n(reset_n),
        .start(div_start_pulse),
        .dividend(alu_a_src),
        .divisor(alu_b_src),
        .mode(IDEX_div_mode_out),
        .div_result(div_result),
        .done(div_done)
    );
    
       // === Data Memory ===
    data_memory DMEM (
        .clk(clk),
        .address(EXMEM_ALU_res_out),
        .MemW(EXMEM_MemW_out),
        .memRead(EXMEM_memRead_out),
        .write_data(EXMEM_rs2_out),
        .funct3(EXMEM_funct3_out),
        .read_data(read_data)
    );
endmodule
