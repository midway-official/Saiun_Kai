

/*定义常用的常量*/
`define     PC_START_ADDR   32'h80000000    // PC起始地址

`define     RstEnable       1'b1            //复位使能
`define     RstDisable      1'b0            //复位除能
`define     WriteEnable     1'b1            //写使能
`define     WriteEnable_n   1'b0            //写使能（低有效）
`define     WriteDisable    1'b0            //写除能
`define     WriteDisable_n  1'b1            //写除能（高有效）
`define     ReadEnable      1'b1            //读使能
`define     ReadDisable     1'b0            //读除能
`define     ChipEnable      1'b1            //芯片使能
`define     ChipDisable     1'b0            //芯片禁止
`define     ZeroWord        32'h00000000    //32位数字0
`define     Branch          1'b1            //跳转
`define     NotBranch       1'b0            //不跳转
`define     Stop            1'b1            //停止
`define     NoStop          1'b0            //不停止
`define     NOPRegAddr      5'b00000        //空操作使用的寄存器地址

`define     LL_OP           6'b110000       // LL
`define     SC_OP           6'b111000       // SW
`define     SYNC_FUNC       6'b001111       // SYNC
`define     SH_OP           6'b101001      // SW
`define     LH_OP           6'b100001      // SW
module IFU (
    input wire          clk,
    input wire          rst,
    input wire          stall,              // 外部停顿信号
    input wire [31:0]   inst_from_sram,     // 来自SRAM的指令
    
    input wire          branch_flag_i,      // 分支执行结果
    input wire [31:0]   branch_address_i,   // 分支目标地址
    
    output reg [31:0]  fetch_addr_o,       // 取指地址输出给SRAM
    output reg         fetch_enable,       // 取指使能输出给SRAM
    output wire        fetch_ready,
    output wire [127:0] inst_package_o,     // 指令包输出 (128位)
    output wire        package_valid       // 指令包有效信号
);

// IF1状态机状态定义
parameter IF1_IDLE = 3'b000;
parameter IF1_FETCH_INST1 = 3'b001;
parameter IF1_FETCH_INST2 = 3'b010;

reg [2:0] if1_state, if1_next_state;

// PC寄存器
reg [31:0] pc_reg;
reg        pc_ce;

// IF1级寄存器（唯一的寄存器级）
reg [31:0] if1_pc;
reg [31:0] if1_inst1;
reg [31:0] if1_inst2;
reg        if1_inst1_valid;
reg        if1_inst2_valid;


// Icache接口信号
wire [31:0] icache_inst1;
wire [31:0] icache_inst2;
wire        icache_inst2_valid;
wire        icache_hit1;
wire        icache_hit2;
wire        icache_stall;
wire        icache_active;
wire        inst_stop;

// 分支预测相关信号（组合逻辑）
wire       inst1_is_branch;
wire       inst1_pred_taken;
wire [31:0] inst1_pred_target;
wire       inst2_is_branch;
wire       inst2_pred_taken;
wire [31:0] inst2_pred_target;

// 内部控制信号
reg [31:0]  icache_addr;
reg         icache_ce;
reg         pc_stall;

// 例化Icache模块
Icache  u_Icache (
    .clk            (clk),
    .rst            (rst),
   .branch      (branch_flag_i),
    .rom_addr_i     (icache_addr),
    .rom_ce_i       (icache_ce),
    .inst_o         (icache_inst1),
    .inst2_o        (icache_inst2),
    .inst2_valid    (icache_inst2_valid),
    .stall          (icache_stall),
    .Icache_hit     (icache_hit1),
    .Icache_active  (icache_active),
    .inst_stop      (inst_stop),
    .inst_i         (inst_from_sram)
);
assign inst_stop = stall;
// 计算第二条指令的命中情况
wire [31:0] pc_plus4 = pc_reg + 32'h4;
assign icache_hit2 = icache_inst2_valid;
assign fetch_ready = (if1_state == IF1_IDLE) &&( icache_hit1 &&icache_hit2);
  
// PC更新优先级：分支修正 > 停顿保持 > 预测跳转 > 正常递增
always @(posedge clk) begin
    if (rst == `RstEnable) begin
        pc_ce  <= `ChipDisable;
        pc_reg <= `PC_START_ADDR;
    end else begin
        pc_ce <= `ChipEnable;

        if (branch_flag_i == `Branch) begin
            pc_reg <= branch_address_i;              // 分支优先级最高
        end else if (inst1_is_branch && inst1_pred_taken) begin
            pc_reg <= inst1_pred_target;             // 预测第一条跳转
        end else if (inst2_is_branch && inst2_pred_taken) begin
            pc_reg <= inst2_pred_target;             // 预测第二条跳转
        end  else if (stall || pc_stall ) begin
            pc_reg <= pc_reg;                        // stall 冻结
        end  else  begin
            pc_reg <= pc_reg + 32'h8;                // 正常取两条
        end
    end
end


// IF1状态机时序逻辑
always @(posedge clk) begin
    if (rst == `RstEnable) begin
        if1_state <= IF1_IDLE;
    end else if (branch_flag_i == `Branch) begin
        if1_state <= IF1_IDLE; // 分支跳转时回到初始状态
    end  else if (stall) begin
        if1_state <= if1_state; //维持
    end else begin
        if1_state <= if1_next_state;
    end
end
// IF1状态机组合逻辑
always @(*) begin
    // 默认值，防止 latch
    if1_next_state = IF1_IDLE;
    icache_addr = pc_reg;
    icache_ce = 1'b0;
    fetch_addr_o = 32'b0;
    fetch_enable = 1'b0;
    pc_stall = 1'b0;
    
    case (if1_state)
        IF1_IDLE: begin
            icache_addr = pc_reg;
            icache_ce = 1'b1;
            if (icache_hit1 && icache_hit2) begin
                if1_next_state = IF1_IDLE;
                fetch_addr_o = 32'b0;
                fetch_enable = 1'b0;
                pc_stall = 1'b0;
            end else if (!icache_hit1) begin
                if1_next_state = IF1_FETCH_INST1;
                icache_ce = 1'b0;
                fetch_addr_o = 32'b0;
                fetch_enable = 1'b0;
                pc_stall = 1'b1;
            end else if (!icache_hit2) begin
                if1_next_state = IF1_FETCH_INST2;
                icache_ce = 1'b0;
                fetch_addr_o = 32'b0;
                fetch_enable = 1'b0;
                pc_stall = 1'b1;
            end else begin 
                // 补充默认情况（理论上不会到达）
                if1_next_state = IF1_IDLE;
                pc_stall = 1'b0;
            end 
        end
        
        IF1_FETCH_INST1: begin
            if (icache_active) begin
                if1_next_state = IF1_IDLE;
            end else begin
                if1_next_state = IF1_FETCH_INST1;
            end
            icache_addr = pc_reg;
            icache_ce = 1'b1;
            fetch_addr_o = pc_reg;
            fetch_enable = 1'b1;
            pc_stall = 1'b1;
        end
        
        IF1_FETCH_INST2: begin
            if (icache_active) begin
                if1_next_state = IF1_IDLE;
            end else begin
                if1_next_state = IF1_FETCH_INST2;
            end
            icache_addr = pc_plus4;
            icache_ce = 1'b1;
            fetch_addr_o = pc_plus4;
            fetch_enable = 1'b1;
            pc_stall = 1'b1;
        end
        
        default: begin
            if1_next_state = IF1_IDLE;
            icache_addr = pc_reg;
            icache_ce = 1'b0;
            fetch_addr_o = 32'b0;
            fetch_enable = 1'b0;
            pc_stall = 1'b1;
        end
    endcase
    
    // 分支跳转时立即重置（注意运算符优先级）
    if ((branch_flag_i == `Branch) || inst1_pred_taken || inst2_pred_taken) begin
        if1_next_state = IF1_IDLE;
        icache_ce = 1'b0;
        pc_stall = 1'b0;
    end
end
// IF1级寄存器更新（唯一的寄存器级）
always @(posedge clk) begin
    if (rst == `RstEnable) begin
        if1_pc <= 32'b0;
        if1_inst1 <= 32'b0;
        if1_inst2 <= 32'b0;
        if1_inst1_valid <= 1'b0;
        if1_inst2_valid <= 1'b0;
        
    end else if (branch_flag_i == `Branch|inst1_pred_taken|inst2_pred_taken) begin
        // 分支跳转，清空IF1
        
        if1_inst1_valid <= 1'b0;
        if1_inst2_valid <= 1'b0;
        if1_pc <= 32'b0;
        if1_inst1 <= 32'b0;
        if1_inst2 <= 32'b0;
    end else if (stall) begin
        // 外部停顿时保持IF1状态
        if1_pc <= if1_pc;
        if1_inst1 <= if1_inst1;
        if1_inst2 <= if1_inst2;
        if1_inst1_valid <= if1_inst1_valid;
        if1_inst2_valid <= if1_inst2_valid;
        
    end else if (if1_state == IF1_IDLE && icache_hit1 && icache_hit2) begin
        // 两条指令都命中时，更新IF1级寄存器
        if1_pc <= pc_reg;
        if1_inst1 <= icache_inst1;
        if1_inst2 <= icache_inst2;
        if1_inst1_valid <= icache_hit1;
        if1_inst2_valid <= icache_hit2;
       
    end else begin
        // 其他情况输出无效（相当于NOP）
        if1_pc <= 32'b0;
        if1_inst1 <= 32'b0;
        if1_inst2 <= 32'b0;
        if1_inst1_valid <= 1'b0;
        if1_inst2_valid <= 1'b0;
        
    end
end
wire inst1_is_nocondition,inst2_is_nocondition;
// 分支指令识别模块 - 第一条指令（组合逻辑）
branch_pred branch_pred1 (
    .instruction(if1_inst1),
    .pc(if1_pc),
    .is_branch(inst1_is_branch),
    .is_nocondition(inst1_is_nocondition),
    .pred_taken(inst1_pred_taken),
    .pred_target(inst1_pred_target)
);

// 分支指令识别模块 - 第二条指令（组合逻辑）
branch_pred branch_pred2 (
    .instruction(if1_inst2),
    .pc(if1_pc + 32'h4),
    .is_nocondition(inst2_is_nocondition),
    .is_branch(inst2_is_branch),
    .pred_taken(inst2_pred_taken),
    .pred_target(inst2_pred_target)
);
// 第二条指令有效信号屏蔽逻辑：如果第一条是无条件跳转，则第二条无效化
wire inst2_valid_masked = (inst1_is_nocondition) ? 1'b0 : if1_inst2_valid;

// 第二条分支预测结果也要屏蔽
wire inst2_is_branch_masked = (inst1_is_nocondition) ? 1'b0 : inst2_is_branch;
wire inst2_pb = (inst1_is_nocondition) ? 1'b0 :
                (inst1_is_branch && inst1_pred_taken) ? 1'b0 : inst2_pred_taken;

// 输出128位指令包逻辑
assign package_valid = (if1_inst1_valid || inst2_valid_masked);

assign inst_package_o = (package_valid) ? {
    if1_pc,                 // [127:96] 取指阶段的PC
    if1_inst1,              // [95:64] 第一条指令
    (inst1_is_nocondition ? 32'b0 : if1_inst2), // [63:32] 第二条指令（被无效化则置零）
    if1_inst1_valid,        // [31] 第一条是否有效
    inst2_valid_masked,     // [30] 第二条是否有效（被屏蔽）
    inst1_is_branch,        // [29] 第一条是否分支
    inst1_pred_taken,       // [28] 第一条预测是否跳转
    inst2_is_branch_masked, // [27] 第二条是否分支（被屏蔽）
    inst2_pb,               // [26] 第二条预测是否跳转（被屏蔽）
    26'b0                   // [25:0] 预留
} : 128'b0;

endmodule

// 分支指令识别和预测模块
module branch_pred (
    input wire [31:0] instruction,
    input wire [31:0] pc,
    output reg        is_branch,//是否是分支跳转指令
     output wire        is_nocondition,//是否是分支跳转指令
    output reg        pred_taken,//预测是否跳转
    output reg [31:0] pred_target//跳转地址
);

// 指令字段解析
wire [5:0] opcode = instruction[31:26];

wire [15:0] imm16 = instruction[25:10];       // 取指令中 [25:10] 共16位
wire [9:0]  imm26_hi = instruction[9:0];        // 取指令中 [9:0] 共10位
wire [25:0] imm26  = {imm26_hi, imm16};         // 
wire [4:0] rj = instruction[9:5];
wire [4:0] rd = instruction[4:0];
// 分支指令识别
wire is_beq = (opcode == 6'b010110);
wire is_bne = (opcode == 6'b010111);  

wire is_b = (opcode == 6'b010100);
wire is_bl = (opcode == 6'b010101);
wire is_jirl = (opcode == 6'b010011) ;
assign  is_nocondition= is_b|is_bl|is_jirl;
// 分支目标地址计算
wire is_backward = (imm16[15] == 1'b1); // 负偏移表示后跳
// 立即数符号扩展并 <<2
wire [31:0] branch_off = {{14{imm16[15]}}, imm16, 2'b00};  // 16->32，左移2
wire [31:0] jump_off   = {{6{imm26[25]}}, imm26, 2'b00};   // 26->32，左移2
wire [31:0] branch_target = pc + branch_off;     // 用于 BEQ/BNE
wire [31:0] jump_target   = pc + jump_off;       // B/BL
always @(*) begin
    is_branch = is_beq || is_bne ||is_b ||is_bl||is_jirl;
    
    // 分支预测逻辑：前跳不跳，后跳跳转
    pred_taken = is_b ||is_bl ||  // 无条件跳转
                (is_beq && is_backward) ||      // beq后跳预测跳转
                (is_bne && is_backward) ;       // bne后跳预测跳转      
                // jr默认预测不跳
    
    // 目标地址计算
    pred_target = (is_b ||is_bl) ? jump_target : 
                  (is_jirl) ? 32'b0 :  // jr/jalr目标地址需要从寄存器读取
                  branch_target;
end

endmodule

