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

#include <stdlib.h>
#include <stdio.h>
#include "ref_ntt.h"
#include "ref_ntt2x2.h"

#define TESTS 100000

int compare_array(data_t *a_gold, data_t *a)
{
    for (int i = 0; i < DILITHIUM_N; i++)
    {
        if ((a_gold[i] - a[i]) % DILITHIUM_Q != 0)
        {
            printf("%d: %d != %d\n", i, a_gold[i], a[i]);
            return 1;
        }
    }
    return 0;
}

int main()
{
    data_t a[DILITHIUM_N] = {0}, a_gold[DILITHIUM_N] = {0};
    data_t tmp;
    srand(0);

    printf("Test Forward NTT = %u :", TESTS);
    for (int j = 0; j < TESTS; j++)
    {
        // Test million times
        for (int i = 0; i < DILITHIUM_N; i++)
        {
            tmp = rand() % DILITHIUM_Q;
            a[i] = tmp;
            a_gold[i] = tmp;
        }

        ntt2x2_ref(a);
        // printf("=======\n");
        ntt(a_gold);

        if (compare_array(a_gold, a))
        {
            return 1;
        }
    }
    printf("OK\n");

    printf("Test Inverse NTT = %u :", TESTS);
    for (int j = 0; j < TESTS; j++)
    {
        // Test million times
        for (int i = 0; i < DILITHIUM_N; i++)
        {
            tmp = rand() % DILITHIUM_Q;
            a[i] = tmp;
            a_gold[i] = tmp;
        }

        invntt2x2_ref(a);
        invntt(a_gold);

        if (compare_array(a_gold, a))
        {
            return 1;
        }
    }
    printf("OK\n");
    return 0;
}

/*
 * Compile flags
 * gcc -o ref_test_ntt_ntt2x2 ref_ntt.c ref_ntt2x2.c ../consts.cpp  ref_test_ntt_ntt2x2.c -Wall
 * ./ref_test_ntt_ntt2x2
*/
