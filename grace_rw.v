`timescale 1ns/1ps

////////grace接口的读写寄存器
////DW grace接口的数据宽度
////RW 寄存器宽度，它应小于等于DW
////RI 寄存器初始值
////WW 写使能位宽
////OR 读数据输出寄存使能，1 使能（延时2拍），0 不使能

module Grace_rw #(parameter  DW = 32,RW = 32,RI = 'h00000000,WW = 1,OR = 1) 
      (
       input              Grace_Rs , 
       input              Grace_Ck , 
	   input              Grace_CE ,
       input              Grace_CS , 
       input  [WW-1:0]    Grace_WR , 
       output             Grace_Ac , 
       output             Grace_Re , 
       input  [DW-1:0]    Grace_WD , 
       output [DW-1:0]    Grace_RD , 
       ////寄存器输出接口
       output [RW-1:0]    Reg_Out  , 
       input  [RW-1:0]    Reg_In    
      );

assign Grace_Re = 1;

//////////////////////////////////////////写处理///////////////////////////////////
reg  [DW-1:0] Reg_Out_R = 0;

genvar gv;
generate
begin
  for(gv=0;gv<WW;gv=gv+1)
  begin:GV_WW
    always@(posedge(Grace_Rs),posedge(Grace_Ck))
    begin
      if(Grace_Rs)
        Reg_Out_R[(gv+1)*DW/WW-1:gv*DW/WW] <= RI[(gv+1)*DW/WW-1:gv*DW/WW];
      else if(Grace_CE)
      begin
        if(Grace_CS == 1 && Grace_WR[gv] == 1 )
          Reg_Out_R[(gv+1)*DW/WW-1:gv*DW/WW] <= Grace_WD[(gv+1)*DW/WW-1:gv*DW/WW];
      end
    end
  end
end  
endgenerate
assign  Reg_Out = Reg_Out_R[RW-1:0];

//////////////////////////////////////////读处理///////////////////////////////////
reg  [DW-1:0] Grace_RD_Temp0=0;
reg  [DW-1:0] Grace_RD_Temp1=0;

generate
begin
  if(OR == 1)
  begin
    always@(posedge(Grace_Ck))
	begin
	  if(Grace_CE)
	  begin
        Grace_RD_Temp0 <= Reg_In        ;
	    Grace_RD_Temp1 <= Grace_RD_Temp0;
      end
    end	  
  end
  else
  begin
    always@(*)
	begin
      Grace_RD_Temp0 <= Reg_In        ;
	  Grace_RD_Temp1 <= Grace_RD_Temp0;
    end  
  end
end  
endgenerate
assign  Grace_RD = Grace_RD_Temp1;
//////////////////////////////////////////产生ACK///////////////////////////////////
reg  Grace_Ac_R0;
reg  Grace_Ac_R1;
generate
begin
  if(OR == 1)
  begin
    always @(posedge(Grace_Ck))
    begin
	  if(Grace_CE)
	  begin
        Grace_Ac_R0 <= Grace_CS   ;
        Grace_Ac_R1 <= Grace_Ac_R0;
	  end 
    end
  end
  else
  begin
    always @(*)
    begin
      Grace_Ac_R0 <= Grace_CS   ;
      Grace_Ac_R1 <= Grace_Ac_R0;
    end
  end  
end
endgenerate
assign  Grace_Ac = Grace_Ac_R1;
     
      
endmodule