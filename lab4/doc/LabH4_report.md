# Lab4 实验报告

[TOC]

## 1. 设计单周期 CPU

### 1.1 逻辑设计

RISC-V 实现中的数据通路包含两种不同类型的逻辑单元：处理数据值的单元和存储状态的单元。处理数据值的单元是组合逻辑，而处理存储状元的是时序逻辑。在单周期 CPU 的设计中，只有程序计数器寄存器、寄存器堆和数据存储单元是存储单元，而其他控制信号的单元都是组合逻辑实现的。然后根据我们所要实现的 10 条指令：`sw, lw, add, addi, sub, jal, jalr, beq, blt, auipc ` 的功能，设计一个简单的数据通路。

|        指令格式        |                        功能                        |
| :--------------------: | :------------------------------------------------: |
| `lw, rd, offset(rs1)`  |          x[rd] = M[x[rs1] + sext(offset)]          |
| `sw rs2, offset(rs1)`  |         M[x[rs1] + sext(offset)] = x[rs2]          |
|   `add rd, rs1, rs2`   |              x[rd] = x[rs1] + x[rs2]               |
|  `addi rd, rs1, imm`   |             x[rd] = x[rs1] + sext(imm)             |
|   `sub rd, rs1, rs2`   |              x[rd] = x[rs1] - x[rs2]               |
| `beq rs1, rs2, offset` |      if(x[rs1] == x[rs2]) pc += sext(offset)       |
| `blt rs1, rs2, offset` |       if(x[rs1] < x[rs2]) pc += sext(offset)       |
|    `jal rd, offset`    |         x[rd] = pc + 4, pc += sext(offset)         |
| `jalr rd, offset(rs1)` | x [rd] = pc + 4, pc = (x[rs1] + sext(pffset)) & ~1 |
|    `auipc rd, imm`     |        x[rd] = pc + sext(imm[31:12] << 12)         |

#### 1.1.1 数据通路

大致上的数据通路设计如下，具体实现细节还需要做一些改进：

<img src="..\images\data_path1.png"/>

#### 1.1.2 功能部件

- ALU / ADD：数据运算的主要部件，用来实现不同指令的运算操作。对于 ADD 部件，只需要进行加法，对与 PC 有关的跳转量进行计算，得到下一个 PC 的值。
- Control：主要根据指令的操作码 `instruction[6:0]` 来确定不同指令的主要控制信号：`Jal, Jalr, Beq, Blt, MemtoReg, ALUop, MemWrite, ALUsrc, RegWrite`。每一个指令对应的控制信号不同，其中有一些控制信号也可能对其没有影响，原因是在数据通路中，数据不需要经过该控制信号控制的功能部件或者选择器。
- Imm Gen Control：该功能部件根据指令的操作码，将指令中的立即数进行符号拓展，不同指令的拓展方式可能不同。
- ALU Control：根据指令的操作码，`funct3` 和 `funct7`  来确定 ALU中进行何种算术运算，实际上，绝大数指令使用的都是加法运算。

### 1.2 核心代码

#### 1.2.1 Control

```verilog
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
```

#### 1.2.2 Imm Gen Control

```verilog
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
```

#### 1.2.3 ALU Control

```verilog
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
```

#### 1.2.4 CPU

这个是尚未增加调试总线和数据总线的 CPU 设计：

```verilog
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
    REG_FILE3 Register(.clk(clk), .ra0(inst[19:15]), .ra1(inst[24:20]), .ra2(), .wa(inst[11:7]), .wd(memtoreg_data), .we(RegWrite), .rd0(read_reg0), .rd1(read_reg1), .rd2(read_reg2));
    IMM_GEN_CONTROL IMM_sext(.inst(inst), .imm_sext(imm_sext));
    MUX2 ALUsrcMUX(.sel0(read_reg1), .sel1(imm_sext), .s(ALUsrc), .y(alumux_src));
    ALU_CONTROL ALU_control(.funct7(inst[31:25]), .funct3(inst[14:12]), .ALUop(ALUop), .alu_fun(alu_fun));
    ALU PC4(.a(PC), .b(32'h4), .s(3'b001), .y(pc_plus4), .f());
    ALU PCImm(.a(PC), .b({imm_sext[30:0], 1'b0}), .s(3'b001), .y(pc_plusimm), .f());
    ALU AUIPC(.a(PC), .b(imm_sext), .s(3'b001), .y(pc_auipc), .f());
    ALU mainALU(.a(read_reg0), .b(alumux_src), .s(alu_fun), .y(alu_result), .f(zero));
    Data_Memory DM(.a(alu_result[9:2]), .d(read_reg1), .dpra(), .clk(clk), .we(MemWrite), .spo(read_data0), .dpo(read_data1));
    MUX4 MemtoRegMux(.sel0(alu_result), .sel1(read_data0), .sel2(pc_plus4), .sel3(pc_auipc), .s(MemtoReg), .y(memtoreg_data));
    MUX2 PCMux1(.sel0(pc_plus4), .sel1(pc_plusimm), .s(PCsrc), .y(pc_ret1));
    MUX2 PCMux2(.sel0(pc_ret1), .sel1(alu_result & ~1), .s(Jalr), .y(pc_ret2));
    
    always@(posedge clk or posedge rst) begin
        if (rst)
            PC <= 32'b0;
        else
            PC <= pc_ret2;
    end
    
    assign pc = PC;

endmodule
```

### 1.3 CPU 与 PDU 整合

#### 1.3.1 数据通路

具体实现细节还需要做一些改进：（**注：从 DM 中读出来的数据还需要经过一个选择器**）

<img src="..\images\data_path2.png"/>

#### 1.3.2 核心代码

将 I/O 总线以及 debug 总线添加到 CPU 的数据通路中，将相应的代码中添加以下相关代码，并且将其连接到有关单元的端口：

```verilog
// < -- snip -- >
REG_FILE3 Register(.clk(clk), .ra0(inst[19:15]), .ra1(inst[24:20]), .ra2(chk_addr[4:0]), .wa(inst[11:7]), .wd(memtoreg_data), .we(RegWrite), .rd0(read_reg0), .rd1(read_reg1), .rd2(read_reg2));
Data_Memory DM(.a(alu_result[9:2]), .d(read_reg1), .dpra(chk_addr[7:0]), .clk(clk), .we(MemWrite), .spo(read_data0), .dpo(read_data1));
MUX4 MemtoRegMux(.sel0(alu_result), .sel1(mem_io_data), .sel2(pc_plus4), .sel3(pc_auipc), .s(MemtoReg), .y(memtoreg_data));
// < -- snip -- >	
reg [31:0] mem_io_data, chk_data_r;
reg io_we_r, io_rd_r;
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
```

## 2. 逐条指令功能测试

### 2.1 测试代码

测试代码沿用 lab3 中的测试方案：

```assembly
.data
  led_data: .word 0xffff
  swt_data: .word 0x0001
.text
  # test sw
  sw x0, 0(x0)  # show 0x0000
  # test lw
  lw t0, 4(x0)
  sw t0, 0(x0)  # show 0x0001
  # test add
  add t0, t0, t0
  sw t0, 0(x0)  # show 0x0002
  # test addi
  addi t0, x0, 0x0003
  sw t0, 0(x0)  # show 0x0003
  # test sub
  addi t0, x0, 0x5
  addi t1, x0, 0x1
  sub t0, t0, t1
  sw t0, 0(x0)  # show 0x0004
  # test jal
  jal x1, TEST_JARL
  addi t0, x0, 0x0006
  sw t0, 0(x0)  # show 0x0006
  # test beq
  beq x0, x0, BEQ_IF
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
BEQ_IF:
  addi t0, x0, 0x0007
  sw t0, 0(x0)  # show 0x0007
  beq x0, t0, BEQ_ELSE
  addi t0, x0, 0x0008
  sw t0, 0(x0)  # show 0x0008
  jal x0, NEXT
BEQ_ELSE:
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
NEXT:
  # test blt
  addi t0, x0, 0x1
  addi t1, x0, 0x2
  blt t0, t1, BLT_IF
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
BLT_IF:
  addi t0, x0, 0x0009
  sw t0, 0(x0)  # show 0x0009
  blt t0, t1, BLT_ELSE
  addi t0, x0, 0x000a
  sw t0, 0(x0)  # show 0x000a
  jal x0, NEXT2
BLT_ELSE:
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
NEXT2:
  # test auipc
  auipc t0, 1
  sw t0, 0(x0)  # show 0x1098
  sw x0, 0(x0)  # show 0x0000, BreakPoint at this line
  
TEST_JARL:
  addi t0, x0, 0x0005
  sw t0, 0(x0)  # show 0x0005
  # test jalr
  jalr x0, 0(x1)
```

### 2.2 仿真结果和下载测试

#### 2.2.1 仿真结果

可以查看 `chk_data` 来模拟查看当前 LED 将会显示的数据，可以和预先设想的顺序进行对比。

<img src="..\images\test_1.png"/>

<img src="..\images\test_2.png"/><img src="..\images\test_3.png"/>

#### 2.2.2 下载测试

先将 `chk_addr` 设置为 `0xh0001` ，以便查看当前 `PC` 地址，然后按 `step` 按钮，观察 led 的变化：

<img src="..\images\led0.png" style="zoom:50%;" />

<img src="..\images\led1.png" style="zoom:50%;" />

<img src="..\images\led2.png" style="zoom:50%;" />

<img src="..\images\led3.png" style="zoom:50%;" />

<img src="..\images\led4.png" style="zoom:50%;" />

<img src="..\images\led5.png" style="zoom:50%;" />

<img src="..\images\led6.png" style="zoom:50%;" />

<img src="..\images\led7.png" style="zoom:50%;" />

<img src="..\images\led8.png" style="zoom:50%;" />

<img src="..\images\led9.png" style="zoom:50%;" />

<img src="..\images\led10.png" style="zoom:50%;" />

<img src="..\images\led11.png" style="zoom:50%;" />

## 3. 排序程序测试

### 3.1 测试代码

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

### 3.2 下载测试

首先将 `chk_addr` 设置为 `0xh2000` 查看内存的初始数据（下面 led 对应的就是当前 `chk_addr` ）：

<img src="..\images\mem0.png" style="zoom:50%;" />

<img src="..\images\mem1.png" style="zoom:50%;" />

<img src="..\images\mem2.png" style="zoom:50%;" />

然后设置断点后开始排序，排序完之后，使用数码管将其排序结果输出：

<img src="..\images\seg0.png" style="zoom:50%;" />

<img src="..\images\seg1.png" style="zoom:50%;" />

<img src="..\images\seg2.png" style="zoom:50%;" />

然后可以再次查看内存里的值，看看排序后数组是否正确有序地存储在内存当中（下面 led 对应的就是当前 `chk_addr` ）：

<img src="..\images\sort0.png" style="zoom:50%;" />

<img src="..\images\sort1.png" style="zoom:50%;" />

<img src="..\images\sort2.png" style="zoom:50%;" />

<img src="..\images\sort3.png" style="zoom:50%;" />

### 3.3 电路资源和时间性能

#### 3.3.1 RTL电路图

<img src="..\images\rtl.png" />

#### 3.3.2 综合电路

<img src="..\images\syn_rtl.png" />

#### 3.3.3 电路资源

<img src="..\images\utilization.png" />

#### 3.3.4 电路性能

<img src="..\images\time1.png" />

<img src="..\images\time2.png" />

## 4. 实验总结

1. 从本次实验中，学习到了单周期 CPU 的设计方法，并且自主实现了一个单周期 CPU 的结构，设计了多个功能部件，并且采用了多级译码的方式来生成 `ALUfun` ，很好地理解了其中的工作原理，很好地与理论课所学知识相结合。同时本次实验采用了 PDU 调试模块，让我们可以掌握单周期 CPU 的调试方法，并且熟悉使用 PDU模块来调试我们设计的 CPU 的错误。

2. 本次实验中也遇到了一些问题，例如出现了组合环的现象，Vivado 报错为：`FATAL_ERROR: Iteration limit 10000 is reached. Possible zero delay oscillation detected where simulation time can not advance. Please check your source code. Note that the iteration limit can be changed using switch -maxdeltaid.`。通过分析，发现了代码中确实存在组合环的现象，存在于寄存器堆中，将其修改即可：（原因在于这个写优先会导致组合逻辑的输出反馈给组合逻辑的输入，导致无限循环一直变化）

   ```verilog
   //    assign rd0 = (ra0 == wa && we) ? wd : rf[ra0];
       assign rd0 = rf[ra0];
   ```

3. 本次实验难度极大，做起来十分吃力，耗费时间大。原因在于：

   - PPT 内容不详尽，很多内容不懂要干什么（引用一个同学的说法：PPT 不像是文档，反而像是注释）
   - 时间短促（我是在一周内写完的，但是后面延长了O^O）
   - PDU 模块作为一个调试单元，本意是用来给大家调试 CPU 中的错误，可是老师给出 PDU 的时间不仅晚，而且错误很多，无疑给同学们带来了更多困难

4. 强烈建议延长实验时间，完善 PPT 内容，并且给出 PDU 前请确保 PDU 的正确性以及可行性。
