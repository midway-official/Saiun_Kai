
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
module Icache(
    input wire clk,
    input wire rst,
    input wire branch,
    // 与 CPU 连接
    (* DONT_TOUCH = "1" *) input  wire [31:0] rom_addr_i,  
    (* DONT_TOUCH = "1" *) input  wire        rom_ce_i,    
    output reg [31:0] inst_o,                
    
    output reg [31:0] inst2_o,
    output reg        inst2_valid,

    output reg        stall,
    output wire       Icache_hit,
    output reg        Icache_active,

    // 与 SRAM 控制器连接
    input wire  inst_stop,
    input wire [31:0] inst_i
);

////////////////////////////////////////////////////////
//// -------- Cache 参数配置：128 行，512B -------- //
//parameter Cache_Num    = 128;
//parameter Cache_Index  = 7;
//parameter Block_Offset = 2;
//parameter Tag          = 32 - Cache_Index - Block_Offset; 
////////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// -------- Cache 参数配置：32 行，128B -------- //
parameter Cache_Num    = 32;    // 32 行
parameter Cache_Index  = 5;     // log2(32)
parameter Block_Offset = 2;     // 每行 4B
parameter Tag          = 32 - Cache_Index - Block_Offset; 
//////////////////////////////////////////////////////

// 内部存储
reg [31:0]       cache_mem[0:Cache_Num-1];
reg [Tag-1:0]    cache_tag[0:Cache_Num-1];
reg [Cache_Num-1:0] cache_valid;

// 状态机
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

// 地址分解
wire [Tag-1:0]         ram_tag_i   = rom_addr_i[31:(32-Tag)];
wire [Cache_Index-1:0] ram_cache_i = rom_addr_i[(32-Tag-1):(Block_Offset)];
wire hit = (state == IDLE) ? cache_valid[ram_cache_i] && (cache_tag[ram_cache_i] == ram_tag_i) : 1'b0;
assign Icache_hit = hit;

// 第二条指令
wire [31:0] pc2    = rom_addr_i + 32'd4;
wire [Tag-1:0]         tag2   = pc2[31:(32-Tag)];
wire [Cache_Index-1:0] index2 = pc2[(32-Tag-1):(Block_Offset)];
wire hit2 = cache_valid[index2] && (cache_tag[index2] == tag2);

reg finish_read;
integer i;

// 获取指令
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

// 存入 cache memory
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
                if (~branch) begin  // 防止分支时写入
                    cache_mem[ram_cache_i]   <= inst_i;
                    cache_valid[ram_cache_i] <= 1'b1;
                    cache_tag[ram_cache_i]   <= ram_tag_i;
                end
            end
        endcase
    end
end

// 状态机控制
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
                    // WAIT1/WAIT2默认逻辑
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


// 第二条指令输出逻辑
always @(*) begin
    inst2_o     = `ZeroWord;
    inst2_valid = 1'b0;
    if (state == IDLE && hit2 && ~inst_stop) begin
        inst2_o     = cache_mem[index2];
        inst2_valid = 1'b1;
    end
end

endmodule


