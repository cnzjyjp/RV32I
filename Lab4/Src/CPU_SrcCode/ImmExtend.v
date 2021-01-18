`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Immediate Extend
// Tool Versions: Vivado 2017.4.1
// Description: Immediate Extension Module
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  立即数拓展，将指令中的立即数部分拓展为完整立即数
// 输入
    // Inst              指令的[31:7]
    // ImmType           立即数类型
// 输出
    // imm               补全的立即数
// 实验要求
    // 补全模块


`include "Parameters.v"   
module ImmExtend(
    input wire [31:7] inst,
    input wire [2:0] imm_type,
    output reg [31:0] imm
    );

    always@(*)
    begin
        case(imm_type)
            `ITYPE: imm <= {{21{inst[31]}}, inst[30:20]};
            `STYPE: imm <= {{21{inst[31]}}, inst[30:25], inst[11:7]};
            `BTYPE: imm <= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            `UTYPE: imm <= {inst[31:12], 12'b0};
            `JTYPE: imm <= {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
            `RTYPE: imm <= {32'b0};
            // testmodule
            // 31       1
            // 30:25    101010
            // 24:20    10101
            // 19:12    00000000
            // 11:7     11111
            // I        111111111111111111111_10101010101
            // S        111111111111111111111_101010_11111
            // B        11111111111111111111_1_101010_1111_0
            // U        11010101010100000000_000000000000
            // J        111111111111_00000000_1_101010_1010_0
            // R        00000000000000000000000000000000
            // Parameters.v defines all immediate type
        endcase
    end
    
endmodule
