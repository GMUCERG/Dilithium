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
module dual_port_rom #(parameter WIDTH=96, LENGTH=1024, INIT_FILE="") (clk,en,addra,addrb,doa,dob);
    input clk,en;
    input [$clog2(LENGTH)-1:0] addra,addrb;
    output [WIDTH-1:0] doa,dob;
    (* rom_style = "distributed" *) reg[WIDTH-1:0] ram [LENGTH-1:0];
    reg[WIDTH-1:0] doa,dob;
    
    always @(posedge clk) begin 
        if (en) begin
            doa <= ram[addra];
            dob <= ram[addrb];
        end
    end
    
    
    integer i;
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end else begin
            for (i = 0; i < LENGTH; i = i + 1)
                ram[i] = 0;
        end
    end
    
endmodule