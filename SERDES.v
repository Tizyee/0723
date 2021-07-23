/////////////////////SERDES16
//CNT_WAIT_W   delay模块每次延时等待时间的位宽
//WAIT_MAX     delay模块每次延时等待时间
//TEST         delay模块中ok状态验证q等待周期次数

`timescale 100ps/1ps
module SERDES 
#(parameter  CNT_WAIT_W = 2,WAIT_MAX = 0,TEST = 4) 
(    
  input          Rs        ,//总复位，高复位
  input          fclk      ,//311
  input          pclk      ,//311/4
  input          din       ,//输入的串行数据
  input          din_ck    ,//输入的串行数据的时钟
  input          calib     ,//ides16调整输出16位并行顺序，高有效，连接sici的Rx_Bit_Slp
  input          recal     ,//延时控制模块的重置,1有效
  input  [7:0]   RX_Phy_Dat,//sici_pcs输入
  
  output [7:0]   TX_Phy_Dat,//输出给sici_pcs
  output         cal       ,//delay模块中延时成功标志，1有效
  output         Q         ,//sici输入的16位并行转成1位串行输出
  output         Ck_622     //输出的时钟622MHz和数据对齐的
);
/* reg  calib1;
always @(posedge pclk or posedge RS)
begin
  if(Rs)
  begin
    calib1 <= 0;
  end
  else
  begin
    calib1 <= calib;
  end
end */

ctrl_top #(.CNT_WAIT_W(CNT_WAIT_W),.WAIT_MAX(WAIT_MAX),.TEST(TEST))
ides16_dly_ctrl
(
  .din     (din) ,   //输入的串行数据622.04MHz
  .din_ck  (din_ck) ,//输入的串行数据的时钟622.04MHz
  .fclk    (fclk) ,//311
  .pclk    (pclk) ,//311/8
  .rst     (Rs) ,//rst
  .calib   (calib) ,//ides16调整输出16位并行顺序，高有效
  .recal   (recal) ,//延时控制模块的重置

  .q       (TX_Phy_Dat)  ,//din转换的值，输出给sici_pcs的PHY侧
  .cal     (cal)   //延时控制模块成功标志，高有效
);

/////////////////////例化高云原语8位并转1位串行数据
Gowin_DDR_OSER8 TX_622M_Dat
(
  .din    (RX_Phy_Dat), //input [7:0] din  
  .fclk   (fclk      ), //input fclk
  .pclk   (pclk      ), //input pclk
  .reset  (Rs        ), //input reset
  .q      (Q         )  //output [0:0] q
);

/////////////////////例化高云原语8位并转1位串行Ck_622MHz
Gowin_DDR_OSER8 TX_622M_Ck
(
  .din    (8'h55   ), //input [7:0] din  8'b0101 0101
  .fclk   (fclk    ), //input fclk
  .pclk   (pclk    ), //input pclk
  .reset  (Rs      ), //input reset
  .q      (Ck_622  )  //output [0:0] q
);

endmodule 