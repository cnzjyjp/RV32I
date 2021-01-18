`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Branch Decision
// Tool Versions: Vivado 2017.4.1
// Description: Decide whether to branch
// 
//////////////////////////////////////////////////////////////////////////////////


//  功能说明
    //  判断是否branch
// 输入
    // reg1               寄存�?1
    // reg2               寄存�?2
    // br_type            branch类型
// 输出
    // br                 是否branch
// 实验要求
    // 补全模块

`include "Parameters.v"   
module BranchDecision(
    input wire [31:0] reg1, reg2,
    input wire [2:0] br_type,
    input wire BTB_EX,BHT_EX,
    input wire clk,
    output reg BTB_Update,BHT_Update,
    output reg br
    );
    reg [31:0] fail_count,success_count;
    initial
    begin
        fail_count = 0;
        success_count = 0;
    end

    // 分支判断
    always @(*)
    begin
        case(br_type)
            `NOBRANCH: br <= 0;
            `BEQ: br <= (reg1 == reg2);
            `BNE: br <= (reg1 != reg2);
            `BLT: br <= ($signed(reg1) < $signed(reg2));
            `BLTU: br <= (reg1 < reg2);
            `BGE: br <= ($signed(reg1) >= $signed(reg2));
            `BGEU: br <= (reg1 >= reg2);
        endcase
    end

    // 判断分支预测是否成功，据此输出BTB更新信号
    always @(*)
    begin
        if (br_type != `NOBRANCH)
        begin
            if ( BTB_EX && !BHT_EX && !br || !BTB_EX && BHT_EX && br || !BTB_EX && !BHT_EX && br) // 表中�?3种预测失败的情况
            begin
                BTB_Update <= 1'b1;
            end
            else // 分支预测成功
            begin
                BTB_Update <= 1'b0;
            end
            BHT_Update <= 1'b1; // 只要是分支指令，就需要更新BHT状�?�机
        end
        else // 不是分支指令
        begin
            BTB_Update <= 1'b0;
            BHT_Update <= 1'b0;
        end
    end

    // 统计分支预测成功与失败指�?
    always @(negedge clk)
    begin
        if (br_type != `NOBRANCH) // 只作用于branch指令
        begin
            if( BTB_EX && BHT_EX && !br || BTB_EX && !BHT_EX && br || !BTB_EX && br) // 预测成功
                fail_count <= fail_count + 1;
            else if ( BTB_EX && BHT_EX && br || BTB_EX && !BHT_EX && !br || !BTB_EX && !br) // 预测失败
                success_count <= success_count + 1;
        end
    end
endmodule
