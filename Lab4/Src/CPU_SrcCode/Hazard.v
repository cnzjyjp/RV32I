`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Hazard Module
// Tool Versions: Vivado 2017.4.1
// Description: Hazard Module is used to control flush, bubble and bypass
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  识别流水线中的数据冲突，控制数据转发，和flush、bubble信号
// 输入
    // rst               CPU的rst信号
    // reg1_srcD         ID阶段的源reg1地址
    // reg2_srcD         ID阶段的源reg2地址
    // reg1_srcE         EX阶段的源reg1地址
    // reg2_srcE         EX阶段的源reg2地址
    // reg_dstE          EX阶段的目的reg地址
    // reg_dstM          MEM阶段的目的reg地址
    // reg_dstW          WB阶段的目的reg地址
    // br                是否branch
    // jalr              是否jalr
    // jal               是否jal
    // src_reg_en        指令中的源reg1和源reg2地址是否有效
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果）
    // reg_write_en_MEM  MEM阶段的寄存器写使能信号
    // reg_write_en_WB   WB阶段的寄存器写使能信号
    // alu_src1          ALU操作数1来源：0表示来自reg1，1表示来自PC
    // alu_src2          ALU操作数2来源：2’b00表示来自reg2，2'b01表示来自reg2地址，2'b10表示来自立即数
    // miss              cache 缺失
// 输出
    // flushF            IF阶段的flush信号
    // bubbleF           IF阶段的bubble信号
    // flushD            ID阶段的flush信号
    // bubbleD           ID阶段的bubble信号
    // flushE            EX阶段的flush信号
    // bubbleE           EX阶段的bubble信号
    // flushM            MEM阶段的flush信号
    // bubbleM           MEM阶段的bubble信号
    // flushW            WB阶段的flush信号
    // bubbleW           WB阶段的bubble信号
    // op1_sel           ALU的操作数1来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自PC，2'b11表示来自reg1
    // op2_sel           ALU的操作数2来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自reg2地址，2'b11表示来自reg2或立即数
    // reg2_sel          reg2的来源
// 实验要求
    // 补全模块


module HarzardUnit(
    input wire rst,
    input wire [4:0] reg1_srcD, reg2_srcD, reg1_srcE, reg2_srcE, reg_dstE, reg_dstM, reg_dstW,
    input wire [11:0] csr_srcE, csr_dstM, csr_dstW,
    input wire br, jalr, jal,
    input wire [1:0] src_reg_en,
    input wire wb_select,
    input wire reg_write_en_MEM,
    input wire reg_write_en_WB,
    input wire csr_write_en_MEM,
    input wire csr_write_en_WB,
    input wire csr_write_en_EX,// wirte 信号同时也是 src 信号
    input wire alu_src1,
    input wire [1:0] alu_src2,
    input wire miss,
    input wire BTB_EX,BHT_EX, // 分支预测跳转，但没有跳转，此时需要flush
    output reg flushF, bubbleF, flushD, bubbleD, flushE, bubbleE, flushM, bubbleM, flushW, bubbleW,
    output reg [1:0] op1_sel, op2_sel, reg2_sel
    );

    always @(*)
        if(rst)
            {flushF, flushD, flushE, flushM, flushW} = 5'b11111;
        else
        begin
            {flushF, flushD, flushE, flushM, flushW} = 5'b00000;
            {bubbleF, bubbleD, bubbleE, bubbleM, bubbleW} = 5'b00000;
            // op1_sel
            if(reg_write_en_MEM  && src_reg_en[1] && (reg_dstM == reg1_srcE) && (reg1_srcE != 5'b0))
                op1_sel = 2'b00;// inst2[src1] == inst1[dst]
            else if(reg_write_en_WB && src_reg_en[1] && (reg_dstW == reg1_srcE) && (reg1_srcE != 5'b0))
                op1_sel = 2'b01;// inst3[src1] == inst1[dst]
            else if(alu_src1)
                op1_sel = 2'b10;// auipc
            else
                op1_sel = 2'b11;
            // op2_sel
            if(alu_src2 == 2'b00)
            begin
                if((reg_write_en_MEM  && src_reg_en[0] && (reg_dstM == reg2_srcE) && (reg2_srcE != 5'b0)) ||
                (csr_write_en_MEM  && csr_write_en_EX && (csr_dstM == csr_srcE)))
                    op2_sel = 2'b00;// inst2[src2] == inst1[dst]
                else if((reg_write_en_WB && src_reg_en[0] && (reg_dstW == reg2_srcE) && (reg2_srcE != 5'b0)) ||
                (csr_write_en_WB && csr_write_en_EX && (csr_dstW == csr_srcE)))
                    op2_sel = 2'b01;// inst3[src2] == inst1[dst]
                else
                    op2_sel = 2'b11;
            end
            else if(alu_src2 == 2'b01)
                op2_sel = 2'b10;// alu_op2 comes from reg2src
            else
                op2_sel = 2'b11;// comes from imm
            // reg2_sel
            if((reg_write_en_MEM  && src_reg_en[0] && (reg_dstM == reg2_srcE) && (reg2_srcE != 5'b0)) ||
            (csr_write_en_MEM  && csr_write_en_EX && (csr_dstM == csr_srcE)))
                reg2_sel = 2'b00;// inst2[src2] == inst1[dst]
            else if((reg_write_en_WB && src_reg_en[0] && (reg_dstW == reg2_srcE) && (reg2_srcE != 5'b0)) ||
            (csr_write_en_WB && csr_write_en_EX && (csr_dstW == csr_srcE)))
                reg2_sel = 2'b01;// inst3[src2] == inst1[dst]
            else
                reg2_sel = 2'b10;
            // bubble and flush
            if(wb_select)// load inst in EXE
                if((reg_dstE == reg1_srcD) || (reg_dstE == reg2_srcD))
                    {bubbleF, bubbleD, flushE} = 3'b111;
            //jump inst
            if(jalr || (br && !(BTB_EX && BHT_EX)) || (!br && BHT_EX && BTB_EX)) // 分支预测失败时需要flush
                {flushD, flushE} = 2'b11;
            else if(jal)
                flushD = 1'b1;
            if(miss)
                {bubbleF, bubbleD, bubbleE, bubbleM, bubbleW} = 5'b11111;
        end

endmodule
