# Lab2 实验报告

[TOC]

## 1. 32x32位的寄存器堆

### 1.1 核心代码

```verilog
module REG_FILE #(parameter AW = 5, parameter DW = 32)(
    input clk,
    input [AW-1:0] ra0, ra1,
    output [DW-1:0] rd0, rd1,
    input [AW-1:0] wa,
    input [DW-1:0] wd,
    input we
);
    reg [DW-1:0] rf[0:(1<<AW)-1];
    wire [DW-1:0] ini;
    assign ini = 0;
    assign rd0 = we ? wd : rf[ra0];
    assign rd1 = rf[ra1];
    always @(posedge clk) begin
        if (we) begin
            if (wa != 0)
                rf[wa] <= wd;
        end
    end
    always@(*) begin
        rf[0] = ini;	// 上板时可有可无，但对于仿真文件是需要的
    end
endmodule
```

### 1.2 功能仿真

#### 1.2.1 仿真文件

```verilog
module tb_regfile();
    reg clk;
    reg [4:0] ra0, ra1;
    wire [31:0] rd0, rd1;
    reg [4:0] wa;
    reg [31:0] wd;
    reg we;
    integer i;

    REG_FILE test(.clk(clk), .ra0(ra0), .ra1(ra1), .rd0(rd0), .rd1(rd1), .wa(wa), .wd(wd), .we(we));

    initial begin
        clk = 0;
        we = 1;
        forever #10 clk = ~clk;
    end

    initial begin
        for(i = 0; i <= 31; i = i + 1) begin
            wa = i;
            wd = (i+1)*100;
            ra0 = i;
            #50;
        end
        ra0 = 5'b00011;
        wa = 5'b00011;
        wd = 5'b00011;
        ra1 = 5'b00011;
    end

endmodule
```

#### 1.2.2 仿真结果

首先对所有寄存器初始化一个值，同时可以发现，0号寄存器的值并未更改，还是保持为0：

<img src="..\images\regfile_sim_0.png" width="600"/>

接着在初始化结束后，修改3号寄存器的值，可以发现，数据一写入，输出数据 `rd0` 立马变化，对比 `rd1` ，`rd1` 会先输出上一个时钟周期的数据，然后再时钟上升沿显示出写入数据。所以实际上这是写操作优先的。即当读取的寄存器和访问的寄存器一致时，`rd0` 会显示当前写入的数据：

<img src="..\images\regfile_sim_1.png" width="800"/>

## 2. 256x16位的分布式和块式RAM IP核

### 2.1 分布式和块式存储器的读操作

#### 2.1.1 仿真文件

由于只需要比较分布式和块式存储器的读操作，所以在仿真文件中我们只要将地址进行变化即可：

```verilog
module tb_mem();
    reg clk, we;
    reg [7:0] a;
    reg [15:0] d;
    wire [15:0] spo, douta;
    reg ena;

    integer i;

    dist_mem_gen_0 dist_test(.clk(clk), .we(we), .a(a), .d(d), .spo(spo));
    blk_mem_gen_0 blk_test(.clka(clk), .wea(we), .addra(a), .dina(d), .douta(douta), .ena(ena));

    initial begin
        we = 0;
        ena = 1;
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        for(i = 0; i <= 255; i = i + 1) begin
            a = i;
            #50;
        end
    end
endmodule
```

#### 2.1.2 仿真结果

<img src="..\images\dist_blk_read.png" width="700"/>

#### 2.1.3 对比结果

- 块式 RAM 的读取需要时钟信号，分布式 RAM 的读取不需要时钟信号。
- 分布式 RAM 的使用更灵活方便些，块式 RAM 的时序性会更好。

### 2.2 块式存储器写操作优先和读操作优先

#### 2.2.1 仿真文件

既然比较的是块式存储器读操作优先和写操作优先，那么只需要着重注意在写信号有效的时候，这个时候读取的数据是写入前的数据还是写进的数据，因为其余时间读取的结果肯定都是相同的。

```verilog
module tb_read_write();
    reg [7:0] addra;
    reg clka;
    reg [15:0] dina;
    reg ena;
    reg wea;
    wire [15:0] douta_read, douta_write;

    blk_mem_gen_0 write_test(.addra(addra), .clka(clka), .dina(dina), .ena(ena), .wea(wea), .douta(douta_write));
    blk_mem_gen_1 read_test(.addra(addra), .clka(clka), .dina(dina), .ena(ena), .wea(wea), .douta(douta_read));

    initial begin
        ena = 1;
        clka = 0;
        addra = 8'b11;
        forever #10 clka = ~clka;
    end

    initial begin
        #100;
        wea = 1;
        dina = 16'b1000;
    end
endmodule
```

#### 2.2.2 仿真结果

<img src="..\images\blk_read_write.png" width="700"/>

#### 2.2.3 对比结果

可以看出，写操作优先的块式存储器在时钟沿上升的时候直接输出刚写进的数据，而读操作优先的块式存储器在时钟沿的上升的时候保持不变，输出的还是写入前的数据，而当下一个时钟沿上升的时候，输出刚刚写进的数据。

所以说，写操作优先的块式存储器会直接输出写进的数据，而读操作优先的块式存储器会在下一个时钟周期输出写进的数据，即输出会延迟一个周期。

## 3. 排序电路的逻辑设计、仿真和下载测试

### 3.1 逻辑设计

> 总体思路：由于 DRAM 中只有一个共有的读写端口和一个读端口，所以在交换过程中重新写入需要修改读写端口，导致原来的地址改变，这样是不便于后续交换的。而寄存器堆 REG_FILE 是拥有两个读端口和一个写端口的。所以我的想法是将 DRAM 中的数据先存储到 REG_FILE 寄存器堆内，接着进行排序过程。在排序时，如果两个数据不是有序的，则进行交换存储，由于这时候寄存器堆 `REG_FILE` 可以保持原地址不变（就是只改变写地址来存数据，而原来的读地址不变），则这次交换完后可以立马进行下一位比较，直至把这个最大的数排到尽可能后面，而这就是冒泡排序的思路，只不过在这里有点类似于把最大的数“沉底”罢了。在寄存器堆内完成排序后，再重新重载回 DRAM 中，这样会极大地方便排序进行。

#### 3.1.1 数据通路

由于数据通路在电脑上作图实在过于麻烦，所以手绘了一个简易版：

<img src="..\images\data_path.jpg"/>

其中每个框内代表的是其可能的赋值，用这个来代表数据线，显得比较清晰方便。具体的数据输入对应于每个状态。
#### 3.1.2 状态转化

记排序的初始状态为  `waiting`，所有的数据输入操作都发生 `waiting` 状态中，这个时候 `busy = 0` ，使得可以使用 `data` ，`del` ，`addr`，`chk` 等操作。在按下 `run` 之后，`busy = 1` 并且进入下一个状态 `loading`，即把 DRAM 中的所有数据存储在寄存器堆。在装载完成之后，状态进入到排序状态。`sorting` 状态中，每次取出两个数，并且用 `ALU` 进行比较，如果后一个数字比前一个数字小，则会发生交换事件，进入到下一个状态 `store1`。在 `store1` 和 `store2` 两个状态中分别对前后两个数字进行重新存储，完成交换，并且返回到 `sorting` 状态。其中用一个寄存器 `done_cnt` 来记录当前这一轮的完成数，当不发生交换事件时，完成数会＋1，当完成数达到数据的总个数时，说明所有数据已经有序，这时候进入到 `reload` 状态。在 `reload` 状态中，把寄存器里全部有序的数据重新存储到 DRAM 当中，当存储完成时，进入 `finished` 状态。最后再把 `busy` 置为0。

<img src="..\images\state_machine.png" width="700"/>

### 3.2 核心代码

#### 3.2.1 ENCODER16

由于每次 `x` 只改变一个开关，所以我们可以对其进行枚举，将 `h` 编码为对应数据。同时又因为每次只有一个开关变化，使得 `x` 只有一位为高电平，所以脉冲可以使用缩位或 `|` 运算得到，这样在 `x` 取边沿之后，`p` 也是只维持一个周期的。

```verilog
module ENCODER16 (
    input clk,
    input [15:0] signal,
    output reg [3:0] h,
    output p
);
    always@(*) begin
        case(signal)
            16'h0001: h = 4'h0;
            16'h0002: h = 4'h1;
            16'h0004: h = 4'h2;
            16'h0008: h = 4'h3;
            16'h0010: h = 4'h4;
            16'h0020: h = 4'h5;
            16'h0040: h = 4'h6;
            16'h0080: h = 4'h7;
            16'h0100: h = 4'h8;
            16'h0200: h = 4'h9;
            16'h0400: h = 4'ha;
            16'h0800: h = 4'hb;
            16'h1000: h = 4'hc;
            16'h2000: h = 4'hd;
            16'h4000: h = 4'he;
            16'h8000: h = 4'hf;
        endcase
    end
    assign p = |signal;
endmodule
```

#### 3.2.2 SEG7

由于数码管是共用显示数据的，使得在同一时刻，只能显示出一个数码管的数据。但是由于人眼视觉暂留效应，控制数码管交替显示时间间隔，如果数码管切换时间足够快，肉眼效果即为多个数码管同时点亮。所以我们需要对其采取时分复用的方式。同时根据多次测试发现，这些管脚都是低电平有效的。

```verilog
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
```

#### 3.2.3 BTN_CLEAN

由于这次需要去抖动的开关比较多，同时又因为 `x` 每次只改变一位数据的特性，我们可以设计如下去除抖动的代码，直接对所有开关一起进行去除抖动。

```verilog
module BTN_CLEAN #(parameter WIDTH = 16)(
    input clk,
    input [WIDTH-1:0] btn,
    output [WIDTH-1:0] btn_clean 
);
    integer i;
    genvar j;
    reg [3:0] btn_cnt[0:WIDTH-1];
    always @(posedge clk) begin
        for(i = 0; i <= WIDTH - 1; i = i + 1) begin
            if(btn[i] == 1'b0)
                btn_cnt[i] <= 4'h0;
            else if(btn_cnt[i] < 4'hF)
                btn_cnt[i] <= btn_cnt[i] + 1'b1;
            else
                btn_cnt[i] <= btn_cnt[i];
        end
    end
    for(j = 0; j <= WIDTH - 1; j = j + 1) begin
        assign btn_clean[j] = btn_cnt[j][3];
    end
endmodule
```

#### 3.2.4 BTN_EDGE

不同于之前，这里要求的是在 `x` 向上拨动和向下拨动都能得到一个数据，所以要进行双边检验，在上下边缘都取一次信号：

```verilog
module BTN_EDGE #(parameter WIDTH = 16)(
    input clk,
    input [WIDTH-1:0] btn,
    output [WIDTH-1:0] btn_edge
);
    reg btn1[WIDTH-1:0], btn2[WIDTH-1:0];
    integer i;
    genvar j;

    always@(posedge clk) begin
        for(i = 0; i <= WIDTH - 1; i = i + 1)
            btn1[i] <= btn[i];
    end

    always@(posedge clk) begin
        for(i = 0; i <= WIDTH - 1; i = i + 1)
            btn2[i] <= btn1[i];
    end

    for(j = 0; j <= WIDTH - 1; j = j + 1) begin
        assign btn_edge[j] = (btn1[j]&(~btn2[j]))|((~btn1[j])&btn2[j]);
    end
endmodule
```

#### 3.2.5 SORT

```verilog
module SORT(
    input clk,
    input rst,

    input [15:0] x,
    input del,
    input addr,
    input data,
    input chk,
    input run,

    output [7:0] an,
    output [6:0] seg,
    output reg busy,
    output reg [15:0] cnt
);

    wire [15:0] x_clean, x_clean2, x_edge;
    wire [3:0] h;
    wire p;

    BTN_CLEAN clean(.clk(clk), .btn(x), .btn_clean(x_clean));
    BTN_CLEAN clean2(.clk(clk), .btn(x_clean), .btn_clean(x_clean2));
    BTN_EDGE edg(.clk(clk), .btn(x_clean2), .btn_edge(x_edge));
    ENCODER16 encode(.clk(clk), .signal(x_edge), .h(h), .p(p));

    wire chk_clean, del_clean, data_clean, addr_clean, run_clean, rst_clean;
    wire chk_p, del_p, data_p, addr_p, run_p, rst_p;
    BTN_CLEAN #(1) clean_chk(.clk(clk), .btn(chk), .btn_clean(chk_clean));
    BTN_CLEAN #(1) clean_del(.clk(clk), .btn(del), .btn_clean(del_clean));
    BTN_CLEAN #(1) clean_data(.clk(clk), .btn(data), .btn_clean(data_clean));
    BTN_CLEAN #(1) clean_addr(.clk(clk), .btn(addr), .btn_clean(addr_clean));
    BTN_CLEAN #(1) clean_run(.clk(clk), .btn(run), .btn_clean(run_clean));
    BTN_CLEAN #(1) clean_rst(.clk(clk), .btn(rst), .btn_clean(rst_clean));
    BTN_EDGE1 edge_chk(.clk(clk), .btn(chk_clean), .btn_edge(chk_p));
    BTN_EDGE1 edge_del(.clk(clk), .btn(del_clean), .btn_edge(del_p));
    BTN_EDGE1 edge_data(.clk(clk), .btn(data_clean), .btn_edge(data_p));
    BTN_EDGE1 edge_addr(.clk(clk), .btn(addr_clean), .btn_edge(addr_p));
    BTN_EDGE1 edge_run(.clk(clk), .btn(run_clean), .btn_edge(run_p));
    BTN_EDGE1 edge_rst(.clk(clk), .btn(rst_clean), .btn_edge(rst_p));

    reg [7:0] a, dpra;
    reg [15:0] d;
    reg s;
    wire [15:0] spo, dpo;

    reg [7:0] next_a, now_a, load_a;
    wire write_en;
    reg reload_en;
    MUX2 #(1,0) mux_data_p (.sel1(reload_en), .sel0(data_p), .s(busy), .y(write_en));

    dist_mem_gen_1 dist_test(.clk(clk), .we(write_en), .a(a), .d(d), .spo(spo), .dpra(dpra), .dpo(dpo));
    wire [15:0] mux_s_out;
    MUX2 #(16,0) mux_s (.sel1(d), .sel0(spo), .s(s), .y(mux_s_out));
    wire [15:0] now_data, next_data;
    
    always@(posedge clk or posedge rst_p) begin
        if (rst_p == 1'b1) begin
            a <= 8'b0;
            d <= 16'b0;
            s <= 1'b0;
        end
        else if (busy == 1'b0) begin
            if (chk_p == 1'b1) begin
                a <= a + 1'b1;
                s <= 1'b0;
            end
            else if (p == 1'b1) begin
                d <= {d[11:0], h};
                s <= 1'b1;
            end
            else if (del_p == 1'b1) begin
                d <= d[15:4];
                s <= 1'b1;
            end
            else if (data_p == 1'b1) begin
                d <= 16'b0;
                a <= a + 1'b1;
                s <= 1'b0;
            end
            else if (addr_p == 1'b1) begin
                a <= d[7:0];
                d <= 16'b0;
                s <= 1'b0;
            end
        end
        else if (current_state == reload || current_state == finised) begin
                a <= now_a;
                d <= now_data;
                reload_en <= 1'b1;
        end
    end

    SEG7 seg_display(.clk(clk), .a(a), .mux_s_out(mux_s_out), .an(an), .display(seg));

    reg [15:0] load_data, load_data1;
    reg load_reg;
    wire load;
    assign load = (current_state == loading)||(load_reg == 1'b1);
    
    REG_FILE #(8,16) regfile(.clk(clk), .ra0(now_a), .ra1(next_a), .rd0(now_data), .rd1(next_data), .wa(load_a), .wd(load_data1), .we(load));
    
    reg [2:0] current_state, next_state;
    reg [7:0] done_cnt;
    parameter waiting = 3'b0, loading = 3'b1, sorting = 3'b10, store1 = 3'b11, store2 = 3'b100, reload = 3'b101, finised = 3'b110;
    wire [2:0] less_than;

    always@(*) begin
        if(current_state == loading)
            load_data1 = dpo;
        else
            load_data1 = load_data;
    end
    ALU #(16) alu_sort(.a(next_data), .b(now_data), .s(3'b000), .y(), .f(less_than));
    
    always@(posedge clk or posedge rst_p) begin
        if (rst_p) begin
            current_state <= waiting;
            cnt <= 16'b0;
            busy <= 1'b0;
            next_a <= 8'b0;
            now_a <= 8'b0;
            done_cnt <= 8'b0;
            dpra <= 8'b0;
            load_a <= 8'b0;
            load_reg <= 1'b0;
        end
        else begin
            current_state <= next_state;
            case (current_state) 
                waiting: begin
                    if (run_p)
                        busy <= 1'b1;
                end
                loading: begin
                    load_a <= load_a + 1'b1;
                    dpra <= dpra + 1'b1;
                    load_data <= dpo;
                end
                sorting: begin
                    load_reg <= 1'b0;
                    if (less_than[2] != 1'b1) begin
                        next_a <= next_a + 1'b1;
                        now_a <= next_a;
                        done_cnt <= done_cnt + 1'b1;
                    end
                    else if(now_a == 8'hFF) begin
                        next_a <= next_a + 1'b1;
                        now_a <= next_a;
                        done_cnt <= 8'b0;
                    end
                    else
                        done_cnt <= 8'b0;
                    cnt <= cnt + 1'b1;
                end
                store1: begin
                    load_reg <= 1'b1;
                    load_a <= now_a;
                    load_data <= next_data;
                    cnt <= cnt + 1'b1;
                end
                store2: begin
                    load_reg <= 1'b1;
                    load_a <= next_a;
                    load_data <= now_data;
                    cnt <= cnt + 1'b1;
                end
                reload: begin
                    now_a <= now_a + 1'b1;
                end
                finised: begin
                    busy <= 1'b0;
                end
            endcase
        end
    end

    always@(*) begin
        case(current_state)
            waiting: begin
                if (run_p)
                    next_state = loading;
                else
                    next_state = waiting;
            end
            loading: begin
                if (load_a == 8'hFF)
                    next_state = sorting;
                else
                    next_state = loading;
            end
            sorting: begin
                if (less_than[2] == 1'b1)
                    if(now_a != 8'hFF)
                        next_state = store1;
                	else if (done_cnt == 8'hFF)		//此轮排序完成
                        next_state = reload;
                    else
                        next_state = sorting;
                else
                    next_state = sorting;
            end
            store1: begin
                next_state = store2;
            end
            store2: begin
                next_state = sorting;
            end
            reload: begin
                if(now_a == 8'hFF)
                    next_state = finised;
                else
                    next_state = reload;
            end
            finised: begin
                next_state = waiting;
            end
            default: begin
                next_state = waiting;
            end
        endcase
    end
    
endmodule
```

### 3.3 仿真结果和下载测试

#### 3.3.1 仿真结果

由于数据输入需要进行多步，在仿真实现中比较麻烦，所以在本仿真中，只在地址2中写入数据 `oxb` ，即只对一个数字进行排序，便于方便检查结果：

在数据输入完成之后，首先进入 `loading` 状态：

<img src="..\images\sim_loading.png" width="600"/>

接着在 `sorting` 状态中，发现数据不是有序的时候，会进入到 `store` 状态：

<img src="..\images\sim_store.png" width="700"/>

在排序完成之后，会进入到 `reload` 状态，**同时从该过程中（`next_data` 和 `next_a`)，可以看出排序的正确性**：

<img src="..\images\sim_reload.png" width="700"/>

最后 `reload` 结束，进入到 `finished` 状态，完成排序，`busy = 0`， 并且返回到 `waiting` 状态：

<img src="..\images\sim_finished.png" width="700"/>

#### 3.3.2 下载测试

约束文件如下：

```verilog
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports { data }];
set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 } [get_ports { del }];
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 } [get_ports { addr }];
set_property -dict { PACKAGE_PIN M17 IOSTANDARD LVCMOS33 } [get_ports { chk }];
set_property -dict { PACKAGE_PIN P18 IOSTANDARD LVCMOS33 } [get_ports { run }];
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { rst }];

set_property -dict { PACKAGE_PIN N15 IOSTANDARD LVCMOS33 } [get_ports { busy }];

set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports { x[15] }];
set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS33 } [get_ports { x[14] }];
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { x[13] }];
set_property -dict { PACKAGE_PIN H6 IOSTANDARD LVCMOS33 } [get_ports { x[12] }];
set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports { x[11] }];
set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS33 } [get_ports { x[10] }];
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports { x[9] }];
set_property -dict { PACKAGE_PIN T8 IOSTANDARD LVCMOS33 } [get_ports { x[8] }];
set_property -dict { PACKAGE_PIN R13 IOSTANDARD LVCMOS33 } [get_ports { x[7] }];
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports { x[6] }];
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports { x[5] }];
set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS33 } [get_ports { x[4] }];
set_property -dict { PACKAGE_PIN R15 IOSTANDARD LVCMOS33 } [get_ports { x[3] }];
set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS33 } [get_ports { x[2] }];
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports { x[1] }];
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { x[0] }];

set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports { cnt[15] }];
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { cnt[14] }];
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { cnt[13] }];
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports { cnt[12] }];
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports { cnt[11] }];
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { cnt[10] }];
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports { cnt[9] }];
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports { cnt[8] }];
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { cnt[7] }];
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { cnt[6] }];
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { cnt[5] }];
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { cnt[4] }];
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { cnt[3] }];
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { cnt[2] }];
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { cnt[1] }];
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { cnt[0] }];

set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { an[7] }];
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports { an[6] }];
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { an[5] }];
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { an[4] }];
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports { an[3] }];
set_property -dict { PACKAGE_PIN T9 IOSTANDARD LVCMOS33 } [get_ports { an[2] }];
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports { an[1] }];
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports { an[0] }];

set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { seg[6] }];
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { seg[5] }];
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { seg[4] }];
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports { seg[3] }];
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { seg[2] }];
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { seg[1] }];
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { seg[0] }];
```

接下来将展示数据输入按钮的功能：

首先先在地址1的位置上拨动开关7：

<img src="..\images\x7.png" width="500"/>

接着在地址1的位置上拨动开关6：

<img src="..\images\x6.png" width="500"/>

然后按下 `del` 按钮，可以发现数据6被删除：

<img src="..\images\del.png" width="500"/>

然后按下 `data` 按钮，这时候可以保存数据 `0xh7` 到地址1上，同时显示下一个地址的数据：

<img src="..\images\data.png" width="500"/>

然后拨动开关1，按下 `addr` 按钮，可以查看地址1的内容，发现数据 `0xh7` 已经保存到地址1上了：

<img src="..\images\addr.png" width="500"/>

同时为了方便测试排序正确性，我将分布式 RAM 的初始文件进行了小小修改：

<img src="..\images\init.png" width="500"/>

这样可以直接进行一个较大规模的排序，效果如下：

<img src="..\images\sort_init1.png" width="500"/>

<img src="..\images\sort_init2.png" width="500"/>

<img src="..\images\sort_init3.png" width="500"/>

按下 `run` 按键后：

<img src="..\images\sort_done1.png" width="500"/>

<img src="..\images\sort_done2.png" width="500"/>

<img src="..\images\sort_done3.png" width="500"/>

### 3.4 电路资源和时间性能

#### 3.4.1 RTL电路

<img src="..\images\RTL1.png"/>

<img src="..\images\RTL2.png"/>

#### 3.4.2 综合电路

<img src="..\images\sort_schematic.png"/>

#### 3.4.3 电路资源

<img src="..\images\sort_utilization.png" width="600"/>

#### 3.4.4 时间性能

<img src="..\images\sort_timing.png" width="700"/>

<img src="..\images\sort_timing1.png" width="700"/>

## 4. 实验总结

1. 本次实验中进行了 SORT 模块的编写，对寄存器堆和 IP 核进行了应用。同时温故了 `for` 的使用方法，以及时分复用的设计思路来显示数码管。同时本次实验采取了三段式的设计方式，进一步加强了设计逻辑，最后实现了功能较为齐全，工程量较大的排序应用程序，并且能够在开发板上运行使用。
2. 建议：本次实验难度太大，做起来十分痛苦十分耗时。希望可以完善PPT，在 PPT 中给出更详细的教程来指引怎么做、需要注意什么。而不是让同学们在这一门实验上耗费几天时间，严重影响其他课程的学习。
