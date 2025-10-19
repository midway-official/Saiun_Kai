module FU (
    input wire clk,
    input wire rst,
    input wire backend_stall,
    // ����׶������źţ�ȥ��pipeline1ǰ׺��
    input wire valid_i,
    output wire ready_o,
    input wire [15:0] alu_op_i,
    input wire [31:0] src1_data_i,
    input wire [3:0] src1_i,
    input wire [31:0] src2_data_i,
    input wire [3:0] src2_i,
    input wire [31:0] mem_wdata_i,
    input wire [31:0] pc_i,
    input wire is_branch_i,
    input wire pred_taken_i,
    input wire is_conditional_branch_i,
    input wire is_jirl_i,
    input wire is_b_i,
    input wire is_bl_i,
    input wire [31:0] br_offs_i,
    input wire [31:0] jirl_offs_i,
    input wire [4:0] dest_i,
    input wire [4:0] special_i,
    input wire [4:0] mem_op_i,
    input wire [4:0] rd_i,
    input wire gr_we_i,
    input wire mem_we_i,
    input wire res_from_mem_i,
    
    // ��ˮ�߿����ź�
    input wire is_ex_stall,
    input wire is_ex_nop,
    input wire ex_mem_stall,
    input wire ex_mem_nop,
    input wire mem_wb_stall,
    input wire mem_wb_nop,
    //loaduseð�պͷô�
    output wire ex_is_load,
    output wire mem_stall,
    input wire [31:0] ex1_r,
    input wire  [31:0]ex2_r,
    input wire  [31:0]mem1_r,
    input wire  [31:0]mem2_r,
    
    
    // �ô�ӿ�
    output wire [31:0] mem_addr,
    output wire [31:0] mem_data,
    output wire        mem_we_n,
    output wire [3:0]  mem_sel_n,
    output wire        mem_ready,
    output wire        mem_ce,
    output wire        mem_ll,
    output wire        mem_sc,
    input wire        mem_sc_success,
    input  wire [31:0] mem_data_i,
    
    // д�ؼĴ����ѿ����ź�
    output wire [4:0]  wb_dest_o,
    output wire        wb_gr_we_o,
    output wire [31:0] wb_data_o,
    //ǰ������
    output wire [4:0]  ex_dest_o,
    output wire        ex_gr_we_o,
    output wire [31:0] ex_wdata_o,
    output wire [4:0]  mem_dest_o,
    output wire           mem_gr_we_o,
    output wire [31:0] mem_wdata_o,
    // ��֧��ת���
    output wire        branch_taken_o,
    output wire [31:0] branch_target_o

);


 assign    ready_o=valid_i&&!mem_stall;
   
// ============================================================================
// IS_EX ��ˮ�߼Ĵ���
// ============================================================================
reg is_ex_valid;
reg [15:0] is_ex_alu_op;
reg [31:0] is_ex_src1_data;
reg [31:0] is_ex_src2_data;
reg [3:0] is_ex_src1;
reg [3:0] is_ex_src2;
reg [31:0] is_ex_mem_wdata;
reg [31:0] is_ex_pc;
reg is_ex_is_branch;
reg is_ex_pred_taken;
reg is_ex_is_conditional_branch;
reg is_ex_is_jirl;
reg is_ex_is_b;
reg is_ex_is_bl;
reg [31:0] is_ex_br_offs;
reg [31:0] is_ex_jirl_offs;
reg [4:0] is_ex_dest;
reg [4:0] is_ex_special;
reg [4:0] is_ex_mem_op;
reg [4:0] is_ex_rd;
reg is_ex_gr_we;
reg is_ex_mem_we;
reg is_ex_res_from_mem;

always @(posedge clk) begin
    if (rst) begin
        is_ex_valid <= 1'b0;
        is_ex_alu_op <= 16'b0;
        is_ex_src1_data <= 32'b0;
        is_ex_src2_data <= 32'b0;
        is_ex_src1 <= 4'b0;
        is_ex_src2 <= 4'b0;
        is_ex_mem_wdata <= 32'b0;
        is_ex_pc <= 32'b0;
        is_ex_is_branch <= 1'b0;
        is_ex_pred_taken <= 1'b0;
        is_ex_is_conditional_branch <= 1'b0;
        is_ex_is_jirl <= 1'b0;
        is_ex_is_b <= 1'b0;
        is_ex_is_bl <= 1'b0;
        is_ex_br_offs <= 32'b0;
        is_ex_jirl_offs <= 32'b0;
        is_ex_dest <= 5'b0;
        is_ex_special <= 5'b0;
        is_ex_mem_op <= 5'b0;
        is_ex_rd <= 5'b0;
        is_ex_gr_we <= 1'b0;
        is_ex_mem_we <= 1'b0;
        is_ex_res_from_mem <= 1'b0;
    end else if (is_ex_nop) begin
        // nop���ȼ�����stall�������ˮ�߼Ĵ���
        is_ex_valid <= 1'b0;
        is_ex_alu_op <= 16'b0;
        is_ex_src1_data <= 32'b0;
        is_ex_src2_data <= 32'b0;
        is_ex_src1 <= 4'b0;
        is_ex_src2 <= 4'b0;
        is_ex_mem_wdata <= 32'b0;
        is_ex_pc <= 32'b0;
        is_ex_is_branch <= 1'b0;
        is_ex_pred_taken <= 1'b0;
        is_ex_is_conditional_branch <= 1'b0;
        is_ex_is_jirl <= 1'b0;
        is_ex_is_b <= 1'b0;
        is_ex_is_bl <= 1'b0;
        is_ex_br_offs <= 32'b0;
        is_ex_jirl_offs <= 32'b0;
        is_ex_dest <= 5'b0;
        is_ex_special <= 5'b0;
        is_ex_mem_op <= 5'b0;
        is_ex_rd <= 5'b0;
        is_ex_gr_we <= 1'b0;
        is_ex_mem_we <= 1'b0;
        is_ex_res_from_mem <= 1'b0;
    end else if (!is_ex_stall) begin
        // ������ˮ
        is_ex_valid <= valid_i;
        is_ex_alu_op <= alu_op_i;
        is_ex_src1_data <= src1_data_i;
        is_ex_src2_data <= src2_data_i;
        is_ex_src1 <= src1_i;
        is_ex_src2<= src2_i;
        is_ex_mem_wdata <= mem_wdata_i;
        is_ex_pc <= pc_i;
        is_ex_is_branch <= is_branch_i;
        is_ex_pred_taken <= pred_taken_i;
        is_ex_is_conditional_branch <= is_conditional_branch_i;
        is_ex_is_jirl <= is_jirl_i;
        is_ex_is_b <= is_b_i;
        is_ex_is_bl <= is_bl_i;
        is_ex_br_offs <= br_offs_i;
        is_ex_jirl_offs <= jirl_offs_i;
        is_ex_dest <= dest_i;
        is_ex_special <= special_i;
        is_ex_mem_op <= mem_op_i;
        is_ex_rd <= rd_i;
        is_ex_gr_we <= gr_we_i;
        is_ex_mem_we <= mem_we_i;
        is_ex_res_from_mem <= res_from_mem_i;
    end
    // stallʱ����ԭֵ����
end

// ============================================================================
// ִ�н׶��߼�
// ============================================================================
wire [31:0] ex_alu_result;
wire        ex_branch_taken;
wire [31:0] ex_branch_target;
wire  [31:0] src1,src2,mem_wdata;
assign src1 = is_ex_src1[3] ? ex2_r  :
               is_ex_src1[2] ? ex1_r  :
               is_ex_src1[1] ? mem2_r :
               is_ex_src1[0] ? mem1_r :
                               is_ex_src1_data;

assign src2 = is_ex_src2[3] ? ex2_r  :
               is_ex_src2[2] ? ex1_r  :
               is_ex_src2[1] ? mem2_r :
               is_ex_src2[0] ? mem1_r :
                               is_ex_src2_data;
assign mem_wdata =is_ex_src2[3] ? ex2_r  :
               is_ex_src2[2] ? ex1_r  :
               is_ex_src2[1] ? mem2_r :
               is_ex_src2[0] ? mem1_r :
                               is_ex_mem_wdata;
// ALU�����߼�
alu_unit u_alu (
    .alu_op(is_ex_alu_op),
    .src1(src1),
    .src2(src2),
    .result(ex_alu_result)
);

// ��֧��ת�߼�
branch_unit u_branch (
    .pc(is_ex_pc),
    .is_branch(is_ex_is_branch),
    .is_conditional_branch(is_ex_is_conditional_branch),
    .is_jirl(is_ex_is_jirl),
    .is_b(is_ex_is_b),
    .is_bl(is_ex_is_bl),
    .br_offs(is_ex_br_offs),
    .jirl_offs(is_ex_jirl_offs),
    .alu_op(is_ex_alu_op),
    .src1(src1),
    .src2(src2),
    .pred_taken(is_ex_pred_taken),
    .branch_taken(ex_branch_taken),
    .branch_target(ex_branch_target)
);
assign ex_is_load =is_ex_res_from_mem;
assign ex_dest_o=is_ex_dest;
assign ex_gr_we_o=is_ex_gr_we;
assign ex_wdata_o = (is_ex_res_from_mem) ? 32'b0 : 
                    (is_ex_is_jirl    ) ? (is_ex_pc + 32'd4) : 
                                          ex_alu_result;
wire[31:0]  ex_jirl_addr=is_ex_pc + 32'd4;
// ============================================================================
// �ô���Ƶ�Ԫ����
// ============================================================================
wire        ex_mem_we_n;
wire [3:0]  ex_mem_sel_n;
wire        ex_mem_ce_o;


mem_ctrl_unit u_mem_ctrl_unit (
    .mem_op       (is_ex_mem_op),       // �ô�������� (load/store, byte/word)
    .addr         (ex_alu_result),      // ALU ������ķô��ַ
    .mem_we       (is_ex_mem_we),       // �Ƿ�Ϊд����
    .res_from_mem (is_ex_res_from_mem), // �Ƿ������ڴ棨load ָ�
    .mem_we_n     (ex_mem_we_n),        // ���: дʹ�ܣ�����Ч��
    .mem_sel_n    (ex_mem_sel_n),       // ���: �ֽ�ѡͨ�źţ�����Ч��
    .mem_ce_o     (ex_mem_ce_o)         // ���: Ƭѡ�ź�
);

// ============================================================================
// EX_MEM ��ˮ�߼Ĵ���
// ============================================================================
//�������ݼĴ���
reg ex_mem_valid;
reg [31:0] ex_mem_alu_result;
reg [31:0] ex_mem_pc;          // ����������������쳣����ȣ�
reg [31:0] ex_mem_branch_target;         
reg ex_mem_branch_taken;         
//�Ĵ�����д
reg ex_mem_gr_we;
reg [4:0] ex_mem_dest;           // Ŀ��Ĵ������

//�ô��źżĴ���
reg [31:0] ex_mem_mem_wdata;
reg [3:0] ex_mem_mem_sel_n;
reg ex_mem_mem_we_n;
reg ex_mem_mem_ce;
reg ex_mem_jirl;
reg [31:0] ex_mem_jirl_addr;
// �������
reg [4:0] ex_mem_special;       
 


always @(posedge clk) begin
    if (rst) begin
        // ��λʱ�������мĴ���
        ex_mem_valid <= 1'b0;
        ex_mem_jirl <= 1'b0;
        ex_mem_alu_result <= 32'b0;
        ex_mem_jirl_addr<= 32'b0;
        ex_mem_pc <= 32'b0;
        ex_mem_gr_we <= 1'b0;
        ex_mem_dest <= 5'b0;
        ex_mem_mem_wdata <= 32'b0;
        
        ex_mem_mem_sel_n <= 4'b1111;      // Ĭ�ϲ�ѡ���κ��ֽ�
        ex_mem_mem_we_n <= 1'b1;      // Ĭ�ϲ�д
        ex_mem_mem_ce <= 1'b0;        // Ĭ�ϲ�Ƭѡ
        ex_mem_special <= 5'b0;
        ex_mem_branch_target <= 32'b0;
        ex_mem_branch_taken <= 1'b0;
    end else if (ex_mem_nop) begin
        // nop���ȼ�����stall�������ˮ�߼Ĵ���
        ex_mem_valid <= 1'b0;
        ex_mem_jirl <= 1'b0;
        ex_mem_jirl_addr<= 32'b0;
        ex_mem_alu_result <= 32'b0;
        ex_mem_pc <= 32'b0;
        ex_mem_gr_we <= 1'b0;
        ex_mem_dest <= 5'b0;
        ex_mem_mem_wdata <= 32'b0;
        ex_mem_mem_sel_n <= 4'b1111;
        ex_mem_mem_we_n <= 1'b1;
        ex_mem_mem_ce <= 1'b0;
        ex_mem_special <= 5'b0;
        ex_mem_branch_target <= 32'b0;
        ex_mem_branch_taken <= 1'b0;
    end else if (!ex_mem_stall) begin
        // ������ˮ
        ex_mem_valid <= is_ex_valid;
        ex_mem_jirl <=is_ex_is_jirl  ;
        ex_mem_jirl_addr<= ex_jirl_addr;
        ex_mem_alu_result <= ex_alu_result;
        ex_mem_pc <= is_ex_pc;
        ex_mem_gr_we <= is_ex_gr_we;
        ex_mem_dest <= is_ex_dest;
        ex_mem_mem_wdata <= mem_wdata;
        ex_mem_mem_sel_n <= ex_mem_sel_n;
        ex_mem_mem_we_n <= ex_mem_we_n;
        ex_mem_mem_ce <= ex_mem_ce_o;
        ex_mem_special <= is_ex_special;
        ex_mem_branch_target <= ex_branch_target;
        ex_mem_branch_taken <=  ex_branch_taken;
    end
    // stallʱ����ԭֵ����
end

wire is_SerialState = (ex_mem_alu_result == `SerialState);
wire is_SerialData  = (ex_mem_alu_result== `SerialData);
wire is_core_addr   = (ex_mem_alu_result == 32'hBFD10000)|(ex_mem_alu_result== 32'hBFD10004);

wire is_special_io  = is_SerialState || is_SerialData || is_core_addr;
wire needs_fsm      =ex_mem_mem_ce  && !is_special_io;

// ----------- State Machine Definition -----------
parameter IDLE  = 3'b000;
parameter REQ   = 3'b001; // Note: REQ state is unreachable in the refactored logic, kept for reference
parameter WAIT1 = 3'b010;
parameter WAIT2 = 3'b011;
parameter WAIT3 = 3'b111;
parameter WAIT4 = 3'b101;
parameter DONE  = 3'b100;

reg [2:0] mem_state;
wire[2:0] mem_state_next;



// ----------- Sequential Logic: State Register (UNCHANGED) -----------
// ״̬��ʱ�Ӹ����߼� - ����EXTI��ͣ����
always @(posedge clk or posedge rst) begin
    if (rst)
        mem_state <= IDLE;
  else
  if (backend_stall)
      mem_state <= mem_state; // EXTI��Чʱ��״̬�����ֵ�ǰ״̬���䣨��ͣ��
    else
        mem_state <= mem_state_next;
end


// ----------- Combinational Logic: Flattened with Assigns -----------

// ** REFACTORED ** State transition and Dcache active logic
assign mem_state_next = 
    (mem_state == IDLE)  ? (needs_fsm  ? WAIT1 : IDLE) :
    //(mem_state == REQ)   ? ... // REQ state is now unreachable
    (mem_state == WAIT1) ? WAIT2 :
    (mem_state == WAIT2) ? WAIT3 :
    (mem_state == WAIT3) ? WAIT4 :
    (mem_state == WAIT4) ? DONE  :
    (mem_state == DONE)  ? IDLE  :
                           IDLE; // Default case
                           
assign mem_stall = (mem_state == IDLE) ? (needs_fsm ) : (mem_state != DONE);
assign mem_addr=ex_mem_alu_result;
assign mem_data = (ex_mem_mem_we_n == 1'b1) ? 32'b0 :   // ��д �� ȫ0
                    (ex_mem_mem_sel_n != 4'b0000) ? 
                        {4{ex_mem_mem_wdata[7:0]}} : 
                        ex_mem_mem_wdata;
assign mem_sel_n= ex_mem_mem_sel_n;
assign mem_we_n= ex_mem_mem_we_n;
assign mem_ce= ex_mem_mem_ce;
assign   mem_ll=(ex_mem_special==5'd1);
assign   mem_sc=(ex_mem_special==5'd2);
assign  mem_ready= (mem_state == DONE)|is_special_io;
// �����ڴ������
wire [31:0] mem_result = mem_data_i;

// д��������Դѡ��
//  - ����� Load ָ���Ҫ���ڴ��������д�� mem_result
//  - ����д�� ALU ������
wire mem_res_from_mem = (ex_mem_mem_ce && ex_mem_mem_we_n == 1'b1);  

wire [31:0] mem_wdata_pre = (ex_mem_jirl&&mem_dest_o!=5'b0)       ? ex_mem_jirl_addr :
                            mem_res_from_mem ? mem_result        :
                                               ex_mem_alu_result;
// LL/SC ���⴦��
assign mem_wdata_o = (ex_mem_special == 5'd2) ? {31'b0, mem_sc_success} :// SC �ɹ����
                      mem_wdata_pre;
assign mem_dest_o=ex_mem_dest;
assign mem_gr_we_o=ex_mem_gr_we;

// ============================================================================
// MEM_WB ��ˮ�߼Ĵ���
// ============================================================================
reg mem_wb_valid;
reg [31:0] mem_wb_wdata;
reg [4:0] mem_wb_dest;
reg mem_wb_gr_we;


always @(posedge clk) begin
    if (rst) begin
        mem_wb_valid <= 1'b0;
        mem_wb_gr_we <= 1'b0;
        mem_wb_wdata <= 32'b0;
        mem_wb_dest <=5'b0;
    end else if (mem_wb_nop) begin
        mem_wb_valid <= 1'b0;
        mem_wb_gr_we <= 1'b0;
        mem_wb_wdata <= 32'b0;
        mem_wb_dest <=5'b0;
    end else if (!mem_wb_stall) begin
        mem_wb_valid <= ex_mem_valid;
        mem_wb_gr_we <= ex_mem_gr_we;
        mem_wb_wdata <= mem_wdata_o;
        mem_wb_dest <= ex_mem_dest;
    end
end

// ============================================================================
// д�ؽ׶��߼�
// ============================================================================
assign wb_dest_o = mem_wb_dest;
assign wb_gr_we_o = mem_wb_gr_we && mem_wb_valid;
assign wb_data_o = mem_wb_wdata;

// ============================================================================
// ��֧��ת���
// ============================================================================
assign branch_taken_o = ex_mem_branch_taken ;
assign branch_target_o = ex_mem_branch_target;


endmodule


module FU_R (
    input  wire         clk,
    input  wire         rst,

    // ����׶����루�򻯺�
    input  wire         valid_i,
     output  wire        ready_o,
    input  wire [15:0]  alu_op_i,
    input wire [31:0] src1_data_i,
    input wire [3:0] src1_i,
    input wire [31:0] src2_data_i,
    input wire [3:0] src2_i,
    input  wire [4:0]   dest_i,
    input  wire         gr_we_i,
    input wire [31:0] ex1_r,
    input wire  [31:0]ex2_r,
    input wire  [31:0]mem1_r,
    input wire  [31:0]mem2_r,
    // ��ˮ�߿����źţ����ֺ�ԭģ��һ�µĽӿڷ��
    input  wire         is_ex_stall,
    input  wire         is_ex_nop,
    input  wire         ex_mem_stall,
    input  wire         ex_mem_nop,
    input  wire         mem_wb_stall,
    input  wire         mem_wb_nop,

    // ǰ�����磨EX stage �������
    output wire [4:0]   ex_dest_o,
    output wire         ex_gr_we_o,
    output wire [31:0]  ex_wdata_o,

    // ǰ������ / д�� MEM stage��EX->MEM��
    output wire [4:0]   mem_dest_o,
    output wire         mem_gr_we_o,
    output wire [31:0]  mem_wdata_o,
     
    // д�ؼĴ����ѿ����źţ�WB��
    output wire [4:0]   wb_dest_o,
    output wire         wb_gr_we_o,
    output wire [31:0]  wb_data_o
);

   assign  ready_o=valid_i;
   

// ============================================================================
// IS_EX ��ˮ�߼Ĵ����������뵽ִ�У�
reg                 is_ex_valid;
reg [15:0]          is_ex_alu_op;
reg [31:0]          is_ex_src1_data;
reg [3:0]          is_ex_src1;
reg [31:0]          is_ex_src2_data;
reg [3:0]          is_ex_src2;
reg [4:0]           is_ex_dest;
reg                 is_ex_gr_we;

always @(posedge clk) begin
    if (rst) begin
        is_ex_valid      <= 1'b0;
        is_ex_alu_op     <= 16'b0;
        is_ex_src1_data  <= 32'b0;
        is_ex_src2_data  <= 32'b0;
        is_ex_src1  <= 4'b0;
        is_ex_src2  <= 4'b0;
        is_ex_dest       <= 5'b0;
        is_ex_gr_we      <= 1'b0;
    end else if (is_ex_nop) begin
        // nop ���ȼ����� stall -- ��ռĴ���
        is_ex_valid      <= 1'b0;
        is_ex_alu_op     <= 16'b0;
        is_ex_src1_data  <= 32'b0;
        is_ex_src2_data  <= 32'b0;
        is_ex_src1  <= 4'b0;
        is_ex_src2  <= 4'b0;
        is_ex_dest       <= 5'b0;
        is_ex_gr_we      <= 1'b0;
    end else if (!is_ex_stall) begin
        // ����д��
        is_ex_valid      <= valid_i;
        is_ex_alu_op     <= alu_op_i;
        is_ex_src1_data  <= src1_data_i;
        is_ex_src2_data  <= src2_data_i;
        is_ex_src1  <= src1_i;
        is_ex_src2  <= src2_i;
        is_ex_dest       <= dest_i;
        is_ex_gr_we      <= gr_we_i;
    end
    // �� stall���򱣳�ԭֵ
end

// ============================================================================
// ALU��������ԭ��һ�µĽӿڣ�
wire [31:0] ex_alu_result;
wire [31:0] src1,src2,mem_wdata; 
assign src1 = is_ex_src1[3] ? ex2_r : is_ex_src1[2] ? ex1_r : is_ex_src1[1] ? mem2_r : is_ex_src1[0] ? mem1_r : is_ex_src1_data;
assign src2 = is_ex_src2[3] ? ex2_r : is_ex_src2[2] ? ex1_r : is_ex_src2[1] ? mem2_r : is_ex_src2[0] ? mem1_r : is_ex_src2_data;
alu_unit u_alu (
    .alu_op(is_ex_alu_op),
    .src1(src1),
    .src2(src2),
    .result(ex_alu_result)
);

// ============================================================================
// EX_MEM ��ˮ�߼Ĵ�����ִ�С�MEM��ע�⣺����� MEM ֻ����ˮ�׶����ƣ����漰��ʵ�ô棩
reg                 ex_mem_valid;
reg [31:0]          ex_mem_alu_result;
reg [4:0]           ex_mem_dest;
reg                 ex_mem_gr_we;

always @(posedge clk) begin
    if (rst) begin
        ex_mem_valid       <= 1'b0;
        ex_mem_alu_result  <= 32'b0;
        ex_mem_dest        <= 5'b0;
        ex_mem_gr_we       <= 1'b0;
    end else if (ex_mem_nop) begin
        ex_mem_valid       <= 1'b0;
        ex_mem_alu_result  <= 32'b0;
        ex_mem_dest        <= 5'b0;
        ex_mem_gr_we       <= 1'b0;
    end else if (!ex_mem_stall) begin
        ex_mem_valid       <= is_ex_valid;
        ex_mem_alu_result  <= ex_alu_result;
        ex_mem_dest        <= is_ex_dest;
        ex_mem_gr_we       <= is_ex_gr_we;
    end
    // stall ʱ����
end

// ============================================================================
// MEM_WB ��ˮ�߼Ĵ�����MEM��WB��
reg                 mem_wb_valid;
reg [31:0]          mem_wb_wdata;
reg [4:0]           mem_wb_dest;
reg                 mem_wb_gr_we;

always @(posedge clk) begin
    if (rst) begin
        mem_wb_valid  <= 1'b0;
        mem_wb_wdata  <= 32'b0;
        mem_wb_dest   <= 5'b0;
        mem_wb_gr_we  <= 1'b0;
    end else if (mem_wb_nop) begin
        mem_wb_valid  <= 1'b0;
        mem_wb_wdata  <= 32'b0;
        mem_wb_dest   <= 5'b0;
        mem_wb_gr_we  <= 1'b0;
    end else if (!mem_wb_stall) begin
        mem_wb_valid  <= ex_mem_valid;
        mem_wb_wdata  <= ex_mem_alu_result; // �޷ô棬д������ֱ������ ALU ���
        mem_wb_dest   <= ex_mem_dest;
        mem_wb_gr_we  <= ex_mem_gr_we;
    end
    // stall ʱ����
end

// ============================================================================
// �����ǰ�� / д�أ�
// EX �׶�ǰ�ݣ����ָ������ EX���ṩ ALU �����ǰ��ת��
assign ex_dest_o   = is_ex_dest;
assign ex_gr_we_o  = is_ex_gr_we;
assign ex_wdata_o  = ex_alu_result;

// MEM �׶�ǰ�ݣ����� EX_MEM �Ĵ�����
assign mem_dest_o  = ex_mem_dest;
assign mem_gr_we_o = ex_mem_gr_we;
assign mem_wdata_o = ex_mem_alu_result;

// д����������� MEM_WB��
assign wb_dest_o   = mem_wb_dest;
assign wb_gr_we_o  = mem_wb_gr_we;
assign wb_data_o   = mem_wb_wdata;

endmodule



// ============================================================================
// ALU���㵥Ԫ - �Ż��汾����ƽ������߼�������ʱ��
// ============================================================================
module alu_unit (
    input wire [15:0] alu_op,
    input wire [31:0] src1,
    input wire [31:0] src2,
    output wire [31:0] result
);

// ============================================================================
// �м������м��㣨һ���߼���
// ============================================================================
wire [31:0] add_result  = src1 + src2;
wire [31:0] sub_result  = src1 - src2;
wire [31:0] and_result  = src1 & src2;
wire [31:0] or_result   = src1 | src2;
wire [31:0] xor_result  = src1 ^ src2;
wire [31:0] nor_result  = ~or_result;
wire [31:0] sll_result  = src1 << src2[4:0];
wire [31:0] srl_result  = src1 >> src2[4:0];
wire [31:0] sra_result  = $signed(src1) >>> src2[4:0];
wire [31:0] lui_result  = {src2[19:0], 12'b0};
wire [31:0] mul_result  = src1 * src2;

// �ȽϽ��
wire slt_cond  = $signed(src1) < $signed(src2);
wire sltu_cond = src1 < src2;
wire eq_cond   = (src1 == src2);
wire ne_cond   = (src1 != src2);

wire [31:0] slt_result  = {31'b0, slt_cond};
wire [31:0] sltu_result = {31'b0, sltu_cond};
wire [31:0] eq_result   = {31'b0, eq_cond};
wire [31:0] ne_result   = {31'b0, ne_cond};

// ============================================================================
// ��ƽ����·ѡ�����������߼���
// ============================================================================
// ʹ��λ���Լ���������ε�if-elseǶ��
assign result = ({32{alu_op[0]}}  & add_result)  |
                ({32{alu_op[1]}}  & sub_result)  |
                ({32{alu_op[2]}}  & slt_result)  |
                ({32{alu_op[3]}}  & sltu_result) |
                ({32{alu_op[4]}}  & and_result)  |
                ({32{alu_op[5]}}  & nor_result)  |
                ({32{alu_op[6]}}  & or_result)   |
                ({32{alu_op[7]}}  & xor_result)  |
                ({32{alu_op[8]}}  & sll_result)  |
                ({32{alu_op[9]}}  & srl_result)  |
                ({32{alu_op[10]}} & sra_result)  |
                ({32{alu_op[11]}} & lui_result)  |
                ({32{alu_op[12]}} & mul_result)  |
                ({32{alu_op[13]}} & eq_result)   |
                ({32{alu_op[14]}} & ne_result);

endmodule

// ============================================================================
// ��֧��ת��Ԫ
// ============================================================================
module branch_unit (
    input  wire [31:0] pc,
    input  wire        is_branch,
    input  wire        is_conditional_branch,
    input  wire        is_jirl,
    input  wire        is_b,
    input  wire        is_bl,
    input  wire [31:0] br_offs,
    input  wire [31:0] jirl_offs,
    input  wire [15:0] alu_op,
    input  wire [31:0] src1,
    input  wire [31:0] src2,
    input  wire        pred_taken,   // ��֧Ԥ����

    output reg         branch_taken, // �Ƿ���Ҫ������Ԥ�����
    output reg [31:0]  branch_target // ����Ŀ���ַ
);

    reg actual_taken;
    reg [31:0] actual_target;

    // =========================================================
    // ���� alu_op �ж�������֧�Ƿ����
    // =========================================================
    function automatic branch_condition;
        input [15:0] alu_op;
        input [31:0] src1, src2;
        begin
            branch_condition = 1'b0;
            case (1'b1)
                alu_op[13]: branch_condition = (src1 == src2);          // BEQ
                alu_op[14]: branch_condition = (src1 != src2);          // BNE
                default:    branch_condition = 1'b0;
            endcase
        end
    endfunction

    // =========================================================
    // ���߼���ȷ��ʵ���Ƿ���ת + Ŀ���ַ
    // =========================================================
    always @(*) begin
        // Ĭ��ֵ
        actual_taken  = 1'b0;
        actual_target = pc + 32'd4;

        if (is_branch) begin
            if (is_b || is_bl) begin
                // ��������ת
                actual_taken  = 1'b1;
                actual_target = pc + br_offs;
            end else if (is_jirl) begin
                // �����ת
                actual_taken  = 1'b1;
                actual_target = src1 + jirl_offs;
            end else if (is_conditional_branch) begin
                // ������֧������ alu_op �� src1/src2 �ж��Ƿ����
                actual_taken  = branch_condition(alu_op, src1, src2);
                actual_target = pc + br_offs;
            end
        end

        // =====================================================
        // Ԥ�� vs ʵ�ʣ��Ƿ���Ҫ����
        // =====================================================
        if (actual_taken != pred_taken) begin
            branch_taken  = 1'b1;
            branch_target = actual_taken ? actual_target : (pc + 32'd4);
        end else begin
            branch_taken  = 1'b0;
            branch_target = 32'b0;
        end
    end

endmodule

// ============================================================================
// �ô���Ƶ�Ԫ
// ============================================================================
module mem_ctrl_unit (
    input wire [4:0] mem_op,
    input wire [31:0] addr,
   
    input wire mem_we,
    input wire res_from_mem,
   
    output wire        mem_we_n,
    output wire [3:0]  mem_sel_n,
    output wire        mem_ce_o
);

// �ô�������Ͷ���
parameter MEM_BYTE  = 5'b00010;
parameter MEM_WORD  = 5'b00001;


assign mem_we_n = ~(mem_we);
assign mem_ce_o =  (|mem_op);

// �ֽ�Ƭѡ�߼�
reg [3:0] sel_n;
always @(*) begin
    case (mem_op)
        MEM_BYTE: begin
            case (addr[1:0])
                2'b00: sel_n = 4'b1110;
                2'b01: sel_n = 4'b1101;
                2'b10: sel_n = 4'b1011;
                2'b11: sel_n = 4'b0111;
                default: sel_n = 4'b0000;
            endcase
        end
        MEM_WORD: sel_n = 4'b0000;
        default: sel_n = 4'b0000;
    endcase
end

assign mem_sel_n = sel_n;

endmodule