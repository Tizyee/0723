`timescale 1ns/1ps

////DW    ��������������λ��>=1
////SI    ����Ĵ�����ʼֵ,��Ҫ��Ϊ0�����򣬵�����ȫ0ʱ�����Ҳȫ0��ʧȥ��������
////POLY  �������ʽ            
////PP    �������ʽ�Ķ�������ߴ��ݵ�ֵ   
////      ��Dat_i����Ϊ0��POLY��ΪPRBS����ʽ��������ģ�������ΪPRBS������  
   
module Scram #(parameter DW = 62, SI = 58'h3ffffffffffffff,PP = 58, POLY  = 59'h400008000000001)
      (
       //ȫ���ź�
       input                         Rs        ,  //�첽��λ������Ч
       input                         Ck        ,  //ʱ��
       input                         CE        ,  //ʱ��ʹ�ܣ�����Ч
       
       input                         Scr_En    ,  //����ʹ�ܣ�����Ч
       input  [DW-1:0]               Dat_i     ,  //��������������
       output [DW-1:0]               Dat_o        //������������
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


//����Ĵ���������λ�Ĵ�������Լ��Դ
assign Dat_o = Scr_Shift_LS[DW-1:0];



endmodule