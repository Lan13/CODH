`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/21 22:13:53
// Design Name: 
// Module Name: FORWARD_UNIT
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


module FORWARD_UNIT(
    input [31:0] IRM,
    input [31:0] IRW,
    input [2:0] EX_MEM_WB,
    input [2:0] MEM_WB_WB,
    input [31:0] IRd,
    output reg [1:0] afwd,
    output reg [1:0] bfwd
);
    always@(*) begin
        
        if (IRM[6:0] == 7'b0010111 && IRM[11:7] != 5'b0 && IRM[11:7] == IRd[19:15])
            afwd = 2'b11;
        else if (EX_MEM_WB[0] && IRM[11:7] != 5'b0 && IRM[11:7] == IRd[19:15])
            afwd = 2'b10;
        else if (MEM_WB_WB[0] && IRW[11:7] != 5'b0 && IRW[11:7] == IRd[19:15])
            afwd = 2'b01;
        else
            afwd = 2'b00;

        if (IRM[6:0] == 7'b0010111 && IRM[11:7] != 5'b0 && IRM[11:7] == IRd[24:20])
            bfwd = 2'b11;
        else if (EX_MEM_WB[0] && IRM[11:7] != 5'b0 && IRM[11:7] == IRd[24:20])
            bfwd = 2'b10;
        else if (MEM_WB_WB[0] && IRW[11:7] != 5'b0 && IRW[11:7] == IRd[24:20])
            bfwd = 2'b01; 
        else
            bfwd = 2'b00;

    end
endmodule
