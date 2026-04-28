`timescale 1ns / 1ps
module MCP4725_Driver(  input clk , rst , 
                        input [2:0]btn,
                        inout sda,
                        output scl,
                        output reg [3:0]led);
                        
reg [7:0]  slave_address   = 8'b1100_0010;        //have to ask about last Bit 1,2,3 ; 0 is readwrite signal
reg        ReadWrite       = 0;                        // 0 for write and 1 for read
reg [7:0]  config_byte     = 8'b010_00_00_1;            // C2,C1,C0_X,X_PD0,PD1_X
reg [15:0] dac_data_full   = 16'b1111_1111_1111_0000;   //Highest Voltage i.e VDD (First 12 bits only , last 4 bits is XXXX)
reg [15:0] dac_data_half   = 16'b1100_0000_0000_0000; // half
reg [15:0] dac_data_zero   = 16'b0;
reg start;
wire data_valid;
reg [2:0] byte_count;
reg [7:0]data;
wire sdainput_ila , sdaoutput_ila ;
wire enable;
wire [2:0]state1;
wire [3:0] data_counter1;
wire [3:0] led1;
wire sda_listener;

I2C_Master uut (clk , rst , start , ReadWrite , data , sda , scl ,sdainput_ila , sdaoutput_ila , enable ,data_valid , led1 , state1 , data_counter1 , sda_listener);
ila_0 uut1  (clk , enable , data_valid , scl  , byte_count  , sda_listener , state1 , data_counter1);
always@(posedge clk)
begin
    if(~rst)
    begin
        start       <= 0;
        byte_count  <= 0;
        led        <= 4'b0001;
    end
    else
    begin
        if(byte_count == 0 )
        begin
            start <= 1;
            data <= slave_address;
            byte_count <= byte_count + 1;
        end
        else if(data_valid)
        begin

            byte_count <= byte_count + 1;
            if(byte_count == 1)
            begin
                data <=     config_byte;
                led  <= 4'b1101;

            end
            
            else if(byte_count == 2)
            begin
                if(btn[0])
                begin
                    data <=     dac_data_full[15:8];
                    led  <= 4'b1111;
                end
                else if(btn[1])
                begin
                    data <=     dac_data_half[15:8];
                    led  <= 4'b1111;
                end
                else if(btn[2])
                begin
                    data <=     dac_data_zero[15:8];
                    led  <= 4'b1111;
                end
            end
            else if(byte_count == 3)
            begin
                if(btn[0])
                begin
                    data <=     dac_data_full[7:0];
                end
                else if(btn[1])
                begin
                    data <=     dac_data_half[7:0];
                end
                else if(btn[2])
                begin
                    data <=     dac_data_zero[7:0];
                end

            end
            else if(byte_count == 4)
            begin 
                start <= 0;
                byte_count <= byte_count ;
                
            end
        end
    end
end                
                
    

endmodule
