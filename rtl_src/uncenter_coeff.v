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

module uncenter_coeff(
    input [2:0] sec_lvl,
    input [2:0] mode,
    input [22:0] di,
    output reg [22:0] dout
    );
    
    localparam
        Q = 23'd8380417;
        
    localparam
        M_NONE   = 3'd0,
        M_ETA    = 3'd1,
        M_T0     = 3'd2,
        M_T1     = 3'd3,
        M_GAMMA1 = 3'd4;
        
    reg signed [23:0] t0, t1;
    
    reg [3:0] ETA;
    reg [12:0] T;
    reg [19:0] GAMMA1;
    always @(*) begin
        ETA    = (sec_lvl == 3) ? 4 : 2;
        T      = (1 << 13-1);
        GAMMA1 = (sec_lvl == 2) ? (1 << 17) : (1 << 19);
        
        t1 = (di + T - 1) >> 13;
        t0 = di - (t1 << 13);
        
        (*full_case*)
        case({mode})
        M_NONE:   dout = di;
        M_ETA:    dout = (di > ETA)    ? ETA + Q - di    : ETA - di;
        M_T0:     dout = T - t0;
        M_T1:     dout = t1;
        M_GAMMA1: dout = (di > GAMMA1) ? GAMMA1 + Q - di : GAMMA1 - di;
        endcase
    end
    
endmodule
