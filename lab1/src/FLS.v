`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/19 09:45:24
// Design Name: 
// Module Name: FLS
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


module FLS(
    input clk, rstn, en,
    input [15:0] d,
    output reg [15:0] y
    );
    wire [15:0] dmux_a, dmux_b, mux_a, mux_b, dff_a, dff_b, mux_ab, mux_y, wire_y, out_y;
    wire [2:0] wire_f;
    reg [15:0] reg_a, reg_b;
    reg [1:0] reg_cnt;

    reg [3:0] en_cnt, rstn_cnt;
    wire en_clean, rstn_clean;

    reg en_btn1, en_btn2, rstn_btn1, rstn_btn2;
    wire en_edge, rstn_edge;

    DMUX2 #(16,0) DMUX_d(.d(d), .s(reg_cnt[0]), .sel0(dmux_a), .sel1(dmux_b));

    MUX2 #(16,0) MUX_a(.sel0(dmux_a), .sel1(reg_b), .s(reg_cnt[1]), .y(mux_a));
    MUX2 #(16,0) MUX_b(.sel0(dmux_b), .sel1(wire_y), .s(reg_cnt[1]), .y(mux_b));

    DFF #(16,0) DFF_a(.clk(clk), .rstn(rstn_edge), .en(en_edge), .d(mux_a), .q(dff_a));
    DFF #(16,0) DFF_b(.clk(clk), .rstn(rstn_edge), .en(en_edge), .d(mux_b), .q(dff_b));

    ALU #(16) ALU_test (.a(reg_a), .b(reg_b), .s(3'b001), .y(wire_y), .f(wire_f));

    MUX2 #(16,0) MUX_y(.sel0(reg_a), .sel1(reg_b), .s(reg_cnt[1]), .y(mux_y));

    DFF #(16,0) DFF_y(.clk(clk), .rstn(rstn_edge), .en(1'b1), .d(mux_y), .q(out_y));

    always@(*) begin
        y = out_y;
        reg_a = dff_a;
        reg_b = dff_b;
    end
    
    always@(posedge clk) begin
        if (en == 1'b0)
            en_cnt <= 4'h0;
        else if (en_cnt < 4'h8)
            en_cnt <= en_cnt + 1'b1;
        else
            en_cnt <= en_cnt;
    end
    assign en_clean = en_cnt[3];

    always@(posedge clk) begin
        if (rstn == 1'b1)
            rstn_cnt <= 4'h0;
        else if (rstn_cnt < 4'h8)
            rstn_cnt <= rstn_cnt + 1'b1;
        else
            rstn_cnt <= rstn_cnt;
    end
    assign rstn_clean = ~rstn_cnt[3];

    always@(posedge clk) begin
        en_btn1 <= en_clean;
        en_btn2 <= en_btn1;
        rstn_btn1 <= rstn_clean;
        rstn_btn2 <= rstn_btn1;
    end
    assign en_edge = en_btn1 & (~en_btn2);
    assign rstn_edge = ~((~rstn_btn1) & rstn_btn2);

    always@(posedge clk or negedge rstn_edge) begin
        if (!rstn_edge)
            reg_cnt = 2'b00;
        else if (reg_cnt == 2'b10)
            reg_cnt = reg_cnt;
        else if (en_edge == 1'b1)
            reg_cnt = reg_cnt + 1'b1;
        else
            reg_cnt = reg_cnt;
    end
endmodule