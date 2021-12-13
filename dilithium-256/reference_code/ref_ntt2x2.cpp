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
#include "ref_ntt2x2.h"
#include "../consts.h"

#define DEBUG 0

// ================ FORWARD NTT 2x2 ========================

#define ctbf(a, b, z, t)                     \
    t = ((data2_t)b * z) % DILITHIUM_Q;      \
    b = (a - t) % DILITHIUM_Q; \
    a = (a + t) % DILITHIUM_Q;

void ntt2x2_ref(data_t a[DILITHIUM_N])
{
    data_t len;
    data_t zeta1, zeta2[2];
    data_t a1, b1, a2, b2;
    data_t t1, t2;
    data_t k1, k2[2];

    for (int l = DILITHIUM_LOGN; l > 0; l -= 2)
    {
        len = 1 << (l - 2);
        for (unsigned i = 0; i < DILITHIUM_N; i += 1 << l)
        {
            k1 = (DILITHIUM_N + i) >> l;
            k2[0] = (DILITHIUM_N + i) >> (l - 1);
            k2[1] = k2[0] + 1;
            zeta1 = zetas_barrett[k1];
            zeta2[0] = zetas_barrett[k2[0]];
            zeta2[1] = zetas_barrett[k2[1]];

            for (unsigned j = i; j < i + len; j++)
            {
                a1 = a[j];
                a2 = a[j + len];
                b1 = a[j + 2 * len];
                b2 = a[j + 3 * len];

                // Left
                // a1 - b1, a2 - b2
                ctbf(a1, b1, zeta1, t1);
                ctbf(a2, b2, zeta1, t2);

                // Right
                // a1 - a2, b1 - b2
                ctbf(a1, a2, zeta2[0], t1);
                ctbf(b1, b2, zeta2[1], t2);

                a[j] = a1;
                a[j + len] = a2;
                a[j + 2 * len] = b1;
                a[j + 3 * len] = b2;
            }
        }
    }
    // End function
}

// ================ INVERSE NTT 2x2 ========================

#define gsbf(a, b, z, t)                     \
    t = (a - b) % DILITHIUM_Q; \
    a = (a + b) % DILITHIUM_Q;               \
    b = ((data2_t)t * z) % DILITHIUM_Q;

#define div2(t) ((t & 1) ? ((t >> 1) + (DILITHIUM_Q + 1) / 2) : (t >> 1))

#define gsbf_div2(a, b, z, t)                \
    t = (a - b) % DILITHIUM_Q; \
    t = div2(t);                             \
    a = (a + b) % DILITHIUM_Q;               \
    a = div2(a);                             \
    b = ((data2_t)t * z) % DILITHIUM_Q;

void invntt2x2_ref(data_t a[DILITHIUM_N])
{
    data_t len;
    data_t a1, b1, a2, b2;
    data_t t1, t2;
    data_t k1[2], k2;
    data_t zeta1[2], zeta2;

    for (int l = 0; l < DILITHIUM_LOGN - (DILITHIUM_LOGN & 1); l += 2)
    {
        len = 1 << l;
        for (unsigned i = 0; i < DILITHIUM_N; i += 1 << (l + 2))
        {
            k1[0] = ((DILITHIUM_N - i / 2) >> l) - 1;
            k1[1] = k1[0] - 1;
            k2 = ((DILITHIUM_N - i / 2) >> (l + 1)) - 1;
            zeta1[0] = -zetas_barrett[k1[0]];
            zeta1[1] = -zetas_barrett[k1[1]];
            zeta2 = -zetas_barrett[k2];

            for (unsigned j = i; j < i + len; j++)
            {
                a1 = a[j];
                a2 = a[j + len];
                b1 = a[j + 2 * len];
                b2 = a[j + 3 * len];

                // Left
                // a1 - a2, b1 - b2
                gsbf_div2(a1, a2, zeta1[0], t1);
                gsbf_div2(b1, b2, zeta1[1], t2);

                // Right
                // a1 - b1, a2 - b2
                gsbf_div2(a1, b1, zeta2, t1);
                gsbf_div2(a2, b2, zeta2, t2);

                a[j] = a1;
                a[j + len] = a2;
                a[j + 2 * len] = b1;
                a[j + 3 * len] = b2;
            }
        }
    }
    // End function
}
