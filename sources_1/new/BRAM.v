module BRAM(
    input  wire        clk,        // ʱ��
    input  wire        rst,        // ��λ
    input  wire [19:0] addr_i,     // �ⲿ�����ַ��20λ��
    output  wire [31:0] rdata,
    input  wire [31:0]  wdata,       
    input  wire        wen_i,      // �ֽ�дʹ�ܣ�����Ч��
    input  wire [3:0]  sel,        // �ֽ�ʹ�ܣ�����Ч��
    input  wire        en_i        // �ⲿƬѡ������Ч��
);

    // ��ַƫ�Ƽ��㣨��λ��ȥƫ�ƣ�����λ��0��
    wire [31:0] addr_offset;
    assign addr_offset =  {10'b0, addr_i, 2'b00}  - 32'h8000_0000;
    
    // BRAM дʹ�ܣ�����Ч
    // ֻ��дʹ����Ч��Ƭѡ��Чʱ��д��
    wire [3:0] bram_wea;
    assign bram_wea = ( ~wen_i) ? ~sel : 4'b0000;
    
;
    
    // BRAM ʵ����
    base_ram u_base_ram (
        .clka      (clk),
        .rsta      (rst),
        .rsta_busy (),
        .ena       (~en_i),          // BRAMʹ���źţ�ת��Ϊ����Ч
        .wea       (bram_wea),
        .addra     (addr_offset), // ����BRAM��ַλ�����
        .dina      (wdata),
        .douta     (rdata)
    );

endmodule