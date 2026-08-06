// =============================================================================
// SPDX-License-Identifier: BSD-3-Clause
//
// Copyright (c) 2025 Astera Labs, Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 3. Neither the name of Astera Labs, Inc. nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// efec_enc.sv
// Author  : V. Shvydun
// Design  : eFEC encoder - Reed-Solomon RS(256, 246..250) over GF(2^8).
// Details : Supports t=3, t=4, and t=5 error correction configurations
//           selected at runtime via the 2-bit mode input.
//           Each clock cycle p_gen produces the parity contribution for the
//           current 256-byte data slice; efec_enc accumulates (XORs) those
//           contributions across the flit and resets at EOF.
//           Output fec_enc_out is 112 bits (14 bytes): the ECC bytes followed
//           by the CRC-region bytes extracted from data_in bytes 242..249/247/245.
// =============================================================================


// ---------------------------------------------------------------------------
// Module : efec_enc
// Purpose: Top-level encoder.  Instantiates p_gen to compute per-cycle parity
//          contributions, accumulates them into P_rt across the flit, and
//          presents the final {ECC, CRC-region} bundle on fec_enc_out.
// ---------------------------------------------------------------------------
module efec_enc #(
    parameter P_FLIT_WD = 2048
) (
    // Inputs
    input  logic                      clk,
    input  logic                      rst_n,
    // Config
    input  logic               [1:0]  mode,      // 00=t=3, 01=t=4, 1x=t=5
    // Data
    input  logic [P_FLIT_WD-1:0]     data_in,
    input  logic                      eof,        // End of flit
    input  logic                      halt_in,    // Back-pressure from lower layer
    // Outputs
    // 14 bytes: {ECC[2*t-1:0], data_in[CRC_region]}; CRC region is bytes 242..249/247/245
    output logic        [111:0]       fec_enc_out
);

    localparam t = 5;
    localparam w = 8;

    // ---------------------------------------------------------------------------
    // Parity polynomial: P is the combinational contribution for the current
    // data_in slice; P_rt is the running XOR accumulation across the flit.
    // ---------------------------------------------------------------------------
    logic [2*t-1:0][w-1:0] P;
    logic [2*t-1:0][w-1:0] P_rt;

    // ---------------------------------------------------------------------------
    // Parity-polynomial generator instance
    // ---------------------------------------------------------------------------
    p_gen p_gen (
        .din  ( data_in ),
        .mode ( mode    ),
        .P    ( P       )
    );

    // ---------------------------------------------------------------------------
    // Accumulation register: XOR each cycle's parity contribution into P_rt.
    // Clear P_rt at EOF so the accumulator is ready for the next flit.
    // Only the lanes active for the selected mode are updated.
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk, negedge rst_n) begin : fec_out_PROC
        if (!rst_n) begin
            P_rt <= '0;
        end else if (!halt_in) begin
            if (eof) begin
                P_rt <= '0;
            end else begin
                casex (mode)
                    2'b00: P_rt[5:0] <= P[5:0] ^ P_rt[5:0];
                    2'b01: P_rt[7:0] <= P[7:0] ^ P_rt[7:0];
                    2'b1x: P_rt[9:0] <= P[9:0] ^ P_rt[9:0];
                endcase
            end
        end
    end : fec_out_PROC

    // ---------------------------------------------------------------------------
    // Output assembly: combine final ECC bytes with the CRC-region bytes from
    // data_in.  The CRC region occupies flit bytes 242..249 (mode=00),
    // 242..247 (mode=01), or 242..245 (mode=1x).
    // ---------------------------------------------------------------------------
    always_comb begin : fec_enc_out_PROC
        casex (mode)
            2'b00: fec_enc_out = {P[5:0] ^ P_rt[5:0], data_in[250*8-1:242*8]};
            2'b01: fec_enc_out = {P[7:0] ^ P_rt[7:0], data_in[248*8-1:242*8]};
            2'b1x: fec_enc_out = {P[9:0] ^ P_rt[9:0], data_in[246*8-1:242*8]};
        endcase
    end : fec_enc_out_PROC

endmodule


// ---------------------------------------------------------------------------
// Module : p_gen
// Purpose: Computes the parity-check polynomial contribution P[0..2t-1] for
//          one 256-symbol data word.
//
//          Step 1 — Syndrome projection:
//            PP[y] = XOR_{x=0}^{k-1}  din[x] * H[y][x],  y = 0..2t-1
//          where H is the 10x256 parity-check matrix (from gf_func.sv).
//          Only the symbol positions active for the current mode are included.
//
//          Step 2 — Back-substitution (Gaussian elimination):
//            Converts the raw syndrome vector PP into the systematic parity
//            polynomial P by applying the precomputed elimination constants.
//            Each step scales one pivot row then eliminates it from the rows
//            below; the resulting P[0..2t-1] are the GF(2^8) parity bytes.
// ---------------------------------------------------------------------------
module p_gen #(
    parameter n = 256,
    parameter w = 8,
    parameter t = 5
) (
    // Inputs
    input  logic [n-1:0][w-1:0]    din,
    input  logic          [1:0]    mode,   // 00=t=3, 01=t=4, 1x=t=5
    // Outputs
    output logic [2*t-1:0][w-1:0] P
);

    logic [2*t-1:0][w-1:0] PP;

    always_comb begin : p_gen_PROC
        P  = '0;
        PP = '0;

        // -----------------------------------------------------------------------
        // Step 1: Syndrome projection onto H rows 0..5 (common to all modes)
        // -----------------------------------------------------------------------
        for (int y = 0; y < 6;  y++) for (int x = 0;   x < 246; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
        if (mode > 2'd0)
            for (int y = 6; y < 8;  y++) for (int x = 0;   x < 246; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
        if (mode > 2'd1)
            for (int y = 8; y < 10; y++) for (int x = 0;   x < 246; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);

        // Include CRC-region symbol positions that are part of the data field
        case (mode)
            2'b00: for (int y = 0; y < 6; y++) for (int x = 246; x < 250; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
            2'b01: for (int y = 0; y < 8; y++) for (int x = 246; x < 248; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);
        endcase

        // -----------------------------------------------------------------------
        // Step 2: Back-substitution to produce systematic parity bytes P[0..2t-1]
        // -----------------------------------------------------------------------
        casex (mode)

            // -------------------------------------------------------------------
            // t=3: 6 parity bytes, RS(256, 250)
            // -------------------------------------------------------------------
            2'b00: begin
                // Eliminate PP[1] from rows 2..5
                PP[2] ^= PP[1];
                PP[3] ^= PP[1];
                PP[4] ^= PP[1];
                PP[5] ^= PP[1];

                // Pivot PP[2]
                PP[2]  = gf8_mult_comp(PP[2], 8'h02);
                PP[3] ^= gf8_mult_comp(PP[2], 8'h99);
                PP[4] ^= gf8_mult_comp(PP[2], 8'h04);
                PP[5] ^= gf8_mult_comp(PP[2], 8'h49);

                // Pivot PP[3]
                PP[3]  = gf8_mult_comp(PP[3], 8'h08);
                PP[4] ^= gf8_mult_comp(PP[3], 8'h01);
                PP[5] ^= gf8_mult_comp(PP[3], 8'h18);

                // Pivot PP[4]
                PP[4]  = gf8_mult_comp(PP[4], 8'h8c);
                PP[5] ^= gf8_mult_comp(PP[4], 8'hff);

                // Pivot PP[5]
                PP[5]  = gf8_mult_comp(PP[5], 8'hb7);

                // Back-substitution: resolve P[0..5]
                P[0] = PP[5];
                P[1] = PP[4] ^ gf8_mult_comp(P[0], 8'h94);
                P[2] = PP[3] ^ gf8_mult_comp(P[0], 8'h02) ^ gf8_mult_comp(P[1], 8'h80);
                P[3] = PP[2] ^ gf8_mult_comp(P[0], 8'h0f) ^ gf8_mult_comp(P[1], 8'h84) ^ gf8_mult_comp(P[2], 8'h09);
                P[4] = PP[1] ^ gf8_mult_comp(P[0], 8'h14) ^ gf8_mult_comp(P[1], 8'h89) ^ gf8_mult_comp(P[2], 8'h19) ^ gf8_mult_comp(P[3], 8'h10);
                P[5] = PP[0] ^ P[0] ^ P[1] ^ P[2] ^ P[3] ^ P[4];
            end

            // -------------------------------------------------------------------
            // t=4: 8 parity bytes, RS(256, 248)
            // -------------------------------------------------------------------
            2'b01: begin
                // Eliminate PP[1] from rows 2..7
                PP[2] ^= PP[1];
                PP[3] ^= PP[1];
                PP[4] ^= PP[1];
                PP[5] ^= PP[1];
                PP[6] ^= PP[1];
                PP[7] ^= PP[1];

                // Pivot PP[2]
                PP[2]  = gf8_mult_comp(PP[2], 8'h02);
                PP[3] ^= gf8_mult_comp(PP[2], 8'h99);
                PP[4] ^= gf8_mult_comp(PP[2], 8'h04);
                PP[5] ^= gf8_mult_comp(PP[2], 8'h49);
                PP[6] ^= gf8_mult_comp(PP[2], 8'hdb);
                PP[7] ^= gf8_mult_comp(PP[2], 8'h66);

                // Pivot PP[3]
                PP[3]  = gf8_mult_comp(PP[3], 8'h08);
                PP[4] ^= gf8_mult_comp(PP[3], 8'h01);
                PP[5] ^= gf8_mult_comp(PP[3], 8'h18);
                PP[6] ^= gf8_mult_comp(PP[3], 8'h12);
                PP[7] ^= gf8_mult_comp(PP[3], 8'h4e);

                // Pivot PP[4]
                PP[4]  = gf8_mult_comp(PP[4], 8'h8c);
                PP[5] ^= gf8_mult_comp(PP[4], 8'hff);
                PP[6] ^= gf8_mult_comp(PP[4], 8'he6);
                PP[7] ^= gf8_mult_comp(PP[4], 8'h58);

                // Pivot PP[5]
                PP[5]  = gf8_mult_comp(PP[5], 8'hb7);
                PP[6] ^= gf8_mult_comp(PP[5], 8'h71);
                PP[7] ^= gf8_mult_comp(PP[5], 8'h2c);

                // Pivot PP[6]
                PP[6]  = gf8_mult_comp(PP[6], 8'heb);
                PP[7] ^= gf8_mult_comp(PP[6], 8'h2a);

                // Pivot PP[7]
                PP[7]  = gf8_mult_comp(PP[7], 8'h66);

                // Back-substitution: resolve P[0..7]
                P[0] = PP[7];
                P[1] = PP[6] ^ gf8_mult_comp(P[0], 8'h06);
                P[2] = PP[5] ^ gf8_mult_comp(P[0], 8'hce) ^ gf8_mult_comp(P[1], 8'hcd);
                P[3] = PP[4] ^ gf8_mult_comp(P[0], 8'h95) ^ gf8_mult_comp(P[1], 8'hfc) ^ gf8_mult_comp(P[2], 8'h94);
                P[4] = PP[3] ^ gf8_mult_comp(P[0], 8'h41) ^ gf8_mult_comp(P[1], 8'h3e) ^ gf8_mult_comp(P[2], 8'h02) ^ gf8_mult_comp(P[3], 8'h80);
                P[5] = PP[2] ^ gf8_mult_comp(P[0], 8'h6b) ^ gf8_mult_comp(P[1], 8'hea) ^ gf8_mult_comp(P[2], 8'h0f) ^ gf8_mult_comp(P[3], 8'h84) ^ gf8_mult_comp(P[4], 8'h09);
                P[6] = PP[1] ^ gf8_mult_comp(P[0], 8'hcb) ^ gf8_mult_comp(P[1], 8'h59) ^ gf8_mult_comp(P[2], 8'h14) ^ gf8_mult_comp(P[3], 8'h89) ^ gf8_mult_comp(P[4], 8'h19) ^ gf8_mult_comp(P[5], 8'h10);
                P[7] = PP[0] ^ P[0] ^ P[1] ^ P[2] ^ P[3] ^ P[4] ^ P[5] ^ P[6];
            end

            // -------------------------------------------------------------------
            // t=5: 10 parity bytes, RS(256, 246)
            // -------------------------------------------------------------------
            2'b1x: begin
                // Eliminate PP[1] from rows 2..9
                PP[2] ^= PP[1];
                PP[3] ^= PP[1];
                PP[4] ^= PP[1];
                PP[5] ^= PP[1];
                PP[6] ^= PP[1];
                PP[7] ^= PP[1];
                PP[8] ^= PP[1];
                PP[9] ^= PP[1];

                // Pivot PP[2]
                PP[2]  = gf8_mult_comp(PP[2], 8'h02);
                PP[3] ^= gf8_mult_comp(PP[2], 8'h99);
                PP[4] ^= gf8_mult_comp(PP[2], 8'h04);
                PP[5] ^= gf8_mult_comp(PP[2], 8'h49);
                PP[6] ^= gf8_mult_comp(PP[2], 8'hdb);
                PP[7] ^= gf8_mult_comp(PP[2], 8'h66);
                PP[8] ^= gf8_mult_comp(PP[2], 8'h0a);
                PP[9] ^= gf8_mult_comp(PP[2], 8'ha9);

                // Pivot PP[3]
                PP[3]  = gf8_mult_comp(PP[3], 8'h08);
                PP[4] ^= gf8_mult_comp(PP[3], 8'h01);
                PP[5] ^= gf8_mult_comp(PP[3], 8'h18);
                PP[6] ^= gf8_mult_comp(PP[3], 8'h12);
                PP[7] ^= gf8_mult_comp(PP[3], 8'h4e);
                PP[8] ^= gf8_mult_comp(PP[3], 8'h0d);
                PP[9] ^= gf8_mult_comp(PP[3], 8'hd4);

                // Pivot PP[4]
                PP[4]  = gf8_mult_comp(PP[4], 8'h8c);
                PP[5] ^= gf8_mult_comp(PP[4], 8'hff);
                PP[6] ^= gf8_mult_comp(PP[4], 8'he6);
                PP[7] ^= gf8_mult_comp(PP[4], 8'h58);
                PP[8] ^= gf8_mult_comp(PP[4], 8'hf4);
                PP[9] ^= gf8_mult_comp(PP[4], 8'h82);

                // Pivot PP[5]
                PP[5]  = gf8_mult_comp(PP[5], 8'hb7);
                PP[6] ^= gf8_mult_comp(PP[5], 8'h71);
                PP[7] ^= gf8_mult_comp(PP[5], 8'h2c);
                PP[8] ^= gf8_mult_comp(PP[5], 8'h5d);
                PP[9] ^= gf8_mult_comp(PP[5], 8'ha7);

                // Pivot PP[6]
                PP[6]  = gf8_mult_comp(PP[6], 8'heb);
                PP[7] ^= gf8_mult_comp(PP[6], 8'h2a);
                PP[8] ^= gf8_mult_comp(PP[6], 8'h9e);
                PP[9] ^= gf8_mult_comp(PP[6], 8'ha3);

                // Pivot PP[7]
                PP[7]  = gf8_mult_comp(PP[7], 8'h66);
                PP[8] ^= gf8_mult_comp(PP[7], 8'hc0);
                PP[9] ^= gf8_mult_comp(PP[7], 8'hde);

                // Pivot PP[8]
                PP[8]  = gf8_mult_comp(PP[8], 8'hf4);
                PP[9] ^= gf8_mult_comp(PP[8], 8'h0d);

                // Pivot PP[9]
                PP[9]  = gf8_mult_comp(PP[9], 8'h67);

                // Back-substitution: resolve P[0..9]
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
    end : p_gen_PROC

endmodule
