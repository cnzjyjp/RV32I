`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/15 22:01:22
// Design Name: 
// Module Name: CSRRegisterFile
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
    //  CSR 寄存器，提供读写端口（同步写，异步读）
    //  时钟下降沿写入
    //  0号寄存器的值始终为0
// 输入
    // clk               时钟信号
    // rst               寄存器重置信号
    // write_en          寄存器写使能
    // addr             reg读地址
    // wb_addr           写回地址
    // wb_data           写回数据
// 输出
    // csr_out              csr 读数据


module CSRRegisterFile(
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [11:0] addr, wb_addr,
    input wire [31:0] wb_data,
    output wire [31:0] csr_out
    );

    reg [31:0] reg_file[4095:1];// 2^12 address space
    integer i;

    // init register file
    initial
    begin
        for(i = 1; i < 4096; i = i + 1) 
            reg_file[i][31:0] <= 32'b0;
    end

    // write in clk negedge, reset in rst posedge
    // if write register in clk posedge,
    // new wb data also write in clk posedge,
    // so old wb data will be written to register
    always@(negedge clk or posedge rst) 
    begin 
        if (rst)
            for (i = 1; i < 4096; i = i + 1) 
                reg_file[i][31:0] <= 32'b0;
        else if(write_en && (wb_addr != 12'h0))
            reg_file[wb_addr] <= wb_data;   
    end

    // read data changes when address changes
    assign csr_out = (addr == 12'b0) ? 32'h0 : reg_file[addr];

endmodule
