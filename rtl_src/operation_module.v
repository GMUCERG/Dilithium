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


module operation_module(
    input clk,
    input rst,
    input start,
    input [2:0] mode,
    input [1:0] encode_mode,
    output reg done = 0,
    // BRAM 1
    output reg [5:0]  addra1 = 0,
    output reg [5:0]  addrb1 = 0,
    input      [95:0] doa1,
    input      [95:0] dob1,
    output reg        web1 = 0,
    output reg [95:0] dib1 = 0,
    // BRAM 2  
    output reg [5:0]  addra2 = 0,
    output reg [5:0]  addrb2 = 0,
    input      [95:0] doa2,
    output reg        web2 = 0,
    output reg [95:0] dib2 = 0
    );
    
    localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1,
        MULT_MODE        = 3'd2,
        ADD_MODE         = 3'd3,
        SUB_MODE         = 3'd4;
        
    reg         validi_bf = 0;
    reg [95:0]  datai_bf = 0;
    reg [95:0]  zetai_bf = 0;
    reg [95:0]  acci_bf  = 0;
    wire [95:0] datao_bf;
    wire        valido_bf;
        
    reg done_latch = 0, pause = 0, done_delay;
    
    reg [3:0] pause_ctr;

    reg en_addr, rst_addr;
    wire [5:0] ram_addr;
    wire [5:0] ram_nat;
    wire [7:0] twiddle_addr [3:0];
    wire ntt_round_done, done_addr;
    address_unit ADDR(
        clk, rst_addr, mode, encode_mode, en_addr, ram_nat, ram_addr,
        twiddle_addr[0], twiddle_addr[1], 
        twiddle_addr[2], twiddle_addr[3],
        ntt_round_done, done_addr
    );
        
    reg en_twiddle;
    wire [23:0] do1_twiddle,do2_twiddle,do3_twiddle,do4_twiddle;
    
    dual_port_rom #(.WIDTH(24), .LENGTH(256), .INIT_FILE("D:/programming/0_GMU/DilithiumGMU/zetas.txt")) 
            TWIDDLE_RAM1 (clk, en_twiddle, twiddle_addr[0], twiddle_addr[1],do1_twiddle,do2_twiddle);
    dual_port_rom #(.WIDTH(24), .LENGTH(256), .INIT_FILE("D:/programming/0_GMU/DilithiumGMU/zetas.txt")) 
            TWIDDLE_RAM2 (clk, en_twiddle, twiddle_addr[2], twiddle_addr[3],do3_twiddle,do4_twiddle);
    
    butterfly2x2 BF_CIRCUIT(
        clk, rst, mode, validi_bf, datai_bf,
        zetai_bf, acci_bf, datao_bf, valido_bf
    );
    
    
    reg en_pipo;
    wire [95:0] out_pipo;
    NTT_PIPO DELAY_TWIDDLE (
        clk,  en_pipo,
        {do4_twiddle,do3_twiddle,do2_twiddle,do1_twiddle},
        out_pipo
    );
        
    reg en_fifo, rst_fifo;
    wire [95:0] data_in;
    wire [95:0] new_value;
    wire [95:0] data_out;
    assign new_value = (mode == INVERSE_NTT_MODE) ? datao_bf : 0;
    assign data_in   = (mode == FORWARD_NTT_MODE) ? doa1     : 0;
    ntt_fifo FIFO (
        clk, rst_fifo, en_fifo, mode, data_in, new_value, data_out
    );
    
    reg running, bram_delay, pause_delay,pause_delay1;
    
    reg [5:0] addr1_sr [23:0];
    reg [7:0] valid_sr = 0;
    
    integer i;
    
    initial begin
        running    = 0;
        bram_delay = 0;
        done_latch = 0;
        pause      = 0;
        
        for (i = 0; i < 23; i = i + 1)
            addr1_sr[i] = 0;
    end 
    
    always @(*) begin
        // BRAM 1
        addra1 = 0;
        addrb1 = 0; web1 = 0; dib1 = 0;
        
        // BRAM 2  
        addra2 = 0;
        addrb2 = 0; web2 = 0; dib2 = 0;

        validi_bf = 0;
        datai_bf  = 0;
        zetai_bf  = 0;
        acci_bf   = 0;

        en_addr = 0;
        en_twiddle = 0;
        en_fifo = 0;
        en_pipo = 0;

        rst_addr = rst | start;
        rst_fifo = rst;

        case(mode)
        FORWARD_NTT_MODE: begin
            en_addr = running & ~done_latch & ~pause & ~ntt_round_done; 
            addra1  = ram_addr;
            
            datai_bf  = data_out;
            zetai_bf  = out_pipo;
            validi_bf = valid_sr[5];
            
            addrb1 = addr1_sr[21];
            web1   = valido_bf;
            dib1   = datao_bf;
            
            if (pause && valid_sr[5:0] == 0) begin
                rst_fifo = 1;
            end

            en_twiddle = 1;
            en_fifo = (valid_sr[5:0] != 0) ? 1 : 0; 
            en_pipo = (valid_sr[5:0] != 0) ? 1 : 0; 
        end
        INVERSE_NTT_MODE: begin
            en_addr = running & ~done_latch & ~pause;
            addra1  = ram_addr;
            
            datai_bf  = doa1;
            zetai_bf  = {do4_twiddle,do3_twiddle,do2_twiddle,do1_twiddle};
            validi_bf = bram_delay  & ~done & ~done_delay & ~pause_delay;
            
            addrb1 = addr1_sr[22];
            web1   = valid_sr[3];
            dib1   = data_out;
            
            en_twiddle = 1;
            en_fifo = valido_bf || (valid_sr[3:0] != 0); 
        end
        MULT_MODE: begin
            en_addr = running & ~done_latch;
            // addra1: multa, addra2: multb, addrb1: accumulate
            addra1  = ram_addr;
            addra2  = ram_nat;
            addrb1  = ram_addr;
            
            datai_bf  = doa1;
            zetai_bf  = {doa2[71:48],doa2[23:0],doa2[95:72],doa2[47:24]};
            acci_bf   = dob1;
            validi_bf = bram_delay  & ~done_latch & ~done;
            
            // addrb2: write
            addrb2 = addr1_sr[8];
            web2   = valido_bf;
            dib2   = datao_bf;
        end
        ADD_MODE, SUB_MODE: begin
            en_addr = running & ~done_latch;
            addra1  = ram_addr;
            addra2  = ram_addr;
            
            datai_bf  = doa1;
            zetai_bf  = {doa2[71:48],doa2[23:0],doa2[95:72],doa2[47:24]};
            validi_bf = bram_delay  & ~done_latch & ~done;
            
            addrb2 = addr1_sr[4];
            web2   = valido_bf;
            dib2   = datao_bf;
        end
        endcase
    
    end
    
    always @(posedge clk) begin
        done <= 0;
        bram_delay <= running;
        pause_delay <= pause;
        pause_delay1 <= pause_delay;
        valid_sr   <= valid_sr;
        done_delay <= done_latch;
        
        if (rst) begin
            running    <= 0;
            done_latch <= 0;
            pause      <= 0;
            pause_ctr <= 0;
            
            valid_sr <= 0;
            for (i = 0; i < 23; i = i + 1)
                addr1_sr[i] <= 0;
        end else begin
            running <= running;
            
            if (running || (mode == FORWARD_NTT_MODE && valido_bf)) begin
                addr1_sr[0] <= ram_addr;
                for (i = 0; i < 23; i = i + 1)
                    addr1_sr[i+1] <= addr1_sr[i];
            end
        
            case(mode)
            FORWARD_NTT_MODE: begin
                done_latch <= (done_addr) ? 1 : done_latch;

                if (ntt_round_done) begin
                    pause <= 1;
                    pause_ctr <= 0;
                end else if (pause) begin
                    pause_ctr <= pause_ctr + 1;
                    pause <= (pause_ctr == 6) ? 0 : 1;
                end

                if (running && ~done_addr && ~done_latch && ~pause && ~ntt_round_done)
                    valid_sr <= {valid_sr[6:0], 1'b1};
                else 
                    valid_sr <= {valid_sr[6:0], 1'b0};
                
                if (done_addr) begin
                    running <= 0;
                end
                
                if (start) begin
                    running <= 1;
                end else if (done_latch && !valido_bf) begin
                    done       <= 1;
                    done_latch <= 0;
                end  
            end
            INVERSE_NTT_MODE: begin
                done_latch <= (done_addr) ? 1 : done_latch;
                if (ntt_round_done) begin
                    pause <= 1;
                    pause_ctr <= 0;
                end else if (pause) begin
                    pause_ctr <= pause_ctr + 1;
                    pause <= (pause_ctr == 4) ? 0 : 1;
                end
                    
                if (running)
                    valid_sr <= {valid_sr[6:0], valido_bf};
            
                if (start)
                    running <= 1;

                
                else if (done_latch && valid_sr[3:0] == 0) begin
                    running    <= 0;
                    done       <= 1;
                    done_latch <= 0;
                end  
            end
            MULT_MODE, ADD_MODE, SUB_MODE: begin
                done_latch <= (done_addr) ? 1 : done_latch;
                
                if (running && ~done_addr && ~done_latch)
                    valid_sr <= {valid_sr[6:0], 1'b1};
                else 
                    valid_sr <= {valid_sr[6:0], 1'b0};
                
                if (start)
                    running <= 1;
                else if (done_latch && valid_sr[6:0] == 0) begin
                    running    <= 0;
                    done       <= 1;
                    done_latch <= 0;
                end  
            end
            endcase
        end
    
    end
    
endmodule
