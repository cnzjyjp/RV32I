`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/16 18:07:24
// Design Name: 
// Module Name: Reg2Wb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    // EX\MEM的寄存器段寄存器
// 输入
    // clk               时钟信号
    // reg2_EX           寄存器2内容(可能是转发后的)
    // bubbleM           MEM阶段的bubble信号
    // flushM            MEM阶段的flush信号
// 输出
    // reg2_MEM           传给下一流水段的寄存器2内容
// 实验要求  
    // 无需修改


module Reg2_WB(
    input wire clk, bubbleM, flushM,
    input wire [31:0] reg2_MEM,
    output reg [31:0] reg2_WB
    );

    initial reg2_WB = 0;
    
    always@(posedge clk)
        if (!bubbleM) 
        begin
            if (flushM)
                reg2_WB <= 0;
            else 
                reg2_WB <= reg2_MEM;
        end
    
endmodule
