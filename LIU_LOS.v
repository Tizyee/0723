module LIU_LOS
(
  input            Ck      	   ,//38.88    
  input            Rs     	   ,   
  input          LIU0_Ck       ,//时钟是2.048 
  input          LIU0_LOS      ,// 0-20，21未用  
  input          LIU0_LOS0     ,//0通道标志，每22个周期脉冲一次
                                
  input          LIU1_Ck       ,//时钟是2.048 
  input          LIU1_LOS      ,//21-41，42未用
  input          LIU1_LOS0     ,//0通道标志，每22个周期脉冲一次
                                
  output reg [41:0]  RX_E1_LOS      //42路LOS信号   
  );
  
reg ck0,ck1;
always @(posedge Ck or posedge Rs)
begin
  if(Rs)
    ck0 <= 1'b0;
  else
    ck0 <= LIU0_Ck;    
end  

always @(posedge Ck or posedge Rs)
begin
  if(Rs)
    ck1 <= 1'b0;
  else
    ck1 <= LIU1_Ck;    
end  

assign  ck0_n  = ~LIU0_Ck&ck0;//下降沿脉冲
assign  ck1_n  = ~LIU1_Ck&ck1;//下降沿脉冲
 
reg  [21:0]  LOS_reg0;
always @(posedge Ck or posedge Rs)
begin
  if(Rs) 
    LOS_reg0 <= 22'b0;
  else if(ck0_n)
	LOS_reg0 <= {LIU0_LOS,LOS_reg0[21:1]};
end

reg  [21:0]  LOS_reg1;
always @(posedge Ck or posedge Rs)
begin
  if(Rs) 
    LOS_reg1 <= 22'b0; 
  else if(ck1_n)
	LOS_reg1 <= {LIU1_LOS,LOS_reg1[21:1]};	
end

always @(posedge Ck or posedge Rs)
begin
  if(Rs) 
    RX_E1_LOS[20:0]  <= 21'b0;
  else if(ck1_n && LIU1_LOS0)
	RX_E1_LOS[20:0]  <= LOS_reg0[20:0];
end

always @(posedge Ck or posedge Rs)
begin
  if(Rs) 
    RX_E1_LOS[41:21] <= 21'b0;
  else if(ck1_n && LIU1_LOS0)
	RX_E1_LOS[41:21] <= LOS_reg1[20:0];	
end

/* reg LOS0,LOS1;
always @(posedge Ck or posedge Rs)
begin
  if(Rs)
    LOS0 <= 1'b0;
  else
    LOS0 <= LIU0_LOS0;    
end  

always @(posedge Ck or posedge Rs)
begin
  if(Rs)
    LOS1 <= 1'b0;
  else
    LOS1 <= LIU1_LOS0;    
en */
/* assign  LOS0_p =  LIU0_LOS0&~LOS0;//上沿脉冲
assign  LOS1_p =  LIU1_LOS0&~LOS1;//上沿脉冲 */

endmodule