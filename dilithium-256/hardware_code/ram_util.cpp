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

#include "../consts.h"
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

void read_twiddle(data_t data_out[4], enum OPERATION mode, const unsigned tw_i[4])
{
    unsigned i1 = tw_i[0];
    unsigned i2 = tw_i[1];
    unsigned i3 = tw_i[2];
    unsigned i4 = tw_i[3];
    switch (mode)
    {
    case FORWARD_NTT_MODE:
        data_out[0] = zetas_barrett[i1];
        data_out[1] = zetas_barrett[i2];
        data_out[2] = zetas_barrett[i3];
        data_out[3] = zetas_barrett[i4];
        break;

    case INVERSE_NTT_MODE:
        data_out[0] = -zetas_barrett[i1];
        data_out[1] = -zetas_barrett[i2];
        data_out[2] = -zetas_barrett[i3];
        data_out[3] = -zetas_barrett[i4];
        break;

    default:
        printf("Not supported\n");
        break;
    }
}