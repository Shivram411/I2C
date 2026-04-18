`timescale 1ns / 1ps
module MCP4725_Driver(  input clk , rst , 
                        inout sda,
                        output scl);
                        
reg [7:0]  slave_address   = 8'b1100_0000;              //have to ask about last Bit 1,2,3 ; 0 is readwrite signal
reg        ReadWrite       = 0;                        // 0 for write and 1 for read
reg [7:0]  config_byte     = 8'b010_11_00_1;            // C2,C1,C0_X,X_PD0,PD1_X
reg [15:0] dac_data        = 16'b1111_1111_1111_0000;   //Highest Voltage i.e VDD (First 12 bits only , last 4 bits is XXXX)
reg start;
wire data_valid;
reg [2:0] byte_count;
reg [7:0]data;



I2C_Master uut (clk , rst , start , ReadWrite , data , sda , scl , data_valid);

always@(posedge clk)
begin
    if(~rst)
    begin
        start       <= 0;
        byte_count  <= 0;
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
            end
            
            else if(byte_count == 2)
            begin
                data <=     dac_data[15:8];
            end
            else if(byte_count == 3)
            begin
                data <=     dac_data[7:0];
            end
            else
            begin
                start <= 0;
                byte_count <= byte_count ;
            end
        end
    end
end                
                
    

endmodule
