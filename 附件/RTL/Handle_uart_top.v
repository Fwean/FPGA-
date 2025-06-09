module Handle_uart_top(
    input  I_clk,        //外部50M时钟
    input  I_rst_n,      //外部复位信号，低有效

    input  uart_rxd,       //UART接收端口
    output uart_txd,        //UART发送端口
    output reg [4:0]  Led_X
);
//===========================================================================
parameter   CLK_FREQ=50000000;   //定义系统时钟频率
parameter   UART_BPS=9600;     //定义串口波特率
 
wire    uart_TX_en;             //串口发送使能
wire    [7:0] uart_TX_data;     //串口发送数据缓存
//===========================================================================
//实例化底层接收
uart_rx #(
    .CLK_FREQ       (CLK_FREQ),     
    .UART_BPS       (UART_BPS)      
    )                               
uart_rx_init(
    .I_clk        (I_clk),      
    .I_rst_n      (I_rst_n),    
    
    .uart_rxd       (uart_rxd),     
    .uart_done      (uart_TX_en),   
    .uart_data      (uart_TX_data)  
); 
//===========================================================================
//uart 数据缓存模块
reg        uart_TX_en_buf;
reg [23:0] uart_TX_data_buf;
reg        uart_en_flag;
always@(posedge I_clk or negedge I_rst_n)begin
    if(!I_rst_n)begin
        uart_TX_data_buf<=24'h000000;
        uart_TX_en_buf<=1'b0;
        uart_en_flag<=1'b0;
    end else if((uart_TX_en==1'b1)&&(uart_TX_en_buf==1'b0))begin
        uart_TX_data_buf<=uart_TX_data_buf;
        uart_TX_en_buf<=uart_TX_en;
        uart_en_flag<=1'b1;
    end else if(uart_en_flag==1'b1)begin
        uart_TX_data_buf<={uart_TX_data_buf[15:0],uart_TX_data};//前八位移位，后八位填兿
        uart_TX_en_buf<=uart_TX_en;
        uart_en_flag<=1'b0;
    end else begin
        uart_TX_data_buf<=uart_TX_data_buf;
        uart_TX_en_buf<=uart_TX_en;
        uart_en_flag<=1'b0;
    end
end
//============================================================================
//uart 数据缓存真！
reg [23:0] uart_TX_data_real;
always@(posedge I_clk or negedge I_rst_n)begin
    if(!I_rst_n)begin
        uart_TX_data_real<=24'h000000;
    end else if(uart_TX_data_buf[15:0]==16'hCCCC)begin
        uart_TX_data_real<=uart_TX_data_buf;
    end else begin
        uart_TX_data_real<=uart_TX_data_real;
    end
end


//===========================================================================
//Led_X 灯珠显示模式选取模块 1~24
always@(posedge I_clk or negedge I_rst_n)begin
    if(!I_rst_n)begin
        Led_X <= 5'd0;
    end else begin //if(uart_TX_data_real[15:0]==16'h0D0A)
        case(uart_TX_data_real[23:16])
             8'h30: Led_X <=  5'd0 ;
             8'h31: Led_X <=  5'd1 ;
             8'h32: Led_X <=  5'd2 ;
             8'h33: Led_X <=  5'd3 ;
             8'h34: Led_X <=  5'd4 ;
             8'h35: Led_X <=  5'd5 ;
             8'h36: Led_X <=  5'd6 ;
             8'h37: Led_X <=  5'd7 ;
             8'h38: Led_X <=  5'd8 ;
             8'h39: Led_X <=  5'd9 ;
             8'h40: Led_X <= 5'd10 ;
             8'h41: Led_X <= 5'd11 ;
             8'h42: Led_X <= 5'd12 ;
             8'h43: Led_X <= 5'd13 ;
             8'h44: Led_X <= 5'd14 ;
             8'h45: Led_X <= 5'd15 ;
             8'h46: Led_X <= 5'd16 ;
             8'h47: Led_X <= 5'd17 ;
             8'h48: Led_X <= 5'd18 ;
             8'h49: Led_X <= 5'd19 ;
             8'h20: Led_X <= 5'd20 ;
             8'h21: Led_X <= 5'd21 ;
             8'h22: Led_X <= 5'd22 ;
             8'h23: Led_X <= 5'd23 ;
             8'h24: Led_X <= 5'd24 ;
           default: Led_X <= Led_X ;
        endcase
    end 
end
//===========================================================================
//

uart_tx #(                          //串口发送模块
    .CLK_FREQ       (CLK_FREQ),       //设置系统时钟频率
    .UART_BPS       (UART_BPS))       //设置串口发送波特率
urat_tx_init(                 
    .I_clk        (I_clk),
    .I_rst_n      (I_rst_n),
     
    .uart_en        (uart_TX_en_buf),
    .uart_din       (uart_TX_data_buf[7:0]),
    .uart_txd       (uart_txd)
    );

    
endmodule
