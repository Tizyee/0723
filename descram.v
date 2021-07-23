`timescale 1ns/1ps

//DW     ����������������λ��>=1
//DI     ������Ĵ�����ʼֵ
//POLY   �������ʽ            
//PP     �������ʽ�Ķ�������ߴ��ݵ�ֵ 
//       ��POLY��ΪPRBS����ʽ��������ģ�������ΪPRBS���������ȷ�Ļ�Dat_o���ȫΪ0 

module Descram #(parameter DW = 62, DI = 58'h3ffffffffffffff,PP = 58, POLY  = 59'h400008000000001)
      (
       //ȫ���ź�
       input            Rs     ,  //�첽��λ������Ч
       input            Ck     ,  //ʱ��
       input            CE     ,  //ʱ��ʹ�ܣ�����Ч
       
       input            Des_En ,  //������ʹ�ܣ�����Ч
       input  [DW-1:0]  Dat_i  ,  //����������������
       output [DW-1:0]  Dat_o     //��������������
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