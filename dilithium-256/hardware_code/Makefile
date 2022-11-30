# /*
#  * From our research paper "High-Performance Hardware Implementation of CRYSTALS-Dilithium"
#  * by Luke Beckwith, Duc Tri Nguyen, Kris Gaj
#  * at George Mason University, USA
#  * https://eprint.iacr.org/2021/1451.pdf
#  * =============================================================================
#  * Copyright (c) 2021 by Cryptographic Engineering Research Group (CERG)
#  * ECE Department, George Mason University
#  * Fairfax, VA, U.S.A.
#  * Author: Duc Tri Nguyen
#  * Licensed under the Apache License, Version 2.0 (the "License");
#  * you may not use this file except in compliance with the License.
#  * You may obtain a copy of the License at
#  *     http://www.apache.org/licenses/LICENSE-2.0
#  * Unless required by applicable law or agreed to in writing, software
#  * distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.
#  * =============================================================================
#  * @author   Duc Tri Nguyen <dnguye69@gmu.edu>
#  */

CC = /usr/bin/c++
CFLAGS = -O3 -Wall -Wpedantic
RM = /bin/rm 

REF_DIR = ../reference_code

REF_HEADERS = ../params.h
REF_HEADERS += ../consts.h   $(REF_DIR)/ref_ntt.h   $(REF_DIR)/ref_ntt2x2.h
REF_SOURCES  = ../consts.cpp $(REF_DIR)/ref_ntt.cpp $(REF_DIR)/ref_ntt2x2.cpp

HEADERS = address_encoder_decoder.h config.h ntt2x2.h util.h butterfly_unit.h fifo.h ram_util.h consts_hw.h
SOURCES = address_encoder_decoder.cpp util.cpp ram_util.cpp ntt2x2_fwdntt.cpp ntt2x2_invntt.cpp ntt2x2_mul.cpp consts_hw.cpp

.PHONY: all clean 

all: ntt2x2_test

ntt2x2_test: $(SOURCES) $(HEADERS) $(REF_HEADERS) $(REF_SOURCES) ntt2x2_test.cpp
	$(CC)  -o $@  $(REF_SOURCES) $(SOURCES) ntt2x2_test.cpp $(CFLAGS) 

clean:
	$(RM) ntt2x2_test

