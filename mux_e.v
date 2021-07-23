`timescale 1ns/1ps

////////带使能信号的数据选择器
////GN  选择器组位宽
////GW  选择器组数量

module Mux_e 
       #(parameter GN = 2,GW = 4)       
      (
       input  [GN*GW-1:0] Da_In  ,  //数据输入，按如下排列{Da_In[GW-1],Da_In[GW-1],Da_In[GW-1],...,Da_In[GW-1]}
       input  [GN-1:0]    Da_En  ,  //数据使能，高有效，任何时刻只能有一个信号有效
       output [GW-1:0]    Da_Ou     //选择后的数据输出
      );
////////输入数据按位重新排列,该排列不消耗逻辑资源
reg  [GN-1:0] Da_In_RA[GW-1:0];
genvar gv0,gv1;
generate
begin
  for(gv0 = 0; gv0 < GW; gv0=gv0+1)
  begin:gv_00 
    for(gv1 = 0; gv1 < GN; gv1=gv1+1)
    begin:gv_01
      always @(*)
        Da_In_RA[gv0][gv1] <= Da_In[GW*gv1+gv0];
    end 
  end
end
endgenerate
////////输入数据和各自使能信号逻辑与，再把所有数据作逻辑或
reg  [GW-1:0] Da_Ou_T;
generate
begin
  for(gv0 = 0;gv0 < GW; gv0=gv0+1)
  begin:gv_0
    always@(*)
      Da_Ou_T[gv0]   <= |(Da_In_RA[gv0]& Da_En) ;
  end  
end
endgenerate
assign Da_Ou = Da_Ou_T; 
      
endmodule