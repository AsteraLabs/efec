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
// rs256_t4_dec.sv
// Author  : V. Shvydun
// Design  : Parallel decoder for extended RS(256, 248) over GF(2^8), t=4.
// Details : 10-clock-cycle pipeline latency.
//           Input codeword width: 256 bytes (248 data + 8 parity).
// =============================================================================


// ---------------------------------------------------------------------------
// Module : ea_unr_t4
// Purpose: Extended Euclidean Algorithm, unrolled across 2*t=8 pipeline stages.
//          Computes error-locator polynomial L(x) and error-evaluator
//          polynomial O(x) from the 2t syndromes S[0..7].  Each pipeline
//          stage advances the GCD by one step; results are available after
//          2*t clock cycles.
// ---------------------------------------------------------------------------
module ea_unr_t4 #(
    parameter t = 4,
    parameter w = 8,
    parameter n = 256
) (
    // Inputs
    input  logic                    clk,
    input  logic                    rstn,
    input  logic                    init,
    input  logic [2*t-1:0][w-1:0]  S,
    // Outputs
    output logic                    ready,
    output logic                    no_error,
    output logic                    last_symbol_error,
    output logic   [t:0][w-1:0]    L,
    output logic [t-1:0][w-1:0]    O,
    output logic         [w-1:0]   S0
);

    localparam R_max    = 3 * t;
    localparam ea_depth = 2 * t;

    // ---------------------------------------------------------------------------
    // FSM state and pipeline registers
    // ---------------------------------------------------------------------------
    typedef enum logic [2:0] { IDLE, LOAD_S, CALC, SHIFT_Q, SHIFT_R, COPY_R } FSM;
    FSM curr_state [2*t];
    FSM next_state [2*t];

    logic [R_max:0][w-1:0] R [2*t];
    logic [R_max:0][w-1:0] Q [2*t];

    // 3 bits suffices for t=4: degree range 0..4
    logic [2:0] deg_R [2*t];
    logic [2:0] deg_Q [2*t];

    logic [w-1:0] S0_local [2*t];

    // ---------------------------------------------------------------------------
    // Combinational helper signals
    // ---------------------------------------------------------------------------
    logic [2*t-1:1] swap;
    always_comb begin : swap_PROC
        for (int i = 1; i < 2*t; i++)
            swap[i] = deg_Q[i-1] > deg_R[i-1];
    end : swap_PROC

    wire zero_syndrome          = S == '0;
    wire last_symbol_error_flag = (S[2*t-1:1] == '0) & (S[0] != '0);

    logic [w-1:0] R_lead [2*t-1:1];
    logic [w-1:0] Q_lead [2*t-1:1];

    always_comb begin : lead_extract_PROC
        for (int i = 1; i < 2*t; i++) R_lead[i] = R[i-1][R_max];
        for (int i = 1; i < 2*t; i++) Q_lead[i] = Q[i-1][R_max];
    end : lead_extract_PROC

    logic [2*t-1:1] zero_R_lead;
    logic [2*t-1:1] zero_Q_lead;

    always_comb begin : zero_lead_PROC
        for (int i = 1; i < 2*t; i++) zero_R_lead[i] = R_lead[i] == '0;
        for (int i = 1; i < 2*t; i++) zero_Q_lead[i] = Q_lead[i] == '0;
    end : zero_lead_PROC

    logic [w-1:0] selected_lead [2*t];

    always_comb begin : sel_lead_PROC
        selected_lead[0] = S[2*t-1];
        for (int i = 1; i < 2*t; i++)
            selected_lead[i] = (next_state[i] == SHIFT_Q) ? Q[i-1][R_max-1] : R_lead[i];
    end : sel_lead_PROC

    logic [w-1:0] inv_lead [2*t];
    always_comb begin : inv_lead_PROC
        for (int i = 0; i < 2*t; i++)
            inv_lead[i] = gf8_inv_comp(selected_lead[i]);
    end : inv_lead_PROC

    logic [w-1:0] M [2*t-1:1];
    always_comb begin : M_PROC
        for (int i = 1; i < 2*t; i++)
            M[i] = gf8_mult_comp(R_lead[i], Q_lead[i]);
    end : M_PROC

    // ---------------------------------------------------------------------------
    // No-error / last-symbol-error shift registers (match 2*t pipeline depth)
    // ---------------------------------------------------------------------------
    logic [2*t-1:0] proc_vld;
    logic [2*t-1:0] no_error_local;
    logic [2*t-1:0] last_symbol_error_local;

    always_ff @(posedge clk, negedge rstn) begin : no_err_shift_PROC
        if (!rstn) begin
            no_error_local          <= '0;
            last_symbol_error_local <= '0;
            for (int i = 0; i < 2*t; i++) S0_local[i] <= '0;
        end else begin
            no_error_local          <= {no_error_local[2*t-2:0],          zero_syndrome & init};
            last_symbol_error_local <= {last_symbol_error_local[2*t-2:0], last_symbol_error_flag & init};
            S0_local[0] <= S[0];
            for (int i = 1; i < 2*t; i++) S0_local[i] <= S0_local[i-1];
        end
    end : no_err_shift_PROC

    // proc_vld[0] is combinational; proc_vld[j] is registered for j >= 1
    always_comb proc_vld[0] = init;

    always_ff @(posedge clk, negedge rstn) begin : proc_vld_PROC
        if (!rstn) proc_vld[2*t-1:1] <= '0;
        else       proc_vld[2*t-1:1] <= proc_vld[2*t-2:0];
    end : proc_vld_PROC

    // ---------------------------------------------------------------------------
    // FSM next-state logic
    // Stage 0 enters LOAD_S when init fires on a correctable syndrome.
    // Stages 1..2t-1 advance the GCD; each stage derives its next state from
    // the previous stage's current state and the lead-coefficient flags.
    // ---------------------------------------------------------------------------
    always_comb begin : fsm_next_PROC
        if (init & !zero_syndrome & !last_symbol_error_flag)
            next_state[0] = LOAD_S;
        else
            next_state[0] = IDLE;

        for (int i = 1; i < 2*t; i++) begin
            next_state[i] = IDLE;
            case (curr_state[i-1])
                IDLE:    next_state[i] = IDLE;
                COPY_R:  next_state[i] = COPY_R;
                LOAD_S:  if (zero_Q_lead[i])        next_state[i] = SHIFT_Q;
                         else if (zero_R_lead[i])   next_state[i] = SHIFT_R;
                         else                       next_state[i] = CALC;
                SHIFT_Q: if (!zero_Q_lead[i])       next_state[i] = CALC;
                         else if (deg_Q[i-1] > 'd1) next_state[i] = SHIFT_Q;
                         else                       next_state[i] = proc_vld[i] ? COPY_R : IDLE;
                SHIFT_R: if (deg_R[i-1] < 1)        next_state[i] = proc_vld[i] ? COPY_R : IDLE;
                         else if (zero_R_lead[i])   next_state[i] = SHIFT_R;
                         else                       next_state[i] = CALC;
                CALC:    if (zero_R_lead[i])        next_state[i] = SHIFT_R;
                         else                       next_state[i] = CALC;
            endcase
        end
    end : fsm_next_PROC

    // ---------------------------------------------------------------------------
    // FSM state registers
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk, negedge rstn) begin : fsm_state_PROC
        if (!rstn)
            for (int i = 0; i < 2*t; i++) curr_state[i] <= IDLE;
        else
            for (int i = 0; i < 2*t; i++) curr_state[i] <= next_state[i];
    end : fsm_state_PROC

    // ---------------------------------------------------------------------------
    // Polynomial degree tracking registers
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk, negedge rstn) begin : deg_PROC
        if (!rstn) begin
            for (int j = 0; j < 2*t; j++) deg_R[j] <= '0;
            for (int j = 0; j < 2*t; j++) deg_Q[j] <= '0;
        end else begin
            if (next_state[0] == LOAD_S)
                begin deg_R[0] <= t[2:0]; deg_Q[0] <= t[2:0]; end

            for (int j = 1; j < 2*t; j++)
                case (next_state[j])
                    SHIFT_Q: begin
                        deg_R[j] <= deg_R[j-1];
                        deg_Q[j] <= deg_Q[j-1] - 1;
                    end
                    SHIFT_R: begin
                        deg_R[j] <= deg_R[j-1] - 1;
                        deg_Q[j] <= deg_Q[j-1];
                    end
                    CALC: begin
                        deg_R[j] <= (swap[j] ? deg_Q[j-1] : deg_R[j-1]) - 'd1;
                        deg_Q[j] <=  swap[j] ? deg_R[j-1] : deg_Q[j-1];
                    end
                endcase
        end
    end : deg_PROC

    // ---------------------------------------------------------------------------
    // R/Q polynomial pipeline registers
    // LOAD_S  : initialise R = S(x)*x,  Q = inv(lc(S))*S(x)*x + 1
    // CALC    : one GCD elimination step; swap R<->Q if deg(Q) > deg(R)
    // SHIFT_Q : divide out leading coefficient of Q (shift polynomial left)
    // SHIFT_R : divide out leading coefficient of R
    // COPY_R  : propagate final result to the last stage
    // No reset: FSM ensures R/Q are always initialised via LOAD_S before use.
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk) begin : RQ_PROC
        if (next_state[0] == LOAD_S) begin
            R[0] <= {S[2*t-2:0], {t{8'h00}}, 8'h01, 8'h00};
            Q[0] <= {inv_lead[0], S[2*t-2:0], {t{8'h00}}, 8'h01};
        end

        for (int j = 1; j < 2*t; j++)
            case (next_state[j])
                CALC: begin
                    for (int i = 1; i <= R_max; i++)
                        R[j][i] <= R[j-1][i-1] ^ gf8_mult_comp(Q[j-1][i-1], M[j]);
                    R[j][0] <= '0;
                    if (swap[j]) begin
                        for (int i = 0; i < R_max; i++) Q[j][i] <= R[j-1][i];
                        Q[j][R_max] <= inv_lead[j];
                    end else
                        for (int i = 0; i <= R_max; i++) Q[j][i] <= Q[j-1][i];
                end
                SHIFT_Q: begin
                    for (int i = 1; i < R_max; i++)
                        {Q[j][i], R[j][i]} <= {Q[j-1][i-1], R[j-1][i-1]};
                    {Q[j][0],     R[j][0]}    <= '0;
                    {Q[j][R_max], R[j][R_max]} <= {inv_lead[j], R[j-1][R_max-1]};
                end
                SHIFT_R: begin
                    for (int i = 1; i <= R_max; i++) R[j][i] <= R[j-1][i-1];
                    R[j][0] <= '0;
                    for (int i = 0; i <= R_max; i++) Q[j][i] <= Q[j-1][i];
                end
                COPY_R: begin
                    for (int i = 1; i <= R_max; i++) R[j][i] <= R[j-1][i];
                    R[j][0] <= '0;
                end
            endcase
    end : RQ_PROC

    // ---------------------------------------------------------------------------
    // Output extraction from the final pipeline stage (byte-indexed).
    // R is stored MSB-first; field layout for t=4 (R_max=12):
    //   R[7][12:9] -> O[3:0]   (error-evaluator coefficients)
    //   R[7][8:4]  -> L[4:0]   (error-locator coefficients; L[0]=1 at R[7][4])
    // ---------------------------------------------------------------------------
    assign {O, L} = {R[2*t-1][R_max -: t], R[2*t-1][2*t : t]};

    always_comb begin : output_PROC
        no_error          = no_error_local[2*t-1];
        S0                = S0_local[2*t-1];
        last_symbol_error = last_symbol_error_local[2*t-1];
    end : output_PROC

    always_ff @(posedge clk, negedge rstn) begin : ready_PROC
        if (!rstn) ready <= 1'b0;
        else       ready <= proc_vld[2*t-1];
    end : ready_PROC

endmodule


// ---------------------------------------------------------------------------
// Module : ec_t4
// Purpose: Error correction via Chien search and Forney formula.
//          For each symbol position i (0..254): evaluates L(alpha^i) to find
//          roots (Chien), then computes the error magnitude as
//          O(alpha^i) / L'(alpha^i) (Forney), where L'(x) is the formal
//          derivative of L(x) (odd-indexed terms only over GF(2^m)).
//          Symbol 255 is the overall parity byte, recovered from S[0].
// ---------------------------------------------------------------------------
module ec_t4 #(
    parameter t = 4,
    parameter w = 8,
    parameter n = 256
) (
    // Inputs
    input  logic                    clk,
    input  logic                    rstn,
    input  logic                    init,
    input  logic                    no_error,
    input  logic                    last_symbol_error,
    input  logic   [t:0][w-1:0]    L,
    input  logic [t-1:0][w-1:0]    O,
    input  logic         [w-1:0]   S0,
    // Outputs
    output logic [n-1:0][w-1:0]    ecp,
    output logic                    ready,
    // Performance monitor / statistics
    output logic         [n-1:0]   pm_symbol_err,
    output logic                    pm_no_error,
    output logic                    pm_1_error,
    output logic                    pm_2_error,
    output logic                    pm_3_error,
    output logic                    pm_4_error,
    output logic                    pm_fail
);

    // ---------------------------------------------------------------------------
    // Internal signals
    // ---------------------------------------------------------------------------
    logic [n-2:0][w-1:0] chien;        // L(alpha^i) for i = 0..254
    logic [n-2:0][w-1:0] chien_odd;    // odd-term sum of L: L'(alpha^i) denominator
    logic [n-2:0][w-1:0] forney;       // O(alpha^i) numerator
    logic [n-2:0]        zero;         // 1 iff L(alpha^i) == 0 (root found)
    logic [n-2:0][w-1:0] corr_pattern;
    logic                init_rt;
    logic                no_error_rt;
    logic                last_symbol_error_rt;
    logic        [w-1:0] S0_rt;
    logic        [2:0]   L_poly_deg;

    // ---------------------------------------------------------------------------
    // Chien search: L(alpha^i) = sum_k L[k] * H[k][i],  H[k][i] = alpha^(k*i)
    // ---------------------------------------------------------------------------
    always_comb begin : chien_PROC
        for (int i = 0; i < n-1; i++)
            chien[i] = gf8_mult_comp(L[4], H[4][i]) ^
                       gf8_mult_comp(L[3], H[3][i]) ^
                       gf8_mult_comp(L[2], H[2][i]) ^
                       gf8_mult_comp(L[1], H[1][i]) ^
                       gf8_mult_comp(L[0], H[0][i]);
    end : chien_PROC

    // ---------------------------------------------------------------------------
    // Registered: chien_odd, forney, zero, and ea_unr output metadata
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk, negedge rstn) begin : ec_reg_PROC
        if (!rstn) begin
            for (int i = 0; i < n-1; i++) chien_odd[i] <= '0;
            for (int i = 0; i < n-1; i++) forney[i]    <= '0;
            for (int i = 0; i < n-1; i++) zero[i]      <= '0;
            S0_rt                <= '0;
            no_error_rt          <= '0;
            last_symbol_error_rt <= '0;
            init_rt              <= '0;
            L_poly_deg           <= '0;
        end else begin
            if (init) begin
                if (!no_error & !last_symbol_error) begin
                    // Formal derivative L'(x): only odd-indexed terms survive over GF(2^m)
                    for (int i = 0; i < n-1; i++)
                        chien_odd[i] <= gf8_mult_comp(L[3], H[3][i]) ^
                                        gf8_mult_comp(L[1], H[1][i]);
                    // Forney numerator O(alpha^i)
                    for (int i = 0; i < n-1; i++)
                        forney[i] <= gf8_mult_comp(O[3], H[3][i]) ^
                                     gf8_mult_comp(O[2], H[2][i]) ^
                                     gf8_mult_comp(O[1], H[1][i]) ^
                                     gf8_mult_comp(O[0], H[0][i]);
                end
                for (int i = 0; i < n-1; i++)
                    zero[i] <= (!no_error & !last_symbol_error) & (chien[i] == 8'h00);
                S0_rt                <= S0;
                no_error_rt          <= no_error;
                last_symbol_error_rt <= last_symbol_error;
                L_poly_deg           <= poly_degree(L);
            end
            init_rt <= init;
        end
    end : ec_reg_PROC

    // ---------------------------------------------------------------------------
    // Error pattern and output correction
    // Forney formula: e[i] = O(alpha^i) / L'(alpha^i)  at roots of L(x)
    // ---------------------------------------------------------------------------
    logic [2:0] err_num;

    always_comb begin : correction_PROC
        for (int i = 0; i < n-1; i++)
            corr_pattern[i] = (zero[i] & !no_error_rt & !last_symbol_error_rt)
                              ? gf8_div_comp(forney[i], chien_odd[i])
                              : 8'h00;

        // Symbol positions 0..253 are stored in reverse order in the codeword array
        for (int i = 0; i < 254; i++) begin
            ecp[i]           = corr_pattern[253 - i];
            pm_symbol_err[i] = zero[253 - i];
        end
        ecp[254]           = corr_pattern[254];
        pm_symbol_err[254] = zero[254];

        // Symbol 255: overall parity — recover from S[0] XOR all correction values
        ecp[255] = S0_rt;
        for (int i = 0; i < n-1; i++) ecp[255] ^= corr_pattern[i];
        pm_symbol_err[255] = |ecp[255];

        err_num = root_num(zero[n-2:0]);
        ready   = init_rt;

        pm_no_error = no_error_rt;
        pm_1_error  = !no_error_rt & (L_poly_deg == err_num) & (L_poly_deg == 3'd1);
        pm_2_error  = !no_error_rt & (L_poly_deg == err_num) & (L_poly_deg == 3'd2);
        pm_3_error  = !no_error_rt & (L_poly_deg == err_num) & (L_poly_deg == 3'd3);
        pm_4_error  = !no_error_rt & (L_poly_deg == err_num) & (L_poly_deg == 3'd4);

        // Symbol 255 error shifts the corrected-symbol count up by one
        if (pm_symbol_err[255]) begin
            if (pm_3_error) begin pm_3_error = 1'b0; pm_4_error = 1'b1; end
            if (pm_2_error) begin pm_2_error = 1'b0; pm_3_error = 1'b1; end
            if (pm_1_error) begin pm_1_error = 1'b0; pm_2_error = 1'b1; end
        end

        pm_fail = !no_error_rt & (L_poly_deg != err_num);
        if (last_symbol_error_rt) begin pm_1_error = 1'b1; pm_fail = 1'b0; end
    end : correction_PROC

    // ---------------------------------------------------------------------------
    // Helper functions
    // ---------------------------------------------------------------------------

    // poly_degree: return degree of L(x) from its non-zero coefficients
    function automatic [2:0] poly_degree (input [t:0][w-1:0] poly);
        casex ({|poly[4], |poly[3], |poly[2], |poly[1]})
            4'b1xxx:  return 3'd4;
            4'b01xx:  return 3'd3;
            4'b001x:  return 3'd2;
            4'b0001:  return 3'd1;
            default:  return 3'd0;
        endcase
    endfunction

    // root_num: count set bits in zero[] using a two-level tree adder
    function automatic [2:0] root_num (input [n-2:0] z);
        logic [31:0][3:0] sum_8;
        logic      [7:0]  sum_128;

        for (int i = 0; i < 31; i++)
            sum_8[i] = z[i*8+7] + z[i*8+6] + z[i*8+5] + z[i*8+4] +
                       z[i*8+3] + z[i*8+2] + z[i*8+1] + z[i*8+0];
        sum_8[31] = z[31*8+6] + z[31*8+5] + z[31*8+4] + z[31*8+3] +
                    z[31*8+2] + z[31*8+1] + z[31*8+0];

        sum_128 =
            sum_8[31][2:0] + sum_8[30][2:0] + sum_8[29][2:0] + sum_8[28][2:0] +
            sum_8[27][2:0] + sum_8[26][2:0] + sum_8[25][2:0] + sum_8[24][2:0] +
            sum_8[23][2:0] + sum_8[22][2:0] + sum_8[21][2:0] + sum_8[20][2:0] +
            sum_8[19][2:0] + sum_8[18][2:0] + sum_8[17][2:0] + sum_8[16][2:0] +
            sum_8[15][2:0] + sum_8[14][2:0] + sum_8[13][2:0] + sum_8[12][2:0] +
            sum_8[11][2:0] + sum_8[10][2:0] + sum_8[ 9][2:0] + sum_8[ 8][2:0] +
            sum_8[ 7][2:0] + sum_8[ 6][2:0] + sum_8[ 5][2:0] + sum_8[ 4][2:0] +
            sum_8[ 3][2:0] + sum_8[ 2][2:0] + sum_8[ 1][2:0] + sum_8[ 0][2:0];

        return sum_128[2:0];
    endfunction

endmodule


// ---------------------------------------------------------------------------
// Module : rs256_t4_dec
// Purpose: Top-level RS(256,248) t=4 decoder.  Computes syndromes on the
//          incoming codeword (s_calc), passes them to ea_unr for polynomial
//          solving, then to ec for Chien/Forney error correction.  A one-hot
//          circular FIFO (depth = 2*t = 8) delays the raw data to align with
//          the correction pipeline; the corrected output is XORed with the
//          FIFO output.
// ---------------------------------------------------------------------------
module rs256_t4_dec #(
    parameter             t          = 4,
    parameter             w          = 8,
    parameter             n          = 256,
    localparam            FIFO_DEPTH = 2 * t
) (
    // Inputs
    input  logic                    clk,
    input  logic                    rstn,
    // Data
    input  logic [n-1:0][w-1:0]    din,
    input  logic                    din_vld,
    // Outputs
    output logic [n-1:0][w-1:0]    dout,
    output logic                    dout_vld,
    // Debug: polynomials captured at ea_ready
    output logic   [t:0][w-1:0]    pm_loc,
    output logic [t-1:0][w-1:0]    pm_out,
    output logic         [w-1:0]   pm_syn,
    // Debug: FIFO pointers
    output logic [FIFO_DEPTH-1:0]   fifo_wr_ptr,
    output logic [FIFO_DEPTH-1:0]   fifo_rd_ptr,
    // Performance monitor / statistics
    output logic         [n-1:0]   pm_symbol_err,
    output logic                    pm_no_error,
    output logic                    pm_1_error,
    output logic                    pm_2_error,
    output logic                    pm_3_error,
    output logic                    pm_4_error,
    output logic                    pm_fail
);

    // ---------------------------------------------------------------------------
    // Syndrome calculation
    // s_calc projects the codeword onto the 2*t rows of H to produce 8 syndromes.
    // A zero syndrome vector means the codeword is error-free.
    // ---------------------------------------------------------------------------
    logic [2*t-1:0][w-1:0] S;
    logic                   S_vld;

    always_ff @(posedge clk, negedge rstn) begin : syndrome_PROC
        if (!rstn) begin
            S_vld <= 1'b0;
            S     <= '0;
        end else begin
            S_vld <= din_vld;
            if (din_vld) S <= s_calc(din);
        end
    end : syndrome_PROC

    // ---------------------------------------------------------------------------
    // Extended Euclidean Algorithm instance
    // ---------------------------------------------------------------------------
    logic [t:0][w-1:0]   L;
    logic [t-1:0][w-1:0] O;
    logic        [w-1:0] S0;
    logic                ea_ready;
    logic                ea_no_error;
    logic                ea_last_symbol_error;

    ea_unr_t4 ea (
        .clk               ( clk                  ),
        .rstn              ( rstn                 ),
        .init              ( S_vld                ),
        .S                 ( S                    ),
        .ready             ( ea_ready             ),
        .no_error          ( ea_no_error          ),
        .last_symbol_error ( ea_last_symbol_error ),
        .L                 ( L                    ),
        .O                 ( O                    ),
        .S0                ( S0                   )
    );

    // ---------------------------------------------------------------------------
    // Error correction (Chien search + Forney)
    // ---------------------------------------------------------------------------
    logic [n-1:0][w-1:0] ecp;
    logic                ecp_ready;
    logic                ecp_no_error_flag;
    logic                ecp_1_error_flag;
    logic                ecp_2_error_flag;
    logic                ecp_3_error_flag;
    logic                ecp_4_error_flag;
    logic                ecp_fail_flag;
    logic        [n-1:0] ecp_symbol_err;

    ec_t4 ec (
        .clk               ( clk                  ),
        .rstn              ( rstn                 ),
        .init              ( ea_ready             ),
        .no_error          ( ea_no_error          ),
        .last_symbol_error ( ea_last_symbol_error ),
        .L                 ( L                    ),
        .O                 ( O                    ),
        .S0                ( S0                   ),
        .ecp               ( ecp                  ),
        .ready             ( ecp_ready            ),
        .pm_symbol_err     ( ecp_symbol_err       ),
        .pm_no_error       ( ecp_no_error_flag    ),
        .pm_1_error        ( ecp_1_error_flag     ),
        .pm_2_error        ( ecp_2_error_flag     ),
        .pm_3_error        ( ecp_3_error_flag     ),
        .pm_4_error        ( ecp_4_error_flag     ),
        .pm_fail           ( ecp_fail_flag        )
    );

    // ---------------------------------------------------------------------------
    // Data delay FIFO
    // One-hot circular FIFO (depth = 2*t = 8) delays raw input to align with
    // the correction pipeline.  FIFO output is XORed with ecp.
    // ---------------------------------------------------------------------------
    logic [n-1:0][w-1:0] fifo [FIFO_DEPTH-1:0];
    logic                fifo_pop;

    always_comb fifo_pop = ecp_ready;

    always_ff @(posedge clk) begin : fifo_write_PROC
        for (int i = 0; i < FIFO_DEPTH; i++)
            if (din_vld & fifo_wr_ptr[i]) fifo[i] <= din;
    end : fifo_write_PROC

    always_ff @(posedge clk, negedge rstn) begin : fifo_wr_ptr_PROC
        if (!rstn)        fifo_wr_ptr <= 'h1;
        else if (din_vld) fifo_wr_ptr <= {fifo_wr_ptr[FIFO_DEPTH-2:0], fifo_wr_ptr[FIFO_DEPTH-1]};
    end : fifo_wr_ptr_PROC

    always_ff @(posedge clk, negedge rstn) begin : fifo_rd_ptr_PROC
        if (!rstn)         fifo_rd_ptr <= 'h1;
        else if (fifo_pop) fifo_rd_ptr <= {fifo_rd_ptr[FIFO_DEPTH-2:0], fifo_rd_ptr[FIFO_DEPTH-1]};
    end : fifo_rd_ptr_PROC

    logic [255:0][7:0] fifo_out;

    always_comb begin : fifo_read_PROC
        fifo_out = '0;
        for (int i = 0; i < FIFO_DEPTH; i++)
            if (fifo_rd_ptr[i]) fifo_out |= fifo[i];
    end : fifo_read_PROC

    // ---------------------------------------------------------------------------
    // Output register: XOR correction pattern with delayed raw data
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk, negedge rstn) begin : output_PROC
        if (!rstn) begin
            dout_vld      <= '0;
            dout          <= '0;
            pm_no_error   <= '0;
            pm_symbol_err <= '0;
            pm_1_error    <= '0;
            pm_2_error    <= '0;
            pm_3_error    <= '0;
            pm_4_error    <= '0;
            pm_fail       <= '0;
            pm_loc        <= '0;
            pm_out        <= '0;
            pm_syn        <= '0;
        end else begin
            dout_vld <= ecp_ready;
            if (ecp_ready) begin
                dout          <= ecp ^ fifo_out;
                pm_no_error   <= ecp_no_error_flag;
                pm_symbol_err <= ecp_symbol_err;
                pm_1_error    <= ecp_1_error_flag;
                pm_2_error    <= ecp_2_error_flag;
                pm_3_error    <= ecp_3_error_flag;
                pm_4_error    <= ecp_4_error_flag;
                pm_fail       <= ecp_fail_flag;
                pm_loc        <= L;
                pm_out        <= O;
                pm_syn        <= S0;
            end
        end
    end : output_PROC

    // ---------------------------------------------------------------------------
    // Syndrome calculation function
    // Projects each codeword symbol onto all 2*t=8 rows of H.
    // ---------------------------------------------------------------------------
    function automatic [2*t-1:0][w-1:0] s_calc (input [n-1:0][w-1:0] CW);
        logic [2*t-1:0][w-1:0] S;
        S = '0;
        for (int x = 0; x < n; x++)
            for (int y = 0; y < 2*t; y++) S[y] ^= gf8_mult_comp(CW[x], H[y][x]);
        return S;
    endfunction

endmodule
