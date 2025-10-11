module IDU(
    input  wire         clk,
    input  wire         rst,
    input  wire          stall,
    input  wire          nop,
    // 来自IFU的输入
    input  wire [127:0] inst_package_i,     // 指令包
    input  wire         package_valid_i,    // 指令包有效
    
    // 输出到后端的微操作
    output wire         inst1_valid_o,      // 指令1有效
    output wire         inst2_valid_o,      // 指令2有效
    
    // 指令1译码输出
    output wire [15:0]  inst1_alu_op_o,     // ALU操作类型 (注意改为16位)
    output wire [31:0]  inst1_imm_o,        // 立即数
    output wire [31:0]  inst1_br_offs_o,    // 分支偏移
    output wire [31:0]  inst1_jirl_offs_o,  // jirl偏移
    output wire [4:0]   inst1_rf_raddr1_o,  // 读端口1地址
    output wire [4:0]   inst1_rf_raddr2_o,  // 读端口2地址
    output wire [4:0]   inst1_dest_o,       // 目的寄存器
    output wire [4:0]   inst1_special_o,    // 特殊操作类型
    output wire [4:0]   inst1_mem_op_o,    // 访存操作类型
    output wire         inst1_gr_we_o,      // 寄存器写使能
    output wire         inst1_mem_we_o,     // 存储器写使能
    output wire         inst1_res_from_mem_o, // 结果来自存储器
    output wire         inst1_src1_is_pc_o, // 源操作数1是PC
    output wire         inst1_src2_is_imm_o,// 源操作数2是立即数
    output wire         inst1_dst_is_r1_o,  // 目的寄存器是r1
    output wire [31:0]  inst1_pc_o,         // 指令1的PC
    output wire         inst1_is_branch_o,  // 是否分支指令
    output wire         inst1_pred_taken_o, // 预测跳转
    // 新增分支控制信号
    output wire         inst1_is_conditional_branch_o, // 条件分支
    output wire         inst1_is_jirl_o,              // JIRL指令
    output wire         inst1_is_b_o,                 // B指令
    output wire         inst1_is_bl_o,                // BL指令
    
    // 指令2译码输出
    output wire [15:0]  inst2_alu_op_o,     // ALU操作类型 (注意改为16位)
    output wire [31:0]  inst2_imm_o,        // 立即数
    output wire [31:0]  inst2_br_offs_o,    // 分支偏移
    output wire [31:0]  inst2_jirl_offs_o,  // jirl偏移
    output wire [4:0]   inst2_rf_raddr1_o,  // 读端口1地址
    output wire [4:0]   inst2_rf_raddr2_o,  // 读端口2地址
    output wire [4:0]   inst2_dest_o,       // 目的寄存器
    output wire [4:0]   inst2_special_o,    // 特殊操作类型
    output wire [4:0]   inst2_mem_op_o,    // 访存操作类型
    output wire         inst2_gr_we_o,      // 寄存器写使能
    output wire         inst2_mem_we_o,     // 存储器写使能
    output wire         inst2_res_from_mem_o, // 结果来自存储器
    output wire         inst2_src1_is_pc_o, // 源操作数1是PC
    output wire         inst2_src2_is_imm_o,// 源操作数2是立即数
    output wire         inst2_dst_is_r1_o,  // 目的寄存器是r1
    output wire [31:0]  inst2_pc_o,         // 指令2的PC
    output wire         inst2_is_branch_o,  // 是否分支指令
    output wire         inst2_pred_taken_o, // 预测跳转
    // 新增分支控制信号
    output wire         inst2_is_conditional_branch_o, // 条件分支
    output wire         inst2_is_jirl_o,              // JIRL指令
    output wire         inst2_is_b_o,                 // B指令
    output wire         inst2_is_bl_o                 // BL指令
);
wire [63:0] cnt;
counter64 counter64(
.clk(clk),
.rst(rst),
.count(cnt)

);
// ---- ID 级寄存器：寄存 IF 发来的包（采样点） ----
reg [127:0] inst_package_r;
reg         package_valid_r;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        inst_package_r  <= 128'b0;
        package_valid_r <= 1'b0;
    end else begin
        if (nop) begin
            // nop 优先：插入气泡
            inst_package_r  <= 128'b0;
            package_valid_r <= 1'b0;
        end else if (stall) begin
            // stall：冻结
            inst_package_r  <= inst_package_r;
            package_valid_r <= package_valid_r;
        end else begin
            // 正常采样
            inst_package_r  <= inst_package_i;
            package_valid_r <= package_valid_i;
        end
    end
end

// 解析指令包
wire [31:0] if1_pc              = inst_package_r [127:96];
wire [31:0] if1_inst1           = inst_package_r [95:64];
wire [31:0] if1_inst2           =inst_package_r [63:32];
wire        if1_inst1_valid     = inst_package_r [31];
wire        if1_inst2_valid     =inst_package_r [30];
wire        inst1_is_branch     =inst_package_r [29];
wire        inst1_pred_taken    =inst_package_r [28];
wire        inst2_is_branch     =inst_package_r [27];
wire        inst2_pred_taken    = inst_package_r [26];

// 指令有效信号
assign inst1_valid_o = package_valid_r & if1_inst1_valid&!stall;
assign inst2_valid_o = package_valid_r & if1_inst2_valid&!stall;

// 指令1译码
wire [31:0] inst1 = if1_inst1;
dual_inst_decoder u_inst1_decoder(
    .inst               (inst1),
    .pc                 (if1_pc),
    .cnt                  (cnt),
    .alu_op             (inst1_alu_op_o),
    .imm                (inst1_imm_o),
    .br_offs            (inst1_br_offs_o),
    .jirl_offs          (inst1_jirl_offs_o),
    .rf_raddr1          (inst1_rf_raddr1_o),
    .rf_raddr2          (inst1_rf_raddr2_o),
    .dest               (inst1_dest_o),
    .special            (inst1_special_o),
    .mem_op             (inst1_mem_op_o),
    .gr_we              (inst1_gr_we_o),
    .mem_we             (inst1_mem_we_o),
    .res_from_mem       (inst1_res_from_mem_o),
    .src1_is_pc         (inst1_src1_is_pc_o),
    .src2_is_imm        (inst1_src2_is_imm_o),
    
    .dst_is_r1          (inst1_dst_is_r1_o),
    // 新增分支控制信号连接
    .is_conditional_branch (inst1_is_conditional_branch_o),
    .is_jirl            (inst1_is_jirl_o),
    .is_b               (inst1_is_b_o),
    .is_bl              (inst1_is_bl_o)
);

// 指令2译码
wire [31:0] inst2 = if1_inst2;
wire [31:0] inst2_pc = if1_pc + 4; // 第二条指令的PC
dual_inst_decoder u_inst2_decoder(
    .inst               (inst2),
    .pc                 (inst2_pc),
    .cnt                  (cnt),
    .alu_op             (inst2_alu_op_o),
    .imm                (inst2_imm_o),
    .br_offs            (inst2_br_offs_o),
    .jirl_offs          (inst2_jirl_offs_o),
    .rf_raddr1          (inst2_rf_raddr1_o),
    .rf_raddr2          (inst2_rf_raddr2_o),
    .dest               (inst2_dest_o),
    .special            (inst2_special_o),
    .mem_op             (inst2_mem_op_o),
    .gr_we              (inst2_gr_we_o),
    .mem_we             (inst2_mem_we_o),
    .res_from_mem       (inst2_res_from_mem_o),
    .src1_is_pc         (inst2_src1_is_pc_o),
    .src2_is_imm        (inst2_src2_is_imm_o),
    
    .dst_is_r1          (inst2_dst_is_r1_o),
    // 新增分支控制信号连接
    .is_conditional_branch (inst2_is_conditional_branch_o),
    .is_jirl            (inst2_is_jirl_o),
    .is_b               (inst2_is_b_o),
    .is_bl              (inst2_is_bl_o)
);

// 输出PC和分支预测信息
assign inst1_pc_o = if1_pc;
assign inst2_pc_o = inst2_pc;
assign inst1_is_branch_o = inst1_is_branch;
assign inst2_is_branch_o = inst2_is_branch;
assign inst1_pred_taken_o = inst1_pred_taken;
assign inst2_pred_taken_o = inst2_pred_taken;

endmodule

// 单条指令译码器模块
module dual_inst_decoder(
   
    input  wire [31:0]  inst,
    input  wire [31:0]  pc,
    input   wire [63:0]  cnt,
    output wire [15:0]  alu_op,
    output wire [31:0]  imm,
    output wire [31:0]  br_offs,
    output wire [31:0]  jirl_offs,
    output wire [4:0]   rf_raddr1,
    output wire [4:0]   rf_raddr2,
    output wire [4:0]   dest,
    output wire [4:0]   special,
    output wire [4:0]   mem_op,
    output wire         gr_we,
    output wire         mem_we,
    output wire         res_from_mem,
    output wire         src1_is_pc,
    output wire         src2_is_imm,
    
    output wire         is_conditional_branch,
    output wire         is_jirl,
    output wire         is_b,
    output wire         is_bl,
    output wire         dst_is_r1
);

// 指令字段解析
wire [5:0]  op_31_26  = inst[31:26];
wire [3:0]  op_25_22  = inst[25:22];
wire [1:0]  op_21_20  = inst[21:20];
wire [4:0]  op_19_15  = inst[19:15];

wire [4:0]  rd   = inst[ 4: 0];
wire [4:0]  rj   = inst[ 9: 5];
wire [4:0]  rk   = inst[14:10];
wire [4:0]  ui5   = inst[14:10];
wire [11:0] i12  = inst[21:10];
wire [19:0] i20  = inst[24: 5];
wire [15:0] i16  = inst[25:10];
wire [25:0] i26  = {inst[ 9: 0], inst[25:10]};
wire [13:0] i14  = inst[23:10];  // si14字段

// 译码器实例化
wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [3:0]  op_21_20_d;
wire [31:0] op_19_15_d;
//one-hot编码
decoder_6_64 u_dec0(.in(op_31_26), .out(op_31_26_d));
decoder_4_16 u_dec1(.in(op_25_22), .out(op_25_22_d));
decoder_2_4  u_dec2(.in(op_21_20), .out(op_21_20_d));
decoder_5_32 u_dec3(.in(op_19_15), .out(op_19_15_d));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];

assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];

assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];

assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~inst[25];

// 新增指令译码
wire inst_ll_w = op_31_26_d[6'h08] & ~inst[24];
wire inst_sc_w = op_31_26_d[6'h08] & inst[24];
wire  inst_ld_b = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
wire  inst_st_b = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
wire  inst_pcaddu12i = op_31_26_d[6'h07] & ~inst[25];
wire inst_mul_w = op_31_26_d[6'h00] & op_25_22_d[4'h0]
                  & op_21_20_d[2'h1] & op_19_15_d[5'h18];
                  

                  
// 新增立即数逻辑指令译码
wire inst_andi  = op_31_26_d[6'h00] & op_25_22_d[4'hd];
wire inst_ori   = op_31_26_d[6'h00] & op_25_22_d[4'he];
wire inst_xori  = op_31_26_d[6'h00] & op_25_22_d[4'hf];
wire inst_RDCNTVL_W = (inst[31:15] == 17'b0) & (inst[14:10] == 5'b11000);
wire inst_RDCNTVH_W = (inst[31:15] == 17'b0) & (inst[14:10] == 5'b11001);

// ALU操作选择
assign alu_op[0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w | inst_jirl | inst_bl |
                   inst_ll_w | inst_sc_w | inst_ld_b | inst_st_b| inst_pcaddu12i|inst_RDCNTVL_W|inst_RDCNTVH_W;  // 加法运算
assign alu_op[1] = inst_sub_w;                                      // 减法运算
assign alu_op[2] = inst_slt;                                        // 有符号比较
assign alu_op[3] = inst_sltu;                                       // 无符号比较
assign alu_op[4] = inst_and | inst_andi;   // 与
assign alu_op[5] = inst_nor;                                        // 或非运算
assign alu_op[6] = inst_or  | inst_ori;    // 或
assign alu_op[7] = inst_xor | inst_xori;   // 异或
assign alu_op[8] = inst_slli_w;                                     // 左移
assign alu_op[9] = inst_srli_w;                                     // 逻辑右移
assign alu_op[10]= inst_srai_w;                                     // 算术右移
assign alu_op[11]= inst_lu12i_w;      // lu12i 只填imm
assign alu_op[12]=  inst_mul_w;   //乘法指令
assign alu_op[13]= inst_beq;      //相等比较
assign alu_op[14]= inst_bne;      //不相等比较
assign alu_op[15]= 0;             //预留
// 立即数类型检测
wire need_ui5   = inst_slli_w | inst_srli_w | inst_srai_w;
wire need_si12  = inst_addi_w | inst_ld_w | inst_st_w | inst_ld_b | inst_st_b;
wire need_ui12  = inst_andi | inst_ori | inst_xori;
wire need_si14  = inst_ll_w | inst_sc_w;
wire need_si16  = inst_beq | inst_bne;
wire need_si20  = inst_lu12i_w | inst_pcaddu12i;
wire need_si26  = inst_b | inst_bl;
wire need_cnt_L = inst_RDCNTVL_W;
wire need_cnt_H  = inst_RDCNTVH_W;
wire src2_is_4 =    inst_bl;

// 立即数计算



assign imm =  
             need_cnt_L ? cnt[31:0] :
             need_cnt_H ? cnt[63:32] :
             src2_is_4 ? 32'h4 :
             need_si20 ? {i20[19:0], 12'b0} :
             need_si14 ? {{18{i14[13]}}, i14[13:0]} :
             need_ui12 ? {20'b0, i12[11:0]} :   // 无符号扩展
             need_ui5  ? {27'b0, ui5[4:0]} :        // ui5处理
             need_si12 ? {{20{i12[11]}}, i12[11:0]} :
             need_si16 ? {{14{i16[15]}}, i16[15:0], 2'b0} :
             need_si26 ? {{4{i26[25]}}, i26[25:0], 2'b0} :
             32'b0;

// 分支偏移计算
assign br_offs = need_si26 ? {{4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0};

// jirl偏移计算
assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

// 源寄存器是rd的情况
wire src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_st_b | inst_sc_w ;

// 控制信号
assign src1_is_pc    =  inst_bl | inst_pcaddu12i;
assign src2_is_imm = inst_slli_w | inst_srli_w | inst_srai_w | inst_addi_w |
                     inst_ld_w | inst_st_w | inst_lu12i_w | inst_jirl | inst_bl |
                     inst_ll_w | inst_sc_w | inst_ld_b | inst_st_b | inst_pcaddu12i |
                     inst_andi | inst_ori | inst_xori|inst_RDCNTVL_W|inst_RDCNTVH_W;

assign res_from_mem  = inst_ld_w | inst_ld_b|inst_ll_w ;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & ~inst_st_b;//SC指令需要返回写入结果
assign mem_we        = inst_st_w | inst_st_b | inst_sc_w;

assign mem_op[0]     = inst_ld_w|inst_ll_w|inst_st_w|inst_sc_w;//整字访问
assign mem_op[1]     = inst_ld_b|inst_st_b;//字节访问
assign mem_op[2]     = 0;
assign mem_op[3]     = 0;
assign mem_op[4]     = 0;

assign dest          = dst_is_r1 ? 5'd1 : rd;
assign special       = inst_ll_w ? 5'd1 :
                       inst_sc_w ? 5'd2 :
                       5'd0;
                       
//分支指令控制信号
assign is_conditional_branch = inst_beq | inst_bne;
assign  is_jirl =    inst_jirl;
assign  is_b    =    inst_b;
assign  is_bl   =    inst_bl; 
// 寄存器地址
assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd : rk;

endmodule

module decoder_2_4(
    input  wire [ 1:0] in,
    output wire [ 3:0] out
);

genvar i;
generate for (i=0; i<4; i=i+1) begin : gen_for_dec_2_4
    assign out[i] = (in == i);
end endgenerate

endmodule


module decoder_4_16(
    input  wire [ 3:0] in,
    output wire [15:0] out
);

genvar i;
generate for (i=0; i<16; i=i+1) begin : gen_for_dec_4_16
    assign out[i] = (in == i);
end endgenerate

endmodule


module decoder_5_32(
    input  wire [ 4:0] in,
    output wire [31:0] out
);

genvar i;
generate for (i=0; i<32; i=i+1) begin : gen_for_dec_5_32
    assign out[i] = (in == i);
end endgenerate

endmodule


module decoder_6_64(
    input  wire [ 5:0] in,
    output wire [63:0] out
);

genvar i;
generate for (i=0; i<64; i=i+1) begin : gen_for_dec_6_64
    assign out[i] = (in == i);
end endgenerate

endmodule
module counter64 (
    input  wire clk,   // 时钟信号
    input  wire rst,   // 异步复位，高电平有效
    output reg  [63:0] count  // 64位计数输出
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= 64'd0;              // 复位清零
        else
            count <= count + 64'd1;      // 每个时钟周期加1，自动回绕
    end

endmodule
