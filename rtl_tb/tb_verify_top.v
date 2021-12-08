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
`define P 10


module tb_verify_top;
  reg clk = 1,  rst = 0, start = 0;
  
  localparam  NUM_TV = 5;


    reg [2:0] sec_lvl = 2;
      
    reg [1:0] mode = 1;
      
    reg valid_i,  ready_o;
    wire ready_i, valid_o;
    reg  [63:0] data_i;  
    wire [63:0] data_o;
    
    combined_top DUT (
        clk,
        rst,
        start,
        mode,
        sec_lvl,
        valid_i,
        ready_i,
        data_i,
        valid_o,
        ready_o,
        data_o
    );
  
  localparam
    START         = 4'd0,
    LOAD_RHO      = 4'd1,
    LOAD_C        = 4'd2,
    LOAD_Z        = 4'd3,
    LOAD_T1       = 4'd4,
    LOAD_MLEN     = 4'd5,
    LOAD_M        = 4'd6,
    LOAD_H        = 4'd7,
    UNLOAD_RESULT = 4'd8,
    STOP          = 4'd9;
  
  reg [3:0] state;
  integer ctr,c,start_time;
  
    reg [0:3300*8-1] m_2    [NUM_TV-1:0];
    reg [0:15]       mlen_2 [NUM_TV-1:0];
  
    reg [0:255]      c_2    [NUM_TV-1:0];
    reg [0:255]      rho_2  [NUM_TV-1:0];
    reg [0:18431]    z_2    [NUM_TV-1:0];
    reg [0:10239]    t1_2   [NUM_TV-1:0];
    reg [0:671]      h_2    [NUM_TV-1:0];
    

    reg [0:255]          c_3   [NUM_TV-1:0];
    reg [0:487]          h_3   [NUM_TV-1:0];
    reg [0:255]          rho_3 [NUM_TV-1:0];
    reg [0:15359]        t1_3  [NUM_TV-1:0];
    reg [0:25600-1]      z_3  [NUM_TV-1:0];
   
    reg [0:255]          c_5   [NUM_TV-1:0];
    reg [0:663]          h_5   [NUM_TV-1:0];
    reg [0:255]          rho_5 [NUM_TV-1:0];
    reg [0:20480-1]      t1_5  [NUM_TV-1:0];
    reg [0:35840-1]      z_5  [NUM_TV-1:0];
    
  initial begin
    $readmemh("zs_2.txt",   z_2);
    $readmemh("rho_2.txt",  rho_2);
    $readmemh("t1_2.txt",   t1_2);
    $readmemh("m_2.txt",    m_2);
    $readmemh("mlen_2.txt", mlen_2);
    $readmemh("c_2.txt",    c_2);
    $readmemh("h_2.txt",    h_2);
    
    $readmemh("zs_3.txt",   z_3);
    $readmemh("rho_3.txt",  rho_3);
    $readmemh("t1_3.txt",   t1_3);
    $readmemh("c_3.txt",    c_3);
    $readmemh("h_3.txt",    h_3);
    
    $readmemh("zs_5.txt",   z_5);
    $readmemh("rho_5.txt",  rho_5);
    $readmemh("t1_5.txt",   t1_5);
    $readmemh("c_5.txt",    c_5);
    $readmemh("h_5.txt",    h_5);
    
    c = 0;
    ctr   = 0;
    state = START;
    start = 0;
    rst  = 1;
  end
  
  always @(posedge clk) begin
    data_i  <= 0;
    valid_i <= 0;
    ready_o <= 0;
    start   <= 0;
    rst     <= 0;
    
    case(sec_lvl)
    2: begin
        case(state)
        START: begin
            start_time <= $time;
            if (ctr < 2) begin
                ctr    <= ctr + 1;
                rst  <= 1;
            end else begin
                ctr <= 0;
                start <= 1;
                state  <= LOAD_RHO;
            end
        end
        LOAD_RHO: begin
            data_i  <= rho_2[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 3) begin
                    state  <= LOAD_C;
                    ctr    <= 0;
                    data_i <= c_2[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= rho_2[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_C: begin
            data_i  <= c_2[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 3) begin
                    state  <= LOAD_Z;
                    ctr    <= 0;
                    data_i <= z_2[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= c_2[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_Z: begin
            data_i  <= z_2[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 287) begin
                    state  <= LOAD_T1;
                    ctr    <= 0;
                    data_i <= t1_2[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= z_2[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_T1: begin
            data_i  <= t1_2[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 159) begin
                    state  <= LOAD_MLEN;
                    ctr    <= 0;
                    data_i <= {48'd0, mlen_2[c]};
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= t1_2[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_MLEN: begin
            data_i <= {48'd0, mlen_2[c]};
            valid_i <= 1;
            
            if (ready_i) begin
                state  <= LOAD_M;
                ctr    <= 0;
                data_i <= m_2[c][(0)*64+:64];
            end
        end
        LOAD_M: begin
            data_i  <= m_2[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if ((ctr+1)*8 >= mlen_2[c]) begin
                    state  <= LOAD_H;
                    ctr    <= 0;
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= m_2[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_H: begin
            data_i  <= h_2[c][ctr*64+:64];
            valid_i <= 1;
        
            if (ready_i) begin
                if (ctr == 10) begin
                    state  <= UNLOAD_RESULT;
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= h_2[c][(ctr+1)*64+:64];
                end
            end
        end
        UNLOAD_RESULT: begin
            ready_o <= 1;
            if (valid_o) begin
                if (data_o == 1) begin
                    $display("Rejected");
                end 
                state <= STOP;
            end
        end
        STOP: begin
            ready_o <= 1;
            c       <= c + 1;
            state <= START;
            ctr   <= 0;

            $display("VY2[%d] completed in %d clock cycles", c, ($time-start_time)/10);

            if (c == NUM_TV-1) begin
                c <= 0;
                sec_lvl <= 3;
                $display ("Moving to VY3");
            end       
        end
        endcase
    end
    3: begin
        case(state)
        START: begin
            start_time <= $time;
            if (ctr < 2) begin
                ctr    <= ctr + 1;
            end else begin
                ctr <= 0;
                start <= 1;
                state  <= LOAD_RHO;
            end
        end
        LOAD_RHO: begin
            data_i  <= rho_3[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 3) begin
                    state  <= LOAD_C;
                    ctr    <= 0;
                    data_i <= c_3[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= rho_3[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_C: begin
            data_i  <= c_3[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 3) begin
                    state  <= LOAD_Z;
                    ctr    <= 0;
                    data_i <= z_3[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= c_3[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_Z: begin
            data_i  <= z_3[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 25600/64-1) begin
                    state  <= LOAD_T1;
                    ctr    <= 0;
                    data_i <= t1_3[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= z_3[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_T1: begin
            data_i  <= t1_3[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 15360/64-1) begin
                    state  <= LOAD_MLEN;
                    ctr    <= 0;
                    data_i <= {48'd0, mlen_2[c]};
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= t1_3[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_MLEN: begin
            data_i <= {48'd0, mlen_2[c]};
            valid_i <= 1;
            
            if (ready_i) begin
                state  <= LOAD_M;
                ctr    <= 0;
                data_i <= m_2[c][(0)*64+:64];
            end
        end
        LOAD_M: begin
            data_i  <= m_2[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if ((ctr+1)*8 >= mlen_2[c]) begin
                    state  <= LOAD_H;
                    ctr    <= 0;
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= m_2[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_H: begin
            data_i  <= h_3[c][ctr*64+:64];
            valid_i <= 1;
        
            if (ready_i) begin
                if (ctr == 7) begin
                    state  <= UNLOAD_RESULT;
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= h_3[c][(ctr+1)*64+:64];
                end
            end
        end
        UNLOAD_RESULT: begin
            ready_o <= 1;
            if (valid_o) begin
                if (data_o == 1) begin
                    $display("Rejected");
                end
                state <= STOP;
            end
        end
        STOP: begin
            ready_o <= 1;
            c       <= c + 1;
            state <= START;
            ctr   <= 0;

            $display("VY3[%d] completed in %d clock cycles", c, ($time-start_time)/10);

            if (c == NUM_TV-1) begin
                c <= 0;
                sec_lvl <= 5;
                $display ("Moving to VY5");
            end           
        end
        endcase
    end
    5: begin
        case(state)
        START: begin
            start_time <= $time;
            if (ctr < 2) begin
                ctr    <= ctr + 1;
            end else begin
                ctr <= 0;
                start <= 1;
                state  <= LOAD_RHO;
            end
        end
        LOAD_RHO: begin
            data_i  <= rho_5[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 3) begin
                    state  <= LOAD_C;
                    ctr    <= 0;
                    data_i <= c_5[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= rho_5[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_C: begin
            data_i  <= c_5[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 3) begin
                    state  <= LOAD_Z;
                    ctr    <= 0;
                    data_i <= z_5[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= c_5[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_Z: begin
            data_i  <= z_5[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 35840/64-1) begin
                    state  <= LOAD_T1;
                    ctr    <= 0;
                    data_i <= t1_5[c][(0)*64+:64];
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= z_5[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_T1: begin
            data_i  <= t1_5[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if (ctr == 20480/64-1) begin
                    state  <= LOAD_MLEN;
                    ctr    <= 0;
                    data_i <= {48'd0, mlen_2[c]};
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= t1_5[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_MLEN: begin
            data_i <= {48'd0, mlen_2[c]};
            valid_i <= 1;
            
            if (ready_i) begin
                state  <= LOAD_M;
                ctr    <= 0;
                data_i <= m_2[c][(0)*64+:64];
            end
        end
        LOAD_M: begin
            data_i  <= m_2[c][ctr*64+:64];
            valid_i <= 1;
            
            if (ready_i) begin
                if ((ctr+1)*8 >= mlen_2[c]) begin
                    state  <= LOAD_H;
                    ctr    <= 0;
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= m_2[c][(ctr+1)*64+:64];
                end
            end
        end
        LOAD_H: begin
            data_i  <= h_5[c][ctr*64+:64];
            valid_i <= 1;
        
            if (ready_i) begin
                if (ctr == 10) begin
                    state  <= UNLOAD_RESULT;
                end else begin
                    ctr    <= ctr + 1;
                    data_i <= h_5[c][(ctr+1)*64+:64];
                end
            end
        end
        UNLOAD_RESULT: begin
            ready_o <= 1;
            if (valid_o) begin
                if (data_o == 1) begin
                    $display("Rejected");
                end
                state <= STOP;
            end
        end
        STOP: begin
            ready_o <= 1;
            c       <= c + 1;
            state <= START;
            ctr   <= 0;

            $display("VY5[%d] completed in %d clock cycles", c, ($time-start_time)/10);

            if (c == NUM_TV-1) begin
                c <= 0;
                sec_lvl <= 3;
                $display ("Testbench done.");
                $finish;
            end        
        end
        endcase
    end
    endcase
  
  end
  
  always #(`P/2) clk = ~clk;
  

endmodule
`undef P