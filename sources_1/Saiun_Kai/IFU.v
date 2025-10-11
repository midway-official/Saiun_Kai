

/*���峣�õĳ���*/
`define     PC_START_ADDR   32'h80000000    // PC��ʼ��ַ

`define     RstEnable       1'b1            //��λʹ��
`define     RstDisable      1'b0            //��λ����
`define     WriteEnable     1'b1            //дʹ��
`define     WriteEnable_n   1'b0            //дʹ�ܣ�����Ч��
`define     WriteDisable    1'b0            //д����
`define     WriteDisable_n  1'b1            //д���ܣ�����Ч��
`define     ReadEnable      1'b1            //��ʹ��
`define     ReadDisable     1'b0            //������
`define     ChipEnable      1'b1            //оƬʹ��
`define     ChipDisable     1'b0            //оƬ��ֹ
`define     ZeroWord        32'h00000000    //32λ����0
`define     Branch          1'b1            //��ת
`define     NotBranch       1'b0            //����ת
`define     Stop            1'b1            //ֹͣ
`define     NoStop          1'b0            //��ֹͣ
`define     NOPRegAddr      5'b00000        //�ղ���ʹ�õļĴ�����ַ

`define     LL_OP           6'b110000       // LL
`define     SC_OP           6'b111000       // SW
`define     SYNC_FUNC       6'b001111       // SYNC
`define     SH_OP           6'b101001      // SW
`define     LH_OP           6'b100001      // SW
module IFU (
    input wire          clk,
    input wire          rst,
    input wire          stall,              // �ⲿͣ���ź�
    input wire [31:0]   inst_from_sram,     // ����SRAM��ָ��
    
    input wire          branch_flag_i,      // ��ִ֧�н��
    input wire [31:0]   branch_address_i,   // ��֧Ŀ���ַ
    
    output reg [31:0]  fetch_addr_o,       // ȡָ��ַ�����SRAM
    output reg         fetch_enable,       // ȡָʹ�������SRAM
    output wire        fetch_ready,
    output wire [127:0] inst_package_o,     // ָ������ (128λ)
    output wire        package_valid       // ָ�����Ч�ź�
);

// IF1״̬��״̬����
parameter IF1_IDLE = 3'b000;
parameter IF1_FETCH_INST1 = 3'b001;
parameter IF1_FETCH_INST2 = 3'b010;

reg [2:0] if1_state, if1_next_state;

// PC�Ĵ���
reg [31:0] pc_reg;
reg        pc_ce;

// IF1���Ĵ�����Ψһ�ļĴ�������
reg [31:0] if1_pc;
reg [31:0] if1_inst1;
reg [31:0] if1_inst2;
reg        if1_inst1_valid;
reg        if1_inst2_valid;


// Icache�ӿ��ź�
wire [31:0] icache_inst1;
wire [31:0] icache_inst2;
wire        icache_inst2_valid;
wire        icache_hit1;
wire        icache_hit2;
wire        icache_stall;
wire        icache_active;
wire        inst_stop;

// ��֧Ԥ������źţ�����߼���
wire       inst1_is_branch;
wire       inst1_pred_taken;
wire [31:0] inst1_pred_target;
wire       inst2_is_branch;
wire       inst2_pred_taken;
wire [31:0] inst2_pred_target;

// �ڲ������ź�
reg [31:0]  icache_addr;
reg         icache_ce;
reg         pc_stall;

// ����Icacheģ��
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
// ����ڶ���ָ����������
wire [31:0] pc_plus4 = pc_reg + 32'h4;
assign icache_hit2 = icache_inst2_valid;
assign fetch_ready = (if1_state == IF1_IDLE) &&( icache_hit1 &&icache_hit2);
  
// PC�������ȼ�����֧���� > ͣ�ٱ��� > Ԥ����ת > ��������
always @(posedge clk) begin
    if (rst == `RstEnable) begin
        pc_ce  <= `ChipDisable;
        pc_reg <= `PC_START_ADDR;
    end else begin
        pc_ce <= `ChipEnable;

        if (branch_flag_i == `Branch) begin
            pc_reg <= branch_address_i;              // ��֧���ȼ����
        end else if (inst1_is_branch && inst1_pred_taken) begin
            pc_reg <= inst1_pred_target;             // Ԥ���һ����ת
        end else if (inst2_is_branch && inst2_pred_taken) begin
            pc_reg <= inst2_pred_target;             // Ԥ��ڶ�����ת
        end  else if (stall || pc_stall ) begin
            pc_reg <= pc_reg;                        // stall ����
        end  else  begin
            pc_reg <= pc_reg + 32'h8;                // ����ȡ����
        end
    end
end


// IF1״̬��ʱ���߼�
always @(posedge clk) begin
    if (rst == `RstEnable) begin
        if1_state <= IF1_IDLE;
    end else if (branch_flag_i == `Branch) begin
        if1_state <= IF1_IDLE; // ��֧��תʱ�ص���ʼ״̬
    end  else if (stall) begin
        if1_state <= if1_state; //ά��
    end else begin
        if1_state <= if1_next_state;
    end
end
// IF1״̬������߼�
always @(*) begin
    // Ĭ��ֵ����ֹ latch
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
                // ����Ĭ������������ϲ��ᵽ�
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
    
    // ��֧��תʱ�������ã�ע����������ȼ���
    if ((branch_flag_i == `Branch) || inst1_pred_taken || inst2_pred_taken) begin
        if1_next_state = IF1_IDLE;
        icache_ce = 1'b0;
        pc_stall = 1'b0;
    end
end
// IF1���Ĵ������£�Ψһ�ļĴ�������
always @(posedge clk) begin
    if (rst == `RstEnable) begin
        if1_pc <= 32'b0;
        if1_inst1 <= 32'b0;
        if1_inst2 <= 32'b0;
        if1_inst1_valid <= 1'b0;
        if1_inst2_valid <= 1'b0;
        
    end else if (branch_flag_i == `Branch|inst1_pred_taken|inst2_pred_taken) begin
        // ��֧��ת�����IF1
        
        if1_inst1_valid <= 1'b0;
        if1_inst2_valid <= 1'b0;
        if1_pc <= 32'b0;
        if1_inst1 <= 32'b0;
        if1_inst2 <= 32'b0;
    end else if (stall) begin
        // �ⲿͣ��ʱ����IF1״̬
        if1_pc <= if1_pc;
        if1_inst1 <= if1_inst1;
        if1_inst2 <= if1_inst2;
        if1_inst1_valid <= if1_inst1_valid;
        if1_inst2_valid <= if1_inst2_valid;
        
    end else if (if1_state == IF1_IDLE && icache_hit1 && icache_hit2) begin
        // ����ָ�����ʱ������IF1���Ĵ���
        if1_pc <= pc_reg;
        if1_inst1 <= icache_inst1;
        if1_inst2 <= icache_inst2;
        if1_inst1_valid <= icache_hit1;
        if1_inst2_valid <= icache_hit2;
       
    end else begin
        // ������������Ч���൱��NOP��
        if1_pc <= 32'b0;
        if1_inst1 <= 32'b0;
        if1_inst2 <= 32'b0;
        if1_inst1_valid <= 1'b0;
        if1_inst2_valid <= 1'b0;
        
    end
end
wire inst1_is_nocondition,inst2_is_nocondition;
// ��ָ֧��ʶ��ģ�� - ��һ��ָ�����߼���
branch_pred branch_pred1 (
    .instruction(if1_inst1),
    .pc(if1_pc),
    .is_branch(inst1_is_branch),
    .is_nocondition(inst1_is_nocondition),
    .pred_taken(inst1_pred_taken),
    .pred_target(inst1_pred_target)
);

// ��ָ֧��ʶ��ģ�� - �ڶ���ָ�����߼���
branch_pred branch_pred2 (
    .instruction(if1_inst2),
    .pc(if1_pc + 32'h4),
    .is_nocondition(inst2_is_nocondition),
    .is_branch(inst2_is_branch),
    .pred_taken(inst2_pred_taken),
    .pred_target(inst2_pred_target)
);
// �ڶ���ָ����Ч�ź������߼��������һ������������ת����ڶ�����Ч��
wire inst2_valid_masked = (inst1_is_nocondition) ? 1'b0 : if1_inst2_valid;

// �ڶ�����֧Ԥ����ҲҪ����
wire inst2_is_branch_masked = (inst1_is_nocondition) ? 1'b0 : inst2_is_branch;
wire inst2_pb = (inst1_is_nocondition) ? 1'b0 :
                (inst1_is_branch && inst1_pred_taken) ? 1'b0 : inst2_pred_taken;

// ���128λָ����߼�
assign package_valid = (if1_inst1_valid || inst2_valid_masked);

assign inst_package_o = (package_valid) ? {
    if1_pc,                 // [127:96] ȡָ�׶ε�PC
    if1_inst1,              // [95:64] ��һ��ָ��
    (inst1_is_nocondition ? 32'b0 : if1_inst2), // [63:32] �ڶ���ָ�����Ч�������㣩
    if1_inst1_valid,        // [31] ��һ���Ƿ���Ч
    inst2_valid_masked,     // [30] �ڶ����Ƿ���Ч�������Σ�
    inst1_is_branch,        // [29] ��һ���Ƿ��֧
    inst1_pred_taken,       // [28] ��һ��Ԥ���Ƿ���ת
    inst2_is_branch_masked, // [27] �ڶ����Ƿ��֧�������Σ�
    inst2_pb,               // [26] �ڶ���Ԥ���Ƿ���ת�������Σ�
    26'b0                   // [25:0] Ԥ��
} : 128'b0;

endmodule

// ��ָ֧��ʶ���Ԥ��ģ��
module branch_pred (
    input wire [31:0] instruction,
    input wire [31:0] pc,
    output reg        is_branch,//�Ƿ��Ƿ�֧��תָ��
     output wire        is_nocondition,//�Ƿ��Ƿ�֧��תָ��
    output reg        pred_taken,//Ԥ���Ƿ���ת
    output reg [31:0] pred_target//��ת��ַ
);

// ָ���ֶν���
wire [5:0] opcode = instruction[31:26];

wire [15:0] imm16 = instruction[25:10];       // ȡָ���� [25:10] ��16λ
wire [9:0]  imm26_hi = instruction[9:0];        // ȡָ���� [9:0] ��10λ
wire [25:0] imm26  = {imm26_hi, imm16};         // 
wire [4:0] rj = instruction[9:5];
wire [4:0] rd = instruction[4:0];
// ��ָ֧��ʶ��
wire is_beq = (opcode == 6'b010110);
wire is_bne = (opcode == 6'b010111);  

wire is_b = (opcode == 6'b010100);
wire is_bl = (opcode == 6'b010101);
wire is_jirl = (opcode == 6'b010011) ;
assign  is_nocondition= is_b|is_bl|is_jirl;
// ��֧Ŀ���ַ����
wire is_backward = (imm16[15] == 1'b1); // ��ƫ�Ʊ�ʾ����
// ������������չ�� <<2
wire [31:0] branch_off = {{14{imm16[15]}}, imm16, 2'b00};  // 16->32������2
wire [31:0] jump_off   = {{6{imm26[25]}}, imm26, 2'b00};   // 26->32������2
wire [31:0] branch_target = pc + branch_off;     // ���� BEQ/BNE
wire [31:0] jump_target   = pc + jump_off;       // B/BL
always @(*) begin
    is_branch = is_beq || is_bne ||is_b ||is_bl||is_jirl;
    
    // ��֧Ԥ���߼���ǰ��������������ת
    pred_taken = is_b ||is_bl ||  // ��������ת
                (is_beq && is_backward) ||      // beq����Ԥ����ת
                (is_bne && is_backward) ;       // bne����Ԥ����ת      
                // jrĬ��Ԥ�ⲻ��
    
    // Ŀ���ַ����
    pred_target = (is_b ||is_bl) ? jump_target : 
                  (is_jirl) ? 32'b0 :  // jr/jalrĿ���ַ��Ҫ�ӼĴ�����ȡ
                  branch_target;
end

endmodule

