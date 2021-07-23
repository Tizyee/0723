

`timescale 1ns/10ps
`include   "Macro.v"

//�÷ֲ�ʽramʵ�ּ�˫���ƶ�ramģ��
// AW   ��ַλ��
// DW   ����λ��


// OR   ����Ĵ���ʹ�ܣ�TRUE,FALSE
// IF   ram��ʼ���ļ������û�г�ʼ���ļ�����������Ϊ""��
//      �ļ�һ��16���Ʊ�ʾһ����ַ��ֵ��ÿ��ֵ�ÿո������
//      ������@hhhhhh(h��ʾ16����)��ָʾ��������ݵĿ�ʼ��ַ��
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
//synplify�ۺ�Intel�� 

reg [DW-1:0]     Mem_Array [0:(2**AW)-1]  /* synthesis syn_ramstyle = "MLAB" */;/*parameters:  MLAB; select_ram.*/
reg [DW-1:0]     odr_int = 0;
reg [DW-1:0]     odr_e   = 0;

integer i=0;
initial
begin
  if(IF !=0) 
    $readmemh(IF, Mem_Array);
  else                       //ֻ�Է�������
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
  
`else  //��Xilinx  Lattice����

reg [DW-1:0] Mem_Array [0:(2**AW)-1]  /* synthesis syn_ramstyle = "select_ram" */;/*parameters:  MLAB; select_ram.*/
reg [DW-1:0] odr_e      = 0;
reg [DW-1:0] odr_xil    = 0;

//��Lattice �ֲ�ʽRAM���ܳ�ʼ�����ⲿ����ʱIF = ""��
integer i;
initial
begin
  if(IF !=0) 
    $readmemh(IF, Mem_Array);
  else                       //ֻ�Է�������
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