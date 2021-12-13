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
#include "ref_ntt.h"
#include "../consts.h"

void ntt(data_t a[DILITHIUM_N])
{
    unsigned int len, start, j, k;
    data_t zeta, t;

    k = 0;
    for (len = DILITHIUM_N / 2; len > 0; len >>= 1)
    {
        for (start = 0; start < DILITHIUM_N; start = j + len)
        {
            zeta = zetas_barrett[++k];
            for (j = start; j < start + len; ++j)
            {
                t = ((data2_t)zeta * a[j + len]) % DILITHIUM_Q;
                a[j + len] = (a[j] - t) % DILITHIUM_Q;
                a[j] = (a[j] + t) % DILITHIUM_Q;
            }
        }
    }
}

void pointwise_barrett(data_t c[DILITHIUM_N],
                       const data_t a[DILITHIUM_N],
                       const data_t b[DILITHIUM_N])
{
    for (unsigned i = 0; i < DILITHIUM_N; ++i)
    {
        c[i] = ((data2_t)a[i] * b[i]) % DILITHIUM_Q;
    }
}

void invntt(data_t a[DILITHIUM_N])
{
    unsigned int start, len, j, k;
    data_t t, zeta, w;

    const data_t f = 8347681; // pow(256, -1, 8380417)

    k = DILITHIUM_N;
    for (len = 1; len < DILITHIUM_N; len <<= 1)
    {
        for (start = 0; start < DILITHIUM_N; start = j + len)
        {
            // Plus Q so it is alway positive
            zeta = - zetas_barrett[--k];
            for (j = start; j < start + len; ++j)
            {
                t = a[j];
                a[j] = (t + a[j + len]) % DILITHIUM_Q;
                w = (t - a[j + len]) % DILITHIUM_Q;
                a[j + len] = ((data2_t)zeta * w) % DILITHIUM_Q;
            }
        }
    }

    for (j = 0; j < DILITHIUM_N; ++j)
    {
        a[j] = ((data2_t)f * a[j]) % DILITHIUM_Q;
    }
}
