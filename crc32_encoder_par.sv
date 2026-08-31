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
// crc32_encoder_par.sv
//
// CRC-32 encoder for a 256-byte frame — parallel-table variant
//   Identical interface and functionality to crc32_encoder.sv.
//   The bit-serial LFSR loop is replaced with a parallel binary-matrix
//   multiply (XOR of pre-computed coefficient table entries) to allow
//   synthesis tools to generate an efficient gate-level XOR tree without
//   requiring very long loop unrolling.
//
//   Payload  : 242 bytes (PCIe data, supplied by caller)
//   Padding  : 14 bytes forced to 0x00 internally
//   Polynomial: 0xBA0DC66B (Koopman) → normal form 0x741B8CD7
//   Init      : 0x00000000  (pre-inversion;  set to 0 so that all-zero data produces a zero CRC)
//   Final XOR : 0x00000000  (post-inversion; set to 0 so that all-zero data produces a zero CRC)
//   Bit order : LSB-first (data_in[0] is the oldest/first-processed bit)
//
// DATA_WIDTH parameter (elaboration-time, not SW-configurable): 128 | 256 | 1024
//
// Parallel table:
//   parallel_crc_coef[j] = x^(1024+31-j) mod P(x),  j = 0..1023
//   Computed LSB-first (same bit ordering as the LFSR loop in crc32_encoder.sv).
//   For DATA_WIDTH < 1024 the table is indexed at offset 1024-DATA_WIDTH,
//   so the same 1024-entry file covers all three supported widths.
//
//   CRC state injection: for each word, r_crc[31-i] is XOR'd into
//   combined_data[i] for i=0..31 before the table lookup.  This is the
//   GF(2)-linear recurrence continuation term T^DW(crc_prev), identical
//   to the feedback used in crc32 koopman enc.
//   On the first word of a frame r_crc = CRC_INIT = 0x00000000, so no
//   state is injected on the first word.
//
// All sequential logic, port list, parameters, and functional behaviour are
// identical to crc32_encoder.sv.
// =============================================================================

module crc32_encoder #(
    parameter int DATA_WIDTH = 256          // 128 | 256 | 1024
) (
    // Clock / reset
    input  logic                    clk,
    input  logic                    rst_n,      // async active-low reset

    // Control
    input  logic                    clear,      // synchronous reset of CRC state & counter
    input  logic                    halt_in,    // back-pressure: hold all state

    // Data input
    input  logic                    valid_in,   // data_in is valid this cycle
    input  logic [DATA_WIDTH-1:0]   data_in,    // input word; bit 0 is oldest bit
    input  logic                    last_in,    // last word of the 256-byte frame
                                                // (qualified by valid_in)

    // CRC output (one-cycle pipeline delay after last_in, matches reference)
    output logic [31:0]             crc_out,    // CRC-32 result
    output logic                    crc_valid   // one-cycle pulse: crc_out is valid
);

// ---------------------------------------------------------------------------
// Parameter validation (simulation-time; synthesis ignores initial blocks)
// ---------------------------------------------------------------------------
// pragma translate_off
initial begin : param_check
    if (DATA_WIDTH != 128 && DATA_WIDTH != 256 && DATA_WIDTH != 1024)
        $fatal(1, "[crc32_encoder] DATA_WIDTH must be 128, 256, or 1024 (got %0d)",
               DATA_WIDTH);
    if ((256 * 8) % DATA_WIDTH != 0)
        $fatal(1, "[crc32_encoder] DATA_WIDTH must evenly divide 2048 (got %0d)",
               DATA_WIDTH);
    if (DATA_WIDTH > 1024)
        $fatal(1, "[crc32_encoder] DATA_WIDTH must be <= 1024 for parallel table (got %0d)",
               DATA_WIDTH);
end : param_check
// pragma translate_on

// ---------------------------------------------------------------------------
// Local parameters
// ---------------------------------------------------------------------------
localparam int TOTAL_BYTES     = 256;
localparam int PAYLOAD_BYTES   = 242;
// Derived
localparam int BYTES_PER_WORD  = DATA_WIDTH / 8;                // 16 | 32 | 128
localparam int WORDS_PER_FRAME = TOTAL_BYTES / BYTES_PER_WORD;  // 16 |  8 |   2
localparam int CNT_WD          = $clog2(WORDS_PER_FRAME);       //  4 |  3 |   1

// Pad boundary (byte index 0-based; byte 242..255 are zero-padded)
localparam int PAD_WORD_IDX   = PAYLOAD_BYTES / BYTES_PER_WORD;
localparam int PAD_START_OFFS = PAYLOAD_BYTES % BYTES_PER_WORD;  // never 0 for our params

// CRC-32 polynomial (Koopman 0xBA0DC66B → normal 0x741B8CD7)
localparam logic [31:0] CRC_POLY  = 32'h741B8CD7;
localparam logic [31:0] CRC_INIT  = 32'h0000_0000;   // pre-inversion  (zero-CRC-on-zero-data behavior)
localparam logic [31:0] CRC_FXOR  = 32'h0000_0000;   // post-inversion (zero-CRC-on-zero-data behavior)

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
logic [CNT_WD-1:0]      r_word_cnt;     // which word of the frame we are on
logic [DATA_WIDTH-1:0]  s_data_padded;  // data_in with pad bytes forced to 0x00
logic [31:0]            r_crc;          // running CRC accumulator
logic [31:0]            s_crc_next;     // next-CRC combinational output
logic [31:0]            r_crc_out;
logic                   r_crc_valid;

// ---------------------------------------------------------------------------
// CRC-32 update function — parallel coefficient table
//
// Replaces the bit-serial LFSR loop with a parallel XOR-of-table-entries,
// implementing binary matrix multiplication over GF(2).  The synthesis tool
// sees a tree of independent XOR reductions rather than a long dependency
// chain, enabling much better area/timing optimisation.
//
// State injection:
//   combined[i] = data[i] ^ crc_in[31-i]  for i = 0..31
//   combined[i] = data[i]                  for i = 32..DATA_WIDTH-1
//
//   This injects the running CRC state as the GF(2) continuation term
//   T^DATA_WIDTH(crc_prev), identical to the feedback in crc32 koopman enc.
//   When crc_in = CRC_INIT = 0xFFFFFFFF (palindrome) on the first word,
//   the injection is equivalent to the SOF init XOR in crc32 koopman enc.
//
// Table index: bit i of combined uses coef[1024-DATA_WIDTH+i], so the same
// 1024-entry table works for DATA_WIDTH = 128, 256, and 1024.
// ---------------------------------------------------------------------------
function automatic logic [31:0] crc32_update (
    input logic [31:0]           crc_in,
    input logic [DATA_WIDTH-1:0] data
);
    logic [DATA_WIDTH-1:0] combined;
    logic [31:0]           c;
    combined = data;
    // Inject running CRC state (bit-reversed) into the 32 LSBs
    for (int i = 0; i < 32; i++)
        combined[i] = combined[i] ^ crc_in[31-i];
    // Parallel XOR accumulation
    c = '0;
    for (int i = 0; i < DATA_WIDTH; i++)
        if (combined[i]) c ^= parallel_crc_coef[1024-DATA_WIDTH+i];
    return c;
endfunction

// ---------------------------------------------------------------------------
// Pad masking
//
// Any byte within the current word that falls at or beyond PAYLOAD_BYTES
// is replaced with 0x00 before the CRC computation.
// Byte b within the current word occupies bits [(DATA_WIDTH-1 - b*8) -: 8].
// ---------------------------------------------------------------------------
always_comb begin : pad_mask_PROC
    s_data_padded = data_in;
    if (r_word_cnt == CNT_WD'(PAD_WORD_IDX)) begin
        for (int b = PAD_START_OFFS; b < BYTES_PER_WORD; b++)
            s_data_padded[(DATA_WIDTH-1 - b*8) -: 8] = 8'h00;
    end
end : pad_mask_PROC

// ---------------------------------------------------------------------------
// Next-CRC (combinational)
// ---------------------------------------------------------------------------
assign s_crc_next = crc32_update(r_crc, s_data_padded);

// ---------------------------------------------------------------------------
// Word counter
// Increments on every accepted word (valid_in & ~halt_in).
// Resets to 0 at frame end (last_in) or when counter reaches WORDS_PER_FRAME-1.
// ---------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin : word_cnt_PROC
    if (!rst_n) begin
        r_word_cnt <= '0;
    end else begin
        if (clear) begin
            r_word_cnt <= '0;
        end else if (valid_in && !halt_in) begin
            if (last_in || r_word_cnt == CNT_WD'(WORDS_PER_FRAME - 1))
                r_word_cnt <= '0;
            else
                r_word_cnt <= r_word_cnt + 1'b1;
        end
    end
end : word_cnt_PROC

// ---------------------------------------------------------------------------
// CRC accumulator
// Resets to CRC_INIT on:  rst_n deassertion, clear, or frame completion
// (ready for the next frame immediately after last_in).
// ---------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin : crc_accum_PROC
    if (!rst_n) begin
        r_crc <= CRC_INIT;
    end else begin
        if (clear) begin
            r_crc <= CRC_INIT;
        end else if (valid_in && !halt_in) begin
            if (last_in)
                r_crc <= CRC_INIT;  // reset: accumulator is ready for next frame
            else
                r_crc <= s_crc_next;
        end
    end
end : crc_accum_PROC

// ---------------------------------------------------------------------------
// Output register  (1-cycle pipeline delay)
// ---------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin : crc_out_PROC
    if (!rst_n) begin
        r_crc_out   <= '0;
        r_crc_valid <= 1'b0;
    end else begin
        if (clear) begin
            r_crc_out   <= '0;
            r_crc_valid <= 1'b0;
        end else if (!halt_in) begin
            r_crc_valid <= valid_in & last_in;
            if (valid_in & last_in)
                r_crc_out <= s_crc_next ^ CRC_FXOR;  // post-inversion
        end
    end
end : crc_out_PROC

assign crc_out   = r_crc_out;
assign crc_valid = r_crc_valid;

endmodule
