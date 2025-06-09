`timescale 1ns / 1ps

module PWM_Ctrl_Top(
    input   wire    clk     ,
    input   wire    rst_n   ,
    input   wire    key0    ,//Duty1
    input   wire    key1    ,//Duty2
    input   wire    key2    ,//Freq_All
    input   wire    key3    ,//Change
    //output
    output  reg     pwm1    ,
    output  reg     pwm2
);
//wire define
wire Duty1_Change;
wire Duty2_Change;

wire Freq_Change;
wire Out_Change;

//reg define
reg [13:0] Freq;
reg [7:0]  Duty1;
reg [7:0]  Duty2;

//Freq Logic
reg [3:0] Freq_State;
reg [3:0] Out_State;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Freq_State<=4'd0;
    end else if(Freq_Change==1'b1)begin
        Freq_State<=Freq_State+1;
    end else if(Freq_State>4'd8)begin
        Freq_State<=4'd0;
    end else begin
        Freq_State<=Freq_State;
    end 
end
//Out Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Out_State<=4'd0;
    end else if(Out_Change==1'b1)begin
        Out_State<=Out_State+1;
    end else if(Out_State>4'd3)begin
        Out_State<=4'd0;
    end else begin
        Out_State<=Out_State;
    end 
end


//Duty Logic
reg [3:0] Duty1_State;
reg [3:0] Duty2_State;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Duty1_State<=4'd0;
    end else if(Duty1_Change==1'b1)begin
        Duty1_State<=Duty1_State+1;
    end else if(Duty1_State>4'd9)begin
        Duty1_State<=4'd0;
    end else begin
        Duty1_State<=Duty1_State;
    end 
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Duty2_State<=4'd0;
    end else if(Duty2_Change==1'b1)begin
        Duty2_State<=Duty2_State+1;
    end else if(Duty2_State>4'd9)begin
        Duty2_State<=4'd0;
    end else begin
        Duty2_State<=Duty2_State;
    end 
end


//Duty in
always@(*)begin
    case(Duty1_State)
        4'd0:Duty1 =  10;
        4'd1:Duty1 =  20;
        4'd2:Duty1 =  30;
        4'd3:Duty1 =  40;
        4'd4:Duty1 =  50;
        4'd5:Duty1 =  60;
        4'd6:Duty1 =  70;
        4'd7:Duty1 =  80;
        4'd8:Duty1 =  90;
        4'd9:Duty1 = 100;
     default:Duty1 =  10;
    endcase
end
always@(*)begin
    case(Duty2_State)
        4'd0:Duty2 =  10;
        4'd1:Duty2 =  20;
        4'd2:Duty2 =  30;
        4'd3:Duty2 =  40;
        4'd4:Duty2 =  50;
        4'd5:Duty2 =  60;
        4'd6:Duty2 =  70;
        4'd7:Duty2 =  80;
        4'd8:Duty2 =  90;
        4'd9:Duty2 = 100;
     default:Duty2 =  10;
    endcase
end

//Freq in
always@(*)begin
    case(Freq_State)
        4'd0:Freq =   100; //100hz
        4'd1:Freq =   200; //200hz
        4'd2:Freq =   500; //500hz
        4'd3:Freq =   700; //700hz
        4'd4:Freq =  1000; // 1khz
        4'd5:Freq =  2000; // 2khz
        4'd6:Freq =  5000; // 5khz
        4'd7:Freq =  7000; // 7khz
        4'd8:Freq = 10000; //10khz
     default:Freq =   100;
    endcase
end

wire pwm1_wire;
wire pwm2_wire;

always@(*)begin
    case(Out_State)
        4'd0:begin pwm1 = 0         ; pwm2 = 0         ;end 
        4'd1:begin pwm1 = pwm1_wire ; pwm2 = 0         ;end 
        4'd2:begin pwm1 = 0         ; pwm2 = pwm2_wire ;end 
        4'd3:begin pwm1 = pwm1_wire ; pwm2 = pwm2_wire ;end 
     default:begin pwm1 = 0         ; pwm2 = 0         ;end
    endcase
end


PWM_gen u_PWM_gen (
    .clk  (clk       ),
    .rst_n(rst_n     ),
    .freq1(Freq      ),
    .freq2(Freq      ),
    .duty1(Duty1     ),
    .duty2(Duty2     ),
    .pwm1 (pwm1_wire ),
    .pwm2 (pwm2_wire )
);

key_filter u_key0
(
    .sys_clk  (clk      ),
    .sys_rst_n(rst_n    ),
    .key_in   (key0     ),
    .key_flag (Duty1_Change)
);
key_filter u_key1
(
    .sys_clk  (clk      ),
    .sys_rst_n(rst_n    ),
    .key_in   (key1     ),
    .key_flag (Duty2_Change)
);
key_filter u_key2
(
    .sys_clk  (clk      ),
    .sys_rst_n(rst_n    ),
    .key_in   (key2     ),
    .key_flag (Freq_Change)
);
key_filter u_key3
(
    .sys_clk  (clk      ),
    .sys_rst_n(rst_n    ),
    .key_in   (key3     ),
    .key_flag (Out_Change)
);


endmodule
