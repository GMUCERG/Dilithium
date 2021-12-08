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

module twiddle_resolver(
    input clk,
    input rst,
    input [2:0] mode,
    input en,
    input [5:0] k,
    input [3:0] s,
    output reg [7:0] twiddle_addr1 = 0,
    output reg [7:0] twiddle_addr2 = 0,
    output reg [7:0] twiddle_addr3 = 0,
    output reg [7:0] twiddle_addr4 = 0
    );
    
    localparam 
        DILITHIUM_N = 256;
    
    reg [7:0] tw_base_i [3:0];
    
    reg t_last;
    reg [7:0] l1, l2, l3, l4;
    reg [7:0] l1_base, l2_base, l3_base, l4_base;
    
    wire [7:0] l1_addmask, l2_addmask, l3_addmask, l4_addmask;
    assign l1_addmask = (l1 + 1) & ((2 << s) - 1); 
    assign l2_addmask = (l2 + 1) & ((2 << s) - 1); 
    
    assign l3_addmask = (l3 + 2) & (2 << (s + 1)) - 1; 
    assign l4_addmask = (l4 + 2) & (2 << (s + 1)) - 1; 

    localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1,
        MULT_MODE        = 3'd2,
        ADD_MODE         = 3'd3,
        SUB_MODE         = 3'd4;
    
    initial begin
        l1 = 0;
        l2 = 0;
        l3 = 0;
        l4 = 0;
        tw_base_i[0] = 0;
        tw_base_i[1] = 0;
        tw_base_i[2] = 0;
        tw_base_i[3] = 0;
        t_last = 0;
    end
    
    always @(*) begin    
        twiddle_addr1 = 0;
        twiddle_addr2 = 0;
        twiddle_addr3 = 0;
        twiddle_addr4 = 0;
    
        l1_base = 0;
        l2_base = 0;
        l3_base = 0;
        l4_base = 0;
    
        case(mode)
        INVERSE_NTT_MODE: begin
            if (k == 0) begin
                l1_base = (DILITHIUM_N >> s) - 1;
                l2_base = (DILITHIUM_N >> s) - 2;
                l3_base = (DILITHIUM_N >> (s + 1)) - 1;
                l4_base = l3_base;
            end else begin
                l1_base = l1 - 2;
                l2_base = l2 - 2;
                l3_base = l3 - 1;
                l4_base = l4 - 1;   
            end
            
            
            twiddle_addr1 = l1_base;
            twiddle_addr2 = l2_base;
            twiddle_addr3 = l3_base;
            twiddle_addr4 = l4_base;
        end
        FORWARD_NTT_MODE: begin
            if ((s < 6 && k == 0) || (s >= 6 && !t_last)) begin
                l1_base = 1 << s;
                l2_base = 1 << s;
                l3_base = (1 << (s + 1));
                l4_base = (1 << (s + 1)) + 1;
            end else begin
                if (s < 6) begin
                    l1_base = (tw_base_i[0] > l1_addmask) ? tw_base_i[0] : l1_addmask;
                    l2_base = (tw_base_i[1] > l2_addmask) ? tw_base_i[1] : l2_addmask;
                    l3_base = (tw_base_i[2] > l3_addmask) ? tw_base_i[2] : l3_addmask;
                    l4_base = (tw_base_i[3] > l4_addmask) ? tw_base_i[3] : l4_addmask;
                end else begin
                    l1_base = l1 + 1;
                    l2_base = l2 + 1;
                    l3_base = l3 + 2;
                    l4_base = l4 + 2;  
                end
            end

            twiddle_addr1 = l1_base;
            twiddle_addr2 = l2_base;
            twiddle_addr3 = l3_base;
            twiddle_addr4 = l4_base;
        end
        endcase
    end
    
    
    always @(posedge clk) begin
        if (rst) begin
            l1 <= l1_base;
            l2 <= l2_base;
            l3 <= l3_base;
            l4 <= l4_base;
            
            t_last <= 0;
            tw_base_i[0] <= 0;
            tw_base_i[1] <= 0;
            tw_base_i[2] <= 0;
            tw_base_i[3] <= 0;
        end else if (en) begin
            case(mode)
            INVERSE_NTT_MODE: begin
                l1 <= l1_base;
                l2 <= l2_base;
                l3 <= l3_base;
                l4 <= l4_base;

                if (k == 0) begin
                    tw_base_i[0] <= l1_base;
                    tw_base_i[1] <= l2_base;
                    tw_base_i[2] <= l3_base;
                    tw_base_i[3] <= l4_base;
                end

            end
            FORWARD_NTT_MODE: begin
                l1 <= l1_base;
                l2 <= l2_base;
                l3 <= l3_base;
                l4 <= l4_base;
            
                if ((s < 6 && k == 0) || (s >= 6 && !t_last)) begin
                    tw_base_i[0] <= l1_base;
                    tw_base_i[1] <= l2_base;
                    tw_base_i[2] <= l3_base;
                    tw_base_i[3] <= l4_base;
                    
                    t_last <= (s >= 6) ?  1 : 0;
                end
            end
            endcase
        end
    end
    
endmodule
