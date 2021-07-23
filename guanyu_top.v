/////////////////////Guanyu
//WAIT_W     ides16中delay模块每次延时等待时间的位宽
//WAIT_MAX   ides16中delay模块每次延时等待时间
//TEST       ides16中delay模块中ok状态验证q等待周期次数
//FW         SICI_PCS帧的宽度，数据宽度加上同步头SH的宽度，
//D_W        E1侧数据位宽
//AW         Grace_Agg输入输出的地址位宽
//DN         Grace_Agg下游管理寄存器数量
`timescale 1ns/1ps
module guanyu_top
(        
  //全局信号
  input              Rs            ,  ////异步复位，高有效
  input              Ck_38_A       ,  
  input              Ck_38_B       ,  ////38用PLL倍频得77和311m，grace ck用38M
  ////A，B选择信号
  input              SEL           ,  ////  0选A，1选B 
  ////SERDES侧A和B两路通道端口
  input              RX_Ck_622_A   ,//UPck
  input              RX_UP_Dat_A   ,//UP数据，622M需要311 DDR
  input              RX_Ck_622_B   ,// 
  input              RX_UP_Dat_B   ,//   
  output             TX_Ck_622_A   ,//A数据的CK 622M
  output             TX_UP_Dat_A   ,//A发送UP数据 622M需要311 DDR 
  output             TX_Ck_622_B   ,//B数据的CK 622M
  output             TX_UP_Dat_B   ,//B发送UP数据 622M需要311 DDR     
  //////////LIU_E1_42端口
  input  [42-1:0]    RX_E1_SD      ,
  input  [42-1:0]    RX_E1_Ck      ,
                     
  output [42-1:0]    TX_E1_SD      ,
  output [42-1:0]    TX_E1_Ck      ,    
  //////////LIU_E1_LOS端口
  input              LIU0_Ck       ,  //时钟是2.048 
  input              LIU0_LOS      ,  // 0-20，21未用  
  input              LIU0_LOS0     ,  //0通道标志，每22个周期脉冲一次
  
  input              LIU1_Ck       ,  //时钟是2.048 
  input              LIU1_LOS      ,  //21-41，42未用
  input              LIU1_LOS0     ,  //0通道标志，每22个周期脉冲一次

  //output  [3:0]      TX_CARD_TYPE  , //复帧抽出的不发送  
  ////spi_slave接口
  input              SPI_CS0       ,//扩展SPI 0 片选信号，低电平有效
  input              SPI_SCK       ,//扩展SPI时钟信号，片选无效期间保持低电平  
  input              SPI_MOSI      ,//扩展SPI主机发送，从机接收数据信号
  output             SPI_MISO0      //扩展SPI 0主机接收，从机发送数据信号
  );
/* assign  SEL=1'b0; */
wire    Ck_38_i;
assign  Ck_38_i = (SEL)?Ck_38_B:Ck_38_A;
/////////PLL 
wire  Ck_311,Ck_311_i,Ck_77_i,Ck_77;
Gowin_rPLL PLL_77_311
(
  .clkout     (Ck_311_i), //output clkout
  .clkoutd    (Ck_77_i ), //output clkoutd
  
  .clkin      (Ck_38_i )  //input clkin
);
// BUFG (global clock buffer)    
BUFG BUFG_77
(
  .I     (Ck_77_i),
  .O     (Ck_77)  
);

BUFG BUFG_311
(
  .I     (Ck_311_i),
  .O     (Ck_311)  
);

	
/* localparam AW = BitSize(D_W-1);/////BitSize(D_W-1)相当于例化模块和端口;
//计算函数，无逻辑资源，纯计算
function integer BitSize (input integer N); //bitsize计算函数模块，N是输入端口
integer ci;//定义整数变量 ci
begin
  ci=0;
  while ((2**ci)<= N)
  begin  
    ci = ci+1;
  end
  if(N<2)
    BitSize = 1;
  else
    BitSize = ci;
end
endfunction */

///////////E1_LOS 42路
wire [41:0] RX_E1_LOS;
LIU_LOS E1_LOS
(
  .  Ck         (Ck_77    ),
  .  Rs     	(Rs       ), 
  ///LIU0
  .LIU0_Ck      (LIU0_Ck  ),
  .LIU0_LOS     (LIU0_LOS ),
  .LIU0_LOS0    (LIU0_LOS0),
  ///LIU1
  .LIU1_Ck      (LIU1_Ck  ),
  .LIU1_LOS     (LIU1_LOS ),
  .LIU1_LOS0    (LIU1_LOS0),
  
  .RX_E1_LOS    (RX_E1_LOS) 
);
//////////////////创造SCK_P，SCK_N\\\\\\\\\\\\\\\\\\\\\\\\\\;
reg SCK1,SCK2;
always @(posedge Ck_77 or posedge  Rs)
begin
  if(Rs)
  begin
    SCK1 <= 1'b0;
    SCK2 <= 1'b0;
  end	
  else
  begin
    SCK1 <= SPI_SCK;
    SCK2 <= SCK1;
  end
end
assign SCK_P = ((~SCK2) & SCK1); //sck posedge;
assign SCK_N = ((~SCK1) & SCK2); //sck negedge;

///////////////////spi_slave管理Grace_agg\\\\\\\\\\\\\\\\\\\\\\\\\\；
wire [32-1:0] UP_Grace_RD,UP_Grace_WD;
wire [11:0] Grace_Ad;
wire [4-1:0] UP_Grace_Ad = Grace_Ad[3:0] ;//地址确定片选，同时也是ram深度
spi_slave UP_SPI
(
  . SPI_CS0        (SPI_CS0    ),//扩展SPI 0 片选信号，低电平有效
  . SPI_SCK        (SPI_SCK    ),//扩展SPI时钟信号，片选无效期间保持低电平
  . SCK_P          (SCK_P      ),////仿真时产生一个上沿脉冲输入
  . SCK_N          (SCK_N      ),////仿真时产生一个下沿脉冲输入
  ///主从机数据接口           
  . SPI_MOSI       (SPI_MOSI   ),//扩展SPI主机发送，从机接收数据信号
  . SPI_MISO0      (SPI_MISO0  ),//扩展SPI 0主机接收，从机发送数据信号
  ////Grace        
  . Grace_Rs       (Rs         ),//Grace复位信号，高复位
  . Grace_Ck       (Ck_77      ),//Grace复位时钟信号，
  ////输入         
  . Grace_RD       (UP_Grace_RD),//Grace读数据
  . Grace_Ac       (UP_Grace_Ac),//Grace读写应答信号，高电平有效，应答信号无效前，读写状态应该保持不变，对读，可以用Grace_Ac来锁存读数据
  ////输出         
  . Grace_CS       (UP_Grace_CS),//输出给下游Grace片选信号，高电平有效
  . Grace_WR       (UP_Grace_WR),//输出给下游Grace写使能，高电平写，低电平读
  . Grace_Ad       ( Grace_Ad  ),//输出给下游Grace地址信号,未用地址
  . Grace_WD       (UP_Grace_WD) //对下游Grace写数据，输出
);

////////////////grace接口汇聚功能模块，管理下游15个寄存器
localparam DN=15;///寄存器数量
wire [DN-1:0]    DN_Grace_CS,DN_Grace_Ac,DN_Grace_Re;
wire [DN*32-1:0] DN_Grace_RD;
wire [32-1:0]    DN_Grace_WD;
wire             DN_Grace_CE;
Grace_Agg  #(.AW(4),.DN(DN),.WN(1),.MOD(0),/* MOD 下游片选译码模式，0：设定地址范围模式，1：顺序地址译码模式 */
             .LT(60'hE_D_C_B_A_9_8_7_6_5_4_3_2_1_0),/* 每个下游片选地址低门限 */
             .UT(60'hE_D_C_B_A_9_8_7_6_5_4_3_2_1_0),/* 每个下游片选地址高门限 */
             .OP(15'h0_0_0_0)) /* 每个下游门限处理方法设置，0：在范围内片选有效(包含门限)，1：在范围外片选有效(不包含门限) */
E1_REG_Agg          
(
 //上游Grace接口
  . UP_Grace_Rs     (Rs         ) ,//Grace复位信号，高复位
  . UP_Grace_Ck     (Ck_77      ) ,//Grace复位时钟信号，100MHz
  . UP_Grace_CE     (    1'b1   ) ,////输入时钟使能
  . UP_Grace_CS     (UP_Grace_CS) ,////上游SPI输入1位
  . UP_Grace_WR     (UP_Grace_WR) ,////32位用一个使能
  . UP_Grace_Ac     (UP_Grace_Ac) ,////输出到上游SPI输出给上游SPI的读写应答信号
  . UP_Grace_Re     (           ) ,//输出到上游？ spi_slave没有此端口
  . UP_Grace_Ad     (UP_Grace_Ad) ,//上游输入，地址
  . UP_Grace_WD     (UP_Grace_WD) ,//上游写数据
  . UP_Grace_RD     (UP_Grace_RD) ,//输出,上游SPI读数据
  . UP_Grace_IR     (           ) ,//输出悬空
  . UP_Grace_OT     (           ) ,//悬空
  //下游Grace接口      
  . DN_Grace_Rs     (DN_Grace_Rs) ,//输出到下游每路寄存器
  . DN_Grace_Ck     (DN_Grace_Ck) ,//输出到下游每路寄存器
  . DN_Grace_CE     (DN_Grace_CE) ,//输出到下游每路寄存器
  . DN_Grace_CS     (DN_Grace_CS) ,//片选个数为下游管理的寄存器个数
  . DN_Grace_WR     (DN_Grace_WR) ,//32位写使能共用1位，可以分配8位则没个使能管理4位
  . DN_Grace_Ac     (DN_Grace_Ac) ,//输入位宽为寄存器个数
  . DN_Grace_Re     (DN_Grace_Re) ,//输入位宽为寄存器个数
  . DN_Grace_Ad     (           ) ,//地址未用，下游寄存器无深度，片选就够了
  . DN_Grace_WD     (DN_Grace_WD) ,//写入到下游可写寄存器32位，控制信号寄存器和软件配置寄存器可写
  . DN_Grace_RD     (DN_Grace_RD) ,//读到数据以32位*组数接收
  . DN_Grace_IR     (   15'b0   )  //输入0
);

////////////////////////E1接收A/B通道//////////////////////////////  
wire  [3:0]   E1_Cha_A,E1_Cha_B,E1_Cha;
wire  [5:0]  TX_DV_Dat,TX_DV_Dat_A,TX_DV_Dat_B;
wire  [41:0]  TX_TSF_A,TX_TSF_B,TX_TSF;

////A通道:
sici_SERDES
#( .D_W(42),.FW(8),.SWT(64),.SE(1),.TEST(4),.WAIT_MAX(0),.WAIT_W(2))
sici_SERDES_A 
(        
  //全局信号                    
  . Rs             (Rs            ),////异步复位，高有效
//. Ck_38          (Ck_38         ),////未用38
  . Ck_77          (Ck_77         ),////77.76 CDR模块输入77m
  . Ck_311         (Ck_311        ),//// 
  ///////////SERDES侧端口        
  . RX_UP_Dat      (RX_UP_Dat_A   ),//UP数据，622M需要311 DDR 
  . RX_UP_Ck       (RX_Ck_622_A   ),//UPck
  . TX_Ck_622      (TX_Ck_622_A   ),/////同数据的CK 622M
  . TX_UP_Dat      (TX_UP_Dat_A   ),//发送UP数据 622M需要311 DDR    
  . recal          (recal_A       ),//延时模块重新校准信号，1有效,存入sici控制寄存器
  . cal            (cal_A         ),//校准成功标志，高有效,存入sici告警寄存器
  ///////////E1_42信号输入端口
  . E1_In_Dat      (RX_E1_SD      ),
  . E1_In_Ck       (RX_E1_Ck      ),
  ///////////card和SSF           
  . RX_CARD_TYPE   (4'b0001       ),//接收，根据板卡设置常数 
  . RX_SSF         (RX_E1_LOS     ),//要存入LOS寄存器
  . TX_CARD_TYPE   (              ),//发送复帧抽出的
  . TX_SSF         (TX_TSF_A      ),//送到E1的TSF信号，存入TSF寄存器
  ///////////E1_Demux_CR侧端口     
  . E1_Cha         (E1_Cha_A      ),// A通道
  . TX_DV_Dat      (TX_DV_Dat_A   ),// A通道                           
  /////管理接口                   
  . Tx_Err_CRC     (Tx_Err_CRC_A  ),////在发送侧插入CRC错误，高有效 
  . Tx_Err_SH      (Tx_Err_SH_A   ),////在发送侧插入SH同步头错误，高有效 
  . Tx_Err_MF      (Tx_Err_MF_A   ),////在发送侧插入复帧头错误，高有效                   
  . Rx_Re_Syn      (Rx_Re_Syn_A   ),////接收侧重新同步信号，高有效。
    
  . Rx_Err_SH      (Rx_Err_SH_A   ),////接收侧SH同步头错误指示，高有效
  . Rx_Err_MF      (Rx_Err_MF_A   ),////接收侧复帧同步头错误指示，高有效
  . Rx_Lo_Syn      (Rx_Lo_Syn_A   ),////接收侧帧失步指示，高有效
  . Rx_Lo_MF       (Rx_Lo_MF_A    ),////接收侧复帧失步指示，高有效 
  . Rx_Err_CRC     (Rx_Err_CRC_A  ),////接收侧CRC错误指示，高有效 
  ///远端
  . Rx_R_Lo_Syn    (Rx_R_Lo_Syn_A ),////远端帧失步指示，高有效
  . Rx_R_Lo_MF     (Rx_R_Lo_MF_A  ),////远端复帧失步指示，高有效
  . Rx_R_Err_CRC   (Rx_R_Err_CRC_A) ////远端CRC错误指示，高有效
);

////B通道:
sici_SERDES
#( .D_W(42),.FW(8),.SWT(64),.SE(1),.TEST(4),.WAIT_MAX(0),.WAIT_W(2))
sici_SERDES_B 
(        
  ///全局信号                    
  . Rs             (Rs            ),  ////异步复位，高有效
//. Ck_38          (Ck_38         ),  ////
  . Ck_77          (Ck_77         ),  ////77.76 CDR模块输入77m
  . Ck_311         (Ck_311        ),  //// 
  ///////////SERDES侧端口        
  . RX_UP_Dat      (RX_UP_Dat_B   ),//UP数据，622M需要311 DDR 
  . RX_UP_Ck       (RX_Ck_622_B   ),//UPck
  . TX_Ck_622      (TX_Ck_622_B   ),/////同数据的CK 622M
  . TX_UP_Dat      (TX_UP_Dat_B   ),//发送UP数据 622M需要311 DDR    
  . recal          (recal_B       ),//延时模块重新校准信号，1有效,存入sici控制寄存器
  . cal            (cal_B         ),//校准成功标志，高有效,存入sici告警寄存器
  ///////////E1_42信号输入端口
  . E1_In_Dat      (RX_E1_SD      ),
  . E1_In_Ck       (RX_E1_Ck      ),
  ///////////card和SSF           
  . RX_CARD_TYPE   (4'b0001       ),//接收，根据板卡设置常数 //根据板卡设置常数
  . RX_SSF         (RX_E1_LOS     ),//要存入LOS寄存器     //E1送来的LOS信号，sici内部插入SH头，LOS寄存器也需要存
  . TX_CARD_TYPE   (              ),//发送复帧抽出的 
  . TX_SSF         (TX_TSF_B      ),//送到E1的TSF信号，存入TSF寄存器   
  ///E1_Demux_CR侧端口  
  . E1_Cha         (E1_Cha_B      ),  // B通道
  . TX_DV_Dat      (TX_DV_Dat_B   ),  // B通道                           
  ///管理接口       
  . Tx_Err_CRC     (Tx_Err_CRC_B  ),  ////在发送侧插入CRC错误，高有效 
  . Tx_Err_SH      (Tx_Err_SH_B   ),  ////在发送侧插入SH同步头错误，高有效 
  . Tx_Err_MF      (Tx_Err_MF_B   ),  ////在发送侧插入复帧头错误，高有效 
  . Rx_Re_Syn      (Rx_Re_Syn_B   ),  ////接收侧重新同步信号，高有效。
    
  . Rx_Err_SH      (Rx_Err_SH_B   ),  ////接收侧SH同步头错误指示，高有效
  . Rx_Err_MF      (Rx_Err_MF_B   ),  ////接收侧复帧同步头错误指示，高有效
  . Rx_Lo_Syn      (Rx_Lo_Syn_B   ),  ////接收侧帧失步指示，高有效
  . Rx_Lo_MF       (Rx_Lo_MF_B    ),  ////接收侧复帧失步指示，高有效 
  . Rx_Err_CRC     (Rx_Err_CRC_B  ),  ////接收侧CRC错误指示，高有效 
  ///远端                
  . Rx_R_Lo_Syn    (Rx_R_Lo_Syn_B ),  ////远端帧失步指示，高有效
  . Rx_R_Lo_MF     (Rx_R_Lo_MF_B  ),  ////远端复帧失步指示，高有效
  . Rx_R_Err_CRC   (Rx_R_Err_CRC_B)   ////远端CRC错误指示，高有效
);

////////////////////////A和B通道信号选择//////////////////////////////
assign E1_Cha    = (SEL==0)?E1_Cha_A   :E1_Cha_B    ;
assign TX_DV_Dat = (SEL==0)?TX_DV_Dat_A:TX_DV_Dat_B ;
assign TX_TSF    = (SEL==0)?TX_TSF_A   :TX_TSF_B    ;//42路并行v12到E1的TSF信号

//////////////////////////E1_SD，E1_Ck恢复模块\\\\\\\\\\\\\\\\\\\\\\\\\\;
localparam gn = 3; //42路E1需要6组
wire [gn*14-1:0] E1_Ck_n;
wire [gn*14-1:0] E1_SD_n;
wire [gn*14-1:0] MI_WFul;
wire [gn*14-1:0] MI_REmp;
wire [gn*14-1:0] MI_Lck ;
reg  [gn*14-1:0] WFul;
reg  [gn*14-1:0] REmp;
reg  [gn*14-1:0] Lck;
wire [4*gn-1:0] MI_Cha;
genvar n; 
generate for(n = 0;n < gn; n=n+1) //1个cdr模块恢复16位，取14位出来，D_W总计需要gn组
begin:E1_CDR


  E1_Demux_CR #(.E1N(14),.E1W(4),.FAW(7),.GP(8),.GI(10),.PUP(77760),.CF(883738),.NCO_NW(20),.NCO_DW(26)) E1_CR
  (
    .Rs             (Rs                ),
    .Ck             (Ck_77             ), //
    .CE             (1'b1              ), //   1/2
                                       
    .Mux_E1_DV      (TX_DV_Dat[2*n]    ),//8个ck_77周期时间组成[n+7:n]
    .Mux_E1_Cha     (E1_Cha            ),//输入通道号
    .Mux_E1_Dat     (TX_DV_Dat[(2*n)+1]),//8个ck_77周期时间组成[n+7:n]
                         
    .MI_Cha         (MI_Cha[4*n+3:4*n] ),//告警通道0-8
    .MI_WFul        (MI_WFul[n]        ),//位宽==组数n*Cha;
    .MI_REmp        (MI_REmp[n]        ),//位宽==组数n*Cha;
    .MI_Lck         (MI_Lck [n]        ),//位宽==组数n*Cha;
                                      
    .E1_Ck          (E1_Ck_n[(n*14)+13:n*14]),//位宽由gn决定
    .E1_SD          (E1_SD_n[(n*14)+13:n*14]) //位宽由gn决定,一次通道恢复7位出来
  );
 
  always @(posedge Ck_77 or posedge Rs)
  begin
    if(Rs)
	  WFul[14*n+7:14*n+0] <= 14'b0;
    else 
	begin
      case (MI_Cha[4*n+3:4*n])
        0:WFul[14*n+0]  <= MI_WFul[n];
        1:WFul[14*n+1]  <= MI_WFul[n];
        2:WFul[14*n+2]  <= MI_WFul[n];
        3:WFul[14*n+3]  <= MI_WFul[n];
    	4:WFul[14*n+4]  <= MI_WFul[n];
    	5:WFul[14*n+5]  <= MI_WFul[n];
    	6:WFul[14*n+6]  <= MI_WFul[n];
    	7:WFul[14*n+7]  <= MI_WFul[n];
        8:WFul[14*n+8]  <= MI_WFul[n];
        9:WFul[14*n+9]  <= MI_WFul[n];
       10:WFul[14*n+10] <= MI_WFul[n];
       11:WFul[14*n+11] <= MI_WFul[n];
       12:WFul[14*n+12] <= MI_WFul[n];
       13:WFul[14*n+13] <= MI_WFul[n];	
      endcase 
    end
  end
  
  always @(posedge Ck_77 or posedge Rs)
  begin
    if(Rs)
	  REmp[14*n+7:14*n+0] <= 14'b0;
    else 
	begin
      case (MI_Cha[4*n+3:4*n])
        0:REmp[14*n+0]  <= MI_REmp[n];
        1:REmp[14*n+1]  <= MI_REmp[n];
        2:REmp[14*n+2]  <= MI_REmp[n];
        3:REmp[14*n+3]  <= MI_REmp[n];
    	4:REmp[14*n+4]  <= MI_REmp[n];
    	5:REmp[14*n+5]  <= MI_REmp[n];
    	6:REmp[14*n+6]  <= MI_REmp[n];
    	7:REmp[14*n+7]  <= MI_REmp[n];
        8:REmp[14*n+8]  <= MI_REmp[n];
        9:REmp[14*n+9]  <= MI_REmp[n];
       10:REmp[14*n+10] <= MI_REmp[n];
       11:REmp[14*n+11] <= MI_REmp[n];
       12:REmp[14*n+12] <= MI_REmp[n];
       13:REmp[14*n+13] <= MI_REmp[n];		
      endcase 
    end
  end
  
  always @(posedge Ck_77 or posedge Rs)
  begin
    if(Rs)
	  Lck[14*n+7:14*n+0] <= 14'b0;
    else 
	begin
      case (MI_Cha[4*n+3:4*n])
        0:Lck[14*n+0]  <= MI_Lck[n];
        1:Lck[14*n+1]  <= MI_Lck[n];
        2:Lck[14*n+2]  <= MI_Lck[n];
        3:Lck[14*n+3]  <= MI_Lck[n];
    	4:Lck[14*n+4]  <= MI_Lck[n];
    	5:Lck[14*n+5]  <= MI_Lck[n];
    	6:Lck[14*n+6]  <= MI_Lck[n];
    	7:Lck[14*n+7]  <= MI_Lck[n];
        8:Lck[14*n+8]  <= MI_Lck[n];
        9:Lck[14*n+9]  <= MI_Lck[n];
       10:Lck[14*n+10] <= MI_Lck[n];
       11:Lck[14*n+11] <= MI_Lck[n];
       12:Lck[14*n+12] <= MI_Lck[n];
       13:Lck[14*n+13] <= MI_Lck[n];
      endcase 
    end
  end
  
end
endgenerate

////////////输出TX_E1_Ck，TX_E1_SD
assign TX_E1_Ck = E1_Ck_n[42-1:0]; //输出E1_Ck对应位宽
assign TX_E1_SD = E1_SD_n[42-1:0]; //输出E1_SD对应位宽

//0：只读版本寄存器
wire[31:0] Version = 32'h0000_01_02;//[15:8]代表主版本01，[7:0]次版本.02，版本号1.02
Grace_ro  Ver//////// 
(
  .Grace_Ck       (   Ck_77      ),//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[0]),//片选  
  .Grace_CE       (DN_Grace_CE   ),//时钟使能，grace_up输入1，dn输出1
  .Grace_WR       (DN_Grace_WR   ),//一位使能是控制32位写，两位控制16和16.。。。。                                         
                                 
  .Grace_Re       (DN_Grace_Re[0]),//同片选 
  .Grace_Ac       (DN_Grace_Ac[0]),//同片选  
  .Grace_RD       (DN_Grace_RD[0*32+31:0*32]),//读出Reg_In存入的数据 32位

  .Reg_Vld        (1'b1          ), //输入 
  .Reg_In         (Version       )  //存下输出的
);

//1：只读日期寄存器
wire[31:0] Date = 32'h2021_0719;
Grace_ro  DATE//////// 
(
  .Grace_Ck       (   DN_Grace_Ck      ),//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[1]),//片选  
  .Grace_CE       (DN_Grace_CE   ),//时钟使能，grace_up输入1，dn输出1
  .Grace_WR       (DN_Grace_WR   ),//一位使能是控制32位写                                         
                                 
  .Grace_Re       (DN_Grace_Re[1]),//同片选 
  .Grace_Ac       (DN_Grace_Ac[1]),//同片选  
  .Grace_RD       (DN_Grace_RD[1*32+31:1*32]),//读出Reg_In存入的数据 32位

  .Reg_Vld        (1'b1          ), //输入 
  .Reg_In         (Date          )  //存下输出的
);

//2：软件配置读写寄存器\\\\\\\\\\\\\\\\\\\\\\\\\\  ;
wire [31:0] CFG_FLAG;
Grace_rw  rw_CFG_FLAG////////寄存器没有调用ram，只有多通道_mc才会调用ram存在ram不同地址 
(
  .Grace_Rs       (DN_Grace_Rs   ),//agg下游端口输入
  .Grace_Ck       (   DN_Grace_Ck      ),//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[2]),//片选003 
  .Grace_CE       (DN_Grace_CE   ),//时钟使能，grace_up输入1，dn输出1
  .Grace_WR       (DN_Grace_WR   ),//一位使能是控制32位写，                                         

  .Grace_Re       (DN_Grace_Re[2]),//同片选003
  .Grace_Ac       (DN_Grace_Ac[2]),//同片选003
  .Grace_WD       (DN_Grace_WD   ),//DN写入Reg_Out要输出的数据 32位	   
  .Grace_RD       (DN_Grace_RD[2*32+31:2*32]),//读出Reg_In存入的数据 32位

  .Reg_Out        (CFG_FLAG      ), //输出32位 
  .Reg_In         (CFG_FLAG      )  //存下输出的
);	

//3：A_B控制信号读写寄存器\\\\\\\\\\\\\\\\\\\\\\\\\\  ;
wire[9:0] A_B_CTRL;///控制信号
assign {recal_B,recal_A,Tx_Err_CRC_B,Tx_Err_SH_B,Tx_Err_MF_B,Rx_Re_Syn_B,Tx_Err_CRC_A,Tx_Err_SH_A,Tx_Err_MF_A,Rx_Re_Syn_A}
	   = A_B_CTRL[9:0];///	  
Grace_rw #(.RW(10))  SICI_CTRL //10bit寄存器 
(
  .Grace_Rs       (DN_Grace_Rs   ),//agg下游端口输入
  .Grace_Ck       (   DN_Grace_Ck      ),//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[3]),//片选003 
  .Grace_CE       (DN_Grace_CE   ),//时钟使能
  .Grace_WR       (DN_Grace_WR   ),//32位的写使能                                           
 
  .Grace_Re       (DN_Grace_Re[3]),//同片选003
  .Grace_Ac       (DN_Grace_Ac[3]),//同片选003
  .Grace_WD       (DN_Grace_WD   ),//DN写入Reg_Out数据 32位	   
  .Grace_RD       (DN_Grace_RD[3*32+31:3*32]),//读出Reg_In数据 32位

  .Reg_Out        (A_B_CTRL      ), //输出32位 
  .Reg_In         (A_B_CTRL      )  //存下输出的控制信号
);
	  
//4：A_B状态读清寄存器\\\\\\\\\\\\\\\\\\\\\\\\\\;
wire[17:0] A_B_STA =
 {cal_B,cal_A,Rx_Err_SH_B,Rx_Err_MF_B,Rx_Lo_Syn_B,Rx_Lo_MF_B,Rx_Err_CRC_B,Rx_R_Lo_Syn_B,Rx_R_Lo_MF_B,Rx_R_Err_CRC_B,
              Rx_Err_SH_A,Rx_Err_MF_A,Rx_Lo_Syn_A,Rx_Lo_MF_A,Rx_Err_CRC_A,Rx_R_Lo_Syn_A,Rx_R_Lo_MF_A,Rx_R_Err_CRC_A};	  	  
Grace_rc #(.RW(18))  A_B_STA_reg//18bit寄存器 
(
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[4] ) ,//第几位片选
  .Grace_WR       (DN_Grace_WR    ) ,//没有写
                                  
  .Grace_Re       (DN_Grace_Re[4] ) ,//同片选004
  .Grace_Ac       (DN_Grace_Ac[4] ) ,//同片选004
  .Grace_RD       (DN_Grace_RD[4*32+31:4*32]),//读出存入的
  
  .Reg_In         (A_B_STA        )   //32位数据存入
);

//5:E1到VC12方向，SSF_E1_LOS[31:0]告警信号读清寄存器\\\\\\\\\\\\\\\\\\\\\\\\\\;
Grace_rc  SSF_E1_LOS31_0//////// 
 (
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[5] ) ,//片选  
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                  
  .Grace_Re       (DN_Grace_Re[5] ) ,//同片选 
  .Grace_Ac       (DN_Grace_Ac[5] ) ,//同片选 
  .Grace_RD       (DN_Grace_RD[5*32+31:5*32]),//读出存入的
 
  .Reg_In         (RX_E1_LOS[31:0]) //收到E1背板的SSF_LOS，存入
 );
 
//6:E1到VC12方向，SSF_E1_LOS[41:32]告警信号读清寄存器\\\\\\\\\\\\\\\\\\\\\\\\\\	  	  
Grace_rc #(.RW(10))  SSF_E1_LOS41_32//10bit寄存器 
 (
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[6] ) ,//片选 
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                  
  .Grace_Re       (DN_Grace_Re[6] ) ,//同片选
  .Grace_Ac       (DN_Grace_Ac[6] ) ,//同片选
  .Grace_RD       (DN_Grace_RD[6*32+31:6*32]),//读出存入的
                  
  .Reg_In         (RX_E1_LOS[41:32])   //32位数据存入
 );
 
//7:VC12到E1方向，SSF_TSF[31:0]告警信号读清寄存器\\\\\\\\\\\\\\\\\\\\\\\\\\;
Grace_rc  SSF_TSF31_0//////// 
 (
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[7] ) ,//片选  
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                 
  .Grace_Re       (DN_Grace_Re[7] ) ,//同片选 
  .Grace_Ac       (DN_Grace_Ac[7] ) ,//同片选 
  .Grace_RD       (DN_Grace_RD[7*32+31:7*32]),//读出存入的
                  
  .Reg_In         (TX_TSF[31:0]   )   //32位数据存入
 );
 
//8:E1到VC12方向，SSF_TSF[41:32]告警信号读清寄存器\\\\\\\\\\\\\\\\\\\\\\\\\\	  	  
Grace_rc #(.RW(10))  SSF_TSF41_32//10bit寄存器 
 (
  .Grace_Rs       (DN_Grace_Rs    ),//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ),//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[8] ),//片选 
  .Grace_WR       (DN_Grace_WR),//悬空，此寄存器无写使能
                                  
  .Grace_Re       (DN_Grace_Re[8] ),//同片选
  .Grace_Ac       (DN_Grace_Ac[8] ),//同片选
  .Grace_RD       (DN_Grace_RD[8*32+31:8*32]),//读出存入的
                  
  .Reg_In         (TX_TSF[41:32]  )//32位数据存入
 );	
 
//9:WFul[31:0]读清寄存器，存入恢复模块的告警信号\\\\\\\\\\\\\\\\\\\\\\\\\\	  	  
Grace_rc  FIFO_WFul31_0//////// 
(
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[9] ) ,//片选009 
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                 
  .Grace_Re       (DN_Grace_Re[9] ) ,//同片选009
  .Grace_Ac       (DN_Grace_Ac[9] ) ,//同片选009
  .Grace_RD       (DN_Grace_RD[9*32+31:9*32]),//读出存入的
                  
  .Reg_In         (WFul[31:0]     )     //32位数据存入
);

//10:WFul[41:32]读清寄存器，存入恢复模块的告警信号\\\\\\\\\\\\\\\\\\\\\\\\\\	  	  
Grace_rc  #(.RW(10)) FIFO_WFul41_32//10bit寄存器 
 (
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[10]) ,//片选 
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                  
  .Grace_Re       (DN_Grace_Re[10]) ,//同片选00A
  .Grace_Ac       (DN_Grace_Ac[10]) ,//同片选00A
  .Grace_RD       (DN_Grace_RD[10*32+31:10*32]),//读出存入的
                  
  .Reg_In         ( WFul[41:32]   )   //32位数据存入
 );
 
//11:REmp[31:0]读清寄存器，存入恢复模块的告警信号\\\\\\\\\\\\\\\\\\\\\\\\\\	  	  
Grace_rc  FIFO_REmp31_0//////// 
 (
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[11]) ,//片选11 
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                  
  .Grace_Re       (DN_Grace_Re[11]) ,//同片选11
  .Grace_Ac       (DN_Grace_Ac[11]) ,//同片选11
  .Grace_RD       (DN_Grace_RD[11*32+31:11*32]),//读出存入的
                  
  .Reg_In         (REmp[31:0]     )   //32位数据存入
 );
 
//12:REmp[41:32]读清寄存器，存入恢复模块的告警信号\\\\\\\\\\\\\\\\\\\\\\\\\\	  	  
Grace_rc #(.RW(10))  FIFO_REmp41_32//10bit寄存器 
 (
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[12]) ,//片选12 
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                  
  .Grace_Re       (DN_Grace_Re[12]) ,//同片选12
  .Grace_Ac       (DN_Grace_Ac[12]) ,//同片选12
  .Grace_RD       (DN_Grace_RD[12*32+31:12*32]),//读出存入的
                  
  .Reg_In         ( REmp[41:32]   )   //32位数据存入
 );
 
//13:Lck[31:0]读清寄存器，存入恢复模块的告警信号\\\\\\\\\\\\\\\\\\\\\\\\\\	  	  
Grace_rc  E1_Lck31_0//////// 
 (
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[13]) ,//片选13 
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                  
  .Grace_Re       (DN_Grace_Re[13]) ,//同片选13
  .Grace_Ac       (DN_Grace_Ac[13]) ,//同片选13
  .Grace_RD       (DN_Grace_RD[13*32+31:13*32]),//读出存入的
                  
  .Reg_In         (Lck[31:0]      )       //32位数据存入
 );
 
//14:Lck[41:32]读清寄存器，存入恢复模块的告警信号\\\\\\\\\\\\\\\\\\\\\\\\\\	  	  
Grace_rc #(.RW(10))  E1_Lck41_32//10bit寄存器 
 (
  .Grace_Rs       (DN_Grace_Rs    ) ,//agg下游端口输入
  .Grace_Ck       (DN_Grace_Ck    ) ,//agg下游端口输入
  .Grace_CS       (DN_Grace_CS[14]) ,//片选14 
  .Grace_WR       (DN_Grace_WR    ) ,//悬空，此寄存器无写使能
                                  
  .Grace_Re       (DN_Grace_Re[14]) ,//同片选14
  .Grace_Ac       (DN_Grace_Ac[14]) ,//同片选14
  .Grace_RD       (DN_Grace_RD[14*32+31:14*32]),//读出存入的
                  
  .Reg_In         ( Lck[41:32]    )    //32位数据存入
 );	  

endmodule