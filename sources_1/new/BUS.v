
`define SerialState 32'hBFD003FC //串口状态地址
`define SerialData 32'hBFD003F8  //串口数据地址

module Ram_Serial_ctrl (
    input wire clk,
    input wire rst,
    
    //统一的访存接口
    output reg[31:0] mem_rdata,     //读取的数据
    input wire[31:0] mem_addr,      //读（写）地址
    input wire[31:0] mem_wdata,     //写入的数据
    input wire mem_we_n,            //写使能，低有效
    input wire[3:0] mem_sel_n,      //字节选择信号
    input wire mem_ce_i,            //片选信号
    
    //BaseRAM信号 - 解耦后
    output wire[31:0] base_ram_wdata,   //BaseRAM写数据输出
    input wire[31:0] base_ram_rdata,    //BaseRAM读数据输入
    output wire [19:0] base_ram_addr,   //BaseRAM地址
    output wire [3:0] base_ram_be_n,    //BaseRAM字节使能，低有效
    output wire base_ram_ce_n,          //BaseRAM片选，低有效
    output wire base_ram_oe_n,          //BaseRAM读使能，低有效
    output wire base_ram_we_n,          //BaseRAM写使能，低有效
    
    //ExtRAM信号 - 解耦后
    output wire[31:0] ext_ram_wdata,    //ExtRAM写数据输出
    input wire[31:0] ext_ram_rdata,     //ExtRAM读数据输入
    output wire [19:0] ext_ram_addr,    //ExtRAM地址
    output wire [3:0] ext_ram_be_n,     //ExtRAM字节使能，低有效
    output wire ext_ram_ce_n,           //ExtRAM片选，低有效
    output wire ext_ram_oe_n,           //ExtRAM读使能，低有效
    output wire ext_ram_we_n,           //ExtRAM写使能，低有效
    
    //直连串口信号
    output wire txd,        //直连串口发送端
    input wire rxd,         //直连串口接收端
    output wire txd_busy,
    output wire[1:0] state  //串口状态
);

// 串口相关信号
wire [7:0] RxD_data;        //接收到的数据
reg [7:0] TxD_data;         //待发送的数据
wire RxD_data_ready;        //接收器收到数据完成之后，置为1
wire TxD_busy;              //发送器状态是否忙碌，1为忙碌，0为不忙碌
reg TxD_start;              //发送器是否可以发送数据，1代表可以发送
reg RxD_clear;              //为1时将清除接收标志（ready信号）

// 内存映射区域判断
wire is_SerialState = (mem_addr == `SerialState);
wire is_SerialData = (mem_addr == `SerialData);
wire is_base_ram = (mem_addr >= 32'h80000000) && (mem_addr < 32'h80400000);
wire is_ext_ram = (mem_addr >= 32'h80400000) && (mem_addr < 32'h80800000);

// 数据输出信号
reg [31:0] serial_data;     //串口输出数据

assign txd_busy = TxD_busy;
assign state = {RxD_data_ready, !TxD_busy};

//串口实例化模块，波特率9600
 (* dont_touch = "true" *) async_receiver #(.ClkFrequency(50_000000),.Baud(9600)) //接收模块
    ext_uart_r(
        .clk(clk),                      //外部时钟信号
        .RxD(rxd),                      //外部串行信号输入
        .RxD_data_ready(RxD_data_ready), //数据接收到标志
        .RxD_clear(RxD_clear),          //清除接收标志
        .RxD_data(RxD_data)             //接收到的一字节数据
    );

 (* dont_touch = "true" *) async_transmitter #(.ClkFrequency(50_000000),.Baud(9600)) //发送模块
    ext_uart_t(
        .clk(clk),              //外部时钟信号
        .TxD(txd),              //串行信号输出
        .TxD_busy(TxD_busy),    //发送器忙状态指示
        .TxD_start(TxD_start),  //开始发送信号
        .TxD_data(TxD_data)     //待发送的数据
    );

// 串口数据处理
always @(*) begin
    TxD_start = 1'b0;
    serial_data = 32'h00000000;
    TxD_data = 8'h00;
    RxD_clear = 1'b0;
    
    if(is_SerialState && mem_ce_i) begin
        // 读串口状态
        serial_data = {{30{1'b0}}, {RxD_data_ready, !TxD_busy}};
    end else if(is_SerialData && mem_ce_i) begin
        if(mem_we_n) begin
            // 读数据
            serial_data = {24'h000000, RxD_data};
            RxD_clear = RxD_data_ready; // 读取数据后清除ready标志
        end else if(!TxD_busy) begin
            // 写数据（发送）
            TxD_data = mem_wdata[7:0];
            TxD_start = 1'b1;
            serial_data = 32'h00000000;
        end
    end
end

// BaseRAM控制逻辑 - 解耦后
assign base_ram_wdata = mem_wdata;              // 写数据直接输出
assign base_ram_addr = mem_addr[21:2];          // 有对齐要求，低两位舍去
assign  base_ram_be_n = base_ram_ce_n ? 4'b1:mem_sel_n;
assign base_ram_oe_n = mem_we_n;                // 读操作时为0（mem_we_n为1时是读操作）
assign base_ram_we_n = mem_we_n;                // 写操作时为0
assign base_ram_ce_n = !(is_base_ram && mem_ce_i);

// ExtRAM控制逻辑 - 解耦后
assign ext_ram_wdata = mem_wdata;               // 写数据直接输出
assign ext_ram_addr = mem_addr[21:2];           // 有对齐要求，低两位舍去
assign  ext_ram_be_n = ext_ram_ce_n ? 4'b1:mem_sel_n;
assign ext_ram_oe_n = mem_we_n;                 // 读操作时为0（mem_we_n为1时是读操作）
assign ext_ram_we_n = mem_we_n;                 // 写操作时为0
assign ext_ram_ce_n = !(is_ext_ram && mem_ce_i);

// 统一的数据输出处理
always @(*) begin
    mem_rdata = 32'b0;
    
    if(!mem_ce_i) begin
        mem_rdata =32'b0;
    end else if(is_SerialState || is_SerialData) begin
        mem_rdata = serial_data;
    end else if(is_base_ram) begin
        // 根据字节选择信号处理BaseRAM数据
        case (mem_sel_n)
            4'b1110: begin // 读取最低字节，符号扩展
                mem_rdata = {{24{base_ram_rdata[7]}}, base_ram_rdata[7:0]};
            end
            4'b1101: begin // 读取第二字节，符号扩展
                mem_rdata = {{24{base_ram_rdata[15]}}, base_ram_rdata[15:8]};
            end
            4'b1011: begin // 读取第三字节，符号扩展
                mem_rdata = {{24{base_ram_rdata[23]}}, base_ram_rdata[23:16]};
            end
            4'b0111: begin // 读取最高字节，符号扩展
                mem_rdata = {{24{base_ram_rdata[31]}}, base_ram_rdata[31:24]};
            end
            4'b0000: begin // 读取整个字
                mem_rdata = base_ram_rdata;
            end
            default: begin
                mem_rdata = base_ram_rdata;
            end
        endcase
    end else if(is_ext_ram) begin
        // 根据字节选择信号处理ExtRAM数据
        case (mem_sel_n)
            4'b1110: begin // 读取最低字节，符号扩展
                mem_rdata = {{24{ext_ram_rdata[7]}}, ext_ram_rdata[7:0]};
            end
            4'b1101: begin // 读取第二字节，符号扩展
                mem_rdata = {{24{ext_ram_rdata[15]}}, ext_ram_rdata[15:8]};
            end
            4'b1011: begin // 读取第三字节，符号扩展
                mem_rdata = {{24{ext_ram_rdata[23]}}, ext_ram_rdata[23:16]};
            end
            4'b0111: begin // 读取最高字节，符号扩展
                mem_rdata = {{24{ext_ram_rdata[31]}}, ext_ram_rdata[31:24]};
            end
            4'b0000: begin // 读取整个字
                mem_rdata = ext_ram_rdata;
            end
            default: begin
                mem_rdata = ext_ram_rdata;
            end
        endcase
    end
end

endmodule