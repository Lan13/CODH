`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/19 20:42:54
// Design Name: 
// Module Name: CPU1
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


module CPU1(
    input clk,
    input rst,

    output [7:0] io_addr,
    output [31:0] io_dout,
    output io_we,
    output io_rd,
    input [31:0] io_din,

    output [31:0] chk_pc,
    input [15:0] chk_addr,
    output [31:0] chk_data
);
    reg [31:0] PC, mem_io_data, chk_data_r;
    wire [31:0] inst, read_reg0, read_reg1, read_reg2, alumux_src, alu_result, read_data0, read_data1, memtoreg_data;
    wire [31:0] pc_plus4, pc_plusimm, imm_sext, pc_ret1, pc_ret2, pc_auipc;
    wire Jal, Jalr, Beq, Blt, MemWrite, ALUsrc, RegWrite, PCsrc;
    wire [1:0] MemtoReg;
    wire [2:0] ALUfun, zero;
    reg io_we_r, io_rd_r;

    
    
    reg [31:0] PCD, PCD_plus4, IR;
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            PCD <= 32'b0;
            PCD_plus4 <= 32'b0;
            IR <= 32'b0;
        end
        else begin
            PCD <= PC;
            PCD_plus4 <= pc_plus4;
            IR <= inst;
        end
    end

    reg [31:0] PCE, PCE_plus4, A, B, Imm, IRd;
    reg [7:0] ID_EX_EX;
    reg ID_EX_M;
    reg [2:0] ID_EX_WB;
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            PCE <= 32'b0;
            PCE_plus4 <= 32'b0;
            A <= 32'b0;
            B <= 32'b0;
            Imm <= 32'b0;
            IRd <= 32'b0;
            ID_EX_EX <= 8'b0;
            ID_EX_M <= 1'b0;
            ID_EX_WB <= 3'b0;
        end
        else begin
            PCE <= PCD;
            PCE_plus4 <= PCD_plus4;
            A <= read_reg0;
            B <= read_reg1;
            Imm <= imm_sext;
            IRd <= IR;
            ID_EX_EX <= {Jal, Jalr, Beq, Blt, ALUfun, ALUsrc};
            ID_EX_M <= MemWrite;
            ID_EX_WB <= {MemtoReg, RegWrite};
        end
    end

    reg EX_MEM_M;
    reg [2:0] EX_MEM_WB;
    reg [31:0] Y, MDW, PCM_plus4, PCM_auipc, IRM;
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            PCM_plus4 <= 32'b0;
            PCM_auipc <= 32'b0;
            EX_MEM_M <= 1'b0;
            EX_MEM_WB <= 3'b0;
            Y <= 32'b0;
            MDW <= 32'b0;
            IRM <= 32'b0;
        end
        else begin
            PCM_plus4 <= PCE_plus4;
            PCM_auipc <= pc_auipc;
            EX_MEM_M <= ID_EX_M;
            EX_MEM_WB <= ID_EX_WB;
            Y <= alu_result;
            MDW <= B;
            IRM <= IRd;
        end
    end

    reg [2:0] MEM_WB_WB;
    reg [31:0] MDR, YW, PCW_plus4, PCW_auipc, IRW;
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            PCW_plus4 <= 32'b0;
            PCW_auipc <= 32'b0;
            MEM_WB_WB <= 3'b0;
            MDR <= 32'b0;
            YW <= 32'b0;
            IRW <= 32'b0;
        end
        else begin
            PCW_plus4 <= PCM_plus4;
            PCW_auipc <= PCM_auipc;
            MEM_WB_WB <= EX_MEM_WB;
            MDR <= read_data0;
            YW <= Y;
            IRW <= IRM;
        end
    end

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 32'b0;
        end
        else begin
            PC <= pc_ret2;
        end
    end

    assign chk_pc = PC;

    // IF
    Instruction_Memory IM(.a(PC[9:2]), .d(32'b0), .clk(clk), .we(1'b0), .spo(inst));
    ALU PC4(.a(PC), .b(32'h4), .s(3'b001), .y(pc_plus4), .f());

    // ID
    CONTROL Control(.inst(IR), .Jal(Jal), .Jalr(Jalr), .Beq(Beq), .Blt(Blt), .MemtoReg(MemtoReg), .ALUfun(ALUfun), .MemWrite(MemWrite), .ALUsrc(ALUsrc), .RegWrite(RegWrite));
    REG_FILE3 Register(.clk(clk), .ra0(IR[19:15]), .ra1(IR[24:20]), .ra2(chk_addr[4:0]), .wa(IRW[11:7]), .wd(memtoreg_data), .we(MEM_WB_WB[0]), .rd0(read_reg0), .rd1(read_reg1), .rd2(read_reg2));
    IMM_GEN_CONTROL IMM_sext(.inst(IR), .imm_sext(imm_sext));

    // EX
    MUX2 ALUsrcMUX(.sel0(B), .sel1(Imm), .s(ID_EX_EX[0]), .y(alumux_src));
    ALU PCImm(.a(PCE), .b({Imm[30:0], 1'b0}), .s(3'b001), .y(pc_plusimm), .f());
    ALU AUIPC(.a(PCE), .b(Imm), .s(3'b001), .y(pc_auipc), .f());
    ALU mainALU(.a(A), .b(alumux_src), .s(ID_EX_EX[3:1]), .y(alu_result), .f(zero));
    MUX2 PCMux1(.sel0(pc_plus4), .sel1(pc_plusimm), .s(PCsrc), .y(pc_ret1));
    MUX2 PCMux2(.sel0(pc_ret1), .sel1(alu_result & ~1), .s(ID_EX_EX[6]), .y(pc_ret2));
    assign PCsrc =  (ID_EX_EX[5] & zero[0])| (ID_EX_EX[4] & zero[1]) | ID_EX_EX[7];

    // MEM
    Data_Memory DM(.a(Y[9:2]), .d(MDW), .dpra(chk_addr[7:0]), .clk(clk), .we(EX_MEM_M), .spo(read_data0), .dpo(read_data1));

    // WB   
    MUX4 MemtoRegMux(.sel0(YW), .sel1(MDR), .sel2(PCW_plus4), .sel3(PCW_auipc), .s(MEM_WB_WB[2:1]), .y(memtoreg_data));
    //MUX4 MemtoRegMux(.sel0(YW), .sel1(mem_io_data), .sel2(pc_plus4), .sel3(pc_auipc), .s(), .y(memtoreg_data));


endmodule
