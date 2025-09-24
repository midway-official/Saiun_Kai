
`default_nettype wire
module thinpad_top(
   // ----------------- System Clock -----------------
    input  wire c0_sys_clk_p,  // ���ʱ������
    input  wire c0_sys_clk_n,  // ���ʱ�Ӹ���

    // ----------------- Reset ------------------------
    input  wire reset_btn_n,   // ����Ч��λ

    // ----------------- UART -------------------------
    input  wire rxd,           // UART ����
    output wire txd            // UART ����
);
wire reset_btn;           
assign reset_btn = !reset_btn_n;  
/* =========== Demo code begin =========== */

// PLL分频示例
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





// ---------------- �����ź� ----------------
// CPU���ķô��ź�
wire [31:0]  mem_addr;          // �ڴ��ַ
wire [31:0]  mem_wdata;         // д������
wire [31:0]  mem_rdata;         // ��ȡ����
wire [3:0]   mem_sel_n;         // �ֽ�ѡ���ź�
wire         mem_en;            // �ô�ʹ��
wire         mem_done;          // �ô����
wire         mem_we_n;          // дʹ�ܣ�����Ч��

// ԭ�Ӳ����ź�
wire SYNC, LL, SC, SC_result;

// �ж��ź�
wire EXTI, IF_EXTI;

// ����״̬�ź�
wire txd_busy;
wire [1:0] state;

// ---------------- BaseRAM�ź� ----------------
wire [31:0] base_ram_wdata;     // BaseRAMд����
wire [31:0] base_ram_rdata;     // BaseRAM������
wire [19:0] base_ram_addr;      // BaseRAM��ַ
wire [3:0]  base_ram_be_n;      // BaseRAM�ֽ�ʹ��
wire        base_ram_ce_n;      // BaseRAMƬѡ
wire        base_ram_oe_n;      // BaseRAM��ʹ��
wire        base_ram_we_n;      // BaseRAMдʹ��

// ---------------- ExtRAM�ź� ----------------
wire [31:0] ext_ram_wdata;      // ExtRAMд����
wire [31:0] ext_ram_rdata;      // ExtRAM������
wire [19:0] ext_ram_addr;       // ExtRAM��ַ
wire [3:0]  ext_ram_be_n;       // ExtRAM�ֽ�ʹ��
wire        ext_ram_ce_n;       // ExtRAMƬѡ
wire        ext_ram_oe_n;       // ExtRAM��ʹ��
wire        ext_ram_we_n;       // ExtRAMдʹ��



// ---------------- CPU�������� ----------------
Saiun_Kai Saiun_Kai (
    // ʱ�Ӻ͸�λ
    .clk        (clk_CPU),
    .rst        (reset_of_clkCPU),
    
    // �ô�ӿ�
    .mem_addr   (mem_addr),
    .mem_wdata  (mem_wdata),
    .mem_rdata  (mem_rdata),
    .mem_sel_n  (mem_sel_n),
    .mem_wen_n  (mem_we_n),
    .mem_en     (mem_en),
    .mem_done   (mem_done),
    
    // ԭ�Ӳ���/ͬ��
    .LL         (LL),
    .SC         (SC),
    .SC_result  (SC_result),
    
    // �쳣/�ж�
    .EXTI       (EXTI)
);

// ---------------- RAM�ʹ��ڿ��������� ----------------
Ram_Serial_ctrl Ram_Serial_ctrl_inst (
    // ʱ�Ӻ͸�λ
    .clk                (clk_CPU),
    .rst                (reset_of_clkCPU),
    
    // ͳһ�ô�ӿ� - ���ӵ�CPU
    .mem_rdata          (mem_rdata),        // �����CPU
    .mem_addr           (mem_addr),         // ����CPU
    .mem_wdata          (mem_wdata),        // ����CPU
    .mem_we_n           (mem_we_n),         // ����CPU
    .mem_sel_n          (mem_sel_n),        // ����CPU
    .mem_ce_i           (mem_en),           // ����CPU
    
    // BaseRAM�ź� - �������ź�
    .base_ram_wdata     (base_ram_wdata),   // �����BRAM
    .base_ram_rdata     (base_ram_rdata),   // ����BRAM
    .base_ram_addr      (base_ram_addr),    // �����BRAM
    .base_ram_be_n      (base_ram_be_n),    // �����BRAM
    .base_ram_ce_n      (base_ram_ce_n),    // �����BRAM
    .base_ram_oe_n      (base_ram_oe_n),    // �����BRAM
    .base_ram_we_n      (base_ram_we_n),    // �����BRAM
    
    // ExtRAM�ź� - �������ź�
    .ext_ram_wdata      (ext_ram_wdata),    // �����EXTRAM
    .ext_ram_rdata      (ext_ram_rdata),    // ����EXTRAM
    .ext_ram_addr       (ext_ram_addr),     // �����EXTRAM
    .ext_ram_be_n       (ext_ram_be_n),     // �����EXTRAM
    .ext_ram_ce_n       (ext_ram_ce_n),     // �����EXTRAM
    .ext_ram_oe_n       (ext_ram_oe_n),     // �����EXTRAM
    .ext_ram_we_n       (ext_ram_we_n),     // �����EXTRAM
    
    // �����ź�
    .txd                (txd),
    .rxd                (rxd),
    .txd_busy           (txd_busy),
    .state              (state)
);

// ---------------- ԭ�Ӳ���������� ----------------
// SC�������������ʵ�֣����ǳɹ���
assign SC_result = 1'b1;

// ---------------- �ж��źŴ��� ----------------
// �ж��źŴ�����ʵ�֣���ʱû���ⲿ�жϣ�
assign EXTI = 1'b0;
assign IF_EXTI = 1'b0;

// ---------------- BRAMģ������ ----------------
BRAM u_bram (
    .clk        (clk_CPU),
    .rst        (reset_of_clkCPU),
    .addr_i     (base_ram_addr),        // ��ַ�ź�
    .rdata      (base_ram_rdata),       // ���������
    .wdata      (base_ram_wdata),       // д��������
    .wen_i      (base_ram_we_n),       
    .sel        (base_ram_be_n),       
    .en_i       (base_ram_ce_n)        
);

// ---------------- EXTRAMģ������ ----------------
EXTRAM u_extram (
    .clk        (clk_CPU),
    .rst        (reset_of_clkCPU),
    .addr_i     (ext_ram_addr),         // ��ַ�ź�
    .rdata      (ext_ram_rdata),        // ���������
    .wdata      (ext_ram_wdata),        // д��������
    .wen_i      (ext_ram_we_n),        // 
    .sel        (ext_ram_be_n),        // 
    .en_i       (ext_ram_ce_n)         // 
);

endmodule
