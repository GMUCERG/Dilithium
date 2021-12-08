/*
 * From our research paper "High-Performance Hardware Implementation of CRYSTALS-Dilithium"
 * by Luke Beckwith, Duc Tri Nguyen, Kris Gaj
 * at George Mason University, USA
 * https://eprint.iacr.org/2021/1451.pdf
 * =============================================================================
 * Copyright (c) 2021 by Cryptographic Engineering Research Group (CERG)
 * ECE Department, George Mason University
 * Fairfax, VA, U.S.A.
 * Author: Luke Beckwith
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =============================================================================
 * @author   Luke Beckwith <lbeckwit@gmu.edu>
 */


`timescale 1ns / 1ps


module encoder #(
    parameter OUTPUT_W    = 4,
    parameter COEFF_W     = 23,
    parameter MAX_LVL     = 20,
    parameter W           = 64
    ) (
    input rst,
    input clk,
    input [2:0] sec_lvl,
    input [2:0] encode_mode,
    input  valid_i,
    output reg ready_i,
    input [OUTPUT_W*COEFF_W-1:0] di,
    output reg [W-1:0] dout,
    output reg valid_o,
    input  ready_o
    );
    
    reg [4:0] ENCODE_LVL;
    reg [2:0] mode;
    
    localparam
        DILITHIUM_Q = 23'd8380417,
        ENCODE_T0   = 3'd0,
        ENCODE_T1   = 3'd1,
        ENCODE_S1   = 3'd2,
        ENCODE_S2   = 3'd3,
        ENCODE_W1   = 3'd4,
        ENCODE_Z    = 3'd5;
    
    localparam
        NONE   = 3'd0,
        ETA    = 3'd1,
        T0     = 3'd2,
        T1     = 3'd3,
        GAMMA1 = 3'd4;
    
    wire [OUTPUT_W*COEFF_W-1:0] di_uncentered;
    reg  [OUTPUT_W*COEFF_W-1:0] di_uncentered_buffer;
    wire [MAX_LVL*OUTPUT_W-1:0]  stripped;
    
    reg [OUTPUT_W*COEFF_W-1:0] di_buffer;

    reg [1:0] valid_buffer;

    genvar i;
    generate
        for (i = 0; i < OUTPUT_W; i = i + 1) begin
            uncenter_coeff UNCENTER (sec_lvl, mode, di_buffer[23*i+:23], di_uncentered[23*i+:23]);
        end
    endgenerate

    zero_strip Z_STRIP(ENCODE_LVL, di_uncentered_buffer, stripped);
    
    reg [255:0] PISO;
    reg [9:0]  piso_len, piso_len_next;
    reg [9:0] buffer_len [1:0];
    
    initial begin
        PISO = 0;
        piso_len = 0;        
    end
    
    always @(*) begin
       /* ----- decoder lane connection ----- */
        ENCODE_LVL = 0;
        mode = NONE;
        
        casex({sec_lvl, encode_mode})
        {3'dX, ENCODE_T0}: begin
            ENCODE_LVL = 13;
            mode = T0;
        end
        {3'dX, ENCODE_T1}: begin
            ENCODE_LVL = 10;
            mode = T1;
        end
        {3'd2, ENCODE_S2},
        {3'd5, ENCODE_S2},
        {3'd2, ENCODE_S1},
        {3'd5, ENCODE_S1}: begin
            ENCODE_LVL = 3;
            mode = ETA;
        end
        {3'd3, ENCODE_S2},
        {3'd3, ENCODE_S1}: begin
            ENCODE_LVL = 4;
            mode = ETA;
        end   
        {3'd3, ENCODE_W1},
        {3'd5, ENCODE_W1}: begin
            ENCODE_LVL = 4;
        end
        {3'd2, ENCODE_W1}: begin
            ENCODE_LVL = 6;
        end
        {3'd2, ENCODE_Z}: begin
            ENCODE_LVL = 18;
            mode = GAMMA1;
        end
        {3'd3, ENCODE_Z},
        {3'd5, ENCODE_Z}: begin
            ENCODE_LVL = 20;
            mode = GAMMA1;
        end
        endcase
    
        
        valid_o = (piso_len >= W) ? 1 : 0; 
        piso_len_next = (valid_o && ready_o) ? piso_len - W: piso_len;   
        ready_i = 1;
        
        dout = PISO[W-1:0];
    end
    
    always @(posedge clk) begin
        
        di_uncentered_buffer <= di_uncentered;

        valid_buffer[0] <= ready_i && valid_i;
        valid_buffer[1] <= valid_buffer[0];

        buffer_len[0] <= (ready_i && valid_i) ? 4*ENCODE_LVL : 0;
        buffer_len[1] <= buffer_len[0];
        piso_len <= piso_len_next + buffer_len[1];

        di_buffer <= di;
        if (rst) begin
            piso_len <= 0;
            PISO     <= 0;
        end else begin
            if (valid_buffer[1]) begin
                if (valid_o && ready_o) begin
                    PISO <= (PISO >> W) | ({192'd0, stripped} << piso_len_next);
                end else begin
                    PISO <= PISO | ({192'd0, stripped} << piso_len_next);    
                end
            end else if (valid_o && ready_o) begin
                PISO <= (PISO >> W);
            end
        end
    end
    
endmodule
