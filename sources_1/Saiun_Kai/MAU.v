module MAU (
    //=============================================
    // ȫ��ʱ�Ӻ͸�λ
    //=============================================
    input  wire         clk,
    input  wire         rst,
   
    //=============================================
    // ָ��ô�ӿ�
    //=============================================
    input  wire [31:0]  inst_addr,         
    output wire [31:0]  inst_rdata,        
    input  wire         inst_ce,           
    input  wire         inst_done,         // ָ��ô�����ź� (���Դ洢��)
    input  wire        branch,
   input wire          iq_full, 
    //=============================================
    // ���ݷô�ӿ�  
    //=============================================
    input  wire [31:0]  data_addr,         
    input  wire [31:0]  data_wdata,        
    output wire [31:0]  data_rdata,        
    input  wire [3:0]   data_sel_n,        
    input  wire         data_ce,           
    input  wire         data_wen_n,        
    input  wire         data_done,         // ���ݷô�����ź� (���Դ洢��)

    //=============================================
    // ԭ�Ӳ��������ź�
    //=============================================
    input  wire         ll_i,              
    input  wire         sc_i,              

    //=============================================
    // �ٲÿ������
    //=============================================
    output wire         front_stall,       
    output wire         back_stall,        // <-- ���� back_stall ���

    //=============================================
    // �洢�����߽ӿ�
    //=============================================
    output wire [31:0]  mem_addr,          
    output wire [31:0]  mem_wdata,         
    input  wire [31:0]  mem_rdata,         
    output wire [3:0]   mem_sel,           
    output wire         mem_en,            
    output wire         mem_wen_n,         
    output wire         ll_o,              
    output wire         sc_o,              
    output wire         mem_done           
);

//=============================================
// ״̬������
//=============================================
localparam S_IDLE       = 2'b00; // ����״̬
localparam S_GRANT_INST = 2'b01; // ��Ȩ��ָ��ô�
localparam S_GRANT_DATA = 2'b10; // ��Ȩ�����ݷô�

reg [1:0] state, next_state;

//=============================================
// �ڲ��źŶ���
//=============================================
wire data_access_req;       // ���ݷô�����
wire inst_access_req;       // ָ��ô�����  
wire grant_data;            // ������Ȩ�����ݷô�
wire grant_inst;            // ������Ȩ��ָ��ô�

// �����ź�
assign data_access_req = data_ce;
assign inst_access_req = inst_ce&&!iq_full;

// ��Ȩ�ź��ɵ�ǰ״̬����
assign grant_inst = (state == S_GRANT_INST);
assign grant_data = (state == S_GRANT_DATA);

//=============================================
// ״̬��ʱ���߼� (״̬�Ĵ���)
//=============================================
always @(posedge clk ) begin
    if (rst) begin
        state <= S_IDLE;
    end else begin
        state <= next_state;
    end
end

//=============================================
// ״̬������߼� (��һ״̬�߼�)
//=============================================
always @(*) begin
    next_state = state; // Ĭ�ϱ��ֵ�ǰ״̬
    case (state)
        S_IDLE: begin
            // �ڿ���״̬�£����ݷô�������Ȩ
            if (data_access_req) begin
                next_state = S_GRANT_DATA;
            end else if (inst_access_req) begin
                next_state = S_GRANT_INST;
            end
        end

        S_GRANT_INST: begin
            // �ȴ�ָ��ô����
            if (inst_done|branch) begin
                    next_state = S_IDLE;
                end
            end
     

        S_GRANT_DATA: begin
            // �ȴ����ݷô����
            if (data_done) begin
               
                    next_state = S_IDLE;
              
            end
        end

        default: begin
            next_state = S_IDLE;
        end
    endcase
end

//=============================================
// �����������߼�
//=============================================

// ��ָ��ô��������ߣ������߱����ݷô�ռ��(�򼴽�ռ��)ʱ����ͣǰ��
assign front_stall = inst_access_req & (grant_data | (state == S_IDLE & data_access_req));

// �����ݷô��������ߣ������߱�ָ��ô�ռ��ʱ����ͣ���
assign back_stall = data_access_req & !grant_data; // <-- ���� back_stall �߼�

// ��ַ���߸���
assign mem_addr = grant_data ? data_addr : 
                  grant_inst ? inst_addr : 
                  32'h0;

// д�������߸���
assign mem_wdata = grant_data ? data_wdata : 32'h0;

// �ֽ�ѡ���źŸ��� (����Ϊ����Ч)
assign mem_sel = grant_data ? data_sel_n :
                 grant_inst ? 4'b0000 :      // ָ��ô�����ȫ��
                 4'b0000;                   // ����ʱ��ѡ��

// ����ʹ��
assign mem_en = grant_data | grant_inst;

// дʹ���ź� (����Ч)��ֻ�����ݷô�ʱ��Ч
assign mem_wen_n = grant_data ? data_wen_n : 1'b1;

// ԭ�Ӳ����źţ�ֻ�����ݷô�ʱ͸��
assign ll_o = grant_data ? ll_i : 1'b0;
assign sc_o = grant_data ? sc_i : 1'b0;

// ��ǰ�����Ȩ�ĵ�Ԫ��������ź�
assign mem_done = (grant_inst & inst_done) | (grant_data & data_done);

// ������ͨ·
assign inst_rdata = grant_inst ? mem_rdata : 32'h0;
assign data_rdata = grant_data ? mem_rdata : 32'h0;

endmodule