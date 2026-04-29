`timescale 1ns / 1ps
module I2C_Slave(input clk , rst , scl_slave ,
                 inout sda );
                 
parameter 
    IDLE        =   2'b00,
    START       =   2'b01,
    ACKNOWLEDGE =   2'b10;
    
reg [1:0] state;
reg [7:0] data_reg;
reg [6:0] address_reg = 7'b001_0101;

always@(posedge clk)
begin
    if(~rst) 
    begin
        state <= IDLE;
        data_reg <= 0;
    end
    
    else
    begin
        case(state)
            IDLE: 
            begin
                if(~scl_slave)
                begin
                    state <= START;
                end
            end
            
            START:
            begin
                
                    
    end
end

endmodule
