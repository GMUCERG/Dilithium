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

module decomposer_unit #(
    parameter OUTPUT_W    = 4,
    parameter COEFF_W     = 24
    ) (
    input rst,
    input clk,
    input [2:0] sec_lvl,
    input  valid_i,
    output ready_i,
    input  [OUTPUT_W*COEFF_W-1:0] di,
    output [OUTPUT_W*COEFF_W-1:0] doa,
    output [OUTPUT_W*COEFF_W-1:0] dob,
    output valid_o,
    input ready_o
    );
    
    wire [0:OUTPUT_W-1] valid_coeff_o;
    assign valid_o = &valid_coeff_o;
    wire [OUTPUT_W-1:0] ready_i_sub;
    assign ready_i = |ready_i_sub;
    
    
    genvar i;
    generate
        for (i = 0; i < OUTPUT_W; i = i + 1) begin
            coeff_decomposer COEFF_DECOMP(
                rst, clk, valid_i, ready_i_sub[i], sec_lvl, di[24*i+:24],
                doa[24*i+:24], dob[24*i+:24], valid_coeff_o[i], ready_o
            );
        end
        
    endgenerate
    
endmodule
