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


module rejection_y #(
    parameter W            = 64,
    parameter SAMPLE_W     = 23,
    parameter BUS_W        = 4
    )(
        input  rst,
        input  clk,
        input [2:0] sec_lvl,
        input  valid_i,
        output reg ready_i,
        input  [W-1:0] rdi,
        output reg [SAMPLE_W*BUS_W-1:0] samples = 0,
        output reg valid_o = 0,
        input  ready_o
    );
    
    wire [4:0] RDI_SAMPLE_W;
    assign RDI_SAMPLE_W = (sec_lvl == 2) ? 18 : 20;
    
    
    localparam
        DILITHIUM_Q = 23'd8380417,
        GAMMA2_LIMIT  = 20'd131072,
        GAMMA3_5_LIMIT   = 20'd524288;    
    
    wire [19:0] GAMMA_LIMIT;
    assign GAMMA_LIMIT = (sec_lvl == 2) ? GAMMA2_LIMIT : GAMMA3_5_LIMIT;
    
    reg [79:0]  SIPO_IN, SIPO_IN_SHIFT;
    reg [137:0] SIPO_OUT;
    reg [3*SAMPLE_W-1:0] sipo_out_in;
    
    reg [19:0] rej_lane0, rej_lane1, rej_lane2;
    
    reg [22:0] sample0, sample1, sample2;
    reg rej_lane0_valid, rej_lane1_valid, rej_lane2_valid;
    reg [1:0] num_valid;
    
    reg [6:0] sipo_in_len, sipo_in_len_next;
    reg [7:0] sipo_out_len, sipo_out_len_next;
    
    reg [10:0] SHIFT_IN_AMT;
    
    
    always @(*) begin
        ready_i = (sipo_in_len < 3*RDI_SAMPLE_W) ? 1 : 0;
        valid_o = (sipo_out_len >= SAMPLE_W*BUS_W) ? 1 : 0; 
    
        if (sec_lvl == 2) begin
            rej_lane0 = {2'd0, SIPO_IN[17:0]};
            rej_lane1 = {2'd0, SIPO_IN[35:18]};
            rej_lane2 = {2'd0, SIPO_IN[53:36]};
        end else begin
            rej_lane0 = {SIPO_IN[19:0]};
            rej_lane1 = {SIPO_IN[39:20]};
            rej_lane2 = {SIPO_IN[59:40]};
        end
        
        if (sipo_in_len >= 3*RDI_SAMPLE_W) begin
            SHIFT_IN_AMT = 3*RDI_SAMPLE_W;
        end else if (sipo_in_len >= 2*RDI_SAMPLE_W) begin
            SHIFT_IN_AMT = 2*RDI_SAMPLE_W;
        end else if (sipo_in_len >= RDI_SAMPLE_W) begin
            SHIFT_IN_AMT = RDI_SAMPLE_W;
        end else begin
            SHIFT_IN_AMT = 0;
        end
        
        
        sample0 = (rej_lane0 > GAMMA_LIMIT) ? GAMMA_LIMIT + DILITHIUM_Q - rej_lane0 : GAMMA_LIMIT - rej_lane0;
        sample1 = (rej_lane1 > GAMMA_LIMIT) ? GAMMA_LIMIT + DILITHIUM_Q - rej_lane1 : GAMMA_LIMIT - rej_lane1;
        sample2 = (rej_lane2 > GAMMA_LIMIT) ? GAMMA_LIMIT + DILITHIUM_Q - rej_lane2 : GAMMA_LIMIT - rej_lane2;
        
        
        rej_lane0_valid = (sipo_in_len >= RDI_SAMPLE_W) ? 1 : 0;
        rej_lane1_valid = (sipo_in_len >= 2*RDI_SAMPLE_W) ? 1 : 0;
        rej_lane2_valid = (sipo_in_len >= 3*RDI_SAMPLE_W) ? 1 : 0;
        num_valid       = rej_lane0_valid + rej_lane1_valid + rej_lane2_valid;
        
        if (rej_lane0_valid == 0)
            sample0 = 0;
        if (rej_lane1_valid == 0)
            sample1 = 0;
        if (rej_lane2_valid == 0)
            sample2 = 0;
        
        sipo_in_len_next  = (ready_i && valid_i) ? sipo_in_len + W : sipo_in_len;
        sipo_out_len_next = (valid_o && ready_o) ? sipo_out_len - SAMPLE_W*BUS_W: sipo_out_len;      
        
        SIPO_IN_SHIFT = (SIPO_IN >> SHIFT_IN_AMT);

        sipo_out_in = {sample2, sample1, sample0}; 
        samples = SIPO_OUT[SAMPLE_W*BUS_W-1:0];
    end
    
    initial begin
        SIPO_IN  = 0;
        SIPO_OUT = 0;
    
        sipo_in_len  = 0;
        sipo_out_len = 0;
    end
    
    always @(posedge clk) begin
            
        sipo_in_len <= sipo_in_len_next - SHIFT_IN_AMT;
        if (valid_i) begin
            SIPO_IN <= SIPO_IN_SHIFT | (rdi << sipo_in_len - SHIFT_IN_AMT);
        end else begin
            SIPO_IN <= SIPO_IN_SHIFT;
        end
        
        if (num_valid == 1) begin
            sipo_out_len <= sipo_out_len_next + SAMPLE_W;
        end else if (num_valid == 2) begin
            sipo_out_len <= sipo_out_len_next + 2*SAMPLE_W;
        end else if (num_valid == 3) begin
            sipo_out_len <= sipo_out_len_next + 3*SAMPLE_W;
        end else begin
            sipo_out_len <= sipo_out_len_next;
        end
        
        if (valid_o) begin   
            if (num_valid != 0) begin
                SIPO_OUT <= (SIPO_OUT >> SAMPLE_W*BUS_W) | sipo_out_in << sipo_out_len_next;
            end else begin
                SIPO_OUT <= SIPO_OUT >> SAMPLE_W*BUS_W;
            end
        end else if (num_valid >0) begin
            SIPO_OUT <= SIPO_OUT | sipo_out_in << sipo_out_len;
        end
        
        if (rst) begin
            SIPO_IN  <= 0;
            SIPO_OUT <= 0;
        
            sipo_in_len  <= 0;
            sipo_out_len <= 0;         
        end   
    end
    
endmodule
