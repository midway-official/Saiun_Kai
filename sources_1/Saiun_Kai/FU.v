module FU (
    input wire clk,
    input wire rst,
    input wire backend_stall,
    // 译码阶段输入信号（去掉pipeline1前缀）
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
    
    // 流水线控制信号
    input wire is_ex_stall,
    input wire is_ex_nop,
    input wire ex_mem_stall,
    input wire ex_mem_nop,
    input wire mem_wb_stall,
    input wire mem_wb_nop,
    //loaduse冒险和访存
    output wire ex_is_load,
    output wire mem_stall,
    input wire [31:0] ex1_r,
    input wire  [31:0]ex2_r,
    input wire  [31:0]mem1_r,
    input wire  [31:0]mem2_r,
    
    
    // 访存接口
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
    
    // 写回寄存器堆控制信号
    output wire [4:0]  wb_dest_o,
    output wire        wb_gr_we_o,
    output wire [31:0] wb_data_o,
    //前递网络
    output wire [4:0]  ex_dest_o,
    output wire        ex_gr_we_o,
    output wire [31:0] ex_wdata_o,
    output wire [4:0]  mem_dest_o,
    output wire           mem_gr_we_o,
    output wire [31:0] mem_wdata_o,
    // 分支跳转结果
    output wire        branch_taken_o,
    output wire [31:0] branch_target_o

);


 assign    ready_o=valid_i&&!mem_stall;
   
// ============================================================================
// IS_EX 流水线寄存器
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
        // nop优先级高于stall，清空流水线寄存器
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
        // 正常流水
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
    // stall时保持原值不变
end

// ============================================================================
// 执行阶段逻辑
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
// ALU运算逻辑
alu_unit u_alu (
    .alu_op(is_ex_alu_op),
    .src1(src1),
    .src2(src2),
    .result(ex_alu_result)
);

// 分支跳转逻辑
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
// 访存控制单元例化
// ============================================================================
wire        ex_mem_we_n;
wire [3:0]  ex_mem_sel_n;
wire        ex_mem_ce_o;


mem_ctrl_unit u_mem_ctrl_unit (
    .mem_op       (is_ex_mem_op),       // 访存操作类型 (load/store, byte/word)
    .addr         (ex_alu_result),      // ALU 计算出的访存地址
    .mem_we       (is_ex_mem_we),       // 是否为写操作
    .res_from_mem (is_ex_res_from_mem), // 是否来自内存（load 指令）
    .mem_we_n     (ex_mem_we_n),        // 输出: 写使能（低有效）
    .mem_sel_n    (ex_mem_sel_n),       // 输出: 字节选通信号（低有效）
    .mem_ce_o     (ex_mem_ce_o)         // 输出: 片选信号
);

// ============================================================================
// EX_MEM 流水线寄存器
// ============================================================================
//基本数据寄存器
reg ex_mem_valid;
reg [31:0] ex_mem_alu_result;
reg [31:0] ex_mem_pc;          // 程序计数器（用于异常处理等）
reg [31:0] ex_mem_branch_target;         
reg ex_mem_branch_taken;         
//寄存器堆写
reg ex_mem_gr_we;
reg [4:0] ex_mem_dest;           // 目标寄存器编号

//访存信号寄存器
reg [31:0] ex_mem_mem_wdata;
reg [3:0] ex_mem_mem_sel_n;
reg ex_mem_mem_we_n;
reg ex_mem_mem_ce;
reg ex_mem_jirl;
reg [31:0] ex_mem_jirl_addr;
// 特殊操作
reg [4:0] ex_mem_special;       
 


always @(posedge clk) begin
    if (rst) begin
        // 复位时清零所有寄存器
        ex_mem_valid <= 1'b0;
        ex_mem_jirl <= 1'b0;
        ex_mem_alu_result <= 32'b0;
        ex_mem_jirl_addr<= 32'b0;
        ex_mem_pc <= 32'b0;
        ex_mem_gr_we <= 1'b0;
        ex_mem_dest <= 5'b0;
        ex_mem_mem_wdata <= 32'b0;
        
        ex_mem_mem_sel_n <= 4'b1111;      // 默认不选中任何字节
        ex_mem_mem_we_n <= 1'b1;      // 默认不写
        ex_mem_mem_ce <= 1'b0;        // 默认不片选
        ex_mem_special <= 5'b0;
        ex_mem_branch_target <= 32'b0;
        ex_mem_branch_taken <= 1'b0;
    end else if (ex_mem_nop) begin
        // nop优先级高于stall，清空流水线寄存器
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
        // 正常流水
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
    // stall时保持原值不变
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
// 状态机时钟更新逻辑 - 增加EXTI暂停控制
always @(posedge clk or posedge rst) begin
    if (rst)
        mem_state <= IDLE;
  else
  if (backend_stall)
      mem_state <= mem_state; // EXTI有效时，状态机保持当前状态不变（暂停）
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
assign mem_data = (ex_mem_mem_we_n == 1'b1) ? 32'b0 :   // 不写 → 全0
                    (ex_mem_mem_sel_n != 4'b0000) ? 
                        {4{ex_mem_mem_wdata[7:0]}} : 
                        ex_mem_mem_wdata;
assign mem_sel_n= ex_mem_mem_sel_n;
assign mem_we_n= ex_mem_mem_we_n;
assign mem_ce= ex_mem_mem_ce;
assign   mem_ll=(ex_mem_special==5'd1);
assign   mem_sc=(ex_mem_special==5'd2);
assign  mem_ready= (mem_state == DONE)|is_special_io;
// 来自内存的数据
wire [31:0] mem_result = mem_data_i;

// 写回数据来源选择：
//  - 如果是 Load 指令（需要从内存读），则写回 mem_result
//  - 否则写回 ALU 计算结果
wire mem_res_from_mem = (ex_mem_mem_ce && ex_mem_mem_we_n == 1'b1);  

wire [31:0] mem_wdata_pre = (ex_mem_jirl&&mem_dest_o!=5'b0)       ? ex_mem_jirl_addr :
                            mem_res_from_mem ? mem_result        :
                                               ex_mem_alu_result;
// LL/SC 特殊处理
assign mem_wdata_o = (ex_mem_special == 5'd2) ? {31'b0, mem_sc_success} :// SC 成功与否
                      mem_wdata_pre;
assign mem_dest_o=ex_mem_dest;
assign mem_gr_we_o=ex_mem_gr_we;

// ============================================================================
// MEM_WB 流水线寄存器
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
// 写回阶段逻辑
// ============================================================================
assign wb_dest_o = mem_wb_dest;
assign wb_gr_we_o = mem_wb_gr_we && mem_wb_valid;
assign wb_data_o = mem_wb_wdata;

// ============================================================================
// 分支跳转输出
// ============================================================================
assign branch_taken_o = ex_mem_branch_taken ;
assign branch_target_o = ex_mem_branch_target;


endmodule


module FU_R (
    input  wire         clk,
    input  wire         rst,

    // 译码阶段输入（简化后）
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
    // 流水线控制信号（保持和原模块一致的接口风格）
    input  wire         is_ex_stall,
    input  wire         is_ex_nop,
    input  wire         ex_mem_stall,
    input  wire         ex_mem_nop,
    input  wire         mem_wb_stall,
    input  wire         mem_wb_nop,

    // 前递网络（EX stage 的输出）
    output wire [4:0]   ex_dest_o,
    output wire         ex_gr_we_o,
    output wire [31:0]  ex_wdata_o,

    // 前递网络 / 写入 MEM stage（EX->MEM）
    output wire [4:0]   mem_dest_o,
    output wire         mem_gr_we_o,
    output wire [31:0]  mem_wdata_o,
     
    // 写回寄存器堆控制信号（WB）
    output wire [4:0]   wb_dest_o,
    output wire         wb_gr_we_o,
    output wire [31:0]  wb_data_o
);

   assign  ready_o=valid_i;
   

// ============================================================================
// IS_EX 流水线寄存器（从译码到执行）
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
        // nop 优先级高于 stall -- 清空寄存器
        is_ex_valid      <= 1'b0;
        is_ex_alu_op     <= 16'b0;
        is_ex_src1_data  <= 32'b0;
        is_ex_src2_data  <= 32'b0;
        is_ex_src1  <= 4'b0;
        is_ex_src2  <= 4'b0;
        is_ex_dest       <= 5'b0;
        is_ex_gr_we      <= 1'b0;
    end else if (!is_ex_stall) begin
        // 正常写入
        is_ex_valid      <= valid_i;
        is_ex_alu_op     <= alu_op_i;
        is_ex_src1_data  <= src1_data_i;
        is_ex_src2_data  <= src2_data_i;
        is_ex_src1  <= src1_i;
        is_ex_src2  <= src2_i;
        is_ex_dest       <= dest_i;
        is_ex_gr_we      <= gr_we_i;
    end
    // 若 stall，则保持原值
end

// ============================================================================
// ALU（保持与原来一致的接口）
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
// EX_MEM 流水线寄存器（执行→MEM，注意：这里的 MEM 只是流水阶段名称，不涉及真实访存）
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
    // stall 时保持
end

// ============================================================================
// MEM_WB 流水线寄存器（MEM→WB）
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
        mem_wb_wdata  <= ex_mem_alu_result; // 无访存，写回数据直接来自 ALU 结果
        mem_wb_dest   <= ex_mem_dest;
        mem_wb_gr_we  <= ex_mem_gr_we;
    end
    // stall 时保持
end

// ============================================================================
// 输出（前递 / 写回）
// EX 阶段前递：如果指令来自 EX，提供 ALU 结果给前级转发
assign ex_dest_o   = is_ex_dest;
assign ex_gr_we_o  = is_ex_gr_we;
assign ex_wdata_o  = ex_alu_result;

// MEM 阶段前递（来自 EX_MEM 寄存器）
assign mem_dest_o  = ex_mem_dest;
assign mem_gr_we_o = ex_mem_gr_we;
assign mem_wdata_o = ex_mem_alu_result;

// 写回输出（来自 MEM_WB）
assign wb_dest_o   = mem_wb_dest;
assign wb_gr_we_o  = mem_wb_gr_we;
assign wb_data_o   = mem_wb_wdata;

endmodule



// ============================================================================
// ALU运算单元 - 优化版本（扁平化组合逻辑，改善时序）
// ============================================================================
module alu_unit (
    input wire [15:0] alu_op,
    input wire [31:0] src1,
    input wire [31:0] src2,
    output wire [31:0] result
);

// ============================================================================
// 中间结果并行计算（一级逻辑）
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

// 比较结果
wire slt_cond  = $signed(src1) < $signed(src2);
wire sltu_cond = src1 < src2;
wire eq_cond   = (src1 == src2);
wire ne_cond   = (src1 != src2);

wire [31:0] slt_result  = {31'b0, slt_cond};
wire [31:0] sltu_result = {31'b0, sltu_cond};
wire [31:0] eq_result   = {31'b0, eq_cond};
wire [31:0] ne_result   = {31'b0, ne_cond};

// ============================================================================
// 扁平化多路选择器（二级逻辑）
// ============================================================================
// 使用位或归约，避免深层次的if-else嵌套
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
// 分支跳转单元
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
    input  wire        pred_taken,   // 分支预测结果

    output reg         branch_taken, // 是否需要修正（预测错误）
    output reg [31:0]  branch_target // 修正目标地址
);

    reg actual_taken;
    reg [31:0] actual_target;

    // =========================================================
    // 根据 alu_op 判断条件分支是否成立
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
    // 主逻辑：确定实际是否跳转 + 目标地址
    // =========================================================
    always @(*) begin
        // 默认值
        actual_taken  = 1'b0;
        actual_target = pc + 32'd4;

        if (is_branch) begin
            if (is_b || is_bl) begin
                // 无条件跳转
                actual_taken  = 1'b1;
                actual_target = pc + br_offs;
            end else if (is_jirl) begin
                // 间接跳转
                actual_taken  = 1'b1;
                actual_target = src1 + jirl_offs;
            end else if (is_conditional_branch) begin
                // 条件分支：根据 alu_op 与 src1/src2 判断是否成立
                actual_taken  = branch_condition(alu_op, src1, src2);
                actual_target = pc + br_offs;
            end
        end

        // =====================================================
        // 预测 vs 实际：是否需要修正
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
// 访存控制单元
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

// 访存操作类型定义
parameter MEM_BYTE  = 5'b00010;
parameter MEM_WORD  = 5'b00001;


assign mem_we_n = ~(mem_we);
assign mem_ce_o =  (|mem_op);

// 字节片选逻辑
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