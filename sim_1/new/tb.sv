`timescale 1ns/1ps
`default_nettype wire

module tb_thinpad_top;

    // ----------------- ʱ�Ӻ͸�λ -----------------
    reg c0_sys_clk_p;
    reg c0_sys_clk_n;
    reg reset_btn_n;

    // ----------------- UART -----------------
    reg rxd;
    wire txd;

    // ʵ��������ģ��
    thinpad_top dut (
        .c0_sys_clk_p(c0_sys_clk_p),
        .c0_sys_clk_n(c0_sys_clk_n),
        .reset_btn_n(reset_btn_n),
        .rxd(rxd),
        .txd(txd)
    );

    // ----------------- ʱ������ -----------------
    initial begin
        c0_sys_clk_p = 0;
        c0_sys_clk_n = 1; // ���ʱ��
        forever #5 c0_sys_clk_p = ~c0_sys_clk_p; // 100 MHz
    end

    always @(c0_sys_clk_p)
        c0_sys_clk_n = ~c0_sys_clk_p; // ��ַ���

    // ----------------- ���Թ��� -----------------
    initial begin
        // ��ʼ��
        reset_btn_n = 0;
        rxd = 1; // UART idle

        // ��λ����100 ns
        #1000;
        reset_btn_n = 1;

        #1000000000;


    end



endmodule
