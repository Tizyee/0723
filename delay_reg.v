`timescale 1ns/1ps

////////�üĴ���ʵ���ź���ʱģ��
////SW  �ź�λ�����ڵ���1
////DN  ��ʱ�����������ڵ���1

module Delay_reg #(parameter SW = 8,DN =6)
       (
        input          Ck , 
        input          CE ,
        input [SW-1:0] DI ,
        output[SW-1:0] DO  
       );

reg  [SW-1:0] SR [DN-1:0]  /* synthesis syn_srlstyle = "registers" */; 

always @(posedge(Ck))
begin
  if(CE)
  begin
    if(DN==1)
      SR[0]      <= {DI}; 
    else
      SR[DN-1:0] <= {SR[DN-2:0],DI}; 
  end  
end
assign DO = SR[DN-1]; 

endmodule


