`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/23 15:13:44
// Design Name: 
// Module Name: HAZARD_UNIT
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


module HAZARD_UNIT(
    input [31:0] IR,
    input [31:0] IRd,
    output reg ctrl,
    output reg PCWrite,
    output reg IF_ID_Write
);
    always@(*) begin
        if (IRd[6:0] == 7'b0000011 && (IRd[11:7] == IR[19:15] || IRd[11:7] == IR[24:20])) begin
            PCWrite = 1'b0;
            IF_ID_Write = 1'b0;
            ctrl = 1'b0;
        end
        else begin
            PCWrite = 1'b1;
            IF_ID_Write = 1'b1;
            ctrl = 1'b1;
        end
    end
endmodule
