`timescale 1ns/1ps

////����CRC����ʽ
/*********************************************************************************************

   CRC-4       x4+x+1                  'h13         ITU G.704
   CRC-8       x8+x5+x4+1              'h131                   
   CRC-8       x8+x2+x1+1              'h107                   
   CRC-8       x8+x6+x4+x3+x2+x1       'h15E
   CRC-12      x12+x11+x3+x+1          'h180F
   CRC-16      x16+x15+x2+1            'h18005      IBM SDLC
   CRC16-CCITT x16+x12+x5+1            'h11021      ISO HDLC, ITU X.25, V.34/V.41/V.42, PPP-FCS
   CRC-32      x32+x26+x23+...+x2+x+1  'h104C11DB7  ZIP, RAR, IEEE 802 LAN/FDDI, IEEE 1394, PPP-FCS
   CRC-32c     x32+x28+x27+...+x8+x6+1 'h11EDC6F41  SCTP
**********************************************************************************************/
////DW  Ҫ����CRC������������λ��
////CW  CRC��λ����CRC����ʽλ����1λ
////CP  CRC����ʽ,����CRC����ʽ���ϱ�

module CRC_Core #(parameter DW = 64, CW = 16, CP  = 17'h18005)
      (
       input  [DW+CW-1:0] Dat_i,
       output [CW-1:0]    CRC_o 
      );


////DW+1����ʱ�����ݶ���ʽ
reg [CW+DW-1:0] Dat_Cal [0:DW];     
always @(*)
begin
  Dat_Cal[0]  <= Dat_i;  
end

////��ʱ�����ݶ���ʽ���Ա�ԭ����ʽ,��λ��DW�����������
genvar gv;
generate
begin
  for(gv=1;gv<=DW;gv=gv+1)
  begin:GL
  
    always @(*)
    begin
      Dat_Cal[gv]  <= Dat_Cal[gv-1] ^ ({(CW+DW){Dat_Cal[gv-1][CW+DW-gv]}} & (CP << (DW-gv)));
    end
    
  end
end
endgenerate

//���һ����ʱ���ݾ��Ƕ���ʽ���������������ݶ�������µ�CRC
assign  CRC_o = Dat_Cal[DW][CW-1:0]; 
      
    
endmodule