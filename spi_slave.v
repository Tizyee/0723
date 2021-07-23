`timescale 1ns/1ns
module spi_slave(
input               SPI_CS0   ,//扩展SPI 0 片选信号，低电平有效
input               SPI_SCK   ,//扩展SPI时钟信号，片选无效期间保持低电平
input               SCK_P     ,////CK上沿脉冲
input               SCK_N     ,////CK下沿脉冲
input               SPI_MOSI  ,//扩展SPI主机发送，从机接收数据信号
output              SPI_MISO0 ,//扩展SPI 0主机接收，从机发送数据信号

input               Grace_Rs  ,//Grace复位信号，高复位
input               Grace_Ck  ,//Grace复位时钟信号，100MHz
input  [31:0]       Grace_RD  ,//Grace读数据
input               Grace_Ac  ,//Grace读写应答信号，高电平有效，应答信号无效前，读写状态应该保持不变，对读，可以用Grace_Ac来锁存读数据
output  reg         Grace_CS  ,//Grace片选信号，高电平有效
output  reg         Grace_WR  ,//Grace读写指示信号，高电平写，低电平读
output  reg [11:0]  Grace_Ad  ,//Grace地址信号
output  reg [31:0]  Grace_WD   //Grace写数据

);
/*
reg             sck_reg1;
reg             sck_reg2;
always @(posedge Grace_Ck or posedge Grace_Rs) 
begin 
if (Grace_Rs)
 begin
   sck_reg1 <= 1'b0;
   sck_reg2 <= 1'b0; 
 end //if
 else 
 begin
   sck_reg1 <=  SPI_SCK ;
   sck_reg2 <=  sck_reg1;  
 end //else
end //always
  
assign sck_p = ((~sck_reg2) & sck_reg1); //sck posedge;
assign sck_n = ((~sck_reg1) & sck_reg2); //sck negedge;
*/
localparam  IDLE          = 2'b00 ;
localparam  SPI_CMD       = 2'b01 ;
localparam  SPI_RD        = 2'b10 ;
localparam  SPI_WD        = 2'b11 ;

reg [1:0] cstate;
reg [1:0] nstate;
reg [4:0] scnt  ;

always @(posedge Grace_Ck or posedge Grace_Rs) 
begin
 if (Grace_Rs)
 begin 
   cstate <= IDLE;
   scnt   <= 0   ;
 end
 else 
 begin
   cstate <= nstate;
   scnt   <= (cstate != nstate)?1'b0:
             (SCK_P)?scnt + 1'b1:scnt;  
 end
end 

reg [4:0] sck_n_cnt;
always @(posedge Grace_Ck or posedge Grace_Rs) 
begin
 if (Grace_Rs)
 begin 
   cstate <= IDLE;
   sck_n_cnt   <= 0   ;
 end
 else 
 begin
   cstate <= nstate;
   sck_n_cnt   <= (cstate != nstate)?1'b0:
             (SCK_N)?sck_n_cnt + 1'b1:sck_n_cnt;  
 end
end 

reg  [3:0]  CMD; 
always @(*)
begin 
  case (cstate)
   IDLE : begin 
           if (~SPI_CS0) nstate <=SPI_CMD;
		   else nstate <= IDLE;
          end 

SPI_CMD : begin 
            if ( sck_n_cnt == 17) nstate <= (CMD == 4'h8)?SPI_WD:SPI_RD;
			else nstate <= SPI_CMD;
          end 

 SPI_RD : begin
            if (SPI_CS0) nstate <= IDLE;
		    else nstate <= SPI_RD; 
          end  

 SPI_WD : begin
            if (SPI_CS0) nstate <= IDLE;
		    else nstate <= SPI_WD; 
          end  
 default: nstate = IDLE;	  
  endcase	  
end


reg [31:0]  shift_reg;
always @(posedge Grace_Ck or posedge Grace_Rs) 
begin
 if (Grace_Rs)
 begin 
   shift_reg <= 0;
 end
 else 
 begin
   if(SCK_P)
	 shift_reg <= {shift_reg[30:0],SPI_MOSI} ;
 end
end 

reg  [11:0] addr    ; 

always @(posedge Grace_Ck or posedge Grace_Rs) 
begin
 if (Grace_Rs)
 begin   
	addr <=12'd0; 
	CMD <= 4'h0;
 end 
 else
 begin
   if (cstate==SPI_CMD&&scnt ==3&&SCK_P)
   CMD <= {shift_reg[2:0],SPI_MOSI};
   case (cstate)
    
       SPI_CMD : begin 
	               if (scnt ==15&&SCK_P)
			       addr <= {shift_reg[10:0],SPI_MOSI};
		         end   
   
 SPI_RD,SPI_WD : begin
                   if (SCK_N&&scnt ==31)	
                   addr <= addr + 1'b1 ; 			
                 end 
   	   
        default:  ;
 
	endcase	  
 end 
end 

reg  [31:0] rd_data ;
always @(posedge Grace_Ck or posedge Grace_Rs) 
begin
 if (Grace_Rs)
 begin   
   Grace_CS <= 1'b0 ;  
   Grace_WD <= 32'd0;
   Grace_Ad <= 1'b0 ;
   rd_data  <= 32'd0;   
 end 
 else
 begin
   if((cstate==SPI_CMD&&scnt ==16&&CMD==4'd0)||(cstate==SPI_RD&&scnt==0))
   begin 
     Grace_CS <= 1'b1; 
	 Grace_WR <=1'b0;
     Grace_Ad <= addr;   
   end 
   else if (cstate==SPI_WD&&scnt==31&&SCK_P)
   begin 
     Grace_WR <=1'b1;
     Grace_Ad <=addr;  
     Grace_CS <= 1'b1;
     Grace_WD <={shift_reg[30:0],SPI_MOSI};
   end
   else if (Grace_Ac)
   begin 		   
      Grace_CS <= 1'b0;
      //Grace_WR <=1'b0;
      Grace_Ad <=addr; 
     //Grace_WD <={shift_reg[30:0],SPI_MOSI};
   end
   if (Grace_Ac) rd_data <= Grace_RD ;
   
 end   
end 
 

reg [7:0] byte_send;
always @(posedge Grace_Ck or posedge Grace_Rs) 
begin
 if (Grace_Rs)
 begin   
   byte_send <=8'd0;
 end 
 else if (SCK_N) 
 begin 
   if ((cstate==SPI_CMD&&(scnt==8||scnt==16))||(cstate==SPI_WD&&(scnt==8||scnt==16||scnt==24||scnt==0)))
   byte_send <= shift_reg[7:0];
   else if (cstate==SPI_RD&&scnt[2:0]==0)
   begin 
    case (scnt[4:3])
    2'b01: byte_send <= rd_data[31:24]; 
    2'b10: byte_send <= rd_data[23:16];
    2'b11: byte_send <= rd_data[15:8];
    2'b00: byte_send <= rd_data[7:0];   
    endcase
   end 
   else 
     byte_send <= {byte_send[6:0],1'b0}; 	 
 end 
end  
 
assign SPI_MISO0 = byte_send[7];

endmodule 