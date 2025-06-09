// 文件: uart_rx.v
module uart_rx(
    input clk,           // 50MHz时钟
    input rst_n,         // 复位信号
    input uart_rx,       // UART接收数据线
    output reg [7:0] data_out,  // 接收到的数据
    output reg valid             // 数据有效标志
);

// 波特率参数 (115200 bps @ 50MHz)
localparam BAUD_CNT = 434;  // 50e6 / 115200 ≈ 434

// 状态定义
localparam IDLE = 1'b0;
localparam RECEIVE = 1'b1;

reg state = IDLE;
reg [3:0] bit_cnt;
reg [15:0] clk_cnt;
reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        bit_cnt <= 0;
        clk_cnt <= 0;
        data_reg <= 0;
        data_out <= 0;
        valid <= 0;
    end else begin
        valid <= 0;  // 默认无效
        
        case (state)
            IDLE: begin
                if (!uart_rx) begin  // 检测到起始位(低电平)
                    state <= RECEIVE;
                    clk_cnt <= 0;
                    bit_cnt <= 0;
                end
            end
            
            RECEIVE: begin
                if (clk_cnt == BAUD_CNT - 1) begin
                    clk_cnt <= 0;
                    
                    if (bit_cnt == 0) begin
                        // 验证起始位
                        if (!uart_rx) bit_cnt <= bit_cnt + 1;
                        else state <= IDLE;  // 无效起始位
                    end 
                    else if (bit_cnt < 9) begin // 数据位0-7
                        data_reg[bit_cnt-1] <= uart_rx;
                        bit_cnt <= bit_cnt + 1;
                    end
                    else begin  // 停止位
                        if (uart_rx) begin  // 有效停止位
                            data_out <= data_reg;
                            valid <= 1;
                        end
                        state <= IDLE;
                    end
                end 
                else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
        endcase
    end
end

endmodule
