`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/08 13:52:41
// Design Name: 
// Module Name: IMM_GEN_CONTROL
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


module IMM_GEN_CONTROL(
    input [31:0] inst,
    output reg [31:0] imm_sext
);
    always@(*) begin
        case(inst[6:0])
            7'b0110011: begin   //add, sub
                imm_sext = inst;
            end
            7'b0010111: begin   //auipc
                imm_sext = {inst[31:12], 12'b0};
            end
            7'b0000011: begin   //lw
                imm_sext = {{20{inst[31]}}, inst[31:20]};
            end
            7'b0010011: begin   //addi
                imm_sext = {{20{inst[31]}}, inst[31:20]};
            end
            7'b0100011: begin   //sw
                imm_sext = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end
            7'b1101111: begin   //jal
                imm_sext = {{12{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21]};
            end
            7'b1100111: begin   //jalr
                imm_sext = {{20{inst[31]}}, inst[31:20]};
            end
            7'b1100011: begin   //beq, blt
                imm_sext = {{20{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8]};
            end
            default: begin
                imm_sext = inst;
            end
        endcase
    end
endmodule
