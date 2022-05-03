`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/24 11:10:44
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
    wire [1:0] afwd, bfwd;
    wire [31:0] afwd_data, bfwd_data;
    wire ctrl, PCWrite, IF_ID_Write, branch_flush;
    reg io_we_r, io_rd_r;
    
    // IF
    reg [31:0] PCD, PCD_plus4, IR;
    always@(posedge clk or posedge rst) begin
        if (rst || branch_flush) begin
            PCD <= 32'b0;
            PCD_plus4 <= 32'b0;
            IR <= 32'b0;
        end
        else begin
            if (IF_ID_Write) begin
                PCD <= PC;
                PCD_plus4 <= pc_plus4;
                IR <= inst;
            end
        end
    end

    // ID
    reg [31:0] PCE, PCE_plus4, A, B, Imm, IRd;
    reg [7:0] ID_EX_EX;
    reg ID_EX_M;
    reg [2:0] ID_EX_WB;
    always@(posedge clk or posedge rst) begin
        if (rst || branch_flush) begin
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
            if (ctrl) begin
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
            else begin
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
        end
    end

    // EX
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
            MDW <= bfwd_data;
            IRM <= IRd;
        end
    end

    // MEM
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
//            MDR <= read_data0;
            MDR <= mem_io_data;
            YW <= Y;
            IRW <= IRM;
        end
    end

    // WB
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 32'b0;
        end
        else begin
            if (PCWrite)
                PC <= pc_ret2;
        end
    end

    assign chk_pc = PCD;
    assign io_addr = Y[7:0];
    assign io_dout = MDW;

    // IF
    Instruction_Memory IM(.a(PC[9:2]), .d(32'b0), .clk(clk), .we(1'b0), .spo(inst));
    ALU PC4(.a(PC), .b(32'h4), .s(3'b001), .y(pc_plus4), .f());

    // ID
    CONTROL Control(.inst(IR), .Jal(Jal), .Jalr(Jalr), .Beq(Beq), .Blt(Blt), .MemtoReg(MemtoReg), .ALUfun(ALUfun), .MemWrite(MemWrite), .ALUsrc(ALUsrc), .RegWrite(RegWrite));
    REG_FILE3 Register(.clk(clk), .ra0(IR[19:15]), .ra1(IR[24:20]), .ra2(chk_addr[4:0]), .wa(IRW[11:7]), .wd(memtoreg_data), .we(MEM_WB_WB[0]), .rd0(read_reg0), .rd1(read_reg1), .rd2(read_reg2));
    IMM_GEN_CONTROL IMM_sext(.inst(IR), .imm_sext(imm_sext));

    // EX
    MUX4 Afwd(.sel0(A), .sel1(memtoreg_data), .sel2(Y), .sel3(PCM_auipc), .s(afwd), .y(afwd_data));
    MUX4 Bfwd(.sel0(B), .sel1(memtoreg_data), .sel2(Y), .sel3(PCM_auipc), .s(bfwd), .y(bfwd_data));
    //MUX2 ALUsrcMUX(.sel0(B), .sel1(Imm), .s(ID_EX_EX[0]), .y(alumux_src));
    MUX2 ALUsrcMUX(.sel0(bfwd_data), .sel1(Imm), .s(ID_EX_EX[0]), .y(alumux_src));
    ALU PCImm(.a(PCE), .b({Imm[30:0], 1'b0}), .s(3'b001), .y(pc_plusimm), .f());
    ALU AUIPC(.a(PCE), .b(Imm), .s(3'b001), .y(pc_auipc), .f());
    ALU mainALU(.a(afwd_data), .b(alumux_src), .s(ID_EX_EX[3:1]), .y(alu_result), .f(zero));
    MUX2 PCMux1(.sel0(pc_plus4), .sel1(pc_plusimm), .s(PCsrc), .y(pc_ret1));
    MUX2 PCMux2(.sel0(pc_ret1), .sel1(alu_result & ~1), .s(ID_EX_EX[6]), .y(pc_ret2));
    assign PCsrc =  (ID_EX_EX[5] & zero[0])| (ID_EX_EX[4] & zero[1]) | ID_EX_EX[7];
    assign branch_flush = PCsrc | ID_EX_EX[6];   // beq or blt or jal or jalr

    // MEM
    Data_Memory DM(.a(Y[9:2]), .d(MDW), .dpra(chk_addr[7:0]), .clk(clk), .we(EX_MEM_M), .spo(read_data0), .dpo(read_data1));

    // WB   
    MUX4 MemtoRegMux(.sel0(YW), .sel1(MDR), .sel2(PCW_plus4), .sel3(PCW_auipc), .s(MEM_WB_WB[2:1]), .y(memtoreg_data));
    //MUX4 MemtoRegMux(.sel0(YW), .sel1(mem_io_data), .sel2(pc_plus4), .sel3(pc_auipc), .s(), .y(memtoreg_data));

    // Forwarding Unit
    FORWARD_UNIT forwading_unit(.IRM(IRM), .IRW(IRW), .EX_MEM_WB(EX_MEM_WB), .MEM_WB_WB(MEM_WB_WB), .IRd(IRd), .afwd(afwd), .bfwd(bfwd));
    
    // Hazard Unit
    HAZARD_UNIT hazard(.IR(IR), .IRd(IRd), .ctrl(ctrl), .PCWrite(PCWrite), .IF_ID_Write(IF_ID_Write));


    always@(*) begin
        case(chk_addr[15:12])
            4'h0: begin
                case(chk_addr[7:0])
                    8'h0: chk_data_r = pc_ret2;
                    8'h1: chk_data_r = PC;
                    8'h2: chk_data_r = PCD;
                    8'h3: chk_data_r = IR;
                    8'h4: chk_data_r = {20'b0, ID_EX_EX, ID_EX_M, ID_EX_WB};
                    8'h5: chk_data_r = PCE;
                    8'h6: chk_data_r = A;
                    8'h7: chk_data_r = B;
                    8'h8: chk_data_r = Imm;
                    8'h9: chk_data_r = IRd;
                    8'ha: chk_data_r = {28'b0, EX_MEM_M, EX_MEM_WB};
                    8'hb: chk_data_r = Y;
                    8'hc: chk_data_r = MDW;
                    8'hd: chk_data_r = IRM;
                    8'he: chk_data_r = {29'b0, MEM_WB_WB};
                    8'hf: chk_data_r = MDR;
                    8'h10: chk_data_r = YW;
                    8'h11: chk_data_r = IRW;
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
        case(Y[15:8])
            8'hff: begin
                case(Y[7:0])
                    8'h04: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (IRM[6:0] == 7'b0000011);
                    end
                    8'h08: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (IRM[6:0] == 7'b0000011);
                    end
                    8'h10: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (IRM[6:0] == 7'b0000011);
                    end
                    8'h14: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (IRM[6:0] == 7'b0000011);
                    end
                    8'h18: begin
                        mem_io_data = io_din;
                        io_we_r = 0;
                        io_rd_r = (IRM[6:0] == 7'b0000011);
                    end
                    default: begin
                        mem_io_data = read_data0;
                        io_we_r = EX_MEM_M;
                        io_rd_r = 0;
                    end
                endcase
            end
            default: begin
                mem_io_data = read_data0;
                io_we_r = EX_MEM_M;     // test
                io_rd_r = 0;
            end
        endcase
    end
    assign io_we = io_we_r;
    assign io_rd = io_rd_r;

    
endmodule
