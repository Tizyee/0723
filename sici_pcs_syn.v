`timescale 1ns/1ps

////FW   PCS帧的宽度，数据宽度加上同步头SH的宽度，可以取需要的任何值
////SWT  slip等待时间，Bit_Slip 有效发出后，要等Phy_Dat的位序关系发生变化所需时间。
////ENT  进入同步时间，当连续搜到ENT个同步头后，进入同步状态
////EXT  退出同步时间，当连续搜到EXT个非同步头后，退出同步状态，EXT应该小于ENT
////     为了节约逻辑资源，建议把上面的几个时间参数设为2的n次方

module Sici_PCS_Syn  #(parameter FW=96, SWT = 64,ENT = 32,EXT = 4)
      (
       //全局输入信号
       input             Rs      ,  //异步复位，高有效
       input             Ck      ,  //时钟
       input             CE      ,  //时钟使能
       //PHY侧接口       
       output            Bit_Slp ,  //比特滑动请求信号，高有效，当有效时，要求串并转换模块输出的并行数据滑动一比特，便于帧同步
       input  [FW-1:0]   Phy_Dat ,  //phy侧输入数据
       
       //到下一级模块
       output            Syn_OK  ,  //同步成功信号，高有效
       output  [FW-1:0]  PCS_Dat ,  //PCS输出数据
       //管理接口
       input             Re_Syn  ,  //重新同步请求，上升沿有效
       output            Err_SH  ,  //同步头错误指示，高有效
       output            Lo_Syn     //同步丢失信号，高有效
       
      );
      
////计算一个整数的二进制比特数
function integer BitSize(input integer N);
integer ci;
begin
  ci = 0;
  while((2**ci) <= N)
  begin
    ci = ci+1;
  end
  if(N<2)
    BitSize = 1; 
  else
    BitSize = ci; 
end  
endfunction

localparam SCW = (BitSize(SWT) >BitSize(ENT))?BitSize(SWT):BitSize(ENT);

////把复位信号同步到Clk ，以便可靠复位。      
reg  [1:0] Rs_D;      
always @(posedge(Ck ))
begin
  if(CE )
    Rs_D <= {Rs_D[0],Rs};
end      

////检测Re_Syn 上升沿      
reg  [2:0] Re_Syn_D ; 
reg        Re_Syn_PE;    
always @(posedge(Ck ))
begin
  if(CE )
  begin
    Re_Syn_D  <= {Re_Syn_D[1:0],Re_Syn}              ;
    Re_Syn_PE <= ~Re_Syn_D[2] & Re_Syn_D[1] | Rs_D[1]; 
  end  
end      

////帧搜索状态机      
localparam  HUNT = 0, SLIP =1, SYNC = 2, SH_ERR = 3;
reg  [1:0]     Syn_FSM_NS ;
reg  [1:0]     Syn_FSM_LS ;
reg  [SCW-1:0] FSM_Sta_Cnt;
always @(posedge(Re_Syn_PE),posedge(Ck ))
begin
  if(Re_Syn_PE)
  begin
    Syn_FSM_LS  <= HUNT;
    FSM_Sta_Cnt <= 0   ;
  end
  else if(CE )
  begin
    Syn_FSM_LS <= Syn_FSM_NS;
    
    if(Syn_FSM_LS != Syn_FSM_NS)
      FSM_Sta_Cnt <= 0;
    else
      FSM_Sta_Cnt <= FSM_Sta_Cnt + 1'b1;
  end
end

wire   SH_Ava;
assign SH_Ava =(Phy_Dat [FW-1] != Phy_Dat [FW-2])?1:0;
 
always @(*)
begin
  case(Syn_FSM_LS)
  HUNT:
    if(SH_Ava == 0)                  ////没有搜到帧头，进入bitslip状态
      Syn_FSM_NS <= SLIP;
    else if(FSM_Sta_Cnt > (ENT-1))   ////连续搜到ENT+1次帧头，进入同步状态
      Syn_FSM_NS <= SYNC;
    else
      Syn_FSM_NS <= HUNT;
  SLIP:
    if(FSM_Sta_Cnt > (SWT-1))        ////等待bitslip生效时间后，再次进入HUNT
      Syn_FSM_NS <= HUNT; 
    else
      Syn_FSM_NS <= SLIP;
  SYNC:
    if(SH_Ava == 0)                  ////搜到一个错误的帧头，进入帧头错误状态
      Syn_FSM_NS <= SH_ERR;
    else
      Syn_FSM_NS <= SYNC  ;
  SH_ERR:
    if(SH_Ava == 0)
    begin
      if(FSM_Sta_Cnt > (EXT-1))      ////连续搜到EXT+1个错误帧头，进入bitslip状态
        Syn_FSM_NS <= SLIP;
      else
        Syn_FSM_NS <= SH_ERR ;
    end  
    else
      Syn_FSM_NS <= SYNC;
  default:
    Syn_FSM_NS <= HUNT;
  endcase
end      

////刚进入SLIP状态时，产生一次比特滑动信号
reg  Bit_Slp_R;
always @(posedge(Re_Syn_PE),posedge(Ck ))
begin
  if(Re_Syn_PE)
    Bit_Slp_R <= 0;
  else if(CE )
  begin
    if(Syn_FSM_LS == SLIP && FSM_Sta_Cnt==0)
      Bit_Slp_R <= 1;
    else
      Bit_Slp_R <= 0;
  end
end
assign  Bit_Slp = Bit_Slp_R;


////输出同步状态和数据到后续处理模块
reg           Syn_OK_R ;
reg [FW-1:0]  PCS_Dat_R;
always @(posedge(Ck ))
begin
  if(CE )
  begin
    PCS_Dat_R <= Phy_Dat;
    if(Syn_FSM_LS == SYNC || Syn_FSM_LS==SH_ERR)
      Syn_OK_R <= 1;
    else
      Syn_OK_R <= 0;
  end
end
assign  Syn_OK  = Syn_OK_R ;
assign  PCS_Dat = PCS_Dat_R;

////管理接口告警输出
reg  Err_SH_R ;
reg  Lo_Syn_R ;
always @(posedge(Ck ))
begin
  if(CE )
  begin
    if(Syn_FSM_LS == SYNC || Syn_FSM_LS == SH_ERR)
      Lo_Syn_R <= 0;
    else
      Lo_Syn_R <= 1;
    
    if(Syn_FSM_LS == SH_ERR)
      Err_SH_R <= 1;
    else
      Err_SH_R <= 0;
  end
end
assign  Err_SH = Err_SH_R;
assign  Lo_Syn = Lo_Syn_R;

endmodule