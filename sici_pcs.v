`timescale 1ns/1ps

////FW  PCS帧的宽度，数据宽度加上同步头SH的宽度，可以取需要的任何值
////SE  扰码使能 1：使能，0：不使能

module Sici_PCS #(parameter FW=40,SWT = 64,SE = 1)
      (
       ////全局信号
       input             Rs            ,  ////异步复位，高有效
       input             Rx_Ck         ,  ////接收时钟
       input             Rx_CE         ,  ////接收时钟使能，高有效
       input             Tx_Ck         ,  ////发送时钟
       input             Tx_CE         ,  ////发送时钟使能，高有效 
       ////PHY侧接口       
       output            Rx_Bit_Slp    ,  ////比特滑动请求信号，高有效，当有效时，要求串并转换模块输出的并行数据滑动一比特，便于帧同步
       input  [FW-1:0]   Rx_Phy_Dat    ,  ////phy侧接收数据
       output [FW-1:0]   Tx_Phy_Dat    ,  ////phy侧发送数据
       ////系统侧接口 
       output [7:0]      Rx_PCS_MFI    ,  ////系统侧复帧信号，0到255循环                      
       output            Rx_PCS_SH_Res ,  ////系统侧SH及保留信号，和PCS_MFI一起可以抽取自己需要的信号
       output [FW-2-1:0] Rx_PCS_Dat    ,  ////系统侧的数据
                                
       input [7:0]       Tx_PCS_MFI    ,
       input             Tx_PCS_SH_Res ,  
       input [FW-2-1:0]  Tx_PCS_Dat    ,
                              
       ////管理接口
       input             Tx_Err_CRC    ,  ////在发送侧插入CRC错误，高有效
       input             Tx_Err_SH     ,  ////在发送侧插入SH同步头错误，高有效
       input             Tx_Err_MF     ,  ////在发送侧插入复帧头错误，高有效
       input             Rx_Re_Syn     ,  ////接收侧重新同步信号，高有效。
       output            Rx_Err_SH     ,  ////接收侧SH同步头错误指示，高有效
       output            Rx_Err_MF     ,  ////接收侧复帧同步头错误指示，高有效
       output            Rx_Lo_Syn     ,  ////接收侧帧失步指示，高有效
       output            Rx_Lo_MF      ,  ////接收侧复帧失步指示，高有效 
       output            Rx_Err_CRC    ,  ////接收侧CRC错误指示，高有效 
	   
       output            Rx_R_Lo_Syn   ,  ////远端帧失步指示，高有效
       output            Rx_R_Lo_MF    ,  ////远端复帧失步指示，高有效
       output            Rx_R_Err_CRC     ////远端CRC错误指示，高有效
	   
       
      );

//////////////////////////////////////////////////////////////接收方向处理////////////////////////////////////////////      
      
wire           Syn_OK_Inn ;
wire  [FW-1:0] PCS_Dat_Inn;
      
Sici_PCS_Syn #(.FW(FW), .SWT(SWT),.ENT(32),.EXT(4)) SYNC
      (
       
       .Rs      (Rs         ),  
       .Ck      (Rx_Ck      ),
       .CE      (Rx_CE      ),  
       .Bit_Slp (Rx_Bit_Slp ),  
       .Phy_Dat (Rx_Phy_Dat ),
       .Syn_OK  (Syn_OK_Inn ),
       .PCS_Dat (PCS_Dat_Inn),
       .Re_Syn  (Rx_Re_Syn  ),
       .Err_SH  (Rx_Err_SH  ),
       .Lo_Syn  (Rx_Lo_Syn  ) 
      );   
      
wire  [FW-2-1:0] PCS_Dat_Des;
Sici_PCS_OH_Ext #(.FW(FW))  SH_EXTR
      (
       .Rs         (Rs                 ),  
       .Ck         (Rx_Ck              ),
       .CE         (Rx_CE              ),  
       .Syn_OK     (Syn_OK_Inn         ),
       .PCS_Dat_i  (PCS_Dat_Inn[FW-1:0]), 
       .PCS_MFI    (Rx_PCS_MFI         ), 
       .PCS_SH_Res (Rx_PCS_SH_Res      ),  
       .PCS_Dat_o  (PCS_Dat_Des        ),
									   
       .Err_MF     (Rx_Err_MF          ),
       .Lo_MF      (Rx_Lo_MF           ),
       .Err_CRC    (Rx_Err_CRC         ),
									   
       .R_Lo_Syn   (Rx_R_Lo_Syn        ),  
       .R_Lo_MF    (Rx_R_Lo_MF         ),  
       .R_Err_CRC  (Rx_R_Err_CRC       )   
	   
      );

generate
begin
  if(SE == 1)            
    Descram #(.DW(FW-2), .DI(58'h3ffffffffffffff),.PP(58), .POLY(59'h400008000000001)) DES
          (
           
           .Rs     (Rs          ),  
           .Ck     (Rx_Ck       ),
           .CE     (Rx_CE       ),  
           .Des_En (1'b1        ),  
           .Dat_i  (PCS_Dat_Des ),  
           .Dat_o  (Rx_PCS_Dat  )   
          );
  else
    assign Rx_PCS_Dat = PCS_Dat_Des;
            
end
endgenerate      
////////////////////////////////////////////////////////////////发送方向处理////////////////////////////////////////////      
wire  [FW-2-1:0] PCS_Dat_Scr;      

generate
begin
  if(SE == 1)            
    Scram #(.DW(FW-2), .SI(58'h3ffffffffffffff),.PP(58), .POLY(59'h400008000000001)) SCR
      (
       
       .Rs     (Rs         ),  
       .Ck     (Tx_Ck      ),
       .CE     (Tx_CE      ),  
       .Scr_En (1'b1       ),  
       .Dat_i  (Tx_PCS_Dat ),  
       .Dat_o  (PCS_Dat_Scr)   
      );
  else
    assign PCS_Dat_Scr = Tx_PCS_Dat;
            
end
endgenerate      
      
      
Sici_PCS_OH_Ins #(.FW(FW))   SH_INS
      (
       .Rs        (Rs           ),  
       .Ck        (Tx_Ck        ),
       .CE        (Tx_CE        ),  
       .PCS_Dat_o (Tx_Phy_Dat   ), 
       .PCS_MFI   (Tx_PCS_MFI   ), 
       .PCS_SH_Res(Tx_PCS_SH_Res),            
       .PCS_Dat_i (PCS_Dat_Scr  ),
	   
       .Rx_Lo_Syn (Rx_Lo_Syn    ),  
       .Rx_Lo_MF  (Rx_Lo_MF     ),  
       .Rx_Err_CRC(Rx_Err_CRC   ),  
	   
       .Err_SH    (Tx_Err_SH    ),
       .Err_MF    (Tx_Err_MF    ),
       .Err_CRC   (Tx_Err_CRC   )
      );
      

endmodule