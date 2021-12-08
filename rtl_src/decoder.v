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


module decoder #(
    parameter OUTPUT_W    = 4,
    parameter COEFF_W     = 23,
    parameter W           = 64
    ) (
    input rst,
    input clk,
    input [2:0] sec_lvl,
    input [2:0] encode_modei,
    input  valid_i,
    output reg ready_i,
    input  [W-1:0] di,
    output reg [OUTPUT_W*COEFF_W-1:0] samples,
    output reg valid_o,
    input  ready_o
    );
    reg [W-1:0] di_buffer;
    localparam
        DILITHIUM_Q = 23'd8380417,
        ENCODE_T0   = 3'd0,
        ENCODE_T1   = 3'd1,
        ENCODE_S1   = 3'd2,
        ENCODE_S2   = 3'd3,
        ENCODE_W1   = 3'd4,
        ENCODE_Z    = 3'd5;
    
    localparam
        GAMMA1_2  = 23'd131072,
        GAMMA1_35 = 23'd524288;
    
    
    reg [2:0] encode_mode;
    reg [3*W-1:0]                SIPO_IN, SIPO_IN_SHIFT;
    reg [199:0] SIPO_OUT;
    reg [4*COEFF_W-1:0]          sipo_out_in, sipo_out_in_shift;

    reg [8:0] sipo_in_len, sipo_in_len_next;
    reg [7:0] sipo_out_len, sipo_out_len_next;
    reg [3:0] ETA;

    reg [2*W-1:0] di_shift;
    
    reg [5:0] ENCODE_LVL;
    integer i;
    
    initial begin
        SIPO_IN  = 0;
        SIPO_OUT = 0;
    
        sipo_in_len  = 0;
        sipo_out_len = 0;
    end
    
    always @(*) begin    
        ETA = 0;
        
        /* ----- decoder lane connection ----- */
        ENCODE_LVL = 0;
        for (i = 0; i < 4; i = i + 1)
            sipo_out_in[i*COEFF_W+:COEFF_W] = 0;
        
        casex({sec_lvl, encode_mode})
        {3'dX, ENCODE_T0}: begin
            ENCODE_LVL = 13;
            for (i = 0; i < 4; i = i + 1)
                sipo_out_in[i*COEFF_W+:COEFF_W] =  (SIPO_IN[i*13+:13] > 4096) ? DILITHIUM_Q - SIPO_IN[i*13+:13] + 4096 : 4096 - SIPO_IN[i*13+:13];

        end
        {3'dX, ENCODE_T1}: begin
            ENCODE_LVL = 10;
            for (i = 0; i < 4; i = i + 1)
                sipo_out_in[i*COEFF_W+:COEFF_W] = {SIPO_IN[i*10+:10], 13'd0};
        end
        {3'd2, ENCODE_S2},
        {3'd5, ENCODE_S2},
        {3'd2, ENCODE_S1},
        {3'd5, ENCODE_S1}: begin
            ENCODE_LVL = 3;
            ETA = 2;
            for (i = 0; i < 4; i = i + 1)
                sipo_out_in[i*COEFF_W+:COEFF_W] = (SIPO_IN[i*3+:3] > ETA) ? DILITHIUM_Q - SIPO_IN[i*3+:3] + ETA : ETA - SIPO_IN[i*3+:3];
        end
        {3'd3, ENCODE_S2},
        {3'd3, ENCODE_S1}: begin
            ENCODE_LVL = 4;
            ETA        = 4;
            for (i = 0; i < 4; i = i + 1)
                sipo_out_in[i*COEFF_W+:COEFF_W] = (SIPO_IN[i*4+:4] > ETA) ? DILITHIUM_Q - SIPO_IN[i*4+:4] + ETA : ETA - SIPO_IN[i*4+:4];
        end   
        {3'd3, ENCODE_W1},
        {3'd5, ENCODE_W1}: begin
            ENCODE_LVL = 4;
            for (i = 0; i < 4; i = i + 1)
                sipo_out_in[i*COEFF_W+:COEFF_W] = SIPO_IN[i*4+:4];
        end
        {3'd2, ENCODE_W1}: begin
            ENCODE_LVL = 6;
            for (i = 0; i < 4; i = i + 1)
                sipo_out_in[i*COEFF_W+:COEFF_W] = SIPO_IN[i*6+:6];
        end
        {3'd2, ENCODE_Z}: begin
            ENCODE_LVL = 18;
            for (i = 0; i < 4; i = i + 1) begin
                if (sipo_in_len >= (i+1)*18)
                    sipo_out_in[i*COEFF_W+:COEFF_W] = (SIPO_IN[i*18+:18] > GAMMA1_2) ? GAMMA1_2 + (DILITHIUM_Q - SIPO_IN[i*18+:18]) : GAMMA1_2 - SIPO_IN[i*18+:18];
            end
        end
        {3'd3, ENCODE_Z},
        {3'd5, ENCODE_Z}: begin
            ENCODE_LVL = 20;
            for (i = 0; i < 4; i = i + 1) begin
                if (sipo_in_len >= (i+1)*20)
                    sipo_out_in[i*COEFF_W+:COEFF_W] = (SIPO_IN[i*20+:20] > GAMMA1_35) ? GAMMA1_35 + DILITHIUM_Q - SIPO_IN[i*20+:20] : GAMMA1_35 - SIPO_IN[i*20+:20];
            end
        end
        endcase
        
        
        valid_o = (sipo_out_len >= OUTPUT_W*COEFF_W) ? 1 : 0; 
        ready_i = (sipo_in_len < 4*ENCODE_LVL || (valid_o && 4*ENCODE_LVL > 63)) ? 1 : 0;
        
        sipo_in_len_next  = (ready_i && valid_i) ? sipo_in_len + W : sipo_in_len;
        sipo_out_len_next = (valid_o && ready_o) ? sipo_out_len - OUTPUT_W*COEFF_W: sipo_out_len;   
        
        samples = SIPO_OUT[OUTPUT_W*COEFF_W-1:0];

        SIPO_IN_SHIFT = (SIPO_IN >> 4*ENCODE_LVL);

        if (valid_o && ready_o) begin   
            sipo_out_in_shift = sipo_out_in << (sipo_out_len - OUTPUT_W*COEFF_W);  
        end else begin
            sipo_out_in_shift = sipo_out_in << sipo_out_len;
        end

        if (sipo_in_len >= 4*ENCODE_LVL) begin
            di_shift = ({64'd0, di} << (sipo_in_len - 4*ENCODE_LVL));
        end else begin
            di_shift = ({64'd0, di} << sipo_in_len);
        end
    end
    
    always @(posedge clk) begin
        encode_mode <= encode_modei;
        if (rst) begin
            SIPO_IN  <= 0;
            SIPO_OUT <= 0;
            sipo_in_len  <= 0;
            sipo_out_len <= 0;  
        end else begin
            if (sipo_out_len_next <= OUTPUT_W*COEFF_W) begin
                if (sipo_in_len >= 4*ENCODE_LVL) begin
                    sipo_in_len  <= sipo_in_len_next  - 4*ENCODE_LVL;
                    sipo_out_len <= sipo_out_len_next + 4*COEFF_W;
                    
                    if (valid_i) begin
                        SIPO_IN <= SIPO_IN_SHIFT | di_shift;
                    end else begin
                        SIPO_IN <= SIPO_IN_SHIFT;
                    end
                end else begin
                    sipo_in_len  <= sipo_in_len_next;
                    sipo_out_len <= sipo_out_len_next;
                    
                    if (valid_i) begin
                        SIPO_IN <= SIPO_IN | di_shift;
                    end else begin
                        SIPO_IN <= SIPO_IN;
                    end
                end
            end else begin
                sipo_in_len  <= sipo_in_len_next;
                sipo_out_len <= sipo_out_len_next;
            end
            
            if (valid_o && ready_o) begin   
                if (sipo_in_len >= ENCODE_LVL) begin
                    SIPO_OUT <= (SIPO_OUT >> OUTPUT_W*COEFF_W) | sipo_out_in_shift;  
                end else begin
                    SIPO_OUT <= SIPO_OUT >> OUTPUT_W*COEFF_W;
                end
            end else if (sipo_in_len >= ENCODE_LVL) begin
                SIPO_OUT <= SIPO_OUT | sipo_out_in_shift;
            end
        end 
    end
    
endmodule
