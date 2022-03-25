`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/19 10:55:04
// Design Name: 
// Module Name: DMUX2
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


module DMUX2 #(parameter MSB = 31, LSB = 0)(
    input [MSB: LSB] d,
    input s,
    output reg [MSB: LSB] sel1, sel0
    );
    always @(*) begin
        if (s == 1'b0) begin
            sel0 = d;
        end
        else begin
            sel1 = d;
        end
    end
endmodule
