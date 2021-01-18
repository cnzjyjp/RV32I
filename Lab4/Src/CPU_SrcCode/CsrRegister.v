`timescale 1ns / 1ps

//添加用于实现CSR指令的控制和状态寄存器
//类似GeneralRegister的实现方式
//csr部分references:指令手册特权级&用户级、https://www.cnblogs.com/mikewolf2002/p/11305031.html

// 输入
    // clk               时钟信号
    // rst               寄存器重置信号
    // csr_write_en      寄存器写使能
    // csr_rd_addr       读地址
    // csr_wb_addr       写回地址
    // csr_wb_data       写回数据
// 输出
    // csr_rd_data       读数据

module CsrRegisterFile(
    input wire clk,
    input wire rst,
    input wire csr_write_en,
    input wire [11:0] csr_rd_addr,
    input wire [11:0] csr_wb_addr,
    input wire [31:0] csr_wb_data,
    output wire [31:0] csr_rd_data,
    //debug CSR
    output wire [31:0] csr0, csr1, csr2
    );
    
    //在这里实现的CSR为32位，否则，读取以后需要先零扩展到32位再进行后续操作
    reg [31:0] csr_reg_file[4095:0];
    integer i;

    // init register file
    initial
    begin
        for(i = 0; i < 4096; i = i + 1) 
            csr_reg_file[i][31:0] <= 32'b0;
    end

    // write in clk negedge, reset in rst posedge
    // if write register in clk posedge,
    // new wb data also write in clk posedge,
    // so old wb data will be written to register
    always@(negedge clk or posedge rst) 
    begin 
        if (rst)
            for (i = 0; i < 4096; i = i + 1) 
                csr_reg_file[i][31:0] <= 32'b0;
        else if(csr_write_en)
            csr_reg_file[csr_wb_addr] <= csr_wb_data;   
    end

    // read data changes when address changes
    assign csr_rd_data = csr_reg_file[csr_rd_addr];
    assign csr0 = csr_reg_file[0][31:0];
    assign csr1 = csr_reg_file[1][31:0];
    assign csr2 = csr_reg_file[2][31:0];
    



endmodule
