module BRAM(
    input  wire        clk,        // 时钟
    input  wire        rst,        // 复位
    input  wire [19:0] addr_i,     // 外部物理地址（20位）
    output  wire [31:0] rdata,
    input  wire [31:0]  wdata,       
    input  wire        wen_i,      // 字节写使能（低有效）
    input  wire [3:0]  sel,        // 字节使能（低有效）
    input  wire        en_i        // 外部片选（低有效）
);

    // 地址偏移计算（高位减去偏移，低两位补0）
    wire [31:0] addr_offset;
    assign addr_offset =  {10'b0, addr_i, 2'b00}  - 32'h8000_0000;
    
    // BRAM 写使能，高有效
    // 只有写使能有效且片选有效时才写入
    wire [3:0] bram_wea;
    assign bram_wea = ( ~wen_i) ? ~sel : 4'b0000;
    
;
    
    // BRAM 实例化
    base_ram u_base_ram (
        .clka      (clk),
        .rsta      (rst),
        .rsta_busy (),
        .ena       (~en_i),          // BRAM使能信号，转换为高有效
        .wea       (bram_wea),
        .addra     (addr_offset), // 根据BRAM地址位宽调整
        .dina      (wdata),
        .douta     (rdata)
    );

endmodule