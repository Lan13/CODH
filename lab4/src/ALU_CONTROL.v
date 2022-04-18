`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/07 22:44:10
// Design Name: 
// Module Name: ALU_CONTROL
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


module ALU_CONTROL(
    input [6:0] funct7,
    input [2:0] funct3,
    input [1:0] ALUop,
    output reg [2:0] alu_fun
);
    always@(*) begin
        case(ALUop)
            2'b00: begin    //lw, addi, sw, jal, jalr, auipc
                alu_fun = 3'b001;
            end
            2'b01: begin    //beq, blt
                alu_fun = 3'b000;
            end
            2'b10: begin    //add, sub
                case(funct7)
                    7'b0000000: begin   //add
                        alu_fun = 3'b001;
                    end
                    7'b0100000: begin   //sub
                        alu_fun = 3'b000;
                    end
                endcase
            end
            2'b11: begin
                alu_fun = 3'b000; 
            end
        endcase
    end
endmodule
