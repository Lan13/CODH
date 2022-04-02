`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/25 20:39:53
// Design Name: 
// Module Name: SORT
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
    // DONE
    wire [15:0] x_clean, x_clean2, x_edge;
    wire [3:0] h;
    wire p;
    // DPE BEGIN
    BTN_CLEAN clean(.clk(clk), .btn(x), .btn_clean(x_clean));
    BTN_CLEAN clean2(.clk(clk), .btn(x_clean), .btn_clean(x_clean2));
    BTN_EDGE edg(.clk(clk), .btn(x_clean2), .btn_edge(x_edge));
    ENCODER16 encode(.clk(clk), .signal(x_edge), .h(h), .p(p));
    // END

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

    // modified
    reg [7:0] next_a, now_a, load_a;
    wire write_en;
    reg reload_en;
    MUX2 #(1,0) mux_data_p (.sel1(reload_en), .sel0(data_p), .s(busy), .y(write_en));
    // end

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
    // DONE



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
                    else if (done_cnt == 8'hFF)
                        next_state = reload;
                    else
                        next_state = sorting;
//                else if (done_cnt == 8'hFF)
//                    next_state = finised;
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
