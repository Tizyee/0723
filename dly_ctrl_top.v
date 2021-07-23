`timescale 100ps/100ps
module  ctrl_top
#(parameter  CNT_WAIT_W = 2,WAIT_MAX = 0,TEST = 4) 
(
input       din     ,//����Ĵ�������
input       din_ck  ,//����Ĵ������ݵ�ʱ��
input      fclk     ,//311
input      pclk     ,//311/8
input      rst      ,//rst
input      calib    ,//ides16�������16λ����˳�򣬸���Ч
input      recal    ,//��ʱ����ģ�������

output[7:0]q        ,//dinת����ֵ�������sici_pcs
output     cal       //��ʱ����ģ��ɹ���־������Ч
);

wire       sdtap;
wire       value;
wire       setn;
wire [7:0] q_0;


//////////////*������ʱ����ģ��*///////////
ides16_delay_ctrl #(.CNT_WAIT_W(CNT_WAIT_W),.MAX(WAIT_MAX),.TEST(TEST))
 ides16_delay_ctrl_uut
(
  .q        (  q_0  )   , //din_ck1ת16��������q0
  .pclk     ( pclk  )   ,
  .recal    ( recal )   , //����ģ��
  .rst      ( rst   )   ,
  
  .sdtap    ( sdtap )   ,
  .value    ( value )   ,
  .cal      ( cal   )   ,
  .setn     ( setn  )    
);
//////////////////
Gowin_DDR_dly RX_UP_Dat(
  .din      (din  )   , //input [0:0] din
  .fclk     (fclk )   , //input fclk
  .pclk     (pclk )   , //input pclk
  .reset    (rst  )   , //input reset
  .calib    (calib)   , //input calib
  .sdtap    (sdtap)   , //input sdtap
  .value    (value)   , //input value
  .setn     (setn )   , //input setn
  .q        (q)         //output [7:0] q
);
///////////////
Gowin_DDR_dly RX_UP_Ck(
  .din      (din_ck)   , //input [0:0] din
  .fclk     (fclk  )   , //input fclk
  .pclk     (pclk  )   , //input pclk
  .reset    (rst   )   , //input reset
  .calib    (calib )   , //input calib
  .sdtap    (sdtap )   , //input sdtap
  .value    (value )   , //input value
  .setn     (setn  )   , //input setn
  .q        (q_0   )         //q0
);
endmodule