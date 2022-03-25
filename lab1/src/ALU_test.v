`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/18 21:30:09
// Design Name: 
// Module Name: ALU_test
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


module ALU_test(
    input [5:0] a, b,
    input clk100mhz, rstn, en,
    input [2:0] s,
    output [5:0] y,
    output [2:0] f
    );
    wire [2:0] wire_s;
    wire [5:0] wire_a, wire_b;
    wire [5:0] wire_y;
    wire [2:0] wire_f;

    DFF #(3,0) DFF_s (.clk(clk100mhz), .rstn(rstn), .en(en), .d(s), .q(wire_s));
    DFF #(6,0) DFF_a (.clk(clk100mhz), .rstn(rstn), .en(en), .d(a), .q(wire_a));
    DFF #(6,0) DFF_b (.clk(clk100mhz), .rstn(rstn), .en(en), .d(b), .q(wire_b));
    

    ALU #(6) ALU_test (.a(wire_a), .b(wire_b), .s(wire_s), .y(wire_y), .f(wire_f));
    
    DFF #(6,0) DFF_y (.clk(clk100mhz), .rstn(rstn), .en(1'b1), .d(wire_y), .q(y));
    DFF #(3,0) DFF_f (.clk(clk100mhz), .rstn(rstn), .en(1'b1), .d(wire_f), .q(f));
endmodule
