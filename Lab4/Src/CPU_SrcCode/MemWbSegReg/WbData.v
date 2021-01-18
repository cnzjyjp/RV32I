`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Write-back Data seg reg
// Tool Versions: Vivado 2017.4.1
// Description: Write-back data seg reg for MEM\WB
// 
//////////////////////////////////////////////////////////////////////////////////


//  功能说明
    // MEM\WB的写回寄存器内容
    // 为了数据同步，Data Extension和Data Cache集成在其中
// 输入
    // clk               时钟信号
    // wb_select         选择写回寄存器的数据：如果为0，写回ALU计算结果，如果为1，写回Memory读取的内容
    // load_type         load指令类型
    // write_en          Data Cache写使能
    // addr              Data Cache的写地址，也是ALU的计算结果
    // in_data           Data Cache的写入数据
    // bubbleW           WB阶段的bubble信号
    // flushW            WB阶段的flush信号
// 输出
    // data_WB           传给下一流水段的写回寄存器内容
// 实验要求  
    // 无需修改

module WB_Data_WB(
    input wire clk, rst, bubbleW, flushW,
    input wire wb_select,
    input wire [2:0] load_type,
    input  [3:0] write_en,
    input  [31:0] addr,
    input  [31:0] in_data, 
    output wire [31:0] data_WB,
    output wire miss
    );

    wire [31:0] data_raw;
    wire [31:0] data_WB_raw;


cache #(
    .LINE_ADDR_LEN  ( 3             ),
    .SET_ADDR_LEN   ( 3             ),
    .TAG_ADDR_LEN   ( 5            ),
    .WAY_CNT        ( 2             )
) DataCache1(
    .clk(clk),
    .rst(rst),
    .miss(miss),
    .addr(addr),
    .rd_req(|load_type),
    .rd_data(data_raw),
    .wr_req(|write_en ),
    .wr_data(in_data << (8 * addr[1:0]))
);




    // Add flush and bubble support
    // if chip not enabled, output output last read result
    // else if chip clear, output 0
    // else output values from cache

    reg bubble_ff = 1'b0;
    reg flush_ff = 1'b0;
    reg wb_select_old = 0;
    reg [31:0] data_WB_old = 32'b0;
    reg [31:0] addr_old;
    reg [2:0] load_type_old;
    reg [31:0] miss_count = 32'b0;
    reg [31:0] total_count = 32'b0;

    DataExtend DataExtend1(
        .data(data_raw),
        .addr(addr_old[1:0]),
        .load_type(load_type_old),
        .dealt_data(data_WB_raw)
    );

    always@(posedge clk)
    begin
        bubble_ff <= bubbleW;
        flush_ff <= flushW;
        if(!bubble_ff)
            data_WB_old <= data_WB;
        addr_old <= addr;
        wb_select_old <= wb_select;
        load_type_old <= load_type;
    end

    // 存取指令总数
    always@(posedge clk)
        if(!miss)
            if(|{load_type, write_en})
                total_count <= total_count + 1;
    // 统计缺失次数
    always@(posedge miss)
        if(miss == 1'b1)// 没搞明白的bug：如果不加if判断，在miss恒为0时下面这条语句也可能执行（参数3,2,6,4, 快排算法256个数，FIFO策略）
            miss_count <= miss_count + 1;

    assign data_WB = bubble_ff ? data_WB_old :
                                 (flush_ff ? 32'b0 : 
                                             (wb_select_old ? data_WB_raw :
                                                          addr_old));


    
endmodule
