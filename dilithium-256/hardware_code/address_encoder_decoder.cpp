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

#include <stdio.h>
#include <stdint.h>
#include "config.h"

/* 
 * Figure out how to compute address decoder/encoder on fly. 
 * However, for N=256, it's better to use table-based approach since it's fit in 1 LUT. 
 * The only computation should take more than LUT. 
 * Modulo can be replace by AND operation, divide can be replace by right shift as well. 
 */
unsigned resolve_address(enum MAPPING mapping, unsigned addr)
{
    unsigned ram_i;
    const unsigned f = DILITHIUM_N >> 4;
    switch (mapping)
    {
    case AFTER_INVNTT:
        // This can be implemented with shift and mask
        ram_i = (addr % f)*4 + addr/f;
        break;

    case AFTER_NTT:
        // This can be implemented with shift and mask
        ram_i = (addr % 4)*f + addr/4;
        break;

    case NATURAL:
        ram_i = addr;
        break;
    }
    return ram_i;
}

void resolve_twiddle(unsigned tw_i[4], unsigned *last, unsigned tw_base_i[4],
                    const int k, const int s, enum OPERATION mode)
{
    unsigned l1, l2, l3, l4;
    unsigned l1_base, l2_base, l3_base, l4_base;
    unsigned t_last = *last;
    if (mode == INVERSE_NTT_MODE)
    {
        // INVERSE_NTT_MODE
        l1_base = (DILITHIUM_N >> s) - 1;
        l2_base = (DILITHIUM_N >> s) - 2;
        l3_base = l4_base = (DILITHIUM_N >> (s + 1)) - 1;

        // Layer s
        l1 = l1_base;
        l2 = l2_base;
        // Layer s + 1
        l3 = l3_base;
        l4 = l4_base;

        if (k == 0)
        {
            tw_i[0] = l1;
            tw_i[1] = l2;
            tw_i[2] = l3;
            tw_i[3] = l4;

            tw_base_i[0] = l1_base;
            tw_base_i[1] = l2_base;
            tw_base_i[2] = l3_base;
            tw_base_i[3] = l4_base;
        }
    }
    else if (mode == FORWARD_NTT_MODE)
    {
        l1_base = l2_base = 1 << s;
        l3_base = (1 << (s + 1));
        l4_base = (1 << (s + 1)) + 1;

        // FORWARD_NTT_MODE
        // Layer s
        l1 = l1_base;
        l2 = l2_base;
        // Layer s + 1
        l3 = l3_base;
        l4 = l4_base;

        if (s < (DILITHIUM_LOGN - 2) && k == 0)
        {
            tw_i[0] = l1;
            tw_i[1] = l2;
            tw_i[2] = l3;
            tw_i[3] = l4;

            tw_base_i[0] = l1_base;
            tw_base_i[1] = l2_base;
            tw_base_i[2] = l3_base;
            tw_base_i[3] = l4_base;
        }
        // FORWARD_NTT_MODE
        else if (s >= (DILITHIUM_LOGN - 2) && !t_last)
        {
            *last = 1;

            tw_i[0] = l1;
            tw_i[1] = l2;
            tw_i[2] = l3;
            tw_i[3] = l4;

            tw_base_i[0] = l1_base;
            tw_base_i[1] = l2_base;
            tw_base_i[2] = l3_base;
            tw_base_i[3] = l4_base;
        }
    }
}
