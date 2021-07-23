module RX_E1_Mux
#( parameter     D_W     = 42 )  //数据位宽，可修改为8复用
(
  input                    Ck      	   ,  //77.76    
  input                    Rs     	   ,     
  input  		[D_W-1:0]  E1_In_Dat   ,
  input  		[D_W-1:0]  E1_In_Ck    ,
  
  output   reg   [3:0]     E1_MFI      ,  //延时一拍对齐数据的MFI
  output         [5:0]     Dv_Dat
);

reg  [3:0]  MFI;
always @(posedge Ck or posedge Rs)
begin
  if(Rs == 1'b1) 
    MFI <= 4'b0;
  else
	MFI <= MFI + 1'b1;
end

//打两拍数据的时钟  
reg  [D_W-1:0]  E1_In_Ck_1,E1_In_Ck_2;
always @(posedge Ck or posedge Rs)
begin
  if(Rs == 1'b1)
  begin
    E1_In_Ck_1 <= 0;
    E1_In_Ck_2 <= 0;
  end
  else
  begin
    E1_In_Ck_1 <= E1_In_Ck	   ;
    E1_In_Ck_2 <= E1_In_Ck_1   ;
  end        
end

wire   	[D_W-1:0] Dv_flag ; 
assign Dv_flag = ~E1_In_Ck_2 & E1_In_Ck_1; //有效标志信号

//打两拍数据
reg  [D_W-1:0]  Dat_0,Dat_1;
always @(posedge Ck or posedge Rs)
begin
  if(Rs == 1'b1)
  begin
    Dat_0 <= 0;
    Dat_1   <= 0;
  end
  else
  begin
    Dat_0 <= E1_In_Dat	 ;
    Dat_1 <= Dat_0       ;
  end        
end

localparam  GN = (D_W%16==0)?(D_W/16):(D_W/16)+1'b1;//把输入分成n组

reg   [16-1:0]   Dat[0:GN-1];//二维8位*GN组的数组，位宽*深度可理解为横向*纵向
genvar  j;
generate for(j=0;j<GN*16;j=j+1) ////第14，15帧不存，值为0
begin: Dat_0_41  
    if(j>=D_W)        //多余的数据位为0
      always @(*)
	  begin
 	    if(Rs == 1'b1)
          Dat[(j%14)%3][14+(j%14)/3] <= 1'b0;//14,15帧赋值为0
	  end
	else 
      always @(posedge Ck or posedge Rs)
      begin
        if(Rs == 1'b1)
          Dat[j/14][j%14] <= 1'b0 ;
	    else
	      Dat[j/14][j%14] <= Dat_1[j] ;
      end
end
endgenerate

reg   [16-1:0]   Dv[0:GN-1];//二维8位*GN组的数组，位宽*深度可理解为横向*纵向
generate for(j=0;j<GN*16;j=j+1)
begin: Dv_0_41     
  if(j>=D_W)              //多余的位赋0
    always @(*) 
	begin
      if(Rs == 1'b1)
        Dv[(j%14)%3][14+(j%14)/3] <= 1'b0;//14,15帧赋值为0	
    end	  
  else
    always @(posedge Ck or posedge Rs)
    begin
      if(Rs == 1'b1)
        Dv[j/14][j%14] <= 1'b0;
      else if(Dv_flag[j]==1)  //有效标志信号出现1，Dv拉高保持到发出
        Dv[j/14][j%14]  <= 1'b1;
	  else if((j%14)==MFI) //把42路分成3个14选一，42路中除14余数等于复帧的，则被选中
	    Dv[j/14][j%14]  <= 1'b0 ;  
    end 
end
endgenerate

reg     [GN-1:0]    E1_Dv,E1_Dat;//
generate for(j=0;j<GN;j=j+1)//生成组数个
begin: Dv_Dat_Gn     
  always @(posedge Ck or posedge Rs)
  begin
    if(Rs == 1'b1)
      E1_Dv[j] <= 1'b0;
    else 
      E1_Dv[j] <= Dv[j][MFI];//根据帧数抽取数组中的值
  end 
  
    always @(posedge Ck or posedge Rs) //时序逻辑则延时一拍，(时序逻辑相当于重置组合逻辑处理的延时，输出的信号一般是在时钟下输出)
  begin
    if(Rs == 1'b1)
      E1_Dat[j] <= 1'b0;
    else 
      E1_Dat[j] <= Dat[j][MFI];    //输出延时了一拍，那么复帧输出时也应该延时一拍对齐
  end 
end
endgenerate

always @(posedge Ck or posedge Rs)
begin
  if(Rs == 1'b1) 
    E1_MFI <= 4'b0;
  else
	E1_MFI <= MFI;//ck下打一拍输出
end
//assign Dv_Dat_reg = {E1_Dat[5],E1_Dv[5],E1_Dat[4],E1_Dv[4],E1_Dat[3],E1_Dv[3],E1_Dat[2],E1_Dv[2],E1_Dat[1],E1_Dv[1],E1_Dat[0],E1_Dv[0]};

generate for(j=0;j<3;j=j+1)//
begin: Dv_Dat_MFI
  if(j<GN)
    assign Dv_Dat[2*j+1:2*j] = {E1_Dv[j],E1_Dat[j]}; 
  else//gn=0时，则E1是小于16路
    assign Dv_Dat[2*j+1:2*j] = 2'b00; 
end
endgenerate

endmodule