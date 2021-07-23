

`timescale 1ns/1ps

////////信号延时模块
////SW  信号位宽，大于等于1
////DN  延时的拍数，大于等于1
////TP  实现延时的载体类型，"AUTO" 自动，"REG" 寄存器器实现 ，"SRL"  SRL实现,  "BRAM"   block RAM 实现

module Delay #(parameter SW = 8,DN = 6, TP = "AUTO")
       (
        input          Ck ,
        input          CE ,
        input [SW-1:0] DI ,
        output[SW-1:0] DO    
       );

generate
begin
  if(TP == "AUTO")
  begin
    if(DN<4)
    begin
      Delay_reg #(.SW(SW),.DN(DN)) DR
           (
            .Ck(Ck), .CE(CE), .DI(DI), .DO(DO)
           );
     end      
     else if(DN < 65)
     begin
       Delay_srl #(.SW(SW),.DN(DN)) DS
          (
           .Ck(Ck), .CE(CE), .DI(DI), .DO(DO)
          );
     end     
     else     
     begin
       Delay_ram #(.SW(SW),.DN(DN)) DRA
         (
          .Ck(Ck), .CE(CE), .DI(DI), .DO(DO)
         );
    end       
  end
  else if(TP == "REG")
  begin
    Delay_reg #(.SW(SW),.DN(DN)) DR
       (
        .Ck(Ck), .CE(CE), .DI(DI), .DO(DO)
       );
  end  
  else if(TP == "SRL")
  begin
    Delay_srl #(.SW(SW),.DN(DN)) DS
       (
        .Ck(Ck), .CE(CE), .DI(DI), .DO(DO)
       );
  end     
  else if(TP == "BRAM")
  begin
    if(DN>3)
    begin
      Delay_ram #(.SW(SW),.DN(DN)) DRA
         (
          .Ck(Ck), .CE(CE), .DI(DI), .DO(DO)
         );
    end     
    else
    begin
      Delay_reg #(.SW(SW),.DN(DN)) DR
         (
          .Ck(Ck), .CE(CE), .DI(DI), .DO(DO)
         );
    end     
  end
end
endgenerate



endmodule