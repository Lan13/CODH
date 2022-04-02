`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/26 16:46:40
// Design Name: 
// Module Name: BTN_CLEAN2
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


module BTN_CLEAN2 #(parameter WIDTH = 16)(
    input clk,
    input [WIDTH-1:0] btn,
    output [WIDTH-1:0] btn_clean 
);
    integer i;
    genvar j;
    reg [4:0] btn_cnt[0:WIDTH-1];
    always @(posedge clk) begin
        for(i = 0; i <= WIDTH - 1; i = i + 1) begin
            if(btn[i] == 1'b1)
                btn_cnt[i] <= 5'h0;
            else if(btn_cnt[i] < 5'h1F)
                btn_cnt[i] <= btn_cnt[i] + 1'b1;
            else
                btn_cnt[i] <= btn_cnt[i];
        end
    end
    for(j = 0; j <= WIDTH - 1; j = j + 1) begin
        assign btn_clean[j] = ~btn_cnt[j][4];
    end
endmodule
