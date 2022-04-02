`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/26 12:15:49
// Design Name: 
// Module Name: SEG7
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


module SEG7(
    input clk,
    input [7:0] a,
    input [15:0] mux_s_out,
    output reg [7:0] an,
    output reg [6:0] display
);
    reg [3:0] d;
    reg [15:0] addr_sel;
    always @(*) begin
        case(d)
            4'h0: display = ~7'b1111110;
            4'h1: display = ~7'b0110000;
            4'h2: display = ~7'b1101101;
            4'h3: display = ~7'b1111001;
            4'h4: display = ~7'b0110011;
            4'h5: display = ~7'b1011011;
            4'h6: display = ~7'b1011111;
            4'h7: display = ~7'b1110000;
            4'h8: display = ~7'b1111111;
            4'h9: display = ~7'b1111011;
            4'hA: display = ~7'b1110111;
            4'hB: display = ~7'b0011111;
            4'hC: display = ~7'b1001110;
            4'hD: display = ~7'b0111101;
            4'hE: display = ~7'b1001111;
            4'hF: display = ~7'b1000111;
        endcase
    end

    always@(posedge clk) begin
        addr_sel <= addr_sel + 1'b1;
    end

    always@(*) begin
        case(addr_sel[15:13])
            3'b000: begin
                an = 8'hFE;
                d = mux_s_out[3:0];
            end
            3'b001: begin
                an = 8'hFD;
                d = mux_s_out[7:4];
            end
            3'b010: begin
                an = 8'hFB;
                d = mux_s_out[11:8];
            end
            3'b011: begin
                an = 8'hF7;
                d = mux_s_out[15:12];
            end
            3'b100: begin
                an = 8'hBF;
                d = a[3:0];
            end
            3'b101: begin
                an = 8'h7F;
                d = a[7:4];
            end
            default: begin
                an = 8'hFF;
            end
        endcase
    end
endmodule
