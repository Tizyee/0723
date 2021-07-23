`timescale 1ns/1ps

//DW ����λ��>2
//MODE         ����ģʽ0: ����ѭ�������ܵ�ǰͨ�������Ƿ���Ч�������л�����һͨ��
//                     1: ��ͨ��ѭ������ǰͨ��������Ч������л�����һͨ��

module Adaptive_Mux #(parameter DW = 3,MODE = 0)
      (
       input  [DW-1:0]  Cond_In  ,  //active high
       input  [DW-1:0]  Sel_Last ,  //active high ǰ��ѡ����
       output [DW-1:0]  Sel_Next    //active high ����ѡ��������ѡ�еĶ�ӦΪ1������λ��Ϊ0
      );
      


      
wire [DW-1:0] Cond_In_Shift   [0:DW-1];
wire [DW-1:0] Sel_Last_Shift  [0:DW-1];
wire [DW-3:0] Cond_In_Is_Zero [0:DW-1];

reg  [DW-1:0] Sel_Next_R              ;            

genvar        gv1,gv2                 ;

generate
begin
  for(gv1=0;gv1<DW;gv1=gv1+1)
  begin:gv_1
  
    if(gv1 ==0) //����0λ
    begin
      assign Cond_In_Shift[gv1]  = Cond_In ;
      assign Sel_Last_Shift[gv1] = Sel_Last;
    end  
    else        //����gv1λ
    begin
      assign Cond_In_Shift[gv1]  = {Cond_In[gv1-1:0],Cond_In[DW-1:gv1]}  ;
      assign Sel_Last_Shift[gv1] = {Sel_Last[gv1-1:0],Sel_Last[DW-1:gv1]};
    end  
      
    for(gv2=1;gv2<(DW-1);gv2=gv2+1)
    begin:gv_2
      assign Cond_In_Is_Zero[gv1][gv2-1] = ~(|Cond_In_Shift[gv1][DW-1:gv2+1])&Sel_Last_Shift[gv1][gv2];
    end
    
    if(gv1==0)
      always @(*)
      begin
        if(Cond_In[gv1] == 1)
        begin
          if(Cond_In == (2**gv1))
            Sel_Next_R[gv1] = 1;
          else if(Sel_Last[gv1] == 1)  
            Sel_Next_R[gv1] = (MODE == 0)? 0:1;
          else if(Sel_Last == 0 ) 
            Sel_Next_R[gv1] = 1;
          else if(Sel_Last[DW-1]==1)
          begin 
            if(MODE == 0)
              Sel_Next_R[gv1] = 1;
            else
              Sel_Next_R[gv1] = (Cond_In[DW-1] == 0)?1:0;
          end  
          else if((|Cond_In_Is_Zero[gv1]) ==1)
          begin
            if(MODE == 0)
              Sel_Next_R[gv1] = 1;
            else
              Sel_Next_R[gv1] = ((Cond_In&Sel_Last)==0)?1:0;
          end  
          else
            Sel_Next_R[gv1] = 0;
        end    
        else
          Sel_Next_R[gv1] = 0;
      end 
    else
      always @(*)
      begin
        if(Cond_In[gv1] == 1)
        begin
          if(Cond_In == (2**gv1))
            Sel_Next_R[gv1] = 1;
          else if(Sel_Last[gv1] == 1)  
            Sel_Next_R[gv1] = (MODE == 0)? 0 :1;
          else if(Sel_Last == 0 && Cond_In[gv1-1:0] == 0) 
            Sel_Next_R[gv1] = 1;
          else if(Sel_Last[gv1-1]==1) 
          begin
            if(MODE == 0)
              Sel_Next_R[gv1] = 1;
            else
              Sel_Next_R[gv1] = (Cond_In[gv1-1] == 0)?1:0;
          end  
          else if((|Cond_In_Is_Zero[gv1]) ==1)
          begin
            if(MODE == 0)
              Sel_Next_R[gv1] = 1;
            else
              Sel_Next_R[gv1] = ((Cond_In&Sel_Last)==0)?1:0;
          end  
          else
            Sel_Next_R[gv1] = 0;
        end    
        else
          Sel_Next_R[gv1] = 0;
      end 
    
  end
end
endgenerate

assign  Sel_Next = Sel_Next_R;























   
endmodule