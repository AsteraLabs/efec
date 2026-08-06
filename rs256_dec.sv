//////////////////////////////////////////////////////////////////////////////
////
//// Copyright (c) AsteraLabs Inc. Add rights reserved.
//// AsteraLabs Confidential Property
//// =============================================================================
////	CONFIDENTIAL / PROPRIETARY
////	This document contains confidential and proprietary information of Astera Labs. 
////	It is intended solely for the use of authorized personnel. 
////	Any unauthorized review, use, disclosure, or distribution is strictly prohibited.
////
//// Filename: rs256_dec.sv
//// Author  : Vladimir Shvydun (vlad.shvydun@asteralabs.com)
//// Design  : parallel decoder for extended RS n=256 bytes, t= 3/4/5 code
//// Details : t= 3/4/5 configuration is set by SW
//// 10 clock latency 
//// input data width =  250 bytes (t=3) or  248 bytes (t=4)or  246 bytes (t=5)
//// --------------------------------------------------
//////////////////////////////////////////////////////////////////////////////


module ea_unr #(parameter t=5, w=8, n=256) (
// inputs
  input clk,
  input rstn,
  input init,
  input [1:0] mode,  
  input [2*t-1:0][w-1:0] S,
// outputs
  output logic ready,
  output logic no_error,
  output logic last_symbol_error,
  output logic [t:0][w-1:0] L,
  output logic [t-1:0][w-1:0] O,
  output logic   [w-1:0] S0
  );
  

  localparam R_max = 3*t;
  localparam ea_depth = 2*t;

  typedef enum logic [2:0] { IDLE,LOAD_S,CALC,SHIFT_Q,SHIFT_R,COPY_R} FSM;
  FSM curr_state[2*t], next_state[2*t];
  
  logic [R_max:0][w-1:0] R[2*t];
  logic [R_max:0][w-1:0] Q[2*t];
  
  logic [$clog2(t)-1:0] deg_R[2*t];
  logic [$clog2(t)-1:0] deg_Q[2*t];
  
  logic [w-1:0] S0_local[2*t];
      
  logic [2*t-1:1] swap; 
  always_comb for (int i=1; i<2*t; i++) swap[i] = deg_Q[i-1] > deg_R[i-1];
  wire zero_syndrome = S=='0; 
  wire last_symbol_error_flag = S[2*t-1:1] == '0 & S[0] != '0;
  
  logic [w-1:0] R_lead[2*t-1:1];
  logic [w-1:0] Q_lead[2*t-1:1];
  
  always_comb for (int i=1; i<2*t; i++)  R_lead[i] = R[i-1][R_max]; 
  always_comb for (int i=1; i<2*t; i++)  Q_lead[i] = Q[i-1][R_max]; 
  
  logic [2*t-1:1] zero_R_lead;
  logic [2*t-1:1] zero_Q_lead;
  
  always_comb for (int i=1; i<2*t; i++) zero_R_lead[i] = R_lead[i] == '0;
  always_comb for (int i=1; i<2*t; i++) zero_Q_lead[i] = Q_lead[i] == '0;
  
  logic  [w-1:0] selected_lead[2*t];
   
  always_comb begin
    selected_lead[0] =  mode[1]? S[10-1] : (mode[0]? S[8-1] : S[6-1]);
    for (int i=1; i<2*t; i++) selected_lead[i] = (next_state[i]==SHIFT_Q)? Q[i-1][R_max-1] : R_lead[i];
  end
    
  logic  [w-1:0] inv_lead[2*t];
  always_comb for (int i=0; i<2*t; i++) inv_lead[i] = gf8_inv_comp(selected_lead[i]);

  logic  [w-1:0] M[2*t-1:1];
  always_comb for (int i=1; i<2*t; i++) M[i] = gf8_mult_comp ( R_lead[i],Q_lead[i]);

  logic [2*t-1:0] proc_vld;
  logic [2*t-1:0] no_error_local; 
  logic [2*t-1:0] last_symbol_error_local;
 
  always_ff @(posedge clk, negedge  rstn) 
  if (!rstn) begin
    no_error_local <= '0;
    for (int i=0; i<2*t; i++) S0_local[i] <= '0;
    last_symbol_error_local <= '0;
  end
  else begin
    no_error_local <= {no_error_local[2*t-2:0],zero_syndrome&init};
    S0_local[0] <= S[0];
    for (int i=1; i<2*t; i++) S0_local[i] <= S0_local[i-1];
    last_symbol_error_local <= {last_symbol_error_local[2*t-2:0],last_symbol_error_flag&init};
  end

  always @(*) proc_vld[0] = init;
  
  always @(posedge clk, negedge  rstn ) 
  if (!rstn)  proc_vld[2*t-1:1] <= '0;
  else proc_vld[2*t-1:1] <= proc_vld[2*t-2:0] & {{2{mode[1]}},{2{|mode}},5'b11111};

  always_comb begin
    
    if (init & !zero_syndrome & !last_symbol_error_flag) next_state[0] = LOAD_S;
    else next_state[0] = IDLE;
    
    for (int i=1; i<2*t; i++) begin 

      next_state[i] = IDLE;
      if ((i<2*3) | (mode==2'd1 & i<2*4) | mode[1])
	case (curr_state[i-1])
	  IDLE:   next_state[i] = IDLE;
	  COPY_R: next_state[i] = COPY_R;
	  LOAD_S: if (zero_Q_lead[i])  	next_state[i] = SHIFT_Q;
        	  else if (zero_R_lead[i])  	next_state[i] = SHIFT_R;
		  else                   	next_state[i] = CALC; 
	  SHIFT_Q:     if (!zero_Q_lead[i]) 	next_state[i] = CALC;
        	  else if (deg_Q[i-1]>'d1)    	next_state[i] = SHIFT_Q;
		  else                   	next_state[i] = proc_vld[i]? COPY_R : IDLE;
	  SHIFT_R:     if (deg_R[i-1]<1)      	next_state[i] = proc_vld[i]? COPY_R : IDLE;
        	  else if (zero_R_lead[i])  	next_state[i] = SHIFT_R;
		  else                   	next_state[i] = CALC;
  //	CALC:        if (deg_R[i-1]<1)      	next_state[i] = proc_vld[i]? COPY_R : IDLE;   
	  CALC:      /*  if (deg_R[i-1]<1)      	next_state[i] = proc_vld[i]? COPY_R : IDLE;   
        	  else*/ if (zero_R_lead[i])  	next_state[i] = SHIFT_R;
		  else                   	next_state[i] = CALC;
	endcase 
      
    end      
  end     


    
  always_ff @(posedge clk, negedge rstn)
    if (!rstn) for (int i=0; i<2*t; i++) curr_state[i] <= IDLE;
    else for (int i=0; i<2*t; i++) curr_state[i] <= next_state[i];


      
  always_ff @(posedge clk, negedge rstn )  
  if (!rstn) begin
    for (int j=0; j<2*5; j++) deg_R[0] <= '0; 
    for (int j=0; j<2*5; j++) deg_Q[0] <= '0; 
  end 
  else begin
    if (next_state[0]==LOAD_S)
      casex (mode)
        2'b00 : begin deg_R[0] <= 3'd3; deg_Q[0] <= 3'd3;  end
        2'b01 : begin deg_R[0] <= 3'd4; deg_Q[0] <= 3'd4;  end
	2'b1x : begin deg_R[0] <= 3'd5; deg_Q[0] <= 3'd5;  end	
      endcase 	

    for (int j=1; j<2*3; j++)
      case (next_state[j]) 
	SHIFT_Q:    begin  deg_R[j] <= deg_R[j-1];                                deg_Q[j] <= deg_Q[j-1]-1;                     end
	SHIFT_R:    begin  deg_R[j] <= deg_R[j-1]-1;                              deg_Q[j] <= deg_Q[j-1];                       end
	CALC:       begin  deg_R[j] <= (swap[j]? deg_Q[j-1] : deg_R[j-1])-'d1;    deg_Q[j] <= swap[j]? deg_R[j-1] : deg_Q[j-1]; end
      endcase  
    if (mode>2'd0)
      for (int j=2*3; j<2*4; j++)
	case (next_state[j]) 
	  SHIFT_Q:    begin  deg_R[j] <= deg_R[j-1];                                deg_Q[j] <= deg_Q[j-1]-1;                     end
	  SHIFT_R:    begin  deg_R[j] <= deg_R[j-1]-1;                              deg_Q[j] <= deg_Q[j-1];                       end
	  CALC:       begin  deg_R[j] <= (swap[j]? deg_Q[j-1] : deg_R[j-1])-'d1;    deg_Q[j] <= swap[j]? deg_R[j-1] : deg_Q[j-1]; end
	endcase  
    if (mode>2'd1)
      for (int j=2*4; j<2*5; j++)
	case (next_state[j]) 
	  SHIFT_Q:    begin  deg_R[j] <= deg_R[j-1];                                deg_Q[j] <= deg_Q[j-1]-1;                     end
	  SHIFT_R:    begin  deg_R[j] <= deg_R[j-1]-1;                              deg_Q[j] <= deg_Q[j-1];                       end
	  CALC:       begin  deg_R[j] <= (swap[j]? deg_Q[j-1] : deg_R[j-1])-'d1;    deg_Q[j] <= swap[j]? deg_R[j-1] : deg_Q[j-1]; end
	endcase  
      
  end 
      
          
       
  always_ff @(posedge clk ) begin
    if (next_state[0]==LOAD_S)
      casex (mode)
        2'b00 :   begin R[0] <= {S[4:0],{9{8'h00}},8'h01,8'h00}; Q[0] <= {inv_lead[0],S[4:0],{9{8'h00}},8'h01}; end 
        2'b01 :   begin R[0] <= {S[6:0],{7{8'h00}},8'h01,8'h00}; Q[0] <= {inv_lead[0],S[6:0],{7{8'h00}},8'h01}; end 
        2'b1x :   begin R[0] <= {S[8:0],{5{8'h00}},8'h01,8'h00}; Q[0] <= {inv_lead[0],S[8:0],{5{8'h00}},8'h01}; end
      endcase
    
    
    for (int j=1; j<2*3; j++)
      case (next_state[j]) 
	CALC:     begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i-1] ^ gf8_mult_comp (Q[j-1][i-1], M[j]); R[j][0]<='0; 
                	if (swap[j]) begin for (int i=0; i<R_max; i++) Q[j][i]<= R[j-1][i]; Q[j][R_max]<= inv_lead[j]; end
			else  for (int i=0; i<=R_max; i++) Q[j][i]<= Q[j-1][i]; 
		  end
	SHIFT_Q:  begin for (int i=1; i<R_max; i++) {Q[j][i],R[j][i]}<= {Q[j-1][i-1],R[j-1][i-1]};  {Q[j][0],R[j][0]}<='0; {Q[j][R_max],R[j][R_max]}<= {inv_lead[j],R[j-1][R_max-1]};	 end	
	SHIFT_R:  begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i-1];  R[j][0]<='0; for (int i=0; i<=R_max; i++) Q[j][i]<= Q[j-1][i]; end
	COPY_R :  begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i];  R[j][0]<='0;  end                  
      endcase           
    if (mode>2'd0)
       for (int j=2*3; j<2*4; j++)
	 case (next_state[j]) 
	   CALC:     begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i-1] ^ gf8_mult_comp (Q[j-1][i-1], M[j]); R[j][0]<='0; 
                	   if (swap[j]) begin for (int i=0; i<R_max; i++) Q[j][i]<= R[j-1][i]; Q[j][R_max]<= inv_lead[j]; end
			   else  for (int i=0; i<=R_max; i++) Q[j][i]<= Q[j-1][i]; 
		     end
	   SHIFT_Q:  begin for (int i=1; i<R_max; i++) {Q[j][i],R[j][i]}<= {Q[j-1][i-1],R[j-1][i-1]};  {Q[j][0],R[j][0]}<='0; {Q[j][R_max],R[j][R_max]}<= {inv_lead[j],R[j-1][R_max-1]};	 end	
	   SHIFT_R:  begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i-1];  R[j][0]<='0; for (int i=0; i<=R_max; i++) Q[j][i]<= Q[j-1][i]; end
	   COPY_R :  begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i];  R[j][0]<='0;  end                  
	 endcase           
    if (mode>2'd1)
       for (int j=2*4; j<2*5; j++)
	 case (next_state[j]) 
	   CALC:     begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i-1] ^ gf8_mult_comp (Q[j-1][i-1], M[j]); R[j][0]<='0; 
                	   if (swap[j]) begin for (int i=0; i<R_max; i++) Q[j][i]<= R[j-1][i]; Q[j][R_max]<= inv_lead[j]; end
			   else  for (int i=0; i<=R_max; i++) Q[j][i]<= Q[j-1][i]; 
		     end
	   SHIFT_Q:  begin for (int i=1; i<R_max; i++) {Q[j][i],R[j][i]}<= {Q[j-1][i-1],R[j-1][i-1]};  {Q[j][0],R[j][0]}<='0; {Q[j][R_max],R[j][R_max]}<= {inv_lead[j],R[j-1][R_max-1]};	 end	
	   SHIFT_R:  begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i-1];  R[j][0]<='0; for (int i=0; i<=R_max; i++) Q[j][i]<= Q[j-1][i]; end
	   COPY_R :  begin for (int i=1; i<=R_max; i++) R[j][i]<= R[j-1][i];  R[j][0]<='0;  end                  
	 endcase           
  end 
      
// S:  8  7  6  5  4  3  2  1  0
// R: 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
//    |<-   O    ->| |<-     L     ->|

// S:  6  5  4  3  2  1  0
// R: 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
//    |<-  O  ->|           |<-   L   ->|

// S:  4  3  2  1  0
// R: 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
//    |<  O >|                    |<-  L ->|


  assign {O,L} = mode[1]? R[2*5-1][3*5-:11] : (mode[0]? {8'h00,R[2*4-1][3*5-:4],8'h00, R[2*4-1][8:4]} : {16'h0000, R[2*3-1][3*5-:3],16'h0000, R[2*3-1][6:3]});  
    
  always_comb
    casex (mode)
      2'b00 : begin
		//{O,L} = R[2*3-1][3*5-:7];
		no_error = no_error_local[2*3-1]; 
		S0 = S0_local[2*3-1]; 
		last_symbol_error = last_symbol_error_local[2*3-1]; 
	      end 
      2'b01 : begin
		//{O,L} = R[2*4-1][3*5-:9];
		no_error = no_error_local[2*4-1]; 
		S0 = S0_local[2*4-1]; 
		last_symbol_error = last_symbol_error_local[2*4-1]; 
	      end 
      2'b1x : begin
		//{O,L} = R[2*5-1][3*5-:11]; 
		no_error = no_error_local[2*5-1]; 
		S0 = S0_local[2*5-1]; 
		last_symbol_error = last_symbol_error_local[2*5-1]; 
	      end 
    endcase
          
  always_ff @(posedge clk, negedge rstn ) 
    if (!rstn) ready <= 1'b0;
    else ready <= (mode[1])? proc_vld[2*5-1] : ((mode[0])? proc_vld[2*4-1] : proc_vld[2*3-1]);
             	      


endmodule



	      
	      
module ec #(parameter t=5, w=8, n=256) (
// inputs
  input clk,
  input rstn,
  input init,
  input no_error,
  input last_symbol_error,
  input [t:0][w-1:0] L,
  input [t-1:0][w-1:0] O,
  input [w-1:0] S0,  
// outputs
  output logic [n-1:0][w-1:0] ecp,
  output logic ready,
  // performance monitor / statistic
  output logic [n-1:0] pm_symbol_err,
  output logic pm_no_error,
  output logic pm_1_error,
  output logic pm_2_error,
  output logic pm_3_error,
  output logic pm_4_error,
  output logic pm_5_error,
  output logic pm_fail
  
  );
  
// error correction    
  logic [n-2:0][w-1:0] chien, chien_odd;
  logic [n-2:0][w-1:0] forney;
  logic [n-2:0] zero;
  logic [n-2:0][w-1:0] corr_pattern;
  logic init_rt;
  logic no_error_rt;
  logic last_symbol_error_rt;
  logic [w-1:0] S0_rt;
  logic [2:0] L_poly_deg;

always_comb for (int i=0; i<n-1; i++) chien[i] = gf8_mult_comp (L[5],H[5][i]) ^ 
                                                 gf8_mult_comp (L[4],H[4][i]) ^ 
						 gf8_mult_comp (L[3],H[3][i]) ^ 
						 gf8_mult_comp (L[2],H[2][i]) ^  
						 gf8_mult_comp (L[1],H[1][i]) ^ 
						 gf8_mult_comp (L[0],H[0][i]);
  

always_ff @(posedge clk, negedge rstn) 
  if (!rstn) begin
   
    for (int i=0; i<n-1; i++) chien_odd[i]  <= '0;
    for (int i=0; i<n-1; i++) forney[i]     <= '0;
    for (int i=0; i<n-1; i++) zero[i] <= '0; 
    S0_rt  <= '0;
    no_error_rt  <= '0;
    last_symbol_error_rt  <= '0;
    init_rt  <= '0;
    L_poly_deg <= '0;
  end 
  else begin

    if (init)   begin 
      
      if (!no_error & !last_symbol_error)   begin
	for (int i=0; i<n-1; i++) chien_odd[i]  <= gf8_mult_comp (L[5],H[5][i]) ^ 
                                                   gf8_mult_comp (L[3],H[3][i]) ^ 
						   gf8_mult_comp (L[1],H[1][i]);

	for (int i=0; i<n-1; i++) forney[i]     <= gf8_mult_comp (O[4],H[4][i]) ^ 
                                                   gf8_mult_comp (O[3],H[3][i]) ^ 
						   gf8_mult_comp (O[2],H[2][i]) ^ 
						   gf8_mult_comp (O[1],H[1][i]) ^  
						   gf8_mult_comp (O[0],H[0][i]);


      end
      
     for (int i=0; i<n-1; i++) zero[i] <= (!no_error & !last_symbol_error) & (chien[i] == 8'h00); 
      
      S0_rt  <= S0;
      no_error_rt  <= no_error;
      last_symbol_error_rt  <= last_symbol_error;
      L_poly_deg <= poly_degree(L);
    end
    
    init_rt  <= init;
   
  end 



     

  logic [2:0] err_num;
  

always_comb begin

   for (int i=0; i<n-1; i++) corr_pattern[i] = (zero[i] & (!no_error_rt  & !last_symbol_error_rt))? gf8_div_comp (forney[i], chien_odd[i]): 8'h00;
   
   for (int i=0; i<254; i++) begin ecp[i] = corr_pattern[253-i];  pm_symbol_err[i] = zero[253-i]; end
   ecp[254] = corr_pattern[254];
   pm_symbol_err[254] = zero[254];     

   ecp[255] = '0;
   begin ecp[255] = S0_rt; for (int i=0; i<n-1; i++) ecp[255] ^= corr_pattern[i]; end
   pm_symbol_err[255] = |ecp[255];
   
   err_num = root_num (zero[n-2:0]);
   

   ready = init_rt;
   
   pm_no_error = no_error_rt;
   pm_1_error = !no_error_rt & (L_poly_deg==err_num) & (L_poly_deg == 3'd1);
   pm_2_error = !no_error_rt & (L_poly_deg==err_num) & (L_poly_deg == 3'd2);
   pm_3_error = !no_error_rt & (L_poly_deg==err_num) & (L_poly_deg == 3'd3);
   pm_4_error = !no_error_rt & (L_poly_deg==err_num) & (L_poly_deg == 3'd4);
   pm_5_error = !no_error_rt & (L_poly_deg==err_num) & (L_poly_deg == 3'd5);
   
   if (pm_symbol_err[255]) begin // SCO3-940 csymes - fixes error wit hincorrect cnt_pm_error incrementing
   //if (pm_symbol_err[254]) begin
     if (pm_4_error) begin pm_4_error = 1'b0; pm_5_error = 1'b1; end
     if (pm_3_error) begin pm_3_error = 1'b0; pm_4_error = 1'b1; end
     if (pm_2_error) begin pm_2_error = 1'b0; pm_3_error = 1'b1; end
     if (pm_1_error) begin pm_1_error = 1'b0; pm_2_error = 1'b1; end
   
   end
   
   pm_fail =    !no_error_rt & (L_poly_deg!=err_num);
   if (last_symbol_error_rt) begin pm_1_error = 1'b1; pm_fail = 1'b0; end


end      

function automatic [2:0] poly_degree (input [t:0][w-1:0] poly);

  casex ({|poly[5], |poly[4], |poly[3], |poly[2], |poly[1]}) 
    5'b1xxxx : return 3'd5;
    5'b01xxx : return 3'd4;
    5'b001xx : return 3'd3;
    5'b0001x : return 3'd2;
    5'b00001 : return 3'd1;
    default : return 3'd0;
  endcase  
endfunction  

function automatic [2:0] root_num (input [n-2:0] z);

  logic [31:0][3:0] sum_8;
  logic [7:0] sum_128;  
  
  for (int i=0; i<31; i++) sum_8[i] = z[i*8+7]+z[i*8+6]+z[i*8+5]+z[i*8+4]+z[i*8+3]+z[i*8+2]+z[i*8+1]+z[i*8+0];
  sum_8[31] = z[31*8+6]+z[31*8+5]+z[31*8+4]+z[31*8+3]+z[31*8+2]+z[31*8+1]+z[31*8+0];
  
  sum_128 = sum_8[31][2:0] + sum_8[30][2:0] + sum_8[29][2:0] + sum_8[28][2:0] + sum_8[27][2:0] + sum_8[26][2:0] + sum_8[25][2:0] + sum_8[24][2:0] + 
            sum_8[23][2:0] + sum_8[22][2:0] + sum_8[21][2:0] + sum_8[20][2:0] + sum_8[19][2:0] + sum_8[18][2:0] + sum_8[17][2:0] + sum_8[16][2:0] + 
	    sum_8[15][2:0] + sum_8[14][2:0] + sum_8[13][2:0] + sum_8[12][2:0] + sum_8[11][2:0] + sum_8[10][2:0] + sum_8[ 9][2:0] + sum_8[ 8][2:0] + 
            sum_8[ 7][2:0] + sum_8[ 6][2:0] + sum_8[ 5][2:0] + sum_8[ 4][2:0] + sum_8[ 3][2:0] + sum_8[ 2][2:0] + sum_8[ 1][2:0] + sum_8[ 0][2:0];

  return sum_128[2:0];
  
endfunction  
           	      
endmodule	      

  	      

module rs256_dec #(parameter t=5, w=8, n=256, localparam FIFO_DEPTH = 10) (
// inputs
  input clk,
  input rstn,
  // config  
  input          [1:0] mode, // 00 : t=3 //  01 : t=4 // 1x : t=5 //
  // data
  input [n-1:0][w-1:0] din,
  input                din_vld,
  
// outputs
  output logic [n-1:0][w-1:0] dout,
  output logic                dout_vld,
// debug - captured at ea_ready
  output logic [t:0][w-1:0] pm_loc,
  output logic [t-1:0][w-1:0] pm_out,
  output logic [w-1:0] pm_syn,
// debug - internal wires promote to output
  output logic [FIFO_DEPTH-1:0] fifo_wr_ptr,
  output logic [FIFO_DEPTH-1:0] fifo_rd_ptr,
  // performance monitor / statistic   counters
  output logic       [n-1:0] pm_symbol_err,
  output logic 		     pm_no_error,
  output logic 		     pm_1_error,
  output logic 		     pm_2_error,
  output logic 		     pm_3_error,
  output logic 		     pm_4_error,
  output logic 		     pm_5_error,
  output logic               pm_fail
  );
  

  
 logic [2*t-1:0][w-1:0] S;
 logic S_vld;

 logic [t:0][w-1:0] L;
 logic [t-1:0][w-1:0] O;
 logic [w-1:0] S0;

 always_ff @(posedge clk, negedge  rstn)
  if (!rstn) begin
    S_vld <= 1'b0;
    S <= '0;
  end      
  else begin
    S_vld <= din_vld;
    if (din_vld) S <=  s_calc (din, mode);
  end      
  
 logic ea_ready;
 logic ea_no_error;

 logic ea_last_symbol_error;

 
 ea_unr ea(
// inputs
  .clk      ( clk  ),
  .rstn     ( rstn ),
  .init     ( S_vld ),
  .S        ( S    ),
  .mode     ( mode ),  
// outputs
  .ready    ( ea_ready ),
  .no_error ( ea_no_error ),
  .last_symbol_error ( ea_last_symbol_error ),
  .L        ( L ),
  .O        ( O ),
  .S0       ( S0 )
  );

logic [n-1:0][w-1:0] ecp;
logic                ecp_ready;
logic 		     ecp_no_error_flag;
logic 		     ecp_1_error_flag;
logic 		     ecp_2_error_flag;
logic 		     ecp_3_error_flag;
logic 		     ecp_4_error_flag;
logic 		     ecp_5_error_flag;
logic 		     ecp_fail_flag;
logic       [n-1:0]  ecp_symbol_err;

logic   [n-1:0][w-1:0] fifo [FIFO_DEPTH-1:0];
logic                  fifo_pop;
  
ec  ec //#(.t(t), .w(w)) ec
 (
// inputs
  .clk      	     ( clk  ),
  .rstn     ( rstn ),
  .init     	     ( ea_ready     ),
  .no_error          ( ea_no_error ),
  .last_symbol_error ( ea_last_symbol_error ),
  .L        	     ( L ),
  .O        	     ( O ),
  .S0                ( S0 ),  
// outputs
  .ecp               ( ecp ),
  .ready             ( ecp_ready ),
  .pm_symbol_err     ( ecp_symbol_err ),
  .pm_no_error       ( ecp_no_error_flag ),
  .pm_1_error        ( ecp_1_error_flag  ),
  .pm_2_error        ( ecp_2_error_flag  ),
  .pm_3_error        ( ecp_3_error_flag  ),
  .pm_4_error        ( ecp_4_error_flag  ),
  .pm_5_error        ( ecp_5_error_flag  ),
  .pm_fail           ( ecp_fail_flag ) 

  );  

always_comb fifo_pop = ecp_ready;
always_ff @(posedge clk) for (int i=0; i<FIFO_DEPTH; i++) if (din_vld & fifo_wr_ptr[i]) fifo[i] <= din;

always_ff @(posedge clk, negedge rstn)
  if (!rstn)        fifo_wr_ptr <= 'h1;
  else if (din_vld) fifo_wr_ptr <= {fifo_wr_ptr[FIFO_DEPTH-2:0],fifo_wr_ptr[FIFO_DEPTH-1]};

always_ff @(posedge clk, negedge rstn)
  if (!rstn)         fifo_rd_ptr <= 'h1;
  else if (fifo_pop) fifo_rd_ptr <= {fifo_rd_ptr[FIFO_DEPTH-2:0],fifo_rd_ptr[FIFO_DEPTH-1]};

logic  [255:0][7:0]  fifo_out;
always_comb begin
  fifo_out = '0;
  for (int i=0; i<FIFO_DEPTH; i++) if (fifo_rd_ptr[i]) fifo_out |= fifo[i];
end
 
always_ff @(posedge clk, negedge rstn) 
  if (!rstn)  begin
    dout_vld <= '0;
    dout <= '0;
    pm_no_error <= '0;
    pm_symbol_err <= '0;
    pm_1_error <= '0;
    pm_2_error <= '0;
    pm_3_error <= '0;
    pm_4_error <= '0;
    pm_5_error <= '0;
    pm_fail <= '0; 
    //sts for debug
    pm_loc <= '0;
    pm_out <= '0;
    pm_syn <= '0;

  end          	      
  else  begin
    dout_vld <= ecp_ready;
    if (ecp_ready) begin 
      dout <= ecp ^ fifo_out;
      pm_no_error <= ecp_no_error_flag;
      pm_symbol_err <= ecp_symbol_err;
      pm_1_error <= ecp_1_error_flag;
      pm_2_error <= ecp_2_error_flag;
      pm_3_error <= ecp_3_error_flag;
      pm_4_error <= ecp_4_error_flag;
      pm_5_error <= ecp_5_error_flag;
      pm_fail <= ecp_fail_flag; 
      //sts for debug
      pm_loc <= L;
      pm_out <= O;
      pm_syn <= S0;
    end
  end          	      


  
function automatic [2*t-1:0][w-1:0] s_calc (input [n-1:0][w-1:0] CW, [1:0] mode);
   logic  [2*t-1:0][w-1:0] S;
   S = '0;
    for (int x=0; x<n ; x++) begin
      for (int y=0; y<2*3 ; y++) S[y] ^= gf8_mult_comp(CW[x],H [y][x]);
      if (|mode)   for (int y=2*3; y<2*4 ; y++) S[y] ^= gf8_mult_comp(CW[x],H [y][x]);
      if (mode[1]) for (int y=2*4; y<2*5 ; y++) S[y] ^= gf8_mult_comp(CW[x],H [y][x]);
      
    end  
   return S;

endfunction   


endmodule	      
