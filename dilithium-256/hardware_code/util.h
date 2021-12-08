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

#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>
#include <stdio.h>
#include "config.h"

template <typename T>
void print_array(T *a, int bound, const char *string)
{
    printf("%s :", string);
    for (int i = 0; i < bound; i++)
    {
        printf("%3u, ", a[i]);
    }
    printf("\n");
}

void print_reshaped_array(bram *ram, int bound, const char *string);

void print_index_reshaped_array(bram *ram, int index);

void reshape(bram *ram, const data_t in[DILITHIUM_N]);

int compare_array(data_t *a, data_t *b, int bound);

int compare_bram_array(bram *ram, data_t array[DILITHIUM_N],
                       const char *string,
                       enum MAPPING mapping, int print_out);

#endif
