`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/26 09:21:52
// Design Name: 
// Module Name: BTN_EDGE1
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


module BTN_EDGE1(
    input clk,
    input btn,
    output btn_edge
);
    reg btn1, btn2;
    always@(posedge clk) begin
        btn1 <= btn;
    end

    always@(posedge clk) begin
        btn2 <= btn1;
    end
    assign btn_edge = btn1 & (~btn2);
endmodule
