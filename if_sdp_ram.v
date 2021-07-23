`timescale 1ns/10ps

//��˫���ƶ�ramģ��
// AW   ��ַλ��
// DW   ����λ��
// AT   ��RTΪAUTOʱ����ַ������ֵ
// RT   ram���ͣ�AUTO,BLOCK,LUT;
// OR   ����Ĵ���ʹ�ܣ�TRUE,FALSE
// IF   ram��ʼ���ļ������û�г�ʼ���ļ�����������Ϊ""��
//      �ļ�һ��16���Ʊ�ʾһ����ַ��ֵ��ÿ��ֵ�ÿո������
//      ������@hhhhhh(h��ʾ16����)��ָʾ��������ݵĿ�ʼ��ַ��
//      

module if_sdp_ram #(parameter AW=4,DW=8,OR="TRUE",RT="AUTO",AT=6,IF="if_sdp_ram.ini")
                   (
                    input           A_Ck ,
                    input           A_CE ,
                    input           A_WE ,
                    input  [AW-1:0] A_Ad ,
                    input  [DW-1:0] A_WD ,
                    
                    input           B_Ck ,
                    input           B_CE ,
                    input  [AW-1:0] B_Ad ,
                    output [DW-1:0] B_RD
                   )/*synthesis syn_hier = "hard" */;

generate
  if (RT=="BLOCK") 
    if_sdp_ram_b 
    #( .AW (AW), .DW (DW),.OR(OR),.IF(IF))
    if_sdp_ram_b_i
            ( .A_Ck (A_Ck ),
              .A_CE (A_CE ),
              .A_WE (A_WE ),
              .A_Ad (A_Ad ),
              .A_WD (A_WD ),
              .B_Ck (B_Ck ),
              .B_CE (B_CE ),
              .B_Ad (B_Ad ),
              .B_RD (B_RD )
              ); 
  else if (RT=="LUT") 
    if_sdp_ram_l 
    #( .AW (AW), .DW (DW),.OR(OR),.IF(IF) )
    if_sdp_ram_l_i
            ( .A_Ck (A_Ck ),
              .A_CE (A_CE ),
              .A_WE (A_WE ),
              .A_Ad (A_Ad ),
              .A_WD (A_WD ),
              .B_Ck (B_Ck ),
              .B_CE (B_CE ),
              .B_Ad (B_Ad ),
              .B_RD (B_RD )
              ); 
  else if (RT=="AUTO") 
    if (AW<=AT)
      if_sdp_ram_l 
      #( .AW (AW), .DW (DW),.OR(OR),.IF(IF) )
      if_sdp_ram_l_i
            (.A_Ck (A_Ck ),
             .A_CE (A_CE ),
             .A_WE (A_WE ),
             .A_Ad (A_Ad ),
             .A_WD (A_WD ),
             .B_Ck (B_Ck ),
             .B_CE (B_CE ),
             .B_Ad (B_Ad ),
             .B_RD (B_RD )
            ); 
    else
    if_sdp_ram_b 
      #( .AW (AW), .DW (DW),.OR(OR),.IF(IF) )
      if_sdp_ram_b_i
            (.A_Ck (A_Ck ),
             .A_CE (A_CE ),
             .A_WE (A_WE ),
             .A_Ad (A_Ad ),
             .A_WD (A_WD ),
             .B_Ck (B_Ck ),
             .B_CE (B_CE ),
             .B_Ad (B_Ad ),
             .B_RD (B_RD )
            );       
              
endgenerate

endmodule
