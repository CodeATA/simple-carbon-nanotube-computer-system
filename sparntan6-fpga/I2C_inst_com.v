module I2C_inst_com
(
    input CLK,
	 input RSTn,
	 
	 input [1:0] Start_Sig,             //read or write command
	 input [7:0] Addr_Sig,              //eeprom words address
	 input [15:0] WrData,                //eeprom write data
	 output [15:0] RdData,               //eeprom read data
	 output Done_Sig,                   //eeprom read/write finish
	 
	 output SCL,
	 inout SDA
	 
);

parameter F100K = 9'd200;                //250Khz��ʱ�ӷ�Ƶϵ��              
	 
reg [5:0]i;
reg [5:0]Go;
reg [8:0]C1;
reg [15:0]rData;
reg [7:0] rAddr;
reg rSCL;
reg rSDA;
reg isAck;
reg isDone;
reg isOut;	
 
assign Done_Sig = isDone;
assign RdData = rData;
assign SCL = rSCL;
assign SDA = isOut ? rSDA : 1'bz;        //SDA�������ѡ��

//****************************************// 
//*             I2C��д�������            *// 
//****************************************// 
always @ ( posedge CLK or negedge RSTn )
	 if( !RSTn )  begin
			i <= 6'd0;
			Go <= 5'd0;
			C1 <= 9'd0;
			rData <= 8'd0;
			rSCL <= 1'b1;
			rSDA <= 1'b1;
			isAck <= 1'b1;
			isDone <= 1'b0;
			isOut <= 1'b1;
	 end
	 else if( Start_Sig[0] )                     //I2C ����д  
	     case( i )
				    
		    0: //����IIC��ʼ�ź�
			 begin
					isOut <= 1;                         //SDA�˿����
					
					if( C1 == 0 ) rSCL <= 1'b1;
					else if( C1 == 200 ) rSCL <= 1'b0;       //SCL�ɸ߱��
							  
					if( C1 == 0 ) rSDA <= 1'b1; 
					else if( C1 == 100 ) rSDA <= 1'b0;        //SDA���ɸ߱�� 
							  
					if( C1 == 250 -1) begin C1 <= 9'd0; i <= i + 1'b1; end
					else C1 <= C1 + 1'b1;
			 end
					  
			 1: // Write Device Addr
			 begin rAddr <= {4'b1010, 3'b000, 1'b0}; i <= 6'd7; Go <= i + 1'b1; end         
				 
			 2: // Wirte Word Addr
			 begin rAddr <= Addr_Sig; i <= 6'd7; Go <= i + 1'b1; end
					
			 3: // Write Data
			 begin rData <= WrData; i <= 6'd17; Go <= i + 1'b1; end
	 
			 4: //����IICֹͣ�ź�
			 begin
			    isOut <= 1'b1;
						  
			    if( C1 == 0 ) rSCL <= 1'b0;
			    else if( C1 == 50 ) rSCL <= 1'b1;     //SCL���ɵͱ��       
		
				 if( C1 == 0 ) rSDA <= 1'b0;
				 else if( C1 == 150 ) rSDA <= 1'b1;     //SDA�ɵͱ��  
					 	  
				 if( C1 == 250 -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end
				 else C1 <= C1 + 1'b1; 
			 end
					 
			 5:
			 begin isDone <= 1'b1; i <= i + 1'b1; end       //дI2C ����
					 
			 6: 
			 begin isDone <= 1'b0; i <= 6'd0; end
				 
			 7,8,9,10,11,12,13,14:                         //����Device Addr/Word Addr/Write Data
			 begin
			     isOut <= 1'b1;
				  rSDA <= rAddr[14-i];                      //��λ�ȷ���
					  
				  if( C1 == 0 ) rSCL <= 1'b0;
			     else if( C1 == 50 ) rSCL <= 1'b1;         //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
				  else if( C1 == 150 ) rSCL <= 1'b0; 
						  
				  if( C1 == F100K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end     //����250Khz��IICʱ��
				  else C1 <= C1 + 1'b1;
			 end
					 
			 15:                                          // waiting for acknowledge
			 begin
			     isOut <= 1'b0;                            //SDA�˿ڸ�Ϊ����
			     if( C1 == 100 ) isAck <= SDA;             //��ȡIIC ���豸��Ӧ���ź�
						  
				  if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1;         //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
				  else if( C1 == 150 ) rSCL <= 1'b0;
						  
				  if( C1 == F100K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end    //����250Khz��IICʱ��
				  else C1 <= C1 + 1'b1; 
			 end
					 
			 16:
			 if( isAck != 0 ) i <= 6'd0;
			 else i <= Go; 
					
			 17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32:
			 begin
					isOut <= 1'b1;
					rSDA <= rData[32-i];
					
					if( C1 == 0 ) rSCL <= 1'b0;
					else if( C1 == 50 ) rSCL <= 1'b1;
					else if( C1 == 150 ) rSCL <= 1'b0;
					
					if( C1 == F100K -1 ) begin C1 <= 9'b0; i <= i + 1'b1; end
					else C1 <= C1 + 1'b1;
			 end
			 
			 33:                                          // waiting for acknowledge
			 begin
			     isOut <= 1'b0;                            //SDA�˿ڸ�Ϊ����
			     if( C1 == 100 ) isAck <= SDA;             //��ȡIIC ���豸��Ӧ���ź�
						  
				  if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1;         //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
				  else if( C1 == 150 ) rSCL <= 1'b0;
						  
				  if( C1 == F100K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end    //����250Khz��IICʱ��
				  else C1 <= C1 + 1'b1; 
			 end
			 
			 34:
			 if( isAck != 0 ) i <= 6'd0;
			 else i <= Go; 
			 
  		    endcase
	
	  else if( Start_Sig[1] )                     //I2C ���ݶ�
		    case( i )
				
			 0: // Start
			 begin
			      isOut <= 1;                      //SDA�˿����
					      
			      if( C1 == 0 ) rSCL <= 1'b1;
			 	   else if( C1 == 200 ) rSCL <= 1'b0;      //SCL�ɸ߱��
						  
					if( C1 == 0 ) rSDA <= 1'b1; 
					else if( C1 == 100 ) rSDA <= 1'b0;     //SDA���ɸ߱�� 
						  
					if( C1 == 250 -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end
					 else C1 <= C1 + 1'b1;
			 end
					  
			 1: // Write Device Addr(�豸��ַ)
			 begin rAddr <= {4'b1010, 3'b000, 1'b0}; i <= 6'd9; Go <= i + 1'b1; end
					 
			 2: // Wirte Word Addr(EEPROM��д��ַ)
			 begin rAddr <= Addr_Sig; i <= 6'd9; Go <= i + 1'b1; end
					
			 3: // Start again
			 begin
			     isOut <= 1'b1;
					      
			     if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1; 
				  else if( C1 == 250 ) rSCL <= 1'b0;
						  
			     if( C1 == 0 ) rSDA <= 1'b0; 
				  else if( C1 == 50 ) rSDA <= 1'b1;
				  else if( C1 == 150 ) rSDA <= 1'b0;  
						  
				  if( C1 == 300 -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end
				  else C1 <= C1 + 1'b1;
			 end
					 
			 4: // Write Device Addr ( Read )
			 begin rAddr <= {4'b1010, 3'b000, 1'b1}; i <= 6'd9; Go <= i + 1'b1; end
					
			 5: // Read Data
			 begin rData <= 16'd0; i <= 6'd19; Go <= i + 1'b1; end
				 
			 6: //����IICֹͣ�ź�
			 begin
			     isOut <= 1'b1;
			     if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1; 
		
				  if( C1 == 0 ) rSDA <= 1'b0;
				  else if( C1 == 150 ) rSDA <= 1'b1;
					 	  
				  if( C1 == 250 -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end
				  else C1 <= C1 + 1'b1; 
			 end
					 
			 7:                                                       //дI2C ����
			 begin isDone <= 1'b1; i <= i + 1'b1; end
					 
			 8: 
			 begin isDone <= 1'b0; i <= 6'd0; end
				 
					
			 9,10,11,12,13,14,15,16:                                  //����Device Addr(write)/Word Addr/Device Addr(read)
			 begin
			      isOut <= 1'b1;					      
			 	   rSDA <= rAddr[16-i];                                //��λ�ȷ���
						  
				   if( C1 == 0 ) rSCL <= 1'b0;
					else if( C1 == 50 ) rSCL <= 1'b1;                   //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
					else if( C1 == 150 ) rSCL <= 1'b0; 
						  
					if( C1 == F100K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end   //����250Khz��IICʱ��
					else C1 <= C1 + 1'b1;
			 end
			       
			 17: // waiting for acknowledge
			 begin
			      isOut <= 1'b0;                                       //SDA�˿ڸ�Ϊ����
					     
			 	   if( C1 == 100 ) isAck <= SDA;                        //��ȡIIC ��Ӧ���ź�
						  
					if( C1 == 0 ) rSCL <= 1'b0;
					else if( C1 == 50 ) rSCL <= 1'b1;                 //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
					else if( C1 == 150 ) rSCL <= 1'b0;
						  
					if( C1 == F100K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end     //����250Khz��IICʱ��
					else C1 <= C1 + 1'b1; 
			 end
					 
			 18:
			      if( isAck != 0 ) i <= 6'd0;
					else i <= Go;
					 
					 
			 19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34: // Read data
			 begin
			     isOut <= 1'b0;
			     if( C1 == 100 ) rData[34-i] <= SDA;                              //��λ�Ƚ���
						  
				  if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1;                  //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
				  else if( C1 == 150 ) rSCL <= 1'b0; 
						  
				  if( C1 == F100K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end     //����250Khz��IICʱ��
				  else C1 <= C1 + 1'b1;
			 end	  
					 
			 35: // no acknowledge
			 begin
			     isOut <= 1'b1;
					  
				  if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1;                  //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
				  else if( C1 == 150 ) rSCL <= 1'b0;
						  
				  if( C1 == F100K -1 ) begin C1 <= 9'd0; i <= Go; end    //����250Khz��IICʱ��
				  else C1 <= C1 + 1'b1; 
			end
				
			endcase		
		

	
				
endmodule
