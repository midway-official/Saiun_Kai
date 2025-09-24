module MAU (
    //=============================================
    // 全局时钟和复位
    //=============================================
    input  wire         clk,
    input  wire         rst,
   
    //=============================================
    // 指令访存接口
    //=============================================
    input  wire [31:0]  inst_addr,         
    output wire [31:0]  inst_rdata,        
    input  wire         inst_ce,           
    input  wire         inst_done,         // 指令访存完成信号 (来自存储器)
    input  wire        branch,
   input wire          iq_full, 
    //=============================================
    // 数据访存接口  
    //=============================================
    input  wire [31:0]  data_addr,         
    input  wire [31:0]  data_wdata,        
    output wire [31:0]  data_rdata,        
    input  wire [3:0]   data_sel_n,        
    input  wire         data_ce,           
    input  wire         data_wen_n,        
    input  wire         data_done,         // 数据访存完成信号 (来自存储器)

    //=============================================
    // 原子操作控制信号
    //=============================================
    input  wire         ll_i,              
    input  wire         sc_i,              

    //=============================================
    // 仲裁控制输出
    //=============================================
    output wire         front_stall,       
    output wire         back_stall,        // <-- 新增 back_stall 输出

    //=============================================
    // 存储器总线接口
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
// 状态机定义
//=============================================
localparam S_IDLE       = 2'b00; // 空闲状态
localparam S_GRANT_INST = 2'b01; // 授权给指令访存
localparam S_GRANT_DATA = 2'b10; // 授权给数据访存

reg [1:0] state, next_state;

//=============================================
// 内部信号定义
//=============================================
wire data_access_req;       // 数据访存请求
wire inst_access_req;       // 指令访存请求  
wire grant_data;            // 总线授权给数据访存
wire grant_inst;            // 总线授权给指令访存

// 请求信号
assign data_access_req = data_ce;
assign inst_access_req = inst_ce&&!iq_full;

// 授权信号由当前状态决定
assign grant_inst = (state == S_GRANT_INST);
assign grant_data = (state == S_GRANT_DATA);

//=============================================
// 状态机时序逻辑 (状态寄存器)
//=============================================
always @(posedge clk ) begin
    if (rst) begin
        state <= S_IDLE;
    end else begin
        state <= next_state;
    end
end

//=============================================
// 状态机组合逻辑 (下一状态逻辑)
//=============================================
always @(*) begin
    next_state = state; // 默认保持当前状态
    case (state)
        S_IDLE: begin
            // 在空闲状态下，数据访存有优先权
            if (data_access_req) begin
                next_state = S_GRANT_DATA;
            end else if (inst_access_req) begin
                next_state = S_GRANT_INST;
            end
        end

        S_GRANT_INST: begin
            // 等待指令访存完成
            if (inst_done|branch) begin
                    next_state = S_IDLE;
                end
            end
     

        S_GRANT_DATA: begin
            // 等待数据访存完成
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
// 控制与总线逻辑
//=============================================

// 当指令访存请求总线，但总线被数据访存占用(或即将占用)时，暂停前端
assign front_stall = inst_access_req & (grant_data | (state == S_IDLE & data_access_req));

// 当数据访存请求总线，但总线被指令访存占用时，暂停后端
assign back_stall = data_access_req & !grant_data; // <-- 新增 back_stall 逻辑

// 地址总线复用
assign mem_addr = grant_data ? data_addr : 
                  grant_inst ? inst_addr : 
                  32'h0;

// 写数据总线复用
assign mem_wdata = grant_data ? data_wdata : 32'h0;

// 字节选择信号复用 (假设为低有效)
assign mem_sel = grant_data ? data_sel_n :
                 grant_inst ? 4'b0000 :      // 指令访存总是全字
                 4'b0000;                   // 空闲时不选择

// 总线使能
assign mem_en = grant_data | grant_inst;

// 写使能信号 (低有效)，只在数据访存时有效
assign mem_wen_n = grant_data ? data_wen_n : 1'b1;

// 原子操作信号，只在数据访存时透传
assign ll_o = grant_data ? ll_i : 1'b0;
assign sc_o = grant_data ? sc_i : 1'b0;

// 向当前获得授权的单元反馈完成信号
assign mem_done = (grant_inst & inst_done) | (grant_data & data_done);

// 读数据通路
assign inst_rdata = grant_inst ? mem_rdata : 32'h0;
assign data_rdata = grant_data ? mem_rdata : 32'h0;

endmodule