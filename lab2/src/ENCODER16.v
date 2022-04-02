`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/25 21:37:16
// Design Name: 
// Module Name: ENCODER16
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


module ENCODER16 (
    input clk,
    input [15:0] signal,
    output reg [3:0] h,
    output p
);
    always@(*) begin
        case(signal)
            16'h0001: h = 4'h0;
            16'h0002: h = 4'h1;
            16'h0004: h = 4'h2;
            16'h0008: h = 4'h3;
            16'h0010: h = 4'h4;
            16'h0020: h = 4'h5;
            16'h0040: h = 4'h6;
            16'h0080: h = 4'h7;
            16'h0100: h = 4'h8;
            16'h0200: h = 4'h9;
            16'h0400: h = 4'ha;
            16'h0800: h = 4'hb;
            16'h1000: h = 4'hc;
            16'h2000: h = 4'hd;
            16'h4000: h = 4'he;
            16'h8000: h = 4'hf;
        endcase
    end
    assign p = |signal;

endmodule
