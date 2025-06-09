// 文件: frame_buffer.v
module frame_buffer(
    input clk,
    input rst_n,
    input [7:0] wr_data,  // 写入数据
    input wr_en,          // 写入使能
    output reg [7:0] rd_data, // 读数据
    input [2:0] row_idx,   // 当前行索引
    output reg cmd_brightness_valid, // 亮度命令有效
    output reg [7:0] cmd_brightness  // 亮度命令值
);

// 命令解析状态机
localparam IDLE    = 2'b00;
localparam HEADER1 = 2'b01;
localparam HEADER2 = 2'b10;
localparam COMMAND = 2'b11;

reg [1:0] state = IDLE;  // 当前状态

// 双缓冲存储器
reg [7:0] mem [0:127];     // 128字节存储 (64字节/缓冲)
reg buffer_switch = 0;     // 0:缓冲0(0-63) 1:缓冲1(64-127)
reg [6:0] write_addr = 0;  // 写地址 (0-127)

// 命令解析逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        cmd_brightness_valid <= 0;
        cmd_brightness <= 0;
    end else if (wr_en) begin
        cmd_brightness_valid <= 0;  // 默认无效
        
        case (state)
            IDLE:
                if (wr_data == 8'hAA) begin  // 命令头字节1
                    state <= HEADER1;
                end
            HEADER1:
                if (wr_data == 8'h55) begin  // 命令头字节2
                    state <= HEADER2;
                end else begin
                    state <= IDLE;  // 无效头
                end
            HEADER2:
                if (wr_data == 8'hBC) begin  // 命令头字节3
                    state <= COMMAND;
                end else begin
                    state <= IDLE;  // 无效头
                end
            COMMAND: begin
                cmd_brightness <= wr_data;    // 亮度值
                cmd_brightness_valid <= 1;   // 命令有效
                state <= IDLE;                // 返回空闲
            end
            default: state <= IDLE;
        endcase
    end
end

// 图像帧写入逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_addr <= 0;
        buffer_switch <= 0;
    end else if (wr_en && state == IDLE) begin
        // 跳过命令字节，仅写入图像数据
        if (write_addr[5:0] == 6'd63) begin  // 使用低位作为地址计数器
            buffer_switch <= ~buffer_switch;
            write_addr <= 0;
        end else begin
            if (buffer_switch) begin
                mem[{1'b1, write_addr[5:0]}] <= wr_data;
            end else begin
                mem[{1'b0, write_addr[5:0]}] <= wr_data;
            end
            write_addr <= write_addr + 1;
        end
    end
end

// 读取当前帧数据
always @(posedge clk) begin
    if (buffer_switch) 
        rd_data <= mem[{1'b0, row_idx}];  // 读取缓冲0
    else 
        rd_data <= mem[{1'b1, row_idx}];  // 读取缓冲1
end

endmodule
