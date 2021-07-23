`timescale 1ns/1ps

////FW   PCS幁的宽度，数据宽度加上同步头SH的宽度，可以取需要的任何值

module Sici_PCS_OH_Ins  #(parameter FW=32)
      (
       ////全局信号
       input             Rs         ,  ////异步复位，高有效
       input             Ck         ,  ////时钟
       input             CE         ,  ////时钟使能，高有效
       ////phy侧接口                
                                         
       output  [FW-1:0]  PCS_Dat_o  ,  
                             
       ////系统侧接口                
       input [7:0]       PCS_MFI    ,  ////复帧指示信号
       input             PCS_SH_Res ,  ////和复幁信号PCS_MFI 对齐
       input  [FW-2-1:0] PCS_Dat_i  ,
       ////远端插入告警接口,把接收方向的本地告警插入到发送方向，以便对端能够知道线路情况
       input             Rx_Lo_Syn  ,  
       input             Rx_Lo_MF   ,  
       input             Rx_Err_CRC ,  
       ////管理接口
       input             Err_SH     ,  ////SH错误指示，高有效
       input             Err_MF     ,  ////复帧错误指示，高有效
       input             Err_CRC       ////CRC错误指示，高有效
       
      );

////把接收方向的告警信号同步到发送时钟
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
    
////把帧失步信号展宽到至少一个复帧周期，以便能被采样到
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

////PCS_SH同步头，相对输入复帧信号延时1拍      
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


////因为帧数据相对于复帧已经延时1拍，所以，用于CRC计算的复帧指示也延时1拍，和数据对齐
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

////计算复帧的CRC
wire   [FW+16-1:0]   Dat_i ;
wire   [16-1:0]      CRC_C ; 
reg    [16-1:0]      CRC_R ; 

CRC_Core #(.DW(FW), .CW(16), .CP(17'h11021)) CC
      (
       .Dat_i (Dat_i ),
       .CRC_o (CRC_C )
      );
////CRC输入数据多项式等于前次CRC多项式加上本次待计算数据多项式
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
