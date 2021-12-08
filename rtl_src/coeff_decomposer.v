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

module coeff_decomposer(
        input  rst,
        input  clk,
        input  valid_i,
        output ready_i,
        input      [2:0]  sec_lvl,
        input      [23:0] di,
        output reg [23:0] doa = 0,
        output reg [23:0] dob = 0,
        output reg        valid_o = 0,
        input ready_o
    );
    
    assign ready_i = ready_o;
    
    localparam
        N1        = 18'd190464,
        N2        = 19'd523776,
        Q_N1_DIFF = 23'd8189953,
        Q_N2_DIFF = 23'd7856641,
        K         = 6'd41,
        M1        = 24'd11545611,
        M2        = 23'd4198404,
        Q         = 23'd8380417;
    
    reg [4:0] valid_sr = 0;
    
    always @(*) begin
        valid_o = valid_sr[4];
    end
    
    
    reg [23:0] di_buffer;
    reg signed [55:0] a1_0, a1_1, a1_2, a0_0, a0_1, a0_2;
    
    wire [23:0] sub_val;
    assign sub_val = ((((Q-1)/2 - a0_1) >> 31) & Q);


    wire [5:0] map1_out;
    decomp_map1 MAP1 (
        sec_lvl, di_buffer[22:0], map1_out);
    
    always @(posedge clk) begin
        if (ready_o) begin
            valid_sr <= (rst) ? 0 : {valid_sr[3:0], valid_i};
            di_buffer <= di;
        
            a1_0 <= map1_out;
            a1_1 <= a1_0;
            a1_2 <= a1_1;
            dob  <= a1_2;

            a0_0 <= di_buffer;
            a0_2 <= a0_1 - sub_val;
            doa  <= (a0_2 < 0) ? a0_2 + Q : a0_2;

            if (sec_lvl == 2) begin
                a0_1 <= a0_0 - ((a1_0 << 17) + (a1_0 << 16) - (a1_0 << 12) - (a1_0 << 11));
            end else begin
                a0_1 <= a0_0 - ((a1_0 << 19) - (a1_0 << 9));
            end
        end    
    end
    
endmodule
