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

module address_unit(
    input clk,
    input rst,
    input [2:0] mode,
    input [1:0] mode_resolver,
    input en,
    output reg [5:0] ram_nat,
    output reg [5:0] ram_addr,
    output [7:0] twiddle_addr1,
    output [7:0] twiddle_addr2,
    output [7:0] twiddle_addr3,
    output [7:0] twiddle_addr4,
    output reg ntt_round_done,
    output reg done
    );
    
    localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1,
        MULT_MODE        = 3'd2,
        ADD_MODE         = 3'd3,
        SUB_MODE         = 3'd4;
    
    localparam
        DILITHIUM_N = 256;
    
    localparam 
        DECODE_TRUE = 2'd0,
        ENCODE_TRUE = 2'd1,
        STANDARD    = 2'd2;
    
    reg [5:0] j, k, i;
    reg [3:0] l;
    reg [6:0] k_next;
    
    reg  [5:0] addri_resolver;
    wire [5:0] addro_resolver;
    address_resolver ADDR_RESOLVE (mode_resolver, addri_resolver, addro_resolver);

    twiddle_resolver TWIDDLE_RESOLVE (
        clk, rst, mode, en,
        k, l, twiddle_addr1, twiddle_addr2,
        twiddle_addr3, twiddle_addr4
        );
    
    initial begin
        j              = 0; 
        k              = 0; 
        i              = 1; 
        l              = 0; 
        ram_addr       = 0;
        ntt_round_done = 0;
        done           = 0;
    end
    
    reg [2:0] fw_ntt_pattern;
    
    always @(*) begin
        ram_addr = addro_resolver;
        ram_nat  = addri_resolver;

        case(l[2:1])
        0: fw_ntt_pattern = 4;
        1: fw_ntt_pattern = 2;
        2: fw_ntt_pattern = 0;
        3: fw_ntt_pattern = 4;
        endcase
        
        case(mode)
        ADD_MODE: begin
            addri_resolver = j;
            k_next         = 0;
        end
        MULT_MODE, SUB_MODE: begin
            addri_resolver = j;
            k_next         = 0;
        end
        FORWARD_NTT_MODE: begin
            addri_resolver = j + k;
            k_next = (k + (1 << fw_ntt_pattern)); 
        end
        INVERSE_NTT_MODE: begin
            addri_resolver = j + k;
            k_next = (k + (1 << l));
        end default: begin
            addri_resolver = 0;
            k_next = 0;
        end
        endcase
    
    end
    
    always @(posedge clk) begin
        done           <= 0;
        ntt_round_done <= 0;
        j <= j;
    
        if (rst) begin
            j <= 0;
            k <= 0;
            l <= 0;
            i <= (mode == INVERSE_NTT_MODE) ? 1 : 0;
        end else if (en) begin
            case(mode)
            MULT_MODE, ADD_MODE, SUB_MODE: begin
                if (j == 63) begin
                    j    <= 0;
                    done <= 1;
                end else begin
                    j <= j + 1;
                end
            end
            INVERSE_NTT_MODE: begin
                if (k_next < 64)
                    k <= k_next;
                else begin
                    k <= 0;
                    j <= j + 1;
                end
            
                if (i == 0) begin
                    j <= 0;
                    k <= 0;
                end 
            
                if (i == 63) begin
                    ntt_round_done <= 1;
                    i <= 0;
                    
                
                    if (l == 6) begin
                        done <= 1;
                        k <= k;
                        l <= l;
                    end else begin
                        l <= l + 2;
                    end
                end else begin
                    i <= i + 1;
                end
            end
            FORWARD_NTT_MODE: begin
                if (k_next < 64)
                    k <= k_next;
                else begin
                    k <= 0;
                    j <= j + 1;
                end
            
                if (i == 63) begin
                    ntt_round_done <= 1;
                    i <= 0;
                    j <= 0;
                    
                
                    if (l == 6) begin
                        done <= 1;
                        k <= k;
                        l <= l;
                    end else begin
                        l <= l + 2;
                    end
                end else begin
                    i <= i + 1;
                end
            end
            endcase
        end
    
    end
    
endmodule
