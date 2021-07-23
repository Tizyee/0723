////FW   PCS帧的宽度，数据宽度加上同步头SH的宽度，可以取需要的任何值
////SE   PCS扰码使能 1：使能，0：不使能
////D_W  E1侧数据位宽

//////////////SICI顶层包含adapter和pcs///////////////
`timescale 1ns/1ps
module sici
#( parameter D_W = 42,FW=8,SWT = 64,SE = 1) 
(        
  //全局信号
  input              Rs            ,  ////异步复位，高有效
//input              Ck_38         ,  ////38.88 CDR模块ce就是38
  input              Ck_77         ,  ////77.76 CDR模块输入77m
  //////////E1输入端口
  input  [D_W-1:0]   E1_In_Dat     ,
  input  [D_W-1:0]   E1_In_Ck      ,
//////////card和SSF  
  input  [3:0]       RX_CARD_TYPE  , 
  input  [41:0]      RX_SSF        ,  
  output  [3:0]      TX_CARD_TYPE  , //卡的类型
  output  [41:0]     TX_SSF        , //los信号
 //////////输出到E1_Demux_CR恢复E1时钟和数据 
  output   [3:0]     E1_Cha        ,
  output   [5:0]     TX_DV_Dat     ,                            
  ////PHY侧接口       
  output             Rx_Bit_Slp    ,  ////接SERDES的calib，比特滑动请求信号，高有效，当有效时，要求串并转换模块输出的并行数据滑动一比特，便于帧同步
  input  [FW-1:0]    Rx_Phy_Dat    ,  ////phy侧接收数据
  output [FW-1:0]    Tx_Phy_Dat    ,  ////phy侧发送数据
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
wire            Rx_PCS_SH_Res,Tx_PCS_SH_Res;
wire [7:0]      Rx_PCS_MFI,Tx_PCS_MFI      ;
wire [FW-2-1:0] Tx_PCS_Dat,Rx_PCS_Dat      ;
/////////////////sici_adapter模块
sici_adapter #( .D_W(D_W))  //数据位宽，可修改为8复用
adapter
(        
  //全局信号
  .Rs            (Rs)           ,  ////异步复位，高有效
//.Ck_38         (Ck_38)        ,  ////38.88 CDR模块ce就是38
  .Ck_77         (Ck_77)        ,  ////77.76 CDR模块输入77m
//////////SICI_PCS的接收适配模块的端口
  .Rx_PCS_MFI    (Rx_PCS_MFI)   , //0-255帧
  .Rx_PCS_SH_Res (Rx_PCS_SH_Res), //帧的0位
  .Rx_PCS_Dat    (Rx_PCS_Dat)   , ////14位数据（复帧除去SH）

  .TX_CARD_TYPE  (TX_CARD_TYPE) , //卡的类型
  .TX_SSF        (TX_SSF)       , //los信号
  .E1_Cha        (E1_Cha)       ,//输出到E1_Demux_CR恢复通道号
  .TX_DV_Dat     (TX_DV_Dat)    ,//输出到E1_Demux_CR恢复E1时钟和数据
///////////RX_E1_MUX到SICI_PCS的top         
  .E1_In_Dat     (E1_In_Dat)    ,
  .E1_In_Ck      (E1_In_Ck)     ,
  .RX_CARD_TYPE  (RX_CARD_TYPE) , 
  .RX_SSF        (RX_SSF)       ,  

  .Tx_PCS_MFI    (Tx_PCS_MFI)   , //0-255循环复帧
  .Tx_PCS_SH_Res (Tx_PCS_SH_Res), //插入帧的0位
  .Tx_PCS_Dat    (Tx_PCS_Dat)  ////16位减去2位同步头
);

/////////////////////Sici_PCS模块
Sici_PCS #(.FW(FW),.SWT(SWT),.SE(SE)) 
PCS
(
       ////全局信号
  .Rs            (Rs)           ,  ////异步复位，高有效
  .Rx_Ck         (Ck_77)        ,  ////接收时钟   驱动适配模块数据传输的时钟  38.88
  .Rx_CE         (1'b1)         ,  ////接收时钟使能，高有效
  .Tx_Ck         (Ck_77)        ,  ////发送时钟   驱动适配模块数据传输的时钟  38.88
  .Tx_CE         (1'b1)         ,  ////发送时钟使能，高有效
       ////PHY侧接口            
  .Rx_Bit_Slp    (Rx_Bit_Slp)   ,  ////比特滑动请求信号，高有效，当有效时，要求串并转换模块输出的并行数据滑动一比特，便于帧同步
  .Rx_Phy_Dat    (Rx_Phy_Dat)   ,  ////phy侧接收数据
  .Tx_Phy_Dat    (Tx_Phy_Dat)   ,  ////phy侧发送数据
       ////系统侧接口 ///发送到sici_adapter
  .Rx_PCS_MFI    (Rx_PCS_MFI)   ,  ////系统侧复帧信号，0到255循环                      
  .Rx_PCS_SH_Res (Rx_PCS_SH_Res),  ////系统侧SH及保留信号，和PCS_MFI一起可以抽取自己需要的信号
  .Rx_PCS_Dat    (Rx_PCS_Dat)   ,  ////系统侧的数据
               
  .Tx_PCS_MFI    (Tx_PCS_MFI)   ,
  .Tx_PCS_SH_Res (Tx_PCS_SH_Res),  
  .Tx_PCS_Dat    (Tx_PCS_Dat)   ,                           
       ////管理接口
  .Tx_Err_CRC    (Tx_Err_CRC)   ,  ////在发送侧插入CRC错误，高有效
  .Tx_Err_SH     (Tx_Err_SH)    ,  ////在发送侧插入SH同步头错误，高有效
  .Tx_Err_MF     (Tx_Err_MF)    ,  ////在发送侧插入复帧头错误，高有效
  .Rx_Re_Syn     (Rx_Re_Syn)    ,  ////接收侧重新同步信号，高有效。
  .Rx_Err_SH     (Rx_Err_SH)    ,  ////接收侧SH同步头错误指示，高有效
  .Rx_Err_MF     (Rx_Err_MF)    ,  ////接收侧复帧同步头错误指示，高有效
  .Rx_Lo_Syn     (Rx_Lo_Syn)    ,  ////接收侧帧失步指示，高有效
  .Rx_Lo_MF      (Rx_Lo_MF)     ,  ////接收侧复帧失步指示，高有效 
  .Rx_Err_CRC    (Rx_Err_CRC)   ,  ////接收侧CRC错误指示，高有效 

  .Rx_R_Lo_Syn   (Rx_R_Lo_Syn)  ,  ////远端帧失步指示，高有效
  .Rx_R_Lo_MF    (Rx_R_Lo_MF)   ,  ////远端复帧失步指示，高有效
  .Rx_R_Err_CRC  (Rx_R_Err_CRC)    ////远端CRC错误指示，高有效  
);
endmodule