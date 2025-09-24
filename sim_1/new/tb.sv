`timescale 1ns/1ps
`default_nettype wire

module tb_thinpad_top;

    // ----------------- 时钟和复位 -----------------
    reg c0_sys_clk_p;
    reg c0_sys_clk_n;
    reg reset_btn_n;

    // ----------------- UART -----------------
    reg rxd;
    wire txd;

    // 实例化待测模块
    thinpad_top dut (
        .c0_sys_clk_p(c0_sys_clk_p),
        .c0_sys_clk_n(c0_sys_clk_n),
        .reset_btn_n(reset_btn_n),
        .rxd(rxd),
        .txd(txd)
    );

    // ----------------- 时钟生成 -----------------
    initial begin
        c0_sys_clk_p = 0;
        c0_sys_clk_n = 1; // 差分时钟
        forever #5 c0_sys_clk_p = ~c0_sys_clk_p; // 100 MHz
    end

    always @(c0_sys_clk_p)
        c0_sys_clk_n = ~c0_sys_clk_p; // 差分反相

    // ----------------- 测试过程 -----------------
    initial begin
        // 初始化
        reset_btn_n = 0;
        rxd = 1; // UART idle

        // 复位保持100 ns
        #1000;
        reset_btn_n = 1;

        #1000000000;


    end



endmodule
