// 文件: display_scan.v (修复了语法错误)
module display_scan #(
    parameter PWM_WIDTH = 8,
    parameter SCAN_MAX = 25000  // 扫描周期参数
)(
    input clk,                   // 50MHz时钟
    input rst_n,                 // 复位信号
    input [7:0] frame_data,      // 当前帧数据
    input [PWM_WIDTH-1:0] brightness, // PWM亮度值
    output reg [7:0] row,        // 行选择输出
    output reg [7:0] col,        // 列数据输出
    output reg [2:0] row_idx     // 当前行索引
);

// PWM计数器
reg [PWM_WIDTH-1:0] pwm_cnt = 0;

// 扫描计数器
reg [15:0] scan_counter = 0;

// 扫描时序控制
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scan_counter <= 0;
        row_idx <= 0;
        pwm_cnt <= 0;
        row <= 8'h01;  // 默认选择第一行
        col <= 8'hFF;  // 默认熄灭所有列
    end else begin
        // PWM计数器循环
        pwm_cnt <= pwm_cnt + 1;
        
        // 行扫描控制
        if (scan_counter >= SCAN_MAX - 1) begin
            scan_counter <= 0;
            if (row_idx == 3'd7) 
                row_idx <= 0;
            else 
                row_idx <= row_idx + 1;
        end else begin
            scan_counter <= scan_counter + 1;
        end
        
        // 行选择 (共阴极点阵)
        row <= (1 << row_idx);
        
        // 列数据计算 (关键修复：确保低亮度和零亮度完全熄灯)
        if (brightness == 0) begin
            col <= 8'hFF;  // 亮度为0时全灭
        end else if (pwm_cnt < brightness) begin
            col <= ~frame_data;  // 亮灯期间输出 (取反使0点亮)
        end else begin
            col <= 8'hFF;  // 熄灯期间输出
        end
    end
end

endmodule
