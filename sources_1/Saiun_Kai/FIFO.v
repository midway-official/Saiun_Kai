module sync_fifo( 
    input                   i_clk,
    input                   i_rst,
    input                   i_w_en,
    input                   i_r_en,
    input  [361:0]          i_data,
    output [361:0]          o_data,       
    output                  o_buf_empty,
    output                  o_buf_full,
    output                  o_buf_almost_full
);
    // FIFO参数定义
    parameter DEPTH =4;
    parameter ADDR_WIDTH = 2;  // log2(DEPTH)
    parameter ALMOST_FULL_MARGIN = 1;  // 剩余几个空位时拉高 almost_full

    // 内部信号
    reg [361:0] fifo_mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr;  
    reg [ADDR_WIDTH:0] rd_ptr;  
    
    reg [361:0] output_reg;
    reg output_valid;
    wire fifo_empty_internal;
    wire fifo_rd_en_internal;
    
    // FIFO计数
    wire [ADDR_WIDTH:0] fifo_count;
    assign fifo_count = wr_ptr - rd_ptr;

    // 空/满/接近满信号
    assign fifo_empty_internal = (wr_ptr == rd_ptr);
    assign o_buf_empty         = !output_valid;
    assign o_buf_full          = (fifo_count == DEPTH);
    assign o_buf_almost_full   = (fifo_count >= (DEPTH - ALMOST_FULL_MARGIN));

    // FWFT逻辑
    assign fifo_rd_en_internal = (!fifo_empty_internal) && (!output_valid || i_r_en);

    // 写指针
    always @(posedge i_clk) begin
        if (i_rst) begin
            wr_ptr <= 0;
        end else if (i_w_en) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // 读指针
    always @(posedge i_clk) begin
        if (i_rst) begin
            rd_ptr <= 0;
        end else if (fifo_rd_en_internal) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // 写FIFO
    integer i;
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                fifo_mem[i] <= {362{1'b0}};
            end
        end else if (i_w_en ) begin
            fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_data;
        end
    end

    // 输出寄存器 (FWFT)
    always @(posedge i_clk) begin
        if (i_rst) begin
            output_reg   <= {362{1'b0}};
            output_valid <= 1'b0;
        end else begin
            if (fifo_rd_en_internal) begin
                output_reg   <= fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];
                output_valid <= 1'b1;
            end else if (i_r_en && output_valid) begin
                output_valid <= 1'b0;
            end
        end
    end

    // 输出
    assign o_data = output_valid ? output_reg : {362{1'b0}};

endmodule
