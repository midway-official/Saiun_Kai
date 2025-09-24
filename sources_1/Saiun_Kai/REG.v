
module REG (
    input  wire              clk,
    input  wire              rst,
    // 写端口1（优先级高）
    input  wire              we1,
    input  wire [4:0]        waddr1,
    input  wire [31:0]       wdata1,
    // 写端口2
    input  wire              we2,
    input  wire [4:0]        waddr2,
    input  wire [31:0]       wdata2,
    // 读端口1
    input  wire              re_1,
    input  wire [4:0]        raddr_1,
    output reg  [31:0]       rdata_1,
    // 读端口2
    input  wire              re_2,
    input  wire [4:0]        raddr_2,
    output reg  [31:0]       rdata_2,
    // 读端口3
    input  wire              re_3,
    input  wire [4:0]        raddr_3,
    output reg  [31:0]       rdata_3,
    // 读端口4
    input  wire              re_4,
    input  wire [4:0]        raddr_4,
    output reg  [31:0]       rdata_4
);

reg [31:0] regs [0:31];    // 32个32位通用寄存器
integer i;

// 写入操作（时序逻辑）
always @(posedge clk) begin
    if (rst == 1'b1) begin  // 使用直接的1'b1而不是宏
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] <= 32'h00000000;  // 使用直接的0而不是宏
        end
    end else begin
        // 写端口1：当使能且地址不为0时写入
        if (we1 == 1'b1 && waddr1 != 5'b00000) begin
            regs[waddr1] <= wdata1;
        end
        
        // 写端口2：当使能且地址不为0，且不与写端口1地址冲突时写入
        if (we2 == 1'b1 && waddr2 != 5'b00000 && 
            !(we1 == 1'b1 && waddr1 == waddr2)) begin
            regs[waddr2] <= wdata2;
        end
    end
end

// 读端口1
always @(*) begin
    if (rst == 1'b1) begin
        rdata_1 = 32'h00000000;
    end else if (re_1 == 1'b1) begin
        if (raddr_1 == 5'b00000) begin
            rdata_1 = 32'h00000000;  // 0号寄存器始终为0
        end else if (raddr_1 == waddr1 && we1 == 1'b1) begin
            rdata_1 = wdata1;     // 写端口1前递（优先级高）
        end else if (raddr_1 == waddr2 && we2 == 1'b1) begin
            rdata_1 = wdata2;     // 写端口2前递
        end else begin
            rdata_1 = regs[raddr_1];  // 从寄存器读取
        end
    end else begin
        rdata_1 = 32'h00000000;
    end
end

// 读端口2
always @(*) begin
    if (rst == 1'b1) begin
        rdata_2 = 32'h00000000;
    end else if (re_2 == 1'b1) begin
        if (raddr_2 == 5'b00000) begin
            rdata_2 = 32'h00000000;  // 0号寄存器始终为0
        end else if (raddr_2 == waddr1 && we1 == 1'b1) begin
            rdata_2 = wdata1;     // 写端口1前递（优先级高）
        end else if (raddr_2 == waddr2 && we2 == 1'b1) begin
            rdata_2 = wdata2;     // 写端口2前递
        end else begin
            rdata_2 = regs[raddr_2];  // 从寄存器读取
        end
    end else begin
        rdata_2 = 32'h00000000;
    end
end

// 读端口3
always @(*) begin
    if (rst == 1'b1) begin
        rdata_3 = 32'h00000000;
    end else if (re_3 == 1'b1) begin
        if (raddr_3 == 5'b00000) begin
            rdata_3 = 32'h00000000;
        end else if (raddr_3 == waddr1 && we1 == 1'b1) begin
            rdata_3 = wdata1;
        end else if (raddr_3 == waddr2 && we2 == 1'b1) begin
            rdata_3 = wdata2;
        end else begin
            rdata_3 = regs[raddr_3];
        end
    end else begin
        rdata_3 = 32'h00000000;
    end
end

// 读端口4
always @(*) begin
    if (rst == 1'b1) begin
        rdata_4 = 32'h00000000;
    end else if (re_4 == 1'b1) begin
        if (raddr_4 == 5'b00000) begin
            rdata_4 = 32'h00000000;
        end else if (raddr_4 == waddr1 && we1 == 1'b1) begin
            rdata_4 = wdata1;
        end else if (raddr_4 == waddr2 && we2 == 1'b1) begin
            rdata_4 = wdata2;
        end else begin
            rdata_4 = regs[raddr_4];
        end
    end else begin
        rdata_4 = 32'h00000000;
    end
end

endmodule
//module regfile2 (
//    input  wire              clk,
//    input  wire              rst,
//    // 写端口1（优先级高）
//    input  wire              we1,
//    input  wire [4:0]        waddr1,
//    input  wire [31:0]       wdata1,
//    // 写端口2
//    input  wire              we2,
//    input  wire [4:0]        waddr2,
//    input  wire [31:0]       wdata2,
//    // 读端口1
//    input  wire              re_1,
//    input  wire [4:0]        raddr_1,
//    output reg  [31:0]       rdata_1,
//    // 读端口2
//    input  wire              re_2,
//    input  wire [4:0]        raddr_2,
//    output reg  [31:0]       rdata_2,
//    // 读端口3
//    input  wire              re_3,
//    input  wire [4:0]        raddr_3,
//    output reg  [31:0]       rdata_3,
//    // 读端口4
//    input  wire              re_4,
//    input  wire [4:0]        raddr_4,
//    output reg  [31:0]       rdata_4
//);

//reg [31:0] regs [0:31];    // 32个32位通用寄存器
//integer i;

//// 写入操作（时序逻辑）
//always @(posedge clk) begin
//    if (rst == `RstEnable) begin
//        for (i = 0; i < 32; i = i + 1) begin
//            regs[i] <= `ZeroWord;
//        end
//    end else begin
//        // 写端口1：当使能且地址不为0且没有与写端口2冲突时写入
//        if (we1 == `WriteEnable && waddr1 != 5'b00000 && !(we2 == `WriteEnable && waddr2 == waddr1)) begin
//            regs[waddr1] <= wdata1;
//        end
//        // 写端口2：当使能且地址不为0时写入（如果与写端口1冲突，写端口1优先）
//        if (we2 == `WriteEnable && waddr2 != 5'b00000 && !(we1 == `WriteEnable && waddr1 == waddr2)) begin
//            regs[waddr2] <= wdata2;
//        end
//    end
//end

//// 带前递的读逻辑函数
//function [31:0] read_data;
//    input wire        re;
//    input wire [4:0]  raddr;
//begin
//    if (rst == `RstEnable) begin
//        read_data = `ZeroWord;
//    end else begin
//        if (re == `ReadEnable) begin
//            if (raddr == 5'b00000) begin
//                read_data = `ZeroWord;  // 0号寄存器始终为0
//            end else if (raddr == waddr1 && we1 == `WriteEnable) begin
//                read_data = wdata1;     // 写端口1前递（优先级高）
//            end else if (raddr == waddr2 && we2 == `WriteEnable) begin
//                read_data = wdata2;     // 写端口2前递
//            end else begin
//                read_data = regs[raddr];  // 从寄存器读取
//            end
//        end else begin
//            read_data = `ZeroWord;
//        end
//    end
//end
//endfunction

//// 多读口赋值（组合逻辑）
//always @(*) begin
//    rdata_1 = read_data(re_1, raddr_1);
//end

//always @(*) begin
//    rdata_2 = read_data(re_2, raddr_2);
//end

//always @(*) begin
//    rdata_3 = read_data(re_3, raddr_3);
//end

//always @(*) begin
//    rdata_4 = read_data(re_4, raddr_4);
//end

//endmodule // regfile2