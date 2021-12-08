/*
 * From our research paper "High-Performance Hardware Implementation of CRYSTALS-Dilithium"
 * by Luke Beckwith, Duc Tri Nguyen, Kris Gaj
 * at George Mason University, USA
 * https://eprint.iacr.org/2021/1451.pdf
 * =============================================================================
 * Copyright (c) 2021 by Cryptographic Engineering Research Group (CERG)
 * ECE Department, George Mason University
 * Fairfax, VA, U.S.A.
 * Author: Duc Tri Nguyen
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
 * @author   Duc Tri Nguyen <dnguye69@gmu.edu>
 */

#include "config.h"
#include "address_encoder_decoder.h"
#include "ram_util.h"
#include "butterfly_unit.h"

/* Point-wise multiplication
 * Input: ram, mul_ram, mapping
 * Output: ram
 */
void ntt2x2_mul(bram *ram, const bram *mul_ram, enum MAPPING mapping)
{
    int ram_i;
    data_t data_in[4], data_out[4];
    data_t w_in[4], w_out[4];

    for (unsigned l = 0; l < BRAM_DEPT; ++l)
    {
        ram_i = resolve_address(mapping, l);

        // Read address from RAM
        read_ram(data_in, ram, ram_i);

        // Read address from MUL_RAM
        read_ram(w_in, mul_ram, l);
        w_out[0] = w_in[1];
        w_out[1] = w_in[3];
        w_out[2] = w_in[0];
        w_out[3] = w_in[2];

        // Send to butterfly circuit
        buttefly_circuit<data2_t, data_t>(data_out, data_in, w_out, MUL_MODE);

        // Write back
        write_ram(ram, ram_i, data_out);
    }
}
