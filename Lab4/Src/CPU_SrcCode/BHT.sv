`timescale 1ns / 1ps
module BHT (
	input clk,
	input rst,
	input REAL,
	input wire		[29:0] PC_IF,//IF段的PC
	input wire      [29:0] PC_EX,//EX段的PC，用来更新状态机
	input BHT_Update,//是否需要更新
	output reg BHT	//BHT选中信号
);

localparam SET_LEN = 6;//组地址的长度
localparam TAG_LEN = 7;//TAG的长度
localparam SET_SIZE = 1 << SET_LEN;//组的数量

reg [1:0] state			[SET_SIZE];//状态数组
reg		  valid			[SET_SIZE];//valid数组
reg [TAG_LEN-1:0] BHT_tags[SET_SIZE];//TAG数组

wire [SET_LEN - 1:0] PC_IF_REAL;
wire [TAG_LEN - 1:0] TAG_REAL_IF;
wire [TAG_LEN - 1:0] TAG_REAL_EX;
wire [SET_LEN - 1:0] PC_EX_REAL;

//截取PC对应的位
assign PC_IF_REAL = PC_IF[SET_LEN-1:0];
assign TAG_REAL_IF = PC_IF[TAG_LEN + SET_LEN - 1: SET_LEN];
assign TAG_REAL_EX = PC_EX[TAG_LEN + SET_LEN - 1: SET_LEN];
assign PC_EX_REAL = PC_EX[SET_LEN - 1:0];

initial//初始化
begin
	for (integer i = 0; i < SET_SIZE; i++)
		valid[i] = 0;
end

// 分支预测
always @(*)
begin
	if (rst)
	begin
		for (integer i = 0; i < SET_SIZE; i++)
		valid[i] = 0;
	end
	else begin
		if (valid[PC_IF_REAL] && TAG_REAL_IF == BHT_tags[PC_IF_REAL])//命中，输出state的高位
			BHT <= state[PC_IF_REAL][1];
		else begin
			BHT <= 1'b0;
		end
	end
end

// 状态更新
always @(posedge clk)
begin
	if (BHT_Update)
	begin
		if (!valid[PC_EX_REAL] || TAG_REAL_EX != BHT_tags[PC_EX_REAL])//第一次预测或者覆盖
		begin
			valid[PC_EX_REAL] <= 1'b1;
			BHT_tags[PC_EX_REAL] <= TAG_REAL_EX;
			if (REAL) begin//如果第一次是命中
				state[PC_EX_REAL] <= 2'b10;
			end
			else begin//第一次不命中
				state[PC_EX_REAL] <= 2'b01;
			end
		end
		else if (valid[PC_EX_REAL] && TAG_REAL_EX == BHT_tags[PC_EX_REAL])//状态机的更新
		begin
			if (REAL && state[PC_EX_REAL] != 2'b11)//命中，+1
				state[PC_EX_REAL] <= state[PC_EX_REAL] + 1;
			else if (!REAL && state[PC_EX_REAL] != 2'b00) begin//不命中，-1
				state[PC_EX_REAL] <= state[PC_EX_REAL] - 1;
			end
		end
	end
end


endmodule

