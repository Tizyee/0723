`timescale 1ns/1ps
module adapter_rx_pcs   //接收pcs发来的
( 
  input                  Rs            ,  ////异步复位，高有效
//input                  Ck_38         ,  ////38.88
  input                  Ck_77         ,  ////77.76
  
  input      [7:0]       Rx_PCS_MFI    , //0-255帧
  input                  Rx_PCS_SH_Res , //插入帧的0位
  input   [8-2-1:0]      Rx_PCS_Dat    , ////16位减去2位同步头
  
  output reg [3:0]       E1_Cha        , //输出0-16帧
  output reg [5:0]       TX_DV_Dat     , //77.77m输出6位
                                      
  output reg [3:0]       CARD_TYPE     , //输出的card类型，按复帧插入1位到Tx_PCS_SH_Res信号
  output reg [41:0]      SSF             //输出的SSF类型， 按复帧插入1位到Tx_PCS_SH_Res信号   
);      

assign  E1_Cha = Rx_PCS_MFI[3:0];//低4位复帧，连线0-15通道
assign  TX_DV_Dat = Rx_PCS_Dat;  //输出数据直接连线

//寄存SH到SH_reg低位，并右移留出低位
reg [6:0] SH_reg;
always @(posedge Ck_77 or posedge Rs)
begin
  if(Rs)
    SH_reg <= 7'b0;
  else 
  begin
    SH_reg <= {SH_reg[5:0],Rx_PCS_SH_Res}; //移位赋值会延时一拍执行 
  end
end

//输出card
always @(posedge Ck_77 or posedge Rs) //CARD电平不敏感
begin
  if(Rs)
    CARD_TYPE <= 4'b0;
  else if (Rx_PCS_MFI == 31+1) //下一刻执行完成
    CARD_TYPE = SH_reg[3:0];   //此时低四位的值是card
end

//输出SSF
always @(posedge Ck_77 or posedge Rs) //SSF电平不敏感
begin
  if(Rs)
    SSF <= 42'b0;
  else
    case(Rx_PCS_MFI)
	  46+1:SSF[6 :0 ] = SH_reg;
	  54+1:SSF[13:7 ] = SH_reg;
	  62+1:SSF[20:14] = SH_reg;
	  70+1:SSF[27:21] = SH_reg;
	  78+1:SSF[34:28] = SH_reg;
	  86+1:SSF[41:35] = SH_reg;
	  default:SSF = SSF ; //保持
    endcase
end

endmodule	   