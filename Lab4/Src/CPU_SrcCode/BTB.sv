`timescale 1ns / 1ps

module BTB(
	input 			   clk,
    input wire  [29:0]  PC_IF,//用于IF阶段预测
    input wire 	 	   REAL,//EX段是否真正跳转
    input wire         BTB_Update,//需要更新
    input wire  [29:0]  Update_entry,//要更新的项目
    input wire  [31:0] Update_pc,//更新后的地址
    input wire	rst,
    output reg [31:0] PC_predict,//预测的PC值
    output reg BTB //预测跳转
);

localparam SET_LEN = 6;//组的地址长度
localparam TAG_LEN = 7;//TAG的地址长度
localparam SET_SIZE = 1 << SET_LEN;//组数量

reg [31:0] Predicted_PC [SET_SIZE];//预测的PC值数组
reg 	   valid	 	[SET_SIZE];//valid数组
reg [TAG_LEN-1:0] BTB_tags[SET_SIZE];//TAG数组

initial//初始化
begin
	for (integer i = 0; i < SET_SIZE; i++)
	valid[i] <= 0;
end

wire [SET_LEN - 1:0] PC_IF_REAL;
wire [TAG_LEN - 1:0] TAG_REAL_IF;
wire [TAG_LEN - 1:0] TAG_REAL_EX;
wire [SET_LEN - 1:0] Update_entry_REAL;

//截取PC对应的位
assign PC_IF_REAL = PC_IF[SET_LEN-1:0];
assign TAG_REAL_IF = PC_IF[TAG_LEN + SET_LEN - 1: SET_LEN];
assign TAG_REAL_EX = Update_entry[TAG_LEN + SET_LEN - 1: SET_LEN];
assign Update_entry_REAL = Update_entry[SET_LEN - 1:0];

// 预测分支地址
always @(*)
begin
	if (rst)
	begin
		for (integer i = 0; i < SET_SIZE; i++)
            valid[i] <= 0;
	end
	else begin
		if (valid[PC_IF_REAL] && TAG_REAL_IF == BTB_tags[PC_IF_REAL])//命中
			BTB <= 1'b1;
		else//未命中
			BTB <= 1'b0;	
	end
	PC_predict <= Predicted_PC[PC_IF_REAL];//预测的PC值
end


//更新BTB表
always @(posedge clk)
begin
	if (BTB_Update)//需要更新，这里是由EX段判断出
	begin
		if (REAL)//如果分支且预测不跳转: 则valid置1，写入PC值，写入TAG
		begin
			valid[Update_entry_REAL] <= 1'b1;
			Predicted_PC[Update_entry_REAL] <= Update_pc;
			BTB_tags[Update_entry_REAL] <= TAG_REAL_EX;
		end
        else begin//如果未分支且预测跳转: 将valid清0，清除此项
            valid[Update_entry] <= 1'b0;
        end
	end
end

endmodule // BTB


