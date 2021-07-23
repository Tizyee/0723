`timescale 1ns/1ps

////E1N    E1数量，应该小于高频时钟(带CE)频率/低频时钟频率，这里E1是2.048MHz   
////E1W    E1数量位宽
////GP     比例增益，<=10,实际增益位1/2**GP
////GI     积分增益, <=10,实际增益位1/2**GI
////PUP    相位更新周期
////CF     E1时钟的理论中心频率=(2**NCO_DW)*2.048/高频时钟频率(带CE),取整数值
////FAW    单个通道的FIFO地址位宽
////NCO_NW 数控振荡器分子位宽
////NCO_DW 数控振荡器分母位宽
 
module E1_Demux_CR #(parameter E1N=7,E1W = 3,FAW = 7, GP = 8,GI = 10,PUP = 77760,CF = 883738,NCO_NW =20,NCO_DW =26)
       (
        input            Rs        ,
        input            Ck        , //311.04MHz
        input            CE        , //1/2的时间有效，等效155.52MHz

        input            Mux_E1_DV ,
		input  [E1W-1:0] Mux_E1_Cha,
        input            Mux_E1_Dat,
        
		output [E1W-1:0] MI_Cha    ,//通道
		output           MI_WFul   ,//写满
		output           MI_REmp   ,//读空
		output           MI_Lck    ,//
		
        output [E1N-1:0] E1_Ck     ,
        output [E1N-1:0] E1_SD     
      ); 
      
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
localparam PW = BitSize(PUP);
	  
////把E1数据写入同步通道FIFO
wire           FIFO_WFul_T4;
reg            FIFO_RE     ;
wire [E1W-1:0] FIFO_RC     ;
wire           FIFO_RD_T4  ;
wire           FIFO_REmp_T4;
wire [FAW-1:0] FIFO_RRC_T4 ;   
wire [FAW-1:0] FIFO_RRC_T5 ;   

Syn_Ch_FIFO #(.AW(FAW),.CW(E1W),.DW(1),.FD(1),.WA_IF("WA.if"),.RA_IF("RA.if")) FIFO
             (
              .Rs  (Rs          ),    
              .Ck  (Ck          ),    
              .CE  (CE          ),    
						        
              .WE  (Mux_E1_DV   ),    
              .WC  (Mux_E1_Cha  ),    
              .WD  (Mux_E1_Dat  ),    
              .WFul(FIFO_WFul_T4),    
								
              .RE  (FIFO_RE     ),    
              .RC  (FIFO_RC     ),    
              .RD  (FIFO_RD_T4  ),    
              .REmp(FIFO_REmp_T4),    
              .RRC (FIFO_RRC_T4 )     
             );  

			 
////相位更新周期计数器
reg  [PW-1:0] PUP_Cnt;
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
    PUP_Cnt <= 0;
  else
    PUP_Cnt <= (PUP_Cnt == (PUP-1'b1))?1'b0:PUP_Cnt + 1'b1;
end
////产生相位更新脉冲
wire [E1W-1:0] FIFO_RC_T2 ;
wire [E1W-1:0] FIFO_RC_T4 ;
wire           FIFO_RE_T4 ;

reg            PU_RAM_A_WE;
reg            PU_RAM_A_WD;
reg  [E1W-1:0] PU_RAM_A_Ad;
wire           PU_RAM_B_RD;

reg            PU_Pulse_T5;
if_sdp_ram #(.AW(E1W),.DW(1),.RT("AUTO"),.OR("TRUE"),.IF("")) PU_RAM 
            (.A_Ck (Ck         ),
             .A_CE (CE         ),
             .A_WE (PU_RAM_A_WE),
             .A_Ad (PU_RAM_A_Ad),
             .A_WD (PU_RAM_A_WD),
             .B_Ck (Ck         ),
             .B_CE (CE         ),
             .B_Ad (FIFO_RC_T2 ),
             .B_RD (PU_RAM_B_RD) 
            );
			
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    PU_RAM_A_WE <= 0;
    PU_RAM_A_WD <= 0;
    PU_RAM_A_Ad <= 0;
	PU_Pulse_T5 <= 0;
  end	
  else
  begin
    if(PUP_Cnt < E1N)
	begin
      PU_RAM_A_WE <= 1               ;
      PU_RAM_A_WD <= 1               ;
      PU_RAM_A_Ad <= PUP_Cnt[E1W-1:0];
	end
	else 
	begin
      PU_RAM_A_WE <= (PU_RAM_B_RD ==1&&FIFO_RE_T4==1&&PUP_Cnt >= E1N)?1:0;
      PU_RAM_A_WD <= 0          ;
      PU_RAM_A_Ad <= FIFO_RC_T4 ; 
	end
	PU_Pulse_T5 <= (PU_RAM_B_RD ==1&&FIFO_RE_T4==1&&PUP_Cnt >= E1N)?1:0;
  end	
end


////在更新周期内的相位累加
wire [E1W-1:0]    FIFO_RC_T3  ;
wire [E1W-1:0]    FIFO_RC_T5  ;
wire              FIFO_RE_T5  ;

wire [10+FAW-1:0] NS_Phase_Cnt;
wire [10+FAW-1:0] LS_Phase_Cnt;
if_sdp_ram #(.AW(E1W),.DW(10+FAW),.RT("AUTO"),.OR("TRUE"),.IF("")) PEC_RAM 
            (.A_Ck (Ck           ),
             .A_CE (CE           ),
             .A_WE (FIFO_RE_T5   ),
             .A_Ad (FIFO_RC_T5   ),
             .A_WD (NS_Phase_Cnt ),
             .B_Ck (Ck           ),
             .B_CE (CE           ),
             .B_Ad (FIFO_RC_T3   ),
             .B_RD (LS_Phase_Cnt ) 
            );
assign  NS_Phase_Cnt = (PU_Pulse_T5 == 0)?LS_Phase_Cnt + FIFO_RRC_T5:FIFO_RRC_T5;


////累积相位误差
wire [10+FAW-1:0] LS_Acc_Phase_Err;
assign            LS_Acc_Phase_Err = LS_Phase_Cnt-{1'b1,{(10+FAW-1){1'b0}}};

////比例增益
wire                  LS_CRU_Lck;
wire  [10+FAW-GP-1:0] NS_GP_Val ;
wire  [10+FAW-GP-1:0] LS_GP_Val ;

assign NS_GP_Val = LS_Acc_Phase_Err[10+FAW-1:GP];

if_sdp_ram #(.AW(E1W),.DW(10+FAW-GP),.RT("AUTO"),.OR("TRUE"),.IF("")) GP_RAM 
            (.A_Ck (Ck           ),
             .A_CE (CE           ),
             .A_WE (PU_Pulse_T5  ),
             .A_Ad (FIFO_RC_T5   ),
             .A_WD (NS_GP_Val    ),
             .B_Ck (Ck           ),
             .B_CE (CE           ),
             .B_Ad (FIFO_RC_T3   ),
             .B_RD (LS_GP_Val    ) 
            );
			
reg                  LS_GP_Val_Sgn;
reg  [10+FAW-GP-1:0] LS_GP_Val_Abs;
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    LS_GP_Val_Sgn <= 0;
    LS_GP_Val_Abs <= 0;
  end	
  else
  begin
    LS_GP_Val_Sgn <= LS_GP_Val[10+FAW-GP-1];
    LS_GP_Val_Abs <= (LS_GP_Val[10+FAW-GP-1] == 0)?LS_GP_Val:(~LS_GP_Val+1'b1);
  end	
end

////积分增益
wire  [10+FAW-GI-1:0] NS_GI_Val ;
wire  [10+FAW-GI-1:0] LS_GI_Val ;

assign NS_GI_Val = LS_Acc_Phase_Err[10+FAW-1:GI];

if_sdp_ram #(.AW(E1W),.DW(10+FAW-GI),.RT("AUTO"),.OR("TRUE"),.IF("")) GI_RAM 
            (.A_Ck (Ck           ),
             .A_CE (CE           ),
             .A_WE (PU_Pulse_T5  ),
             .A_Ad (FIFO_RC_T5   ),
             .A_WD (NS_GI_Val    ),
             .B_Ck (Ck           ),
             .B_CE (CE           ),
             .B_Ad (FIFO_RC_T3   ),
             .B_RD (LS_GI_Val    ) 
            );
			
reg                  LS_GI_Val_Sgn;
reg  [10+FAW-GI-1:0] LS_GI_Val_Abs;
reg                  NS_GI_Val_Sgn;
reg  [10+FAW-GI-1:0] NS_GI_Val_Abs;
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    LS_GI_Val_Sgn <= 0;
    LS_GI_Val_Abs <= 0;
    NS_GI_Val_Sgn <= 0;
    NS_GI_Val_Abs <= 0;
  end	
  else
  begin
    LS_GI_Val_Sgn <= LS_GI_Val[10+FAW-GI-1];
    LS_GI_Val_Abs <= (LS_GI_Val[10+FAW-GI-1] == 0)?LS_GI_Val:(~LS_GI_Val+1'b1);
    NS_GI_Val_Sgn <= NS_GI_Val[10+FAW-GI-1];
    NS_GI_Val_Abs <= (NS_GI_Val[10+FAW-GI-1] == 0)?NS_GI_Val:(~NS_GI_Val+1'b1);
  end	
end

////积分累加器
reg  [NCO_NW-1:0] NS_Acc_Val_P ;
reg  [NCO_NW-1:0] NS_Acc_Val_N ;
reg  [NCO_NW-1:0] LS_Acc_Val_T7;
reg  [1:0]        NS_Acc_Sel   ;
wire [NCO_NW-1:0] LS_Acc_Val   ;
  
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    NS_Acc_Val_P <= CF;
	NS_Acc_Val_N <= CF;
	LS_Acc_Val_T7<= CF;
	NS_Acc_Sel   <= 0 ;
  end	
  else if(CE)
  begin
    NS_Acc_Val_P <= LS_Acc_Val + LS_GI_Val_Abs;
	NS_Acc_Val_N <= LS_Acc_Val - LS_GI_Val_Abs;
	LS_Acc_Val_T7<= LS_Acc_Val                ;
	if(NS_GI_Val_Sgn == 0 && LS_GI_Val_Sgn ==0 && NS_GI_Val_Abs > LS_GI_Val_Abs )   
	  NS_Acc_Sel <= 3;
    else if(NS_GI_Val_Sgn == 1 && LS_GI_Val_Sgn ==1 && NS_GI_Val_Abs > LS_GI_Val_Abs)
	  NS_Acc_Sel <= 2;
	else  
	  NS_Acc_Sel <= 0;
  end	
end  

reg  [NCO_NW-1:0] NS_Acc_Val;
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    NS_Acc_Val <= CF;
  end	
  else if(CE)
  begin
    case(NS_Acc_Sel)
	3:
	  NS_Acc_Val <= (NS_Acc_Val_P >(CF+CF/4000))?(CF+CF/4000):NS_Acc_Val_P;
	2:
	  NS_Acc_Val <= (NS_Acc_Val_N <(CF-CF/4000))?(CF-CF/4000):NS_Acc_Val_N;
	default:
	  NS_Acc_Val <= LS_Acc_Val_T7;
	endcase
  end	
end  

////锁定状态
reg    NS_CRU_Lck_T7;
reg    NS_CRU_Lck   ;

always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    NS_CRU_Lck_T7 <= 0;
	NS_CRU_Lck    <= 0;
  end	
  else if(CE)
  begin
    NS_CRU_Lck_T7 <= (NS_GI_Val_Abs < 2 && LS_GI_Val_Abs < 2)?1:
                     (NS_GI_Val_Abs >=2 && LS_GI_Val_Abs >=2)?0:LS_CRU_Lck;
    NS_CRU_Lck    <= NS_CRU_Lck_T7;
  end	
end  

////积分累加器RAM
wire           PU_Pulse_T8;
wire [E1W-1:0] FIFO_RC_T8 ;

if_sdp_ram #(.AW(E1W),.DW(NCO_NW+1),.RT("AUTO"),.IF("CF.if")) ACC_RAM 
            (.A_Ck (Ck                     ),
             .A_CE (CE                     ),
             .A_WE (PU_Pulse_T8            ),
             .A_Ad (FIFO_RC_T8             ),
             .A_WD ({NS_CRU_Lck,NS_Acc_Val}),
             .B_Ck (Ck                     ),
             .B_CE (CE                     ),
             .B_Ad (FIFO_RC_T4             ),
             .B_RD ({LS_CRU_Lck,LS_Acc_Val}) 
            );
			
////产生NCO_N的值
reg [NCO_NW-1:0] Mux_NCO_N      ;
reg [NCO_NW-1:0] Mux_NCO_N_P    ;
reg [NCO_NW-1:0] Mux_NCO_N_N    ;
reg             LS_GP_Val_Sgn_T7;

always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    Mux_NCO_N_P     <= CF;
	Mux_NCO_N_N     <= CF;
	LS_GP_Val_Sgn_T7<= 0 ;
	Mux_NCO_N       <= CF;
  end	
  else if(CE)
  begin
    Mux_NCO_N_P     <= LS_Acc_Val + LS_GP_Val_Abs;
	Mux_NCO_N_N     <= LS_Acc_Val - LS_GP_Val_Abs;
	LS_GP_Val_Sgn_T7<= LS_GP_Val_Sgn             ;
	Mux_NCO_N       <= (LS_GP_Val_Sgn_T7 == 0)?Mux_NCO_N_P:Mux_NCO_N_N;
  end	
end  

////锁存各自的NCO_N
reg [NCO_NW-1:0] NCO_N[E1N-1:0];
genvar gv;
generate
begin
  for(gv=0;gv<E1N;gv=gv+1)
  begin:GL0
    always @(posedge(Rs),posedge(Ck))
    begin
      if(Rs)
        NCO_N[gv] <= CF;
      else
      begin
	    if(FIFO_RC_T8 == gv&&PU_Pulse_T8 == 1)
		  NCO_N[gv] <= Mux_NCO_N;
      end	
    end
  end
end
endgenerate  
////NCO例化及数据输出  
wire [E1N-1:0] E1_CE     ;
reg  [E1N-1:0] E1_SD_T   ;
reg  [E1N-1:0] E1_SD_R   ;
generate
begin
  for(gv=0;gv<E1N;gv=gv+1)
  begin:GL1
    AnyFFD_E #(.DW(NCO_DW), .NW(NCO_NW)) NCO
       (
        .Rs     (Rs       ),  
        .HF_CE  (CE       ),  
        .HF_Ck  (Ck       ),  
        
        .NCO_N  (NCO_N[gv]),  
        
        .Acc_O  (         ),  
        .LF_Ck_O(E1_Ck[gv]),  
        .LF_CE_O(E1_CE[gv])   
       );
	   
    always @(posedge(Rs),posedge(Ck))
    begin
      if(Rs)
	  begin
	    E1_SD_T[gv] <= 0;
		E1_SD_R[gv] <= 0;
	  end	
      else if(CE)
      begin
        if(FIFO_RE_T4 && FIFO_RC_T4 == gv)
		  E1_SD_T[gv] <= FIFO_RD_T4;

        if(E1_CE[gv])
		  E1_SD_R[gv] <= E1_SD_T[gv];
		  
      end
    end
	
	assign E1_SD[gv] = E1_SD_R[gv];
	
  end
end
endgenerate 


////把输出时钟使能自适应复用,以解决相位不能及时反应的问题
//锁存产生数据有效标志
reg  [E1N-1:0] Sel_Last ;  
wire [E1N-1:0] Sel_Next ;  

reg  [E1N-1:0] E1_SD_Val;
generate
begin
  for(gv=0;gv<E1N;gv=gv+1)
  begin:LAT
    always @(posedge(Rs),posedge(Ck))
    begin
      if(Rs)
	    E1_SD_Val[gv] <= 0;
      else if(CE)
      begin
	    if(E1_CE[gv])
		  E1_SD_Val[gv] <= 1;
        else if(Sel_Next[gv] == 1)
		  E1_SD_Val[gv] <= 0;
      end
    end
  end
end
endgenerate
//自适应复用模块
Adaptive_Mux #(.DW(E1N),.MODE(0)) AMUX
      (
       .Cond_In (E1_SD_Val),  
       .Sel_Last(Sel_Last ),  
       .Sel_Next(Sel_Next )   
      );
  
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
    Sel_Last <= 0;
  else if(CE)
  begin
    Sel_Last <= Sel_Next;
  end
end
//通道信号编码
wire [E1W-1:0] Mux_Rd_Cha_c;
N2M_Enc #(.N(E1N),.M(E1W)) N2M
       (
		.Enc_Dat_i(Sel_Last    ),
        .Enc_Dat_o(Mux_Rd_Cha_c)     
      ); 

reg [E1W-1:0] Mux_Rd_Cha;
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
    Mux_Rd_Cha <= 0;
  else if(CE)
  begin
    Mux_Rd_Cha <= Mux_Rd_Cha_c;
  end
end
////读信号产生
always @(posedge(Rs),posedge(Ck))
begin
  if(Rs)
  begin
    FIFO_RE  <= 0;
  end	
  else if(CE)
  begin
    FIFO_RE <= |Sel_Last;
  end
end
assign FIFO_RC = Mux_Rd_Cha;


////产生相关延迟信号
wire FIFO_RE_T2  ;
wire FIFO_WFul_T6;
wire FIFO_REmp_T6;

Delay #(.SW(E1W*3+4),.DN(2),.TP("REG")) D2
       (
        .Ck(Ck), .CE(CE), 
		.DI({FIFO_RC,FIFO_RC_T2,FIFO_RC_T3,FIFO_RE,FIFO_RE_T2,FIFO_WFul_T4,FIFO_REmp_T4}), 
		.DO({FIFO_RC_T2,FIFO_RC_T4,FIFO_RC_T5,FIFO_RE_T2,FIFO_RE_T4,FIFO_WFul_T6,FIFO_REmp_T6})
       );

wire [E1W-1:0] FIFO_RC_T6;
Delay #(.SW(2*E1W+FAW+1),.DN(1),.TP("REG")) D1  
       (
        .Ck(Ck), .CE(CE), 
		.DI({FIFO_RC_T2,FIFO_RE_T4,FIFO_RRC_T4,FIFO_RC_T5}), 
		.DO({FIFO_RC_T3,FIFO_RE_T5,FIFO_RRC_T5,FIFO_RC_T6})
       );

Delay #(.SW(E1W+1),.DN(3),.TP("REG")) D3
       (
        .Ck(Ck), .CE(CE), 
		.DI({FIFO_RC_T5,PU_Pulse_T5}), 
		.DO({FIFO_RC_T8,PU_Pulse_T8})
       );

////管理接口
assign MI_Cha  = FIFO_RC_T6  ;
assign MI_WFul = FIFO_WFul_T6;
assign MI_REmp = FIFO_REmp_T6;
assign MI_Lck  = LS_CRU_Lck  ;
 

  

endmodule