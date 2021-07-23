
////DW   : NCO分母的位宽
////NW   : NCO分子的位宽
////NCO_D: NCO的分母，代表高频时钟的频率因子,为了节约资源/提高时钟性能，通常把NCO_D设置成2**DW
////MO   : 输出模式，0：时钟模式，占空比尽力为50%，1：时钟使能模式，高电平只有一个时钟周期（带使能)

module AnyFFD_E #(parameter DW = 32, NW = 24, NCO_D = 2**DW)
   (
    input          Rs       ,  //复位信号，高复位
    input          HF_CE    ,  //高频时钟的使能信号，高有效
    input          HF_Ck    ,  //高频时钟 
    
    input [NW-1:0] NCO_N    ,  //NCO的分子，代表低频时钟的频率因子
    
    output[DW-1:0] Acc_O    ,  //累加器输出
    output         LF_Ck_O  ,  //低频时钟信号输出
    output         LF_CE_O     //低频时钟使能信号输出
	
	
   );


////累加计数器。      
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

////低频时钟输出
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

////低频时钟使能输出
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