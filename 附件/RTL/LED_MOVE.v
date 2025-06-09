module LED_MOVE(
    input   wire        clk     ,
    input   wire        rst_n   ,
    output  reg  [7:0]  Led_Move_State
);

//LED定时切换--0.5s
integer p;
reg clk_2Hz;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        clk_2Hz=1'b0;
    end else if(p==12500000-1)begin
        p=0;
        clk_2Hz=~clk_2Hz;
    end else begin
        p=p+1;
    end
end

always@(posedge clk_2Hz or negedge rst_n)begin
    if(!rst_n)begin
        Led_Move_State<=8'd11;
    end else if(Led_Move_State==8'd62)begin
        Led_Move_State<=8'd11;
    end else begin
        Led_Move_State<=Led_Move_State+1'b1;
    end
end




    
endmodule
