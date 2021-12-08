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

module butterfly(
    input             clk,
    input             rst,
    input [2:0]       mode,
    input             validi,
    input signed[23:0]  aj,
    input signed [23:0] ajlen,
    input [23:0]      zeta,
    output reg [23:0] bj,
    output reg [23:0] bjlen,
    output reg        valido
    );
    
    localparam
        DILITHIUM_Q = 23'd8380417;
    
    localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1,
        MULT_MODE        = 3'd2,
        ADD_MODE         = 3'd3,
        SUB_MODE         = 3'd4;
    
    
    reg [23:0] aj1 = 0, ajlen1 = 0;
    reg [23:0] aj2 = 0, ajlen2_FNTT = 0;
    reg [23:0] ajlen2_INTT = 0;
    reg [23:0] ajlen2_MODM = 0;
    reg [23:0] aj3  [4:0];
    reg [45:0] mult_result;
    reg [23:0] ajlen3 = 0;
    reg [23:0] aj4 = 0, ajlen4 = 0, ajlen4_sub = 0;
    reg [23:0] aj5 = 0, ajlen5 = 0;
    
    
    reg [23:0] adda = 0, addb = 0, suba = 0, subb = 0;
    reg [23:0] adder = 0;
    reg [24:0] add_tmp = 0;
    reg [23:0] sub_tmp = 0;
    reg [23:0] subtractor = 0;
    
    reg [9:0] valid_sr;
    
    wire barrett_readyi;
    reg  barrett_validi;
    (*keep="true"*)reg  [45:0] barrett_datai;
    wire barrett_valido;
    reg  barrett_readyo;
    wire [22:0] barrett_remainder;
    wire [23:0] barrett_quotient;
    
    reg [23:0] multa, multb;
    reg [23:0] zeta_delay,zeta_delay2;
    
    Barrett REDUCER(
      clk,
      rst,
      barrett_readyi,
      barrett_validi,
      barrett_datai,
      barrett_readyo,
      barrett_valido,
      barrett_remainder,
      barrett_quotient
    );
    
    initial begin
        valid_sr = 0;
        aj3[0] = 0;
        aj3[1] = 0;
        aj3[2] = 0;
        aj3[3] = 0;
        aj3[4] = 0;
    end

    reg [2:0] modei;

    always @(*) begin
        adda   = 0;
        addb   = 0;
        suba   = 0;
        subb   = 0;
        valido = 0;
   
        barrett_readyo = 1;

        multa = ajlen2_FNTT;
        multb = (modei == INVERSE_NTT_MODE) ? zeta_delay2 : zeta_delay;

        if (mode == INVERSE_NTT_MODE) 
            valido = valid_sr[8];
        else if (mode == MULT_MODE)
            valido = valid_sr[7];
        else if (mode == FORWARD_NTT_MODE)
            valido = valid_sr[7];
        else
            valido = valid_sr[3];

        case(modei)
        FORWARD_NTT_MODE: begin
            adda = aj3[4];
            addb = ajlen3;
            
            suba = aj3[4];
            subb = ajlen3;

            multa = ajlen2_FNTT;
        end
        INVERSE_NTT_MODE: begin
            multa = ajlen2_INTT;

            adda = aj1;
            addb = ajlen1;
            
            suba = aj1;
            subb = ajlen1;
        end
        MULT_MODE: begin
            // MULT-ACC
            multa = ajlen2_MODM;

            adda = aj4;
            addb = ajlen3;
        end
        ADD_MODE: begin
            adda = ajlen1;
            addb = zeta_delay;
            
            suba = ajlen4;
            subb = DILITHIUM_Q;
        end
        SUB_MODE: begin
            adda = ajlen1;
            addb = DILITHIUM_Q;
            
            suba = aj4;
            subb = ajlen4_sub;
        end
        endcase
        
        barrett_validi = 1;
 
        adder       = adda + addb;
        mult_result = multb * ajlen2_INTT;
        sub_tmp     = suba + DILITHIUM_Q;
        subtractor  = (subb > suba) ? sub_tmp - subb : suba - subb;      
    end
    


    always @(posedge clk) begin
        if (rst) begin
            valid_sr <= 0;
        end else begin
            valid_sr <= {valid_sr[8:0], validi};
        end
        
        modei <= mode;
        
        zeta_delay <= (mode == INVERSE_NTT_MODE) ? DILITHIUM_Q - zeta :  zeta;
        zeta_delay2 <= zeta_delay;

        aj1    <= aj;
        ajlen1 <= ajlen;
        
        barrett_datai  <= mult_result;

        bj    <= (aj5 >= DILITHIUM_Q)    ? aj5    - DILITHIUM_Q : aj5;
        bjlen <= (ajlen5 >= DILITHIUM_Q) ? ajlen5 - DILITHIUM_Q : ajlen5;

        ajlen3 <= barrett_remainder;

        ajlen4 <= adder;
        ajlen4_sub <= zeta_delay;
        case(mode)
        FORWARD_NTT_MODE: begin
            aj2    <= aj;
            ajlen2_INTT <= ajlen;

            ajlen5 <= subtractor;
            aj5    <= adder;
            
        end
        INVERSE_NTT_MODE: begin
            aj2    <= adder;
            ajlen2_INTT <= subtractor;
            
            if (aj3[4][0] == 1)
                aj5 <= (aj3[4] >> 1) + (DILITHIUM_Q + 1) / 2;
            else
                aj5 <= (aj3[4] >> 1);
    
            if (ajlen3[0] == 1)
                ajlen5 <= (ajlen3 >> 1) + (DILITHIUM_Q + 1) / 2;
            else
                ajlen5 <= (ajlen3 >> 1);       
        end
        MULT_MODE: begin
            aj2    <= aj;
            aj4    <= aj3[3];
        
            ajlen2_INTT <= ajlen;
            ajlen5 <= adder;
        end
        ADD_MODE: begin
            ajlen5 <= (ajlen4 > DILITHIUM_Q) ? subtractor : ajlen4;
        end
        SUB_MODE: begin
            aj4    <= (ajlen1 < zeta_delay) ? adder : ajlen1;
            ajlen5 <= subtractor;
        end
        endcase
    
        
        aj3[0] <= aj2;
        aj3[1] <= aj3[0];
        aj3[2] <= aj3[1];
        aj3[3] <= aj3[2];
        aj3[4] <= aj3[3];
    end
    
    
    
endmodule
