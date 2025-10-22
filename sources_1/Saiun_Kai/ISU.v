module ISU(
    input wire clk,
    input wire rst, 
    input wire sys_rst, 
    input wire stall,
    input wire FU1_ready,
     input wire FU2_ready,
     input wire load_use_hazard,
    output wire iq_is_full,
    // IDU输入
    input wire [15:0] inst1_alu_op_i,
    input wire [31:0] inst1_imm_i,
    input wire [31:0] inst1_br_offs_i, 
    input wire [31:0] inst1_jirl_offs_i,
    input wire [4:0] inst1_rf_raddr1_i,
    input wire [4:0] inst1_rf_raddr2_i,
    input wire [4:0] inst1_dest_i,
    input wire [4:0] inst1_special_i,
    input wire [4:0] inst1_mem_op_i,
    input wire inst1_gr_we_i,
    input wire inst1_mem_we_i,
    input wire inst1_res_from_mem_i,
    input wire inst1_src1_is_pc_i,
    input wire inst1_src2_is_imm_i,
    input wire inst1_dst_is_r1_i,
    input wire [31:0] inst1_pc_i,
    input wire inst1_is_branch_i,
    input wire inst1_pred_taken_i,
    input wire inst1_is_conditional_branch_i,
    input wire inst1_is_jirl_i,
    input wire inst1_is_b_i,
    input wire inst1_is_bl_i,

    input wire [15:0] inst2_alu_op_i,
    input wire [31:0] inst2_imm_i,
    input wire [31:0] inst2_br_offs_i,
    input wire [31:0] inst2_jirl_offs_i, 
    input wire [4:0] inst2_rf_raddr1_i,
    input wire [4:0] inst2_rf_raddr2_i,
    input wire [4:0] inst2_dest_i,
    input wire [4:0] inst2_special_i,
    input wire [4:0] inst2_mem_op_i,
    input wire inst2_gr_we_i,
    input wire inst2_mem_we_i,
    input wire inst2_res_from_mem_i,
    input wire inst2_src1_is_pc_i,
    input wire inst2_src2_is_imm_i,
    input wire inst2_dst_is_r1_i,
    input wire [31:0] inst2_pc_i,
    input wire inst2_is_branch_i,
    input wire inst2_pred_taken_i,
    input wire inst2_is_conditional_branch_i,
    input wire inst2_is_jirl_i,
    input wire inst2_is_b_i,
    input wire inst2_is_bl_i,
    
    input wire idu_valid, // IDU数据有效信号



    // Register File Interface
    output reg [4:0] rf_raddr1,
    output reg rf_re1,
    output reg [4:0] rf_raddr2,
    output reg rf_re2,
    output reg [4:0] rf_raddr3,
    output reg rf_re3,
    output reg [4:0] rf_raddr4,
    output reg rf_re4,

    input wire [31:0] rf_rdata1,
    input wire [31:0] rf_rdata2,
    input wire [31:0] rf_rdata3,
    input wire [31:0] rf_rdata4,

    // Forward from EX1
    input wire ex1_we_i,
    input wire [4:0] ex1_waddr_i,
    input wire [31:0] ex1_wdata_i,

    // Forward from MEM1  
    input wire mem1_we_i,
    input wire [4:0] mem1_waddr_i,
    input wire [31:0] mem1_wdata_i,

    // Forward from EX2
    input wire ex2_we_i,
    input wire [4:0] ex2_waddr_i, 
    input wire [31:0] ex2_wdata_i,

    // Forward from MEM2
    input wire mem2_we_i,
    input wire [4:0] mem2_waddr_i,
    input wire [31:0] mem2_wdata_i,

    // Pipeline 1 Output
    
    output reg pipe1_valid_o,
    output reg [15:0] pipe1_alu_op_o,
    output reg [31:0] pipe1_src1_data_o,
    output reg [31:0] pipe1_src2_data_o,
    output reg [3:0] pipe1_src1_o,
    output reg [3:0] pipe1_src2_o,
    output reg pipe1_src1_pc_o,
    output reg pipe1_src2_imm_o,
    output reg [31:0] pipe1_mem_wdata_o,
    output reg [31:0] pipe1_pc_o,
    output reg pipe1_is_branch_o,
    output reg pipe1_pred_taken_o,
    output reg pipe1_is_conditional_branch_o,
    output reg pipe1_is_jirl_o,
    output reg pipe1_is_b_o,
    output reg pipe1_is_bl_o,
    output reg [31:0] pipe1_br_offs_o,
    output reg [31:0] pipe1_jirl_offs_o,
    output reg [4:0] pipe1_dest_o,
    output reg [4:0] pipe1_special_o,
    output reg [4:0] pipe1_mem_op_o,
    output reg [4:0] pipe1_rd_o,
    output reg pipe1_gr_we_o,
    output reg pipe1_mem_we_o,
    output reg pipe1_res_from_mem_o,

    // Pipeline 2 Output  
    output reg pipe2_valid_o,
    output reg [15:0] pipe2_alu_op_o,
    output reg [31:0] pipe2_src1_data_o, 
    output reg [31:0] pipe2_src2_data_o,
    output reg [3:0] pipe2_src1_o,
    output reg [3:0] pipe2_src2_o,
    output reg pipe2_src1_pc_o,
    output reg pipe2_src2_imm_o,
    output reg [31:0] pipe2_mem_wdata_o,
    output reg [31:0] pipe2_pc_o,
    output reg pipe2_is_branch_o,
    output reg pipe2_pred_taken_o,
    output reg pipe2_is_conditional_branch_o,
    output reg pipe2_is_jirl_o,
    output reg pipe2_is_b_o,
    output reg pipe2_is_bl_o,
    output reg [31:0] pipe2_br_offs_o,
    output reg [31:0] pipe2_jirl_offs_o,
    output reg [4:0] pipe2_dest_o,
    output reg [4:0] pipe2_special_o,
    output reg [4:0] pipe2_mem_op_o,
    output reg [4:0] pipe2_rd_o,
    output reg pipe2_gr_we_o,
    output reg pipe2_mem_we_o,
    output reg pipe2_res_from_mem_o,
    
    output reg [31:0] ex1_r,
    output reg [31:0] ex2_r,
    output reg [31:0] mem1_r,
    output reg [31:0] mem2_r
);

always @(posedge clk or posedge sys_rst) begin
    if (sys_rst) begin
        ex1_r  <= 32'b0;
        ex2_r  <= 32'b0;
        mem1_r <= 32'b0;
        mem2_r <= 32'b0;
    end else begin
        ex1_r  <= ex1_we_i  ? ex1_wdata_i  : ex1_r;   // 仅在写使能时更新
        ex2_r  <= ex2_we_i  ? ex2_wdata_i  : ex2_r;
        mem1_r <= mem1_we_i ? mem1_wdata_i : mem1_r;
        mem2_r <= mem2_we_i ? mem2_wdata_i : mem2_r;
    end
end

// 从FIFO或窗口缓存解包出的指令信息
wire [15:0] fifo_inst1_alu_op;
wire [31:0] fifo_inst1_imm;
wire [31:0] fifo_inst1_br_offs;
wire [31:0] fifo_inst1_jirl_offs;
wire [4:0]  fifo_inst1_rf_raddr1;
wire [4:0]  fifo_inst1_rf_raddr2;
wire [4:0]  fifo_inst1_dest;
wire [4:0]  fifo_inst1_special;
wire [4:0]  fifo_inst1_mem_op;
wire        fifo_inst1_gr_we;
wire        fifo_inst1_mem_we;
wire        fifo_inst1_res_from_mem;
wire        fifo_inst1_src1_is_pc;
wire        fifo_inst1_src2_is_imm;
wire        fifo_inst1_dst_is_r1;
wire [31:0] fifo_inst1_pc;
wire        fifo_inst1_is_branch;
wire        fifo_inst1_pred_taken;
wire        fifo_inst1_is_conditional_branch;
wire        fifo_inst1_is_jirl;
wire        fifo_inst1_is_b;
wire        fifo_inst1_is_bl;

wire [15:0] fifo_inst2_alu_op;
wire [31:0] fifo_inst2_imm;
wire [31:0] fifo_inst2_br_offs;
wire [31:0] fifo_inst2_jirl_offs;
wire [4:0]  fifo_inst2_rf_raddr1;
wire [4:0]  fifo_inst2_rf_raddr2;
wire [4:0]  fifo_inst2_dest;
wire [4:0]  fifo_inst2_special;
wire [4:0]  fifo_inst2_mem_op;
wire        fifo_inst2_gr_we;
wire        fifo_inst2_mem_we;
wire        fifo_inst2_res_from_mem;
wire        fifo_inst2_src1_is_pc;
wire        fifo_inst2_src2_is_imm;
wire        fifo_inst2_dst_is_r1;
wire [31:0] fifo_inst2_pc;
wire        fifo_inst2_is_branch;
wire        fifo_inst2_pred_taken;
wire        fifo_inst2_is_conditional_branch;
wire        fifo_inst2_is_jirl;
wire        fifo_inst2_is_b;
wire        fifo_inst2_is_bl;

    // FIFO 
reg iq_wr_en;
reg iq_rd_en;
reg [361:0] iq_din;
wire [361:0] iq_dout;
wire iq_empty;
wire iq_full;
wire iq_true_full;
wire iq_valid ;
   // ----------------- FIFO例化 -----------------
sync_fifo  u_iq_fifo (
    .i_clk        (clk),
    .i_rst        (rst),          // FIFO复位和ISU复位同步
    .i_w_en       (iq_wr_en),     // 写使能
    .i_r_en       (iq_rd_en),     // 读使能
    .i_data       (iq_din),       // 写入数据
    .o_data       (iq_dout),      // 读出数据
    .o_buf_empty  (iq_empty),     // FIFO空标志
    .o_buf_almost_full   (iq_full),       // FIFO满标志
    .o_buf_full   (iq_true_full)       // FIFO满标志
);




assign iq_is_full =iq_full;
// FIFO数据打包
always @(*) begin
    iq_din = {
        inst1_alu_op_i, inst1_imm_i, inst1_br_offs_i, inst1_jirl_offs_i,
        inst1_rf_raddr1_i, inst1_rf_raddr2_i, inst1_dest_i, inst1_special_i, inst1_mem_op_i,
        inst1_gr_we_i, inst1_mem_we_i, inst1_res_from_mem_i,
        inst1_src1_is_pc_i, inst1_src2_is_imm_i, inst1_dst_is_r1_i,
        inst1_pc_i, inst1_is_branch_i, inst1_pred_taken_i,
        inst1_is_conditional_branch_i, inst1_is_jirl_i, inst1_is_b_i, inst1_is_bl_i,
        
        inst2_alu_op_i, inst2_imm_i, inst2_br_offs_i, inst2_jirl_offs_i,
        inst2_rf_raddr1_i, inst2_rf_raddr2_i, inst2_dest_i, inst2_special_i, inst2_mem_op_i,
        inst2_gr_we_i, inst2_mem_we_i, inst2_res_from_mem_i,
        inst2_src1_is_pc_i, inst2_src2_is_imm_i, inst2_dst_is_r1_i,
        inst2_pc_i, inst2_is_branch_i, inst2_pred_taken_i,
        inst2_is_conditional_branch_i, inst2_is_jirl_i, inst2_is_b_i, inst2_is_bl_i
    };
end

// 根据状态选择从FIFO还是从窗口缓存中解包
wire [361:0] issue_data =  iq_dout;
assign {
    fifo_inst1_alu_op, fifo_inst1_imm, fifo_inst1_br_offs, fifo_inst1_jirl_offs,
    fifo_inst1_rf_raddr1, fifo_inst1_rf_raddr2, fifo_inst1_dest, fifo_inst1_special, fifo_inst1_mem_op,
    fifo_inst1_gr_we, fifo_inst1_mem_we, fifo_inst1_res_from_mem,
    fifo_inst1_src1_is_pc, fifo_inst1_src2_is_imm, fifo_inst1_dst_is_r1,
    fifo_inst1_pc, fifo_inst1_is_branch, fifo_inst1_pred_taken,
    fifo_inst1_is_conditional_branch, fifo_inst1_is_jirl, fifo_inst1_is_b, fifo_inst1_is_bl,
    
    fifo_inst2_alu_op, fifo_inst2_imm, fifo_inst2_br_offs, fifo_inst2_jirl_offs,
    fifo_inst2_rf_raddr1, fifo_inst2_rf_raddr2, fifo_inst2_dest, fifo_inst2_special, fifo_inst2_mem_op,
    fifo_inst2_gr_we, fifo_inst2_mem_we, fifo_inst2_res_from_mem,
    fifo_inst2_src1_is_pc, fifo_inst2_src2_is_imm, fifo_inst2_dst_is_r1,
    fifo_inst2_pc, fifo_inst2_is_branch, fifo_inst2_pred_taken,
    fifo_inst2_is_conditional_branch, fifo_inst2_is_jirl, fifo_inst2_is_b, fifo_inst2_is_bl
} = issue_data;

// FIFO写控制
always @(*) begin
    iq_wr_en = idu_valid&&!iq_true_full ;
end

// RAW冒险检测: inst1的写寄存器是inst2的读寄存器
wire raw_hazard = fifo_inst1_gr_we && (
    (fifo_inst1_dest == fifo_inst2_rf_raddr1 && fifo_inst2_rf_raddr1 != 5'b0 && ~fifo_inst2_src1_is_pc) ||
    (fifo_inst1_dest == fifo_inst2_rf_raddr2 && fifo_inst2_rf_raddr2 != 5'b0 && (~fifo_inst2_src2_is_imm || fifo_inst2_mem_we))
);
// 指令类型判断
wire inst1_is_mem_access = fifo_inst1_mem_we || fifo_inst1_res_from_mem;
wire inst2_is_mem_access = fifo_inst2_mem_we || fifo_inst2_res_from_mem;
// 双发射条件
wire can_dual_issue = !raw_hazard && !inst1_is_mem_access && !inst2_is_mem_access && !fifo_inst1_is_branch && !fifo_inst2_is_branch;


// ---------------- 状态机定义 ----------------
localparam S_IDLE   = 2'b00;  // 初态
localparam S_ISSUE2 = 2'b01;  // 单独发射指令2

reg [1:0] state, next_state;


// 状态寄存器
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= S_IDLE;
        
        end
    else if (!(stall)) 
        begin
        state <= next_state;
       
        end
end
// ---------------- 状态转移逻辑 ----------------
always @(*) begin
    next_state = state;  // 默认保持当前状态
    case (state)
        S_IDLE: begin
            if (can_dual_issue) begin
                // 双发指令，需要两个FU都准备好才能继续
                if (FU1_ready && FU2_ready&&!load_use_hazard)
                    next_state = S_IDLE;   // 双发成功，留在初态
                else
                    next_state = S_IDLE;   // 任意FU没准备好，保持当前状态等待
            end else begin
                // 单发指令，发射inst1后尝试发inst2
                if (FU1_ready&&!load_use_hazard&&!(fifo_inst1_is_branch&&fifo_inst1_pred_taken))
                    next_state = S_ISSUE2; // 可以发指令2，状态转ISSUE2
                else
                    next_state = S_IDLE;   // FU1没准备好，保持初态等待
            end
        end
        
        S_ISSUE2: begin
            // 发射指令2前，确保FU1准备好
            if (FU1_ready&&!load_use_hazard)
                next_state = S_IDLE;   // 发射完成，回到初态
            else
                next_state = S_ISSUE2; // FU1未准备好，保持ISSUE2状态等待
        end
        
    endcase
end
// ---------------- 输出逻辑（使用ready握手） ----------------
always @(*) begin
    // 默认
    iq_rd_en        = 1'b0;
    pipe1_valid_o   = 1'b0;
    pipe2_valid_o   = 1'b0;

    case (state)
        S_IDLE: begin
            // inst1 -> pipe1
            pipe1_valid_o = !iq_empty ;
            
            if(can_dual_issue) begin
                // inst2 -> pipe2
                pipe2_valid_o = !iq_empty ;
                // 双发时，只有两个流水线都准备好才读FIFO
                iq_rd_en = (!iq_empty) && (!stall) && FU1_ready && FU2_ready&&!load_use_hazard;
            end else begin
                // 单发时只发inst1
                pipe2_valid_o = 1'b0;
                // 单发不读下一条 第一条预测跳转 读下一条
                iq_rd_en =   (!iq_empty) && (!stall) &&FU1_ready &&fifo_inst1_is_branch&&fifo_inst1_pred_taken;
            end
        end

        S_ISSUE2: begin
            // 单发状态，把inst2放到pipe1
            pipe1_valid_o = 1;
            pipe2_valid_o = 1'b0;
            // 只有FU1准备好才读下一条
            iq_rd_en = (!iq_empty) && (!stall) && FU1_ready&&!load_use_hazard;
        end
    endcase
end

// ---------------- 输出指令信息 ----------------
// 增加中间变量，用于计算实际的输出数据
reg [15:0] pipe1_alu_op_internal;
reg [4:0] pipe1_dest_internal;
reg [4:0] pipe1_special_internal;
reg [4:0] pipe1_mem_op_internal;
reg [4:0] pipe1_rd_internal;
reg pipe1_gr_we_internal;
reg pipe1_mem_we_internal;
reg pipe1_res_from_mem_internal;
reg [31:0] pipe1_pc_internal;
 reg pipe1_src1_pc_internal;
 reg pipe1_src2_imm_internal;
reg pipe1_is_branch_internal;
reg pipe1_pred_taken_internal;
reg pipe1_is_conditional_branch_internal;
reg pipe1_is_jirl_internal;
reg pipe1_is_b_internal;
reg pipe1_is_bl_internal;
reg [31:0] pipe1_br_offs_internal;
reg [31:0] pipe1_jirl_offs_internal;

reg [15:0] pipe2_alu_op_internal;
reg [4:0] pipe2_dest_internal;
reg [4:0] pipe2_special_internal;
reg [4:0] pipe2_mem_op_internal;
 reg pipe2_src1_pc_internal; 
 reg pipe2_src2_imm_internal;
 reg [4:0] pipe2_rd_internal;
reg pipe2_gr_we_internal;
reg pipe2_mem_we_internal;
reg pipe2_res_from_mem_internal;
reg [31:0] pipe2_pc_internal;
reg pipe2_is_branch_internal;
reg pipe2_pred_taken_internal;
reg pipe2_is_conditional_branch_internal;
reg pipe2_is_jirl_internal;
reg pipe2_is_b_internal;
reg pipe2_is_bl_internal;
reg [31:0] pipe2_br_offs_internal;
reg [31:0] pipe2_jirl_offs_internal;

always @(*) begin
    // 默认值清零/无效
    pipe1_alu_op_internal      = 16'b0;
    pipe1_dest_internal        = 5'b0;
    pipe1_special_internal     = 5'b0;
    pipe1_mem_op_internal      = 5'b0;
     pipe1_src1_pc_internal = 1'b0; 
  pipe1_src2_imm_internal = 1'b0;
    pipe1_rd_internal          = 5'b0;
    pipe1_gr_we_internal       = 1'b0;
    pipe1_mem_we_internal      = 1'b0;
    pipe1_res_from_mem_internal= 1'b0;
    pipe1_pc_internal          = 32'b0;
    pipe1_is_branch_internal   = 1'b0;
    pipe1_pred_taken_internal  = 1'b0;
    pipe1_is_conditional_branch_internal = 1'b0;
    pipe1_is_jirl_internal     = 1'b0;
    pipe1_is_b_internal        = 1'b0;
    pipe1_is_bl_internal       = 1'b0;
    pipe1_br_offs_internal     = 32'b0;
    pipe1_jirl_offs_internal   = 32'b0;

    pipe2_alu_op_internal      = 16'b0;
    pipe2_dest_internal        = 5'b0;
    pipe2_special_internal     = 5'b0;
        pipe2_src1_pc_internal = 1'b0; 
  pipe2_src2_imm_internal = 1'b0;
    pipe2_mem_op_internal      = 5'b0;
    pipe2_rd_internal          = 5'b0;
    pipe2_gr_we_internal       = 1'b0;
    pipe2_mem_we_internal      = 1'b0;
    pipe2_res_from_mem_internal= 1'b0;
    pipe2_pc_internal          = 32'b0;
    pipe2_is_branch_internal   = 1'b0;
    pipe2_pred_taken_internal  = 1'b0;
    pipe2_is_conditional_branch_internal = 1'b0;
    pipe2_is_jirl_internal     = 1'b0;
    pipe2_is_b_internal        = 1'b0;
    pipe2_is_bl_internal       = 1'b0;
    pipe2_br_offs_internal     = 32'b0;
    pipe2_jirl_offs_internal   = 32'b0;
   
    case(state)
        S_IDLE: begin
            // pipe1 -> inst1
            
            pipe1_alu_op_internal  = fifo_inst1_alu_op;
            pipe1_dest_internal    = fifo_inst1_dest;
            pipe1_special_internal = fifo_inst1_special;
             pipe1_src1_pc_internal =  fifo_inst1_src1_is_pc;      
              pipe1_src2_imm_internal = fifo_inst1_src2_is_imm ;   
            pipe1_mem_op_internal  = fifo_inst1_mem_op;
            pipe1_rd_internal      = fifo_inst1_rf_raddr2;
            pipe1_gr_we_internal   = fifo_inst1_gr_we;
            pipe1_mem_we_internal  = fifo_inst1_mem_we;
            pipe1_res_from_mem_internal = fifo_inst1_res_from_mem;
            pipe1_pc_internal      = fifo_inst1_pc;
            pipe1_is_branch_internal = fifo_inst1_is_branch;
            pipe1_pred_taken_internal = fifo_inst1_pred_taken;
            pipe1_is_conditional_branch_internal = fifo_inst1_is_conditional_branch;
            pipe1_is_jirl_internal = fifo_inst1_is_jirl;
            pipe1_is_b_internal    = fifo_inst1_is_b;
            pipe1_is_bl_internal   = fifo_inst1_is_bl;
            pipe1_br_offs_internal   = fifo_inst1_br_offs;
            pipe1_jirl_offs_internal = fifo_inst1_jirl_offs;

            if(can_dual_issue) begin
                // pipe2 -> inst2
                pipe2_alu_op_internal  = fifo_inst2_alu_op;
                pipe2_dest_internal    = fifo_inst2_dest;
                pipe2_special_internal = fifo_inst2_special;
                pipe2_src1_pc_internal =  fifo_inst2_src1_is_pc;   
                 pipe2_src2_imm_internal = fifo_inst2_src2_is_imm ;
                 pipe2_mem_op_internal  = fifo_inst2_mem_op;
                pipe2_rd_internal      = fifo_inst2_rf_raddr2;
                pipe2_gr_we_internal   = fifo_inst2_gr_we;
                pipe2_mem_we_internal  = fifo_inst2_mem_we;
                pipe2_res_from_mem_internal = fifo_inst2_res_from_mem;
                pipe2_pc_internal      = fifo_inst2_pc;
                pipe2_is_branch_internal = fifo_inst2_is_branch;
                pipe2_pred_taken_internal = fifo_inst2_pred_taken;
                pipe2_is_conditional_branch_internal = fifo_inst2_is_conditional_branch;
                pipe2_is_jirl_internal = fifo_inst2_is_jirl;
                pipe2_is_b_internal    = fifo_inst2_is_b;
                pipe2_is_bl_internal   = fifo_inst2_is_bl;
                pipe2_br_offs_internal   = fifo_inst2_br_offs;
                pipe2_jirl_offs_internal = fifo_inst2_jirl_offs;
            end
        end

        S_ISSUE2: begin
            // pipe1 -> inst2
            pipe1_alu_op_internal  = fifo_inst2_alu_op;
            pipe1_dest_internal    = fifo_inst2_dest;
            pipe1_special_internal = fifo_inst2_special;
            pipe1_src1_pc_internal =  fifo_inst2_src1_is_pc;   
            pipe1_src2_imm_internal = fifo_inst2_src2_is_imm ;
            pipe1_mem_op_internal  = fifo_inst2_mem_op;
            pipe1_rd_internal      = fifo_inst2_rf_raddr2;
            pipe1_gr_we_internal   = fifo_inst2_gr_we;
            pipe1_mem_we_internal  = fifo_inst2_mem_we;
            pipe1_res_from_mem_internal = fifo_inst2_res_from_mem;
            pipe1_pc_internal      = fifo_inst2_pc;
            pipe1_is_branch_internal = fifo_inst2_is_branch;
            pipe1_pred_taken_internal = fifo_inst2_pred_taken;
            pipe1_is_conditional_branch_internal = fifo_inst2_is_conditional_branch;
            pipe1_is_jirl_internal = fifo_inst2_is_jirl;
            pipe1_is_b_internal    = fifo_inst2_is_b;
            pipe1_is_bl_internal   = fifo_inst2_is_bl;
            pipe1_br_offs_internal   = fifo_inst2_br_offs;
            pipe1_jirl_offs_internal = fifo_inst2_jirl_offs;
        end
    endcase
end

// 最终输出：根据valid信号选择输出数据或全0
always @(*) begin
    if (pipe1_valid_o) begin
        pipe1_alu_op_o       = pipe1_alu_op_internal;
        pipe1_dest_o         = pipe1_dest_internal;
        pipe1_special_o      = pipe1_special_internal;
        pipe1_src1_pc_o       = pipe1_src1_pc_internal;
        pipe1_src2_imm_o       = pipe1_src2_imm_internal;
        pipe1_mem_op_o       = pipe1_mem_op_internal;
        pipe1_rd_o           = pipe1_rd_internal;
        pipe1_gr_we_o        = pipe1_gr_we_internal;
        pipe1_mem_we_o       = pipe1_mem_we_internal;
        pipe1_res_from_mem_o = pipe1_res_from_mem_internal;
        pipe1_pc_o           = pipe1_pc_internal;
        pipe1_is_branch_o    = pipe1_is_branch_internal;
        pipe1_pred_taken_o   = pipe1_pred_taken_internal;
        pipe1_is_conditional_branch_o = pipe1_is_conditional_branch_internal;
        pipe1_is_jirl_o      = pipe1_is_jirl_internal;
        pipe1_is_b_o         = pipe1_is_b_internal;
        pipe1_is_bl_o        = pipe1_is_bl_internal;
        pipe1_br_offs_o      = pipe1_br_offs_internal;
        pipe1_jirl_offs_o    = pipe1_jirl_offs_internal;
    end else begin
        pipe1_alu_op_o       = 16'b0;
        pipe1_dest_o         = 5'b0;
        pipe1_special_o      = 5'b0;
        pipe1_mem_op_o       = 5'b0;
        pipe1_rd_o           = 5'b0;
        pipe1_gr_we_o        = 1'b0;
        pipe1_src1_pc_o       = 1'b0;
        pipe1_src2_imm_o       = 1'b0;
        pipe1_mem_we_o       = 1'b0;
        pipe1_res_from_mem_o = 1'b0;
        pipe1_pc_o           = 32'b0;
        pipe1_is_branch_o    = 1'b0;
        pipe1_pred_taken_o   = 1'b0;
        pipe1_is_conditional_branch_o = 1'b0;
        pipe1_is_jirl_o      = 1'b0;
        pipe1_is_b_o         = 1'b0;
        pipe1_is_bl_o        = 1'b0;
        pipe1_br_offs_o      = 32'b0;
        pipe1_jirl_offs_o    = 32'b0;
    end

    if (pipe2_valid_o) begin
        pipe2_alu_op_o       = pipe2_alu_op_internal;
        pipe2_dest_o         = pipe2_dest_internal;
        pipe2_special_o      = pipe2_special_internal;
        pipe2_mem_op_o       = pipe2_mem_op_internal;
        pipe2_src1_pc_o       = pipe2_src1_pc_internal;
        pipe2_src2_imm_o       = pipe2_src2_imm_internal;
        pipe2_rd_o           = pipe2_rd_internal;
        pipe2_gr_we_o        = pipe2_gr_we_internal;
        pipe2_mem_we_o       = pipe2_mem_we_internal;
        pipe2_res_from_mem_o = pipe2_res_from_mem_internal;
        pipe2_pc_o           = pipe2_pc_internal;
        pipe2_is_branch_o    = pipe2_is_branch_internal;
        pipe2_pred_taken_o   = pipe2_pred_taken_internal;
        pipe2_is_conditional_branch_o = pipe2_is_conditional_branch_internal;
        pipe2_is_jirl_o      = pipe2_is_jirl_internal;
        pipe2_is_b_o         = pipe2_is_b_internal;
        pipe2_is_bl_o        = pipe2_is_bl_internal;
        pipe2_br_offs_o      = pipe2_br_offs_internal;
        pipe2_jirl_offs_o    = pipe2_jirl_offs_internal;
    end else begin
        pipe2_alu_op_o       = 16'b0;
        pipe2_dest_o         = 5'b0;
        pipe2_special_o      = 5'b0;
        pipe2_mem_op_o       = 5'b0;
        pipe2_src1_pc_o       = 1'b0;
        pipe2_src2_imm_o       = 1'b0;
        pipe2_rd_o           = 5'b0;
        pipe2_gr_we_o        = 1'b0;
        pipe2_mem_we_o       = 1'b0;
        pipe2_res_from_mem_o = 1'b0;
        pipe2_pc_o           = 32'b0;
        pipe2_is_branch_o    = 1'b0;
        pipe2_pred_taken_o   = 1'b0;
        pipe2_is_conditional_branch_o = 1'b0;
        pipe2_is_jirl_o      = 1'b0;
        pipe2_is_b_o         = 1'b0;
        pipe2_is_bl_o        = 1'b0;
        pipe2_br_offs_o      = 32'b0;
        pipe2_jirl_offs_o    = 32'b0;
    end
end
// ============================================================================
// 前递来源检测函数：输出来源阶段 (ex2/ex1/mem2/mem1)
// ============================================================================
function [3:0] forward_src;
    input [4:0] raddr;
    input ex2_we; input [4:0] ex2_waddr;
    input ex1_we; input [4:0] ex1_waddr;
    input mem2_we; input [4:0] mem2_waddr;
    input mem1_we; input [4:0] mem1_waddr;

    reg is_zero;
    reg ex2_match, ex1_match, mem2_match, mem1_match;
    begin
        is_zero    = (raddr == 5'b0);
        ex2_match  = ex2_we  && (ex2_waddr  == raddr);
        ex1_match  = ex1_we  && (ex1_waddr  == raddr);
        mem2_match = mem2_we && (mem2_waddr == raddr);
        mem1_match = mem1_we && (mem1_waddr == raddr);

        // 优先级：ex2 > ex1 > mem2 > mem1
        forward_src = 4'b0000;
        if (!is_zero) begin
            if (ex2_match)       forward_src = 4'b1000;
            else if (ex1_match)  forward_src = 4'b0100;
            else if (mem2_match) forward_src = 4'b0010;
            else if (mem1_match) forward_src = 4'b0001;
        end
    end
endfunction
// ----------------- 主组合逻辑 -----------------
// 增加中间变量，用于计算实际的数据输出
reg [31:0] pipe1_src1_data_internal;
reg [3:0] pipe1_src1_internal;
reg [31:0] pipe1_src2_data_internal;
reg [3:0] pipe1_src2_internal;
reg [31:0] pipe1_mem_wdata_internal;
reg [31:0] pipe2_src1_data_internal;
reg [3:0] pipe2_src1_internal;
reg [31:0] pipe2_src2_data_internal;
reg [3:0] pipe2_src2_internal;
reg [31:0] pipe2_mem_wdata_internal;

always @(*) begin
    // 默认清零
    pipe1_src1_data_internal = 32'b0;
    pipe1_src2_data_internal = 32'b0;
    pipe1_mem_wdata_internal = 32'b0;
    pipe2_src1_data_internal = 32'b0;
    pipe2_src2_data_internal = 32'b0;
    pipe2_mem_wdata_internal = 32'b0;

    case (state)
        S_IDLE: begin
            // inst1 -> pipe1
            pipe1_src1_data_internal = fifo_inst1_src1_is_pc ? fifo_inst1_pc
                                :rf_rdata1;

            pipe1_src2_data_internal = fifo_inst1_src2_is_imm ? fifo_inst1_imm
                                : rf_rdata2;
            
              pipe1_src1_internal = forward_src(
                    rf_raddr1,
                    ex2_we_i, ex2_waddr_i,
                    ex1_we_i, ex1_waddr_i,
                    mem2_we_i, mem2_waddr_i,
                    mem1_we_i, mem1_waddr_i
                );
               
            pipe1_src2_internal = forward_src(
                    rf_raddr2,
                    ex2_we_i, ex2_waddr_i,
                    ex1_we_i, ex1_waddr_i,
                    mem2_we_i, mem2_waddr_i,
                    mem1_we_i, mem1_waddr_i
                );
                
            pipe1_mem_wdata_internal = rf_rdata2;
            
            if (can_dual_issue) begin
                // inst2 -> pipe2
                pipe2_src1_data_internal = fifo_inst2_src1_is_pc ? fifo_inst2_pc
                                    :  rf_rdata3;
     
                pipe2_src2_data_internal = fifo_inst2_src2_is_imm ? fifo_inst2_imm
                                    :  rf_rdata4;
                pipe2_src1_internal = forward_src(
                        rf_raddr3,
                        ex2_we_i, ex2_waddr_i,
                        ex1_we_i, ex1_waddr_i,
                        mem2_we_i, mem2_waddr_i,
                        mem1_we_i, mem1_waddr_i
                    );
                 pipe2_src2_internal = forward_src(
                        rf_raddr4 ,
                        ex2_we_i, ex2_waddr_i,
                        ex1_we_i, ex1_waddr_i,
                        mem2_we_i, mem2_waddr_i,
                        mem1_we_i, mem1_waddr_i
                    );
                pipe2_mem_wdata_internal =  rf_rdata4;
            end
        end

        S_ISSUE2: begin
            // inst2 -> pipe1
            pipe1_src1_data_internal = fifo_inst2_src1_is_pc ? fifo_inst2_pc
                                : rf_rdata1;

            pipe1_src2_data_internal = fifo_inst2_src2_is_imm ? fifo_inst2_imm
                                : rf_rdata2;
            pipe1_src1_internal = forward_src(
                   rf_raddr1,
                    ex2_we_i, ex2_waddr_i,
                    ex1_we_i, ex1_waddr_i,
                    mem2_we_i, mem2_waddr_i,
                    mem1_we_i, mem1_waddr_i
                );
               pipe1_src2_internal = forward_src(
                    rf_raddr2,
                    ex2_we_i, ex2_waddr_i,
                    ex1_we_i, ex1_waddr_i,
                    mem2_we_i, mem2_waddr_i,
                    mem1_we_i, mem1_waddr_i
                );

            pipe1_mem_wdata_internal = rf_rdata2;
        end
    endcase
end
// 最终数据输出：根据valid信号选择输出数据或全0
always @(*) begin
    // ---------------- pipe1 ----------------
    if (pipe1_valid_o) begin
        pipe1_src1_data_o = pipe1_src1_data_internal;
        pipe1_src2_data_o = pipe1_src2_data_internal;
        pipe1_mem_wdata_o = pipe1_mem_wdata_internal;

        // 新增：前递来源标志输出
        pipe1_src1_o = pipe1_src1_internal;
        pipe1_src2_o = pipe1_src2_internal;
    end else begin
        pipe1_src1_data_o = 32'b0;
        pipe1_src2_data_o = 32'b0;
        pipe1_mem_wdata_o = 32'b0;

        pipe1_src1_o = 4'b0000;
        pipe1_src2_o = 4'b0000;
    end

    // ---------------- pipe2 ----------------
    if (pipe2_valid_o) begin
        pipe2_src1_data_o = pipe2_src1_data_internal;
        pipe2_src2_data_o = pipe2_src2_data_internal;
        pipe2_mem_wdata_o = pipe2_mem_wdata_internal;

        // 新增：前递来源标志输出
        pipe2_src1_o = pipe2_src1_internal;
        pipe2_src2_o = pipe2_src2_internal;
    end else begin
        pipe2_src1_data_o = 32'b0;
        pipe2_src2_data_o = 32'b0;
        pipe2_mem_wdata_o = 32'b0;

        pipe2_src1_o = 4'b0000;
        pipe2_src2_o = 4'b0000;
    end
end

// ------------------------------------------------------
// Register File Read Address / Enable 生成逻辑
// ------------------------------------------------------
always @(*) begin
    // 默认关闭所有读端口
    rf_raddr1 = 5'd0; rf_re1 = 1'b0;
    rf_raddr2 = 5'd0; rf_re2 = 1'b0;
    rf_raddr3 = 5'd0; rf_re3 = 1'b0;
    rf_raddr4 = 5'd0; rf_re4 = 1'b0;

    case (state)
        S_IDLE: begin
            // inst1 用端口1/2
            if (!fifo_inst1_src1_is_pc) begin
                rf_raddr1 = fifo_inst1_rf_raddr1;
                rf_re1    = (fifo_inst1_rf_raddr1 != 5'd0);
            end
            if (!fifo_inst1_src2_is_imm|fifo_inst1_mem_we) begin
                rf_raddr2 = fifo_inst1_rf_raddr2;
                rf_re2    = (fifo_inst1_rf_raddr2 != 5'd0);
            end

            // inst2 用端口3/4 （只有双发时才读）
            if (can_dual_issue) begin
                if (!fifo_inst2_src1_is_pc) begin
                    rf_raddr3 = fifo_inst2_rf_raddr1;
                    rf_re3    = (fifo_inst2_rf_raddr1 != 5'd0);
                end
                if (!fifo_inst2_src2_is_imm) begin
                    rf_raddr4 = fifo_inst2_rf_raddr2;
                    rf_re4    = (fifo_inst2_rf_raddr2 != 5'd0);
                end
            end
        end

        S_ISSUE2: begin
            // inst2 被挪到 pipe1，仍然用端口1/2
            if (!fifo_inst2_src1_is_pc) begin
                rf_raddr1 = fifo_inst2_rf_raddr1;
                rf_re1    = (fifo_inst2_rf_raddr1 != 5'd0);
            end
            if (!fifo_inst2_src2_is_imm|fifo_inst2_mem_we) begin
                rf_raddr2 = fifo_inst2_rf_raddr2;
                rf_re2    = (fifo_inst2_rf_raddr2 != 5'd0);
            end
        end
    endcase
end
endmodule