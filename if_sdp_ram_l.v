

`timescale 1ns/10ps
`include   "Macro.v"

//用分布式ram实现简单双口推断ram模块
// AW   地址位宽
// DW   数据位宽


// OR   输出寄存器使能：TRUE,FALSE
// IF   ram初始化文件，如果没有初始化文件，参数例化为""。
//      文件一串16进制表示一个地址的值，每个值用空格隔开。
//      可以用@hhhhhh(h表示16进制)来指示后面的数据的开始地址。
//      

module if_sdp_ram_l #(parameter AW=4,DW=8,OR="TRUE",IF="if_sdp_ram_l.ini")
                   (
                    input           A_Ck,
                    input           A_CE,
                    input           A_WE,
                    input  [AW-1:0] A_Ad,
                    input  [DW-1:0] A_WD,
                    
                    input           B_Ck,
                    input           B_CE,
                    input  [AW-1:0] B_Ad,
                    output [DW-1:0] B_RD
                   )/*synthesis syn_hier = "hard" */;




`ifdef INTEL   
//synplify综合Intel。 

reg [DW-1:0]     Mem_Array [0:(2**AW)-1]  /* synthesis syn_ramstyle = "MLAB" */;/*parameters:  MLAB; select_ram.*/
reg [DW-1:0]     odr_int = 0;
reg [DW-1:0]     odr_e   = 0;

integer i=0;
initial
begin
  if(IF !=0) 
    $readmemh(IF, Mem_Array);
  else                       //只对仿真有用
  begin 
    for (i=0;i<2**AW;i=i+1)
      Mem_Array[i]<=0;
  end    
end    
    
always @(posedge(A_Ck))
begin
  if(A_CE == 1)
    if (A_WE ==1) 
      Mem_Array[A_Ad] <= A_WD; 
end

generate
begin
  if(OR == "NONE")
  begin
    always @(*)
    begin
      odr_int <=  Mem_Array[B_Ad] ;
      odr_e   <=  odr_int         ;
    end 
  end
  else if(OR == "FALSE")
  begin
    always @(posedge(B_Ck))
    begin
      if (B_CE ==1)
      begin
        odr_int <=  Mem_Array[B_Ad];
      end
    end 

    always @(*)
    begin
      odr_e <=  odr_int;
    end 
         
  end
  else
  begin
    always @(posedge(B_Ck))
    begin
      if (B_CE == 1)
      begin
        odr_int <=  Mem_Array[B_Ad];
        odr_e   <=  odr_int        ;
      end
    end  
  end
  
end
endgenerate

  
assign  B_RD=odr_e;        
  
`else  //对Xilinx  Lattice适用

reg [DW-1:0] Mem_Array [0:(2**AW)-1]  /* synthesis syn_ramstyle = "select_ram" */;/*parameters:  MLAB; select_ram.*/
reg [DW-1:0] odr_e      = 0;
reg [DW-1:0] odr_xil    = 0;

//对Lattice 分布式RAM不能初始化，外部调用时IF = ""。
integer i;
initial
begin
  if(IF !=0) 
    $readmemh(IF, Mem_Array);
  else                       //只对仿真有用
  begin 
    for (i=0;i<2**AW;i=i+1)
      Mem_Array[i]<=0;
  end    
end    

always @(posedge(A_Ck))
begin
  if(A_CE == 1)
    if (A_WE ==1) 
      Mem_Array[A_Ad] <= A_WD; 
end

generate
begin
  if(OR == "NONE")
  begin
    always @(*)
    begin
      odr_xil <=  Mem_Array[B_Ad] ;
      odr_e   <=  odr_xil         ;
    end 
  end
  else if(OR == "FALSE")
  begin
    always @(posedge(B_Ck))
    begin
      if (B_CE == 1)
      begin
        odr_xil <=  Mem_Array[B_Ad];
      end
    end 

    always @(*)
    begin
      odr_e <=  odr_xil;
    end 
         
  end
  else
  begin
    always @(posedge(B_Ck))
    begin
      if (B_CE == 1)
      begin
        odr_xil <=  Mem_Array[B_Ad];
        odr_e   <=  odr_xil        ;
      end
    end  
  end
  
end
endgenerate
 
assign  B_RD=odr_e;        
     
`endif

endmodule