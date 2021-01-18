`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: RV32I Core
// Tool Versions: Vivado 2017.4.1
// Description: Top level of our CPU Core
//////////////////////////////////////////////////////////////////////////////////


//功能说明
    // RV32I Core的顶层模�?
//实验要求  
    // 添加CSR指令的数据�?�路和相应部�?

module RV32ICore(
    input wire CPU_CLK,
    input wire CPU_RST,
    output wire [31:0] inst_ID
    );
	//wire values definitions
    wire bubbleF, flushF, bubbleD, flushD, bubbleE, flushE, bubbleM, flushM, bubbleW, flushW;
    wire [31:0] jal_target, br_target;
    wire jal, br;
    wire jalr_ID, jalr_EX;
    wire [31:0] NPC, PC_IF, PC_4, PC_ID, PC_EX, PC_EX_0;
    wire reg_write_en_ID, reg_write_en_EX, reg_write_en_MEM, reg_write_en_WB;
    wire csr_write_en_ID, csr_write_en_EX, csr_write_en_MEM, csr_write_en_WB;
    wire [4:0] reg1_src_EX;
    wire [4:0] reg2_src_EX;
    wire [11:0] csr_src_EX;
    wire [4:0] reg_dest_EX, reg_dest_MEM, reg_dest_WB;
    wire [11:0] csr_dest_EX, csr_dest_MEM, csr_dest_WB;
    wire [31:0] data_WB;
    wire [31:0] data_WB_isCSR;
    wire [31:0] reg1_before, reg1, reg1_EX;
    wire [31:0] reg2_before, reg2, reg2_EX, reg2_MEM, reg2_WB;// reg2/src
    wire [31:0] csr_out;
    wire [31:0] op2;
    wire [31:0] reg_or_imm;
    wire op2_src;
    wire [3:0] ALU_func_ID, ALU_func_EX;
    wire [2:0] br_type_ID, br_type_EX;
    wire load_npc_ID, load_npc_EX;
    wire wb_select_ID, wb_select_EX, wb_select_MEM;
    wire [2:0] load_type_ID, load_type_EX, load_type_MEM;
    wire [1:0] src_reg_en_ID, src_reg_en_EX;
    wire [3:0] cache_write_en_ID, cache_write_en_EX, cache_write_en_MEM;
    wire alu_src1_ID, alu_src1_EX;
    wire [1:0] alu_src2_ID, alu_src2_EX;
    wire [2:0] imm_type;
    wire [31:0] imm;
    wire [31:0] ALU_op1, ALU_op2, ALU_out;
    wire [31:0] dealt_reg2;
    wire [31:0] result, result_MEM;
    wire [1:0] op1_sel, op2_sel, reg2_sel;
    wire [31:0] zimm;
    // cache 缺失
    wire miss;
    // 分支预测
    wire BTB, BTB_ID, BTB_EX, BTB_Update;
    wire BHT, BHT_ID, BHT_EX, BHT_Update;
    wire [31:0] PC_predict; // 预测的地�?


    // Adder to compute PC + 4
    assign PC_4 = PC_IF + 4;
    assign PC_EX_0 = PC_EX - 4; // PC_EX_0 才是真的PC�?
    // MUX for op2 source
    assign op2 = op2_src ? imm : reg2;
    // Adder to compute PC_ID + Imm - 4
    assign jal_target = PC_ID + op2 - 4;
    // MUX for ALU op1
    assign ALU_op1 = (op1_sel == 2'h0) ? result_MEM :
                                         ((op1_sel == 2'h1) ? data_WB :
                                                              (op1_sel == 2'h2) ? (PC_EX - 4) :
                                                                                  reg1_EX);
    // MUX for ALU op2
    assign ALU_op2 = (op2_sel == 2'h0) ? result_MEM :
                                         ((op2_sel == 2'h1) ? data_WB :
                                                              ((op2_sel == 2'h2) ? reg2_src_EX :
                                                                                   reg_or_imm));

    // MUX for Reg2
    assign dealt_reg2 = (reg2_sel == 2'h0) ? result_MEM :
                                            ((reg2_sel == 2'h1) ? data_WB : reg2_EX);


    // MUX for result (ALU or PC_EX)
    assign result = load_npc_EX ? PC_EX : ALU_out;

    // wbdata select
    assign data_WB_isCSR = csr_write_en_WB ? reg2_WB : data_WB;

    // zimm
    assign zimm = {27'b0, inst_ID[19:15]};

    // MUX for reg1 and reg2
    assign reg2 = csr_write_en_ID ? csr_out : reg2_before;
    assign reg1 = (csr_write_en_ID && (inst_ID[14:12] == 3'b101 || inst_ID[14:12] == 3'b110 || inst_ID[14:12] == 3'b111)) ? zimm : reg1_before;



    //Module connections
    // ---------------------------------------------
    // PC-Generator
    // ---------------------------------------------

    // 分支预测
    BTB BTB1(
        .clk(CPU_CLK),
        .PC_IF(PC_IF[31:2]),
        .REAL(br), // EX阶段是否跳转
        .BTB_Update(BTB_Update),
        .Update_entry(PC_EX_0[31:2]),
        .Update_pc(br_target),
        .rst(CPU_RST),
        .PC_predict(PC_predict),
        .BTB(BTB) // 预测是否成功
    );

    BHT BHT1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .REAL(br),
        .PC_IF(PC_IF[31:2]),
        .PC_EX(PC_EX_0[31:2]), // 用于判断是否为第�?次预�?
        .BHT_Update(BHT_Update),
        .BHT(BHT)
    );


    NPC_Generator NPC_Generator1(
        .PC(PC_4),
        .jal_target(jal_target),
        .jalr_target(ALU_out),
        .br_target(br_target),
        .jal(jal),
        .jalr(jalr_EX),
        .br(br),
        .PC_predict(PC_predict),
        .BTB(BTB), 
        .BTB_EX(BTB_EX), 
        .BHT(BHT),
        .BHT_EX(BHT_Update),
        .PC_EX(PC_EX),
        .NPC(NPC)
    );


    PC_IF PC_IF1(
        .clk(CPU_CLK),
        .bubbleF(bubbleF),
        .flushF(flushF),
        .NPC(NPC),
        .PC(PC_IF)
    );



    // ---------------------------------------------
    // IF stage
    // ---------------------------------------------

    PC_ID PC_ID1(
        .clk(CPU_CLK),
        .bubbleD(bubbleD),
        .flushD(flushD),
        .PC_IF(PC_4),
        .BTB_IF(BTB),
        .BTB_ID(BTB_ID),
        .BHT_IF(BHT),
        .BHT_ID(BHT_ID),
        .PC_ID(PC_ID)
    );


    IR_ID IR_ID1(
        .clk(CPU_CLK),
        .bubbleD(bubbleD),
        .flushD(flushD),
        .addr(PC_IF[31:2]),
        .inst_ID(inst_ID)
    );



    // ---------------------------------------------
    // ID stage
    // ---------------------------------------------


    RegisterFile RegisterFile1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .write_en(reg_write_en_WB | csr_write_en_WB),
        .addr1(inst_ID[19:15]),
        .addr2(inst_ID[24:20]),
        .wb_addr(reg_dest_WB),
        .wb_data(data_WB_isCSR),
        .reg1(reg1_before),
        .reg2(reg2_before)
    );

    CSRRegisterFile CSRRegisterFile1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .write_en(csr_write_en_WB),
        .addr(inst_ID[31:20]),
        .wb_addr(csr_dest_WB),
        .wb_data(data_WB),
        .csr_out(csr_out)
    );

    ControllerDecoder ControllerDecoder1(
        .inst(inst_ID),
        .jal(jal),
        .jalr(jalr_ID),
        .op2_src(op2_src),
        .ALU_func(ALU_func_ID),
        .br_type(br_type_ID),
        .load_npc(load_npc_ID),
        .wb_select(wb_select_ID),
        .load_type(load_type_ID),
        .src_reg_en(src_reg_en_ID),
        .reg_write_en(reg_write_en_ID),
        .csr_write_en(csr_write_en_ID),
        .cache_write_en(cache_write_en_ID),
        .alu_src1(alu_src1_ID),
        .alu_src2(alu_src2_ID),
        .imm_type(imm_type)
    );

    ImmExtend ImmExtend1(
        .inst(inst_ID[31:7]),
        .imm_type(imm_type),
        .imm(imm)
    );


    PC_EX PC_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .PC_ID(PC_ID),
        .BTB_ID(BTB_ID),
        .BTB_EX(BTB_EX),
        .BHT_ID(BHT_ID),
        .BHT_EX(BHT_EX),
        .PC_EX(PC_EX)
    );

    BR_Target_EX BR_Target_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .address(jal_target),
        .address_EX(br_target)
    );

    Op1_EX Op1_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .reg1(reg1),
        .reg1_EX(reg1_EX)
    );

    Op2_EX Op2_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .op2(op2),
        .reg_or_imm(reg_or_imm)
    );

    Reg2_EX Reg2_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .reg2(reg2),
        .reg2_EX(reg2_EX)
    );

    Addr_EX Addr_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .reg1_src_ID(inst_ID[19:15]),
        .reg2_src_ID(inst_ID[24:20]),
        .reg_dest_ID(inst_ID[11:7]),
        .csr_dest_ID(inst_ID[31:20]),
        .reg1_src_EX(reg1_src_EX),
        .reg2_src_EX(reg2_src_EX),
        .reg_dest_EX(reg_dest_EX),
        .csr_dest_EX(csr_dest_EX)
    );



    Ctrl_EX Ctrl_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .jalr_ID(jalr_ID),
        .ALU_func_ID(ALU_func_ID),
        .br_type_ID(br_type_ID),
        .load_npc_ID(load_npc_ID),
        .wb_select_ID(wb_select_ID),
        .load_type_ID(load_type_ID),
        .src_reg_en_ID(src_reg_en_ID),
        .reg_write_en_ID(reg_write_en_ID),
        .csr_write_en_ID(csr_write_en_ID),
        .cache_write_en_ID(cache_write_en_ID),
        .alu_src1_ID(alu_src1_ID),
        .alu_src2_ID(alu_src2_ID),
        .jalr_EX(jalr_EX),
        .ALU_func_EX(ALU_func_EX),
        .br_type_EX(br_type_EX),
        .load_npc_EX(load_npc_EX),
        .wb_select_EX(wb_select_EX),
        .load_type_EX(load_type_EX),
        .src_reg_en_EX(src_reg_en_EX),
        .reg_write_en_EX(reg_write_en_EX),
        .csr_write_en_EX(csr_write_en_EX),
        .cache_write_en_EX(cache_write_en_EX),
        .alu_src1_EX(alu_src1_EX),
        .alu_src2_EX(alu_src2_EX)
    );


    // ---------------------------------------------
    // EX stage
    // ---------------------------------------------

    ALU ALU1(
        .op1(ALU_op1),
        .op2(ALU_op2),
        .ALU_func(ALU_func_EX),
        .ALU_out(ALU_out)
    );

    BranchDecision BranchDecision1(
        .clk(CPU_CLK),
        .reg1(ALU_op1),
        .reg2(dealt_reg2),
        .br_type(br_type_EX),
        .BTB_EX(BTB_EX),
        .BTB_Update(BTB_Update),
        .BHT_EX(BHT_EX),
        .BHT_Update(BHT_Update),
        .br(br)
    );


    Result_MEM Result_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .result(result),
        .result_MEM(result_MEM)
    );

    Reg2_MEM Reg2_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .reg2_EX(dealt_reg2),
        .reg2_MEM(reg2_MEM)
    );

    Addr_MEM Addr_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .reg_dest_EX(reg_dest_EX),
        .csr_dest_EX(csr_dest_EX),
        .reg_dest_MEM(reg_dest_MEM),
        .csr_dest_MEM(csr_dest_MEM)
    );



    Ctrl_MEM Ctrl_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .wb_select_EX(wb_select_EX),
        .load_type_EX(load_type_EX),
        .reg_write_en_EX(reg_write_en_EX),
        .csr_write_en_EX(csr_write_en_EX),
        .cache_write_en_EX(cache_write_en_EX),
        .wb_select_MEM(wb_select_MEM),
        .load_type_MEM(load_type_MEM),
        .reg_write_en_MEM(reg_write_en_MEM),
        .csr_write_en_MEM(csr_write_en_MEM),
        .cache_write_en_MEM(cache_write_en_MEM)
    );



    // ---------------------------------------------
    // MEM stage
    // ---------------------------------------------


    WB_Data_WB WB_Data_WB1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .bubbleW(bubbleW),
        .flushW(flushW),
        .wb_select(wb_select_MEM),
        .load_type(load_type_MEM),
        .write_en(cache_write_en_MEM),
        .addr(result_MEM),
        .in_data(reg2_MEM),
        .data_WB(data_WB),
        .miss(miss)
    );

    Reg2_WB Reg2_WB1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .reg2_MEM(reg2_MEM),
        .reg2_WB(reg2_WB)
    );

    Addr_WB Addr_WB1(
        .clk(CPU_CLK),
        .bubbleW(bubbleW),
        .flushW(flushW),
        .reg_dest_MEM(reg_dest_MEM),
        .csr_dest_MEM(csr_dest_MEM),
        .reg_dest_WB(reg_dest_WB),
        .csr_dest_WB(csr_dest_WB)
    );

    Ctrl_WB Ctrl_WB1(
        .clk(CPU_CLK),
        .bubbleW(bubbleW),
        .flushW(flushW),
        .reg_write_en_MEM(reg_write_en_MEM),
        .csr_write_en_MEM(csr_write_en_MEM),
        .reg_write_en_WB(reg_write_en_WB),
        .csr_write_en_WB(csr_write_en_WB)
    );


    // ---------------------------------------------
    // WB stage
    // ---------------------------------------------



    // ---------------------------------------------
    // Harzard Unit
    // ---------------------------------------------
    HarzardUnit HarzardUnit1(
        .rst(CPU_RST),
        .BTB_EX(BTB_EX),
        .BHT_EX(BHT_EX),
        .reg1_srcD(inst_ID[19:15]),
        .reg2_srcD(inst_ID[24:20]),
        .reg1_srcE(reg1_src_EX),
        .reg2_srcE(reg2_src_EX),
        .csr_srcE(csr_dest_EX),
        .reg_dstE(reg_dest_EX),
        .reg_dstM(reg_dest_MEM),
        .csr_dstM(csr_dest_MEM),
        .reg_dstW(reg_dest_WB),
        .csr_dstW(csr_dest_WB),
        .br(br),
        .jalr(jalr_EX),
        .jal(jal),
        .src_reg_en(src_reg_en_EX),
        .wb_select(wb_select_EX),
        .reg_write_en_MEM(reg_write_en_MEM),
        .reg_write_en_WB(reg_write_en_WB),
        .csr_write_en_MEM(csr_write_en_MEM),
        .csr_write_en_WB(csr_write_en_WB),
        .csr_write_en_EX(csr_write_en_EX),
        .alu_src1(alu_src1_EX),
        .alu_src2(alu_src2_EX),
        .miss(miss),
        .flushF(flushF),
        .bubbleF(bubbleF),
        .flushD(flushD),
        .bubbleD(bubbleD),
        .flushE(flushE),
        .bubbleE(bubbleE),
        .flushM(flushM),
        .bubbleM(bubbleM),
        .flushW(flushW),
        .bubbleW(bubbleW),
        .op1_sel(op1_sel),
        .op2_sel(op2_sel),
        .reg2_sel(reg2_sel)
    );  
    	         
endmodule
