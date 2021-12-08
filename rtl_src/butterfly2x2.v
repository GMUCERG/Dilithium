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

module butterfly2x2(
    input             clk,
    input             rst,
    input [2:0]       mode,
    input             validi,
    input [24*4-1:0]  datai,
    input [24*4-1:0]  zetai,
    input [24*4-1:0]  acci,
    output reg [24*4-1:0] datao,
    output reg            valido
    );
    
    localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1,
        MULT_MODE        = 3'd2,
        ADD_MODE         = 3'd3,
        SUB_MODE         = 3'd4;
    
    reg [23:0] z0, z1, z2, z3;
    reg [23:0] z2_sr [8:0];
    reg [23:0] z3_sr [8:0];

    
    reg  [23:0] a0, b0, c0, d0;
    wire [23:0] a1, b1, c1, d1;
    reg  [23:0] a2, b2, c2, d2;
    wire [23:0] a3, b3, c3, d3;
    
    wire valido_1_1, valido_1_2, valido_2_1, valido_2_2;
    reg validi_1_1, validi_1_2, validi_2_1, validi_2_2;
    
    always @(*) begin
        a0 = datai[24*0+:24];
        b0 = datai[24*1+:24];
        c0 = datai[24*2+:24];
        d0 = datai[24*3+:24];
        
        z0 = zetai[24*0+:24];
        z1 = zetai[24*1+:24];
        z2 = z2_sr[5];
        z3 = z3_sr[5];
        
        validi_1_1 = validi;
        validi_1_2 = validi;
        validi_2_1 = validi;
        validi_2_2 = validi;
        
        
        datao[24*0+:24] = a3;
        datao[24*1+:24] = b3;
        datao[24*2+:24] = c3;
        datao[24*3+:24] = d3;
        
        case(mode)
        MULT_MODE, ADD_MODE, SUB_MODE: begin
            datao[24*0+:24] = b3;
            datao[24*1+:24] = b1;
            datao[24*2+:24] = d3;
            datao[24*3+:24] = d1;
            
            z0 = zetai[24*0+:24];
            z1 = zetai[24*1+:24];
            z2 = zetai[24*2+:24];
            z3 = zetai[24*3+:24];
        end
        FORWARD_NTT_MODE: begin
            datao[24*0+:24] = a3;
            datao[24*1+:24] = b3;
            datao[24*2+:24] = c3;
            datao[24*3+:24] = d3;
            validi_1_1 = validi;
            validi_1_2 = validi;
            validi_2_1 = valido_1_1;
            validi_2_2 = valido_1_2;
        
            z0 = zetai[24*0+:24];
            z1 = zetai[24*1+:24];
            z2 = z2_sr[7];
            z3 = z3_sr[7];
        end
        INVERSE_NTT_MODE: begin
            datao[24*0+:24] = a3;
            datao[24*1+:24] = b3;
            datao[24*2+:24] = c3;
            datao[24*3+:24] = d3;
            validi_1_1 = validi;
            validi_1_2 = validi;
            validi_2_1 = valido_1_1;
            validi_2_2 = valido_1_2;
        
            z0 = zetai[24*0+:24];
            z1 = zetai[24*1+:24];
            z2 = z2_sr[8];
            z3 = z3_sr[8];
        end
        endcase
        
        a2 = a1;
        c2 = b1;
    
        case(mode)
        MULT_MODE, ADD_MODE, SUB_MODE: begin
            a2 = acci[0*24+:24];
            a0 = acci[1*24+:24];
            c2 = acci[2*24+:24];
            c0 = acci[3*24+:24];
        
            b2 = datai[24*0+:24];
            d2 = datai[24*2+:24];
        end
        default: begin
            b2 = c1;
            d2 = d1;
        end
        endcase
        
        valido = valido_2_1 & valido_2_2;

    end

    
    butterfly BF1_1(
        clk, rst, mode, validi_1_1,
        a0, b0, z0, a1, b1,
        valido_1_1
        );
    
    butterfly BF1_2(
        clk, rst, mode, validi_1_2,
        c0, d0, z1, c1, d1,
        valido_1_2
        );
    
    butterfly BF2_1(
        clk, rst, mode, validi_2_1,
        a2, b2, z2, a3, b3,
        valido_2_1
        );
    
    butterfly BF2_2(
        clk, rst, mode, validi_2_2,
        c2, d2, z3, c3, d3,
        valido_2_2
        );
    
    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            z2_sr[i] = 0;
            z3_sr[i] = 0;
        end
    end
    
    always @(posedge clk) begin

        if (rst) begin
            for (i = 0; i < 9; i = i + 1) begin
                z2_sr[i] <= 0;
                z3_sr[i] <= 0;
            end
        end else begin
            z2_sr[0] <= zetai[24*2+:24];
            z3_sr[0] <= zetai[24*3+:24];
            
            for (i = 1; i < 9; i = i + 1)
                z2_sr[i] <= z2_sr[i-1];
            for (i = 1; i < 9; i = i + 1)
                z3_sr[i] <= z3_sr[i-1];
            
        end
    end
    
endmodule
