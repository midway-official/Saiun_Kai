//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/18 13:42:18
// Design Name: 
// Module Name: Saiun_Kai
// Project Name: 
// Target Devices: XC7A200T/XCKU5P
// Tool Versions: 
// Description:  loongarch双发射超标量处理器
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: loongarch双发射超标量处理器
// 
//////////////////////////////////////////////////////////////////////////////////

module Saiun_Kai(
     //=============================================
    // 时钟和复位信号
    //=============================================
    input   wire            clk,            // 系统时钟
    input   wire            rst,            // 系统复位（高电平有效）
    //=============================================
    // 访存接口
    //=============================================
    output  wire [31:0] mem_addr,
    output  wire [31:0] mem_wdata,
    input  wire [31:0]  mem_rdata,
    output  wire [3:0]  mem_sel_n,
    output  wire   mem_en,
    output  wire   mem_wen_n,
    output  wire   mem_done,
    //=============================================
    // 原子操作和同步信号
    //=============================================
    output  wire            LL,             // Load-Link指令输出
    output  wire            SC,             // Store-Conditional指令输出
    input   wire            SC_result,      // Store-Conditional执行结果
    //=============================================
    // 异常信号
    //============================================
    input   wire            EXTI          // 外部中断信号
    
    );

    // 内部时钟和复位信号连接
   

    // ======================= 流水线控制信号 =======================
    wire iq_is_full;                    // IQ队列满信号
    wire front_stall;                   // 访存仲裁前端暂停
    wire branch_taken;   // 分支跳转信号
    wire [31:0] branch_target;
    wire fu1_ex_is_load;               // FU1执行阶段是否为load指令
    wire fu2_ex_is_load;               // FU2执行阶段是否为load指令  
    wire fu1_mem_stall, fu2_mem_stall; // 访存暂停信号
    wire load_use_hazard;              // load-use冒险检测信号
    wire       backend_stall;
    // IFU暂停条件：外部暂停 || 访存仲裁前端暂停 || IQ队列满
    wire ifu_stall = EXTI || front_stall || iq_is_full;
    wire idu_stall = EXTI || front_stall || iq_is_full;
    // ISU暂停条件：外部暂停 || load-use冒险 || 访存暂停
    wire isu_stall = EXTI || load_use_hazard || fu1_mem_stall||backend_stall;
    
    // ISU复位条件：分支跳转时需要复位ISU
    wire isu_reset = rst || branch_taken ;
     wire idu_nop =  branch_taken;
    /* ================== IFU 实例化 ================== */
    wire [31:0] fetch_addr;
    wire        fetch_enable;
    wire        fetch_ready;
    wire [127:0] inst_package;
    wire        package_valid;
    wire [31:0] inst_from_baseram;

    IFU u_ifu (
        .clk(clk),
        .rst(rst),
        .stall(ifu_stall),                    // 修正：使用完整的暂停条件
        .inst_from_sram(inst_from_baseram),
        .branch_flag_i(branch_taken),
        .branch_address_i(branch_target),
        .fetch_addr_o(fetch_addr),
        .fetch_enable(fetch_enable),
        .fetch_ready(fetch_ready),
        .inst_package_o(inst_package),
        .package_valid(package_valid)
    );

    /* ================== IDU 实例化 ================== */
    // IDU输出信号定义
    wire        inst1_valid;
    wire        inst2_valid;

    // 指令1译码输出信号
    wire [15:0] inst1_alu_op;
    wire [31:0] inst1_imm;
    wire [31:0] inst1_br_offs;
    wire [31:0] inst1_jirl_offs;
    wire [4:0]  inst1_rf_raddr1;
    wire [4:0]  inst1_rf_raddr2;
    wire [4:0]  inst1_dest;
    wire [4:0]  inst1_special;
    wire [4:0]  inst1_mem_op;
    wire        inst1_gr_we;
    wire        inst1_mem_we;
    wire        inst1_res_from_mem;
    wire        inst1_src1_is_pc;
    wire        inst1_src2_is_imm;
    wire        inst1_dst_is_r1;
    wire [31:0] inst1_pc;
    wire        inst1_is_branch;
    wire        inst1_pred_taken;
    wire        inst1_is_conditional_branch;
    wire        inst1_is_jirl;
    wire        inst1_is_b;
    wire        inst1_is_bl;

    // 指令2译码输出信号
    wire [15:0] inst2_alu_op;
    wire [31:0] inst2_imm;
    wire [31:0] inst2_br_offs;
    wire [31:0] inst2_jirl_offs;
    wire [4:0]  inst2_rf_raddr1;
    wire [4:0]  inst2_rf_raddr2;
    wire [4:0]  inst2_dest;
    wire [4:0]  inst2_special;
    wire [4:0]  inst2_mem_op;
    wire        inst2_gr_we;
    wire        inst2_mem_we;
    wire        inst2_res_from_mem;
    wire        inst2_src1_is_pc;
    wire        inst2_src2_is_imm;
    wire        inst2_dst_is_r1;
    wire [31:0] inst2_pc;
    wire        inst2_is_branch;
    wire        inst2_pred_taken;
    wire        inst2_is_conditional_branch;
    wire        inst2_is_jirl;
    wire        inst2_is_b;
    wire        inst2_is_bl;

    IDU u_idu (
        .clk(clk),
        .rst(rst),
        .stall(idu_stall),
        .nop(idu_nop),
        // 来自IFU的输入
        .inst_package_i(inst_package),
        .package_valid_i(package_valid),
        
        // 输出到后端的微操作
        .inst1_valid_o(inst1_valid),
        .inst2_valid_o(inst2_valid),
        
        // 指令1译码输出
        .inst1_alu_op_o(inst1_alu_op),
        .inst1_imm_o(inst1_imm),
        .inst1_br_offs_o(inst1_br_offs),
        .inst1_jirl_offs_o(inst1_jirl_offs),
        .inst1_rf_raddr1_o(inst1_rf_raddr1),
        .inst1_rf_raddr2_o(inst1_rf_raddr2),
        .inst1_dest_o(inst1_dest),
        .inst1_special_o(inst1_special),
        .inst1_gr_we_o(inst1_gr_we),
        .inst1_mem_we_o(inst1_mem_we),
        .inst1_mem_op_o(inst1_mem_op),
        .inst1_res_from_mem_o(inst1_res_from_mem),
        .inst1_src1_is_pc_o(inst1_src1_is_pc),
        .inst1_src2_is_imm_o(inst1_src2_is_imm),
        .inst1_dst_is_r1_o(inst1_dst_is_r1),
        .inst1_pc_o(inst1_pc),
        .inst1_is_branch_o(inst1_is_branch),
        .inst1_pred_taken_o(inst1_pred_taken),
        .inst1_is_conditional_branch_o(inst1_is_conditional_branch),
        .inst1_is_jirl_o(inst1_is_jirl),
        .inst1_is_b_o(inst1_is_b),
        .inst1_is_bl_o(inst1_is_bl),
        
        // 指令2译码输出
        .inst2_alu_op_o(inst2_alu_op),
        .inst2_imm_o(inst2_imm),
        .inst2_br_offs_o(inst2_br_offs),
        .inst2_jirl_offs_o(inst2_jirl_offs),
        .inst2_rf_raddr1_o(inst2_rf_raddr1),
        .inst2_rf_raddr2_o(inst2_rf_raddr2),
        .inst2_dest_o(inst2_dest),
        .inst2_special_o(inst2_special),
        .inst2_gr_we_o(inst2_gr_we),
        .inst2_mem_we_o(inst2_mem_we),
        .inst2_mem_op_o(inst2_mem_op),
        .inst2_res_from_mem_o(inst2_res_from_mem),
        .inst2_src1_is_pc_o(inst2_src1_is_pc),
        .inst2_src2_is_imm_o(inst2_src2_is_imm),
        .inst2_dst_is_r1_o(inst2_dst_is_r1),
        .inst2_pc_o(inst2_pc),
        .inst2_is_branch_o(inst2_is_branch),
        .inst2_pred_taken_o(inst2_pred_taken),
        .inst2_is_conditional_branch_o(inst2_is_conditional_branch),
        .inst2_is_jirl_o(inst2_is_jirl),
        .inst2_is_b_o(inst2_is_b),
        .inst2_is_bl_o(inst2_is_bl)
    );

    /* ================== 寄存器堆 REG 实例化 ================== */
    wire [4:0]  rf_raddr1, rf_raddr2, rf_raddr3, rf_raddr4;
    wire        rf_re1, rf_re2, rf_re3, rf_re4;
    wire [31:0] rf_rdata1, rf_rdata2, rf_rdata3, rf_rdata4;
    
    // 写回信号
    wire        wb1_we, wb2_we;
    wire [4:0]  wb1_addr, wb2_addr;
    wire [31:0] wb1_data, wb2_data;

    REG u_reg (
        .clk(clk),
        .rst(rst),
        
        // 写端口1和2（来自两个执行单元的写回）
        .we1(wb2_we),
        .waddr1(wb2_addr),
        .wdata1(wb2_data),
        .we2(wb1_we),
        .waddr2(wb1_addr),
        .wdata2(wb1_data),
        
        // 读端口1-4（为双发射提供4个读端口）
        .re_1(rf_re1),
        .raddr_1(rf_raddr1),
        .rdata_1(rf_rdata1),
        .re_2(rf_re2),
        .raddr_2(rf_raddr2),
        .rdata_2(rf_rdata2),
        .re_3(rf_re3),
        .raddr_3(rf_raddr3),
        .rdata_3(rf_rdata3),
        .re_4(rf_re4),
        .raddr_4(rf_raddr4),
        .rdata_4(rf_rdata4)
    );

    /* ================== Load-Use 冒险检测逻辑 ================== */
    // 前递网络信号（来自执行单元）
    wire        fu1_ex_we, fu1_mem_we, fu2_ex_we, fu2_mem_we;
    wire [4:0]  fu1_ex_addr, fu1_mem_addr, fu2_ex_addr, fu2_mem_addr;
    wire [31:0] fu1_ex_data, fu1_mem_data, fu2_ex_data, fu2_mem_data;

    // Load-Use 冒险检测：
    // 如果FU的ex_is_load 且 FU的ex段目的寄存器和ISU中四个读寄存器只要有一个相同 就stall ISU
    assign load_use_hazard = 
        // FU1的load-use冒险检测
        (fu1_ex_is_load && fu1_ex_we && (
            (rf_re1 && (rf_raddr1 != 5'b0) && (rf_raddr1 == fu1_ex_addr)) ||
            (rf_re2 && (rf_raddr2 != 5'b0) && (rf_raddr2 == fu1_ex_addr)) ||
            (rf_re3 && (rf_raddr3 != 5'b0) && (rf_raddr3 == fu1_ex_addr)) ||
            (rf_re4 && (rf_raddr4 != 5'b0) && (rf_raddr4 == fu1_ex_addr))
        ));

    /* ================== ISU 实例化 ================== */
    
    // ISU输出到执行单元的信号
    wire        pipe1_valid, pipe2_valid;
    wire [15:0] pipe1_alu_op, pipe2_alu_op;
    wire [31:0] pipe1_src1_data, pipe1_src2_data, pipe1_mem_wdata;
    wire [31:0] pipe2_src1_data, pipe2_src2_data, pipe2_mem_wdata;
    wire [31:0] pipe1_pc, pipe2_pc;
    wire        pipe1_is_branch, pipe2_is_branch;
    wire        pipe1_pred_taken, pipe2_pred_taken;
    wire        pipe1_is_conditional_branch, pipe2_is_conditional_branch;
    wire        pipe1_is_jirl, pipe2_is_jirl;
    wire        pipe1_is_b, pipe2_is_b;
    wire        pipe1_is_bl, pipe2_is_bl;
    wire [31:0] pipe1_br_offs, pipe1_jirl_offs;
    wire [31:0] pipe2_br_offs, pipe2_jirl_offs;
    wire [4:0]  pipe1_dest, pipe2_dest;
    wire [4:0]  pipe1_special, pipe2_special;
    wire [4:0]  pipe1_mem_op, pipe2_mem_op;
    wire [4:0]  pipe1_rd, pipe2_rd;
    wire        pipe1_gr_we, pipe2_gr_we;
    wire        pipe1_mem_we, pipe2_mem_we;
    wire        pipe1_res_from_mem, pipe2_res_from_mem;
     wire pipe1_ready;
     wire pipe2_ready;
    ISU u_isu (
        .clk(clk),
        .rst(isu_reset),                      // 修正：分支跳转时复位ISU
        .stall(isu_stall),                    // 修正：使用完整的暂停条件
        .iq_is_full(iq_is_full),
        .FU1_ready(pipe1_ready),
        .FU2_ready(pipe2_ready),
        .load_use_hazard(load_use_hazard),
        // 来自IDU的指令输入
        .inst1_alu_op_i(inst1_alu_op),
        .inst1_imm_i(inst1_imm),
        .inst1_br_offs_i(inst1_br_offs),
        .inst1_jirl_offs_i(inst1_jirl_offs),
        .inst1_rf_raddr1_i(inst1_rf_raddr1),
        .inst1_rf_raddr2_i(inst1_rf_raddr2),
        .inst1_dest_i(inst1_dest),
        .inst1_special_i(inst1_special),
        .inst1_mem_op_i(inst1_mem_op),
        .inst1_gr_we_i(inst1_gr_we),
        .inst1_mem_we_i(inst1_mem_we),
        .inst1_res_from_mem_i(inst1_res_from_mem),
        .inst1_src1_is_pc_i(inst1_src1_is_pc),
        .inst1_src2_is_imm_i(inst1_src2_is_imm),
        .inst1_dst_is_r1_i(inst1_dst_is_r1),
        .inst1_pc_i(inst1_pc),
        .inst1_is_branch_i(inst1_is_branch),
        .inst1_pred_taken_i(inst1_pred_taken),
        .inst1_is_conditional_branch_i(inst1_is_conditional_branch),
        .inst1_is_jirl_i(inst1_is_jirl),
        .inst1_is_b_i(inst1_is_b),
        .inst1_is_bl_i(inst1_is_bl),

        .inst2_alu_op_i(inst2_alu_op),
        .inst2_imm_i(inst2_imm),
        .inst2_br_offs_i(inst2_br_offs),
        .inst2_jirl_offs_i(inst2_jirl_offs),
        .inst2_rf_raddr1_i(inst2_rf_raddr1),
        .inst2_rf_raddr2_i(inst2_rf_raddr2),
        .inst2_dest_i(inst2_dest),
        .inst2_special_i(inst2_special),
        .inst2_mem_op_i(inst2_mem_op),
        .inst2_gr_we_i(inst2_gr_we),
        .inst2_mem_we_i(inst2_mem_we),
        .inst2_res_from_mem_i(inst2_res_from_mem),
        .inst2_src1_is_pc_i(inst2_src1_is_pc),
        .inst2_src2_is_imm_i(inst2_src2_is_imm),
        .inst2_dst_is_r1_i(inst2_dst_is_r1),
        .inst2_pc_i(inst2_pc),
        .inst2_is_branch_i(inst2_is_branch),
        .inst2_pred_taken_i(inst2_pred_taken),
        .inst2_is_conditional_branch_i(inst2_is_conditional_branch),
        .inst2_is_jirl_i(inst2_is_jirl),
        .inst2_is_b_i(inst2_is_b),
        .inst2_is_bl_i(inst2_is_bl),

        .idu_valid(inst1_valid | inst2_valid),

        // Register File Interface
        .rf_raddr1(rf_raddr1),
        .rf_re1(rf_re1),
        .rf_raddr2(rf_raddr2),
        .rf_re2(rf_re2),
        .rf_raddr3(rf_raddr3),
        .rf_re3(rf_re3),
        .rf_raddr4(rf_raddr4),
        .rf_re4(rf_re4),

        .rf_rdata1(rf_rdata1),
        .rf_rdata2(rf_rdata2),
        .rf_rdata3(rf_rdata3),
        .rf_rdata4(rf_rdata4),

        // Forwarding 输入
        .ex1_we_i(fu1_ex_we),
        .ex1_waddr_i(fu1_ex_addr),
        .ex1_wdata_i(fu1_ex_data),

        .mem1_we_i(fu1_mem_we),
        .mem1_waddr_i(fu1_mem_addr),
        .mem1_wdata_i(fu1_mem_data),

        .ex2_we_i(fu2_ex_we),
        .ex2_waddr_i(fu2_ex_addr),
        .ex2_wdata_i(fu2_ex_data),

        .mem2_we_i(fu2_mem_we),
        .mem2_waddr_i(fu2_mem_addr),
        .mem2_wdata_i(fu2_mem_data),

        // Pipeline 输出
        .pipe1_valid_o(pipe1_valid),
        .pipe1_alu_op_o(pipe1_alu_op),
        .pipe1_src1_data_o(pipe1_src1_data),
        .pipe1_src2_data_o(pipe1_src2_data),
        .pipe1_mem_wdata_o(pipe1_mem_wdata),
        .pipe1_pc_o(pipe1_pc),
        .pipe1_is_branch_o(pipe1_is_branch),
        .pipe1_pred_taken_o(pipe1_pred_taken),
        .pipe1_is_conditional_branch_o(pipe1_is_conditional_branch),
        .pipe1_is_jirl_o(pipe1_is_jirl),
        .pipe1_is_b_o(pipe1_is_b),
        .pipe1_is_bl_o(pipe1_is_bl),
        .pipe1_br_offs_o(pipe1_br_offs),
        .pipe1_jirl_offs_o(pipe1_jirl_offs),
        .pipe1_dest_o(pipe1_dest),
        .pipe1_special_o(pipe1_special),
        .pipe1_mem_op_o(pipe1_mem_op),
        .pipe1_rd_o(pipe1_rd),
        .pipe1_gr_we_o(pipe1_gr_we),
        .pipe1_mem_we_o(pipe1_mem_we),
        .pipe1_res_from_mem_o(pipe1_res_from_mem),

        .pipe2_valid_o(pipe2_valid),
        .pipe2_alu_op_o(pipe2_alu_op),
        .pipe2_src1_data_o(pipe2_src1_data),
        .pipe2_src2_data_o(pipe2_src2_data),
        .pipe2_mem_wdata_o(pipe2_mem_wdata),
        .pipe2_pc_o(pipe2_pc),
        .pipe2_is_branch_o(pipe2_is_branch),
        .pipe2_pred_taken_o(pipe2_pred_taken),
        .pipe2_is_conditional_branch_o(pipe2_is_conditional_branch),
        .pipe2_is_jirl_o(pipe2_is_jirl),
        .pipe2_is_b_o(pipe2_is_b),
        .pipe2_is_bl_o(pipe2_is_bl),
        .pipe2_br_offs_o(pipe2_br_offs),
        .pipe2_jirl_offs_o(pipe2_jirl_offs),
        .pipe2_dest_o(pipe2_dest),
        .pipe2_special_o(pipe2_special),
        .pipe2_mem_op_o(pipe2_mem_op),
        .pipe2_rd_o(pipe2_rd),
        .pipe2_gr_we_o(pipe2_gr_we),
        .pipe2_mem_we_o(pipe2_mem_we),
        .pipe2_res_from_mem_o(pipe2_res_from_mem)
    );

    /* ================== 执行单元1 (支持访存) ================== */

    // 流水线控制信号
    // 修正：mem_stall为高时暂停ISU IS_EX EX_mem寄存器

    wire        is_ex_stall1 = EXTI || fu1_mem_stall||backend_stall;
    wire        is_ex_nop1 = load_use_hazard||branch_taken;
    wire        ex_mem_stall1 = EXTI || fu1_mem_stall||backend_stall;
    wire        ex_mem_nop1 = 1'b0;
    wire        mem_wb_stall1 = EXTI|| fu1_mem_stall||backend_stall;
    wire        mem_wb_nop1 = 1'b0;
    wire [31:0] fu1_mem_addr_out, fu1_mem_wdata_out;
    wire [31:0] fu1_mem_rdata;
    wire        fu1_mem_ready, fu1_mem_ce, fu1_mem_ll, fu1_mem_sc;
    wire        fu1_sc_success;
    wire [3:0]  fu1_mem_sel_n;
    wire        fu1_mem_we_n;
    FU u_fu1 (
        .clk(clk),
        .rst(rst),
        .backend_stall(backend_stall),
        // 来自ISU的输入
        .valid_i(pipe1_valid),
        .ready_o(pipe1_ready),
        .alu_op_i(pipe1_alu_op),
        .src1_data_i(pipe1_src1_data),
        .src2_data_i(pipe1_src2_data),
        .mem_wdata_i(pipe1_mem_wdata),
        .pc_i(pipe1_pc),
        .is_branch_i(pipe1_is_branch),
        .pred_taken_i(pipe1_pred_taken),
        .is_conditional_branch_i(pipe1_is_conditional_branch),
        .is_jirl_i(pipe1_is_jirl),
        .is_b_i(pipe1_is_b),
        .is_bl_i(pipe1_is_bl),
        .br_offs_i(pipe1_br_offs),
        .jirl_offs_i(pipe1_jirl_offs),
        .dest_i(pipe1_dest),
        .special_i(pipe1_special),
        .mem_op_i(pipe1_mem_op),
        .rd_i(pipe1_rd),
        .gr_we_i(pipe1_gr_we),
        .mem_we_i(pipe1_mem_we),
        .res_from_mem_i(pipe1_res_from_mem),
        
        // 流水线控制
        .is_ex_stall(is_ex_stall1),
        .is_ex_nop(is_ex_nop1),
        .ex_mem_stall(ex_mem_stall1),
        .ex_mem_nop(ex_mem_nop1),
        .mem_wb_stall(mem_wb_stall1),
        .mem_wb_nop(mem_wb_nop1),
        
        // load-use冒险检测
        .ex_is_load(fu1_ex_is_load),
        .mem_stall(fu1_mem_stall),
        
        // 访存接口（连接到MAU）
        .mem_addr(fu1_mem_addr_out),
        .mem_data(fu1_mem_wdata_out),
        .mem_we_n(fu1_mem_we_n),
        .mem_sel_n(fu1_mem_sel_n),
        .mem_ready(fu1_mem_ready),
        .mem_ce(fu1_mem_ce),
        .mem_ll(fu1_mem_ll),
        .mem_sc(fu1_mem_sc),
        .mem_sc_success(fu1_sc_success),
        .mem_data_i(fu1_mem_rdata),
        
        // 写回寄存器堆
        .wb_dest_o(wb1_addr),
        .wb_gr_we_o(wb1_we),
        .wb_data_o(wb1_data),
        
        // 前递网络
        .ex_dest_o(fu1_ex_addr),
        .ex_gr_we_o(fu1_ex_we),
        .ex_wdata_o(fu1_ex_data),
        .mem_dest_o(fu1_mem_addr),
        .mem_gr_we_o(fu1_mem_we),
        .mem_wdata_o(fu1_mem_data),
        
        // 分支跳转结果
        .branch_taken_o(branch_taken),
        .branch_target_o(branch_target)
    );

    /* ================== 执行单元2 (不支持访存，但可能支持算术load指令) ================== */
    wire        is_ex_stall2 =  is_ex_stall1;
    wire        is_ex_nop2 =is_ex_nop1;
    wire        ex_mem_stall2 =  ex_mem_stall1;
    wire        ex_mem_nop2 = ex_mem_nop1;
    wire        mem_wb_stall2 = mem_wb_stall1;
    wire        mem_wb_nop2 = mem_wb_nop1;

    FU_R u_fu2 (
        .clk(clk),
        .rst(rst),
        
        // 来自ISU的输入（简化版，不支持访存）
        .valid_i(pipe2_valid), // 过滤掉访存指令
        .ready_o(pipe2_ready),
        .alu_op_i(pipe2_alu_op),
        .src1_data_i(pipe2_src1_data),
        .src2_data_i(pipe2_src2_data),
        .dest_i(pipe2_dest),
        .gr_we_i(pipe2_gr_we),
        
        // 流水线控制
        .is_ex_stall(is_ex_stall2),
        .is_ex_nop(is_ex_nop2),
        .ex_mem_stall(ex_mem_stall2),
        .ex_mem_nop(ex_mem_nop2),
        .mem_wb_stall(mem_wb_stall2),
        .mem_wb_nop(mem_wb_nop2),
        
        
        // 前递网络
        .ex_dest_o(fu2_ex_addr),
        .ex_gr_we_o(fu2_ex_we),
        .ex_wdata_o(fu2_ex_data),
        .mem_dest_o(fu2_mem_addr),
        .mem_gr_we_o(fu2_mem_we),
        .mem_wdata_o(fu2_mem_data),
        
        
        // 写回寄存器堆
        .wb_dest_o(wb2_addr),
        .wb_gr_we_o(wb2_we),
        .wb_data_o(wb2_data)
    );

    /* ================== 访存仲裁单元 MAU 实例化 ================== */


    MAU u_mau (
         .clk(clk),
        .rst(rst),
        .branch(branch_taken),
        .iq_full( iq_is_full),
        // 指令访存接口
        .inst_addr(fetch_addr),
        .inst_rdata(inst_from_baseram),
        .inst_ce(fetch_enable),
        .inst_done(fetch_ready),
        
        // 数据访存接口（来自FU1）
        .data_addr(fu1_mem_addr_out),
        .data_wdata(fu1_mem_wdata_out),
        .data_rdata(fu1_mem_rdata),
        .data_sel_n(fu1_mem_sel_n),
        .data_ce(fu1_mem_ce),
        .data_wen_n(fu1_mem_we_n),
        .data_done(fu1_mem_ready),
        
        // 原子操作控制信号
        .ll_i(fu1_mem_ll),
        .sc_i(fu1_mem_sc),
        
        // 仲裁控制输出
        .front_stall(front_stall),
        .back_stall(backend_stall),
        // 存储器总线接口（连接到顶层模块接口）
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_sel(mem_sel_n),
        .mem_en(mem_en),
        .mem_wen_n(mem_wen_n),
        .ll_o(LL),
        .sc_o(SC),
        .mem_done(mem_done)
    );

    // SC 操作结果反馈
    assign fu1_sc_success = SC_result;

    /* ================== 流水线状态监控和调试信号 ================== */
    // 可选：添加一些调试信号来监控流水线状态
    `ifdef DEBUG
    wire [31:0] debug_ifu_pc = fetch_addr;
    wire        debug_ifu_stall = ifu_stall;
    wire        debug_isu_stall = isu_stall;
    wire        debug_load_use_hazard = load_use_hazard;
    wire        debug_branch_taken = branch_taken || branch_taken2;
    wire        debug_front_stall = front_stall;
    wire        debug_iq_full = iq_is_full;
    wire        debug_mem_stall = fu1_mem_stall || fu2_mem_stall;
    `endif

endmodule