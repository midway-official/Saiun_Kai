`default_nettype wire
module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到"ON"时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式时无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请置为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_CPU, clk_20M;
clk_wiz_0 clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // 外部时钟输入
  // Clock out ports
  .clk_out1(clk_CPU), // 时钟输出1，频率在IP配置界面中设置 59M
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置 20M
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
                     // 后级电路复位信号应当由它生成（见下）
 );
wire  reset_of_clkCPU =reset_btn;

// ---------- 顶层对 CPU 与 内存/串口 控制器 的实例化连接 ----------

// 与 Saiun_Kai/Ram_Serial_ctrl 连接的内部总线信号
wire [31:0] cpu_mem_addr;
wire [31:0] cpu_mem_wdata;
wire [31:0] cpu_mem_rdata;
wire [3:0]  cpu_mem_sel_n;
wire        cpu_mem_en;
wire        cpu_mem_wen_n;
wire        cpu_mem_done;

wire        cpu_LL;
wire        cpu_SC;
wire        cpu_SC_result;

// 外设中断（如果没有外部中断线，先拉低）
wire        exti_n = 1'b0; // EXTI = 0 (无外中断)

// 连接顶层的 Base/Ext RAM 与 串口线到 Ram_Serial_ctrl
// 注意：top 模块已有 base_ram_* / ext_ram_* / txd/rxd 等端口

// 实例化 Saiun_Kai（CPU/主控）
Saiun_Kai u_saiun_kai (
    .clk      (clk_CPU),          // 来自 PLL 的 CPU 时钟
    .rst      (reset_of_clkCPU),  // 复位（高电平有效，和你的 reset_of_clkCPU 保持一致）
    // 访存接口（输出 -> Ram_Serial_ctrl）
    .mem_addr (cpu_mem_addr),
    .mem_wdata(cpu_mem_wdata),
    .mem_rdata(cpu_mem_rdata),
    .mem_sel_n(cpu_mem_sel_n),
    .mem_en   (cpu_mem_en),
    .mem_wen_n(cpu_mem_wen_n),
    .mem_done (cpu_mem_done),
    // 原子操作与同步
    .LL       (cpu_LL),
    .SC       (cpu_SC),
    .SC_result(cpu_SC_result),    // 目前由外部拉低（见下面）
    // 异常 / 中断
    .EXTI     (exti_n)
);

// 如果你的设计需要 SC_result（store-conditional 结果），
 // 需要把实际逻辑连回这里。当前暂用 0 表示失败（可按需改）。
assign cpu_SC_result = 1'b1;

// 实例化 Ram_Serial_ctrl（负责 Base/Ext RAM 与 串口的仲裁）
Ram_Serial_ctrl u_ram_serial_ctrl (
    .clk            (clk_CPU),
    .rst            (reset_of_clkCPU),

    // 统一的访存接口（来自 Saiun_Kai）
    .mem_rdata      (cpu_mem_rdata),   // Ram_Serial_ctrl 输出给 CPU 的读数据
    .mem_addr       (cpu_mem_addr),    // CPU 地址输入
    .mem_wdata      (cpu_mem_wdata),   // CPU 写数据输入
    .mem_we_n       (cpu_mem_wen_n),   // 写使能（低有效）
    .mem_sel_n      (cpu_mem_sel_n),   // 字节选择（低有效）
    .mem_ce_i       (cpu_mem_en),      // 片选 / 生效（高有效）

    // BaseRAM 信号直接连顶层引脚
    .base_ram_data  (base_ram_data),
    .base_ram_addr  (base_ram_addr),
    .base_ram_be_n  (base_ram_be_n),
    .base_ram_ce_n  (base_ram_ce_n),
    .base_ram_oe_n  (base_ram_oe_n),
    .base_ram_we_n  (base_ram_we_n),

    // ExtRAM 信号直接连顶层引脚
    .ext_ram_data   (ext_ram_data),
    .ext_ram_addr   (ext_ram_addr),
    .ext_ram_be_n   (ext_ram_be_n),
    .ext_ram_ce_n   (ext_ram_ce_n),
    .ext_ram_oe_n   (ext_ram_oe_n),
    .ext_ram_we_n   (ext_ram_we_n),

    // 直连串口（与顶层 txd/rxd 直接连接）
    .txd            (txd),
    .rxd            (rxd),
    .txd_busy       (),       // 可选未连接；Ram_Serial_ctrl 会输出 txd_busy/state
    .state          ()        // 可选未连接
);


endmodule