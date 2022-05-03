# Lab5 实验报告

[TOC]

## 1. 无数据和控制相关处理的流水线 CPU

### 1.1 逻辑设计

所有的流水线阶段都需要一个时钟周期，根据单周期 CPU 的数据通路设计，将其标识为不同的流水线阶段。将其划分成5个阶段，即五级流水线，分别为：

- IF 阶段：取指令
- ID：指令译码和读寄存器
- EX：执行或计算地址
- MEM：数据存储器访存
- WB：写回

为了使后续阶段能够继续执行第一个阶段所读取的指令，即让第一个阶段的指令能够被后面4个阶段所共享，需要把指令保存进一个寄存器进行存储。相应的，每个阶段都需要为后面阶段提供数据，因此需要使用流水线段寄存器。在每个时钟周期来临时，才会更新这些流水线段寄存器。因此在这里，只需要适当的对单周期 CPU 的设计稍作修改，便可以得到流水线 CPU 的实现。

#### 1.1.1 数据通路

根据课本以及 PPT 上基础版的数据通路，补充上 `jal` `jalr` `auipc` 等指令的数据通路，就是如下的数据通路：（其中省略了PC的两个数据选择器的选择信号）

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\data_path1.png"/>

### 1.2 核心代码

对单周期 CPU 的代码进行稍作修改，加上流水线段间寄存器的更新便可以得到：

```verilog
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

endmodule
```

### 1.3 测试文件以及仿真结果

#### 1.3.1 测试文件

将 lab3 中所有代码的后面增加三条 `nop` 指令，就可以实现类似停顿的操作，可以规避数据相关和控制相关：

```assembly
# <-- snip -->
.text
  # test sw
  sw x0, 0(x0)  # show 0x0000
  nop
  nop
  nop
  # test lw
  lw t0, 4(x0)
  nop
  nop
  nop
# <-- snip -->
```

#### 1.3.2 仿真结果

可以查看 `chk_data` 来模拟查看当前 LED 将会显示的数据，可以和预先设想的顺序进行对比。

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu1_sim1.png"/>

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu1_sim2.png"/>

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu1_sim3.png"/>

## 2. 仅有数据相关处理的流水线 CPU

### 2.1 逻辑设计

由于流水线 CPU 中的指令是一个一个周期进行的，对于大部分指令来说，当其进行到 EX 阶段时，其上一条指令还处于 MEM 阶段，即上一条指令还没有完全结束。这样就可能会导致一些意想不到的情况：读取不到正确的数据。

例如该例子：

```assembly
sub x2, x1, x3
and x12, x2, x5
```

当第一条指令还未结束时，即寄存器 x2 的值还未被写回到寄存器堆内时，这时候第二条指令已经读取了寄存器 x2 内的数据，但这个数据并不等于寄存器 x1 和寄存器 x3 内数据的差值，即读取了写入前的数据，很明显，这个并不是我们想要的结果，这时便发生了数据相关。每个流水线寄存器之间的相关关系会随着时间向前移动，因此可以通过前递在流水线寄存器中找到结果，使得其提前返回相应位置。相应的可以给出两种检测冒险的条件以及解决相应冒险的控制信号：

- EX 冒险

  对于 `auipc` 指令：

  ```verilog
  if (EX/MEM.IR == auipc && (EX/MEM.RegisterRd != 0) && (EX/MEM.RegisterRd == ID/EX.RegisterRs1))
      ForwardA = 11;
  if (EX/MEM.IR == auipc && (EX/MEM.RegisterRd != 0) && (EX/MEM.RegisterRd == ID/EX.RegisterRs2))
      ForwardB = 11;
  ```
	其它指令：

  ```verilog
  else if (EX/MEM.RegWrite && (EX/MEM.RegisterRd != 0) && (EX/MEM.RegisterRd == ID/EX.RegisterRs1)) 
      ForwardA = 10;
  else if (EX/MEM.RegWrite && (EX/MEM.RegisterRd != 0) && (EX/MEM.RegisterRd == ID/EX.RegisterRs2)) 
      ForwardB = 10;
  ```

- MEM 冒险

  ```verilog
  else if (MEM/WB.RegWrite && (MEM/WB.RegisterRd !=0 ) && (MEM/WB.RegisterRd == ID/EX.RegisterRs1))
      ForwardA = 01;
  else if (MEM/WB.RegWrite && (MEM/WB.RegisterRd !=0 ) && (MEM/WB.RegisterRd == ID/EX.RegisterRs2))
      ForwardB = 01;
  ```

上述冒险并不能解决其他类型的数据相关，例如 Load-Use Hazard。对于加载-使用冒险，需要先判断指令是否为加载指令，只有加载指令需要读取数据存储器，接下来检测在 EX 阶段的加载指令的目标寄存器是否与 ID 阶段的指令中的某一个源寄存器相匹配。如果条件成立，指令会停顿一个时钟周期，只需要简单地禁止 PC 寄存器和 IF/ID 流水线寄存器地改变就可以阻止这两条指令的执行，并且将控制信号全部改为0。

```verilog
if (ID/EX.MemRead && (ID/EX.RegisterRd == IF/ID.RegisterRs1) || (ID/EX.RegisterRd == IF/ID.RegisterRs2))
    stall the pipeline;
```

#### 2.1.1 数据通路

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\data_path2.png"/>

### 2.2 核心代码

#### 2.2.1 Forwarding Unit

```verilog
module FORWARD_UNIT(
    input [31:0] IRM,
    input [31:0] IRW,
    input [2:0] EX_MEM_WB,
    input [2:0] MEM_WB_WB,
    input [31:0] IRd,
    output reg [1:0] afwd,
    output reg [1:0] bfwd
);
    always@(*) begin
        
        if (IRM[6:0] == 7'b0010111 && IRM[11:7] != 5'b0 && IRM[11:7] == IRd[19:15])
            afwd = 2'b11;
        else if (EX_MEM_WB[0] && IRM[11:7] != 5'b0 && IRM[11:7] == IRd[19:15])
            afwd = 2'b10;
        else if (MEM_WB_WB[0] && IRW[11:7] != 5'b0 && IRW[11:7] == IRd[19:15])
            afwd = 2'b01;
        else
            afwd = 2'b00;

        if (IRM[6:0] == 7'b0010111 && IRM[11:7] != 5'b0 && IRM[11:7] == IRd[24:20])
            bfwd = 2'b11;
        else if (EX_MEM_WB[0] && IRM[11:7] != 5'b0 && IRM[11:7] == IRd[24:20])
            bfwd = 2'b10;
        else if (MEM_WB_WB[0] && IRW[11:7] != 5'b0 && IRW[11:7] == IRd[24:20])
            bfwd = 2'b01; 
        else
            bfwd = 2'b00;

    end
endmodule
```

#### 2.2.2 Hazard Unit

```verilog
module HAZARD_UNIT(
    input [31:0] IR,
    input [31:0] IRd,
    output reg ctrl,
    output reg PCWrite,
    output reg IF_ID_Write
);
    always@(*) begin
        if (IRd[6:0] == 7'b0000011 && (IRd[11:7] == IR[19:15] || IRd[11:7] == IR[24:20])) begin
            PCWrite = 1'b0;
            IF_ID_Write = 1'b0;
            ctrl = 1'b0;
        end
        else begin
            PCWrite = 1'b1;
            IF_ID_Write = 1'b1;
            ctrl = 1'b1;
        end
    end
endmodule
```

#### 2.2.3 CPU2

```verilog
module CPU2(
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
    wire ctrl, PCWrite, IF_ID_Write;

    
    
    reg [31:0] PCD, PCD_plus4, IR;
    always@(posedge clk or posedge rst) begin
        if (rst) begin
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
            if (PCWrite)
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

    // MEM
    Data_Memory DM(.a(Y[9:2]), .d(MDW), .dpra(chk_addr[7:0]), .clk(clk), .we(EX_MEM_M), .spo(read_data0), .dpo(read_data1));

    // WB   
    MUX4 MemtoRegMux(.sel0(YW), .sel1(MDR), .sel2(PCW_plus4), .sel3(PCW_auipc), .s(MEM_WB_WB[2:1]), .y(memtoreg_data));
    //MUX4 MemtoRegMux(.sel0(YW), .sel1(mem_io_data), .sel2(pc_plus4), .sel3(pc_auipc), .s(), .y(memtoreg_data));

    // Forwarding Unit
    FORWARD_UNIT forwading_unit(.IRM(IRM), .IRW(IRW), .EX_MEM_WB(EX_MEM_WB), .MEM_WB_WB(MEM_WB_WB), .IRd(IRd), .afwd(afwd), .bfwd(bfwd));
    
    // Hazard Unit
    HAZARD_UNIT hazard(.IR(IR), .IRd(IRd), .ctrl(ctrl), .PCWrite(PCWrite), .IF_ID_Write(IF_ID_Write));


endmodule
```

### 2.3 测试文件以及仿真结果

#### 2.3.1 测试文件

在这里只需要保留每一个分支指令后面的三条空指令 `nop` 即可。

```assembly
# <-- snip -->
  jal x1, TEST_JARL
  nop
  nop
  nop
  addi t0, x0, 0x0006
  sw t0, 0(x0)  # show 0x0006
  # test beq
  beq x0, x0, BEQ_IF
  nop
  nop
  nop
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
BEQ_IF:
  addi t0, x0, 0x0007
  sw t0, 0(x0)  # show 0x0007
  beq x0, t0, BEQ_ELSE
  nop
  nop
  nop
# <-- snip -->
```

#### 2.3.2 仿真结果

可以查看 `chk_data` 来模拟查看当前 LED 将会显示的数据，可以和预先设想的顺序进行对比。

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu2_sim1.png"/>

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu2_sim2.png"/>

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu2_sim3.png"/>

## 3. 完整的有数据和控制相关处理的流水线 CPU

### 3.1 逻辑设计

在流水线 CPU 中，需要等到 MEM 流水线按阶段才可以决定分支是否发生，因此如果不进行干预的话，在一个分支指令之后的三条指令都将会被取值并且开始执行。因此需要对其进行优化。可以采取假设分支不发生、缩短分支延迟、动态分支预测等方法来解决控制相关的问题。由于假设分支不发生比较简单，且无需添加额外的硬件支持，所以采用假设分支不发生的方法。

假设分支不发生只需要在分支发生时，将已经读取和译码的指令丢弃即可，丢弃指令，意味着将流水线中IF、ID阶段的指令都清除。

#### 3.1.1 数据通路

其中 `flush` 代表着分支发生：

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\data_path3.png"/>

### 3.2 核心代码

在这里只需要对上一个 CPU 代码稍作处理即可，详情可以看 **CPU3.v** 代码。

### 3.3 测试文件以及仿真结果

#### 3.3.1 测试文件

测试文件即为原始的 lab3 测试代码。详情可看附加代码。

#### 3.3.2 仿真结果

可以查看 `chk_data` 来模拟查看当前 LED 将会显示的数据，可以和预先设想的顺序进行对比。

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu3_sim1.png"/>

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu3_sim2.png"/>

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\cpu3_sim3.png"/>

### 3.4 CPU 与 PDU 整合

这个整合方式和单周期 CPU 中的整合方法是一样的，只需要注意一下对应的寄存器即可：

```verilog
// <-- snip -->	
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
            MDR <= mem_io_data;		// 修改了这里
            YW <= Y;
            IRW <= IRM;
        end
    end
// <-- snip -->

	assign chk_pc = PCD;
    assign io_addr = Y[7:0];
    assign io_dout = MDW;

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
// <-- snip -->
```

详情在 **CPU.v** 代码中。

### 3.5 排序程序测试

#### 3.5.1 测试代码

```assembly
.text
  addi x10, x0, 0
  addi x11, x0, 0x10
  jal x1, sort
  jal x1, output
  add x0, x0, x0    # breakpoint here
output:
  lw x5, 0x40(x0)  # x5 = 0xff00
  addi x5, x5, 0xc  # 0xff0c
  addi x6, x0, 0
loopshow:
  blt x6, x11, show_en
  jalr x0, 0(x1)
show_en:
  lw x7, 0x40(x0)  # x7 = 0xff00
  addi x7, x7, 8   # 0xff08
  lw x7, 0(x7)	   # get ready bit
  addi x31, x0, 1
  beq x31, x7, show_ready  # if ready bit = 1
  jal x0, show_en
show_ready:
  add x7, x6, x6
  add x7, x7, x6
  add x7, x7, x6   # offset shift left 2
  add x7, x7, x10  # add base address to get the number address
  lw x28, 0(x7)    # get sorting number
  sw x28, 0(x5)	   # output to the peripheral
  addi x6, x6, 1
  jal x0, loopshow
.data 0xf 0xe 0xd 0xc 0xb 0xa 0x9 0x8 0x7 0x6 0x5 0x4 0x3 0x2 0x1 0x0 0xff00
```

其中 `sort` 部分代码与之前编写的一样，完整代码在附件代码中。

#### 3.5.2 下载测试

首先将 `chk_addr` 设置为 `0xh2000` 查看内存的初始数据（下面 led 对应的就是当前 `chk_addr` ）：

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\seg0.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\seg1.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\seg2.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\seg3.png"  style="zoom:30%;" />

然后设置断点后开始排序，排序完之后，使用数码管将其排序结果输出：

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\sort0.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\sort1.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\sort2.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\sort3.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\sort4.png"  style="zoom:30%;" />

然后可以再次查看内存里的值，看看排序后数组是否正确有序地存储在内存当中（下面 led 对应的就是当前 `chk_addr` ）：

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\mem0.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\mem1.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\mem2.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\mem3.png"  style="zoom:30%;" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\mem4.png"  style="zoom:30%;" />

### 3.6 电路资源和时间性能

#### 3.6.1 RTL电路图

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\rtl.png" />

#### 3.6.2 综合电路

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\syn_rtl.png" />

#### 3.6.3 电路资源

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\utilization1.png" />

#### 3.6.4 电路性能

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\time_report2.png" />

<img src="C:\Users\蓝\Desktop\md文档\计组H图片\Lab5\time_report1.png" />

## 4. 实验总结

1. 从本次实验中，学习到了流水线 CPU 的设计方法，并且自主实现了一个流水线 CPU 的结构，同时添加上一些与课本不同的数据通路，进一步地理解了其中的工作原理，很好地与理论课所学知识相结合。通过在单周期 CPU 的设计基础上进行改动，也温故了单周期 CPU 的设计方法。同时在本次实验中也实现了数据相关和控制相关的处理方法，加深了对流水线 CPU 中指令运行方式的理解。
1. 在单周期 CPU 的设计基础上对流水线 CPU 进行设计改动比较简单，而且本次实验遇见问题较少，建议可以将本次实验时间缩短。
