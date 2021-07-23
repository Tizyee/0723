//
//Written by GowinSynthesis
//Product Version "GowinSynthesis V1.9.7.06Beta"
//Thu Jul 22 13:36:05 2021

//Source file index table:
//file0 "\C:/Gowin/Gowin_V1.9.7.06Beta_GowinSynthesis-only/IDE/ipcore/DDR/data/ddr.v"
`timescale 100 ps/100 ps
module Gowin_DDR_dly (
  din,
  fclk,
  pclk,
  reset,
  calib,
  sdtap,
  value,
  setn,
  q
)
;
input [0:0] din;
input fclk;
input pclk;
input reset;
input calib;
input sdtap;
input value;
input setn;
output [7:0] q;



wire \iodelay_gen[0].iodelay_inst_1_DF ;
wire [0:0] ibuf_o;
wire [0:0] iodly_o;
wire VCC;
wire GND;
  IBUF \ibuf_gen[0].ibuf_inst  (
    .O(ibuf_o[0]),
    .I(din[0]) 
);
  IODELAY \iodelay_gen[0].iodelay_inst  (
    .DO(iodly_o[0]),
    .DF(\iodelay_gen[0].iodelay_inst_1_DF ),
    .DI(ibuf_o[0]),
    .SDTAP(sdtap),
    .VALUE(value),
    .SETN(setn) 
);
defparam \iodelay_gen[0].iodelay_inst .C_STATIC_DLY=0;
  IDES8 \ides8_gen[0].ides8_inst  (
    .Q0(q[0]),
    .Q1(q[1]),
    .Q2(q[2]),
    .Q3(q[3]),
    .Q4(q[4]),
    .Q5(q[5]),
    .Q6(q[6]),
    .Q7(q[7]),
    .D(iodly_o[0]),
    .CALIB(calib),
    .PCLK(pclk),
    .FCLK(fclk),
    .RESET(reset) 
);
  VCC VCC_cZ (
    .V(VCC)
);
  GND GND_cZ (
    .G(GND)
);
  GSR GSR (
    .GSRI(VCC) 
);
endmodule /* Gowin_DDR */
