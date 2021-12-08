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

module NTT_PIPO
# (parameter DEPTH = 5)
    (
    input clk,
    input en,
    input [95:0] datai,
    output [95:0] data0
    );
    
    reg [95:0] PIPO [DEPTH-1:0];
    
    assign data0 = PIPO[DEPTH-1];
        
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            PIPO[i] = 0;
    end

    always @(posedge clk) begin
        if (en) begin
            PIPO[0] <= datai;
            for (i = 0; i < DEPTH-1; i = i + 1)
                PIPO[i+1] <= PIPO[i];
        end
    
    end
    
    
    
endmodule
