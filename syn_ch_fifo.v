`timescale 1ns / 100ps

////////��������
////AW  FIFO��ַλ��
////CW  ͨ��λ��
////DW  FIFO����λ��
////FD  ���źŷ���0�����źź�д��ʱ����룬1�����źźͶ���ʱ�����

module Syn_Ch_FIFO #(parameter AW = 4, CW =10, DW = 10,FD = 0,WA_IF = "WA.if",RA_IF = "RA.if")
                  (
                   input          Rs  ,    //��λ�źţ��߸�λ
                   input          Ck  ,    //ʱ���ź�
                   input          CE  ,    //ʱ��ʹ���źţ�����Ч
									   
                   input          WE  ,    //дʹ�ܣ�����Ч
                   input [CW-1:0] WC  ,    //дͨ������ͨ��Ӧ����ѭ������ 
                   input [DW-1:0] WD  ,    //д����
                   output         WFul,    //��ָʾ�źţ�����Ч��
									   
                   input          RE  ,    //��ʹ�ܣ�����Ч
                   input [CW-1:0] RC  ,    //��ͨ������ͨ��Ӧ����ѭ������ 
                   output[DW-1:0] RD  ,    //�����ݣ�����ڶ�ͨ����ʱ4��
                   output         REmp,    //��ָʾ�źţ�����Ч��
                   output[AW-1:0] RRC      //FIFO��ʣ������ָʾ
                  );        


////������ʱ����
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


////ͨ��FIFO��д��ַ

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



////ͨ��FIFO�Ķ���ַ

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


////ͨ��FIFO������RAM

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

////д���źŲ���
assign WA_N       = WA_L + 1'b1;
assign WAWR_A_WE  = (RA_W != WA_N)?WE_D2:0;

wire   WFul_c;
////�����źŲ���
assign RA_N       = RA_L + 1'b1;
assign RARR_A_WE  = (WA_R != RA_L)?RE_D2:0;

wire   REmp_c;
assign REmp_c = (WA_R == RA_L)?1:0;

wire  [AW-1:0] RRC_c;
assign RRC_c = WA_R-RA_L;
////���źŲ���
generate
begin
  if(FD == 0)
    assign WFul_c = (RA_W == WA_N )?1:0;
  else
    assign WFul_c = ((WA_R+1) == RA_L )?1:0;

end
endgenerate
////��ʱ2�ģ�REmp,RRC��������ݶ���,WFul�����WC��ʱ4��
Delay #(.SW(AW + 2),.DN(2)) OSD1
       (
        .Ck(Ck), 
		.CE(CE), 
        .DI({WFul_c,REmp_c,RRC_c}), 
        .DO({WFul,REmp,RRC})
       );

endmodule