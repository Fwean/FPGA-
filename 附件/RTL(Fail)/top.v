// 文件: top.v
module top(
    input clk,               // 50MHz系统时钟
    input rst_n,             // 复位信号 (低电平有效)
    input uart_rx,          // UART接收引脚
    input key_up,            // 亮度增加按键
    input key_down,          // 亮度减少按键
    output [7:0] row,       // 点阵行选择信号
    output [7:0] col         // 点阵列数据
);

// 内部信号定义
wire [7:0] uart_data;
wire uart_valid;
wire [2:0] scan_row_idx;
wire [7:0] frame_data;
wire key_up_pulse, key_down_pulse;
wire cmd_brightness_valid;
wire [7:0] cmd_brightness;
reg [7:0] brightness_reg = 8'd128;  // 亮度寄存器，默认50%

// 模块实例化
uart_rx u_rx(
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .data_out(uart_data),
    .valid(uart_valid)
);

frame_buffer u_buffer(
    .clk(clk),
    .rst_n(rst_n),
    .wr_data(uart_data),
    .wr_en(uart_valid),
    .rd_data(frame_data),
    .row_idx(scan_row_idx),
    .cmd_brightness_valid(cmd_brightness_valid),
    .cmd_brightness(cmd_brightness)
);

key_debounce u_key_up(
    .clk(clk),
    .rst_n(rst_n),
    .key_in(key_up),
    .key_pulse(key_up_pulse)
);

key_debounce u_key_down(
    .clk(clk),
    .rst_n(rst_n),
    .key_in(key_down),
    .key_pulse(key_down_pulse)
);

display_scan u_scan(
    .clk(clk),
    .rst_n(rst_n),
    .frame_data(frame_data),
    .brightness(brightness_reg),
    .row(row),
    .col(col),
    .row_idx(scan_row_idx)
);

// 亮度控制逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        brightness_reg <= 8'd128;  // 默认亮度
    end else if (cmd_brightness_valid) begin
        brightness_reg <= cmd_brightness;  // UART命令设置亮度
    end else if (key_up_pulse) begin
        // 亮度增加 (上限255)
        if (brightness_reg < 8'd255) brightness_reg <= brightness_reg + 1;
    end else if (key_down_pulse) begin
        // 亮度减少 (下限0)
        if (brightness_reg > 8'd0) brightness_reg <= brightness_reg - 1;
    end
end

endmodule
