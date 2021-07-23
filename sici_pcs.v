`timescale 1ns/1ps

////FW  PCS֡�Ŀ�ȣ����ݿ�ȼ���ͬ��ͷSH�Ŀ�ȣ�����ȡ��Ҫ���κ�ֵ
////SE  ����ʹ�� 1��ʹ�ܣ�0����ʹ��

module Sici_PCS #(parameter FW=40,SWT = 64,SE = 1)
      (
       ////ȫ���ź�
       input             Rs            ,  ////�첽��λ������Ч
       input             Rx_Ck         ,  ////����ʱ��
       input             Rx_CE         ,  ////����ʱ��ʹ�ܣ�����Ч
       input             Tx_Ck         ,  ////����ʱ��
       input             Tx_CE         ,  ////����ʱ��ʹ�ܣ�����Ч 
       ////PHY��ӿ�       
       output            Rx_Bit_Slp    ,  ////���ػ��������źţ�����Ч������Чʱ��Ҫ�󴮲�ת��ģ������Ĳ������ݻ���һ���أ�����֡ͬ��
       input  [FW-1:0]   Rx_Phy_Dat    ,  ////phy���������
       output [FW-1:0]   Tx_Phy_Dat    ,  ////phy�෢������
       ////ϵͳ��ӿ� 
       output [7:0]      Rx_PCS_MFI    ,  ////ϵͳ�ิ֡�źţ�0��255ѭ��                      
       output            Rx_PCS_SH_Res ,  ////ϵͳ��SH�������źţ���PCS_MFIһ����Գ�ȡ�Լ���Ҫ���ź�
       output [FW-2-1:0] Rx_PCS_Dat    ,  ////ϵͳ�������
                                
       input [7:0]       Tx_PCS_MFI    ,
       input             Tx_PCS_SH_Res ,  
       input [FW-2-1:0]  Tx_PCS_Dat    ,
                              
       ////����ӿ�
       input             Tx_Err_CRC    ,  ////�ڷ��Ͳ����CRC���󣬸���Ч
       input             Tx_Err_SH     ,  ////�ڷ��Ͳ����SHͬ��ͷ���󣬸���Ч
       input             Tx_Err_MF     ,  ////�ڷ��Ͳ���븴֡ͷ���󣬸���Ч
       input             Rx_Re_Syn     ,  ////���ղ�����ͬ���źţ�����Ч��
       output            Rx_Err_SH     ,  ////���ղ�SHͬ��ͷ����ָʾ������Ч
       output            Rx_Err_MF     ,  ////���ղิ֡ͬ��ͷ����ָʾ������Ч
       output            Rx_Lo_Syn     ,  ////���ղ�֡ʧ��ָʾ������Ч
       output            Rx_Lo_MF      ,  ////���ղิ֡ʧ��ָʾ������Ч 
       output            Rx_Err_CRC    ,  ////���ղ�CRC����ָʾ������Ч 
	   
       output            Rx_R_Lo_Syn   ,  ////Զ��֡ʧ��ָʾ������Ч
       output            Rx_R_Lo_MF    ,  ////Զ�˸�֡ʧ��ָʾ������Ч
       output            Rx_R_Err_CRC     ////Զ��CRC����ָʾ������Ч
	   
       
      );

//////////////////////////////////////////////////////////////���շ�����////////////////////////////////////////////      
      
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
////////////////////////////////////////////////////////////////���ͷ�����////////////////////////////////////////////      
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