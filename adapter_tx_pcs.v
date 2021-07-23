`timescale 1ns/1ps
module adapter_tx_Pcs   //E1_mux发送进来处理后给Pcs
( 
  input                  Rs            ,  ////异步复位，高有效
  input                  Ck            ,  ////38.88	 
  ////E1_mux侧接口 
  input   [5:0]          Dv_Dat        , //dv和dat组合数据
  input   [3:0]          E1_MFI        , //起始复帧0-15
  ////保留域端口
  input    [3:0]         CARD_TYPE     , //输入的card类型，按复帧插入1位到Tx_PCS_SH_Res信号
  input    [41:0]        SSF           , //输入的SSF类型， 按复帧插入1位到Tx_PCS_SH_Res信号 
                        
  output  reg [7:0]      Tx_PCS_MFI    , //0-255帧
  output                 Tx_PCS_SH_Res , //插入帧的0位
  output  reg [8-2-1:0]  Tx_PCS_Dat      ////16位减去2位同步头
);

reg [3:0]  cnt;
always @(posedge Ck or posedge Rs )
begin
  if(Rs)
    cnt <= 4'b0;
  else if (E1_MFI==15)
    cnt <= cnt + 1'b1; 
end

always @(posedge Ck or posedge Rs )
begin
  if(Rs)
    Tx_PCS_MFI <= 8'b0;
  else 
    Tx_PCS_MFI <= {cnt[3:0],E1_MFI[3:0]};//输出的复帧在ck下输出,打了一拍
end

always @(posedge Ck or posedge Rs)  
begin
  if(Rs)
    Tx_PCS_Dat <= 6'b0;
  else 
    Tx_PCS_Dat[5:0] <= Dv_Dat[5:0];   //输出的dv和dat，打了一拍
end

reg [6:0] SH_reg;  //
always @(posedge Ck or posedge Rs )
begin
  if(Rs)
    SH_reg <= 7'b0;
  else
  begin
    case(Tx_PCS_MFI) //和复帧同步
	  28-1:SH_reg[6:3]= CARD_TYPE ;//时序下则提前一拍赋值
	  40-1:SH_reg     = SSF[41:35];
	  48-1:SH_reg     = SSF[34:28];
	  56-1:SH_reg     = SSF[27:21];
	  64-1:SH_reg     = SSF[20:14];
	  72-1:SH_reg     = SSF[13:7 ];
	  80-1:SH_reg     = SSF[6 :0 ];
      default:SH_reg  = SH_reg <<1;		  
	endcase
  end 	
end
 
assign  Tx_PCS_SH_Res = SH_reg[6];    //输出高位

endmodule	   