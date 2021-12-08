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

template <typename T>
const T MAX(const T a, const T b)
{
    return (a < b) ? b : a; // or: return comp(a,b)?b:a; for version (2)
}

void update_indexes(unsigned tw_i[4],
                    const unsigned tw_base_i[4],
                    const unsigned s, enum OPERATION mode)
{
    unsigned mask1, mask2;
    const unsigned w_m1 = 2;
    const unsigned w_m2 = 1;
    unsigned l1, l2, l3, l4;

    mask1 = (2 << s) - 1;
    mask2 = (2 << (s + 1)) - 1;

    l1 = tw_i[0];
    l2 = tw_i[1];
    l3 = tw_i[2];
    l4 = tw_i[3];

    // Adjust address
    if (mode == INVERSE_NTT_MODE)
    {
        // Only adjust omega in NTT mode
        l1 -= w_m1;
        l2 -= w_m1;
        l3 -= w_m2;
        l4 -= w_m2;
    }
    else if (mode == FORWARD_NTT_MODE)
    {
        if (s < (DILITHIUM_LOGN - 2))
        {
            l1 = MAX<unsigned>(tw_base_i[0], (l1 + 1) & mask1);
            l2 = MAX<unsigned>(tw_base_i[1], (l2 + 1) & mask1);
            l3 = MAX<unsigned>(tw_base_i[2], (l3 + 2) & mask2);
            l4 = MAX<unsigned>(tw_base_i[3], (l4 + 2) & mask2);
        }
        else
        {
            l1 += w_m2;
            l2 += w_m2;
            l3 += w_m1;
            l4 += w_m1;
        }
    }
    tw_i[0] = l1;
    tw_i[1] = l2;
    tw_i[2] = l3;
    tw_i[3] = l4;
}
