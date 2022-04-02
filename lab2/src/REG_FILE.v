`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/25 17:02:23
// Design Name: 
// Module Name: REG_FILE
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


module REG_FILE #(parameter AW = 5, parameter DW = 32)(
    input clk,
    input [AW-1:0] ra0, ra1,
    output [DW-1:0] rd0, rd1,
    input [AW-1:0] wa,
    input [DW-1:0] wd,
    input we
);
    reg [DW-1:0] rf[0:(1<<AW)-1];
    wire [DW-1:0] ini;
    assign ini = 0;
    assign rd0 = we ? wd : rf[ra0];
    assign rd1 = rf[ra1];
    always @(posedge clk) begin
        if (we) begin
            if (wa != 0)
                rf[wa] <= wd;
        end
    end
    always@(*) begin
        rf[0] = ini;
    end
endmodule
