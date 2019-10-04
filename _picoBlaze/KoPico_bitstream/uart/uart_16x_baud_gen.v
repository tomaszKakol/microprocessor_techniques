`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:39:30 01/14/2011 
// Design Name: 
// Module Name:    uart_16x_baud_gen 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_16x_baud_gen #(parameter BAUD_RATE=115200, CLK_FREQ=50e6, COUNTER_DEPTH=16)(
    input clk,
    input reset,
    output reg out_16_x_baud
    );
//Second localparam UART_CLK_NUM is necessary because of insufficient number precision
//For 50MHz -> 27.126736
localparam real UART_CLK_NUM = CLK_FREQ/(16*BAUD_RATE);
//For 50MHz -> 2416d = 970h
localparam [COUNTER_DEPTH-1:0] UART_TIME_CONST = 2**(COUNTER_DEPTH)/UART_CLK_NUM;

//reg reset = 1'b0;
reg [COUNTER_DEPTH-1:0] counter;
//reg clk=0;

always @(posedge clk) begin
   if (reset) begin
      counter <= {COUNTER_DEPTH{1'b0}};
      out_16_x_baud <= 1'b0;
   end
   else begin
      if (counter <= UART_TIME_CONST)
         out_16_x_baud <= 1'b1;
		else
			out_16_x_baud <= 1'b0;
      counter <= counter + UART_TIME_CONST;
   end
end

//always
//   #1 clk=~clk;
//
//initial begin
//   $display("Stala czasowa %d, liczba zegarow %f",UART_TIME_CONST, UART_CLK_NUM);
//   $monitor(" %t, %b %b ",$time, out_16_x_baud, reset);
//   reset=1'b1;
//   #2 reset=1'b0;
//   #1000 $finish;
//end
endmodule
