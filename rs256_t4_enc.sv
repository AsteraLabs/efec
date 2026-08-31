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
// rs256_t4_enc.sv
// Author  : V. Shvydun
// Design  : Parallel encoder for extended RS(256, 248) over GF(2^8), t=4.
// Details : 2-clock-cycle pipeline latency.
//           Input data width: 248 bytes; output codeword: 256 bytes.
// =============================================================================


// ---------------------------------------------------------------------------
// Module : rs256_t4_enc
// Purpose: Top-level RS(256,248) t=4 encoder.  Instantiates p_gen_t4 to
//          compute 8 parity bytes, then registers the full codeword
//          (248 data bytes followed by 8 parity bytes).
// ---------------------------------------------------------------------------
module rs256_t4_enc #(
    parameter n = 256,
    parameter k = 248,
    parameter w = 8
) (
    // Inputs
    input  logic                    clk,
    // Data
    input  logic [k-1:0][w-1:0]    din,
    input  logic                    din_vld,
    // Outputs
    output logic [n-1:0][w-1:0]    dout,
    output logic                    dout_vld
);

    localparam t = (n - k) / 2;

    // ---------------------------------------------------------------------------
    // Parity generation
    // ---------------------------------------------------------------------------
    logic [n-1:0][w-1:0] dout_tmp;
    logic [2*t-1:0][w-1:0] P;

    p_gen_t4 p_gen (
        .din ( din ),
        .P   ( P   )
    );

    // Assemble codeword: data bytes in [k-1:0], parity bytes in [n-1:k]
    always_comb begin : assemble_PROC
        for (int i = 0; i < k; i++) dout_tmp[i] = din[i];
        for (int x = k; x < n; x++) dout_tmp[x] = P[x - k];
    end : assemble_PROC

    always_ff @(posedge clk) begin : output_PROC
        dout     <= dout_tmp;
        dout_vld <= din_vld;
    end : output_PROC

endmodule


// ---------------------------------------------------------------------------
// Module : p_gen_t4
// Purpose: Combinational parity generator for RS(256,248) t=4.
//          Computes 8 parity bytes P[0..7] from 248 data bytes.
//
//          Algorithm (two passes):
//          Pass 1 — Project data onto the 2*t=8 syndrome rows of H:
//                     PP[y] = XOR_x( din[x] * H[y][x] )  for y=0..7
//          Pass 2 — Gaussian elimination on PP to triangularize the parity
//                   generator matrix.  Steps are labeled by elimination row
//                   (descending from 2*t-4 down to 0).  Back-substitution
//                   then yields P[0..7].
// ---------------------------------------------------------------------------
module p_gen_t4 #(
    parameter n = 256,
    parameter k = 248,
    parameter w = 8,
    parameter t = (n - k) / 2
) (
    // Inputs
    input  logic [k-1:0][w-1:0]    din,
    // Outputs
    output logic [2*t-1:0][w-1:0]  P
);

    logic [2*t-1:0][w-1:0] PP;

    always_comb begin : parity_PROC
        // Pass 1: project data onto syndrome rows
        PP = '0;
        for (int y = 0; y < 2*t; y++)
            for (int x = 0; x < k; x++) PP[y] ^= gf8_mult_comp(din[x], H[y][x]);

        // Pass 2: Gaussian elimination (pivot row by row, then back-substitute)
        PP[2] ^= PP[1];
        PP[3] ^= PP[1];
        PP[4] ^= PP[1];
        PP[5] ^= PP[1];
        PP[6] ^= PP[1];
        PP[7] ^= PP[1];

        // Elimination step 5: pivot PP[2]
        PP[2]  = gf8_mult_comp(PP[2], 8'h02);
        PP[3] ^= gf8_mult_comp(PP[2], 8'h99);
        PP[4] ^= gf8_mult_comp(PP[2], 8'h04);
        PP[5] ^= gf8_mult_comp(PP[2], 8'h49);
        PP[6] ^= gf8_mult_comp(PP[2], 8'hdb);
        PP[7] ^= gf8_mult_comp(PP[2], 8'h66);

        // Elimination step 4: pivot PP[3]
        PP[3]  = gf8_mult_comp(PP[3], 8'h08);
        PP[4] ^= gf8_mult_comp(PP[3], 8'h01);
        PP[5] ^= gf8_mult_comp(PP[3], 8'h18);
        PP[6] ^= gf8_mult_comp(PP[3], 8'h12);
        PP[7] ^= gf8_mult_comp(PP[3], 8'h4e);

        // Elimination step 3: pivot PP[4]
        PP[4]  = gf8_mult_comp(PP[4], 8'h8c);
        PP[5] ^= gf8_mult_comp(PP[4], 8'hff);
        PP[6] ^= gf8_mult_comp(PP[4], 8'he6);
        PP[7] ^= gf8_mult_comp(PP[4], 8'h58);

        // Elimination step 2: pivot PP[5]
        PP[5]  = gf8_mult_comp(PP[5], 8'hb7);
        PP[6] ^= gf8_mult_comp(PP[5], 8'h71);
        PP[7] ^= gf8_mult_comp(PP[5], 8'h2c);

        // Elimination step 1: pivot PP[6]
        PP[6]  = gf8_mult_comp(PP[6], 8'heb);
        PP[7] ^= gf8_mult_comp(PP[6], 8'h2a);

        // Elimination step 0: pivot PP[7]
        PP[7]  = gf8_mult_comp(PP[7], 8'h66);

        // Back-substitution to extract parity bytes P[0..7]
        P[0] = PP[7];
        P[1] = PP[6] ^ gf8_mult_comp(P[0], 8'h06);
        P[2] = PP[5] ^ gf8_mult_comp(P[0], 8'hce) ^ gf8_mult_comp(P[1], 8'hcd);
        P[3] = PP[4] ^ gf8_mult_comp(P[0], 8'h95) ^ gf8_mult_comp(P[1], 8'hfc) ^ gf8_mult_comp(P[2], 8'h94);
        P[4] = PP[3] ^ gf8_mult_comp(P[0], 8'h41) ^ gf8_mult_comp(P[1], 8'h3e) ^ gf8_mult_comp(P[2], 8'h02) ^ gf8_mult_comp(P[3], 8'h80);
        P[5] = PP[2] ^ gf8_mult_comp(P[0], 8'h6b) ^ gf8_mult_comp(P[1], 8'hea) ^ gf8_mult_comp(P[2], 8'h0f) ^ gf8_mult_comp(P[3], 8'h84) ^ gf8_mult_comp(P[4], 8'h09);
        P[6] = PP[1] ^ gf8_mult_comp(P[0], 8'hcb) ^ gf8_mult_comp(P[1], 8'h59) ^ gf8_mult_comp(P[2], 8'h14) ^ gf8_mult_comp(P[3], 8'h89) ^ gf8_mult_comp(P[4], 8'h19) ^ gf8_mult_comp(P[5], 8'h10);
        P[7] = PP[0] ^               P[0]          ^               P[1]          ^               P[2]          ^               P[3]          ^               P[4]          ^               P[5]          ^               P[6];
    end : parity_PROC

endmodule
