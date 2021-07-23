`timescale 1ns/1ps


module N2M_Enc #(parameter N=42,M = 6)
       (
		input  [N-1:0] Enc_Dat_i,
        output [M-1:0] Enc_Dat_o     
      ); 
      
genvar gv; 

////N组信号和各自期望值比较，如果相等，则编码数据等于位置的值，否则为0。 
reg [M-1:0] Enc_Dat_o_T1[N-1:0];
generate
begin
  for(gv=0;gv<N;gv=gv+1)
  begin:GLT
    always @(*)
	begin
	  Enc_Dat_o_T1[gv] <= (Enc_Dat_i[gv:0] == 2**gv)?gv:0;  
	end
  end
end
endgenerate

////N组信号按位相或。 
reg [M-1:0] Enc_Dat_o_T2[N-1:0];
generate
begin
  for(gv=0;gv<N;gv=gv+1)
  begin:GLO
    always @(*)
	begin
	  if(gv == 0)
	    Enc_Dat_o_T2[gv] <= Enc_Dat_o_T1[gv];  
	  else
	    Enc_Dat_o_T2[gv] <= Enc_Dat_o_T2[gv-1] | Enc_Dat_o_T1[gv];  
	end
  end
end
endgenerate

assign Enc_Dat_o = Enc_Dat_o_T2[N-1];


endmodule