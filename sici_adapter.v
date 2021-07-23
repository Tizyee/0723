
//////////////SICI_PCS适配模块顶层包含Rx和TX///////////////
`timescale 1ns/1ps
module sici_adapter
#( parameter D_W = 42 )  //数据位宽，可修改为8复用
(        
  //全局信号
  input              Rs            ,  ////异步复位，高有效
//input              Ck_38         ,  ////38.88 CDR模块ce就是38
  input              Ck_77         ,  ////77.76 CDR模块输入77m
//////////SICI_PCS的接收适配模块的端口
  input    [7:0]     Rx_PCS_MFI    , //0-255帧
  input              Rx_PCS_SH_Res , //帧的0位
  input  [8-2-1:0]   Rx_PCS_Dat    , ////14位数据（复帧除去SH）

  output  [3:0]      TX_CARD_TYPE  , //卡的类型
  output  [41:0]     TX_SSF        , //los信号
  output   [3:0]     E1_Cha        ,//输出到E1_Demux_CR恢复通道号
  output   [5:0]     TX_DV_Dat     ,//输出到E1_Demux_CR恢复E1时钟和数据
///////////RX_E1_MUX到SICI_PCS的top         
  input  [D_W-1:0]   E1_In_Dat     ,
  input  [D_W-1:0]   E1_In_Ck      ,
  input  [3:0]       RX_CARD_TYPE  , 
  input  [41:0]      RX_SSF        ,  
                     
  output [7:0]       Tx_PCS_MFI    , //0-255循环复帧
  output             Tx_PCS_SH_Res , //插入帧的0位
  output [8-2-1:0]   Tx_PCS_Dat      ////16位减去2位同步头
);

////////////////////RX_E1_MUX到SICI_PCS的top 
adapter_tx_pcs_top #(.D_W(D_W))   tx_pcs_top

(         
     .   Ck      	    (Ck_77)         ,  //  38.88  
     .   Rs     	    (Rs)            ,     
     .  E1_In_Dat       (E1_In_Dat)     ,  //接收E1进来的数据
     .  E1_In_Ck        (E1_In_Ck)      ,  //接收E1进来数据的时钟
     .  CARD_TYPE       (RX_CARD_TYPE)  ,  //接收卡类型
     .  SSF             (RX_SSF)        ,  //接收los信号
                                        
     .  Tx_PCS_MFI      (Tx_PCS_MFI)    , //发送到sici_pcs的 复帧号 
     .  Tx_PCS_SH_Res   (Tx_PCS_SH_Res) , //发送到sici_pcs的 SH
     .  Tx_PCS_Dat      (Tx_PCS_Dat)      //发送到sici_pcs的 14位数据（复帧除去SH）
);
////////////////////SICI_PCS的接收适配模块 
adapter_rx_pcs  rx_pcs //接收pcs发来的
( 
     .  Rs             (Rs),  ////异步复位，高有效
//   .  Ck_38          (Ck_38),  ////38.88
     .  Ck_77          (Ck_77),  ////77.76

     .  Rx_PCS_MFI     (Rx_PCS_MFI), //0-255帧
     .  Rx_PCS_SH_Res  (Rx_PCS_SH_Res), //插入帧的0位
     .  Rx_PCS_Dat     (Rx_PCS_Dat), ////16位减去2位同步头

     .  E1_Cha         (E1_Cha), //输出
     .  TX_DV_Dat      (TX_DV_Dat), //77.77m输出12位

     .  CARD_TYPE      (TX_CARD_TYPE), //输出的card类型，按复帧插入1位到Tx_PCS_SH_Res信号
     .  SSF            (TX_SSF) //输出的SSF类型， 按复帧插入1位到Tx_PCS_SH_Res信号   
);


endmodule