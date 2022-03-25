`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/18 21:32:26
// Design Name: 
// Module Name: DFF
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DFF #(parameter WIDTH = 32, RST_VALUE = 0)(
    input clk, rstn, en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
    );
  always @(posedge clk or negedge rstn) begin
        if(!rstn)
            q <= RST_VALUE;
        else if(en)
            q <= d;
        else
            q <= q;
  end
endmodule
