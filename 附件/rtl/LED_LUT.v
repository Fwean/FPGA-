module LED_LUT(
    input   wire        clk     ,
    input   wire        rst_n   ,
    input   wire [7:0]  Led_State,
    output  reg  [7:0]  col,
    output  reg  [7:0]  row
);
//LED_RAM--切换显示字符
reg [63:0] LED_RAM;
always@(*)begin
    if(!rst_n)
        LED_RAM = 64'h00_00_00_00_00_00_00_00;
    else begin
    case(Led_State)
         8'd0: LED_RAM = 64'h0038444444444438;// 0
         8'd1: LED_RAM = 64'h081828080808083E;// 1
         8'd2: LED_RAM = 64'h003C66040C18307E;// 2
         8'd3: LED_RAM = 64'h003C66041C06663C;// 3
         8'd4: LED_RAM = 64'h000C0C14247E0404;// 4
         8'd5: LED_RAM = 64'h007C40407C04447C;// 5
         8'd6: LED_RAM = 64'h0038444078444438;// 6
         8'd7: LED_RAM = 64'h003E020408080808;// 7
         8'd8: LED_RAM = 64'h001C22221C22221C;// 8
         8'd9: LED_RAM = 64'h001C22221E02221C;// 9
        8'd10: LED_RAM = 64'h0000247E7E3C1800;// @
        //Donghua
        8'd11: LED_RAM = 64'h3C3C181818183C3C;// I
        8'd12: LED_RAM = 64'h3C3C181818183C3C;// I
        8'd13: LED_RAM = 64'h3C3C181818183C3C;// I
        8'd14: LED_RAM = 64'h3C3C181818183C3C;// I
        8'd15: LED_RAM = 64'h0066FFFFFF7E3C18;// LOVE
        8'd16: LED_RAM = 64'h0000247E7E3C1800;// LOVE
        8'd17: LED_RAM = 64'h0066FFFFFF7E3C18;// LOVE
        8'd18: LED_RAM = 64'h0000247E7E3C1800;// LOVE
        8'd19: LED_RAM = 64'h0066FFFFFF7E3C18;// LOVE
        8'd20: LED_RAM = 64'h0000247E7E3C1800;// LOVE
        8'd21: LED_RAM = 64'h0066FFFFFF7E3C18;// LOVE
        8'd22: LED_RAM = 64'h0000247E7E3C1800;// LOVE
        8'd23: LED_RAM = 64'h003C66041C06663C;// LOVE
        8'd24: LED_RAM = 64'h003C66041C06663C;// LOVE
        8'd25: LED_RAM = 64'h003C66040C18307E;// LOVE
        8'd26: LED_RAM = 64'h003C66040C18307E;// 3
        8'd27: LED_RAM = 64'h081828080808083E;// 2
        8'd28: LED_RAM = 64'h081828080808083E;// 1
        //cycle
        8'd29: LED_RAM = 64'h1818181818180018;
        8'd30: LED_RAM = 64'h1818181818180018;
        8'd31: LED_RAM = 64'h1818181818180018;
        8'd32: LED_RAM = 64'h1818181818180018;
        8'd33: LED_RAM = 64'h3C243C24FF24669A;
        8'd34: LED_RAM = 64'h3C243C24FF24669A;
        8'd35: LED_RAM = 64'h3C243C24FF24669A;
        8'd36: LED_RAM = 64'h244AD54455554458;
        8'd37: LED_RAM = 64'h244AD54455554458;
        8'd38: LED_RAM = 64'h244AD54455554458;
        8'd39: LED_RAM = 64'h1E02EAAFA1FF0107;
        8'd40: LED_RAM = 64'h1E02EAAFA1FF0107;
        8'd41: LED_RAM = 64'h1E02EAAFA1FF0107;
        8'd42: LED_RAM = 64'h040AF1AEA0EE0A0E;
        8'd43: LED_RAM = 64'h247E243C24DB24FF; 
        8'd44: LED_RAM = 64'h543810FE38549210;
        8'd45: LED_RAM = 64'h3C4281A581AB5D3E;      
        8'd46: LED_RAM = 64'h1818181818180018;
        8'd47: LED_RAM = 64'h3C4281A581AB5D3E;
        8'd48: LED_RAM = 64'h1818181818180018;
        8'd49: LED_RAM = 64'h3C4281A581AB5D3E;      
        8'd50: LED_RAM = 64'h1818181818180018;
        8'd51: LED_RAM = 64'h3C4281A581AB5D3E;
        8'd52: LED_RAM = 64'h1818181818180018;

      default: LED_RAM = LED_RAM;
    endcase
    end
end




//LED定时切换
reg [20:0] cnt1;    
reg [2:0] row_state;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt1 <= 20'd0;
        row_state <= 3'd0;
    end else begin
        // cnt1计数
        if (cnt1 == 20'd99) begin
            cnt1 <= 20'd0;
            row_state <= row_state + 1'b1;
        end else begin
            cnt1 <= cnt1 + 1'b1;
        end
    end
end

/*
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        row_state <= 3'd0;
    end else begin
        row_state <= row_state + 1'b1;
    end
end
*/
//LED_col --行列定时赋值
always@(posedge clk)begin
    case (row_state)
        3'd0: begin row <= 8'b10000000; col = {LED_RAM[63:56]};end//第1行
        3'd1: begin row <= 8'b01000000; col = {LED_RAM[55:48]};end//第2行
        3'd2: begin row <= 8'b00100000; col = {LED_RAM[47:40]};end//第3行
        3'd3: begin row <= 8'b00010000; col = {LED_RAM[39:32]};end//第4行
        3'd4: begin row <= 8'b00001000; col = {LED_RAM[31:24]};end//第5行
        3'd5: begin row <= 8'b00000100; col = {LED_RAM[23:16]};end//第6行
        3'd6: begin row <= 8'b00000010; col = {LED_RAM[15: 8]};end//第7行
        3'd7: begin row <= 8'b00000001; col = {LED_RAM[ 7: 0]};end//第8行
     default: begin row <= 8'b00000000; col = 8'b00000000;   end
    endcase
end

    
endmodule
