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

module expandmask_ext #(
    parameter SAMPLER_W   = 4,
    parameter SAMPLE_W    = 23,
    parameter W           = 64
    )(
    input  start,
    input  rst,
    input  clk,
    input  [2:0] sec_lvl,
    input  [31:0] msg_len,
    input  valid_seed,
    output reg ready_for_seed,
    input  [W-1:0] seed_i,
    output reg [W-1:0] mu_out,
    output reg mu_valid,
    output [SAMPLER_W*SAMPLE_W-1:0] samples,
    output valid_o,
    input  ready_o,
    output reg done_sampler = 0,
    // Keccak passthrough
    output reg  rst_k,
    output reg  [63:0] din,
    input [63:0] dout,   
    output reg   src_ready,
    input        src_read,
    input        dst_write,
    output reg   dst_ready
    );
    
    localparam
        S_HOLD          = 4'd0,
        S_INIT          = 4'd1,
        S_ABSORB_TR     = 4'd2,
        S_ABSORB_M      = 4'd3,
        S_HASH_MU       = 4'd4,
        S_INIT_K        = 4'd5,
        S_ABSORB_K      = 4'd6,
        S_ABSORB_MU     = 4'd7,
        S_HASH_RHO_P    = 4'd8,
        S_LOAD_SAMPLERS = 4'd9,
        S_RUN_SAMPLERS  = 4'd10,
        S_WAIT          = 4'd11;
    
    reg [3:0] cstate, nstate;
    reg [31:0] ctr, ctr_next;
    
    reg  rst_y;
    reg  [31:0] ctrl_len;

   
    reg [511:0] SEED_SIPO = 0;
    reg [7:0]   SIPO_status = 0;
   
    reg  [15:0] NONCE = 0, OFFSET = 0;
    reg [15:0] L;
    wire ready_i, done;
    reg  valid_seed_sampler, start_y;
    reg  [W-1:0] seed_i_sampler;

    // gen sampler
    wire rst_k_y;
    wire [63:0] din_y;
    wire        src_ready_y;
    wire        dst_ready_y;
    

    reg [31:0] msg_bytes;
    always @(posedge clk) begin
        msg_bytes <= msg_len;
    end

    sampler_y_ext SAMPLER_Y (start_y, rst_y, clk, sec_lvl, NONCE+OFFSET, valid_seed_sampler, ready_i, seed_i_sampler, 
                                samples, valid_o, ready_o, done, rst_k_y, din_y, dout, src_ready_y, src_read,
                                dst_write, dst_ready_y);                
   
    always @(*) begin
        src_ready = 1;
        nstate    = cstate;
        ready_for_seed = 0;
        din = 0;
        dst_ready = 0;
        valid_seed_sampler = 0;
        seed_i_sampler = 0;
        ctr_next = 0 ;
        
        case(sec_lvl)
        2: begin
            L = 4;
        end
        3: begin
            L = 5;
        end
        default: begin
            L = 7;
        end
        endcase
        
        rst_k = 0;
        
        case(cstate)
        S_HOLD: begin
            nstate = (start) ? S_INIT : S_HOLD;
            rst_k = 1;
        end
        S_INIT: begin
            // load in ctrl block
            src_ready = 0;
            ctrl_len = {msg_bytes, 3'd0}+ 32'h100;
            din = {32'hE0000200, ctrl_len}; 
            nstate = (src_read) ? S_ABSORB_TR : S_INIT;
        end
        S_ABSORB_TR: begin
            din = seed_i;
            src_ready      = ~valid_seed;
            ready_for_seed = src_read;
            
            ctr_next = (src_read) ? ctr + 1 : ctr;
            nstate = (ctr_next == 4) ? S_ABSORB_M : S_ABSORB_TR;
        end
        S_ABSORB_M: begin
            din = seed_i;
            src_ready      = ~valid_seed;
            ready_for_seed = src_read;
            
            ctr_next = (src_read) ? ctr + 1 : ctr;
            nstate = ({ctr_next, 3'd0} >= msg_bytes) ? S_HASH_MU : S_ABSORB_M;
        end
        S_HASH_MU: begin
            dst_ready = 1;
            
            nstate = (dst_write && SIPO_status[6]) ? S_INIT_K : S_HASH_MU;

        end
        S_INIT_K: begin
            // load in ctrl block
            src_ready = 0;
            ctrl_len = 32'h300;
            din = {32'hE0000200, ctrl_len}; 
            nstate = (src_read) ? S_ABSORB_K : S_INIT_K;
        end
        S_ABSORB_K: begin
            din = seed_i;
            src_ready      = ~valid_seed;
            ready_for_seed = src_read;
            
            ctr_next = (src_read) ? ctr + 1 : ctr;
            nstate = (ctr_next == 4) ? S_ABSORB_MU : S_ABSORB_K;
        end
        S_ABSORB_MU: begin
            din = SEED_SIPO[511:448];
            src_ready = 0;
            nstate = (SIPO_status == 1 && src_read) ? S_HASH_RHO_P : S_ABSORB_MU;
        end
        S_HASH_RHO_P: begin
            dst_ready = 1;
            
            nstate = (dst_write && SIPO_status[6]) ? S_LOAD_SAMPLERS : S_HASH_RHO_P;
            rst_k = (dst_write && SIPO_status[6]) ? 1 : 0;
        end
        S_LOAD_SAMPLERS: begin
            valid_seed_sampler = 1;
            seed_i_sampler = SEED_SIPO[511:448];
            
            ctr_next = ctr + 1;
            nstate = (ctr == 7 && &ready_i) ? S_RUN_SAMPLERS : S_LOAD_SAMPLERS;
            
            rst_k = rst_k_y;
            din   = din_y;
            src_ready = src_ready_y;
            dst_ready = dst_ready_y;
        end
        S_RUN_SAMPLERS: begin
            nstate = (done && NONCE == L-1) ? S_WAIT
                   : (done) ? S_LOAD_SAMPLERS : S_RUN_SAMPLERS;
                   
            rst_k = rst_k_y;
            din   = din_y;
            src_ready = src_ready_y;
            dst_ready = dst_ready_y;
        end
        S_WAIT: begin
            nstate = (start) ? S_LOAD_SAMPLERS : S_WAIT;
        end
        endcase
    
    
    end
   
   
    initial begin
        cstate = S_HOLD;
        nstate = S_HOLD;
        ctr    = 0;
    end
        
    always @(posedge clk) begin
        if (rst) begin
            cstate <= S_HOLD;
            rst_y  <= 1;
        end else begin
            rst_y <= 0;
            cstate <= nstate;
        end
    end
    
    
    always @(posedge clk) begin
        done_sampler <= 0;
        start_y <= 0;
    
        mu_valid <= 0;
    
        case(cstate)
        S_HOLD: begin
            NONCE  <= 0;
            OFFSET <= 0;

            SIPO_status <= 0;
        end
        S_ABSORB_TR: begin
            ctr <= (ctr_next == 4) ? 0 : ctr_next;
        end
        S_ABSORB_M: begin
            ctr <= ({ctr_next, 3'd0} >= msg_bytes) ? 0 : ctr_next;
        end
        S_HASH_MU: begin
            mu_valid <= dst_write;
            mu_out   <= dout;
            if (dst_write) begin
                SIPO_status <= {SIPO_status[6:0],1'b1};
                SEED_SIPO   <= {SEED_SIPO[447:0], dout};
            end
        end
        S_ABSORB_K: begin
            ctr <= (ctr_next == 4) ? 0 : ctr_next;
        end
        S_ABSORB_MU: begin
            if (src_read) begin
                SIPO_status <= {1'b0, SIPO_status[7:1]};
                SEED_SIPO   <= {SEED_SIPO[447:0], 64'd0};
            end
        end
        S_HASH_RHO_P: begin
            if (dst_write) begin
                SIPO_status <= {SIPO_status[6:0],1'b1};
                SEED_SIPO   <= {SEED_SIPO[447:0], dout};
            end
            
            
            start_y <= (dst_write && SIPO_status[6]) ? 1 : 0;
        end
        S_LOAD_SAMPLERS: begin
            if (&ready_i) begin
                SEED_SIPO     <= {SEED_SIPO[447:0], SEED_SIPO[511:448]};
                ctr           <= (ctr == 7) ? 0 : ctr_next;
            end
        end
        S_RUN_SAMPLERS: begin
            start_y <= (done && NONCE < L-1) ? 1 : 0; 
        
            if (done && NONCE == L-1) begin
                done_sampler <= 1;
                OFFSET <= OFFSET+L;
                NONCE  <= 0;
            end else if (done) begin
                NONCE <= NONCE + 1; 
            end
        end
        S_WAIT: begin
            start_y <= (start) ? 1 : 0;
        end
        endcase
    end     
    
endmodule
