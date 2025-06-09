module key_filter
#(
    parameter           CNT_MAX = 20'd999_999
)
(
    input   wire        sys_clk,
    input   wire        sys_rst_n,
    input   wire        key_in,
    
    output  reg         key_flag
);
            reg [19:0]  cnt;

always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if(sys_rst_n == 1'b0)
            cnt <= 20'b0;
        else if(key_in == 1'b1)
            cnt <= 20'b0;
        else if(cnt == CNT_MAX && key_in == 1'b0)
            cnt <= cnt;
            else
            cnt <= cnt + 1'b1;
    end
//key_flag:当计数满 20ms 后产生按键有效标志位
//且 key_flag 在 999_999 时拉高,维持一个时钟的高电平

always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if(sys_rst_n == 1'b0)
            key_flag <= 1'b0;
        else if(cnt == CNT_MAX - 1'b1)
            key_flag <= 1'b1;
            else
            key_flag <= 1'b0;
    end
    
endmodule
