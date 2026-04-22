`timescale 1ns / 1ps

module MCP4725_Driver_tb();
reg clk , rst;
wire sda;
wire scl;
MCP4725_Driver uut ( clk , rst , sda , scl);

reg tb_enable , tb_dataout;

assign sda = tb_enable? tb_dataout : 1'bz;

initial begin
clk = 1;
end
always #4 clk = ~clk;

initial 
begin
rst = 0; tb_enable =0;tb_dataout = 0;
repeat(2) @(negedge clk);
rst = 1;
repeat(9) @(negedge scl);
#632;
tb_enable = 1;
tb_dataout = 0;
#1888;
tb_enable = 0;
repeat(9) @(posedge scl);
tb_enable = 1;
#1888;
tb_enable = 0;
repeat(9) @(posedge scl);
tb_enable = 1;
#1888;
tb_enable = 0;
repeat(8) @(negedge scl);
#632;
tb_enable = 1;
#1352;
tb_enable = 0;

end
endmodule
