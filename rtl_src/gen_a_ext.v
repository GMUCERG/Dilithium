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



module gen_a_ext # (
    parameter SAMPLER_NUM = 2,
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
    output [5:0] sample_state_out,
    output [SAMPLER_NUM-1:0] valid_o,
    input  [SAMPLER_NUM-1:0] ready_o,
    output reg done_sampler,
    // Keccak passthrough
    output     [SAMPLER_NUM-1:0] rst_k,
    output     [SAMPLER_NUM*64-1:0] din,
    input      [SAMPLER_NUM*64-1:0] dout,   
    output     [SAMPLER_NUM-1:0]  src_ready,
    input      [SAMPLER_NUM-1:0]  src_read,
    input      [SAMPLER_NUM-1:0]  dst_write,
    output      [SAMPLER_NUM-1:0]  dst_ready
    );
    
    wire [SAMPLE_W*SAMPLER_W-1:0] sampler_output [SAMPLER_NUM-1:0];
    reg [3:0] K [SAMPLER_NUM-1:0];
    reg [3:0] L [SAMPLER_NUM-1:0];
    wire [SAMPLER_NUM-1:0] ready_i, done;
    reg  [SAMPLER_NUM-1:0] valid_i, re_sample, done_latch;
    reg [5:0] sample_state;
    
    
    assign sample_state_out = sample_state;
    genvar g;
    generate
        // unpack array
        for (g = 0; g < SAMPLER_NUM; g = g + 1) begin
            assign sampler_output[g] = samples[g*(SAMPLER_W*SAMPLE_W)+:(SAMPLER_W*SAMPLE_W)];
        end
    
        // gen sampler
        for (g = 0; g < SAMPLER_NUM; g = g + 1) begin
            sampler_a_ext SAMPLER_A (start, rst, clk, re_sample[g], K[g], L[g], valid_seed, ready_i[g], seed_i, 
                                    samples[g*(SAMPLER_W*SAMPLE_W)+:(SAMPLER_W*SAMPLE_W)], valid_o[g], ready_o[g], done[g],
                                    rst_k[g], din[g*64+:64], dout[g*64+:64], src_ready[g], src_read[g], dst_write[g], dst_ready[g]);                
        end
    endgenerate
    
    integer i;
    assign ready_for_seed = &ready_i;
    
    initial begin
        done_sampler   = 0;
        done_latch     = 0;
        sample_state   = 0;
        
        for (i = 0; i < SAMPLER_NUM; i = i + 1)
            re_sample[i] = 0; 
    end
    
    always @(posedge clk) begin
        done_latch     <= done_latch | done;
        done_sampler   <= 0;
        
        for (i = 0; i < SAMPLER_NUM; i = i + 1)
            re_sample[i] <= 0; 
        
        if (done_latch == {SAMPLER_NUM{1'b1}}) begin
            done_latch <= 0;
            if (sec_lvl == 2 && sample_state == 14) begin
                done_sampler <= 1;
                sample_state <= 0;
            end else if (sec_lvl == 3 && sample_state == 28) begin
                done_sampler <= 1;
                sample_state <= 0;
            end else if (sec_lvl == 5 && sample_state == 54) begin
                done_sampler <= 1;
                sample_state <= 0;
            end else begin
                for (i = 0; i < SAMPLER_NUM; i = i + 1)
                    re_sample[i] <= 1;
                sample_state <= sample_state + 2;
            end
        end
    
    end

    always @(*) begin
        for (i = 0; i < SAMPLER_NUM; i = i + 1)
            valid_i[i] = valid_seed;
        
        for (i = 0; i < SAMPLER_NUM; i = i + 1)
            K[i] = {sample_state,1'd0};
        
        for (i = 0; i < SAMPLER_NUM; i = i + 1)
            L[i] = {sample_state,1'd1};
        
        case(sec_lvl) 
        2: begin
            L[0] = sample_state & 3;
            L[1] = (sample_state & 3) + 1;
            
            K[0] = sample_state >> 2;
            K[1] = sample_state >> 2;
        end
        3: begin
            (*full_case*)
            case(sample_state)
            0: begin
                L[0] = 0;
                L[1] = 1;
                K[0] = 0;
                K[1] = 0;
            end
            2: begin
                L[0] = 2;
                L[1] = 3;
                K[0] = 0;
                K[1] = 0;
            end
            4: begin
                L[0] = 4;
                L[1] = 0;
                K[0] = 0;
                K[1] = 1;
            end
            6: begin
                L[0] = 1;
                L[1] = 2;
                K[0] = 1;
                K[1] = 1;
            end
            8: begin
                L[0] = 3;
                L[1] = 4;
                K[0] = 1;
                K[1] = 1;
            end
            10: begin
                L[0] = 0;
                L[1] = 1;
                K[0] = 2;
                K[1] = 2;
            end
            12: begin
                L[0] = 2;
                L[1] = 3;
                K[0] = 2;
                K[1] = 2;
            end
            14: begin
                L[0] = 4;
                L[1] = 0;
                K[0] = 2;
                K[1] = 3;
            end
            16: begin
                L[0] = 1;
                L[1] = 2;
                K[0] = 3;
                K[1] = 3;
            end
            18: begin
                L[0] = 3;
                L[1] = 4;
                K[0] = 3;
                K[1] = 3;
            end
            20: begin
                L[0] = 0;
                L[1] = 1;
                K[0] = 4;
                K[1] = 4;
            end
            22: begin
                L[0] = 2;
                L[1] = 3;
                K[0] = 4;
                K[1] = 4;
            end
            24: begin
                L[0] = 4;
                L[1] = 0;
                K[0] = 4;
                K[1] = 5;
            end
            26: begin
                L[0] = 1;
                L[1] = 2;
                K[0] = 5;
                K[1] = 5;
            end
            default: begin
                L[0] = 3;
                L[1] = 4;
                K[0] = 5;
                K[1] = 5;
            end
            endcase
        end
        5: begin
            case(sample_state)
            0: begin
                L[0] = 0;
                L[1] = 1;
                K[0] = 0;
                K[1] = 0;
            end
            2: begin
                L[0] = 2;
                L[1] = 3;
                K[0] = 0;
                K[1] = 0;
            end
            4: begin
                L[0] = 4;
                L[1] = 5;
                K[0] = 0;
                K[1] = 0;
            end
            6: begin
                L[0] = 6;
                L[1] = 0;
                K[0] = 0;
                K[1] = 1;
            end
            8: begin
                L[0] = 1;
                L[1] = 2;
                K[0] = 1;
                K[1] = 1;
            end
            10: begin
                L[0] = 3;
                L[1] = 4;
                K[0] = 1;
                K[1] = 1;
            end
            12: begin
                L[0] = 5;
                L[1] = 6;
                K[0] = 1;
                K[1] = 1;
            end
            14: begin
                L[0] = 0;
                L[1] = 1;
                K[0] = 2;
                K[1] = 2;
            end
            16: begin
                L[0] = 2;
                L[1] = 3;
                K[0] = 2;
                K[1] = 2;
            end
            18: begin
                L[0] = 4;
                L[1] = 5;
                K[0] = 2;
                K[1] = 2;
            end
            20: begin
                L[0] = 6;
                L[1] = 0;
                K[0] = 2;
                K[1] = 3;
            end
            22: begin
                L[0] = 1;
                L[1] = 2;
                K[0] = 3;
                K[1] = 3;
            end
            24: begin
                L[0] = 3;
                L[1] = 4;
                K[0] = 3;
                K[1] = 3;
            end
            26: begin
                L[0] = 5;
                L[1] = 6;
                K[0] = 3;
                K[1] = 3;
            end
            28: begin
                L[0] = 0;
                L[1] = 1;
                K[0] = 4;
                K[1] = 4;
            end
            30: begin
                L[0] = 2;
                L[1] = 3;
                K[0] = 4;
                K[1] = 4;
            end
            32: begin
                L[0] = 4;
                L[1] = 5;
                K[0] = 4;
                K[1] = 4;
            end
            34: begin
                L[0] = 6;
                L[1] = 0;
                K[0] = 4;
                K[1] = 5;
            end
            36: begin
                L[0] = 1;
                L[1] = 2;
                K[0] = 5;
                K[1] = 5;
            end
            38: begin
                L[0] = 3;
                L[1] = 4;
                K[0] = 5;
                K[1] = 5;
            end
            40: begin
                L[0] = 5;
                L[1] = 6;
                K[0] = 5;
                K[1] = 5;
            end
            42: begin
                L[0] = 0;
                L[1] = 1;
                K[0] = 6;
                K[1] = 6;
            end
            44: begin
                L[0] = 2;
                L[1] = 3;
                K[0] = 6;
                K[1] = 6;
            end
            46: begin
                L[0] = 4;
                L[1] = 5;
                K[0] = 6;
                K[1] = 6;
            end
            48: begin
                L[0] = 6;
                L[1] = 0;
                K[0] = 6;
                K[1] = 7;
            end
            50: begin
                L[0] = 1;
                L[1] = 2;
                K[0] = 7;
                K[1] = 7;
            end
            52: begin
                L[0] = 3;
                L[1] = 4;
                K[0] = 7;
                K[1] = 7;
            end
            default: begin
                L[0] = 5;
                L[1] = 6;
                K[0] = 7;
                K[1] = 7;
            end
            endcase
        end
        endcase
        
    end
    
endmodule
