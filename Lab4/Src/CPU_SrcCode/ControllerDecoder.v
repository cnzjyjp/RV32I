`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Controller Decoder
// Tool Versions: Vivado 2017.4.1
// Description: Controller Decoder Module
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  对指令进行译码，将其翻译成控制信号，传输给各个部件
// 输入
    // Inst              待译码指令
// 输出
    // jal               jal跳转指令
    // jalr              jalr跳转指令
    // op2_src           ALU的第二个操作数来源。为1时，op2选择imm，为0时，op2选择reg2
    // ALU_func          ALU执行的运算类型
    // br_type           branch的判断条件，可以是不进行branch
    // load_npc          写回寄存器的值的来源（PC或者ALU计算结果）, load_npc == 1时选择PC
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果），wb_select == 1时选择cache内容
    // load_type         load类型
    // src_reg_en        指令中src reg的地址是否有效，src_reg_en[1] == 1表示reg1被使用到了，src_reg_en[0]==1表示reg2被使用到了
    // reg_write_en      通用寄存器写使能，reg_write_en == 1表示需要写回reg
    // cache_write_en    按字节写入data cache
    // imm_type          指令中立即数类型
    // alu_src1          alu操作数1来源，alu_src1 == 0表示来自reg1，alu_src1 == 1表示来自PC
    // alu_src2          alu操作数2来源，alu_src2 == 2’b00表示来自reg2，alu_src2 == 2'b01表示来自reg2地址，alu_src2 == 2'b10表示来自立即数
// 实验要求
    // 补全模块


`include "Parameters.v"   
module ControllerDecoder(
    input wire [31:0] inst,
    output wire jal,
    output wire jalr,
    output wire op2_src,
    output reg [3:0] ALU_func,
    output reg [2:0] br_type,
    output wire load_npc,
    output wire wb_select,
    output reg [2:0] load_type,
    output reg [1:0] src_reg_en,
    output reg reg_write_en,
    output reg csr_write_en,
    output reg [3:0] cache_write_en,
    output wire alu_src1,
    output wire [1:0] alu_src2,
    output reg [2:0] imm_type
    );

    wire [6:0] opcode = inst[6:0];
    wire [6:0] funct7 = inst[31:25];
    wire [2:0] funct3 = inst[14:12];
    assign jal = (opcode == 7'b1101111);
    assign jalr = (opcode == 7'b1100111);
    assign op2_src = (opcode != 7'b0110011 && opcode != 7'b1110011);// only algorithm instruction use reg2, 为 1 时选择 imm
    assign load_npc = (opcode == 7'b1101111 || opcode == 7'b1100111);// jal or jalr
    assign wb_select = (opcode == 7'b0000011);// load instructions
    assign alu_src1 = (opcode == 7'b0010111);// auipc
    assign alu_src2 = (opcode == 7'b0110011 || opcode == 7'b1110011) ? 2'b00 : (
        ((opcode == 7'b0010011) && (funct3 == 3'b001 || funct3 == 3'b101)) ? 2'b01 : 2'b10
    );// reg/csr, shamt, imm
    always @(*)
    begin
        br_type = `NOBRANCH;
        load_type = `NOREGWRITE;
        cache_write_en = 4'b0;
        case(opcode)// src_reg_en[1], reg1=rs1
            7'b1100111,
            7'b1100011,
            7'b0000011,
            7'b0100011,
            7'b0010011,
            7'b0110011: src_reg_en[1] = 1'b1;
            default: src_reg_en[1] = 1'b0;
        endcase
        if(opcode == 7'b1110011 && (funct3 == 3'b001 || funct3 == 3'b010 || funct3 == 3'b011))// csrrw, csrrs, csrrc
            src_reg_en[1] = 1;
        case(opcode)// src_reg_en[0], reg2=rs2
            7'b1100011,
            7'b0100011,
            7'b0110011: src_reg_en[0] = 1'b1;
            default: src_reg_en[0] = 1'b0;
        endcase
        case(opcode)// reg_write_en, rd
            7'b0110111,
            7'b0010111,
            7'b1101111,
            7'b1100111,
            7'b0000011,
            7'b0010011,
            7'b0110011: reg_write_en = 1'b1;
            default: reg_write_en = 1'b0;
        endcase
        if(opcode == 7'b1110011)// csr
            csr_write_en = 1'b1;
        else
            csr_write_en = 1'b0;
        if(opcode == 7'b1100011)// branch instructions
            case(funct3)
                3'b000: br_type = `BEQ;
                3'b001: br_type = `BNE;
                3'b100: br_type = `BLT;
                3'b110: br_type = `BLTU;
                3'b101: br_type = `BGE;
                3'b111: br_type = `BGEU;
            endcase
        if(opcode == 7'b0000011)// load instructions
            case(funct3)
                3'b000: load_type = `LB;
                3'b001: load_type = `LH;
                3'b010: load_type = `LW;
                3'b100: load_type = `LBU;
                3'b101: load_type = `LHU;
            endcase
        if(opcode == 7'b0100011)// store instructions
            case(funct3)
                3'b000: cache_write_en = 4'b0001;// SB
                3'b001: cache_write_en = 4'b0011;// SH
                3'b010: cache_write_en = 4'b1111;// SW
            endcase
        case(opcode)// instruction type
            7'b0110011: imm_type = `RTYPE;
            7'b1100111,
            7'b0000011,
            7'b0010011: imm_type = `ITYPE;
            7'b0100011: imm_type = `STYPE;
            7'b1100011: imm_type = `BTYPE;
            7'b0110111,
            7'b0010111: imm_type = `UTYPE;
            7'b1101111: imm_type = `JTYPE;
            default: imm_type = `RTYPE;
        endcase
        if(opcode == 7'b0110111)// lui
            ALU_func = `LUI;
        else if(opcode == 7'b0010011 || opcode == 7'b0110011)// algorithm instructions
            case(funct3)
                3'b001: ALU_func = `SLL;
                3'b101: ALU_func = (funct7 == 7'b0000000) ? `SRL : `SRA;
                3'b000: ALU_func = (opcode == 7'b0010011) ? `ADD : ((funct7 == 7'b0000000) ? `ADD : `SUB);
                3'b100: ALU_func = `XOR;
                3'b110: ALU_func = `OR;
                3'b111: ALU_func = `AND;
                3'b010: ALU_func = `SLT;
                3'b011: ALU_func = `SLTU;
            endcase
        else if(opcode == 7'b1110011)// csr instructions
            case(funct3)
                3'b001,
                3'b101: ALU_func = `CSRRW;
                3'b010,
                3'b110: ALU_func = `CSRRS;
                3'b011,
                3'b111: ALU_func = `CSRRC;
            endcase
        else
            ALU_func = `ADD;
    end
endmodule
