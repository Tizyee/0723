`timescale 1ns/1ps

//DW     待解扰码输入数据位宽，>=1
//DI     解扰码寄存器初始值
//POLY   扰码多项式            
//PP     扰码多项式的二进制最高次幂的值 
//       把POLY改为PRBS多项式，该扰码模块可以作为PRBS检测器，正确的话Dat_o输出全为0 

module Descram #(parameter DW = 62, DI = 58'h3ffffffffffffff,PP = 58, POLY  = 59'h400008000000001)
      (
       //全局信号
       input            Rs     ,  //异步复位，高有效
       input            Ck     ,  //时钟
       input            CE     ,  //时钟使能，高有效
       
       input            Des_En ,  //解扰码使能，高有效
       input  [DW-1:0]  Dat_i  ,  //待解扰码输入数据
       output [DW-1:0]  Dat_o     //解扰码后输出数据
      );
      
      
reg  [PP-1:0] Des_Shift_LS;
wire [PP-1:0] Des_Shift_NS;

always @(posedge(Rs), posedge(Ck))
begin
  if(Rs == 1)
    Des_Shift_LS <= DI;
  else if(CE)
  begin
    if(Des_En)
      Des_Shift_LS <= Des_Shift_NS;
  end  
end

generate
begin
  if(DW >= PP)
    assign Des_Shift_NS = Dat_i[PP-1:0]; 
  else
    assign Des_Shift_NS = {Des_Shift_LS[PP-DW-1:0],Dat_i}; 
end
endgenerate



wire [DW-1+PP-1:0] Temp;
generate
begin
  if(DW <2 )
    assign Temp = Des_Shift_LS[PP-1:0]; 
  else
    assign Temp = {Des_Shift_LS[PP-1:0],Dat_i[DW-1:1]}; 
end
endgenerate


wire [DW-1:0] Dat_T   ;
reg  [DW-1:0] Dat_o_R ;
genvar gv;
generate
begin
  for(gv=0;gv<DW;gv=gv+1)
  begin:GL
    assign Dat_T[DW-1-gv] = (^(Temp[DW-1+PP-1-gv:DW-1-gv]&POLY[PP:1]))^Dat_i[DW-1-gv];

    always @(posedge(Rs), posedge(Ck))
    begin
      if(Rs == 1)
        Dat_o_R[DW-1-gv] <= 0;
      else if(CE)
      begin
        if(Des_En)
          Dat_o_R[DW-1-gv] <= Dat_T[DW-1-gv];
      end
    end
  end
end
endgenerate
assign Dat_o = Dat_o_R;



endmodule