
`define SerialState 32'hBFD003FC //����״̬��ַ
`define SerialData 32'hBFD003F8  //�������ݵ�ַ

module Ram_Serial_ctrl (
    input wire clk,
    input wire rst,
    
    //ͳһ�ķô�ӿ�
    output reg[31:0] mem_rdata,     //��ȡ������
    input wire[31:0] mem_addr,      //����д����ַ
    input wire[31:0] mem_wdata,     //д�������
    input wire mem_we_n,            //дʹ�ܣ�����Ч
    input wire[3:0] mem_sel_n,      //�ֽ�ѡ���ź�
    input wire mem_ce_i,            //Ƭѡ�ź�
    
    //BaseRAM�ź� - �����
    output wire[31:0] base_ram_wdata,   //BaseRAMд�������
    input wire[31:0] base_ram_rdata,    //BaseRAM����������
    output wire [19:0] base_ram_addr,   //BaseRAM��ַ
    output wire [3:0] base_ram_be_n,    //BaseRAM�ֽ�ʹ�ܣ�����Ч
    output wire base_ram_ce_n,          //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,          //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,          //BaseRAMдʹ�ܣ�����Ч
    
    //ExtRAM�ź� - �����
    output wire[31:0] ext_ram_wdata,    //ExtRAMд�������
    input wire[31:0] ext_ram_rdata,     //ExtRAM����������
    output wire [19:0] ext_ram_addr,    //ExtRAM��ַ
    output wire [3:0] ext_ram_be_n,     //ExtRAM�ֽ�ʹ�ܣ�����Ч
    output wire ext_ram_ce_n,           //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,           //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,           //ExtRAMдʹ�ܣ�����Ч
    
    //ֱ�������ź�
    output wire txd,        //ֱ�����ڷ��Ͷ�
    input wire rxd,         //ֱ�����ڽ��ն�
    output wire txd_busy,
    output wire[1:0] state  //����״̬
);

// ��������ź�
wire [7:0] RxD_data;        //���յ�������
reg [7:0] TxD_data;         //�����͵�����
wire RxD_data_ready;        //�������յ��������֮����Ϊ1
wire TxD_busy;              //������״̬�Ƿ�æµ��1Ϊæµ��0Ϊ��æµ
reg TxD_start;              //�������Ƿ���Է������ݣ�1������Է���
reg RxD_clear;              //Ϊ1ʱ��������ձ�־��ready�źţ�

// �ڴ�ӳ�������ж�
wire is_SerialState = (mem_addr == `SerialState);
wire is_SerialData = (mem_addr == `SerialData);
wire is_base_ram = (mem_addr >= 32'h80000000) && (mem_addr < 32'h80400000);
wire is_ext_ram = (mem_addr >= 32'h80400000) && (mem_addr < 32'h80800000);

// ��������ź�
reg [31:0] serial_data;     //�����������

assign txd_busy = TxD_busy;
assign state = {RxD_data_ready, !TxD_busy};

//����ʵ����ģ�飬������9600
 (* dont_touch = "true" *) async_receiver #(.ClkFrequency(50_000000),.Baud(9600)) //����ģ��
    ext_uart_r(
        .clk(clk),                      //�ⲿʱ���ź�
        .RxD(rxd),                      //�ⲿ�����ź�����
        .RxD_data_ready(RxD_data_ready), //���ݽ��յ���־
        .RxD_clear(RxD_clear),          //������ձ�־
        .RxD_data(RxD_data)             //���յ���һ�ֽ�����
    );

 (* dont_touch = "true" *) async_transmitter #(.ClkFrequency(50_000000),.Baud(9600)) //����ģ��
    ext_uart_t(
        .clk(clk),              //�ⲿʱ���ź�
        .TxD(txd),              //�����ź����
        .TxD_busy(TxD_busy),    //������æ״ָ̬ʾ
        .TxD_start(TxD_start),  //��ʼ�����ź�
        .TxD_data(TxD_data)     //�����͵�����
    );

// �������ݴ���
always @(*) begin
    TxD_start = 1'b0;
    serial_data = 32'h00000000;
    TxD_data = 8'h00;
    RxD_clear = 1'b0;
    
    if(is_SerialState && mem_ce_i) begin
        // ������״̬
        serial_data = {{30{1'b0}}, {RxD_data_ready, !TxD_busy}};
    end else if(is_SerialData && mem_ce_i) begin
        if(mem_we_n) begin
            // ������
            serial_data = {24'h000000, RxD_data};
            RxD_clear = RxD_data_ready; // ��ȡ���ݺ����ready��־
        end else if(!TxD_busy) begin
            // д���ݣ����ͣ�
            TxD_data = mem_wdata[7:0];
            TxD_start = 1'b1;
            serial_data = 32'h00000000;
        end
    end
end

// BaseRAM�����߼� - �����
assign base_ram_wdata = mem_wdata;              // д����ֱ�����
assign base_ram_addr = mem_addr[21:2];          // �ж���Ҫ�󣬵���λ��ȥ
assign  base_ram_be_n = base_ram_ce_n ? 4'b1:mem_sel_n;
assign base_ram_oe_n = mem_we_n;                // ������ʱΪ0��mem_we_nΪ1ʱ�Ƕ�������
assign base_ram_we_n = mem_we_n;                // д����ʱΪ0
assign base_ram_ce_n = !(is_base_ram && mem_ce_i);

// ExtRAM�����߼� - �����
assign ext_ram_wdata = mem_wdata;               // д����ֱ�����
assign ext_ram_addr = mem_addr[21:2];           // �ж���Ҫ�󣬵���λ��ȥ
assign  ext_ram_be_n = ext_ram_ce_n ? 4'b1:mem_sel_n;
assign ext_ram_oe_n = mem_we_n;                 // ������ʱΪ0��mem_we_nΪ1ʱ�Ƕ�������
assign ext_ram_we_n = mem_we_n;                 // д����ʱΪ0
assign ext_ram_ce_n = !(is_ext_ram && mem_ce_i);

// ͳһ�������������
always @(*) begin
    mem_rdata = 32'b0;
    
    if(!mem_ce_i) begin
        mem_rdata =32'b0;
    end else if(is_SerialState || is_SerialData) begin
        mem_rdata = serial_data;
    end else if(is_base_ram) begin
        // �����ֽ�ѡ���źŴ���BaseRAM����
        case (mem_sel_n)
            4'b1110: begin // ��ȡ����ֽڣ�������չ
                mem_rdata = {{24{base_ram_rdata[7]}}, base_ram_rdata[7:0]};
            end
            4'b1101: begin // ��ȡ�ڶ��ֽڣ�������չ
                mem_rdata = {{24{base_ram_rdata[15]}}, base_ram_rdata[15:8]};
            end
            4'b1011: begin // ��ȡ�����ֽڣ�������չ
                mem_rdata = {{24{base_ram_rdata[23]}}, base_ram_rdata[23:16]};
            end
            4'b0111: begin // ��ȡ����ֽڣ�������չ
                mem_rdata = {{24{base_ram_rdata[31]}}, base_ram_rdata[31:24]};
            end
            4'b0000: begin // ��ȡ������
                mem_rdata = base_ram_rdata;
            end
            default: begin
                mem_rdata = base_ram_rdata;
            end
        endcase
    end else if(is_ext_ram) begin
        // �����ֽ�ѡ���źŴ���ExtRAM����
        case (mem_sel_n)
            4'b1110: begin // ��ȡ����ֽڣ�������չ
                mem_rdata = {{24{ext_ram_rdata[7]}}, ext_ram_rdata[7:0]};
            end
            4'b1101: begin // ��ȡ�ڶ��ֽڣ�������չ
                mem_rdata = {{24{ext_ram_rdata[15]}}, ext_ram_rdata[15:8]};
            end
            4'b1011: begin // ��ȡ�����ֽڣ�������չ
                mem_rdata = {{24{ext_ram_rdata[23]}}, ext_ram_rdata[23:16]};
            end
            4'b0111: begin // ��ȡ����ֽڣ�������չ
                mem_rdata = {{24{ext_ram_rdata[31]}}, ext_ram_rdata[31:24]};
            end
            4'b0000: begin // ��ȡ������
                mem_rdata = ext_ram_rdata;
            end
            default: begin
                mem_rdata = ext_ram_rdata;
            end
        endcase
    end
end

endmodule