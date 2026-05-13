`timescale 1ns / 1ps
module I2C_Master( input clk , rst , 
                   input       start,
                   input       ReadWrite,
                   input [7:0] data,
                   inout       sda,
                   output      scl,
                   output      sdainput_ila,
                   output      sdaoutput_ila,
                   output      enable1,
                   output  reg data_valid,
                   output  reg [3:0]led,
                   output      [2:0]state1,
                   output      [3:0]data_counter1,
                   output       sda_listener    );
                  
parameter 
    IDLE                = 3'b000,
    START_DATA          = 3'b010,
    RECEIVE_DATA        = 3'b011,
    STOP                = 3'b100,
    ACKNOWLEDGE_DATA    = 3'b101,
    ACKNOWLEDGE_MASTER  = 3'b110;
    
                     
reg [8:0]   i2c_counter;            // 125 MHz Zybo clk divided to match 400kbps(KHz) I2C speed. Count comes upto 312.5
reg [6:0]   wait_counter;
reg [3:0]   data_counter;
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
        data_valid      <= 0;
        led             <= 4'b0001;
        
    end
    else
    begin
        if(state != IDLE)
        begin
            i2c_counter <= i2c_counter + 1;
            if(SCL && i2c_counter == 9'd126)
            begin
                SCL <= 0;
                i2c_counter <= 0;
            end
            else if(~SCL  && i2c_counter == 9'd186 ) 
            begin
                SCL <= 1;
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
                    enable <= 1;
                    SDA <= 1;
                    if(start)
                    begin
                        if(wait_counter ==  7'd80)  // T SU:STA : Refer at the bottom
                        begin
                            wait_counter <= 0;
                            state <= START_DATA;
                            SDA   <= 0;              
                        end
                        
                        else if(wait_counter < 7'd80)
                        begin
                            wait_counter <= wait_counter + 1;
                        end
                    end
                end
                
                START_DATA:
                begin
                    data_valid  <= 0;
                    if(~start && data_counter == 0)
                    begin
                        if(~SCL && i2c_counter == 9'd78)
                        begin                   
                            state <= STOP;
                            enable  <= 1;
                            led     <= 4'b0110;
                            SDA     <= 0;
                        end
                    end
                    
                    else if(~SCL && i2c_counter == 9'd78)
                    begin
                        enable <= 1;
                        if(data_counter <4'd8)
                        begin
                            SDA             <= data[3'd7 - data_counter];
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
                
                ACKNOWLEDGE_DATA:
                begin
                    led <= 4'b1101;
                    if(SCL && i2c_counter == 9'd78 && ~sda && ~start)
                    begin
                        state <= STOP;
                        data_valid <= 1;
                    end
                    else if(SCL && i2c_counter == 9'd78 && ~sda && start)    
                    begin
                        state       <= START_DATA;
                        data_valid  <= 1;
                    end
                end
                
                STOP:
                begin
                    if(SCL && i2c_counter == 9'd78)
                    begin
                        state   <= IDLE;
                        led     <= 4'b0110;
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
                            state           <= ACKNOWLEDGE_MASTER;
                        end
                    end
                end
                
                ACKNOWLEDGE_MASTER:
                begin
                    if(~SCL && i2c_counter == 9'd78)
                    begin
                        SDA <= 1; // NACK : basically tells the slave it doesnt want more data
                    end
                    else if(SCL && i2c_counter == 9'd78)
                    begin
                        state <= STOP;
                    end
                end                                 
        endcase
    end
end //for always
assign scl = SCL;
assign sdainput_ila =    enable ? SDA : 0;
assign sdaoutput_ila = ~(enable)? sda : 1;
assign sda_listener = sda;
assign enable1  = enable;
assign state1 = state;
assign data_counter1 = data_counter;
endmodule




/* T SU:STA : Repeated START condition setup time : Minimum of 600 ns has to be waited for SCL to be pulled low after SDA is pulled low 
 I have given 80 cycles , 600ns / 8ns comes to 75 cycles , i have given 5 extra cyles as a safety margin*/
