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

module address_resolver(
    input [1:0]      mapping,
    input [5:0]      addri,
    output reg [5:0] addro
    );
    
    localparam 
        DECODE_TRUE = 2'd0,
        ENCODE_TRUE = 2'd1,
        STANDARD    = 2'd2;
    
    always @(*) begin
        case(mapping)
        DECODE_TRUE: begin
            addro = {addri[3], addri[2], addri[1], addri[0], addri[5], addri[4]};
        end
        ENCODE_TRUE: begin
            addro = {addri[1], addri[0], addri[5], addri[4], addri[3], addri[2]};
        end
        STANDARD: begin
            addro = addri;
        end
        default: begin
            addro = addri;
        end
        endcase
    end
    
endmodule
