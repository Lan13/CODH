`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/07 21:21:23
// Design Name: 
// Module Name: CONTROL
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


module CONTROL(
    input [31:0] inst,
    output reg Jal,
    output reg Jalr,
    output reg Beq,
    output reg Blt,
    output reg [1:0] MemtoReg,
    output reg [1:0] ALUop,
    output reg MemWrite,
    output reg ALUsrc,
    output reg RegWrite
);
    always@(*) begin
        case(inst[6:0])
            7'b0110011: begin   // add, sub
                Jal = 1'b0;
                Jalr = 1'b0;
                Beq = 1'b0;
                Blt = 1'b0;
                MemtoReg = 2'b00;
                ALUop = 2'b10;
                MemWrite = 1'b0;
                ALUsrc = 1'b0;
                RegWrite = 1'b1;
            end
            7'b0000011: begin   // lw
                Jal = 1'b0;
                Jalr = 1'b0;
                Beq = 1'b0;
                Blt = 1'b0;
                MemtoReg = 2'b01;
                ALUop = 2'b00;
                MemWrite = 1'b0;
                ALUsrc = 1'b1;
                RegWrite = 1'b1;
            end
            7'b0010011: begin   // addi
                Jal = 1'b0;
                Jalr = 1'b0;
                Beq = 1'b0;
                Blt = 1'b0;
                MemtoReg = 2'b00;
                ALUop = 2'b00;
                MemWrite = 1'b0;
                ALUsrc = 1'b1;
                RegWrite = 1'b1;
            end
            7'b0100011: begin   // sw
                Jal = 1'b0;
                Jalr = 1'b0;
                Beq = 1'b0;
                Blt = 1'b0;
                MemtoReg = 2'b00;
                ALUop = 2'b00;
                MemWrite = 1'b1;
                ALUsrc = 1'b1;
                RegWrite = 1'b0;
            end
            7'b1101111: begin   // jal
                Jal = 1'b1;
                Jalr = 1'b0;
                Beq = 1'b0;
                Blt = 1'b0;
                MemtoReg = 2'b10;
                ALUop = 2'b00;
                MemWrite = 1'b0;
                ALUsrc = 1'b0;
                RegWrite = 1'b1;
            end
            7'b1100111: begin   // jalr
                Jal = 1'b1;
                Jalr = 1'b1;
                Beq = 1'b0;
                Blt = 1'b0;
                MemtoReg = 2'b10;
                ALUop = 2'b00;
                MemWrite = 1'b0;
                ALUsrc = 1'b1;
                RegWrite = 1'b1;
            end
            7'b1100011: begin   // beq, blt
                Jal = 1'b0;
                Jalr = 1'b0;
                case(inst[14:12])
                    3'b000: begin   //beq
                        Beq = 1'b1;
                        Blt = 1'b0;
                    end             //blt
                    3'b100: begin
                        Beq = 1'b0;
                        Blt = 1'b1;
                    end
                endcase
                MemtoReg = 2'b00;
                ALUop = 2'b01;
                MemWrite = 1'b0;
                ALUsrc = 1'b0;
                RegWrite = 1'b0;
            end
            7'b0010111: begin   // auipc
                Jal = 1'b0;
                Jalr = 1'b0;
                Beq = 1'b0;
                Blt = 1'b0;
                MemtoReg = 2'b11;
                ALUop = 2'b00;
                MemWrite = 1'b0;
                ALUsrc = 1'b1;
                RegWrite = 1'b1;
            end
            default : begin
                Jal = 1'b0;
                Jalr = 1'b0;
                Beq = 1'b0;
                Blt = 1'b0;
                MemtoReg = 2'b00;
                ALUop = 2'b00;
                MemWrite = 1'b0;
                ALUsrc = 1'b0;
                RegWrite = 1'b0;
            end
        endcase
    end
endmodule
