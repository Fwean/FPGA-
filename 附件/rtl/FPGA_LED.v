module FPGA_LED(
    input   wire        clk     ,
    input   wire        rst_n   ,
    input   wire        key0    ,//
    input   wire        key1    ,//
    input   wire        key2    ,//
    input   wire        key3    ,//
    input   wire        uart_rxd,
    output  wire        uart_txd,
    output  reg  [7:0]  col     ,
    output  reg  [7:0]  row     
);
//wire define
wire Reverse;
wire Duty_up;
wire Duty_down;
wire Mode_Change;
reg  Reverse_Now;
reg  Move_now;
//use able
wire pwm1_wire;
wire [7:0] LUT_col;
wire [7:0] LUT_row;

/*--------------------------------------LED_CTRL-------------------------------------*/
//Reverse--极性反转
wire [7:0] Post_col;
wire [7:0] Post_row;
assign Post_col = (Reverse_Now==1'b1) ? LUT_col:(~LUT_col);
assign Post_row = LUT_row;
//PWM控制
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        col <= 8'b0;
        row <= 8'b0;
    end else begin
        col <=~(~Post_col & {8{~pwm1_wire}}); //用与 PWM为高电平才使能 达到占空比输出   & {8{pwm1_wire}}
        row <=Post_row ;
        
    end
end
/*--------------------------------------LED_MOVE-------------------------------------*/
//LED_MOVE--LED动起来
wire [4:0] Led_State;//Uart
wire [7:0] Led_Move_State;//Move Pic

wire [7:0] State_CTRL;
assign State_CTRL = (Move_now==1'b1) ? Led_Move_State: {4'b0000,Led_State};

LED_MOVE u_LED_MOVE(
    .clk           (clk           ),
    .rst_n         (rst_n&Move_now),//
    .Led_Move_State(Led_Move_State)
);

/*--------------------------------------LED_LUT--------------------------------------*/
//LED_LUT--用于读取对应的LED数据
LED_LUT u_LED_LUT(
    .clk      (clk      ),
    .rst_n    (rst_n    ),
    .Led_State(State_CTRL),
    .col      (LUT_col  ),
    .row      (LUT_row  )
);
/*-----------------------------------------UART-------------------------------------*/
//Uart
Handle_uart_top u_top(
    .I_clk   (clk       ),  //外部50M时钟
    .I_rst_n (rst_n     ),  //外部复位信号，低有效
    .uart_rxd(uart_rxd  ),  //UART接收端口
    .uart_txd(uart_txd  ),  //UART发送端口
    .Led_X   (Led_State )
);
/*------------------------------------------PWM-------------------------------------*/
//Duty Logic
reg [3:0] Duty1_State;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Duty1_State<=4'd1;
    end else if((Duty_up==1'b1)&&(Duty1_State<4'd10))begin
        Duty1_State<=Duty1_State+1;
    end else if((Duty_down==1'b1)&&(Duty1_State>4'd1))begin
        Duty1_State<=Duty1_State-1;
    end else begin
        Duty1_State<=Duty1_State;
    end 
end
//Duty in
reg [7:0]  Duty1;
always@(posedge clk or negedge rst_n)begin
    case(Duty1_State)
        4'd0:Duty1 <= 8'd1;
        4'd1:Duty1 <= 8'd10;
        4'd2:Duty1 <= 8'd20;
        4'd3:Duty1 <= 8'd30;
        4'd4:Duty1 <= 8'd40;
        4'd5:Duty1 <= 8'd50;
        4'd6:Duty1 <= 8'd60;
        4'd7:Duty1 <= 8'd70;
        4'd8:Duty1 <= 8'd80;
        4'd9:Duty1 <= 8'd90;
       4'd10:Duty1 <= 8'd95;
     default:Duty1 <= Duty1;
    endcase
end

PWM_gen u_PWM_gen (
    .clk  (clk       ),// 系统时钟
    .rst_n(rst_n     ),// 复位信号
    .freq1(14'd100),// PWM1的频率设置（直接设置PWM频率为50KHz） [13:0] freq1,
    .duty1(Duty1     ),// PWM1的占空比设置（0-100%）         [7:0] duty1,
    .pwm1 (pwm1_wire ) // PWM1输出
);
/*------------------------------------------KEY-------------------------------------*/

key_filter u_key0
(
    .sys_clk  (clk      ),
    .sys_rst_n(rst_n    ),
    .key_in   (key0     ),
    .key_flag (Reverse  )
);
key_filter u_key1
(
    .sys_clk  (clk      ),
    .sys_rst_n(rst_n    ),
    .key_in   (key1     ),
    .key_flag (Duty_up  )
);
key_filter u_key2
(
    .sys_clk  (clk      ),
    .sys_rst_n(rst_n    ),
    .key_in   (key2     ),
    .key_flag (Duty_down)
);
key_filter u_key3
(
    .sys_clk  (clk      ),
    .sys_rst_n(rst_n    ),
    .key_in   (key3     ),
    .key_flag (Mode_Change)
);

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Reverse_Now <= 1'b0;
    end else if(Reverse==1'b1)begin
        Reverse_Now <= ~Reverse_Now;
    end else begin
        Reverse_Now <= Reverse_Now;
    end 
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Move_now <= 1'b0;
    end else if(Mode_Change==1'b1)begin
        Move_now <= ~Move_now;
    end else begin
        Move_now <= Move_now;
    end 
end

/*
assign Reverse      = key0;
assign Duty_up      = key1;
assign Duty_down    = key2;
assign Mode_Change  = key3;
*/

endmodule
