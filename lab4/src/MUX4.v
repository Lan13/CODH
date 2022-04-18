`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/08 13:13:39
// Design Name: 
// Module Name: MUX4
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


module MUX4 #(parameter MSB = 31, LSB = 0)(
    input [MSB: LSB] sel3, sel2, sel1, sel0,
    input [1:0] s,
    output reg [MSB: LSB] y
    );
    always@(*) begin
        case(s)
            2'b00: y = sel0;
            2'b01: y = sel1;
            2'b10: y = sel2;
            2'b11: y = sel3;
        endcase
    end
endmodule