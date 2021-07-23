`timescale 1ns/1ps

////////grace�ӿڵ�ֻ���Ĵ���
////DW grace�ӿڵ����ݿ��
////RW �Ĵ�����ȣ���ӦС�ڵ���DW
////IR ����Ĵ�ʹ�ܣ�1 ʹ�ܣ�0 ��ʹ��
////OR ����������Ĵ�ʹ�ܣ�1 ʹ�ܣ�0 ��ʹ��

module Grace_ro #(parameter DW = 32,RW = 32, IR = 1, OR = 0)
      (
       input              Grace_Ck , 
	   input              Grace_CE ,
       input              Grace_CS , 
       input              Grace_WR , 
	   output             Grace_Re ,
       output             Grace_Ac , 
       output [DW-1:0]    Grace_RD , 
									
       input              Reg_Vld  , 
       input  [RW-1:0]    Reg_In    
      );


/////////////////////////////ֻ���Ĵ����źŵ����봦��///////////////////////////////
reg  [RW-1:0] Reg_In_R0  =0;
reg  [RW-1:0] Reg_In_R1  =0;
reg           Reg_Vld_R0 =0;
reg           Reg_Vld_R1 =0;

generate
begin
  if(IR)
    always @(posedge(Grace_Ck))
    begin
	  if(Grace_CE)
	  begin
        Reg_In_R0  <= Reg_In    ;
        Reg_In_R1  <= Reg_In_R0 ;
        Reg_Vld_R0 <= Reg_Vld   ;
        Reg_Vld_R1 <= Reg_Vld_R0;
	  end
    end
  else 
    always @(*)
    begin
      Reg_In_R0  <= Reg_In    ;
      Reg_In_R1  <= Reg_In_R0 ;
      Reg_Vld_R0 <= Reg_Vld   ;
      Reg_Vld_R1 <= Reg_Vld_R0;
    end
end
endgenerate

     
////////////////////////////////////������//////////////////////////////////////////////
reg  [DW-1:0]   Grace_RD_R =0;
generate
begin
  if(OR == 1)
  begin
    always @(posedge(Grace_Ck))
	  if(Grace_CE)
        Grace_RD_R[RW-1:0] <= Reg_In_R1[RW-1:0];
  end      
  else
    always @(*)
      Grace_RD_R[RW-1:0] <= Reg_In_R1[RW-1:0];
  
end
endgenerate 
assign  Grace_RD = Grace_RD_R;

////////////////////////////////////����Ack�ź�//////////////////////////////////////////////
reg    Grace_Ac_R =0;
generate
begin
  if(OR == 1)
  begin
    always @(posedge(Grace_Ck))
	  if(Grace_CE)
        Grace_Ac_R <= Grace_CS&Reg_Vld_R1;
  end      
  else
    always @(*)
      Grace_Ac_R <= Grace_CS&Reg_Vld_R1;
end
endgenerate 
assign  Grace_Ac = Grace_Ac_R;
assign  Grace_Re = Grace_Ac_R;

endmodule