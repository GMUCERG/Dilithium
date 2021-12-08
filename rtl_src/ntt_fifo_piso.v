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


module ntt_fifo_piso
# (parameter DEPTH = 4)
    (
    input clk,
    input en,
    input piso_en,
    input [95:0] line,
    input [23:0] new_value,
    output reg [95:0] fifo_out,
    output reg [23:0] data_out
    );
    
    reg [23:0] fifo [DEPTH-1:0];
    
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            fifo[i] = 0;
    end
    
    always @(*) begin
        fifo_out = {fifo[DEPTH-4],fifo[DEPTH-3],fifo[DEPTH-2],fifo[DEPTH-1]};
    end
    
    always @(posedge clk) begin
        if (en) begin
            data_out <= fifo[DEPTH - 1];
            for (i = DEPTH-1; i > 3; i = i - 1)
                fifo[i] <= fifo[i-1];
            
            if (piso_en) begin
                fifo[3] = line[0*24+:24];
                fifo[2] = line[1*24+:24];
                fifo[1] = line[2*24+:24];
                fifo[0] = line[3*24+:24];
            end else begin
                fifo[3] = fifo[2];
                fifo[2] = fifo[1];
                fifo[1] = fifo[0];
                fifo[0] = new_value;
            end
        end
    end
    
endmodule
