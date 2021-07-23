`timescale 100ps/1ps
module ides16_delay_ctrl /*��ģ��������ʱ���Ѳ���,���������Ĵ��ڲ�����*/
#(parameter CNT_WAIT_W = 2,  //q�Ƚϵȴ�����λ��1λ��С
            MAX        = 0,  //q�Ƚϵȴ����� ��Ϊ0
            TEST       = 4,
			FW         = 8 )  //输入数据宽度
(     /* ÿ���˿ڶ�����Сдһ�� */
  input [FW-1:0]  q     ,//ides16������16λ��������
  input          recal  ,//����У׼,����Ч
  input          rst    ,//�ܸ�λ���߸�λ
  input          pclk   ,//ģ��ʱ��
  
  output  reg    cal    ,// У׼�ɹ���־��1Ϊ�ɹ�
  output         sdtap  ,// 0��̬��ʱ��1��̬;data��clk���Ƕ�̬
  output  reg    value  ,// data��clk����һ������������������μ��ɣ�ͬ������
  output  reg    setn    // 0��+��ʱ;1��-��ʱ����ʱ����
);

assign sdtap = 1;//0�Ǽ��ؾ�̬��ʱ,1�Ƕ�̬��ʱ;ʼ��Ϊ��̬����

localparam  DLY_INC      = 4'b0000 ; //������ʱ + 1'b1
localparam  SEARCH_EDG1  = 4'b0001 ; //������һ����              
localparam  EDG1         = 4'b0010 ; //��һ����         
localparam  SEARCH_EDG2  = 4'b0011 ; //�����ڶ����� 
localparam  DLY_DEC      = 4'b0100 ; //������ʱ - 1'b1
localparam  DLY_MID      = 4'b0101 ; //������ʱ���е�              
localparam  OK           = 4'b0110 ; //OK״̬����֤        
localparam  OK_INC2      = 4'b0111 ; //����2���ж�            
localparam  OK_DEC2      = 4'b1000 ; //����2���ж�  
localparam  DLY_CLR      = 4'b1001 ; //���㲽����0��ʱ  
localparam  IDLE         = 4'b1111 ; //

reg [3:0] lstate;
reg [3:0] cstate;
reg [3:0] nstate;

reg [CNT_WAIT_W - 1:0] cnt_wait;                 //�ȴ�ʱ���������Ϊ0
reg [6:0]              cnt,edg1_end,cnt_mid,cnt_test; //
reg [15:0]             q0;                            //�Ĵ�q��ǰֵ

//打一拍q
always @(posedge pclk or posedge rst) 
begin
  if (rst)          
    q0 <= 8'b0;
  else
    q0 <= q;
end

always @(posedge pclk or posedge rst) 
begin
  if (rst)          
  begin  
	cstate <= IDLE;
  end
  else if (recal)   //
    cstate <= DLY_CLR;
  else 
    cstate <= nstate;	
end

always @(posedge pclk or posedge rst) 
begin
  if (rst)                   //
    lstate <= SEARCH_EDG1;
  else if (cstate != nstate)//״̬��תʱ
    lstate <= cstate;       //�Ĵ��ϴ�cstate
end

always @(posedge pclk or posedge rst) 
begin
  if (rst) 
    cnt_wait <= 0;
  else if(cstate != nstate)
    cnt_wait <= 0;
  else 
    cnt_wait <= cnt_wait + 1'b1;
end
  
always @(*) 
begin
  case (cstate) 
    IDLE:
    begin
     if(cnt_test == 10)
     nstate <= SEARCH_EDG1;	  	  
    end  
    DLY_INC: //+
    begin                        
	  nstate <= lstate;
    end                       
    SEARCH_EDG1:
    begin                     
     if (q != q0 /* && cnt_wait == MAX */ )      
       nstate <= EDG1;       
     else if (q == q0 && cnt_wait == MAX) 
       nstate <= DLY_INC;        
     else    //״̬����      
       nstate <= cstate;  
    end                       
    EDG1:
    begin    //��һ����   
	 if(q == q0 && cnt_test == (10- 1'b1)) 
       nstate <= SEARCH_EDG2;      //10���ȶ�������2
     else if(q != q0 && cnt_wait == MAX) 
       nstate <= DLY_INC;       	 
     else            
       nstate <= cstate;    
    end                                              
    SEARCH_EDG2:
    begin               
	 if (cnt_wait == MAX && q ==q0  )       
       nstate <= DLY_INC;              		 
	 else if (cnt_wait == MAX && q !=q0 )
       nstate <= DLY_MID; 		 
	 else //cnt_wait < MAX ״̬����      
       nstate <= cstate;     
    end
    DLY_DEC:  // - �����ӳ�
    begin                                        
	  nstate <= lstate;  //�����ϴ�״̬
    end
    DLY_MID:
    begin
     if (cnt == cnt_mid)	//�������ɣ���OK
       nstate <= OK; 
     else                  //�����ӳٵ�cnt_mid
       nstate <= DLY_DEC;		  
    end 		
    OK:
    begin
     if (cnt_test == TEST && q0 != q )
       nstate <= OK_INC2;    //���ֲ��ȣ�����2�۲�   
     else                   
       nstate <= cstate;	  //���ȱ��֣���ʱ����	  
    end
    OK_INC2:
    begin   
     if (q0 == q && cnt_test == TEST)
       nstate <= OK;         //���ȷ���ok  
	 else if ( q0 != q && cnt<cnt_mid + 2)                  
       nstate <= DLY_INC;	  //
	 else if (q0 != q && cnt== cnt_mid + 2)                  
       nstate <= OK_DEC2;	  //			
     else                   
       nstate <= cstate;	  //���ȼ�ʱ����		
    end
    OK_DEC2:
    begin
     if (q0 == q && cnt_test == TEST)
       nstate <= OK;         //���ȷ���ok 
	 else if (q0 != q && cnt>cnt_mid - 2)                  
       nstate <= DLY_DEC;	  //
	 else if (q0 != q && cnt==cnt_mid - 2)                  
       nstate <= DLY_CLR;	  //			
     else                   
       nstate <= cstate;	  //��ʱ����	  
    end
    DLY_CLR:
    begin
     if(cnt == 0 ) //����0
       nstate <= SEARCH_EDG1; //����������1
	 else                   
       nstate <= DLY_DEC; //����  
    end	 
    default : nstate <= IDLE;
  endcase
end

always @(posedge pclk or posedge rst ) 
begin
  if (rst)
  begin
	value    <= 1;
	cal      <= 0;
	setn     <= 0; //+
	cnt      <= 0; //��������
	cnt_test <= 0;
    cnt_mid  <= 0;	  
    edg1_end <= 0; 
 end
  else
  begin  
   case (cstate)
    IDLE:
    begin
      if(cnt_test < 10) //����״̬�ȴ�q�ȶ�
        cnt_test <= cnt_test + 1'b1 ;	  	  
    end     
    DLY_INC:
    begin
      cal      <= 0     ;
      setn     <= 0     ; //+
      cnt      <= cnt + 1'b1; //��������
      value    <= 0     ; //��ʱ״̬���1��
      cnt_test <= 0     ;	  	  
    end   
    SEARCH_EDG1:
    begin             
      value <= 1 ;      //���׼���¸�����	  
    end	 
    EDG1:
    begin             //q�仯��״̬
        value <= 1;      
      if (q == q0 && cnt_wait == MAX)	 //������ʱ�����ж�10������
      begin
  	    edg1_end <= cnt;          //�Ĵ�
  	    cnt_test <= cnt_test + 1'b1; //+��10��
  	  end 
  	  else if (q !=q0)
        cnt_test <= 0;   //10�����Ⱥ��������߲�������     		   
    end
    SEARCH_EDG2:
    begin             
        value <= 1 ;      //���׼���¸�����
	if (q !=q0 /* && cstate == 3 */)	
		cnt_mid  <= (cnt+edg1_end)>>1; //�е�
	end	 
    DLY_DEC:
    begin
      setn  <= 1 ; //����	 
      value <= 0 ; 
      cnt   <= cnt - 1'b1;     //��ʱһ��- 1'b1
      cnt_test  <= 0 ; 	
    end
    DLY_MID:
    begin
  	  value <= 1 ; 
/* 	if (q !=q0 && cstate == 3)	
		cnt_mid  <= (cnt+edg1_end)>>1; //�е� */	  
    end 
    OK:
    begin                             //OK״̬
      
	  if (cnt_test == TEST && q0 == q )  //n�ĺ���һֱ��֤q0 = q
        cal <= 1; 	       //У׼�ɹ���־��1Ϊ�ɹ�	   
      else if(cnt_test == TEST && q0 != q)
      begin
    	cnt_test <= 0;
    	cal <= 0;
      end
      else                    
        cnt_test <= cnt_test + 1'b1;             
    end
    OK_INC2:
    begin                             
        value <= 1 ;	  	           
      if(q0 == q )
        cnt_test  <= cnt_test  + 1'b1 ; 
      if(cnt_test == TEST)
        cnt_test  <= cnt_test  ; 		
    end	 
    OK_DEC2:
    begin                             
        value <= 1 ;	  	           
      if(q0 == q )
        cnt_test  <= cnt_test  + 1'b1 ; 
      if(cnt_test == TEST)
        cnt_test  <= cnt_test  ;
    end	 
    DLY_CLR:
    begin
        value <= 1; 
    end	 
//      default : nstate <= IDLE;  //Ĭ������
     endcase
   end
  end
endmodule

