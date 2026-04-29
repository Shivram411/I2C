`timescale 1ns / 1ps
module I2C_Master_tb();
reg clk , rst , start; 
reg [7:0]data;
reg ReadWrite;
wire sda;
wire scl;
reg tb_enable , tb_dataout;

assign sda = tb_enable? tb_dataout : 1'bz;
I2C_Master  uut ( clk , rst , data , start , ReadWrite , sda , scl);

initial 
begin 
clk = 0;
end

always #4 clk = ~clk;

initial 
begin
rst = 0;
start = 0;
tb_dataout =0;
tb_enable = 0;
data = 8'b1001_0101;
ReadWrite = 1;
#20;
rst = 1;
start = 1;
//#20848;
repeat(9) @(posedge scl);
tb_enable = 1;
tb_dataout = 1;
#2512;
tb_enable = 0;
tb_dataout = 0;
repeat(9) @(posedge scl);
tb_enable = 1;
tb_dataout = 1;
start = 0;
#2512;
tb_enable = 0;
tb_dataout = 0;
end

endmodule
