`timescale 1ns / 1ps

module PWM_gen(
    input clk,             // 系统时钟
    input rst_n,           // 复位信号
    input [13:0] freq1,    // PWM1的频率设置（直接设置PWM频率） [13:0] freq1,
    input [7:0] duty1,     // PWM1的占空比设置（0-100%）         [7:0] duty1,  
    output reg pwm1        // PWM1输出
);

// 系统时钟频率参数
localparam CLK_FREQ = 50000000; // 50MHz

// 计数器和比较器的最大值
reg [25:0] count1 = 0;
reg [25:0] compare1 = 0;

// 根据频率和占空比计算比较值
always@(*)begin
    compare1 = (CLK_FREQ / freq1) * duty1 / 100;
end

// PWM1逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count1 <= 0;
        pwm1 <= 0;
    end else begin
        if (count1 >= (CLK_FREQ / freq1) - 1) begin
            count1 <= 0;
        end else begin
            count1 <= count1 + 1;
        end
        if ((count1>=0)&&(count1 < compare1)) pwm1 = 1;
        else pwm1 = 0;
    end
end


endmodule
