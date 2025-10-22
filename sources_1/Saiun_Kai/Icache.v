
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
module Icache(
    input wire clk,
    input wire rst,
    input wire branch,
    // �� CPU ����
    (* DONT_TOUCH = "1" *) input  wire [31:0] rom_addr_i,  
    (* DONT_TOUCH = "1" *) input  wire        rom_ce_i,    
    output reg [31:0] inst_o,                
    
    output reg [31:0] inst2_o,
    output reg        inst2_valid,

    output reg        stall,
    output wire       Icache_hit,
    output reg        Icache_active,

    // �� SRAM ����������
    input wire  inst_stop,
    input wire [31:0] inst_i
);

////////////////////////////////////////////////////////
//// -------- Cache �������ã�128 �У�512B -------- //
//parameter Cache_Num    = 128;
//parameter Cache_Index  = 7;
//parameter Block_Offset = 2;
//parameter Tag          = 32 - Cache_Index - Block_Offset; 
////////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// -------- Cache �������ã�32 �У�128B -------- //
parameter Cache_Num    = 32;    // 32 ��
parameter Cache_Index  = 5;     // log2(32)
parameter Block_Offset = 2;     // ÿ�� 4B
parameter Tag          = 32 - Cache_Index - Block_Offset; 
//////////////////////////////////////////////////////

// �ڲ��洢
reg [31:0]       cache_mem[0:Cache_Num-1];
reg [Tag-1:0]    cache_tag[0:Cache_Num-1];
reg [Cache_Num-1:0] cache_valid;

// ״̬��
parameter IDLE = 0;
parameter WAIT1 = 1;
parameter WAIT2 = 2;
parameter READ_SRAM = 3;
reg [1:0] state, next_state;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// ��ַ�ֽ�
wire [Tag-1:0]         ram_tag_i   = rom_addr_i[31:(32-Tag)];
wire [Cache_Index-1:0] ram_cache_i = rom_addr_i[(32-Tag-1):(Block_Offset)];
wire hit = (state == IDLE) ? cache_valid[ram_cache_i] && (cache_tag[ram_cache_i] == ram_tag_i) : 1'b0;
assign Icache_hit = hit;

// �ڶ���ָ��
wire [31:0] pc2    = rom_addr_i + 32'd4;
wire [Tag-1:0]         tag2   = pc2[31:(32-Tag)];
wire [Cache_Index-1:0] index2 = pc2[(32-Tag-1):(Block_Offset)];
wire hit2 = cache_valid[index2] && (cache_tag[index2] == tag2);

reg finish_read;
integer i;

// ��ȡָ��
always @(*) begin
    if (rst) begin
        finish_read = 1'b0;
        inst_o = `ZeroWord;
    end else begin
        case(state)
            IDLE: begin
                finish_read = 1'b0;
                if (hit && ~inst_stop) begin
                    inst_o = cache_mem[ram_cache_i];
                end else begin
                    inst_o = `ZeroWord;
                end
            end
            
            READ_SRAM: begin
                inst_o = inst_i;
                finish_read = 1'b1;
            end
            default: begin
                finish_read = 1'b0;
                inst_o = 32'hZZZZZZZZ;
            end
        endcase
    end
end

// ���� cache memory
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < Cache_Num; i = i + 1) begin
            cache_mem[i] <= 32'b0;
            cache_tag[i] <= {Tag{1'b0}};
        end
        cache_valid <= {Cache_Num{1'b0}};
    end else begin
        case (state)
            READ_SRAM: begin
                if (~branch) begin  // ��ֹ��֧ʱд��
                    cache_mem[ram_cache_i]   <= inst_i;
                    cache_valid[ram_cache_i] <= 1'b1;
                    cache_tag[ram_cache_i]   <= ram_tag_i;
                end
            end
        endcase
    end
end

// ״̬������
always @(*) begin
    if (rst) begin
        next_state    = IDLE;
        stall         = 1'b0;
        Icache_active = 1'b0;
    end else begin
        case (state)
            IDLE: begin
                if (branch) begin
                    next_state    = IDLE;
                    stall         = 1'b0;
                    Icache_active = 1'b0;
                end else if (rom_ce_i && ~hit && ~inst_stop) begin
                    next_state    = WAIT1;
                    stall         = 1'b1;
                    Icache_active = 1'b0;
                end else begin
                    next_state    = IDLE;
                    stall         = 1'b0;
                    Icache_active = 1'b1;
                end
            end

            WAIT1, WAIT2, READ_SRAM: begin
                if (branch) begin
                    next_state    = IDLE;
                    stall         = 1'b0;
                    Icache_active = 1'b0;
                end else if (state == READ_SRAM) begin
                    if (finish_read && ~inst_stop) begin
                        next_state    = IDLE;
                        stall         = 1'b0;
                        Icache_active = 1'b1;
                    end else begin
                        next_state    = READ_SRAM;
                        stall         = 1'b1;
                        Icache_active = 1'b0;
                    end
                end else begin
                    // WAIT1/WAIT2Ĭ���߼�
                    next_state    = READ_SRAM;
                    stall         = 1'b1;
                    Icache_active = 1'b0;
                end
            end

            default: begin
                Icache_active = 1'b0;
                next_state    = IDLE;
                stall         = 1'b0;
            end
        endcase
    end
end


// �ڶ���ָ������߼�
always @(*) begin
    inst2_o     = `ZeroWord;
    inst2_valid = 1'b0;
    if (state == IDLE && hit2 && ~inst_stop) begin
        inst2_o     = cache_mem[index2];
        inst2_valid = 1'b1;
    end
end

endmodule


