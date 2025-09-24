module uart_simulation(
    input clk,
    input rst_n,
    input rxd,          // ���ڽ����ź�
    output txd          // ���ڷ����ź�
);

    // ���ڽ����ź�
    wire RxD_data_ready;
    reg RxD_clear;
    wire [7:0] RxD_data;
    
    // ���ڷ����ź�
    wire TxD_busy;
    reg TxD_start;
    reg [7:0] TxD_data;
    
    // ״̬������
    localparam IDLE = 4'd0;
    localparam WAIT_2E_RECEIVED = 4'd1;
    localparam WAIT_00_RECEIVED = 4'd2;
    localparam SEND_A = 4'd3;
    localparam SEND_80100000_BYTE0 = 4'd4;
    localparam SEND_80100000_BYTE1 = 4'd5;
    localparam SEND_80100000_BYTE2 = 4'd6;
    localparam SEND_80100000_BYTE3 = 4'd7;
    localparam SEND_00001000_BYTE0 = 4'd8;
    localparam SEND_00001000_BYTE1 = 4'd9;
    localparam SEND_00001000_BYTE2 = 4'd10;
    localparam SEND_00001000_BYTE3 = 4'd11;
    localparam SEND_FF_LOOP = 4'd12;
    localparam WAIT_SEND_COMPLETE = 4'd13;
    
    reg [3:0] state, next_state;
    
    // �ֽڷ��ͻ���
    reg [3:0] send_byte_idx;

    // ���ڽ���ģ��ʵ����
    async_receiver #(.ClkFrequency(50_000000),.Baud(9600))
                    ext_uart_r(
                       .clk(clk),
                       .RxD(rxd),
                       .RxD_data_ready(RxD_data_ready),
                       .RxD_clear(RxD_clear),
                       .RxD_data(RxD_data)
                    );
    
    // ���ڷ���ģ��ʵ����
    async_transmitter #(.ClkFrequency(50_000000),.Baud(9600))
                        ext_uart_t(
                          .clk(clk),
                          .TxD(txd),
                          .TxD_busy(TxD_busy),
                          .TxD_start(TxD_start),
                          .TxD_data(TxD_data)
                        );
    
  // ״̬��ʱ���߼���ͬ������״̬�Ĵ���
always @(posedge clk or negedge rst_n) begin
    if (rst_n) begin
        state <= IDLE;
        send_byte_idx <= 0;
        RxD_clear <= 0;
    end else begin
        state <= next_state;  // ״̬��ʱ�������ظ���
    end
end

// ״̬������߼�������next_state������ź�
always @(*) begin
    // Ĭ�ϸ�ֵ����ֹ����������
    next_state = state;
    TxD_start = 1'b0;
    TxD_data = 8'h00;
    RxD_clear = 1'b0;

    case (state)
        IDLE: begin
            if (RxD_data_ready) begin
                RxD_clear = 1'b1;
                if (RxD_data == 8'h2E) 
                    next_state = SEND_A;
            end
        end

        WAIT_2E_RECEIVED: begin
            if (RxD_data_ready) begin
                RxD_clear = 1'b1;
                if (RxD_data == 8'h00)
                    next_state = SEND_A;
                else
                    next_state = IDLE;
            end
        end

        SEND_A: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h44; // ASCII 'D'
                next_state = SEND_80100000_BYTE0;
            end
        end

        SEND_80100000_BYTE0: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h00;
                next_state = SEND_80100000_BYTE1;
            end
        end

        SEND_80100000_BYTE1: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h00;
                next_state = SEND_80100000_BYTE2;
            end
        end

        SEND_80100000_BYTE2: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h10;
                next_state = SEND_80100000_BYTE3;
            end
        end

        SEND_80100000_BYTE3: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h80;
                next_state = SEND_00001000_BYTE0;
            end
        end

        SEND_00001000_BYTE0: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h10;
                next_state = SEND_00001000_BYTE1;
            end
        end

        SEND_00001000_BYTE1: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h00;
                next_state = SEND_00001000_BYTE2;
            end
        end

        SEND_00001000_BYTE2: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h00;
                next_state = SEND_00001000_BYTE3;
            end
        end

        SEND_00001000_BYTE3: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'h00;
                next_state = SEND_FF_LOOP;
            end
        end

        SEND_FF_LOOP: begin
            if (!TxD_busy) begin
                TxD_start = 1'b1;
                TxD_data = 8'hFF;
                next_state = SEND_FF_LOOP; // ����ѭ��
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule
