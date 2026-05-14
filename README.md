# I2C
This repository contains the verilog code for I2C protocol supporting a speed of 400Khz and specific to ZYBO board only.

## Files
1. I2C.v : Contains the I2C protocol for both read and write both simulation and synthesis ready.
2. I2C_Master_tb.v : Testbench to run the above file.
3. MCP4725_Driver.v : Code to suit the requirements for MCP4725 I2C DAC module , the datasheet is available over the internet. Here I have used the write command for the dac register.
4. MCP4725_Driver_tb.v : Testbench to run the above file.
5. zybo.xdc : constraints file

## UART&I2C Folder
This folder contains design of using both UART and I2C for the MCP4725 Driver.
UART communication is done between the PC (using DOCKLIGHT) and FPGA. 
I2C communication is done between FPGA and MCP4725.
ASCII numbers has to be sent via UART. For example for maximum brightness the dac needs 12b'1. Via docklight the ASCII '4' , '0' , '9' , '5' has to be sent.
Before sending the dac value , a 'START' sequence has to be sent to enable communication.
