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
#include "config.h"
#include "ram_util.h"
#include "address_encoder_decoder.h"

void print_reshaped_array(bram *ram, int bound, const char *string)
{
    data_t coeffs[4];

    printf("%s :\n", string);
    for (int i = 0; i < bound; i++)
    {
        read_ram(coeffs, ram, i);

        for (int j = 0; j < 4; j++)
        {
            printf("%u, ", coeffs[j]);
        }
    }
    printf("\n");
}

void print_index_reshaped_array(bram *ram, int index)
{
    data_t coeffs[4];

    read_ram(coeffs, ram, index);

    printf("[%d]: ", index);
    for (int j = 0; j < 4; j++)
    {
        printf("%u, ", coeffs[j]);
    }
    printf("\n");
}

// Store 4 coefficients per line
void reshape(bram *ram, const data_t in[DILITHIUM_N])
{
    data_t coeffs[4];
    for (int i = 0; i < BRAM_DEPT; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            coeffs[j] = in[4 * i + j];
        }
        write_ram(ram, i, coeffs);
    }
}

// Compare array
int compare_array(data_t *a, data_t *b, int bound)
{
    for (int i = 0; i < bound; i++)
    {
        if (a[i] != b[i])
            return 1;
    }
    return 0;
}

int compare_bram_array(bram *ram, data_t array[DILITHIUM_N],
                       const char *string,
                       enum MAPPING mapping, int print_out)
{
    data_t a, b, c, d;
    data_t ta, tb, tc, td, t[4];
    int error = 0;
    int addr;

    for (int i = 0; i < DILITHIUM_N; i += 4)
    {
        // Get golden result
        a = (array[i + 0] + DILITHIUM_Q) % DILITHIUM_Q;
        b = (array[i + 1] + DILITHIUM_Q) % DILITHIUM_Q;
        c = (array[i + 2] + DILITHIUM_Q) % DILITHIUM_Q;
        d = (array[i + 3] + DILITHIUM_Q) % DILITHIUM_Q;

        addr = i / 4;
        if (print_out)
        {
            printf("%d: %d, %d, %d, %d\n", addr, a, b, c, d);
        }
        addr = resolve_address(mapping, addr);

        read_ram(t, ram, addr);

        ta = t[0] = (t[0] + DILITHIUM_Q) % DILITHIUM_Q;
        tb = t[1] = (t[1] + DILITHIUM_Q) % DILITHIUM_Q;
        tc = t[2] = (t[2] + DILITHIUM_Q) % DILITHIUM_Q;
        td = t[3] = (t[3] + DILITHIUM_Q) % DILITHIUM_Q;
        if (print_out)
        {
            printf("[%d]: |%d, %d, %d, %d|\n", i, ta, tb, tc, td);
        }

        // Quick xor, I hate long if-else clause
        if (print_out)
        {
            printf("--------------\n");
        }

        if ((ta != a) || (tb != b) || (tc != c) || (td != d))
        {
            printf("%s Error at index: %d => %d\n", string, i, addr);
            printf("gold: %12u | %12u | %12u | %12u [*]\n", a, b, c, d);
            printf("test: %12u | %12u | %12u | %12u\n", ta, tb, tc, td);
            error = 1;
            break;
        }
    }
    if (error)
    {
        return 1;
    }
    return 0;
}
