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

module usehint #(
        parameter OUTPUT_W = 4,
        parameter COEFF_W  = 24,
        parameter W        = 64
    ) (
        input rst,
        input clk,
        input start,
        input [2:0]   sec_lvl,
        input [W-1:0] di,
        input         valid_i,
        output reg    ready_i,
        input [OUTPUT_W*COEFF_W-1:0] poly0_i,
        input [OUTPUT_W*COEFF_W-1:0] poly1_i,
        input      poly_valid_i,
        output reg poly_ready_i,
        output reg [OUTPUT_W*COEFF_W-1:0] poly_o,
        output reg poly_valid_o,
        input      poly_ready_o
    );
    
    reg [7:0]   hint_cnt [7:0];
    reg [671:0] hint_addr;
    reg [10:0] ctr, ctr_next;
    reg [9:0] pos, pos_next;
    reg [3:0] poly_num;
    reg [9:0] hint_len;
    
    reg [95:0] tmp;
    
    reg [256*8-1:0] hint_poly;
    
    localparam
        LVL2_LEN = 7'd80,
        LVL3_LEN = 7'd55,
        LVL5_LEN = 7'd75;
    reg [6:0] hint_addrlen;
    reg [3:0] num_hints;
    reg [7:0] next_hint;
    reg [10:0] hint_offset;
    
    localparam
        INIT         = 2'd0,
        RECEIVE_HINT = 2'd1,
        EXPAND_HINT  = 2'd2,
        APPLY_HINT   = 2'd3;
        
    reg [1:0] state;
    reg [5:0] FINAL_SHIFT;
    reg [3:0] K;
    
    integer i;
    always @(*) begin
        case(sec_lvl)
        2: K=4;
        3: K=6;
        default: K=8;
        endcase
    
        case(sec_lvl)
        2: hint_len=671;
        3: hint_len=487;
        default: hint_len=663;
        endcase

        for (i = 0; i < 8; i = i + 1)
            hint_cnt[i] = (i < K) ? hint_addr[8*(K-i-1)+:8] : 0;
    
        next_hint = hint_addr[hint_len-pos*8-:8];
 
        hint_offset = 0; 
       
        if (ctr >= hint_cnt[0])
           hint_offset = 256*(0+1);
        if (ctr >= hint_cnt[1])
           hint_offset = 256*(1+1);
        if (ctr >= hint_cnt[2])
           hint_offset = 256*(2+1);
        if (ctr >= hint_cnt[3])
           hint_offset = 256*(3+1);
        if (ctr >= hint_cnt[4] && K != 4)
           hint_offset = 256*(4+1);
        if (ctr >= hint_cnt[5] && K != 4)
           hint_offset = 256*(5+1);
        if (ctr >= hint_cnt[6] && K == 8)
           hint_offset = 256*(6+1);
        if (ctr >= hint_cnt[7] && K == 8)
           hint_offset = 256*(7+1);
            
        // Number of addresses in hint
        case(sec_lvl)
        2: hint_addrlen = LVL2_LEN;
        3: hint_addrlen = LVL3_LEN;
        5: hint_addrlen = LVL5_LEN;
        default: hint_addrlen = LVL2_LEN;
        endcase
    
        case(sec_lvl)
        2: num_hints = 4'd4;
        3: num_hints = 4'd6;
        5: num_hints = 4'd8;
        default: num_hints = 4'd4;
        endcase
    
        ready_i      = 0;
        poly_ready_i = poly_ready_o;
        poly_o       = 0;
        poly_valid_o = 0;
        ctr_next     = ctr;
    
        FINAL_SHIFT = 8*((ctr+1)*8 - hint_addrlen-num_hints);
    
    
        poly_o = poly1_i;
        if (sec_lvl != 2) begin
            for (i = 0; i < 4; i = i + 1) begin
                if (hint_poly[ctr+i] == 1) begin
                    if (poly0_i[i*24+:24] > (8380417-1)/32 || poly0_i[i*24+:24] == 0)
                        poly_o[i*24+:24] = (poly1_i[i*24+:24] == 0) ? 15 : poly1_i[i*24+:24] - 1;
                    else
                        poly_o[i*24+:24] = (poly1_i[i*24+:24] == 15) ? 0 : poly1_i[i*24+:24] + 1;
                end 
            end
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                if (hint_poly[ctr+i] == 1) begin
                    if (poly0_i[i*24+:24] > (8380417-1)/88 || poly0_i[i*24+:24] == 0)
                        poly_o[i*24+:24] = (poly1_i[i*24+:24] == 0) ? 43 : poly1_i[i*24+:24] - 1;
                    else
                        poly_o[i*24+:24] = (poly1_i[i*24+:24] == 43) ? 0 : poly1_i[i*24+:24] + 1;
                end 
            end
        end
        pos_next = pos;
    
        case(state)
        INIT: begin
            ctr_next = 0;
            pos_next = 0;
        end
        RECEIVE_HINT: begin
            ctr_next =  (valid_i && (ctr+1)*8 > hint_addrlen+num_hints) ?  0 :
                        (valid_i) ? ctr + 1 : ctr;
            ready_i  = valid_i;
            pos_next = 0;
        end
        EXPAND_HINT: begin
            ctr_next = (ctr+1 >= hint_cnt[K-1]) ?  0 : ctr + 1;
            pos_next = pos + 1;
        end
        APPLY_HINT: begin
            poly_valid_o = poly_valid_i;
            ctr_next = (poly_valid_o && poly_ready_o) ? ctr + 4 : ctr;
        end
        endcase
    end
    
    
    always @(posedge clk) begin
        if (rst) begin
            state <= INIT;
            ctr   <= 0;
        end else begin
            ctr <= ctr_next;  
            pos <= pos_next;      
            case(state)
            INIT: begin
                poly_num  <= 0;
                hint_addr <= 0;
                hint_poly <= 0;
                state <= (start) ? RECEIVE_HINT : INIT;
            end
            RECEIVE_HINT: begin
                // shift in hint
                poly_num <= 0;
                if ((ctr+1)*8 > hint_addrlen+num_hints) 
                    hint_addr <= (hint_addr << (64-FINAL_SHIFT)) | (di >> FINAL_SHIFT);
                else
                    hint_addr <= (valid_i) ? {hint_addr[671-64:0], di} : hint_addr;
                
                state <= (valid_i && (ctr+1)*8 > hint_addrlen+num_hints) ? EXPAND_HINT : RECEIVE_HINT;
            end
            EXPAND_HINT: begin
                hint_poly[next_hint+hint_offset] <= 1;
                state <= (ctr+1 >= hint_cnt[K-1]) ? APPLY_HINT : EXPAND_HINT;
            end
            APPLY_HINT: begin
                state <= (ctr == K*256) ? INIT : APPLY_HINT;
            end
            endcase
        end
    
    end
    
endmodule
