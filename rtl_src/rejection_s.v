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


module rejection_s #(
    parameter W            = 64,
    parameter RDI_SAMPLE_W = 4,
    parameter SAMPLE_W     = 23,
    parameter BUS_W        = 4
    )(
        input  rst,
        input  clk,
        input [2:0] sec_lvl,
        input  valid_i,
        output reg ready_i,
        input  [W-1:0] rdi,
        output reg [SAMPLE_W*BUS_W-1:0] samples = 0,
        output reg valid_o = 0,
        input  ready_o
    );
    
    localparam
        DILITHIUM_Q = 23'd8380417,
        ETA2_LIMIT  = 5'd15,
        ETA4_LIMIT  = 5'd9;    
    
    wire [4:0] ETA_LIMIT;
    assign ETA_LIMIT = (sec_lvl == 3) ? ETA4_LIMIT : ETA2_LIMIT;
    
    reg [79:0]  SIPO_IN, SIPO_IN_SHIFT;
    reg [199:0] SIPO_OUT;
    reg [3*SAMPLE_W-1:0] sipo_out_in;

    reg [5:0] shift_amt;
    
    reg [3:0] rej_lane0, rej_lane1, rej_lane2;
    reg [3:0] rej_lane0_map, rej_lane1_map, rej_lane2_map;
    
    reg [22:0] sample0, sample1, sample2;
    reg rej_lane0_valid, rej_lane1_valid, rej_lane2_valid;
    reg [1:0] num_valid;
    
    reg [6:0] sipo_in_len, sipo_in_len_next;
    reg [7:0] sipo_out_len, sipo_out_len_next;
    
    always @(*) begin
        ready_i = (sipo_in_len < 3*RDI_SAMPLE_W) ? 1 : 0;
        valid_o = (sipo_out_len >= SAMPLE_W*BUS_W) ? 1 : 0;
    
        rej_lane0 = SIPO_IN[3:0];
        rej_lane1 = SIPO_IN[7:4];
        rej_lane2 = SIPO_IN[11:8];
        
        sample0 = 0;
        sample1 = 0;
        sample2 = 0;
        
        rej_lane0_map = 0;
        rej_lane1_map = 0;
        rej_lane2_map = 0;
        
        case(sec_lvl) 
        2,5: begin
            case(rej_lane0)
            0,1,2,3,4: begin
                rej_lane0_map = rej_lane0;
            end
            5,6,7,8,9: begin
                rej_lane0_map = rej_lane0-4'd5;
            end
            10,11,12,13,14:begin
                rej_lane0_map = rej_lane0-4'd10;
            end
            endcase
            sample0 = (rej_lane0_map > 2) ? 2+DILITHIUM_Q-rej_lane0_map : 2-rej_lane0_map;
            
            case(rej_lane1)
            0,1,2,3,4: begin
                rej_lane1_map = rej_lane1;
            end
            5,6,7,8,9: begin
                rej_lane1_map = rej_lane1-4'd5;
            end
            10,11,12,13,14:begin
                rej_lane1_map = rej_lane1-4'd10;
            end
            endcase
            sample1 = (rej_lane1_map > 2) ? 2+DILITHIUM_Q-rej_lane1_map : 2-rej_lane1_map;

            case(rej_lane2)
            0,1,2,3,4: begin
                rej_lane2_map = rej_lane2;
            end
            5,6,7,8,9: begin
                rej_lane2_map = rej_lane2-4'd5;
            end
            10,11,12,13,14:begin
                rej_lane2_map = rej_lane2-4'd10;
            end
            endcase
            sample2 = (rej_lane2_map > 2) ? 2+DILITHIUM_Q-rej_lane2_map : 2-rej_lane2_map;

        end
        3: begin
            // ETA == 4
            sample0 = 4+DILITHIUM_Q-rej_lane0;
            sample1 = 4+DILITHIUM_Q-rej_lane1;
            sample2 = 4+DILITHIUM_Q-rej_lane2;
        end        
        endcase

        
        rej_lane0_valid = (rej_lane0 < ETA_LIMIT && sipo_in_len >= RDI_SAMPLE_W) ? 1 : 0;
        rej_lane1_valid = (rej_lane1 < ETA_LIMIT && sipo_in_len >= 2*RDI_SAMPLE_W) ? 1 : 0;
        rej_lane2_valid = (rej_lane2 < ETA_LIMIT && sipo_in_len >= 3*RDI_SAMPLE_W) ? 1 : 0;
        num_valid       = rej_lane0_valid + rej_lane1_valid + rej_lane2_valid;
        
        if (rej_lane0_valid == 0)
            sample0 = 0;
        if (rej_lane1_valid == 0)
            sample1 = 0;
        if (rej_lane2_valid == 0)
            sample2 = 0;
        
        sipo_in_len_next  = (ready_i && valid_i) ? sipo_in_len + W : sipo_in_len;
        sipo_out_len_next = (valid_o && ready_o) ? sipo_out_len - SAMPLE_W*BUS_W: sipo_out_len;      
        
        casex({rej_lane2_valid, rej_lane1_valid, rej_lane0_valid})
        3'bx11:  sipo_out_in = {sample2, sample1, sample0}; 
        3'bx01:  sipo_out_in = {23'd0,   sample2, sample0}; 
        3'bx10:  sipo_out_in = {23'd0,   sample2, sample1};  
        3'b100:  sipo_out_in = {23'd0,   23'd0,   sample2};  
        default: sipo_out_in = {23'd0,   23'd0,   23'd0  }; 
        endcase

        if (sipo_in_len >= 3*RDI_SAMPLE_W) begin
            shift_amt = 3*RDI_SAMPLE_W;
        end else if (sipo_in_len >= 2*RDI_SAMPLE_W) begin
            shift_amt = 2*RDI_SAMPLE_W;
        end else if (sipo_in_len >= RDI_SAMPLE_W) begin
            shift_amt = RDI_SAMPLE_W;
        end else begin
            shift_amt = 0;
        end

        SIPO_IN_SHIFT = (SIPO_IN >> shift_amt);
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
            SIPO_IN  <= 0;
            SIPO_OUT <= 0;
            
            sipo_in_len  <= 0;
            sipo_out_len <= 0;         
        end else begin
            
            sipo_in_len <= sipo_in_len_next - shift_amt;
            
            if (valid_i) begin
                SIPO_IN <= SIPO_IN_SHIFT | (rdi << sipo_in_len - shift_amt);
            end else begin
                SIPO_IN <= SIPO_IN_SHIFT;
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
            
            if (valid_o && ready_o) begin   
                if (num_valid != 0) begin
                    SIPO_OUT <= (SIPO_OUT >> SAMPLE_W*BUS_W) | sipo_out_in << sipo_out_len_next;
                end else begin
                    SIPO_OUT <= SIPO_OUT >> SAMPLE_W*BUS_W;
                end
            end else if (num_valid >0) begin
                SIPO_OUT <= SIPO_OUT | sipo_out_in << sipo_out_len;
            end
        end    
    end
    
endmodule
