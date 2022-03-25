`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/18 19:05:28
// Design Name: 
// Module Name: top
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


module ALU #(parameter WIDTH = 32)(
    input [WIDTH-1:0] a, b,
    input [2:0] s,
    output [WIDTH-1:0] y,
    output [2:0] f
    );
    reg [WIDTH-1:0] alu_y;
    reg [2:0] alu_f;
    always @(*) 
    begin
        alu_f = 3'b000;
        case(s)
            3'b000: begin
                alu_y = a - b;
                if (WIDTH == 1) begin
                    if (a > b)
                        alu_f = 3'b010;
                    else if (a == b)
                        alu_f = 3'b001;
                    else
                        alu_f = 3'b100;
                end
                else begin
                    case({a[WIDTH-1], b[WIDTH-1]})
                        2'b00: begin
                            if (a[WIDTH-2:0] < b[WIDTH-2:0])
                                alu_f = 3'b110;
                            else if (a[WIDTH-2:0] == b[WIDTH-2:0])
                                alu_f = 3'b001;
                            else
                                alu_f = 3'b000;
                        end
                        2'b01: begin
                            alu_f = 3'b100;
                        end
                        2'b10: begin
                            alu_f = 3'b010;
                        end
                        2'b11: begin
                            if (a[WIDTH-2:0] < b[WIDTH-2:0])
                                alu_f = 3'b100;
                            else if (a[WIDTH-2:0] == b[WIDTH-2:0])
                                alu_f = 3'b001;
                            else
                                alu_f = 3'b010;
                        end
                    endcase
                end
            end
            3'b001: begin
                alu_y = a + b;
            end
            3'b010: begin
                alu_y = a & b;
            end
            3'b011: begin
                alu_y = a | b;
            end
            3'b100: begin
                alu_y = a ^ b;
            end
            3'b101: begin
                alu_y = a >> b;
            end
            3'b110: begin
                alu_y = a << b;
            end
            3'b111: begin
                alu_y = a >>> b;
            end
        endcase
    end
    assign y = alu_y;
    assign f = alu_f;
endmodule
