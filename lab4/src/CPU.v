`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/07 20:46:35
// Design Name: 
// Module Name: CPU
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


module CPU(
    input clk,
    input rst,

    output [7:0] io_addr,
    output [31:0] io_dout,
    output io_we,
    output io_rd,
    input [31:0] io_din,

    output [31:0] pc,
    input [15:0] chk_addr,
    output [31:0] chk_data
);
    reg [31:0] PC, mem_io_data, chk_data_r;
    wire [31:0] inst, read_reg0, read_reg1, read_reg2, alumux_src, alu_result, read_data0, read_data1, memtoreg_data;
    wire [31:0] pc_plus4, pc_plusimm, imm_sext, pc_ret1, pc_ret2, pc_auipc;
    wire Jal, Jalr, Beq, Blt, MemWrite, ALUsrc, RegWrite, PCsrc;
    wire [1:0] MemtoReg, ALUop;
    wire [2:0] alu_fun, zero;
    reg io_we_r, io_rd_r;

    assign PCsrc =  (Beq & zero[0])| (Blt & zero[1]) | Jal;

    wire [31:0] dpo;
    Instruction_Memory IM(.a(PC[9:2]), .d(32'b0), .dpra(8'b0), .clk(clk), .we(1'b0), .spo(inst), .dpo(dpo));
    CONTROL Control(.inst(inst), .Jal(Jal), .Jalr(Jalr), .Beq(Beq), .Blt(Blt), .MemtoReg(MemtoReg), .ALUop(ALUop), .MemWrite(MemWrite), .ALUsrc(ALUsrc), .RegWrite(RegWrite));
    REG_FILE3 Register(.clk(clk), .ra0(inst[19:15]), .ra1(inst[24:20]), .ra2(chk_addr[4:0]), .wa(inst[11:7]), .wd(memtoreg_data), .we(RegWrite), .rd0(read_reg0), .rd1(read_reg1), .rd2(read_reg2));
    IMM_GEN_CONTROL IMM_sext(.inst(inst), .imm_sext(imm_sext));
    MUX2 ALUsrcMUX(.sel0(read_reg1), .sel1(imm_sext), .s(ALUsrc), .y(alumux_src));
    ALU_CONTROL ALU_control(.funct7(inst[31:25]), .funct3(inst[14:12]), .ALUop(ALUop), .alu_fun(alu_fun));
    ALU PC4(.a(PC), .b(32'h4), .s(3'b001), .y(pc_plus4), .f());
    ALU PCImm(.a(PC), .b({imm_sext[30:0], 1'b0}), .s(3'b001), .y(pc_plusimm), .f());
    ALU AUIPC(.a(PC), .b(imm_sext), .s(3'b001), .y(pc_auipc), .f());
    ALU mainALU(.a(read_reg0), .b(alumux_src), .s(alu_fun), .y(alu_result), .f(zero));
    Data_Memory DM(.a(alu_result[9:2]), .d(read_reg1), .dpra(chk_addr[7:0]), .clk(clk), .we(MemWrite), .spo(read_data0), .dpo(read_data1));
    //MUX4 MemtoRegMux(.sel0(alu_result), .sel1(read_data0), .sel2(pc_plus4), .sel3(pc_auipc), .s(MemtoReg), .y(memtoreg_data));
    MUX4 MemtoRegMux(.sel0(alu_result), .sel1(mem_io_data), .sel2(pc_plus4), .sel3(pc_auipc), .s(MemtoReg), .y(memtoreg_data));
    MUX2 PCMux1(.sel0(pc_plus4), .sel1(pc_plusimm), .s(PCsrc), .y(pc_ret1));
    MUX2 PCMux2(.sel0(pc_ret1), .sel1(alu_result & ~1), .s(Jalr), .y(pc_ret2));
    
    
    always@(posedge clk or posedge rst) begin
        if (rst)
            PC <= 32'b0;
        else
            PC <= pc_ret2;
    end
    
    assign pc = PC;
    assign io_addr = alu_result[7:0];
    assign io_dout = read_reg1;

    always@(*) begin
        case(chk_addr[15:12])
            4'h0: begin
                case(chk_addr[3:0])
                    4'h0: chk_data_r = pc_ret2;
                    4'h1: chk_data_r = pc;
                    4'h2: chk_data_r = inst;
                    4'h3: chk_data_r = {21'b0, Jal, Jalr, Beq, Blt, MemtoReg, ALUop, MemWrite, ALUsrc, RegWrite};
                    4'h4: chk_data_r = read_reg0;
                    4'h5: chk_data_r = read_reg1;
                    4'h6: chk_data_r = imm_sext;
                    4'h7: chk_data_r = alu_result;
                    4'h8: chk_data_r = read_data0;
                    default: chk_data_r = 32'b0;
                endcase
            end
            4'h1: begin
                chk_data_r = read_reg2;
            end
            4'h2: begin
                chk_data_r = read_data1;
            end
            default: begin
                chk_data_r = 32'b0;
            end
        endcase
    end
    assign chk_data = chk_data_r;

    always@(*) begin
        case(alu_result[15:8])
            8'hff: begin
                case(alu_result[7:0])
                    8'h04: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (inst[6:0] == 7'b0000011);
                    end
                    8'h08: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (inst[6:0] == 7'b0000011);
                    end
                    8'h10: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (inst[6:0] == 7'b0000011);
                    end
                    8'h14: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (inst[6:0] == 7'b0000011);
                    end
                    8'h18: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (inst[6:0] == 7'b0000011);
                    end
                    default: begin
                        mem_io_data = read_data0;
                        io_we_r = MemWrite;
                        io_rd_r = 0;
                    end
                endcase
            end
            default: begin
                mem_io_data = read_data0;
                io_we_r = MemWrite;     // test
                io_rd_r = 0;
            end
        endcase
    end
    assign io_we = io_we_r;
    assign io_rd = io_rd_r;
endmodule
