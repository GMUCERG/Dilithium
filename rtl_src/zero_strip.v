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

module zero_strip# (
    parameter OUTPUT_W    = 4,
    parameter COEFF_W     = 23,
    parameter MAX_LVL     = 20,
    parameter W           = 64
    ) (
    input [4:0] encode_lvl,
    input [OUTPUT_W*COEFF_W-1:0] di,
    output reg [MAX_LVL*OUTPUT_W-1:0] dout
    );
    
    
    always @(*) begin
        dout = di[22:0] | (di[45:23] << encode_lvl) | (di[68:46] << {encode_lvl,1'd0}) | (di[91:69] << 3*encode_lvl);
    end
endmodule
