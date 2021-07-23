`timescale 1ns / 100ps

////////参数描述
////AW  FIFO地址位宽
////CW  通道位宽
////DW  FIFO数据位宽
////FD  满信号方向，0：满信号和写侧时序对齐，1：满信号和读侧时序对齐

module Syn_Ch_FIFO #(parameter AW = 4, CW =10, DW = 10,FD = 0,WA_IF = "WA.if",RA_IF = "RA.if")
                  (
                   input          Rs  ,    //复位信号，高复位
                   input          Ck  ,    //时钟信号
                   input          CE  ,    //时钟使能信号，高有效
									   
                   input          WE  ,    //写使能，高有效
                   input [CW-1:0] WC  ,    //写通道，各通道应轮流循环出现 
                   input [DW-1:0] WD  ,    //写数据
                   output         WFul,    //满指示信号，高有效。
									   
                   input          RE  ,    //读使能，高有效
                   input [CW-1:0] RC  ,    //读通道，各通道应轮流循环出现 
                   output[DW-1:0] RD  ,    //读数据，相对于读通道延时4拍
                   output         REmp,    //空指示信号，高有效。
                   output[AW-1:0] RRC      //FIFO里剩余数据指示
                  );        


////输入延时处理
wire          WE_D2 ;   
wire [CW-1:0] WC_D2 ;
wire [DW-1:0] WD_D2 ;

wire          RE_D2 ;  
wire [CW-1:0] RC_D2 ;
Delay #(.SW(CW*2+DW+2),.DN(2)) ISD2
       (
        .Ck(Ck), 
		.CE(CE), 
        .DI({WE,WC,WD,RE,RC}), 
        .DO({WE_D2,WC_D2,WD_D2,RE_D2,RC_D2})
       );


////通道FIFO的写地址

wire          WAWR_A_WE;
wire [AW-1:0] WA_N     ;
wire [AW-1:0] WA_L     ;  
wire [AW-1:0] WA_R     ;     

if_sdp_ram #(.AW(CW),.DW(AW),.RT("AUTO"),.OR("TRUE"),.IF(WA_IF)) WAWR
         (.A_Ck (Ck       ),
          .A_CE (CE       ),
          .A_WE (WAWR_A_WE),
          .A_Ad (WC_D2    ),
          .A_WD (WA_N     ),
          .B_Ck (Ck       ),
          .B_CE (CE       ),
          .B_Ad (WC       ),
          .B_RD (WA_L     )
         );

if_sdp_ram #(.AW(CW),.DW(AW),.RT("AUTO"),.OR("TRUE"),.IF(WA_IF)) WARR
         (.A_Ck (Ck       ),
          .A_CE (CE       ),
          .A_WE (WAWR_A_WE),
          .A_Ad (WC_D2    ),
          .A_WD (WA_N     ),
          .B_Ck (Ck       ),
          .B_CE (CE       ),
          .B_Ad (RC       ),
          .B_RD (WA_R     )
         );



////通道FIFO的读地址

wire          RARR_A_WE ;
wire [AW-1:0] RA_N      ;
wire [AW-1:0] RA_L      ;       
wire [AW-1:0] RA_W      ;     


if_sdp_ram #(.AW(CW),.DW(AW),.RT("AUTO"),.OR("TRUE"),.IF(RA_IF)) RARR
         (.A_Ck (Ck        ),
          .A_CE (CE        ),
          .A_WE (RARR_A_WE ),
          .A_Ad (RC_D2     ),
          .A_WD (RA_N      ),
          .B_Ck (Ck        ),
          .B_CE (CE        ),
          .B_Ad (RC        ),
          .B_RD (RA_L      )
         );

if_sdp_ram #(.AW(CW),.DW(AW),.RT("AUTO"),.OR("TRUE"),.IF(RA_IF)) RAWR
         (.A_Ck (Ck        ),
          .A_CE (CE        ),
          .A_WE (RARR_A_WE ),
          .A_Ad (RC_D2     ),
          .A_WD (RA_N      ),
          .B_Ck (Ck        ),
          .B_CE (CE        ),
          .B_Ad (WC        ),
          .B_RD (RA_W      )
         );


////通道FIFO的数据RAM

if_sdp_ram #(.AW(CW + AW),.DW(DW),.RT("AUTO"),.OR("TRUE"),.IF("")) DATA_RAM
         (.A_Ck (Ck          ),
          .A_CE (CE          ),
          .A_WE (WAWR_A_WE   ),
          .A_Ad ({WC_D2,WA_L}),
          .A_WD (WD_D2       ),
          .B_Ck (Ck          ),
          .B_CE (CE          ),
          .B_Ad ({RC_D2,RA_L}),
          .B_RD (RD          )
         );

////写侧信号产生
assign WA_N       = WA_L + 1'b1;
assign WAWR_A_WE  = (RA_W != WA_N)?WE_D2:0;

wire   WFul_c;
////读侧信号产生
assign RA_N       = RA_L + 1'b1;
assign RARR_A_WE  = (WA_R != RA_L)?RE_D2:0;

wire   REmp_c;
assign REmp_c = (WA_R == RA_L)?1:0;

wire  [AW-1:0] RRC_c;
assign RRC_c = WA_R-RA_L;
////满信号产生
generate
begin
  if(FD == 0)
    assign WFul_c = (RA_W == WA_N )?1:0;
  else
    assign WFul_c = ((WA_R+1) == RA_L )?1:0;

end
endgenerate
////延时2拍，REmp,RRC和输出数据对齐,WFul相对于WC延时4拍
Delay #(.SW(AW + 2),.DN(2)) OSD1
       (
        .Ck(Ck), 
		.CE(CE), 
        .DI({WFul_c,REmp_c,RRC_c}), 
        .DO({WFul,REmp,RRC})
       );

endmodule