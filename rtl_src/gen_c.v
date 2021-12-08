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

module gen_c # (
    parameter SAMPLER_W   = 4,
    parameter SAMPLE_W    = 23,
    parameter W           = 64
    ) (
    input  start,
    input  rst,
    input  clk,
    input  [2:0] sec_lvl,
    input  mode,
    input  valid_i,
    output reg ready_i,
    input  [W-1:0] seed_i,
    output reg [SAMPLER_W*SAMPLE_W-1:0] samples = 0,
    output reg valid_o,
    input      ready_o,
    input          ch_read,
    output reg [W-1:0] ch,
    output reg done_sampler = 0,
    // keccak pass through
    output reg  rst_k,
    output reg  [63:0] din,
    input [63:0] dout,
    output reg         src_ready,
    input        src_read,
    input        dst_write,
    output reg         dst_ready
    );
    
    localparam
        S_HOLD          = 4'd0,
        S_STORE_MU      = 4'd1,
        S_STORE_CHAT    = 4'd11,
        S_INIT          = 4'd2,
        S_ABSORB_MU     = 4'd3,
        S_ABSORB_W1     = 4'd4,
        S_HASH_CHAT     = 4'd5,
        S_INIT2         = 4'd6,
        S_ABSORB_CHAT   = 4'd7,
        S_STORE_SIGN    = 4'd8,
        S_SAMPLEC       = 4'd9,
        S_UNLOAD_C      = 4'd10,
        S_STALL         = 4'd12;

        
    localparam NEG_ONE = 23'd8380416;  
    
    reg  [31:0] ctrl_len;
    
    reg [3:0]  cstate, nstate;
    reg [31:0] ctr, ctr_next;
    reg [8:0]  sample_no;
    
    reg [63:0] dout_buffer;
    reg [511:0] MU_SIPO;
    reg [255:0] C_SIPO;
    reg [63:0] SIGN;
    reg [1:0] C_POLY [255:0];
    
    integer i;
    initial begin
        cstate = S_HOLD;
        nstate = S_HOLD;
        ctr    = 0;
        
        MU_SIPO   = 0;
        C_SIPO    = 0;
        sample_no = 0;
        
        for (i = 0; i < 256; i = i + 1) begin
            C_POLY[i] = 0;
        end
    end
    reg [7:0] sample_addr;
    reg [10:0] W1_LEN;
    reg [7:0]  TAU;
    
    always @(*) begin
        ch = C_SIPO[255:256-64];
        
        case(sec_lvl)
        2: begin
             W1_LEN = 4*192/8;
             TAU = 39;
        end
        3: begin
            W1_LEN = 6*256/8/2; 
            TAU = 49;
        end
        5: begin
             W1_LEN = 8*256/8/2; 
             TAU = 60;
        end
        default: begin
            W1_LEN = 0;
            TAU    = 0;
        end
        endcase
    end
    
    always @(*) begin
        nstate  = cstate;
        ready_i = 0;
        valid_o = 0;
        rst_k   = 0;
    
        din       = 0;
        src_ready = 1;
        dst_ready = 1;
        ctrl_len  = W1_LEN*64 + 512;
        ctr_next  = ctr;
        done_sampler = 0;
        samples      = 0;
        
        sample_addr = 0;
    
        case(cstate)
        S_HOLD: begin
            nstate = (start && !mode) ? S_STORE_MU : 
                     (start &&  mode) ? S_STORE_CHAT :   S_HOLD;
            rst_k  = 1;
        end
        S_STORE_MU: begin
            ready_i = (valid_i) ? 1 : 0;
            ctr_next = ctr + 1;
            if (ctr == 7 && valid_i) begin
                nstate = S_INIT;
            end        
        end
        S_STORE_CHAT: begin
            ready_i  = valid_i;
            ctr_next = (valid_i && ready_i) ? ctr + 1 : ctr;
            if (ctr == 3 && valid_i) begin
                nstate = S_INIT2;
            end  
        end
        S_INIT: begin
            // load in ctrl block
            src_ready = 0;
            din = {32'hE0000100, ctrl_len}; 
            nstate = (src_read) ? S_ABSORB_MU : S_INIT;
        end
        S_ABSORB_MU: begin
            din = MU_SIPO[511:512-64];
            src_ready = 0;
            ctr_next = (src_read) ? ctr + 1 : ctr;
            if (ctr == 7 && src_read) begin
                nstate = S_ABSORB_W1;
            end
        end
        S_ABSORB_W1: begin
            din       = seed_i;
            src_ready = ~valid_i;
            ready_i   = src_read;
            
            ctr_next = (src_read) ? ctr + 1 : ctr;
            nstate = (ctr == W1_LEN-1 && src_read) ? S_HASH_CHAT : S_ABSORB_W1;
        end
        S_HASH_CHAT: begin
            ctr_next = (dst_write) ? ctr + 1 : ctr;
            dst_ready = 0;
            
            nstate = (ctr == 3 && dst_write) ? S_INIT2 : S_HASH_CHAT;
            rst_k  = (ctr == 3 && dst_write) ? 1 : 0;
        end
        S_INIT2: begin
            // load in ctrl block
            src_ready = 0;
            din = {32'hE0008000, 32'd256}; 
            nstate = (src_read) ? S_ABSORB_CHAT : S_INIT2;
        end
        S_ABSORB_CHAT: begin
            din = C_SIPO[255:256-64];
            src_ready = 0;
            ctr_next = (src_read) ? ctr + 1 : ctr;
            if (ctr == 3 && src_read) begin
                nstate = S_STORE_SIGN;
            end
        end
        S_STORE_SIGN: begin
            ctr_next = (dst_write) ? ctr + 1 : ctr;
            dst_ready = 0;
            
            nstate = (ctr == 0 && dst_write) ? S_STALL : S_STORE_SIGN;
        end
        S_STALL: begin
            nstate = S_SAMPLEC;
        end
        S_SAMPLEC: begin
            sample_addr = dout_buffer[{4'd7-ctr[2:0],3'd0}+:8];
        
            ctr_next = ctr + 1;
            nstate = (sample_no == 256) ? S_UNLOAD_C : S_SAMPLEC;
            rst_k  = (sample_no == 256) ? 1 : 0;
            dst_ready = (ctr[2:0] == 6) ? 0 : 1;
        end
        S_UNLOAD_C: begin
            valid_o      = (ctr < 64) ? 1 : 0;
            done_sampler = (ctr == 64) ? 1 : 0;
            
            ctr_next = (ready_o && valid_o) ? ctr + 1 : ctr;
            
            // Decode C_POLY Reg
            case(C_POLY[{ctr,2'd0}])
            1: samples[0*SAMPLE_W+:SAMPLE_W] = 1;
            2: samples[0*SAMPLE_W+:SAMPLE_W] = NEG_ONE;
            default: samples[0*SAMPLE_W+:SAMPLE_W] = 0;
            endcase 
            
            case(C_POLY[{ctr,2'd1}])
            1: samples[1*SAMPLE_W+:SAMPLE_W] = 1;
            2: samples[1*SAMPLE_W+:SAMPLE_W] = NEG_ONE;
            default: samples[1*SAMPLE_W+:SAMPLE_W] = 0;
            endcase 
            
            case(C_POLY[{ctr,2'd2}])
            1: samples[2*SAMPLE_W+:SAMPLE_W] = 1;
            2: samples[2*SAMPLE_W+:SAMPLE_W] = NEG_ONE;
            default: samples[2*SAMPLE_W+:SAMPLE_W] = 0;
            endcase 
            
            case(C_POLY[{ctr,2'd3}])
            1: samples[3*SAMPLE_W+:SAMPLE_W] = 1;
            2: samples[3*SAMPLE_W+:SAMPLE_W] = NEG_ONE;
            default: samples[3*SAMPLE_W+:SAMPLE_W] = 0;
            endcase 
            
            nstate = (ctr == 64) ? S_INIT : S_UNLOAD_C;
        end
        default: begin
            nstate = S_HOLD;
        end
        endcase
    
    end
    
    always @(posedge clk) begin
        if (rst) begin
            cstate <= S_HOLD;
        end else begin
            cstate <= nstate;
        end

        dout_buffer <= dout;
    
        if (ch_read) begin
             C_SIPO   <= {C_SIPO[255-64:0], C_SIPO[255:256-64]};
        end
    
        case(cstate)
        S_HOLD: begin
            ctr   <= 0;
        end 
        S_STORE_MU: begin
            if (valid_i & ready_i) begin
                ctr     <= ctr_next;
                MU_SIPO <= {MU_SIPO[511-64:0], seed_i};
            end
        end
        S_STORE_CHAT: begin
            ctr <= (ctr == 3 && valid_i & ready_i) ? 0 : ctr_next;
            if (valid_i & ready_i) begin
                C_SIPO <= {C_SIPO[255-64:0], seed_i};
            end
        end
        S_INIT: begin
            ctr <= 0;
        end
        S_ABSORB_MU: begin
            ctr <= (ctr == 7 && src_read) ? 0 : ctr_next;
            if (src_read) begin
                 MU_SIPO   <= {MU_SIPO[511-64:0], MU_SIPO[511:512-64]};
            end
        end
        S_ABSORB_W1: begin            
            ctr <= (ctr == W1_LEN-1 && src_read) ? 0 : ctr_next;
        end
        S_HASH_CHAT: begin
            ctr   <= (ctr == 3 && dst_write) ? 0 : ctr_next;
            
            if (dst_write) begin
                C_SIPO   <= {C_SIPO[255-64:0], dout};
            end
        end
        S_ABSORB_CHAT: begin
            ctr <= (ctr == 3 && src_read) ? 0 : ctr_next;
            if (src_read) begin
                 C_SIPO   <= {C_SIPO[255-64:0], C_SIPO[255:256-64]};
            end
        end
        S_STORE_SIGN: begin
            sample_no <= 256 - TAU;
            // zero out C poly
            for (i = 0; i < 256; i = i + 1) begin
                C_POLY[i] <= 0;
            end
            
            ctr <= (dst_write) ? 0 : ctr_next;
            if (dst_write) begin
                SIGN   <= {dout[0*8+:8], dout[1*8+:8], dout[2*8+:8], dout[3*8+:8], dout[4*8+:8],
                                    dout[5*8+:8], dout[6*8+:8], dout[7*8+:8]};
            end
        end
        S_SAMPLEC: begin
            if (sample_no <= 255) begin
                ctr <= ctr_next;
                if (sample_addr <= sample_no) begin
                    // ACCEPT
                    sample_no <= sample_no + 1;
                    C_POLY[sample_no]   <= C_POLY[sample_addr];
                    C_POLY[sample_addr] <= (SIGN[0]) ? 2 : 1; // 2 -> -1
                    SIGN                <= (SIGN >> 1);
                end
            end else begin
                ctr <= 0;
            end
        end
        S_UNLOAD_C: begin
            ctr <= ctr_next;
        end
        endcase 
    end
endmodule
