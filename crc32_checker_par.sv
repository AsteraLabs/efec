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
// crc32_checker_par.sv
//
// CRC-32 checker for a 256-byte frame — parallel-table variant
//   Identical interface and functionality to crc32_checker.sv.
//   The bit-serial LFSR loop is replaced with a parallel binary-matrix
//   multiply (XOR of pre-computed coefficient table entries).
//
//   Payload  : 242 bytes (received PCIe data)
//   Padding  : 14 bytes forced to 0x00 internally (identical to encoder)
//   Polynomial: 0xBA0DC66B (Koopman) → normal form 0x741B8CD7
//   Init      : 0x00000000  (pre-inversion;  set to 0 so that all-zero data produces a zero CRC)
//   Final XOR : 0x00000000  (post-inversion; set to 0 so that all-zero data produces a zero CRC)
//   Bit order : LSB-first (data_in[0] is the oldest/first-processed bit)
//
// FLIT_WIDTH is fixed at 2048 bits; DIN_WD = FLIT_WIDTH - 14*8 = 1936 bits.
// The parallel coefficient table covers 1024 entries (coef[j] = x^(1024+31-j)
// mod P(x)).  Since FLIT_WIDTH = 2 × 1024, the 2048-bit CRC computation is
// split into two sequential 1024-bit rounds inside crc32_update, both fully
// combinational within a single clock cycle:
//
//   Round 1: s_data_padded[1023:0]   — lower 1024 bits (pure payload)
//            State in  = r_crc (running accumulator)
//            State out = c0
//
//   Round 2: s_data_padded[2047:1024] — upper 1024 bits
//            = { 112'h0 (pad zeros), data_in[DIN_WD-1:1024] }
//            State in  = c0
//            State out = s_crc_next  (the final 32-bit CRC)
//
// The two-round decomposition is correct by GF(2) linearity:
//   CRC(crc_prev, D[2047:0]) = CRC( CRC(crc_prev, D[1023:0]), D[2047:1024] )
//
// All sequential logic, port list, parameters, and functional behaviour are
// identical to crc32_checker.sv.
// =============================================================================

module crc32_checker #(
    parameter FLIT_WIDTH = 2048,
    parameter DIN_WD     = FLIT_WIDTH - (14*8)  // Flit width less the FEC and CRC
) (
    // Clock / reset
    input  logic          clk,
    input  logic          rst_n,       // async active-low reset

    // Control
    input  logic          clear,       // synchronous reset of CRC state & counter
    input  logic          halt_in,     // back-pressure: hold all state

    // Data input
    input  logic          valid_in,    // data_in is valid this cycle
    input  logic [DIN_WD-1:0] data_in,     // received word; byte 0 at data_in[1023:1016]
    input  logic          last_in,     // last word of the 256-byte frame
                                       // (qualified by valid_in)

    // Received CRC to check (present and stable when valid_in & last_in = 1)
    input  logic [31:0]   crc_in,      // received CRC; same format as encoder's crc_out

    // Check result (one-cycle pipeline delay after last_in, same as encoder)
    output logic          crc_valid,   // one-cycle pulse: crc_error is valid
    output logic          crc_error    // 1 = CRC mismatch detected; 0 = correct
);

// pragma translate_off
initial begin : param_check
    if (FLIT_WIDTH != 2048)
        $fatal(1, "[crc32_checker] FLIT_WIDTH must be 2048 for parallel-table variant (got %0d)",
               FLIT_WIDTH);
end : param_check
// pragma translate_on

localparam logic [31:0] CRC_POLY = 32'h741B8CD7;   // normal form of 0xBA0DC66B
localparam logic [31:0] CRC_INIT = 32'h0000_0000;  // pre-inversion  (zero-CRC-on-zero-data behavior)
localparam logic [31:0] CRC_FXOR = 32'h0000_0000;  // post-inversion (zero-CRC-on-zero-data behavior)

// ---------------------------------------------------------------------------
// Parallel coefficient table
//   1024 packed entries: coef[j] = x^(1024+31-j) mod P(x),  j = 0..1023
//   Generated LSB-first.
//   Verification: coef[1023] = x^32 mod P(x) = 0x741B8CD7 = CRC_POLY
// ---------------------------------------------------------------------------
localparam logic [0:1023][31:0] parallel_crc_coef = {
`include "crc32_koopman_table.svh"
};

// ---------------------------------------------------------------------------
// Signal declarations
// ---------------------------------------------------------------------------
logic [FLIT_WIDTH-1:0]      s_data_padded;   // data_in with pad bytes forced to 0x00
logic [31:0]        r_crc;           // running CRC accumulator
logic [31:0]        s_crc_next;      // next-CRC combinational output
logic               r_crc_valid;
logic               r_crc_error;

// ---------------------------------------------------------------------------
// CRC-32 update function — parallel coefficient table, two 1024-bit rounds
//
// FLIT_WIDTH = 2048 bits is processed as two sequential 1024-bit rounds,
// both evaluated combinationally within a single clock cycle.
//
// The 1024-entry table covers one round (DW=1024):
//   crc_next = XOR_{i: combined[i]=1} coef[i]
// where coef[i] = x^(1024+31-i) mod P(x).
//
// State injection per round: combined[i] = data[i] ^ state[31-i], i=0..31
//   This injects the running state as the GF(2) continuation term T^1024(state),
//   identical to the crc32 koopman encoder feedback.
//
// Round split for 2048-bit input:
//   Round 1: data[1023:0]   — lower half (pure payload for DIN_WD=1936)
//   Round 2: data[2047:1024] — upper half
//            = s_data_padded[2047:1024]
//            = { 112'h0 (pad zeros at MSB), data_in[DIN_WD-1:1024] }
//   Zeros in round 2 bits [1023:912] contribute nothing to the XOR sum.
// ---------------------------------------------------------------------------
function automatic logic [31:0] crc32_update (
    input logic [31:0]           crc_state,
    input logic [FLIT_WIDTH-1:0] data
);
    logic [1023:0] ch0, ch1;
    logic [31:0]   c0,  c1;

    // Round 1: lower 1024 bits with incoming CRC state
    ch0 = data[1023:0];
    for (int i = 0; i < 32; i++)
        ch0[i] = ch0[i] ^ crc_state[31-i];
    c0 = '0;
    for (int i = 0; i < 1024; i++)
        if (ch0[i]) c0 ^= parallel_crc_coef[i];

    // Round 2: upper 1024 bits with state from round 1
    // data[2047:1024] = { pad_zeros[111:0], data_in[DIN_WD-1:1024] }
    ch1 = data[2047:1024];
    for (int i = 0; i < 32; i++)
        ch1[i] = ch1[i] ^ c0[31-i];
    c1 = '0;
    for (int i = 0; i < 1024; i++)
        if (ch1[i]) c1 ^= parallel_crc_coef[i];

    return c1;
endfunction

always_comb begin : pad_mask_PROC
    s_data_padded = {(FLIT_WIDTH-DIN_WD)'(0), data_in};
end : pad_mask_PROC

// ---------------------------------------------------------------------------
// Next-CRC (combinational)
// ---------------------------------------------------------------------------
assign s_crc_next = crc32_update(r_crc, s_data_padded);

// ---------------------------------------------------------------------------
// CRC accumulator
// Resets to CRC_INIT on rst_n, clear, or frame completion (last_in), so
// the checker is ready for the next frame on the very next valid cycle.
// ---------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin : crc_accum_PROC
    if (!rst_n) begin
        r_crc <= CRC_INIT;
    end else begin
        if (clear) begin
            r_crc <= CRC_INIT;
        end else if (valid_in && !halt_in) begin
            if (last_in)
                r_crc <= CRC_INIT;   // reset: ready for next frame immediately
            else
                r_crc <= s_crc_next;
        end
    end
end : crc_accum_PROC

// ---------------------------------------------------------------------------
// Output register (1-cycle pipeline delay, mirrors crc32_encoder.sv)
//
// crc_valid pulses for exactly one cycle, one clock after last_in is sampled.
// halt_in holds crc_valid=1 and crc_error stable until released.
// crc_error is latched at the same edge as crc_valid:
//   computed = s_crc_next ^ CRC_FXOR  (post-inversion, same as encoder's crc_out)
//   crc_error = 1  when computed != crc_in
// ---------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin : crc_out_PROC
    if (!rst_n) begin
        r_crc_valid <= 1'b0;
        r_crc_error <= 1'b0;
    end else begin
        if (clear) begin
            r_crc_valid <= 1'b0;
            r_crc_error <= 1'b0;
        end else if (!halt_in) begin
            r_crc_valid <= valid_in & last_in;
            if (valid_in & last_in)
                r_crc_error <= ((s_crc_next ^ CRC_FXOR) != crc_in);
        end
    end
end : crc_out_PROC

assign crc_valid = r_crc_valid;
assign crc_error = r_crc_error;

endmodule
