`timescale 1ns/1ps
module adapter_tx_Pcs   //E1_mux���ͽ���������Pcs
( 
  input                  Rs            ,  ////�첽��λ������Ч
  input                  Ck            ,  ////38.88	 
  ////E1_mux��ӿ� 
  input   [5:0]          Dv_Dat        , //dv��dat�������
  input   [3:0]          E1_MFI        , //��ʼ��֡0-15
  ////������˿�
  input    [3:0]         CARD_TYPE     , //�����card���ͣ�����֡����1λ��Tx_PCS_SH_Res�ź�
  input    [41:0]        SSF           , //�����SSF���ͣ� ����֡����1λ��Tx_PCS_SH_Res�ź� 
                        
  output  reg [7:0]      Tx_PCS_MFI    , //0-255֡
  output                 Tx_PCS_SH_Res , //����֡��0λ
  output  reg [8-2-1:0]  Tx_PCS_Dat      ////16λ��ȥ2λͬ��ͷ
);

reg [3:0]  cnt;
always @(posedge Ck or posedge Rs )
begin
  if(Rs)
    cnt <= 4'b0;
  else if (E1_MFI==15)
    cnt <= cnt + 1'b1; 
end

always @(posedge Ck or posedge Rs )
begin
  if(Rs)
    Tx_PCS_MFI <= 8'b0;
  else 
    Tx_PCS_MFI <= {cnt[3:0],E1_MFI[3:0]};//����ĸ�֡��ck�����,����һ��
end

always @(posedge Ck or posedge Rs)  
begin
  if(Rs)
    Tx_PCS_Dat <= 6'b0;
  else 
    Tx_PCS_Dat[5:0] <= Dv_Dat[5:0];   //�����dv��dat������һ��
end

reg [6:0] SH_reg;  //
always @(posedge Ck or posedge Rs )
begin
  if(Rs)
    SH_reg <= 7'b0;
  else
  begin
    case(Tx_PCS_MFI) //�͸�֡ͬ��
	  28-1:SH_reg[6:3]= CARD_TYPE ;//ʱ��������ǰһ�ĸ�ֵ
	  40-1:SH_reg     = SSF[41:35];
	  48-1:SH_reg     = SSF[34:28];
	  56-1:SH_reg     = SSF[27:21];
	  64-1:SH_reg     = SSF[20:14];
	  72-1:SH_reg     = SSF[13:7 ];
	  80-1:SH_reg     = SSF[6 :0 ];
      default:SH_reg  = SH_reg <<1;		  
	endcase
  end 	
end
 
assign  Tx_PCS_SH_Res = SH_reg[6];    //�����λ

endmodule	   