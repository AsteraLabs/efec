///////////////////////////////////////////////////////////////////////////
////
//// Copyright (c) AsteraLabs Inc. All rights reserved.
//// AsteraLabs Confidential Property
//// =============================================================================
////	CONFIDENTIAL / PROPRIETARY
////	This document contains confidential and proprietary information of Astera Labs. 
////	It is intended solely for the use of authorized personnel. 
////	Any unauthorized review, use, disclosure, or distribution is strictly prohibited.
////
//// Filename: aip_xplh_efec_enc.sv
//// Author  : Volodymyr Shvydun
//// Details : eFEC encoder
//// Description :
//////////////////////////////////////////////////////////////////////////////
`ifndef __AIP_XPLH_EFEC_ENC_V__
`define __AIP_XPLH_EFEC_ENC_V__

module aip_xplh_efec_enc
#(
  parameter P_FLIT_WD = 2048
) (
  // Inputs
  input                     clk,
  input                     rst_n,
  // config  
  input               [1:0] mode, // 00 : t=3 //  01 : t=4 // 1x : t=5 //
    //data
  input [P_FLIT_WD - 1 : 0] data_in,    // Data
  input                     eof,        // End of Flit
  input                     halt_in,    // Halt from lower layer
  // Outputs
  output  logic [(6+8)*8-1 : 0]    fec_enc_out // 6-Bytes EEC + 8-Bytes CRC packed as {ECC, CRC}
);


localparam t = 5;
localparam w = 8;

logic [2*t-1:0][w-1:0] P;
logic [2*t-1:0][w-1:0] P_rt;

p_gen p_gen (
    // inputs
    .din  ( data_in ),
    .mode ( mode ), // 00 : t=3 //  01 : t=4 // 1x : t=5 //
    // outputs
    .P ( P )
);


always_ff @(posedge clk, negedge rst_n) begin : fec_out_PROC
    if (!rst_n) P_rt <= '0;
    else if(!halt_in) begin
      // Clear the accumulation at the end of Flit
      if(eof) begin
        P_rt <= '0;
      end else begin
	casex (mode)
	  2'b00 :  P_rt[5:0] <=  P[5:0] ^ P_rt[5:0];
	  2'b01 :  P_rt[7:0] <=  P[7:0] ^ P_rt[7:0]; 
	  2'b1x :  P_rt[9:0] <=  P[9:0] ^ P_rt[9:0];   
	endcase
      end
    end  
end : fec_out_PROC

always_comb 
    casex (mode)
      2'b00 : fec_enc_out = {P[5:0] ^ P_rt[5:0], data_in[250*8-1:242*8]};
      2'b01 : fec_enc_out = {P[7:0] ^ P_rt[7:0], data_in[248*8-1:242*8]}; 
      2'b1x : fec_enc_out = {P[9:0] ^ P_rt[9:0], data_in[246*8-1:242*8]};   
    endcase

endmodule

module p_gen #(
    parameter n=256, k=250, w=8, t=5
) (
    // inputs
    input [n-1:0][w-1:0] din,
    input          [1:0] mode, // 00 : t=3 //  01 : t=4 // 1x : t=5 //
    // outputs
    output logic [2*t-1:0][w-1:0] P
);
  

    logic [2*t-1:0][w-1:0] PP;

always_comb begin
     P = '0;
     PP = '0;
     for (int y=0; y<6; y++) for (int x=0; x<246; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
     
     if (mode>2'd0) for (int y=6; y< 8; y++)  for (int x=0; x<246; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
     if (mode>2'd1) for (int y=8; y<10; y++)  for (int x=0; x<246; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
     
     case (mode)
       2'b00 : for (int y=0; y< 6; y++)  for (int x=246; x<250; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
       2'b01 : for (int y=0; y< 8; y++)  for (int x=246; x<248; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
     endcase


     casex (mode)
       2'b00 : begin	 
	 PP[2] ^= PP[1];
	 PP[3] ^= PP[1];
	 PP[4] ^= PP[1];
	 PP[5] ^= PP[1];

     //------------------ 3
	 PP[2]  = gf8_mult_comp(PP[2], 8'h02);

	 PP[3] ^= gf8_mult_comp(PP[2], 8'h99);
	 PP[4] ^= gf8_mult_comp(PP[2], 8'h04);
	 PP[5] ^= gf8_mult_comp(PP[2], 8'h49);
     //------------------ 2
	 PP[3]  = gf8_mult_comp(PP[3], 8'h08);       

	 PP[4] ^= gf8_mult_comp(PP[3], 8'h01);
	 PP[5] ^= gf8_mult_comp(PP[3], 8'h18);

     //------------------ 1
	 PP[4]  = gf8_mult_comp(PP[4], 8'h8c); 

	 PP[5] ^= gf8_mult_comp(PP[4], 8'hff);

     //------------------ 0
	 PP[5]  = gf8_mult_comp(PP[5], 8'hb7); 

	 P[0] = PP[5];
	 P[1] = PP[4] ^ gf8_mult_comp(P[0], 8'h94);
	 P[2] = PP[3] ^ gf8_mult_comp(P[0], 8'h02) ^ gf8_mult_comp(P[1], 8'h80);
	 P[3] = PP[2] ^ gf8_mult_comp(P[0], 8'h0f) ^ gf8_mult_comp(P[1], 8'h84) ^ gf8_mult_comp(P[2], 8'h09);
	 P[4] = PP[1] ^ gf8_mult_comp(P[0], 8'h14) ^ gf8_mult_comp(P[1], 8'h89) ^ gf8_mult_comp(P[2], 8'h19) ^ gf8_mult_comp(P[3], 8'h10);
	 P[5] = PP[0] ^               P[0]         ^               P[1]         ^               P[2]         ^               P[3]         ^               P[4];
       end
       2'b01 : begin	 
	  PP[2] ^= PP[1];	  
	  PP[3] ^= PP[1];	  
	  PP[4] ^= PP[1];	  
	  PP[5] ^= PP[1];	  
	  PP[6] ^= PP[1];	  
	  PP[7] ^= PP[1];	  
     //------------------ 5      

	  PP[2] = gf8_mult_comp(PP[2], 8'h02);   

	  PP[3] ^= gf8_mult_comp(PP[2], 8'h99);
	  PP[4] ^= gf8_mult_comp(PP[2], 8'h04);
	  PP[5] ^= gf8_mult_comp(PP[2], 8'h49);
	  PP[6] ^= gf8_mult_comp(PP[2], 8'hdb);	
	  PP[7] ^= gf8_mult_comp(PP[2], 8'h66);	

     //------------------ 4      

	  PP[3] = gf8_mult_comp(PP[3], 8'h08);   

	  PP[4] ^= gf8_mult_comp(PP[3], 8'h01);
	  PP[5] ^= gf8_mult_comp(PP[3], 8'h18);
	  PP[6] ^= gf8_mult_comp(PP[3], 8'h12);
	  PP[7] ^= gf8_mult_comp(PP[3], 8'h4e);

     //------------------ 3      

	  PP[4] = gf8_mult_comp(PP[4], 8'h8c);   

	  PP[5] ^= gf8_mult_comp(PP[4], 8'hff);
	  PP[6] ^= gf8_mult_comp(PP[4], 8'he6);  
	  PP[7] ^= gf8_mult_comp(PP[4], 8'h58);  


     //------------------ 2      

	  PP[5] = gf8_mult_comp(PP[5], 8'hb7);   

	  PP[6] ^= gf8_mult_comp(PP[5], 8'h71);
	  PP[7] ^= gf8_mult_comp(PP[5], 8'h2c);


     //------------------ 1      

	  PP[6] = gf8_mult_comp(PP[6], 8'heb);   

	  PP[7] ^= gf8_mult_comp(PP[6], 8'h2a);

     //------------------ 0      
	  PP[7] = gf8_mult_comp(PP[7], 8'h66);   


	  P[0] = PP[7];
	  P[1] = PP[6] ^ gf8_mult_comp(P[0], 8'h06);
	  P[2] = PP[5] ^ gf8_mult_comp(P[0], 8'hce) ^ gf8_mult_comp(P[1], 8'hcd);
	  P[3] = PP[4] ^ gf8_mult_comp(P[0], 8'h95) ^ gf8_mult_comp(P[1], 8'hfc) ^ gf8_mult_comp(P[2], 8'h94);
	  P[4] = PP[3] ^ gf8_mult_comp(P[0], 8'h41) ^ gf8_mult_comp(P[1], 8'h3e) ^ gf8_mult_comp(P[2], 8'h02) ^ gf8_mult_comp(P[3], 8'h80);
	  P[5] = PP[2] ^ gf8_mult_comp(P[0], 8'h6b) ^ gf8_mult_comp(P[1], 8'hea) ^ gf8_mult_comp(P[2], 8'h0f) ^ gf8_mult_comp(P[3], 8'h84) ^ gf8_mult_comp(P[4], 8'h09);
	  P[6] = PP[1] ^ gf8_mult_comp(P[0], 8'hcb) ^ gf8_mult_comp(P[1], 8'h59) ^ gf8_mult_comp(P[2], 8'h14) ^ gf8_mult_comp(P[3], 8'h89) ^ gf8_mult_comp(P[4], 8'h19) ^ gf8_mult_comp(P[5], 8'h10);

	  P[7] = PP[0] ^               P[0]         ^               P[1]         ^               P[2]         ^               P[3]         ^               P[4]         ^               P[5]         ^               P[6];

       end
       2'b1x : begin	 
     //------------------ 8       
	 PP[2] ^= PP[1];
	 PP[3] ^= PP[1];
	 PP[4] ^= PP[1];
	 PP[5] ^= PP[1];
	 PP[6] ^= PP[1];
	 PP[7] ^= PP[1];
	 PP[8] ^= PP[1];
	 PP[9] ^= PP[1];
     //------------------ 7
	 PP[2]  = gf8_mult_comp(PP[2], 8'h02);

	 PP[3] ^= gf8_mult_comp(PP[2], 8'h99);
	 PP[4] ^= gf8_mult_comp(PP[2], 8'h04);
	 PP[5] ^= gf8_mult_comp(PP[2], 8'h49);
	 PP[6] ^= gf8_mult_comp(PP[2], 8'hdb); 
	 PP[7] ^= gf8_mult_comp(PP[2], 8'h66); 
	 PP[8] ^= gf8_mult_comp(PP[2], 8'h0a); 
	 PP[9] ^= gf8_mult_comp(PP[2], 8'ha9); 
     //------------------ 6
	 PP[3]  = gf8_mult_comp(PP[3], 8'h08);       

	 PP[4] ^= gf8_mult_comp(PP[3], 8'h01);
	 PP[5] ^= gf8_mult_comp(PP[3], 8'h18);
	 PP[6] ^= gf8_mult_comp(PP[3], 8'h12);      
	 PP[7] ^= gf8_mult_comp(PP[3], 8'h4e);      
	 PP[8] ^= gf8_mult_comp(PP[3], 8'h0d);      
	 PP[9] ^= gf8_mult_comp(PP[3], 8'hd4);      

     //------------------ 5
	 PP[4]  = gf8_mult_comp(PP[4], 8'h8c); 

	 PP[5] ^= gf8_mult_comp(PP[4], 8'hff);
	 PP[6] ^= gf8_mult_comp(PP[4], 8'he6);      
	 PP[7] ^= gf8_mult_comp(PP[4], 8'h58);      
	 PP[8] ^= gf8_mult_comp(PP[4], 8'hf4);      
	 PP[9] ^= gf8_mult_comp(PP[4], 8'h82);      

     //------------------ 4
	 PP[5]  = gf8_mult_comp(PP[5], 8'hb7); 

	 PP[6] ^= gf8_mult_comp(PP[5], 8'h71);      
	 PP[7] ^= gf8_mult_comp(PP[5], 8'h2c);      
	 PP[8] ^= gf8_mult_comp(PP[5], 8'h5d);      
	 PP[9] ^= gf8_mult_comp(PP[5], 8'ha7);      

     //------------------ 3
	 PP[6]  = gf8_mult_comp(PP[6], 8'heb); 

	 PP[7] ^= gf8_mult_comp(PP[6], 8'h2a);      
	 PP[8] ^= gf8_mult_comp(PP[6], 8'h9e);      
	 PP[9] ^= gf8_mult_comp(PP[6], 8'ha3);      

     //------------------ 2
	 PP[7]  = gf8_mult_comp(PP[7], 8'h66); 

	 PP[8] ^= gf8_mult_comp(PP[7], 8'hc0);      
	 PP[9] ^= gf8_mult_comp(PP[7], 8'hde);      

     //------------------ 1
	 PP[8]  = gf8_mult_comp(PP[8], 8'hf4); 

	 PP[9] ^= gf8_mult_comp(PP[8], 8'h0d);	

     //------------------ 0

	 PP[9]  = gf8_mult_comp(PP[9], 8'h67); 


	 P[0] = PP[9];
	 P[1] = PP[8] ^ gf8_mult_comp(P[0], 8'h6a);
	 P[2] = PP[7] ^ gf8_mult_comp(P[0], 8'h52) ^ gf8_mult_comp(P[1], 8'h70);
	 P[3] = PP[6] ^ gf8_mult_comp(P[0], 8'h78) ^ gf8_mult_comp(P[1], 8'h21) ^ gf8_mult_comp(P[2], 8'h06);
	 P[4] = PP[5] ^ gf8_mult_comp(P[0], 8'h54) ^ gf8_mult_comp(P[1], 8'h5f) ^ gf8_mult_comp(P[2], 8'hce) ^ gf8_mult_comp(P[3], 8'hcd);
	 P[5] = PP[4] ^ gf8_mult_comp(P[0], 8'h5e) ^ gf8_mult_comp(P[1], 8'hab) ^ gf8_mult_comp(P[2], 8'h95) ^ gf8_mult_comp(P[3], 8'hfc) ^ gf8_mult_comp(P[4], 8'h94);
	 P[6] = PP[3] ^ gf8_mult_comp(P[0], 8'h03) ^ gf8_mult_comp(P[1], 8'ha1) ^ gf8_mult_comp(P[2], 8'h41) ^ gf8_mult_comp(P[3], 8'h3e) ^ gf8_mult_comp(P[4], 8'h02) ^ gf8_mult_comp(P[5], 8'h80);
	 P[7] = PP[2] ^ gf8_mult_comp(P[0], 8'h05) ^ gf8_mult_comp(P[1], 8'h24) ^ gf8_mult_comp(P[2], 8'h6b) ^ gf8_mult_comp(P[3], 8'hea) ^ gf8_mult_comp(P[4], 8'h0f) ^ gf8_mult_comp(P[5], 8'h84) ^ gf8_mult_comp(P[6], 8'h09);
	 P[8] = PP[1] ^ gf8_mult_comp(P[0], 8'h1a) ^ gf8_mult_comp(P[1], 8'h76) ^ gf8_mult_comp(P[2], 8'hcb) ^ gf8_mult_comp(P[3], 8'h59) ^ gf8_mult_comp(P[4], 8'h14) ^ gf8_mult_comp(P[5], 8'h89) ^ gf8_mult_comp(P[6], 8'h19) ^ gf8_mult_comp(P[7], 8'h10);
	 P[9] = PP[0] ^ P[0] ^ P[1] ^ P[2] ^ P[3] ^ P[4] ^ P[5] ^ P[6] ^ P[7] ^ P[8];


       end
     endcase     

end
  




    
endmodule
`endif
