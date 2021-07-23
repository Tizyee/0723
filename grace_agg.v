`timescale 1ns/1ps

////////grace接口汇聚功能模块
////DW  grace接口的数据宽度
////AW  地址宽度
////IL  中断电平指示，1高电平，0低电平
////DN  下游片选数量
////IR  下游接口输入寄存使能,1 使能，0 不使能
////OR  下游接口数据输出寄存使能，1 使能，0 不使能
////OT  超时时钟周期数量设置
////WN  写使能的数量
////MOD 下游片选译码模式，0：设定地址范围模式，1：顺序地址译码模式
////以下几个参数在MOD为0时才有用，MOD为1，忽略它们
////LT MOD = 0时，每个下游片选地址低门限
////UT MOD = 0时，每个下游片选地址高门限
////OP MOD = 0时，每个下游门限处理方法设置，0：在范围内片选有效(包含门限)，1：在范围外片选有效(不包含门限)

module Grace_Agg 
       #(parameter AW = 4,DW = 32,IL=1,DN = 4,IR = 1,OR = 1,OT = 500, WN = 1, MOD = 0,  
         reg [DN*AW-1:0] LT = 16'b0000_0100_1000_1100,    
         reg [DN*AW-1:0] UT = 16'b0011_0111_1011_1111,    
         reg [DN-1:0]    OP = 4'b0_0_0_0)                 
      (
       //上游Grace接口
       input              UP_Grace_Rs ,  
       input              UP_Grace_Ck ,  
       input              UP_Grace_CE ,  
       input              UP_Grace_CS ,  
       input  [WN-1:0]    UP_Grace_WR ,  
       output             UP_Grace_Ac , 
       output             UP_Grace_Re , 
       input  [AW-1:0]    UP_Grace_Ad ,  
       input  [DW-1:0]    UP_Grace_WD ,  
       output [DW-1:0]    UP_Grace_RD ,  
       output             UP_Grace_IR ,  
       output             UP_Grace_OT ,
       //下游Grace接口    
       output             DN_Grace_Rs ,
       output             DN_Grace_Ck ,
       output             DN_Grace_CE ,
       output [DN-1:0]    DN_Grace_CS ,
       output [WN-1:0]    DN_Grace_WR ,
	   
       input  [DN-1:0]    DN_Grace_Ac ,
       input  [DN-1:0]    DN_Grace_Re ,
       
	   output [AW-1:0]    DN_Grace_Ad ,
       output [DW-1:0]    DN_Grace_WD ,
       
	   input  [DN*DW-1:0] DN_Grace_RD ,
       input  [DN-1:0]    DN_Grace_IR  
      );

///计算一个整数的二进制比特数
function integer BitSize(input integer N);
integer ci;
begin
  ci = 0;
  while((2**ci) <= N)
  begin
    ci = ci+1;
  end
  if(N<2)
    BitSize = 1; 
  else
    BitSize = ci; 
end  
endfunction

localparam OCW = BitSize(OT);
      
///////////////////////////////////////从上游到下游的信号处理//////////////////////////////////////////////      
assign  DN_Grace_Rs = UP_Grace_Rs;
assign  DN_Grace_Ck = UP_Grace_Ck;
assign  DN_Grace_CE = UP_Grace_CE;


reg [DN-1:0] DN_Grace_CS_T = 0;
reg [WN-1:0] DN_Grace_WR_T = 0;
reg [AW-1:0] DN_Grace_Ad_T = 0;
reg [DW-1:0] DN_Grace_WD_T = 0;

genvar  gv;
generate
begin
  if(OR == 1)
  begin
  
    for(gv = 0;gv < DN; gv=gv+1)
    begin:CS_GL
      always@(posedge(UP_Grace_Ck))
      begin
        if(UP_Grace_CE)
        begin
		  if(MOD == 0)
		  begin
            if(OP[gv] == 0)
              DN_Grace_CS_T[gv] <= (UP_Grace_Ad >= LT[gv*AW+AW-1:gv*AW] && UP_Grace_Ad <= UT[gv*AW+AW-1:gv*AW])?UP_Grace_CS:0;
            else
              DN_Grace_CS_T[gv] <= (UP_Grace_Ad <  LT[gv*AW+AW-1:gv*AW] || UP_Grace_Ad >  UT[gv*AW+AW-1:gv*AW])?UP_Grace_CS:0;
          end
		  else
		    DN_Grace_CS_T[gv] <= (UP_Grace_Ad == gv && UP_Grace_CS)?1:0;
		end  
      end
    end 
    
    always@(posedge(UP_Grace_Rs),posedge(UP_Grace_Ck))
    begin
      if(UP_Grace_Rs)
      begin
        DN_Grace_WR_T <= 0;
        DN_Grace_Ad_T <= 0;
        DN_Grace_WD_T <= 0;
      end  
      else if(UP_Grace_CE)
      begin
        DN_Grace_WR_T <= UP_Grace_WR;
        DN_Grace_Ad_T <= UP_Grace_Ad;
        DN_Grace_WD_T <= UP_Grace_WD;
      end  
    end
    

     
  end
  else
  begin
  
    for(gv = 0;gv < DN; gv=gv+1)
    begin:CS_GL
      always@(*)
      begin
	    if(MOD == 0)
          if(OP[gv] == 0)
            DN_Grace_CS_T[gv] <= (UP_Grace_Ad >= LT[gv*AW+AW-1:gv*AW] && UP_Grace_Ad <= UT[gv*AW+AW-1:gv*AW])?UP_Grace_CS:0;
          else
            DN_Grace_CS_T[gv] <= (UP_Grace_Ad <  LT[gv*AW+AW-1:gv*AW] || UP_Grace_Ad >  UT[gv*AW+AW-1:gv*AW])?UP_Grace_CS:0;
        else
		  DN_Grace_CS_T[gv] <= (UP_Grace_Ad == gv && UP_Grace_CS)?1:0;
      end
    end 
    
    always@(*)
    begin
      DN_Grace_WR_T <= UP_Grace_WR;
      DN_Grace_Ad_T <= UP_Grace_Ad;
      DN_Grace_WD_T <= UP_Grace_WD;
    end
  
  end
end
endgenerate
assign   DN_Grace_CS = DN_Grace_CS_T;
assign   DN_Grace_WR = DN_Grace_WR_T;
assign   DN_Grace_Ad = DN_Grace_Ad_T;
assign   DN_Grace_WD = DN_Grace_WD_T;

///////////////////////////////////////超时计数器及指示标志产生/////////////////////////////////////////////////////////
reg  [OCW-1:0] OT_Cnt;
reg            OT_Ind;
always@(posedge(UP_Grace_Rs),posedge(UP_Grace_Ck))
begin
  if(UP_Grace_Rs)
  begin
    OT_Cnt <= 0 ;
    OT_Ind <= 0 ;
  end
  else if(UP_Grace_CE)
  begin
    if(UP_Grace_CS == 1 && UP_Grace_Ac == 0)
      OT_Cnt    <= OT_Cnt + 1'b1;
    else
      OT_Cnt    <= 0;   
   
    OT_Ind <= (OT_Cnt >= OT && UP_Grace_CS == 1 && UP_Grace_Ac == 0)?1:0;     
  end
end

assign UP_Grace_OT = OT_Ind;

///////////////////////////////////////从下游到上游的信号处理 /////////////////////////////////////////////////      
reg          UP_Grace_Ac_T ;
reg          UP_Grace_Re_T ;
reg [DW-1:0] UP_Grace_RD_T ;
reg          UP_Grace_IR_T ;
wire[DW-1:0] DN_Grace_RD_T ;

Mux_e #(.GN(DN),.GW(DW)) RD_MUX
(.Da_In(DN_Grace_RD),.Da_En(DN_Grace_Ac),.Da_Ou(DN_Grace_RD_T));   
     
generate
begin
  if(IR == 1)
  begin
  
    always@(posedge(UP_Grace_Rs),posedge(UP_Grace_Ck))
    begin
      if(UP_Grace_Rs)
      begin
        UP_Grace_Ac_T <= 0            ;
        UP_Grace_IR_T <= (IL==0) ? 1:0;
        UP_Grace_RD_T <= 0            ;
		UP_Grace_Re_T <= 0            ;
      end
      else if(UP_Grace_CE)
      begin
        UP_Grace_Ac_T <= (|(DN_Grace_Ac))|OT_Ind                 ;
        UP_Grace_IR_T <= (IL==0)   ? &DN_Grace_IR:|DN_Grace_IR   ;
        UP_Grace_RD_T <= (OT_Ind == 1)?32'hCA04CA04:DN_Grace_RD_T;
		UP_Grace_Re_T <= |(DN_Grace_Re)                          ;
      end
    end
    
  end
  else
  begin

    always@(*)
    begin 
      UP_Grace_Ac_T <= (|(DN_Grace_Ac))|OT_Ind                 ;
      UP_Grace_IR_T <= (IL==0)   ? &DN_Grace_IR:|DN_Grace_IR   ;
      UP_Grace_RD_T <= (OT_Ind == 1)?32'hCA04CA04:DN_Grace_RD_T;
	  UP_Grace_Re_T <= |(DN_Grace_Re)                          ;
    end
    
  end
end
endgenerate
assign   UP_Grace_Ac = UP_Grace_Ac_T ;
assign   UP_Grace_RD = UP_Grace_RD_T ;
assign   UP_Grace_IR = UP_Grace_IR_T ;
assign   UP_Grace_Re = UP_Grace_Re_T ;
           
            
      
endmodule