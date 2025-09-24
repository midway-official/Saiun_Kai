
`default_nettype wire
module thinpad_top(
   // ----------------- System Clock -----------------
    input  wire c0_sys_clk_p,  // 差分时钟正端
    input  wire c0_sys_clk_n,  // 差分时钟负端

    // ----------------- Reset ------------------------
    input  wire reset_btn_n,   // 低有效复位

    // ----------------- UART -------------------------
    input  wire rxd,           // UART 接收
    output wire txd            // UART 发送
);
wire reset_btn;           
assign reset_btn = !reset_btn_n;  
/* =========== Demo code begin =========== */

// PLL鍒嗛绀轰緥
wire locked, clk_CPU, clk_20M,clk_60M;
clock clock_gen 
 (
  // Clock in ports
  .clk_in1_n(c0_sys_clk_n),  
  .clk_in1_p(c0_sys_clk_p),  
  // Clock out ports
  .clk_out1(clk_CPU), 

  .reset(reset_btn), 
  .locked(locked)    
                     
 );

reg reset_of_clkCPU;

always@(posedge clk_CPU or negedge locked) begin
    if(~locked) reset_of_clkCPU <= 1'b1;
    else        reset_of_clkCPU <= 1'b0;
end





// ---------------- 核心信号 ----------------
// CPU核心访存信号
wire [31:0]  mem_addr;          // 内存地址
wire [31:0]  mem_wdata;         // 写入数据
wire [31:0]  mem_rdata;         // 读取数据
wire [3:0]   mem_sel_n;         // 字节选择信号
wire         mem_en;            // 访存使能
wire         mem_done;          // 访存完成
wire         mem_we_n;          // 写使能（低有效）

// 原子操作信号
wire SYNC, LL, SC, SC_result;

// 中断信号
wire EXTI, IF_EXTI;

// 串口状态信号
wire txd_busy;
wire [1:0] state;

// ---------------- BaseRAM信号 ----------------
wire [31:0] base_ram_wdata;     // BaseRAM写数据
wire [31:0] base_ram_rdata;     // BaseRAM读数据
wire [19:0] base_ram_addr;      // BaseRAM地址
wire [3:0]  base_ram_be_n;      // BaseRAM字节使能
wire        base_ram_ce_n;      // BaseRAM片选
wire        base_ram_oe_n;      // BaseRAM读使能
wire        base_ram_we_n;      // BaseRAM写使能

// ---------------- ExtRAM信号 ----------------
wire [31:0] ext_ram_wdata;      // ExtRAM写数据
wire [31:0] ext_ram_rdata;      // ExtRAM读数据
wire [19:0] ext_ram_addr;       // ExtRAM地址
wire [3:0]  ext_ram_be_n;       // ExtRAM字节使能
wire        ext_ram_ce_n;       // ExtRAM片选
wire        ext_ram_oe_n;       // ExtRAM读使能
wire        ext_ram_we_n;       // ExtRAM写使能



// ---------------- CPU核心例化 ----------------
Saiun_Kai Saiun_Kai (
    // 时钟和复位
    .clk        (clk_CPU),
    .rst        (reset_of_clkCPU),
    
    // 访存接口
    .mem_addr   (mem_addr),
    .mem_wdata  (mem_wdata),
    .mem_rdata  (mem_rdata),
    .mem_sel_n  (mem_sel_n),
    .mem_wen_n  (mem_we_n),
    .mem_en     (mem_en),
    .mem_done   (mem_done),
    
    // 原子操作/同步
    .LL         (LL),
    .SC         (SC),
    .SC_result  (SC_result),
    
    // 异常/中断
    .EXTI       (EXTI)
);

// ---------------- RAM和串口控制器例化 ----------------
Ram_Serial_ctrl Ram_Serial_ctrl_inst (
    // 时钟和复位
    .clk                (clk_CPU),
    .rst                (reset_of_clkCPU),
    
    // 统一访存接口 - 连接到CPU
    .mem_rdata          (mem_rdata),        // 输出到CPU
    .mem_addr           (mem_addr),         // 来自CPU
    .mem_wdata          (mem_wdata),        // 来自CPU
    .mem_we_n           (mem_we_n),         // 来自CPU
    .mem_sel_n          (mem_sel_n),        // 来自CPU
    .mem_ce_i           (mem_en),           // 来自CPU
    
    // BaseRAM信号 - 解耦后的信号
    .base_ram_wdata     (base_ram_wdata),   // 输出到BRAM
    .base_ram_rdata     (base_ram_rdata),   // 来自BRAM
    .base_ram_addr      (base_ram_addr),    // 输出到BRAM
    .base_ram_be_n      (base_ram_be_n),    // 输出到BRAM
    .base_ram_ce_n      (base_ram_ce_n),    // 输出到BRAM
    .base_ram_oe_n      (base_ram_oe_n),    // 输出到BRAM
    .base_ram_we_n      (base_ram_we_n),    // 输出到BRAM
    
    // ExtRAM信号 - 解耦后的信号
    .ext_ram_wdata      (ext_ram_wdata),    // 输出到EXTRAM
    .ext_ram_rdata      (ext_ram_rdata),    // 来自EXTRAM
    .ext_ram_addr       (ext_ram_addr),     // 输出到EXTRAM
    .ext_ram_be_n       (ext_ram_be_n),     // 输出到EXTRAM
    .ext_ram_ce_n       (ext_ram_ce_n),     // 输出到EXTRAM
    .ext_ram_oe_n       (ext_ram_oe_n),     // 输出到EXTRAM
    .ext_ram_we_n       (ext_ram_we_n),     // 输出到EXTRAM
    
    // 串口信号
    .txd                (txd),
    .rxd                (rxd),
    .txd_busy           (txd_busy),
    .state              (state)
);

// ---------------- 原子操作结果处理 ----------------
// SC操作结果处理（简单实现，总是成功）
assign SC_result = 1'b1;

// ---------------- 中断信号处理 ----------------
// 中断信号处理（简单实现，暂时没有外部中断）
assign EXTI = 1'b0;
assign IF_EXTI = 1'b0;

// ---------------- BRAM模块例化 ----------------
BRAM u_bram (
    .clk        (clk_CPU),
    .rst        (reset_of_clkCPU),
    .addr_i     (base_ram_addr),        // 地址信号
    .rdata      (base_ram_rdata),       // 读数据输出
    .wdata      (base_ram_wdata),       // 写数据输入
    .wen_i      (base_ram_we_n),       
    .sel        (base_ram_be_n),       
    .en_i       (base_ram_ce_n)        
);

// ---------------- EXTRAM模块例化 ----------------
EXTRAM u_extram (
    .clk        (clk_CPU),
    .rst        (reset_of_clkCPU),
    .addr_i     (ext_ram_addr),         // 地址信号
    .rdata      (ext_ram_rdata),        // 读数据输出
    .wdata      (ext_ram_wdata),        // 写数据输入
    .wen_i      (ext_ram_we_n),        // 
    .sel        (ext_ram_be_n),        // 
    .en_i       (ext_ram_ce_n)         // 
);

endmodule
