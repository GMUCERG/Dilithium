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


module rejection_a #(
    parameter W        = 64,
    parameter SAMPLE_W = 23,
    parameter RDI_SAMPLE_W = 24,
    parameter BUS_W    = 4
    )(
        input  rst,
        input  clk,
        input  valid_i,
        output reg ready_i,
        input  [W-1:0] rdi,
        output reg [SAMPLE_W*BUS_W-1:0] samples = 0,
        output reg valid_o = 0,
        input  ready_o
    );
    
    localparam
        DILITHIUM_Q = 23'd8380417;    
    
    reg [2*W-1:0] rdi_shift;
    reg [9:0] rdi_shift_amt;

    reg [79:0]  SIPO_IN;
    reg [137:0] SIPO_OUT;
    reg [3*SAMPLE_W-1:0] sipo_out_in;
    reg [6*SAMPLE_W-1:0] sipo_out_in_shft;
    reg [9:0] sipo_out_in_shft_amt;
    
    reg [22:0] rej_lane0, rej_lane1, rej_lane2;
    reg rej_lane0_valid, rej_lane1_valid, rej_lane2_valid;
    reg [1:0] num_valid;
    
    reg [6:0] sipo_in_len, sipo_in_len_next;
    reg [7:0] sipo_out_len, sipo_out_len_next;
    
    always @(*) begin
        ready_i = (sipo_in_len < 3*RDI_SAMPLE_W) ? 1 : 0;
        valid_o = (sipo_out_len >= SAMPLE_W*BUS_W) ? 1 : 0; 
    
        rej_lane0 = SIPO_IN[22:0];
        rej_lane1 = SIPO_IN[46:24];
        rej_lane2 = SIPO_IN[70:48];
        
        rej_lane0_valid = (rej_lane0 < DILITHIUM_Q && sipo_in_len >= RDI_SAMPLE_W) ? 1 : 0;
        rej_lane1_valid = (rej_lane1 < DILITHIUM_Q && sipo_in_len >= 2*RDI_SAMPLE_W) ? 1 : 0;
        rej_lane2_valid = (rej_lane2 < DILITHIUM_Q && sipo_in_len >= 3*RDI_SAMPLE_W) ? 1 : 0;
        num_valid       = rej_lane0_valid + rej_lane1_valid + rej_lane2_valid;
        
        if (rej_lane0_valid == 0)
            rej_lane0 = 0;
        if (rej_lane1_valid == 0)
            rej_lane1 = 0;
        if (rej_lane2_valid == 0)
            rej_lane2 = 0;
        
        sipo_in_len_next  = (ready_i && valid_i) ? sipo_in_len + W : sipo_in_len;
        sipo_out_len_next = (valid_o && ready_o) ? sipo_out_len - SAMPLE_W*BUS_W: sipo_out_len;      
        
        casex({rej_lane2_valid, rej_lane1_valid, rej_lane0_valid})
        3'bx11:  sipo_out_in = {rej_lane2, rej_lane1, rej_lane0}; 
        3'bx01:  sipo_out_in = {23'd0,     rej_lane2, rej_lane0}; 
        3'bx10:  sipo_out_in = {23'd0,     rej_lane2, rej_lane1};  
        3'b100:  sipo_out_in = {23'd0,     23'd0,     rej_lane0};  
        default: sipo_out_in = {23'd0,     23'd0,     23'd0    }; 
        endcase

        if (sipo_in_len >= 3*RDI_SAMPLE_W) begin
            rdi_shift_amt =  3*RDI_SAMPLE_W;
        end else if (sipo_in_len >= 2*RDI_SAMPLE_W) begin
            rdi_shift_amt =  2*RDI_SAMPLE_W;
        end else begin
            rdi_shift_amt = 0;
        end

        rdi_shift = (rdi << sipo_in_len - rdi_shift_amt);
        

        if (valid_o) begin   
            sipo_out_in_shft_amt = sipo_out_len_next;
        end else begin
            sipo_out_in_shft_amt = sipo_out_len;
        end
        sipo_out_in_shft = (sipo_out_in << sipo_out_in_shft_amt);

        samples = SIPO_OUT[SAMPLE_W*BUS_W-1:0];
    end
    
    initial begin
        SIPO_IN  = 0;
        SIPO_OUT = 0;
    
        sipo_in_len  = 0;
        sipo_out_len = 0;
    end
    
    always @(posedge clk) begin
        if (rst) begin
            sipo_in_len  <= 0;
            sipo_out_len <= 0;  
            
            SIPO_IN  <= 0;
            SIPO_OUT <= 0;      
        end else begin
            sipo_in_len <= sipo_in_len_next - rdi_shift_amt;
            if (sipo_in_len >= 3*RDI_SAMPLE_W) begin
                if (valid_i) begin
                    SIPO_IN <= (SIPO_IN >> 3*RDI_SAMPLE_W) | rdi_shift;
                end else begin
                    SIPO_IN <= (SIPO_IN >> 3*RDI_SAMPLE_W);
                end
                
            end else if (sipo_in_len >= 2*RDI_SAMPLE_W) begin
                if (valid_i) begin
                    SIPO_IN <= (SIPO_IN >> 2*RDI_SAMPLE_W) | rdi_shift;
                end else begin
                    SIPO_IN <= (SIPO_IN >> 2*RDI_SAMPLE_W);
                end
            end else begin
                if (valid_i) begin
                    SIPO_IN <= SIPO_IN | rdi_shift;
                end else begin
                    SIPO_IN <= SIPO_IN;
                end
            end
            
            if (num_valid == 1) begin
                sipo_out_len <= sipo_out_len_next + SAMPLE_W;
            end else if (num_valid == 2) begin
                sipo_out_len <= sipo_out_len_next + 2*SAMPLE_W;
            end else if (num_valid == 3) begin
                sipo_out_len <= sipo_out_len_next + 3*SAMPLE_W;
            end else begin
                sipo_out_len <= sipo_out_len_next;
            end
            
            if (valid_o) begin   
                if (num_valid != 0) begin
                    SIPO_OUT <= (SIPO_OUT >> SAMPLE_W*BUS_W) | sipo_out_in_shft;
                end else begin
                    SIPO_OUT <= SIPO_OUT >> SAMPLE_W*BUS_W;
                end
            end else if (num_valid >0) begin
                SIPO_OUT <= SIPO_OUT | sipo_out_in_shft;
            end
        end    
    end
endmodule
