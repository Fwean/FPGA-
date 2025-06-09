
module  uart_rx   (
    input			  I_clk,                  //系统时钟
    input             I_rst_n,                //系统复位，低电平有效
    
    input             uart_rxd,                 //UART接收端口，这里代表的就是硬件RX引脚
    output  reg       uart_done,                //接收一帧数据完成标志信号
    output  reg [7:0] uart_data                 //接收的数据
    );
//parameter可用作在顶层模块中例化底层模块时传递参数的接口，
 
parameter  CLK_FREQ = 50000000;                 //系统时钟频率
parameter  UART_BPS = 9600;                     //串口波特率
 
//localparam的作用域仅仅限于当前module，不能作为参数传递的接口。
localparam  BPS_CNT=CLK_FREQ/UART_BPS; //为得到指定波特率，需要对系统时钟计数BPS_CNT次
 
reg uart_rxd_d0;
reg uart_rxd_d1;   
/* Used
reg [15:0]  clk_cnt;            //系统时钟计数器
reg [3:0]   rx_cnt;             //接收数据计数器
*/
reg [15:0]  clk_cnt;            //系统时钟计数器
reg [3:0]   rx_cnt;             //接收数据计数器
reg         rx_flag;            //接收过程标志信号
reg [7:0]   rxdata;             //接收数据缓存
 
wire    start_flag;             //进入接收过程标志
 
//边沿检测的一个时钟周期脉冲信号
assign  start_flag = uart_rxd_d1 & (~uart_rxd_d0);
 
always  @(posedge   I_clk or negedge I_rst_n)begin//系统时钟的上升沿触发  或者复位信号触发此always块
    if(!I_rst_n)  begin  
        uart_rxd_d0<=1'b0; //复位时清零
        uart_rxd_d1<=1'b0; //复位时清零
    end
    else begin
        uart_rxd_d0  <= uart_rxd;     //寄存  uart_rxd与实际电路连接，其连接的是uart的RX接口           
        uart_rxd_d1  <= uart_rxd_d0;
    end 
end  
 
//当脉冲信号start_flag(边沿检测)到达时，进入接收过程   
always @(posedge I_clk or negedge I_rst_n) begin     
     if(!I_rst_n)    
       rx_flag=1'b0;    
    else begin
    if(start_flag) //上一个模块控制的变量
            rx_flag<=1;    //进入接收过程
        else if((rx_cnt==4'd9/*9是8个数据尾+1个停止位*/)&&(clk_cnt==BPS_CNT/2/*当接收到第9个bit时，在波特率周期的中间将接收标志置零*/))  
                //clk_cnt：是波特率计数   rx_cnt：表示当前接收到第几个数据
            rx_flag<=0;
        else
            rx_flag<=rx_flag;    //保持原有值
    end 
end
 
//进入接收过程后，启动系统时钟计数器与接收数据计数器
always  @(posedge   I_clk or negedge I_rst_n)begin//系统时钟的上升沿触发  或者复位信号触发此always块
     if(!I_rst_n)  begin  
        clk_cnt<=16'b0; //复位时清零
        rx_cnt<=4'b0; //复位时清零
    end
    else if(rx_flag)//上一个模块控制的变量，表示当前处于接收状态
         begin
            if(clk_cnt<BPS_CNT-1)begin//波特率计数
                clk_cnt<=clk_cnt+1;//波特率接着计数
                rx_cnt<=rx_cnt;//还没有接收到新的bit，计数保持
            end   
            else begin
                clk_cnt<=16'd0;//波特率周期时间到，计数清零
                rx_cnt<=rx_cnt+1;                
            end
         end
         else begin
            clk_cnt<=16'b0; //复位时清零
            rx_cnt<=4'b0; //复位时清零
         end
end 
 
//将由外部接收到的数据放到uart接收缓存中
always @(posedge   I_clk or negedge I_rst_n)begin//系统时钟的上升沿触发  或者复位信号触发此always块
    if ( !I_rst_n)  
        rxdata <= 8'd0;                  //复位则清空缓存  
    else if(rx_flag)begin                //当前是接收状态
            if(clk_cnt==BPS_CNT/2)begin  //波特率周期一般的时候
                case (rx_cnt)            //接收到第几个bit
                 4'd1 : rxdata[0] <= uart_rxd_d1;   //寄存数据位最低位
                 4'd2 : rxdata[1] <= uart_rxd_d1;
                 4'd3 : rxdata[2] <= uart_rxd_d1;
                 4'd4 : rxdata[3] <= uart_rxd_d1;
                 4'd5 : rxdata[4] <= uart_rxd_d1;
                 4'd6 : rxdata[5] <= uart_rxd_d1;
                 4'd7 : rxdata[6] <= uart_rxd_d1;
                 4'd8 : rxdata[7] <= uart_rxd_d1;   //寄存数据位最高位
                 default:;  
                 endcase
            end
            else    
                rx_flag<=rx_flag;           //保持 
         end
     else
        rxdata<=8'd0;
end
 
always@(posedge   I_clk or negedge I_rst_n)begin//系统时钟的上升沿触发  或者复位信号触发此always块
     if (!I_rst_n) begin
        uart_data <= 8'd0;                               
        uart_done <= 1'b0;
     end
     else if(rx_cnt==4'd9)begin      //接收数据计数器计数到停止位时   
          uart_data <= rxdata;      //数据由此模块输出
          uart_done <= 1'b1;        //此模块输出的接收完成标志
     end 
     else begin
         uart_data <= 8'd0;         //没有接收完成，则清零                             
         uart_done <= 1'b0; 
     end
 
end
endmodule
