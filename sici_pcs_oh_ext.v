`timescale 1ns/1ps

////FW   PCS���Ŀ�ȣ����ݿ�ȼ���ͬ��ͷSH�Ŀ�ȣ�����ȡ��Ҫ���κ�ֵ

module Sici_PCS_OH_Ext  #(parameter FW=32)
      (
       ////ȫ���ź�
       input             Rs         ,  ////�첽��λ������Ч
       input             Ck         ,  ////ʱ��
       input             CE         ,  ////ʱ��ʹ��
       ////��֡ͬ����ӿ�                
                                          
       input  [FW-1:0]   PCS_Dat_i  ,  ////֡�����Ĳ�����������
       input             Syn_OK     ,  ////ͬ���ɹ��źţ�����Ч
                             
       ////ϵͳ��ӿ�                
       output [7:0]      PCS_MFI    ,  ////��ָ֡ʾ�ź�
       output            PCS_SH_Res ,  ////SH�������ܣ��û������Լ�����
       output [FW-2-1:0] PCS_Dat_o  ,  ////֡�����Ĳ����������
	   ////����ӿ�				 
       output            Err_MF     ,  ////���ظ�֡����ָʾ������Ч
       output            Lo_MF      ,  ////���ظ�֡ʧ��ָʾ������Ч
       output            Err_CRC    ,  ////����CRC����ָʾ������Ч
	   
       output            R_Lo_Syn   ,  ////Զ��֡ʧ��ָʾ������Ч
       output            R_Lo_MF    ,  ////Զ�˸�֡ʧ��ָʾ������Ч
       output            R_Err_CRC     ////Զ��CRC����ָʾ������Ч
	   
       
      );

////ͬ��ͷ��λ�Ĵ���
reg [23:0] SH_Shift;
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    SH_Shift <= 0 ;
  end
  else if(CE )
  begin
    SH_Shift <= {SH_Shift[22:0],PCS_Dat_i[FW-2]};
  end
end

wire   MFS_Ava;
assign MFS_Ava = (SH_Shift == 24'h7FFFFE)?1:0;  //��֡��־����0���22��1��24'h7FFFFE

reg [7:0]  MF_Cnt      ;
reg [2:0]  MF_Lck_Cnt  ;
reg [2:0]  MF_Unlck_Cnt;
reg        Lo_MF_R     ;
reg        Err_MF_R    ;

always @(posedge(Rs),posedge(Ck ))
begin
  if(Rs)
  begin
    MF_Cnt       <= 0 ;
    MF_Lck_Cnt   <= 0 ;
    MF_Unlck_Cnt <= 0 ;
    Lo_MF_R      <= 1 ;
    Err_MF_R     <= 0 ;
  end
  else if(CE )
  begin
    if(MFS_Ava == 1 && Lo_MF_R == 1)   //��֡û������ǰ�����ָ�֡��־������ͬ����֡������
      MF_Cnt <= 25;
    else                               //����������ǰ��ʱ���ϵ������
      MF_Cnt <= MF_Cnt + 1'b1; 
      
    if(Lo_MF_R  == 0 || (MFS_Ava == 1 && MF_Cnt != 8'h18) || (MFS_Ava != 1 && MF_Cnt == 8'h18))
      MF_Lck_Cnt <= 0; 
    else if(MFS_Ava == 1 && MF_Cnt == 8'h18) 
      MF_Lck_Cnt <= MF_Lck_Cnt + 1'b1; 
      
    if(Lo_MF_R == 1 || (MFS_Ava == 1 && MF_Cnt == 8'h18))
      MF_Unlck_Cnt <= 0; 
    else if((MFS_Ava != 1 && MF_Cnt == 8'h18)) 
      MF_Unlck_Cnt <= MF_Unlck_Cnt + 1'b1; 
      
    if(Lo_MF_R ==1 && MF_Lck_Cnt ==7 && Syn_OK  == 1)  
      Lo_MF_R <= 0;
    else if(Lo_MF_R ==0 && MF_Unlck_Cnt ==7)
      Lo_MF_R <= 1;
      
    if(MFS_Ava != 1 && MF_Cnt == 8'h18)
      Err_MF_R <= 1;
    else
      Err_MF_R <= 0;
       
      
  end
end

      
assign  PCS_MFI     =  MF_Cnt             ;      
assign  PCS_SH_Res  =  PCS_Dat_i[FW-2]    ;
assign  PCS_Dat_o   =  PCS_Dat_i[FW-2-1:0];      

assign  Lo_MF       =  Lo_MF_R            ;
assign  Err_MF      =  Err_MF_R           ;


reg  MFI_Ind;
always @(posedge(Rs),posedge(Ck ))
begin
  if(Rs)
  begin
    MFI_Ind <= 0 ;
  end
  else if(CE )
  begin
    MFI_Ind <= (MF_Cnt == 8'hFF)?1:0;
  end
end


wire   [FW+16-1:0]   Dat_Inn;
wire   [16-1:0]      CRC_C  ; 
reg    [16-1:0]      CRC_R  ; 

CRC_Core #(.DW(FW), .CW(16), .CP(17'h11021)) CC
          (
           .Dat_i (Dat_Inn),
           .CRC_o (CRC_C  )
          );
		  
////CRC�������ݶ���ʽ����ǰ��CRC����ʽ���ϱ��δ��������ݶ���ʽ
assign Dat_Inn = (MFI_Ind == 1)? {16'h0000,{(FW){1'b0}}}^{PCS_Dat_i ,{16{1'b0}}}:{{CRC_R,{(FW){1'b0}}}}^{PCS_Dat_i ,{16{1'b0}}};      

reg   [16-1:0] CRC_L    ; 
reg            Err_CRC_R;
always @(posedge(Rs),posedge(Ck ))
begin
  if(Rs)
  begin
    CRC_R     <= 0 ;
    CRC_L     <= 0 ;
    Err_CRC_R <= 0 ;
  end
  else if(CE )
  begin
    CRC_R <= CRC_C;
    CRC_L <= (MFI_Ind == 1)?CRC_R:CRC_L;
    
    if(Lo_MF == 1)
      Err_CRC_R <= 0;
    else if(MF_Cnt == 0)
    begin
       if(CRC_L == SH_Shift[15:0])
         Err_CRC_R <= 0;
       else
         Err_CRC_R <= 1;
    end
      
  end
end
assign Err_CRC  = Err_CRC_R;


////��ȡԶ�˸澯
reg   R_Lo_Syn_R ;  ////Զ��֡ʧ��ָʾ������Ч
reg   R_Lo_MF_R  ;  ////Զ�˸�֡ʧ��ָʾ������Ч
reg   R_Err_CRC_R;  ////Զ��CRC����ָʾ������Ч
always @(posedge(Rs),posedge(Ck ))
begin
  if(Rs)
  begin
    R_Lo_Syn_R  <= 0 ;
    R_Lo_MF_R   <= 0 ;
    R_Err_CRC_R <= 0 ;
  end
  else if(CE )
  begin
    if(MF_Cnt == 24)
	  R_Lo_Syn_R  <= PCS_Dat_i[FW-2];

    if(MF_Cnt == 25)
	  R_Lo_MF_R   <= PCS_Dat_i[FW-2];
	  
    if(MF_Cnt == 26)
	  R_Err_CRC_R <= PCS_Dat_i[FW-2];
	  
  end
end
assign R_Lo_Syn  = R_Lo_Syn_R ;  
assign R_Lo_MF   = R_Lo_MF_R  ;  
assign R_Err_CRC = R_Err_CRC_R;  


endmodule