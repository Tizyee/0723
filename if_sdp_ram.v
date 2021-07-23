`timescale 1ns/10ps

//简单双口推断ram模块
// AW   地址位宽
// DW   数据位宽
// AT   当RT为AUTO时，地址的门限值
// RT   ram类型：AUTO,BLOCK,LUT;
// OR   输出寄存器使能：TRUE,FALSE
// IF   ram初始化文件，如果没有初始化文件，参数例化为""。
//      文件一串16进制表示一个地址的值，每个值用空格隔开。
//      可以用@hhhhhh(h表示16进制)来指示后面的数据的开始地址。
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
