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

module decomp_map1(
    input [2:0] sec_lvl,
    input [22:0]     din,
    output reg [5:0] dout
    );
    
    reg [16:0] dout_32;
    reg [44:0] dout_88;

    always @(*) begin
        dout_32[0] = 1;

        dout_32[1] = (din >= 23'd261889) ? 1 : 0;
        dout_32[2] = (din >= 23'd785665) ? 1 : 0;
        dout_32[3] = (din >= 23'd1309441) ? 1 : 0;
        dout_32[4] = (din >= 23'd1833217) ? 1 : 0;
        dout_32[5] = (din >= 23'd2356993) ? 1 : 0;
        dout_32[6] = (din >= 23'd2880769) ? 1 : 0;
        dout_32[7] = (din >= 23'd3404545) ? 1 : 0;
        dout_32[8] = (din >= 23'd3928321) ? 1 : 0;
        dout_32[9] = (din >= 23'd4452097) ? 1 : 0;
        dout_32[10] = (din >= 23'd4975873) ? 1 : 0;
        dout_32[11] = (din >= 23'd5499649) ? 1 : 0;
        dout_32[12] = (din >= 23'd6023425) ? 1 : 0;
        dout_32[13] = (din >= 23'd6547201) ? 1 : 0;
        dout_32[14] = (din >= 23'd7070977) ? 1 : 0;
        dout_32[15] = (din >= 23'd7594753) ? 1 : 0;
        dout_32[16] = (din >= 23'd8118529) ? 1 : 0;

        dout_88[0] = 1;
        dout_88[1] = (din >= 23'd95233) ? 1 : 0;
        dout_88[2] = (din >= 23'd285697) ? 1 : 0;
        dout_88[3] = (din >= 23'd476161) ? 1 : 0;
        dout_88[4] = (din >= 23'd666625) ? 1 : 0;
        dout_88[5] = (din >= 23'd857089) ? 1 : 0;
        dout_88[6] = (din >= 23'd1047553) ? 1 : 0;
        dout_88[7] = (din >= 23'd1238017) ? 1 : 0;
        dout_88[8] = (din >= 23'd1428481) ? 1 : 0;
        dout_88[9] = (din >= 23'd1618945) ? 1 : 0;
        dout_88[10] = (din >= 23'd1809409) ? 1 : 0;
        dout_88[11] = (din >= 23'd1999873) ? 1 : 0;
        dout_88[12] = (din >= 23'd2190337) ? 1 : 0;
        dout_88[13] = (din >= 23'd2380801) ? 1 : 0;
        dout_88[14] = (din >= 23'd2571265) ? 1 : 0;
        dout_88[15] = (din >= 23'd2761729) ? 1 : 0;
        dout_88[16] = (din >= 23'd2952193) ? 1 : 0;
        dout_88[17] = (din >= 23'd3142657) ? 1 : 0;
        dout_88[18] = (din >= 23'd3333121) ? 1 : 0;
        dout_88[19] = (din >= 23'd3523585) ? 1 : 0;
        dout_88[20] = (din >= 23'd3714049) ? 1 : 0;
        dout_88[21] = (din >= 23'd3904513) ? 1 : 0;
        dout_88[22] = (din >= 23'd4094977) ? 1 : 0;
        dout_88[23] = (din >= 23'd4285441) ? 1 : 0;
        dout_88[24] = (din >= 23'd4475905) ? 1 : 0;
        dout_88[25] = (din >= 23'd4666369) ? 1 : 0;
        dout_88[26] = (din >= 23'd4856833) ? 1 : 0;
        dout_88[27] = (din >= 23'd5047297) ? 1 : 0;
        dout_88[28] = (din >= 23'd5237761) ? 1 : 0;
        dout_88[29] = (din >= 23'd5428225) ? 1 : 0;
        dout_88[30] = (din >= 23'd5618689) ? 1 : 0;
        dout_88[31] = (din >= 23'd5809153) ? 1 : 0;
        dout_88[32] = (din >= 23'd5999617) ? 1 : 0;
        dout_88[33] = (din >= 23'd6190081) ? 1 : 0;
        dout_88[34] = (din >= 23'd6380545) ? 1 : 0;
        dout_88[35] = (din >= 23'd6571009) ? 1 : 0;
        dout_88[36] = (din >= 23'd6761473) ? 1 : 0;
        dout_88[37] = (din >= 23'd6951937) ? 1 : 0;
        dout_88[38] = (din >= 23'd7142401) ? 1 : 0;
        dout_88[39] = (din >= 23'd7332865) ? 1 : 0;
        dout_88[40] = (din >= 23'd7523329) ? 1 : 0;
        dout_88[41] = (din >= 23'd7713793) ? 1 : 0;
        dout_88[42] = (din >= 23'd7904257) ? 1 : 0;
        dout_88[43] = (din >= 23'd8094721) ? 1 : 0;
        dout_88[44] = (din >= 23'd8285185) ? 1 : 0;

        dout = 0;
        if (sec_lvl == 2) begin
            case(1'b1)
            dout_88[44]: dout = 0;
            dout_88[43]: dout = 43;
            dout_88[42]: dout = 42;
            dout_88[41]: dout = 41;
            dout_88[40]: dout = 40;
            dout_88[39]: dout = 39;
            dout_88[38]: dout = 38;
            dout_88[37]: dout = 37;
            dout_88[36]: dout = 36;
            dout_88[35]: dout = 35;
            dout_88[34]: dout = 34;
            dout_88[33]: dout = 33;
            dout_88[32]: dout = 32;
            dout_88[31]: dout = 31;
            dout_88[30]: dout = 30;
            dout_88[29]: dout = 29;
            dout_88[28]: dout = 28;
            dout_88[27]: dout = 27;
            dout_88[26]: dout = 26;
            dout_88[25]: dout = 25;
            dout_88[24]: dout = 24;
            dout_88[23]: dout = 23;
            dout_88[22]: dout = 22;
            dout_88[21]: dout = 21;
            dout_88[20]: dout = 20;
            dout_88[19]: dout = 19;
            dout_88[18]: dout = 18;
            dout_88[17]: dout = 17;
            dout_88[16]: dout = 16;
            dout_88[15]: dout = 15;
            dout_88[14]: dout = 14;
            dout_88[13]: dout = 13;
            dout_88[12]: dout = 12;
            dout_88[11]: dout = 11;
            dout_88[10]: dout = 10;
            dout_88[9]: dout = 9;
            dout_88[8]: dout = 8;
            dout_88[7]: dout = 7;
            dout_88[6]: dout = 6;
            dout_88[5]: dout = 5;
            dout_88[4]: dout = 4;
            dout_88[3]: dout = 3;
            dout_88[2]: dout = 2;
            dout_88[1]: dout = 1;
            dout_88[0]: dout = 0;
            endcase
        end else begin
            case(1'b1)
            dout_32[16]: dout = 0;
            dout_32[15]: dout = 15;
            dout_32[14]: dout = 14;
            dout_32[13]: dout = 13;
            dout_32[12]: dout = 12;
            dout_32[11]: dout = 11;
            dout_32[10]: dout = 10;
            dout_32[9]: dout = 9;
            dout_32[8]: dout = 8;
            dout_32[7]: dout = 7;
            dout_32[6]: dout = 6;
            dout_32[5]: dout = 5;
            dout_32[4]: dout = 4;
            dout_32[3]: dout = 3;
            dout_32[2]: dout = 2;
            dout_32[1]: dout = 1;
            dout_32[0]: dout = 0;
            endcase
        end

    end
endmodule