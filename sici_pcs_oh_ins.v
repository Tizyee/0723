`timescale 1ns/1ps

////FW   PCS���Ŀ�ȣ����ݿ�ȼ���ͬ��ͷSH�Ŀ�ȣ�����ȡ��Ҫ���κ�ֵ

module Sici_PCS_OH_Ins  #(parameter FW=32)
      (
       ////ȫ���ź�
       input             Rs         ,  ////�첽��λ������Ч
       input             Ck         ,  ////ʱ��
       input             CE         ,  ////ʱ��ʹ�ܣ�����Ч
       ////phy��ӿ�                
                                         
       output  [FW-1:0]  PCS_Dat_o  ,  
                             
       ////ϵͳ��ӿ�                
       input [7:0]       PCS_MFI    ,  ////��ָ֡ʾ�ź�
       input             PCS_SH_Res ,  ////�͸����ź�PCS_MFI ����
       input  [FW-2-1:0] PCS_Dat_i  ,
       ////Զ�˲���澯�ӿ�,�ѽ��շ���ı��ظ澯���뵽���ͷ����Ա�Զ��ܹ�֪����·���
       input             Rx_Lo_Syn  ,  
       input             Rx_Lo_MF   ,  
       input             Rx_Err_CRC ,  
       ////����ӿ�
       input             Err_SH     ,  ////SH����ָʾ������Ч
       input             Err_MF     ,  ////��֡����ָʾ������Ч
       input             Err_CRC       ////CRC����ָʾ������Ч
       
      );

////�ѽ��շ���ĸ澯�ź�ͬ��������ʱ��
reg [1:0] Lo_Syn_Rx_R ;  
reg [1:0] Lo_MF_Rx_R  ;  
reg [1:0] Err_CRC_Rx_R;  

always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    Lo_Syn_Rx_R  <= 0;  
    Lo_MF_Rx_R   <= 0;  
    Err_CRC_Rx_R <= 0;  
  end
  else if(CE)
  begin
    Lo_Syn_Rx_R  <= {Lo_Syn_Rx_R[0] ,Rx_Lo_Syn };  
    Lo_MF_Rx_R   <= {Lo_MF_Rx_R[0]  ,Rx_Lo_MF  };  
    Err_CRC_Rx_R <= {Err_CRC_Rx_R[0],Rx_Err_CRC};  
  end
end
    
////��֡ʧ���ź�չ������һ����֡���ڣ��Ա��ܱ�������
reg  Lo_Syn_Rx_Ext;
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    Lo_Syn_Rx_Ext <= 0;
 end
  else if(CE)
  begin
    if(Lo_Syn_Rx_R[1] == 1)
	  Lo_Syn_Rx_Ext <= 1;
	else if(PCS_MFI == 24)  
	  Lo_Syn_Rx_Ext <= 0;
  end
end

////PCS_SHͬ��ͷ��������븴֡�ź���ʱ1��      
reg  [1:0]      PCS_SH     ;
reg  [15:0]     CRC_Shift  ;  
reg  [FW-2-1:0] PCS_Dat_i_R;    
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    PCS_SH      <= 2'b10 ;
	PCS_Dat_i_R <= 0     ;  
  end
  else if(CE)
  begin
    PCS_Dat_i_R <= PCS_Dat_i;
	
    if(PCS_MFI == 0)
	  PCS_SH    <= (Err_MF  == 0)? 2'b10: 2'b01;
    else if(PCS_MFI<23)  
      PCS_SH    <= (Err_MF  == 0)? 2'b01: 2'b10;
    else if(PCS_MFI==23) 
      PCS_SH    <= (Err_MF  == 0)? 2'b10: 2'b01;
    else if(PCS_MFI==24) 
      PCS_SH    <= {~Lo_Syn_Rx_Ext,Lo_Syn_Rx_Ext}    ;
    else if(PCS_MFI==25) 
      PCS_SH    <= {~Lo_MF_Rx_R[1],Lo_MF_Rx_R[1]}    ;
    else if(PCS_MFI==26) 
      PCS_SH    <= {~Err_CRC_Rx_R[1],Err_CRC_Rx_R[1]};
    else if(PCS_MFI < 240)
      PCS_SH    <= (Err_SH  == 0)?{~PCS_SH_Res, PCS_SH_Res }:{PCS_SH_Res, PCS_SH_Res };
	else 
      PCS_SH    <= (Err_SH  == 0)?{~CRC_Shift[15] , CRC_Shift[15]}:{CRC_Shift[15] , CRC_Shift[15]};
    
  end
end
assign  PCS_Dat_o  = {PCS_SH,PCS_Dat_i_R};


////��Ϊ֡��������ڸ�֡�Ѿ���ʱ1�ģ����ԣ�����CRC����ĸ�ָ֡ʾҲ��ʱ1�ģ������ݶ���
reg  MFI_Ind;
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    MFI_Ind     <= 0 ;
  end
  else if(CE)
  begin
    MFI_Ind <= (PCS_MFI == 8'h00)?1:0;
  end
end

////���㸴֡��CRC
wire   [FW+16-1:0]   Dat_i ;
wire   [16-1:0]      CRC_C ; 
reg    [16-1:0]      CRC_R ; 

CRC_Core #(.DW(FW), .CW(16), .CP(17'h11021)) CC
      (
       .Dat_i (Dat_i ),
       .CRC_o (CRC_C )
      );
////CRC�������ݶ���ʽ����ǰ��CRC����ʽ���ϱ��δ��������ݶ���ʽ
assign Dat_i = (MFI_Ind == 1)? {16'h0000,{(FW){1'b0}}}^{PCS_Dat_o ,{16{1'b0}}}:{{CRC_R,{(FW){1'b0}}}}^{PCS_Dat_o ,{16{1'b0}}};      

always @(posedge(Rs),posedge(Ck ))
begin
  if(Rs)
  begin
    CRC_R      <= 0 ;
    CRC_Shift <= 0 ;
  end
  else if(CE )
  begin
    CRC_R      <= CRC_C;
    
    if(MFI_Ind == 1)
      CRC_Shift <= (Err_CRC  == 0)?CRC_R:~CRC_R;
    else if(PCS_MFI >= 240)  
      CRC_Shift <= {CRC_Shift[14:0], 1'b0};
      
  end
end


endmodule
