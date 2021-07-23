
////DW   : NCO��ĸ��λ��
////NW   : NCO���ӵ�λ��
////NCO_D: NCO�ķ�ĸ�������Ƶʱ�ӵ�Ƶ������,Ϊ�˽�Լ��Դ/���ʱ�����ܣ�ͨ����NCO_D���ó�2**DW
////MO   : ���ģʽ��0��ʱ��ģʽ��ռ�ձȾ���Ϊ50%��1��ʱ��ʹ��ģʽ���ߵ�ƽֻ��һ��ʱ�����ڣ���ʹ��)

module AnyFFD_E #(parameter DW = 32, NW = 24, NCO_D = 2**DW)
   (
    input          Rs       ,  //��λ�źţ��߸�λ
    input          HF_CE    ,  //��Ƶʱ�ӵ�ʹ���źţ�����Ч
    input          HF_Ck    ,  //��Ƶʱ�� 
    
    input [NW-1:0] NCO_N    ,  //NCO�ķ��ӣ������Ƶʱ�ӵ�Ƶ������
    
    output[DW-1:0] Acc_O    ,  //�ۼ������
    output         LF_Ck_O  ,  //��Ƶʱ���ź����
    output         LF_CE_O     //��Ƶʱ��ʹ���ź����
	
	
   );


////�ۼӼ�������      
reg [DW-1:0] Acc_Cnt;

always @(posedge(Rs),posedge(HF_Ck))
begin
  if(Rs)
    Acc_Cnt <= 0;
  else if(HF_CE)
  begin
    if((Acc_Cnt + NCO_N)>= NCO_D)  
      Acc_Cnt <= Acc_Cnt + NCO_N - NCO_D;
    else
      Acc_Cnt <= Acc_Cnt + NCO_N;
  end
end
assign Acc_O = Acc_Cnt;

////��Ƶʱ�����
reg  LF_Ck_O_R;
always @(posedge(Rs),posedge(HF_Ck))
begin
  if(Rs)
    LF_Ck_O_R <= 0;
  else if(HF_CE)
  begin
    if(Acc_Cnt >= NCO_D/2)
      LF_Ck_O_R <= 1;
    else
      LF_Ck_O_R <= 0;
  end
end
assign LF_Ck_O = LF_Ck_O_R;

////��Ƶʱ��ʹ�����
reg  LF_Ck_O_R1;	
reg  LF_CE_O_R ;	
always @(posedge(Rs),posedge(HF_Ck))
begin
  if(Rs)
  begin
    LF_Ck_O_R1<= 0;
    LF_CE_O_R <= 0;
  end	
  else if(HF_CE)
  begin
    LF_Ck_O_R1 <= LF_Ck_O_R;
	LF_CE_O_R  <= ~LF_Ck_O_R1 & LF_Ck_O_R;
  end
end
assign LF_CE_O = LF_CE_O_R;                                                        


  
endmodule