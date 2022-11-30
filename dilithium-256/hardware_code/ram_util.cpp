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

#include "consts_hw.h"
#include "config.h"
#include <stdio.h>

void read_ram(data_t data_out[4], const bram *ram, const unsigned ram_i)
{
    data_out[0] = ram->coeffs[ram_i][0];
    data_out[1] = ram->coeffs[ram_i][1];
    data_out[2] = ram->coeffs[ram_i][2];
    data_out[3] = ram->coeffs[ram_i][3];
}

void write_ram(bram *ram, const unsigned ram_i, const data_t data_in[4])
{
    // printf("[%d] < [%d, %d, %d, %d]\n", ram_i, a, b, c, d);
    ram->coeffs[ram_i][0] = data_in[0];
    ram->coeffs[ram_i][1] = data_in[1];
    ram->coeffs[ram_i][2] = data_in[2];
    ram->coeffs[ram_i][3] = data_in[3];
}

static
unsigned int scale_twiddle(int level)
{
    const unsigned bar[] = {
        0,                              // 0 - 1
        (1 << 0),                       // 2 - 3
        (1 << 2) + (1 << 0),            // 4 - 5
        (1 << 4) + (1 << 2) + (1 << 0), // 6 - 7
        // (1 << 6) + (1 << 4) + (1 << 2) + (1 << 0),
    };
    return bar[level >> 1];
}

void get_twiddle_factors(data_t data_out[4], int i, int level, OPERATION mode)
{
    // Initialize to 0 just to slient compiler warnings
    unsigned i1 = 0, i2 = 0, i3 = 0, i4 = 0;
    unsigned index = 0, bar = 0, mask = 0; 

    switch (mode)
    {
    case FORWARD_NTT_MODE:
        mask = (1 << level) - 1;
        bar = scale_twiddle(level);
        index = bar + (i & mask);

        i1 = i2 = 0;
        i3 = 1; 
        i4 = 2;
        break;
    
    case INVERSE_NTT_MODE:
        mask = (1 << (DILITHIUM_LOGN - 2 - level)) - 1;
        bar = scale_twiddle(DILITHIUM_LOGN - 2 - level);
        index = bar + ((BRAM_DEPT - 1 - i ) & mask);

        i1 = 2; 
        i2 = 1; 
        i3 = i4 = 0;
        break;

    default:
        break;
    }

    data_out[0] = zetas_barrett_hw[index][i1];
    data_out[1] = zetas_barrett_hw[index][i2];
    data_out[2] = zetas_barrett_hw[index][i3];
    data_out[3] = zetas_barrett_hw[index][i4];
}
