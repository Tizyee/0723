`timescale 1ns/1ps
module adapter_tx_pcs_top
#( parameter     D_W = 42 )  //数据位宽，可修改为8复用
(         
  input                    Ck      	   ,  //  38.88  
  input                    Rs     	   ,     
  input   [ D_W-1:0]     E1_In_Dat     ,
  input   [ D_W-1:0]     E1_In_Ck      ,
  input    [3:0]         CARD_TYPE     , 
  input    [41:0]        SSF           ,  
         
  output     [7:0]       Tx_PCS_MFI    , //0-255循环复帧
  output                 Tx_PCS_SH_Res , //插入帧的0位
  output     [8-2-1:0]   Tx_PCS_Dat      ////16位减去2位同步头
);

wire [3:0]     E1_MFI;
wire [5:0]     Dv_Dat;
//////////////E1通道信号转换复用模块
RX_E1_Mux #(.D_W(D_W))E1_Mux_uut
(
  .Ck      	   (Ck),      
  .Rs     	   (Rs),     
  .E1_In_Dat   (E1_In_Dat),//E1的数据，42路或8路
  .E1_In_Ck    (E1_In_Ck), //E1的时钟
  
  .E1_MFI      (E1_MFI),  //起始帧
  .Dv_Dat      (Dv_Dat)   //除去SH和高两位，12位；
);
//////////////////E1  TX到sici_pcs的适配模块
adapter_tx_Pcs  adapter_tx_Pcs_uut 
( 
  .Rs            (Rs),         ////异步复位，高有效
  .Ck            (Ck),         ////38.88	 

  .Dv_Dat        (Dv_Dat),     //
  .E1_MFI        (E1_MFI),     //起始帧
  .CARD_TYPE     (CARD_TYPE),  //输入的card类型，按复帧插入1位到Tx_PCS_SH_Res信号
  .SSF           (SSF),        //输入的SSF类型， 按复帧插入1位到Tx_PCS_SH_Res信号 

  .Tx_PCS_MFI    (Tx_PCS_MFI),    //0-255帧
  .Tx_PCS_SH_Res (Tx_PCS_SH_Res), //插入帧的0位
  .Tx_PCS_Dat    (Tx_PCS_Dat)     ////插入dv/dat组合的复帧2-13位数据，14-15插入0；
);

endmodule