`timescale 100ps/100ps
module  ctrl_top
#(parameter  CNT_WAIT_W = 2,WAIT_MAX = 0,TEST = 4) 
(
input       din     ,//输入的串行数据
input       din_ck  ,//输入的串行数据的时钟
input      fclk     ,//311
input      pclk     ,//311/8
input      rst      ,//rst
input      calib    ,//ides16调整输出16位并行顺序，高有效
input      recal    ,//延时控制模块的重置

output[7:0]q        ,//din转换的值，输出给sici_pcs
output     cal       //延时控制模块成功标志，高有效
);

wire       sdtap;
wire       value;
wire       setn;
wire [7:0] q_0;


//////////////*例化延时控制模块*///////////
ides16_delay_ctrl #(.CNT_WAIT_W(CNT_WAIT_W),.MAX(WAIT_MAX),.TEST(TEST))
 ides16_delay_ctrl_uut
(
  .q        (  q_0  )   , //din_ck1转16后的输出是q0
  .pclk     ( pclk  )   ,
  .recal    ( recal )   , //重置模块
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