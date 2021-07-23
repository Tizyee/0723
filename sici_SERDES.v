/////////////////////sici_SERDES
//CNT_WAIT_W   delay模块每次延时等待时间的位宽
//WAIT_MAX     delay模块每次延时等待时间
//TEST         delay模块中ok状态验证q等待周期次数
////FW   PCS帧的宽度，数据宽度加上同步头SH的宽度，可以取需要的任何值
////SE   PCS扰码使能 1：使能，0：不使能
////D_W  E1侧数据位宽

`timescale 1ns/1ps
module sici_SERDES
#( parameter D_W = 42,FW=8,SWT = 64,SE = 1,TEST = 4,WAIT_MAX = 0,WAIT_W = 1) 
(        
  //全局信号
  input              Rs            ,  ////异步复位，高有效
//input              Ck_38         ,  ////38.88 CDR模块ce就是38
  input              Ck_77         ,  ////77.76 CDR模块输入77m
  input              Ck_311        ,  //// 
  //////////SERDES侧端口
  input              RX_UP_Dat     ,//UP数据，622M需要311 DDR 
  input              RX_UP_Ck      ,//UPck
  output             TX_Ck_622     ,/////同数据的CK 622M
  output             TX_UP_Dat     ,//发送UP数据 622M需要311 DDR    
  input              recal         ,//延时模块重新校准信号，1有效
  output             cal           ,//校准成功标志，高有效
  //////////E1_42信号输入端口
  input  [D_W-1:0]   E1_In_Dat     ,
  input  [D_W-1:0]   E1_In_Ck      ,
  //////////card和SSF  
  input  [3:0]       RX_CARD_TYPE  , 
  input  [41:0]      RX_SSF        ,  
  output  [3:0]      TX_CARD_TYPE  , //卡的类型
  output  [41:0]     TX_SSF        , //los信号
  //////////E1_Demux_CR侧端口 
  output   [3:0]     E1_Cha        ,
  output   [5:0]     TX_DV_Dat     ,                            
  ////管理接口      
  input              Tx_Err_CRC    ,  ////在发送侧插入CRC错误，高有效 
  input              Tx_Err_SH     ,  ////在发送侧插入SH同步头错误，高有效 
  input              Tx_Err_MF     ,  ////在发送侧插入复帧头错误，高有效 
  input              Rx_Re_Syn     ,  ////接收侧重新同步信号，高有效。
  output             Rx_Err_SH     ,  ////接收侧SH同步头错误指示，高有效
  output             Rx_Err_MF     ,  ////接收侧复帧同步头错误指示，高有效
  output             Rx_Lo_Syn     ,  ////接收侧帧失步指示，高有效
  output             Rx_Lo_MF      ,  ////接收侧复帧失步指示，高有效 
  output             Rx_Err_CRC    ,  ////接收侧CRC错误指示，高有效 
                    
  output             Rx_R_Lo_Syn   ,  ////远端帧失步指示，高有效
  output             Rx_R_Lo_MF    ,  ////远端复帧失步指示，高有效
  output             Rx_R_Err_CRC     ////远端CRC错误指示，高有效
);

wire [FW-1:0]    Rx_Phy_Dat,Tx_Phy_Dat;
sici 
#( .D_W(D_W),.FW(FW),.SWT(SWT),.SE(SE)) sici_top
(        
  //全局信号
  .Rs            (Rs)          ,  ////异步复位，高有效
//.Ck_38         (Ck_38)       ,  ////38.88 CDR模块ce就是38
  .Ck_77         (Ck_77)       ,  ////77.76 CDR模块输入77m
  //////////E1输入端口
  .E1_In_Dat     (E1_In_Dat)   ,
  .E1_In_Ck      (E1_In_Ck)    ,
//////////card和SSF  
  .RX_CARD_TYPE  (RX_CARD_TYPE), 
  .RX_SSF        (RX_SSF)      ,  
  .TX_CARD_TYPE  (TX_CARD_TYPE), //卡的类型
  .TX_SSF        (TX_SSF)      , //los信号
 //////////输出到E1_Demux_CR恢复E1时钟和数据 
  .E1_Cha        (E1_Cha)      ,
  .TX_DV_Dat     (TX_DV_Dat)   ,                            
  ////PHY侧接口//SERDES内侧接口       
  .Rx_Bit_Slp    (Rx_Bit_Slp)  ,  ////接SERDES的calib，比特滑动请求信号，高有效，当有效时，要求串并转换模块输出的并行数据滑动一比特，便于帧同步
  .Rx_Phy_Dat    (Rx_Phy_Dat)  ,  ////phy侧接收数据
  .Tx_Phy_Dat    (Tx_Phy_Dat)  ,  ////phy侧发送数据
  ////管理接口   告警信号      
  .Tx_Err_CRC    (Tx_Err_CRC)  ,  ////在发送侧插入CRC错误，高有效 
  .Tx_Err_SH     (Tx_Err_SH )  ,  ////在发送侧插入SH同步头错误，高有效 
  .Tx_Err_MF     (Tx_Err_MF )  ,  ////在发送侧插入复帧头错误，高有效 
  .Rx_Re_Syn     (Rx_Re_Syn )  ,  ////接收侧重新同步信号，高有效。
  .Rx_Err_SH     (Rx_Err_SH )  ,  ////接收侧SH同步头错误指示，高有效
  .Rx_Err_MF     (Rx_Err_MF )  ,  ////接收侧复帧同步头错误指示，高有效
  .Rx_Lo_Syn     (Rx_Lo_Syn )  ,  ////接收侧帧失步指示，高有效
  .Rx_Lo_MF      (Rx_Lo_MF  )  ,  ////接收侧复帧失步指示，高有效 
  .Rx_Err_CRC    (Rx_Err_CRC)  ,  ////接收侧CRC错误指示，高有效 
                 
  .Rx_R_Lo_Syn   (Rx_R_Lo_Syn ),  ////远端帧失步指示，高有效
  .Rx_R_Lo_MF    (Rx_R_Lo_MF  ),  ////远端复帧失步指示，高有效
  .Rx_R_Err_CRC  (Rx_R_Err_CRC)   ////远端CRC错误指示，高有效
);

SERDES 
#(.CNT_WAIT_W(WAIT_W),.WAIT_MAX(WAIT_MAX),.TEST(TEST)) SERDES_top
(    
  .Rs            (Rs)        ,//总复位，高复位
  .fclk          (Ck_311)    ,//311
  .pclk          (Ck_77)     ,//311/4
  .din           (RX_UP_Dat) ,//接收UP输入的串行数据
  .din_ck        (RX_UP_Ck)  ,//接收UP输入的串行数据的时钟
  .calib         (Rx_Bit_Slp),//ides16调整输出16位并行顺序，高有效，连接sici的Rx_Bit_Slp
  .recal         (recal)     ,//延时控制模块的重置,1有效
  .RX_Phy_Dat    (Tx_Phy_Dat),
                 
  .TX_Phy_Dat    (Rx_Phy_Dat),//din延时完成后的值，输出给sici_pcs
  .cal           (cal)       ,//delay模块中延时成功标志，1有效
  .Q             (TX_UP_Dat) , //sici输入的16位并行转成1位串行输出
  .Ck_622        (TX_Ck_622)  /////同数据的CK 622M
  );
endmodule