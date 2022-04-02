`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/25 20:44:35
// Design Name: 
// Module Name: BTN_EDEG
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


module BTN_EDGE #(parameter WIDTH = 16)(
    input clk,
    input [WIDTH-1:0] btn,
    output [WIDTH-1:0] btn_edge
);
    reg btn1[WIDTH-1:0], btn2[WIDTH-1:0];
    integer i;
    genvar j;

    always@(posedge clk) begin
        for(i = 0; i <= WIDTH - 1; i = i + 1)
            btn1[i] <= btn[i];
    end

    always@(posedge clk) begin
        for(i = 0; i <= WIDTH - 1; i = i + 1)
            btn2[i] <= btn1[i];
    end

    for(j = 0; j <= WIDTH - 1; j = j + 1) begin
        assign btn_edge[j] = (btn1[j]&(~btn2[j]))|((~btn1[j])&btn2[j]);
    end
endmodule
