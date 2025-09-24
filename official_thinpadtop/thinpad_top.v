`default_nettype wire
module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�����"ON"ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽʱ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_CPU, clk_20M;
clk_wiz_0 clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // �ⲿʱ������
  // Clock out ports
  .clk_out1(clk_CPU), // ʱ�����1��Ƶ����IP���ý��������� 59M
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý��������� 20M
  // Status and control signals
  .reset(reset_btn), // PLL��λ����
  .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                     // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
 );
wire  reset_of_clkCPU =reset_btn;

// ---------- ����� CPU �� �ڴ�/���� ������ ��ʵ�������� ----------

// �� Saiun_Kai/Ram_Serial_ctrl ���ӵ��ڲ������ź�
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

// �����жϣ����û���ⲿ�ж��ߣ������ͣ�
wire        exti_n = 1'b0; // EXTI = 0 (�����ж�)

// ���Ӷ���� Base/Ext RAM �� �����ߵ� Ram_Serial_ctrl
// ע�⣺top ģ������ base_ram_* / ext_ram_* / txd/rxd �ȶ˿�

// ʵ���� Saiun_Kai��CPU/���أ�
Saiun_Kai u_saiun_kai (
    .clk      (clk_CPU),          // ���� PLL �� CPU ʱ��
    .rst      (reset_of_clkCPU),  // ��λ���ߵ�ƽ��Ч������� reset_of_clkCPU ����һ�£�
    // �ô�ӿڣ���� -> Ram_Serial_ctrl��
    .mem_addr (cpu_mem_addr),
    .mem_wdata(cpu_mem_wdata),
    .mem_rdata(cpu_mem_rdata),
    .mem_sel_n(cpu_mem_sel_n),
    .mem_en   (cpu_mem_en),
    .mem_wen_n(cpu_mem_wen_n),
    .mem_done (cpu_mem_done),
    // ԭ�Ӳ�����ͬ��
    .LL       (cpu_LL),
    .SC       (cpu_SC),
    .SC_result(cpu_SC_result),    // Ŀǰ���ⲿ���ͣ������棩
    // �쳣 / �ж�
    .EXTI     (exti_n)
);

// �����������Ҫ SC_result��store-conditional �������
 // ��Ҫ��ʵ���߼����������ǰ���� 0 ��ʾʧ�ܣ��ɰ���ģ���
assign cpu_SC_result = 1'b1;

// ʵ���� Ram_Serial_ctrl������ Base/Ext RAM �� ���ڵ��ٲã�
Ram_Serial_ctrl u_ram_serial_ctrl (
    .clk            (clk_CPU),
    .rst            (reset_of_clkCPU),

    // ͳһ�ķô�ӿڣ����� Saiun_Kai��
    .mem_rdata      (cpu_mem_rdata),   // Ram_Serial_ctrl ����� CPU �Ķ�����
    .mem_addr       (cpu_mem_addr),    // CPU ��ַ����
    .mem_wdata      (cpu_mem_wdata),   // CPU д��������
    .mem_we_n       (cpu_mem_wen_n),   // дʹ�ܣ�����Ч��
    .mem_sel_n      (cpu_mem_sel_n),   // �ֽ�ѡ�񣨵���Ч��
    .mem_ce_i       (cpu_mem_en),      // Ƭѡ / ��Ч������Ч��

    // BaseRAM �ź�ֱ������������
    .base_ram_data  (base_ram_data),
    .base_ram_addr  (base_ram_addr),
    .base_ram_be_n  (base_ram_be_n),
    .base_ram_ce_n  (base_ram_ce_n),
    .base_ram_oe_n  (base_ram_oe_n),
    .base_ram_we_n  (base_ram_we_n),

    // ExtRAM �ź�ֱ������������
    .ext_ram_data   (ext_ram_data),
    .ext_ram_addr   (ext_ram_addr),
    .ext_ram_be_n   (ext_ram_be_n),
    .ext_ram_ce_n   (ext_ram_ce_n),
    .ext_ram_oe_n   (ext_ram_oe_n),
    .ext_ram_we_n   (ext_ram_we_n),

    // ֱ�����ڣ��붥�� txd/rxd ֱ�����ӣ�
    .txd            (txd),
    .rxd            (rxd),
    .txd_busy       (),       // ��ѡδ���ӣ�Ram_Serial_ctrl ����� txd_busy/state
    .state          ()        // ��ѡδ����
);


endmodule