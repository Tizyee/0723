`timescale 1ns/1ps
////////grace接口的读后清零寄存器
////DW grace接口的数据宽度
////RW 寄存器宽度，它应小于等于DW
////IR 输入寄存器使能
////OR 读数据输出寄存使能，1 使能，0 不使能

module Grace_rc #(parameter DW = 32,RW = 32, IR = 0, OR = 0)
      (
       input           Grace_Rs ,
       input           Grace_Ck ,
       input           Grace_CS ,
       input           Grace_WR ,
	   
	   output          Grace_Re ,
       output          Grace_Ac ,
       output [DW-1:0] Grace_RD ,
       
       input  [RW-1:0] Reg_In   
      );

assign Grace_Re = 1;

reg  Grace_CS_R;
always @(posedge(Grace_Rs),posedge(Grace_Ck))
begin
  if(Grace_Rs)
    Grace_CS_R <= 0;
  else 
  begin
    Grace_CS_R <= Grace_CS;
  end  
end

/////////////////////////////输入信号同步处理 ///////////////////////////////
reg  [RW-1:0] Reg_In_R0 =0;
reg  [RW-1:0] Reg_In_R1 =0;
generate
begin
  if(IR)
    always @(posedge(Grace_Rs),posedge(Grace_Ck))
    begin
      if(Grace_Rs)
      begin
        Reg_In_R0 <= 0;
        Reg_In_R1 <= 0;
      end  
      else 
      begin
        Reg_In_R0 <= Reg_In   ;
        Reg_In_R1 <= Reg_In_R0;
      end 
    end
  else
    always @(*)
    begin
      Reg_In_R0 <= Reg_In   ;
      Reg_In_R1 <= Reg_In_R0;
    end
end
endgenerate
/////////////////////////////信号锁存///////////////////////////////
reg  [RW-1:0] Reg_In_Latch = 0;
reg  [RW-1:0] Read_Latch   = 0;

genvar gv;
generate
begin
  for(gv =0; gv< RW; gv=gv+1)
  begin:GV_RW
    always @(posedge(Grace_Rs),posedge(Grace_Ck))
    begin
      if(Grace_Rs)
      begin
        Reg_In_Latch[gv] <= 0;
        Read_Latch[gv]   <= 0;
      end  
      else 
      begin
        if(Reg_In_R1[gv] == 1)
          Reg_In_Latch[gv] <= 1;
        else if(~Grace_CS_R&Grace_CS)
          Reg_In_Latch[gv] <= 0;
        
        if(~Grace_CS_R&Grace_CS) 
          Read_Latch[gv]   <= Reg_In_Latch[gv];
        
      end  
    end
  end
end
endgenerate

////////////////////////////////////读处理//////////////////////////////////////////////
reg  [DW-1:0]  Grace_RD_R =0;

generate
begin
  if(OR == 1)
  begin
    always @(posedge(Grace_Ck))
      Grace_RD_R[RW-1:0] <= Read_Latch[RW-1:0];
  end      
  else
    always @(*)
      Grace_RD_R <= Read_Latch;
  
end
endgenerate 
assign  Grace_RD = Grace_RD_R;

////////////////////////////////////产生Ack//////////////////////////////////////////////
reg    Grace_Ac_R0 =0;
reg    Grace_Ac_R1 =0;

generate
begin
  if(OR == 1)
  begin
    always @(posedge(Grace_Ck))
	begin
      Grace_Ac_R0 <= Grace_CS   ;
	  Grace_Ac_R1 <= Grace_Ac_R0;
    end
  end      
  else
  begin
    always @(posedge(Grace_Ck))
      Grace_Ac_R0 <= Grace_CS;
        
    always @(*)
      Grace_Ac_R1 <= Grace_Ac_R0;
        
  end
end
endgenerate 
assign  Grace_Ac = Grace_Ac_R1 ;
     
      
endmodule