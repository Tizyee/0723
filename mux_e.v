`timescale 1ns/1ps

////////��ʹ���źŵ�����ѡ����
////GN  ѡ������λ��
////GW  ѡ����������

module Mux_e 
       #(parameter GN = 2,GW = 4)       
      (
       input  [GN*GW-1:0] Da_In  ,  //�������룬����������{Da_In[GW-1],Da_In[GW-1],Da_In[GW-1],...,Da_In[GW-1]}
       input  [GN-1:0]    Da_En  ,  //����ʹ�ܣ�����Ч���κ�ʱ��ֻ����һ���ź���Ч
       output [GW-1:0]    Da_Ou     //ѡ�����������
      );
////////�������ݰ�λ��������,�����в������߼���Դ
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
////////�������ݺ͸���ʹ���ź��߼��룬�ٰ������������߼���
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