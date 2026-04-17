`timescale 1ns / 1ps
module I2C_Master( input clk , rst , 
                   input       start,
                   input       ReadWrite,
                   inout       sda,
                   output      scl     );
                  
parameter 
    IDLE                = 3'b000,
    START_ADDRESS       = 3'b001,
    START_DATA          = 3'b101,
    RECEIVE_DATA        = 3'b110,
    STOP                = 3'b010,
    ACKNOWLEDGE_DATA    = 3'b011,
    ACKNOWLEDGE         = 3'b100,
    MASTER_ACKNOWLEDGE  = 3'b111;
                     
reg [8:0]   i2c_counter;            // 125 MHz Zybo clk divided to match 400kbps(KHz) I2C speed. Count comes upto 312.5
reg [3:0]   wait_counter;
reg [3:0]   data_counter;
reg [3:0]   slave_counter;          // 7 bit
reg         addrdata;               // 0 for slave , 1 for data
reg         SCL , SDA;
reg [2:0]   state;
reg         enable;
reg [7:0]   data_storage;

assign sda = enable? SDA : 1'bz ;   // If enable is not 1 , it acts like input
always@(posedge clk)
begin
    if(~rst)
    begin
        SCL             <= 1;
        SDA             <= 1;
        i2c_counter     <= 0;
        wait_counter    <= 0;
        state           <= IDLE;
        enable          <= 1;
        data_counter    <= 0;
        slave_counter   <= 0;
        
    end
    else
    begin
        if(state != IDLE)
        begin
            i2c_counter <= i2c_counter + 1;
            if(i2c_counter == 9'd156)
            begin
                SCL <= ~SCL;
                i2c_counter <= 0;
            end
        end
        else 
        begin
            i2c_counter <= 0;
        end    
         
        case(state)
                IDLE:
                begin
                    SDA <= 1;
                    if(start)
                    begin
                        SDA <= 0;
                        if(wait_counter ==  4'd15)
                        begin
                            wait_counter <= 0;
                            state <= START_ADDRESS;
                            SCL   <= 0;              
                        end
                        
                        else if(wait_counter < 4'd15)
                        begin
                            wait_counter <= wait_counter + 1;
                        end
                    end
                end
                
                START_ADDRESS:
                begin
                    if(~SCL && i2c_counter == 9'd78 && slave_counter < 4'd7 && enable)
                    begin
                        SDA           <= data[3'd6 - slave_counter];
                        slave_counter <= slave_counter + 1;
                    end 
                    else if(~SCL && slave_counter == 4'd7 && enable && i2c_counter == 9'd78)
                    begin
                        SDA           <= ReadWrite;
                        slave_counter <= slave_counter + 1;         // Reset for next use
                    end
                    else if (~SCL && slave_counter == 4'd8 && i2c_counter == 9'd78)
                    begin
                        state         <= ACKNOWLEDGE;
                        enable        <= 0;
                        slave_counter <= 0;
                    end
                 end
                 
                ACKNOWLEDGE:
                begin
                    if(SCL && i2c_counter == 9'd78 && sda && ReadWrite)
                    begin
                        state <= START_DATA;
                    end
                    else if(SCL && i2c_counter == 9'd78 && sda && (~ReadWrite))
                    begin  
                        state   <= RECEIVE_DATA;
                    end
                end
                
                ACKNOWLEDGE_DATA:
                begin
                    if(SCL && i2c_counter == 9'd78 && sda)
                        begin
                            state <= STOP;
                        end
                end
                
                STOP:
                begin
                    if(~SCL && i2c_counter == 9'd78)
                    begin
                        state   <= IDLE;
                        enable  <= 1;
                        SCL     <= 1;
                    end
                end
                
                START_DATA:
                begin
                    
                    if(~start && data_counter == 0)
                    begin                   
                        state <= IDLE;
                    end
                    
                    else if(~SCL && i2c_counter == 9'd78)
                    begin
                        enable <= 1;
                        if(data_counter <4'd8)
                        begin
                            SDA             <= data[data_counter];
                            data_counter    <= data_counter + 1;
                        end
                        else if(data_counter == 4'd8)
                        begin
                            data_counter    <= 0;
                            enable          <= 0;
                            state           <= ACKNOWLEDGE_DATA;
                        end
                    end                    
                end
                
                RECEIVE_DATA:
                begin   
                    if(~SCL && i2c_counter == 9'd78)  // sample at middle of high clock
                    begin
                        enable <= 0;                        
                    end
                    else if(SCL && i2c_counter == 9'd78)
                    begin
                        if(data_counter < 4'd8)
                        begin
                            data_storage[data_counter] <= sda;
                            data_counter               <= data_counter + 1;
                        end
                        else if(data_counter == 4'd8)
                        begin
                            data_counter    <= 0;
                            enable          <= 1;
                            state       <= MASTER_ACKNOWLEDGE;
                        end
                    end
                end
                
                MASTER_ACKNOWLEDGE: 
                begin
                    if(~SCL && i2c_counter == 9'd78)
                    begin
                        SDA   <= 1;
                        state <= STOP; 
                    end
                end
        endcase
    end
end //for always
assign scl = SCL;
endmodule
