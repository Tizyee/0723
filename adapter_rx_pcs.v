`timescale 1ns/1ps
module adapter_rx_pcs   //����pcs������
( 
  input                  Rs            ,  ////�첽��λ������Ч
//input                  Ck_38         ,  ////38.88
  input                  Ck_77         ,  ////77.76
  
  input      [7:0]       Rx_PCS_MFI    , //0-255֡
  input                  Rx_PCS_SH_Res , //����֡��0λ
  input   [8-2-1:0]      Rx_PCS_Dat    , ////16λ��ȥ2λͬ��ͷ
  
  output reg [3:0]       E1_Cha        , //���0-16֡
  output reg [5:0]       TX_DV_Dat     , //77.77m���6λ
                                      
  output reg [3:0]       CARD_TYPE     , //�����card���ͣ�����֡����1λ��Tx_PCS_SH_Res�ź�
  output reg [41:0]      SSF             //�����SSF���ͣ� ����֡����1λ��Tx_PCS_SH_Res�ź�   
);      

assign  E1_Cha = Rx_PCS_MFI[3:0];//��4λ��֡������0-15ͨ��
assign  TX_DV_Dat = Rx_PCS_Dat;  //�������ֱ������

//�Ĵ�SH��SH_reg��λ��������������λ
reg [6:0] SH_reg;
always @(posedge Ck_77 or posedge Rs)
begin
  if(Rs)
    SH_reg <= 7'b0;
  else 
  begin
    SH_reg <= {SH_reg[5:0],Rx_PCS_SH_Res}; //��λ��ֵ����ʱһ��ִ�� 
  end
end

//���card
always @(posedge Ck_77 or posedge Rs) //CARD��ƽ������
begin
  if(Rs)
    CARD_TYPE <= 4'b0;
  else if (Rx_PCS_MFI == 31+1) //��һ��ִ�����
    CARD_TYPE = SH_reg[3:0];   //��ʱ����λ��ֵ��card
end

//���SSF
always @(posedge Ck_77 or posedge Rs) //SSF��ƽ������
begin
  if(Rs)
    SSF <= 42'b0;
  else
    case(Rx_PCS_MFI)
	  46+1:SSF[6 :0 ] = SH_reg;
	  54+1:SSF[13:7 ] = SH_reg;
	  62+1:SSF[20:14] = SH_reg;
	  70+1:SSF[27:21] = SH_reg;
	  78+1:SSF[34:28] = SH_reg;
	  86+1:SSF[41:35] = SH_reg;
	  default:SSF = SSF ; //����
    endcase
end

endmodule	   