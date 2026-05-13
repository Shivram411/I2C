`timescale 1ns / 1ps
module UART_RX ( input clk , rst ,
                 input data_in ,
                 output reg [3:0] data_out,
                 output reg [7:0] uart_out,
                 output reg rx_valid );

parameter   IDLE   = 2'b00,
            START  = 2'b01,
            STOP   = 2'b10;
reg [1:0] state;
reg [3:0] data_counter;
reg [7:0] rx_reg;
reg [10:0] baud_counter; // Counts upto 1085 cycles


always@(posedge clk)
begin
    if(~rst)
    begin
        state        <= IDLE ;
        data_counter <= 0;
        rx_reg       <= 0;
        baud_counter <= 0;
        data_out     <= 0;
        rx_valid <= 0;

    end
    else
        case(state)
        IDLE:
        begin
            uart_out <= 0;
            rx_valid <= 0;
            if(~data_in)          //data in is always tied to high , hence we check for dip in datain
                if(baud_counter < 11'd543)   // reaching mid point of the data_in signal
                begin
                    baud_counter <= baud_counter + 1;
                end
                else
                begin
                    state <= START;
                    baud_counter <= 0;
                end
            else
                baud_counter <= 0;  //rogue data spike in middle causes it to reset
        end
        START:
        begin
            if(data_counter[3])
                state <= STOP;
            else
            begin
                if(~data_counter[3] )
                begin
                    if(baud_counter == 11'd1084)  //shifts data at the exact middle point of clk high
                    begin
                        rx_reg       <= {data_in , rx_reg[7:1]};
                        data_counter <= data_counter + 1;
                        baud_counter <= 0;
                    end
                    else
                        baud_counter <= baud_counter + 1;
                end
                else
                    data_counter <=0;
            end
        end
        
        STOP:     // Configured For ZYBO Board , it consists of 4 led Lights , hence 4bit data_out dedicated for turning those on
        begin
            uart_out <= rx_reg;
            data_counter <= 0;
            if(baud_counter < 11'd1084)
            begin
                case(rx_reg)
                8'b00110000 : data_out <= 4'b0000;
                8'b00110001 : data_out <= 4'b0001;
                8'b00110010 : data_out <= 4'b0010;
                8'b00110011 : data_out <= 4'b0011;
                8'b00110100 : data_out <= 4'b0100;
                8'b00110101 : data_out <= 4'b0101;
                8'b00110110 : data_out <= 4'b0110;
                8'b00110111 : data_out <= 4'b0111; //7
                8'b00111000 : data_out <= 4'b1000;
                8'b00111001 : data_out <= 4'b1001;
                8'b01000001 : data_out <= 4'b1010;
                8'b01000010 : data_out <= 4'b1011;
                8'b01000011 : data_out <= 4'b1100;
                8'b01000100 : data_out <= 4'b1101;
                8'b01000101 : data_out <= 4'b1110;
                8'b01000110 : data_out <= 4'b1111; 
                8'b01000001 : data_out <= 4'b0001; 
                8'b01010011 : data_out <= 4'b0011; 
                8'b01000100 : data_out <= 4'b1111;       
                default: data_out <= 4'b1111;
                endcase
                baud_counter <= baud_counter + 1;
            end
            else
            begin
                rx_valid <= 1;
                state <= IDLE;
                baud_counter <= 0;
            end
        end
    endcase    
end


endmodule



