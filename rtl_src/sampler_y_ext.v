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


module sampler_y_ext #(
    parameter W        = 64,
    parameter SAMPLE_W = 23,
    parameter BUS_W    = 4
    )(
    input  start,
    input  rst,
    input  clk,
    input [2:0]  sec_lvl,
    input [15:0] nonce,
    input  valid_i,
    output reg ready_i,
    input  [W-1:0] seed_i,
    output [SAMPLE_W*BUS_W-1:0] samples,
    output reg valid_o,
    input  ready_o,
    output reg done,
    // Keccak passthrough
    output reg  rst_k,
    output reg  [63:0] din,
    input [63:0] dout,   
    output reg   src_ready,
    input        src_read,
    input        dst_write,
    output       dst_ready
    );
    
    localparam 
        INIT             = 3'd0,
        LOAD_MODE        = 3'd1,
        WAITING_FOR_SEED = 3'd2,
        LOADING_SEED     = 3'd3,
        LOADING_NONCE    = 3'd4,
        SAMPLING         = 3'd5;
    reg [2:0] state, state_next;    
    
    reg [511:0] SEED_SIPO;
    reg [7:0]   SIPO_status;
     
    reg [7:0] sample_ctr;
    reg  rst_y;
    wire [63:0] din_rejy;
    
    assign din_rejy = {dout[7:0],dout[15:8], dout[23:16], dout[31:24], dout[39:32], dout[47:40],dout[55:48], dout[63:56]};
    wire valid_o_y;
    reg  ready_o_y;
    rejection_y REJ(
            rst_y, clk, sec_lvl, dst_write, dst_ready, din_rejy, samples, valid_o_y, ready_o_y
        );
        
    initial begin
        state      = INIT;
        rst_k      = 0;
        rst_y      = 0;
        SEED_SIPO  = 0;
        sample_ctr = 0;
        
    end    
        
        
    always @(*) begin
        state_next = state;
        ready_i    = 0;
        done       = 0;
        din        = 0;
        ready_o_y = 0;
        valid_o   = 0;
        
        case(state)
        INIT: begin
            state_next = (start) ? LOAD_MODE : INIT;
        end
        LOAD_MODE: begin
            din = 64'hE00f000000000210;        
            if (src_read) begin
                state_next = WAITING_FOR_SEED;
            end 
        end
        WAITING_FOR_SEED: begin
            ready_i = (valid_i) ? 1 : 0;
            if (SIPO_status[6] == 1 && valid_i) begin
                state_next = LOADING_SEED;
            end
        end
        LOADING_SEED: begin
            din = SEED_SIPO[511:448];
            if (SIPO_status == 1 && src_read) begin
                state_next = LOADING_NONCE;
            end
        end
        LOADING_NONCE: begin
            din = {nonce[7:0], nonce[15:8], 48'd0};
            if (src_read) begin
                state_next = SAMPLING;
            end
        end
        SAMPLING: begin
            ready_o_y = ready_o;
            valid_o   = valid_o_y;
            if (sample_ctr == 252 && ready_o && valid_o_y) begin
                state_next = INIT;
                done       = 1;
            end
        end
        endcase
    
    end    
        
    always @(posedge clk) begin
        if (rst) begin
            state <= INIT;
        end else begin
            state <= state_next;
        end
    end
    
    always @(posedge clk) begin
        src_ready  <= 1;
        rst_k      <= 0;
        rst_y      <= 0;
        
        case(state)
        INIT: begin
            SIPO_status <= 0;
            sample_ctr  <= 0;
            rst_k       <= 1;
            rst_y       <= 1;
        end
        LOAD_MODE: begin
            src_ready   <= 0;
        end
        WAITING_FOR_SEED: begin
            if (valid_i & ready_i) begin
                SIPO_status <= {SIPO_status[6:0],1'b1};
                SEED_SIPO   <= {SEED_SIPO[447:0], seed_i};
            end
        end
        LOADING_SEED: begin
            src_ready   <= 0;
            if (src_read) begin
                src_ready   <= 1;
                SIPO_status <= {1'b0, SIPO_status[7:1]};
                SEED_SIPO   <= {SEED_SIPO[447:0], 64'd0};
            end
        end
        LOADING_NONCE: begin
            src_ready   <= 0;
        end
        SAMPLING: begin
            if (valid_o) begin
                sample_ctr <= sample_ctr + 4;
            end
        end
        endcase
    end
   
   
endmodule