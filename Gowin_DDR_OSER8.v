//
//Written by GowinSynthesis
//Product Version "GowinSynthesis V1.9.7.06Beta"
//Thu Jul 22 13:32:35 2021

//Source file index table:
//file0 "\C:/Gowin/Gowin_V1.9.7.06Beta_GowinSynthesis-only/IDE/ipcore/DDR/data/ddr.v"
`timescale 100 ps/100 ps
module Gowin_DDR_OSER8 (
  din,
  fclk,
  pclk,
  reset,
  q
)
;
input [7:0] din;
input fclk;
input pclk;
input reset;
output [0:0] q;
wire \oser8_gen[0].oser8_inst_1_Q1 ;
wire [0:0] ddr_inst_o;
wire VCC;
wire GND;
  OBUF \obuf_gen[0].obuf_inst  (
    .O(q[0]),
    .I(ddr_inst_o[0]) 
);
  OSER8 \oser8_gen[0].oser8_inst  (
    .Q0(ddr_inst_o[0]),
    .Q1(\oser8_gen[0].oser8_inst_1_Q1 ),
    .D0(din[0]),
    .D1(din[1]),
    .D2(din[2]),
    .D3(din[3]),
    .D4(din[4]),
    .D5(din[5]),
    .D6(din[6]),
    .D7(din[7]),
    .TX0(GND),
    .TX1(GND),
    .TX2(GND),
    .TX3(GND),
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
