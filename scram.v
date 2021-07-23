`timescale 1ns/1ps

////DW    待扰码输入数据位宽，>=1
////SI    扰码寄存器初始值,不要设为0，否则，当输入全0时，输出也全0，失去扰码意义
////POLY  扰码多项式            
////PP    扰码多项式的二进制最高次幂的值   
////      把Dat_i设置为0，POLY改为PRBS多项式，该扰码模块可以作为PRBS产生器  
   
module Scram #(parameter DW = 62, SI = 58'h3ffffffffffffff,PP = 58, POLY  = 59'h400008000000001)
      (
       //全局信号
       input                         Rs        ,  //异步复位，高有效
       input                         Ck        ,  //时钟
       input                         CE        ,  //时钟使能，高有效
       
       input                         Scr_En    ,  //扰码使能，高有效
       input  [DW-1:0]               Dat_i     ,  //待扰码输入数据
       output [DW-1:0]               Dat_o        //扰码后输出数据
      );
      
localparam RW = (DW >= PP)?DW:PP;
      
reg  [RW-1:0] Scr_Shift_LS;
wire [RW-1:0] Scr_Shift_NS;

always @(posedge(Rs), posedge(Ck))
begin
  if(Rs == 1)
    Scr_Shift_LS <= SI;
  else if(CE)
  begin
    if(Scr_En)
      Scr_Shift_LS <= Scr_Shift_NS;
  end  
end

wire [DW-1+PP-1:0] Temp ;
wire [DW-1:0]      Dat_T;

generate
begin
  if(DW <2 )
    assign Temp = Scr_Shift_LS[PP-1:0]; 
  else
    assign Temp = {Scr_Shift_LS[PP-1:0],Dat_T[DW-1:1]}; 
end
endgenerate

genvar gv;
generate
begin
  for(gv=0;gv<DW;gv=gv+1)
  begin:GL
    assign Dat_T[DW-1-gv] = (^(Temp[DW-1+PP-1-gv:DW-1-gv]&POLY[PP:1]))^Dat_i[DW-1-gv];
  end
end
endgenerate

generate
begin
  if(DW >= PP)
    assign Scr_Shift_NS = Dat_T; 
  else
    assign Scr_Shift_NS = {Scr_Shift_LS[RW-DW-1:0],Dat_T}; 
end
endgenerate


//输出寄存器共用移位寄存器，节约资源
assign Dat_o = Scr_Shift_LS[DW-1:0];



endmodule