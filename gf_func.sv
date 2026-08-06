// =============================================================================
//	CONFIDENTIAL / PROPRIETARY
//	This document contains confidential and proprietary information of Astera Labs. 
//	It is intended solely for the use of authorized personnel. 
//	Any unauthorized review, use, disclosure, or distribution is strictly prohibited.
//
parameter logic [256-1:0][7:0] H [0:9] = '{
{8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01 }, 
{8'h00, 8'h01, 8'h10, 8'h19, 8'h89, 8'h14, 8'h59, 8'hcb, 8'h76, 8'h1a, 8'hb9, 8'h2c, 8'he1, 8'hf7, 8'h8e, 8'h64, 8'h23, 8'h11, 8'h09, 8'h90, 8'h9d, 8'h4d, 8'h92, 8'hbd, 8'h6c, 8'ha3, 8'h95, 8'hcd, 8'h16, 8'h79, 8'hea, 8'h47, 8'h32, 8'h18, 8'h99, 8'h0d, 8'hd0, 8'hdf, 8'h2f, 8'hd1, 8'hcf, 8'h36, 8'h58, 8'hdb, 8'h6f, 8'h93, 8'had, 8'h75, 8'h2a, 8'h81, 8'h94, 8'hdd, 8'h0f, 8'hf0, 8'hfe, 8'h1e, 8'hf9, 8'h6e, 8'h83, 8'hb4, 8'hfc, 8'h3e, 8'hd8, 8'h5f, 8'hab, 8'h15, 8'h49, 8'hd2, 8'hff, 8'h0e, 8'he0, 8'he7, 8'h97, 8'hed, 8'h37, 8'h48, 8'hc2, 8'he6, 8'h87, 8'hf4, 8'hbe, 8'h5c, 8'h9b, 8'h2d, 8'hf1, 8'hee, 8'h07, 8'h70, 8'h7a, 8'hda, 8'h7f, 8'h8a, 8'h24, 8'h61, 8'h73, 8'h4a, 8'he2, 8'hc7, 8'hb6, 8'hdc, 8'h1f, 8'he9, 8'h77, 8'h0a, 8'ha0, 8'ha5, 8'hf5, 8'hae, 8'h45, 8'h12, 8'h39, 8'ha8, 8'h25, 8'h71, 8'h6a, 8'hc3, 8'hf6, 8'h9e, 8'h7d, 8'haa, 8'h05, 8'h50, 8'h5b, 8'heb, 8'h57, 8'h2b, 8'h91, 8'h8d, 8'h54, 8'h1b, 8'ha9, 8'h35, 8'h68, 8'he3, 8'hd7, 8'haf, 8'h55, 8'h0b, 8'hb0, 8'hbc, 8'h7c, 8'hba, 8'h1c, 8'hd9, 8'h4f, 8'hb2, 8'h9c, 8'h5d, 8'h8b, 8'h34, 8'h78, 8'hfa, 8'h5e, 8'hbb, 8'h0c, 8'hc0, 8'hc6, 8'ha6, 8'hc5, 8'h96, 8'hfd, 8'h2e, 8'hc1, 8'hd6, 8'hbf, 8'h4c, 8'h82, 8'ha4, 8'he5, 8'hb7, 8'hcc, 8'h06, 8'h60, 8'h63, 8'h53, 8'h6b, 8'hd3, 8'hef, 8'h17, 8'h69, 8'hf3, 8'hce, 8'h26, 8'h41, 8'h52, 8'h7b, 8'hca, 8'h66, 8'h03, 8'h30, 8'h38, 8'hb8, 8'h3c, 8'hf8, 8'h7e, 8'h9a, 8'h3d, 8'he8, 8'h67, 8'h13, 8'h29, 8'hb1, 8'hac, 8'h65, 8'h33, 8'h08, 8'h80, 8'h84, 8'hc4, 8'h86, 8'he4, 8'ha7, 8'hd5, 8'h8f, 8'h74, 8'h3a, 8'h98, 8'h1d, 8'hc9, 8'h56, 8'h3b, 8'h88, 8'h04, 8'h40, 8'h42, 8'h62, 8'h43, 8'h72, 8'h5a, 8'hfb, 8'h4e, 8'ha2, 8'h85, 8'hd4, 8'h9f, 8'h6d, 8'hb3, 8'h8c, 8'h44, 8'h02, 8'h20, 8'h21, 8'h31, 8'h28, 8'ha1, 8'hb5, 8'hec, 8'h27, 8'h51, 8'h4b, 8'hf2, 8'hde, 8'h3f, 8'hc8, 8'h46, 8'h22 },
{8'h00, 8'h01, 8'h19, 8'h14, 8'hcb, 8'h1a, 8'h2c, 8'hf7, 8'h64, 8'h11, 8'h90, 8'h4d, 8'hbd, 8'ha3, 8'hcd, 8'h79, 8'h47, 8'h18, 8'h0d, 8'hdf, 8'hd1, 8'h36, 8'hdb, 8'h93, 8'h75, 8'h81, 8'hdd, 8'hf0, 8'h1e, 8'h6e, 8'hb4, 8'h3e, 8'h5f, 8'h15, 8'hd2, 8'h0e, 8'he7, 8'hed, 8'h48, 8'he6, 8'hf4, 8'h5c, 8'h2d, 8'hee, 8'h70, 8'hda, 8'h8a, 8'h61, 8'h4a, 8'hc7, 8'hdc, 8'he9, 8'h0a, 8'ha5, 8'hae, 8'h12, 8'ha8, 8'h71, 8'hc3, 8'h9e, 8'haa, 8'h50, 8'heb, 8'h2b, 8'h8d, 8'h1b, 8'h35, 8'he3, 8'haf, 8'h0b, 8'hbc, 8'hba, 8'hd9, 8'hb2, 8'h5d, 8'h34, 8'hfa, 8'hbb, 8'hc0, 8'ha6, 8'h96, 8'h2e, 8'hd6, 8'h4c, 8'ha4, 8'hb7, 8'h06, 8'h63, 8'h6b, 8'hef, 8'h69, 8'hce, 8'h41, 8'h7b, 8'h66, 8'h30, 8'hb8, 8'hf8, 8'h9a, 8'he8, 8'h13, 8'hb1, 8'h65, 8'h08, 8'h84, 8'h86, 8'ha7, 8'h8f, 8'h3a, 8'h1d, 8'h56, 8'h88, 8'h40, 8'h62, 8'h72, 8'hfb, 8'ha2, 8'hd4, 8'h6d, 8'h8c, 8'h02, 8'h21, 8'h28, 8'hb5, 8'h27, 8'h4b, 8'hde, 8'hc8, 8'h22, 8'h10, 8'h89, 8'h59, 8'h76, 8'hb9, 8'he1, 8'h8e, 8'h23, 8'h09, 8'h9d, 8'h92, 8'h6c, 8'h95, 8'h16, 8'hea, 8'h32, 8'h99, 8'hd0, 8'h2f, 8'hcf, 8'h58, 8'h6f, 8'had, 8'h2a, 8'h94, 8'h0f, 8'hfe, 8'hf9, 8'h83, 8'hfc, 8'hd8, 8'hab, 8'h49, 8'hff, 8'he0, 8'h97, 8'h37, 8'hc2, 8'h87, 8'hbe, 8'h9b, 8'hf1, 8'h07, 8'h7a, 8'h7f, 8'h24, 8'h73, 8'he2, 8'hb6, 8'h1f, 8'h77, 8'ha0, 8'hf5, 8'h45, 8'h39, 8'h25, 8'h6a, 8'hf6, 8'h7d, 8'h05, 8'h5b, 8'h57, 8'h91, 8'h54, 8'ha9, 8'h68, 8'hd7, 8'h55, 8'hb0, 8'h7c, 8'h1c, 8'h4f, 8'h9c, 8'h8b, 8'h78, 8'h5e, 8'h0c, 8'hc6, 8'hc5, 8'hfd, 8'hc1, 8'hbf, 8'h82, 8'he5, 8'hcc, 8'h60, 8'h53, 8'hd3, 8'h17, 8'hf3, 8'h26, 8'h52, 8'hca, 8'h03, 8'h38, 8'h3c, 8'h7e, 8'h3d, 8'h67, 8'h29, 8'hac, 8'h33, 8'h80, 8'hc4, 8'he4, 8'hd5, 8'h74, 8'h98, 8'hc9, 8'h3b, 8'h04, 8'h42, 8'h43, 8'h5a, 8'h4e, 8'h85, 8'h9f, 8'hb3, 8'h44, 8'h20, 8'h31, 8'ha1, 8'hec, 8'h51, 8'hf2, 8'h3f, 8'h46 },
{8'h00, 8'h01, 8'h89, 8'hcb, 8'hb9, 8'hf7, 8'h23, 8'h90, 8'h92, 8'ha3, 8'h16, 8'h47, 8'h99, 8'hdf, 8'hcf, 8'hdb, 8'had, 8'h81, 8'h0f, 8'h1e, 8'h83, 8'h3e, 8'hab, 8'hd2, 8'he0, 8'hed, 8'hc2, 8'hf4, 8'h9b, 8'hee, 8'h7a, 8'h8a, 8'h73, 8'hc7, 8'h1f, 8'h0a, 8'hf5, 8'h12, 8'h25, 8'hc3, 8'h7d, 8'h50, 8'h57, 8'h8d, 8'ha9, 8'he3, 8'h55, 8'hbc, 8'h1c, 8'hb2, 8'h8b, 8'hfa, 8'h0c, 8'ha6, 8'hfd, 8'hd6, 8'h82, 8'hb7, 8'h60, 8'h6b, 8'h17, 8'hce, 8'h52, 8'h66, 8'h38, 8'hf8, 8'h3d, 8'h13, 8'hac, 8'h08, 8'hc4, 8'ha7, 8'h74, 8'h1d, 8'h3b, 8'h40, 8'h43, 8'hfb, 8'h85, 8'h6d, 8'h44, 8'h21, 8'ha1, 8'h27, 8'hf2, 8'hc8, 8'h01, 8'h89, 8'hcb, 8'hb9, 8'hf7, 8'h23, 8'h90, 8'h92, 8'ha3, 8'h16, 8'h47, 8'h99, 8'hdf, 8'hcf, 8'hdb, 8'had, 8'h81, 8'h0f, 8'h1e, 8'h83, 8'h3e, 8'hab, 8'hd2, 8'he0, 8'hed, 8'hc2, 8'hf4, 8'h9b, 8'hee, 8'h7a, 8'h8a, 8'h73, 8'hc7, 8'h1f, 8'h0a, 8'hf5, 8'h12, 8'h25, 8'hc3, 8'h7d, 8'h50, 8'h57, 8'h8d, 8'ha9, 8'he3, 8'h55, 8'hbc, 8'h1c, 8'hb2, 8'h8b, 8'hfa, 8'h0c, 8'ha6, 8'hfd, 8'hd6, 8'h82, 8'hb7, 8'h60, 8'h6b, 8'h17, 8'hce, 8'h52, 8'h66, 8'h38, 8'hf8, 8'h3d, 8'h13, 8'hac, 8'h08, 8'hc4, 8'ha7, 8'h74, 8'h1d, 8'h3b, 8'h40, 8'h43, 8'hfb, 8'h85, 8'h6d, 8'h44, 8'h21, 8'ha1, 8'h27, 8'hf2, 8'hc8, 8'h01, 8'h89, 8'hcb, 8'hb9, 8'hf7, 8'h23, 8'h90, 8'h92, 8'ha3, 8'h16, 8'h47, 8'h99, 8'hdf, 8'hcf, 8'hdb, 8'had, 8'h81, 8'h0f, 8'h1e, 8'h83, 8'h3e, 8'hab, 8'hd2, 8'he0, 8'hed, 8'hc2, 8'hf4, 8'h9b, 8'hee, 8'h7a, 8'h8a, 8'h73, 8'hc7, 8'h1f, 8'h0a, 8'hf5, 8'h12, 8'h25, 8'hc3, 8'h7d, 8'h50, 8'h57, 8'h8d, 8'ha9, 8'he3, 8'h55, 8'hbc, 8'h1c, 8'hb2, 8'h8b, 8'hfa, 8'h0c, 8'ha6, 8'hfd, 8'hd6, 8'h82, 8'hb7, 8'h60, 8'h6b, 8'h17, 8'hce, 8'h52, 8'h66, 8'h38, 8'hf8, 8'h3d, 8'h13, 8'hac, 8'h08, 8'hc4, 8'ha7, 8'h74, 8'h1d, 8'h3b, 8'h40, 8'h43, 8'hfb, 8'h85, 8'h6d, 8'h44, 8'h21, 8'ha1, 8'h27, 8'hf2, 8'hc8 },
{8'h00, 8'h01, 8'h14, 8'h1a, 8'hf7, 8'h11, 8'h4d, 8'ha3, 8'h79, 8'h18, 8'hdf, 8'h36, 8'h93, 8'h81, 8'hf0, 8'h6e, 8'h3e, 8'h15, 8'h0e, 8'hed, 8'he6, 8'h5c, 8'hee, 8'hda, 8'h61, 8'hc7, 8'he9, 8'ha5, 8'h12, 8'h71, 8'h9e, 8'h50, 8'h2b, 8'h1b, 8'he3, 8'h0b, 8'hba, 8'hb2, 8'h34, 8'hbb, 8'ha6, 8'h2e, 8'h4c, 8'hb7, 8'h63, 8'hef, 8'hce, 8'h7b, 8'h30, 8'hf8, 8'he8, 8'hb1, 8'h08, 8'h86, 8'h8f, 8'h1d, 8'h88, 8'h62, 8'hfb, 8'hd4, 8'h8c, 8'h21, 8'hb5, 8'h4b, 8'hc8, 8'h10, 8'h59, 8'hb9, 8'h8e, 8'h09, 8'h92, 8'h95, 8'hea, 8'h99, 8'h2f, 8'h58, 8'had, 8'h94, 8'hfe, 8'h83, 8'hd8, 8'h49, 8'he0, 8'h37, 8'h87, 8'h9b, 8'h07, 8'h7f, 8'h73, 8'hb6, 8'h77, 8'hf5, 8'h39, 8'h6a, 8'h7d, 8'h5b, 8'h91, 8'ha9, 8'hd7, 8'hb0, 8'h1c, 8'h9c, 8'h78, 8'h0c, 8'hc5, 8'hc1, 8'h82, 8'hcc, 8'h53, 8'h17, 8'h26, 8'hca, 8'h38, 8'h7e, 8'h67, 8'hac, 8'h80, 8'he4, 8'h74, 8'hc9, 8'h04, 8'h43, 8'h4e, 8'h9f, 8'h44, 8'h31, 8'hec, 8'hf2, 8'h46, 8'h19, 8'hcb, 8'h2c, 8'h64, 8'h90, 8'hbd, 8'hcd, 8'h47, 8'h0d, 8'hd1, 8'hdb, 8'h75, 8'hdd, 8'h1e, 8'hb4, 8'h5f, 8'hd2, 8'he7, 8'h48, 8'hf4, 8'h2d, 8'h70, 8'h8a, 8'h4a, 8'hdc, 8'h0a, 8'hae, 8'ha8, 8'hc3, 8'haa, 8'heb, 8'h8d, 8'h35, 8'haf, 8'hbc, 8'hd9, 8'h5d, 8'hfa, 8'hc0, 8'h96, 8'hd6, 8'ha4, 8'h06, 8'h6b, 8'h69, 8'h41, 8'h66, 8'hb8, 8'h9a, 8'h13, 8'h65, 8'h84, 8'ha7, 8'h3a, 8'h56, 8'h40, 8'h72, 8'ha2, 8'h6d, 8'h02, 8'h28, 8'h27, 8'hde, 8'h22, 8'h89, 8'h76, 8'he1, 8'h23, 8'h9d, 8'h6c, 8'h16, 8'h32, 8'hd0, 8'hcf, 8'h6f, 8'h2a, 8'h0f, 8'hf9, 8'hfc, 8'hab, 8'hff, 8'h97, 8'hc2, 8'hbe, 8'hf1, 8'h7a, 8'h24, 8'he2, 8'h1f, 8'ha0, 8'h45, 8'h25, 8'hf6, 8'h05, 8'h57, 8'h54, 8'h68, 8'h55, 8'h7c, 8'h4f, 8'h8b, 8'h5e, 8'hc6, 8'hfd, 8'hbf, 8'he5, 8'h60, 8'hd3, 8'hf3, 8'h52, 8'h03, 8'h3c, 8'h3d, 8'h29, 8'h33, 8'hc4, 8'hd5, 8'h98, 8'h3b, 8'h42, 8'h5a, 8'h85, 8'hb3, 8'h20, 8'ha1, 8'h51, 8'h3f },
{8'h00, 8'h01, 8'h59, 8'h2c, 8'h23, 8'h4d, 8'h95, 8'h47, 8'hd0, 8'h36, 8'had, 8'hdd, 8'hf9, 8'h3e, 8'h49, 8'he7, 8'hc2, 8'h5c, 8'h07, 8'h8a, 8'he2, 8'he9, 8'hf5, 8'ha8, 8'hf6, 8'h50, 8'h91, 8'h35, 8'h55, 8'hba, 8'h9c, 8'hfa, 8'hc6, 8'h2e, 8'h82, 8'h06, 8'hd3, 8'hce, 8'hca, 8'hb8, 8'h3d, 8'hb1, 8'h80, 8'ha7, 8'h98, 8'h88, 8'h43, 8'ha2, 8'hb3, 8'h21, 8'hec, 8'hde, 8'h01, 8'h59, 8'h2c, 8'h23, 8'h4d, 8'h95, 8'h47, 8'hd0, 8'h36, 8'had, 8'hdd, 8'hf9, 8'h3e, 8'h49, 8'he7, 8'hc2, 8'h5c, 8'h07, 8'h8a, 8'he2, 8'he9, 8'hf5, 8'ha8, 8'hf6, 8'h50, 8'h91, 8'h35, 8'h55, 8'hba, 8'h9c, 8'hfa, 8'hc6, 8'h2e, 8'h82, 8'h06, 8'hd3, 8'hce, 8'hca, 8'hb8, 8'h3d, 8'hb1, 8'h80, 8'ha7, 8'h98, 8'h88, 8'h43, 8'ha2, 8'hb3, 8'h21, 8'hec, 8'hde, 8'h01, 8'h59, 8'h2c, 8'h23, 8'h4d, 8'h95, 8'h47, 8'hd0, 8'h36, 8'had, 8'hdd, 8'hf9, 8'h3e, 8'h49, 8'he7, 8'hc2, 8'h5c, 8'h07, 8'h8a, 8'he2, 8'he9, 8'hf5, 8'ha8, 8'hf6, 8'h50, 8'h91, 8'h35, 8'h55, 8'hba, 8'h9c, 8'hfa, 8'hc6, 8'h2e, 8'h82, 8'h06, 8'hd3, 8'hce, 8'hca, 8'hb8, 8'h3d, 8'hb1, 8'h80, 8'ha7, 8'h98, 8'h88, 8'h43, 8'ha2, 8'hb3, 8'h21, 8'hec, 8'hde, 8'h01, 8'h59, 8'h2c, 8'h23, 8'h4d, 8'h95, 8'h47, 8'hd0, 8'h36, 8'had, 8'hdd, 8'hf9, 8'h3e, 8'h49, 8'he7, 8'hc2, 8'h5c, 8'h07, 8'h8a, 8'he2, 8'he9, 8'hf5, 8'ha8, 8'hf6, 8'h50, 8'h91, 8'h35, 8'h55, 8'hba, 8'h9c, 8'hfa, 8'hc6, 8'h2e, 8'h82, 8'h06, 8'hd3, 8'hce, 8'hca, 8'hb8, 8'h3d, 8'hb1, 8'h80, 8'ha7, 8'h98, 8'h88, 8'h43, 8'ha2, 8'hb3, 8'h21, 8'hec, 8'hde, 8'h01, 8'h59, 8'h2c, 8'h23, 8'h4d, 8'h95, 8'h47, 8'hd0, 8'h36, 8'had, 8'hdd, 8'hf9, 8'h3e, 8'h49, 8'he7, 8'hc2, 8'h5c, 8'h07, 8'h8a, 8'he2, 8'he9, 8'hf5, 8'ha8, 8'hf6, 8'h50, 8'h91, 8'h35, 8'h55, 8'hba, 8'h9c, 8'hfa, 8'hc6, 8'h2e, 8'h82, 8'h06, 8'hd3, 8'hce, 8'hca, 8'hb8, 8'h3d, 8'hb1, 8'h80, 8'ha7, 8'h98, 8'h88, 8'h43, 8'ha2, 8'hb3, 8'h21, 8'hec, 8'hde },
{8'h00, 8'h01, 8'hcb, 8'hf7, 8'h90, 8'ha3, 8'h47, 8'hdf, 8'hdb, 8'h81, 8'h1e, 8'h3e, 8'hd2, 8'hed, 8'hf4, 8'hee, 8'h8a, 8'hc7, 8'h0a, 8'h12, 8'hc3, 8'h50, 8'h8d, 8'he3, 8'hbc, 8'hb2, 8'hfa, 8'ha6, 8'hd6, 8'hb7, 8'h6b, 8'hce, 8'h66, 8'hf8, 8'h13, 8'h08, 8'ha7, 8'h1d, 8'h40, 8'hfb, 8'h6d, 8'h21, 8'h27, 8'hc8, 8'h89, 8'hb9, 8'h23, 8'h92, 8'h16, 8'h99, 8'hcf, 8'had, 8'h0f, 8'h83, 8'hab, 8'he0, 8'hc2, 8'h9b, 8'h7a, 8'h73, 8'h1f, 8'hf5, 8'h25, 8'h7d, 8'h57, 8'ha9, 8'h55, 8'h1c, 8'h8b, 8'h0c, 8'hfd, 8'h82, 8'h60, 8'h17, 8'h52, 8'h38, 8'h3d, 8'hac, 8'hc4, 8'h74, 8'h3b, 8'h43, 8'h85, 8'h44, 8'ha1, 8'hf2, 8'h01, 8'hcb, 8'hf7, 8'h90, 8'ha3, 8'h47, 8'hdf, 8'hdb, 8'h81, 8'h1e, 8'h3e, 8'hd2, 8'hed, 8'hf4, 8'hee, 8'h8a, 8'hc7, 8'h0a, 8'h12, 8'hc3, 8'h50, 8'h8d, 8'he3, 8'hbc, 8'hb2, 8'hfa, 8'ha6, 8'hd6, 8'hb7, 8'h6b, 8'hce, 8'h66, 8'hf8, 8'h13, 8'h08, 8'ha7, 8'h1d, 8'h40, 8'hfb, 8'h6d, 8'h21, 8'h27, 8'hc8, 8'h89, 8'hb9, 8'h23, 8'h92, 8'h16, 8'h99, 8'hcf, 8'had, 8'h0f, 8'h83, 8'hab, 8'he0, 8'hc2, 8'h9b, 8'h7a, 8'h73, 8'h1f, 8'hf5, 8'h25, 8'h7d, 8'h57, 8'ha9, 8'h55, 8'h1c, 8'h8b, 8'h0c, 8'hfd, 8'h82, 8'h60, 8'h17, 8'h52, 8'h38, 8'h3d, 8'hac, 8'hc4, 8'h74, 8'h3b, 8'h43, 8'h85, 8'h44, 8'ha1, 8'hf2, 8'h01, 8'hcb, 8'hf7, 8'h90, 8'ha3, 8'h47, 8'hdf, 8'hdb, 8'h81, 8'h1e, 8'h3e, 8'hd2, 8'hed, 8'hf4, 8'hee, 8'h8a, 8'hc7, 8'h0a, 8'h12, 8'hc3, 8'h50, 8'h8d, 8'he3, 8'hbc, 8'hb2, 8'hfa, 8'ha6, 8'hd6, 8'hb7, 8'h6b, 8'hce, 8'h66, 8'hf8, 8'h13, 8'h08, 8'ha7, 8'h1d, 8'h40, 8'hfb, 8'h6d, 8'h21, 8'h27, 8'hc8, 8'h89, 8'hb9, 8'h23, 8'h92, 8'h16, 8'h99, 8'hcf, 8'had, 8'h0f, 8'h83, 8'hab, 8'he0, 8'hc2, 8'h9b, 8'h7a, 8'h73, 8'h1f, 8'hf5, 8'h25, 8'h7d, 8'h57, 8'ha9, 8'h55, 8'h1c, 8'h8b, 8'h0c, 8'hfd, 8'h82, 8'h60, 8'h17, 8'h52, 8'h38, 8'h3d, 8'hac, 8'hc4, 8'h74, 8'h3b, 8'h43, 8'h85, 8'h44, 8'ha1, 8'hf2 },
{8'h00, 8'h01, 8'h76, 8'h64, 8'h92, 8'h79, 8'hd0, 8'hdb, 8'h94, 8'h6e, 8'hab, 8'he7, 8'h87, 8'hee, 8'h24, 8'hdc, 8'hf5, 8'h71, 8'h05, 8'h8d, 8'hd7, 8'hba, 8'h8b, 8'hc0, 8'hc1, 8'hb7, 8'hd3, 8'h41, 8'h38, 8'he8, 8'h33, 8'ha7, 8'hc9, 8'h62, 8'h85, 8'h02, 8'hec, 8'hc8, 8'h14, 8'he1, 8'h90, 8'h95, 8'h18, 8'hcf, 8'h75, 8'hfe, 8'h3e, 8'hff, 8'h48, 8'h9b, 8'hda, 8'he2, 8'h0a, 8'h39, 8'h9e, 8'h57, 8'h35, 8'hb0, 8'hb2, 8'h5e, 8'h96, 8'h82, 8'h63, 8'hf3, 8'h66, 8'h7e, 8'hb1, 8'hc4, 8'h3a, 8'h04, 8'hfb, 8'hb3, 8'h28, 8'hf2, 8'h10, 8'h1a, 8'h23, 8'hbd, 8'hea, 8'hdf, 8'h6f, 8'hdd, 8'h83, 8'h15, 8'h97, 8'hf4, 8'h07, 8'h61, 8'h1f, 8'hae, 8'h6a, 8'h50, 8'h54, 8'haf, 8'h1c, 8'h34, 8'hc6, 8'hd6, 8'hcc, 8'hef, 8'h52, 8'hb8, 8'h67, 8'h08, 8'hd5, 8'h56, 8'h43, 8'hd4, 8'h20, 8'h27, 8'h46, 8'h59, 8'hf7, 8'h9d, 8'hcd, 8'h99, 8'h36, 8'h2a, 8'h1e, 8'hd8, 8'h0e, 8'hc2, 8'h2d, 8'h7f, 8'hc7, 8'ha0, 8'ha8, 8'h7d, 8'h2b, 8'h68, 8'hbc, 8'h9c, 8'hbb, 8'hfd, 8'ha4, 8'h53, 8'hce, 8'h03, 8'h9a, 8'hac, 8'h86, 8'h98, 8'h40, 8'h4e, 8'h8c, 8'ha1, 8'hde, 8'h19, 8'hb9, 8'h11, 8'h6c, 8'h47, 8'h2f, 8'h93, 8'h0f, 8'hb4, 8'h49, 8'hed, 8'hbe, 8'h70, 8'h73, 8'he9, 8'h45, 8'hc3, 8'h5b, 8'h1b, 8'h55, 8'hd9, 8'h78, 8'ha6, 8'hbf, 8'h06, 8'h17, 8'h7b, 8'h3c, 8'h13, 8'h80, 8'h8f, 8'h3b, 8'h72, 8'h9f, 8'h21, 8'h51, 8'h22, 8'hcb, 8'h8e, 8'h4d, 8'h16, 8'h0d, 8'h58, 8'h81, 8'hf9, 8'h5f, 8'he0, 8'he6, 8'hf1, 8'h8a, 8'hb6, 8'ha5, 8'h25, 8'haa, 8'h91, 8'he3, 8'h7c, 8'h5d, 8'h0c, 8'h2e, 8'he5, 8'h6b, 8'h26, 8'h30, 8'h3d, 8'h65, 8'he4, 8'h1d, 8'h42, 8'ha2, 8'h44, 8'hb5, 8'h3f, 8'h89, 8'h2c, 8'h09, 8'ha3, 8'h32, 8'hd1, 8'had, 8'hf0, 8'hfc, 8'hd2, 8'h37, 8'h5c, 8'h7a, 8'h4a, 8'h77, 8'h12, 8'hf6, 8'heb, 8'ha9, 8'h0b, 8'h4f, 8'hfa, 8'hc5, 8'h4c, 8'h60, 8'h69, 8'hca, 8'hf8, 8'h29, 8'h84, 8'h74, 8'h88, 8'h5a, 8'h6d, 8'h31, 8'h4b },
{8'h00, 8'h01, 8'h1a, 8'h11, 8'ha3, 8'h18, 8'h36, 8'h81, 8'h6e, 8'h15, 8'hed, 8'h5c, 8'hda, 8'hc7, 8'ha5, 8'h71, 8'h50, 8'h1b, 8'h0b, 8'hb2, 8'hbb, 8'h2e, 8'hb7, 8'hef, 8'h7b, 8'hf8, 8'hb1, 8'h86, 8'h1d, 8'h62, 8'hd4, 8'h21, 8'h4b, 8'h10, 8'hb9, 8'h09, 8'h95, 8'h99, 8'h58, 8'h94, 8'h83, 8'h49, 8'h37, 8'h9b, 8'h7f, 8'hb6, 8'hf5, 8'h6a, 8'h5b, 8'ha9, 8'hb0, 8'h9c, 8'h0c, 8'hc1, 8'hcc, 8'h17, 8'hca, 8'h7e, 8'hac, 8'he4, 8'hc9, 8'h43, 8'h9f, 8'h31, 8'hf2, 8'h19, 8'h2c, 8'h90, 8'hcd, 8'h0d, 8'hdb, 8'hdd, 8'hb4, 8'hd2, 8'h48, 8'h2d, 8'h8a, 8'hdc, 8'hae, 8'hc3, 8'heb, 8'h35, 8'hbc, 8'h5d, 8'hc0, 8'hd6, 8'h06, 8'h69, 8'h66, 8'h9a, 8'h65, 8'ha7, 8'h56, 8'h72, 8'h6d, 8'h28, 8'hde, 8'h89, 8'he1, 8'h9d, 8'h16, 8'hd0, 8'h6f, 8'h0f, 8'hfc, 8'hff, 8'hc2, 8'hf1, 8'h24, 8'h1f, 8'h45, 8'hf6, 8'h57, 8'h68, 8'h7c, 8'h8b, 8'hc6, 8'hbf, 8'h60, 8'hf3, 8'h03, 8'h3d, 8'h33, 8'hd5, 8'h3b, 8'h5a, 8'hb3, 8'ha1, 8'h3f, 8'h14, 8'hf7, 8'h4d, 8'h79, 8'hdf, 8'h93, 8'hf0, 8'h3e, 8'h0e, 8'he6, 8'hee, 8'h61, 8'he9, 8'h12, 8'h9e, 8'h2b, 8'he3, 8'hba, 8'h34, 8'ha6, 8'h4c, 8'h63, 8'hce, 8'h30, 8'he8, 8'h08, 8'h8f, 8'h88, 8'hfb, 8'h8c, 8'hb5, 8'hc8, 8'h59, 8'h8e, 8'h92, 8'hea, 8'h2f, 8'had, 8'hfe, 8'hd8, 8'he0, 8'h87, 8'h07, 8'h73, 8'h77, 8'h39, 8'h7d, 8'h91, 8'hd7, 8'h1c, 8'h78, 8'hc5, 8'h82, 8'h53, 8'h26, 8'h38, 8'h67, 8'h80, 8'h74, 8'h04, 8'h4e, 8'h44, 8'hec, 8'h46, 8'hcb, 8'h64, 8'hbd, 8'h47, 8'hd1, 8'h75, 8'h1e, 8'h5f, 8'he7, 8'hf4, 8'h70, 8'h4a, 8'h0a, 8'ha8, 8'haa, 8'h8d, 8'haf, 8'hd9, 8'hfa, 8'h96, 8'ha4, 8'h6b, 8'h41, 8'hb8, 8'h13, 8'h84, 8'h3a, 8'h40, 8'ha2, 8'h02, 8'h27, 8'h22, 8'h76, 8'h23, 8'h6c, 8'h32, 8'hcf, 8'h2a, 8'hf9, 8'hab, 8'h97, 8'hbe, 8'h7a, 8'he2, 8'ha0, 8'h25, 8'h05, 8'h54, 8'h55, 8'h4f, 8'h5e, 8'hfd, 8'he5, 8'hd3, 8'h52, 8'h3c, 8'h29, 8'hc4, 8'h98, 8'h42, 8'h85, 8'h20, 8'h51 },
{8'h00, 8'h01, 8'hb9, 8'h90, 8'h16, 8'hdf, 8'had, 8'h1e, 8'hab, 8'hed, 8'h9b, 8'h8a, 8'h1f, 8'h12, 8'h7d, 8'h8d, 8'h55, 8'hb2, 8'h0c, 8'hd6, 8'h60, 8'hce, 8'h38, 8'h13, 8'hc4, 8'h1d, 8'h43, 8'h6d, 8'ha1, 8'hc8, 8'hcb, 8'h23, 8'ha3, 8'h99, 8'hdb, 8'h0f, 8'h3e, 8'he0, 8'hf4, 8'h7a, 8'hc7, 8'hf5, 8'hc3, 8'h57, 8'he3, 8'h1c, 8'hfa, 8'hfd, 8'hb7, 8'h17, 8'h66, 8'h3d, 8'h08, 8'h74, 8'h40, 8'h85, 8'h21, 8'hf2, 8'h89, 8'hf7, 8'h92, 8'h47, 8'hcf, 8'h81, 8'h83, 8'hd2, 8'hc2, 8'hee, 8'h73, 8'h0a, 8'h25, 8'h50, 8'ha9, 8'hbc, 8'h8b, 8'ha6, 8'h82, 8'h6b, 8'h52, 8'hf8, 8'hac, 8'ha7, 8'h3b, 8'hfb, 8'h44, 8'h27, 8'h01, 8'hb9, 8'h90, 8'h16, 8'hdf, 8'had, 8'h1e, 8'hab, 8'hed, 8'h9b, 8'h8a, 8'h1f, 8'h12, 8'h7d, 8'h8d, 8'h55, 8'hb2, 8'h0c, 8'hd6, 8'h60, 8'hce, 8'h38, 8'h13, 8'hc4, 8'h1d, 8'h43, 8'h6d, 8'ha1, 8'hc8, 8'hcb, 8'h23, 8'ha3, 8'h99, 8'hdb, 8'h0f, 8'h3e, 8'he0, 8'hf4, 8'h7a, 8'hc7, 8'hf5, 8'hc3, 8'h57, 8'he3, 8'h1c, 8'hfa, 8'hfd, 8'hb7, 8'h17, 8'h66, 8'h3d, 8'h08, 8'h74, 8'h40, 8'h85, 8'h21, 8'hf2, 8'h89, 8'hf7, 8'h92, 8'h47, 8'hcf, 8'h81, 8'h83, 8'hd2, 8'hc2, 8'hee, 8'h73, 8'h0a, 8'h25, 8'h50, 8'ha9, 8'hbc, 8'h8b, 8'ha6, 8'h82, 8'h6b, 8'h52, 8'hf8, 8'hac, 8'ha7, 8'h3b, 8'hfb, 8'h44, 8'h27, 8'h01, 8'hb9, 8'h90, 8'h16, 8'hdf, 8'had, 8'h1e, 8'hab, 8'hed, 8'h9b, 8'h8a, 8'h1f, 8'h12, 8'h7d, 8'h8d, 8'h55, 8'hb2, 8'h0c, 8'hd6, 8'h60, 8'hce, 8'h38, 8'h13, 8'hc4, 8'h1d, 8'h43, 8'h6d, 8'ha1, 8'hc8, 8'hcb, 8'h23, 8'ha3, 8'h99, 8'hdb, 8'h0f, 8'h3e, 8'he0, 8'hf4, 8'h7a, 8'hc7, 8'hf5, 8'hc3, 8'h57, 8'he3, 8'h1c, 8'hfa, 8'hfd, 8'hb7, 8'h17, 8'h66, 8'h3d, 8'h08, 8'h74, 8'h40, 8'h85, 8'h21, 8'hf2, 8'h89, 8'hf7, 8'h92, 8'h47, 8'hcf, 8'h81, 8'h83, 8'hd2, 8'hc2, 8'hee, 8'h73, 8'h0a, 8'h25, 8'h50, 8'ha9, 8'hbc, 8'h8b, 8'ha6, 8'h82, 8'h6b, 8'h52, 8'hf8, 8'hac, 8'ha7, 8'h3b, 8'hfb, 8'h44, 8'h27 }
};  



//~~~~~~~~~~~~~~~ GF(2^8) as  GF((2^4)^2) ~~~~~~~~~~~~~~~~~~~~~~


// P(x) = x^2+x+mu is primitive poly for (GF((2^4)^2), with mu in GF(2^4)
// mu = omega^14 (= 'b1001), where omega is primitive element in GF(2^4).
localparam logic [3:0] mu = 4'b1001; // 'd9

function automatic [1:0][3:0] gf8_mult_comp (
  input [1:0][3:0] a,b
);

  logic [1:0][3:0] c;
  logic [3:0] a0b0, a1b1;

  a0b0 =  gf4_mult(a[0],b[0]);
  a1b1 =  gf4_mult(a[1],b[1]);

  c[1] = gf4_mult(a[1]^a[0], b[1]^b[0]) ^ a0b0;
  c[0] = gf4_mult(a1b1, mu) ^ a0b0;
  return c;

endfunction

function automatic [1:0][3:0] gf8_pow2_comp (
  input [1:0][3:0] a
);

  logic [1:0][3:0] c;
  c[1] = gf4_pow2(a[1]);
  c[0] = gf4_mult(c[1], mu) ^ gf4_pow2(a[0]);
  return c;
  
endfunction


function automatic [1:0][3:0] gf8_pow3_comp (
  input [1:0][3:0] a
);

  return  gf8_mult_comp (gf8_pow2_comp (a), a);
  
endfunction

function automatic [1:0][3:0] gf8_inv_comp (
  input [1:0][3:0] a
);

  logic [3:0] d, a1_pow2;
  logic [1:0][3:0] c;  

  a1_pow2 =  gf4_pow2(a[1]);
  d =  gf4_mult(a[0],a[0]^a[1]) ^ gf4_mult(mu, a1_pow2);

  c[0] = gf4_div(a[1]^a[0], d);
  c[1] = gf4_div(a[1],      d);
  return c;

endfunction

function automatic [1:0][3:0] gf8_div_comp (
  input [1:0][3:0] a,b
);
  logic [1:0][3:0] c; 
  logic [2:0][3:0] m; 
  logic      [3:0] d;
  
  d = gf4_mult(b[0], b[0]^b[1]) ^ gf4_mult(mu, gf4_pow2 (b[1])); 
  
  m[0] = gf4_mult(a[1], gf4_mult(mu, b[1])); 
  m[1] = gf4_mult(a[0], 	b[0]^b[1] ); 
  m[2] = gf4_mult(b[0], 	a[0]^a[1] );
  
  c[1] = m[2] ^ m[1];
  c[0] = m[0] ^ m[1];
  
  c[1] = gf4_div (c[1], d);
  c[0] = gf4_div (c[0], d);   
     
  return c;
  
endfunction

//~~~~~~~~~~~~~~~ GF(2^4) ~~~~~~~~~~~~~~~~~~~~~~
localparam logic [4:0] P4 = 5'b10011; // primitive polynomial x^4+x+1
function automatic [3:0] gf4_mult (
  input [3:0] a,b
);
  logic [3:0][3:0] c;   
  logic [3:0] result; 
  c[0] = a;
  for (int i=1; i<4; i++) c[i] = {c[i-1][2:0],1'b0} ^ (c[i-1][3]? P4[3:0] : 4'h0);
  result = '0;
  for (int i=0; i<4; i++) if (b[i]) result ^= c[i];
  return result;
endfunction




function automatic [3:0] gf4_mult_1001 (
  input [3:0] a
);

  return ({1'b0, a[3], a[2], a[1] ^ a[0]});
endfunction


function automatic [3:0] gf4_pow2 (
  input [3:0] a
);
  return ({a[3], a[3]^a[1], a[2], a[2]^a[0]});

endfunction


function automatic [3:0] gf4_inv (
  input [3:0] a
);

  case (a)
  4'h0  : return 4'h0; 
  4'h1  : return 4'h1; 
  4'h2  : return 4'h9; 
  4'h4  : return 4'hd; 
  4'h8  : return 4'hf; 
  4'h3  : return 4'he; 
  4'h6  : return 4'h7; 
  4'hc  : return 4'ha; 
  4'hb  : return 4'h5; 
  4'h5  : return 4'hb; 
  4'ha  : return 4'hc; 
  4'h7  : return 4'h6; 
  4'he  : return 4'h3; 
  4'hf  : return 4'h8; 
  4'hd  : return 4'h4; 
  4'h9  : return 4'h2; 
  
  endcase 

endfunction


function automatic [3:0] gf4_div (
  input [3:0] a,b
);
  logic [3:0] c; 
  c = gf4_mult (a, gf4_inv(b));
  return c;
  
endfunction



