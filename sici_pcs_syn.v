`timescale 1ns/1ps

////FW   PCS֡�Ŀ�ȣ����ݿ�ȼ���ͬ��ͷSH�Ŀ�ȣ�����ȡ��Ҫ���κ�ֵ
////SWT  slip�ȴ�ʱ�䣬Bit_Slip ��Ч������Ҫ��Phy_Dat��λ���ϵ�����仯����ʱ�䡣
////ENT  ����ͬ��ʱ�䣬�������ѵ�ENT��ͬ��ͷ�󣬽���ͬ��״̬
////EXT  �˳�ͬ��ʱ�䣬�������ѵ�EXT����ͬ��ͷ���˳�ͬ��״̬��EXTӦ��С��ENT
////     Ϊ�˽�Լ�߼���Դ�����������ļ���ʱ�������Ϊ2��n�η�

module Sici_PCS_Syn  #(parameter FW=96, SWT = 64,ENT = 32,EXT = 4)
      (
       //ȫ�������ź�
       input             Rs      ,  //�첽��λ������Ч
       input             Ck      ,  //ʱ��
       input             CE      ,  //ʱ��ʹ��
       //PHY��ӿ�       
       output            Bit_Slp ,  //���ػ��������źţ�����Ч������Чʱ��Ҫ�󴮲�ת��ģ������Ĳ������ݻ���һ���أ�����֡ͬ��
       input  [FW-1:0]   Phy_Dat ,  //phy����������
       
       //����һ��ģ��
       output            Syn_OK  ,  //ͬ���ɹ��źţ�����Ч
       output  [FW-1:0]  PCS_Dat ,  //PCS�������
       //����ӿ�
       input             Re_Syn  ,  //����ͬ��������������Ч
       output            Err_SH  ,  //ͬ��ͷ����ָʾ������Ч
       output            Lo_Syn     //ͬ����ʧ�źţ�����Ч
       
      );
      
////����һ�������Ķ����Ʊ�����
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

////�Ѹ�λ�ź�ͬ����Clk ���Ա�ɿ���λ��      
reg  [1:0] Rs_D;      
always @(posedge(Ck ))
begin
  if(CE )
    Rs_D <= {Rs_D[0],Rs};
end      

////���Re_Syn ������      
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

////֡����״̬��      
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
    if(SH_Ava == 0)                  ////û���ѵ�֡ͷ������bitslip״̬
      Syn_FSM_NS <= SLIP;
    else if(FSM_Sta_Cnt > (ENT-1))   ////�����ѵ�ENT+1��֡ͷ������ͬ��״̬
      Syn_FSM_NS <= SYNC;
    else
      Syn_FSM_NS <= HUNT;
  SLIP:
    if(FSM_Sta_Cnt > (SWT-1))        ////�ȴ�bitslip��Чʱ����ٴν���HUNT
      Syn_FSM_NS <= HUNT; 
    else
      Syn_FSM_NS <= SLIP;
  SYNC:
    if(SH_Ava == 0)                  ////�ѵ�һ�������֡ͷ������֡ͷ����״̬
      Syn_FSM_NS <= SH_ERR;
    else
      Syn_FSM_NS <= SYNC  ;
  SH_ERR:
    if(SH_Ava == 0)
    begin
      if(FSM_Sta_Cnt > (EXT-1))      ////�����ѵ�EXT+1������֡ͷ������bitslip״̬
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

////�ս���SLIP״̬ʱ������һ�α��ػ����ź�
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


////���ͬ��״̬�����ݵ���������ģ��
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

////����ӿڸ澯���
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