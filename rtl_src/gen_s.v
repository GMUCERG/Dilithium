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

module gen_s# (
    parameter SAMPLER_NUM = 1,
    parameter SAMPLER_W   = 4,
    parameter SAMPLE_W    = 23,
    parameter W           = 64
    )(
    input  start,
    input  rst,
    input  clk,
    input  [2:0] sec_lvl,
    input  valid_seed,
    output ready_for_seed,
    input  [W-1:0] seed_i,
    output [SAMPLER_NUM*SAMPLER_W*SAMPLE_W-1:0] samples,
    output [SAMPLER_NUM-1:0] valid_o,
    input  [SAMPLER_NUM-1:0] ready_o,
    output reg done_sampler,
    // Keccak passthrough
    input             keccak_ctrl,
    output            rst_k,
    output     [63:0] din,
    input      [63:0] dout,
    output            src_ready,
    input             src_read,
    input             dst_write,
    output            dst_ready
    );
    
    wire [SAMPLE_W*SAMPLER_W-1:0] sampler_output [SAMPLER_NUM-1:0];
    reg  [15:0] N [SAMPLER_NUM-1:0];
    wire [SAMPLER_NUM-1:0] ready_i, done;
    reg  [SAMPLER_NUM-1:0] valid_i, re_sample, done_latch;
    reg  [4:0] sample_state;
    reg start_s; 
    reg mode;
    genvar g;
    generate
        // unpack array
        for (g = 0; g < SAMPLER_NUM; g = g + 1) begin
            assign sampler_output[g] = samples[g*(SAMPLER_W*SAMPLE_W)+:(SAMPLER_W*SAMPLE_W)];
        end
    
        // gen sampler
        for (g = 0; g < SAMPLER_NUM; g = g + 1) begin
            sampler_s SAMPLER_S (start_s, rst, clk, re_sample[g], sec_lvl, N[g], valid_seed, ready_i[g], seed_i, 
                                    samples[g*(SAMPLER_W*SAMPLE_W)+:(SAMPLER_W*SAMPLE_W)], valid_o[g], ready_o[g], done[g],
                                    keccak_ctrl, rst_k, din, dout, src_ready, src_read, dst_write, dst_ready);                
        end
    endgenerate
    
    integer i;
    assign ready_for_seed = &ready_i;
    reg [3:0] L, K;
    
    
    initial begin
        done_sampler   = 0;
        done_latch     = 0;
        sample_state   = 0;
        mode           = 0;
        
        for (i = 0; i < SAMPLER_NUM; i = i + 1)
            re_sample[i] = 0; 
    end
    
    always @(*) begin
        for (i = 0; i < SAMPLER_NUM; i = i + 1)
            valid_i[i] = 0;
        
        case(sec_lvl)
        2: begin
             L = 4; 
             K = 4;
        end
        3: begin
            L = 5;
            K = 6;
        end
        5:  begin
            L = 7;
            K = 8;
        end
        default: begin
            L = 0;
            K = 0;
        end
        endcase    
            
        N[0] = (mode == 0) ?  sample_state : sample_state + L;
        
    end
    
    always @(posedge clk) begin
        done_latch     <= done_latch | done;
        done_sampler   <= 0;
        
        for (i = 0; i < SAMPLER_NUM; i = i + 1)
            re_sample[i] <= 0; 
        
        // If s2, then sigma is already loaded in
        if (mode == 0) begin
            start_s <= start;
        end else if(start) begin
            for (i = 0; i < SAMPLER_NUM; i = i + 1)
                re_sample[i] <= 1; 
        end

        
        if (done_latch == {SAMPLER_NUM{1'b1}}) begin
            done_latch <= 0;
            if ((mode == 0 && sample_state == L-1) || (mode == 1 && sample_state == K-1)) begin
                done_sampler <= 1;
                sample_state <= 0;
                
                if (mode == 0) begin
                    // sample S2
                    mode <= 1;
                    for (i = 0; i < SAMPLER_NUM; i = i + 1)
                        re_sample[i] <= 1; 
                end else begin
                    mode <= 0;
                end 
            end else begin
                for (i = 0; i < SAMPLER_NUM; i = i + 1)
                    re_sample[i] <= 1;
                sample_state <= sample_state + 1;
            end
        end
    
    end    
endmodule