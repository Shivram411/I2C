`timescale 1ns / 1ps
module UART_I2C(input clk , rst,
                input datain_rx,
                inout sda,
                output scl, 
                output reg [3:0] led);

parameter
           RX_IDLE 	    = 4'b0000,
	       RX_S    	    = 4'b0001,
	       RX_T    	    = 4'b0010,
	       RX_A		    = 4'b0011,
	       RX_R   	    = 4'b0100,
	       RX_START	    = 4'b0101,
	       RX_O		    = 4'b0110,
           RX_STOP      = 4'b0111,
           I2C_START    = 4'b1000;
                
reg        start_TX;
wire [7:0] dataout_rx;
wire       rx_valid , tx_valid;
wire [3:0] ledout1 , ledout2 ;
wire [7:0] message_out;
reg  [3:0] state;
reg  [7:0] memory [0:3]; // taking 12 bits hence 2 depth array
reg  [2:0] memory_counter; // counts upto 3
reg        start_i2c ; 
wire       i2c_done;
reg  [15:0] dac_data;
reg  [11:0] decimal_convertor;
wire [2:0]dbg_state1;
wire dbg_start;
wire dbg_sda_listener;

UART_RX receiving  (clk , rst , datain_rx  , ledout1   , dataout_rx , rx_valid );
MCP4725_Driver uut (clk , rst , start_i2c  , dac_data  , sda , scl  , ledout2 , i2c_done , dbg_state1 ,dbg_sda_listener , dbg_start);
ila_0 uut2         (clk , dbg_sda_listener , dbg_start , {decimal_convertor,3'b000}   , dbg_state1);
always@(posedge clk)
begin
    if(~rst)
    begin
        state <= RX_IDLE;
        start_TX <= 0;
        memory_counter <= 0;
        start_i2c <= 0; 
        led      <= 4'b1010;
    end
    
    else
    begin
        case(state)
            RX_IDLE:
            begin                
                led <= 4'b0101;
                if(rx_valid)
                begin
                    if(dataout_rx == 8'b0101_0011)        // S
                    begin
                        state <= RX_S;
                        led   <= 4'b0001;
                    end
                end
            end
            
            RX_S:
            begin
                led   <= 4'b0010;
                if(rx_valid) 
                begin
                    if(dataout_rx == 8'b0101_0100)          //T
                    begin
                        state <= RX_T;
                    end
                    else
                    begin
                        state <= RX_IDLE;
                    end
                end
            end
            
            RX_T:
            begin
                if(rx_valid)
                begin
                    if(dataout_rx == 8'b0100_0001)         //A
                    begin
                        state <= RX_A;
                        led   <= 4'b0011;
                    end
                    else if(dataout_rx == 8'b0100_1111)    //O
                    begin
                        state <= RX_O;
                    end
                    else
                    begin   
                        state <= RX_IDLE;
                    end
                end
            end           
            
            RX_A:
            begin
                if(rx_valid)
                begin
                    if(dataout_rx == 8'b0101_0010)          //R
                    begin
                        state <= RX_R;
                        led   <= 4'b0100;
                    end
                    else 
                    begin
                        state <= RX_IDLE;
                    end
                end
            end
            
            RX_R:
            begin
                if(rx_valid)
                begin
                    if(dataout_rx == 8'b0101_0100)         //T
                    begin
                        state <= RX_START;
                        led   <= 4'b0101;
                    end
                    else
                    begin
                        state <= RX_IDLE;
                    end
                end
            end
            RX_O:
            begin
                if(rx_valid)
                begin
                    if(dataout_rx == 8'b0101_0000)
                    begin
                        state <= RX_STOP;
                        led   <= 4'b0110;
                    end
                    else
                    begin
                        state <= RX_IDLE;
                    end
                end
            end
            RX_START:
            begin
                led   <= 4'b1111;
                if(memory_counter == 0 && rx_valid)
                begin
                    memory[memory_counter] <= dataout_rx;
                    memory_counter <= memory_counter + 1;
                end
                else if(memory_counter == 1 && rx_valid)
                begin
                    memory[memory_counter] <= dataout_rx;
                    memory_counter <= memory_counter + 1;  //could be made into one if statement but leave
                end
                
                else if(memory_counter == 2 && rx_valid)
                begin
                    memory[memory_counter] <= dataout_rx;
                    memory_counter <= memory_counter + 1; 
                end
                
                else if(memory_counter == 3 && rx_valid)
                begin
                    memory[memory_counter] <= dataout_rx;
                    memory_counter <= memory_counter + 1;  
                end
                
                else if(memory_counter == 4)
                begin

                    decimal_convertor   <= ( (memory[0]- 48) * 1000 ) + ( (memory[1]-48) * 100 ) + ( (memory[2]-48) * 10 ) + ( memory[3]-48 );
                    memory_counter      <= 0;
                    state               <= RX_STOP;
                end
            end
            RX_STOP:
            begin
                start_i2c <= 1;
                dac_data <= {decimal_convertor , 4'b0000};
                state <= I2C_START;
            end
            
            I2C_START:
            begin
            
                led <= 4'b1110;
                if(i2c_done)
                begin
                    start_i2c <= 0;
                    state <= RX_IDLE;
                end
            end
         endcase
            end
            end
                   
endmodule
