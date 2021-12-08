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

#ifndef FIFO_H
#define FIFO_H

#include <stdint.h>
#include <cstdio>
#include "config.h"

// Don't change this
#define DEPT_I 3
#define DEPT_W 4
#define DEPT_A 4
#define DEPT_B 6
#define DEPT_C 5
#define DEPT_D 7

/* 
 * Serial in, serial out
 * This function receive 1 elements at the begin of FIFO
 */
template <int DEPT>
data_t FIFO(data_t fifo[DEPT], const data_t new_value)
{
    data_t out = fifo[DEPT - 1];
    for (int i = DEPT - 1; i > 0; i--)
    {
        // printf("%d <= %d\n", i, i-1);
        fifo[i] = fifo[i - 1];
    }
    fifo[0] = new_value;

    return out;
}

/* 
 * Parallel in, parallel out
 * Goal: Delay 4 twiddle factors for butterfly units
 * This function receive 4 elements at the begin of FIFO. 
 * [] -> [] -> [] -> [] 
 * [] -> [] -> [] -> []
 * [] -> [] -> [] -> []
 * [] -> [] -> [] -> []
 */
template <int DEPT, typename T>
void PIPO(T w_out[4], T fifo[DEPT][DEPT],
          const T w_in[4])
{
    w_out[0] = fifo[DEPT - 1][0];
    w_out[1] = fifo[DEPT - 1][1];
    w_out[2] = fifo[DEPT - 1][2];
    w_out[3] = fifo[DEPT - 1][3];

    for (int i = DEPT - 1; i > 0; i--)
    {
        for (int j = 0; j < DEPT; j++)
        {
            fifo[i][j] = fifo[i - 1][j];
        }
    }
    fifo[0][0] = w_in[0];
    fifo[0][1] = w_in[1];
    fifo[0][2] = w_in[2];
    fifo[0][3] = w_in[3];
}

template <int DEPT, typename T>
T FIFO_PISO(T fifo[DEPT], const bool piso_en, const T line[4], const T new_value)
{
    T out = fifo[DEPT - 1];
    for (int i = DEPT - 1; i > 3; i--)
    {
        fifo[i] = fifo[i - 1];
    }
    if (piso_en)
    {
        fifo[3] = line[0];
        fifo[2] = line[1];
        fifo[1] = line[2];
        fifo[0] = line[3];
    }
    else
    {
        fifo[3] = fifo[2];
        fifo[2] = fifo[1];
        fifo[1] = fifo[0];
        fifo[0] = new_value;
    }
    return out;
}

template <typename T>
void read_fifo(T data_out[4],
               const unsigned count,
               const T fifo_a[DEPT_A],
               const T fifo_b[DEPT_B],
               const T fifo_c[DEPT_C],
               const T fifo_d[DEPT_D])
{
    T ta, tb, tc, td;

    // Serial in Parallel out
    switch (count & 3)
    {
    case 0:
        ta = fifo_a[DEPT_A - 1];
        tb = fifo_a[DEPT_A - 2];
        tc = fifo_a[DEPT_A - 3];
        td = fifo_a[DEPT_A - 4];
        break;

    case 2:
        ta = fifo_b[DEPT_B - 1];
        tb = fifo_b[DEPT_B - 2];
        tc = fifo_b[DEPT_B - 3];
        td = fifo_b[DEPT_B - 4];
        break;
    case 1:
        ta = fifo_c[DEPT_C - 1];
        tb = fifo_c[DEPT_C - 2];
        tc = fifo_c[DEPT_C - 3];
        td = fifo_c[DEPT_C - 4];
        break;
    default:
        ta = fifo_d[DEPT_D - 1];
        tb = fifo_d[DEPT_D - 2];
        tc = fifo_d[DEPT_D - 3];
        td = fifo_d[DEPT_D - 4];
        break;
    }

    data_out[0] = ta;
    data_out[1] = tb;
    data_out[2] = tc;
    data_out[3] = td;
}

/* This module rolling FIFO base on operation mode: FWD_NTT or INV_NTT
 * Input: 
 * data_fifo[4]: 4 coefficients to be written to FIFO in parallel-in style
 * [] -> [] -> [] -> []
 * new_value[4]: Each coefficient is written to FIFO in FIFO style
 * [] -> ... 
 * [] -> ... 
 * [] -> ... 
 * [] -> ... 
 * FIFO_A/B/C/D: Pre-defined FIFO
 * count: select which FIFO to be written
 * Output:
 * data_out[4]: Output of this module
 */
template <typename T>
void read_write_fifo(enum OPERATION mode,
                     T data_out[4],
                     const T data_in[4], const T new_value[4],
                     T fifo_a[DEPT_A], T fifo_b[DEPT_B],
                     T fifo_c[DEPT_C], T fifo_d[DEPT_D],
                     const unsigned count)
{
    T fa, fb, fc, fd;
    bool a_piso_en = false,
         b_piso_en = false,
         c_piso_en = false,
         d_piso_en = false;

    switch (count & 3)
    {
        // Use PISO to write
    case 0:
        // Write to FIFO_D
        d_piso_en = true;
        break;
    case 1:
        // Write to FIFO_B
        b_piso_en = true;
        break;
    case 2:
        // Write to FIFO_C
        c_piso_en = true;
        break;

    default:
        // Write to FIFO_A
        a_piso_en = true;
        break;
    }
    a_piso_en &= (mode == FORWARD_NTT_MODE);
    b_piso_en &= (mode == FORWARD_NTT_MODE);
    c_piso_en &= (mode == FORWARD_NTT_MODE);
    d_piso_en &= (mode == FORWARD_NTT_MODE);

    fd = FIFO_PISO<DEPT_A, T>(fifo_a, a_piso_en, data_in, new_value[0]);
    fb = FIFO_PISO<DEPT_B, T>(fifo_b, b_piso_en, data_in, new_value[1]);
    fc = FIFO_PISO<DEPT_C, T>(fifo_c, c_piso_en, data_in, new_value[2]);
    fa = FIFO_PISO<DEPT_D, T>(fifo_d, d_piso_en, data_in, new_value[3]);

    if (mode == FORWARD_NTT_MODE)
    {
        data_out[0] = fa;
        data_out[1] = fc;
        data_out[2] = fb;
        data_out[3] = fd;
    }
    else
    {
        read_fifo<T>(data_out, count, fifo_a, fifo_b, fifo_c, fifo_d);
    }
}

#endif
