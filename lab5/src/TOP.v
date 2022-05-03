`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/24 14:01:44
// Design Name: 
// Module Name: TOP
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


module TOP(
    input clk,            //clk100mhz
    input rstn,           //cpu_resetn

    input step,           //btnu
    input cont,           //btnd
    input chk,            //btnr
    input data,           //btnc
    input del,            //btnl
    input [15:0] x,       //sw15-0

    output stop,          //led16r
    output [15:0] led,    //led15-0
    output [7:0] an,      //an7-0
    output [6:0] seg,     //ca-cg 
    output [2:0] seg_sel  //led17
);
    wire [31:0] io_dout, io_din, chk_pc, chk_data;
    wire rst_cpu, io_we, io_rd, clk_cpu;
    wire [7:0] io_addr;
    wire [15:0] chk_addr;
    CPU cpu(.clk(clk_cpu), .rst(rst_cpu), .io_addr(io_addr), .io_dout(io_dout), 
    .io_we(io_we), .io_rd(io_rd), .io_din(io_din), 
    .chk_pc(chk_pc), .chk_addr(chk_addr), .chk_data(chk_data));
    
    pdu pdu1(.clk(clk), .rstn(rstn), .step(step), .cont(cont), 
    .chk(chk), .data(data), .del(del), .x(x), .stop(stop), 
    .led(led), .an(an), .seg(seg), .seg_sel(seg_sel), 
    .clk_cpu(clk_cpu), .rst_cpu(rst_cpu), .io_addr(io_addr), .io_dout(io_dout), 
    .io_we(io_we), .io_rd(io_rd), .io_din(io_din), 
    .pc(chk_pc), .chk_addr(chk_addr), .chk_data(chk_data));

endmodule