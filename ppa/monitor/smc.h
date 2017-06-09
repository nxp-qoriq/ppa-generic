//-----------------------------------------------------------------------------
// 
// Copyright (c) 2016, Freescale Semiconductor
// Copyright 2017 NXP Semiconductors
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Author Rod Dorris <rod.dorris@nxp.com>
// 
//-----------------------------------------------------------------------------

#ifndef _SMC_H
#define	_SMC_H

//-----------------------------------------------------------------------------

.equ REGISTER_OBFUSCATE, 0xA5A5A5A5A5A5A5A5

//-----------------------------------------------------------------------------

#define  SMC_EL2_IS_LE    0x0
#define  SMC_EL2_IS_BE    0x1

#define SMC_AARCH32_MODE  0x1
#define SMC_AARCH64_MODE  0x0

 // function return values
#define  SMC_SUCCESS         0
#define  SMC_UNIMPLEMENTED  -1
#define  SMC_INVALID        -2
#define  SMC_BAD_PARM       -3
#define  SMC_INVALID_EL     -4
#define  SMC_FAILURE        -5

#define  SIP_PRNG           0xFF10
#define  SIP_RNG            0xFF11
#define  SIP_MEMBANK        0xFF12

.equ SIP_PRNG_32BIT,  0
.equ SIP_PRNG_64BIT,  1
.equ SIP_RNG_32BIT,   0
.equ SIP_RNG_64BIT,   1

//-----------------------------------------------------------------------------

#define  SMC_FUNCTION_MASK  0xFFFF

 // smc function id's - these are "fast", non-preemptible functions

 // this function returns the number of implemented smc-sip functions
#define  SIP_COUNT_ID     0xC200FF00

 // this function returns the number of implemented smc-arch functions
#define  ARCH_COUNT_ID    0xC000FF00

 // this function will return to EL2 @ Aarch32
 // in:  x0 = function id
 //      x1 = start address for EL2 @ Aarch32
 //      x2 = first parameter to EL2
 //      x3 = second parameter to EL2
 //      x4 = 0, EL2 in LE (little-endian)
 //      x4 = 1, EL2 in BE (big-endian)
#define  ARCH_EL2_2_AARCH32_ID  0xC000FF04

 // this is the 32-bit interface to the PRNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit PRNG requested
 //      x1 = 1, 64-bit PRNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-bit PRNG, or hi-order 32-bits of 64-bit PRNG
 //      x2 = lo-order 32-bits of 64-bit PRNG
#define  SIP_PRNG_32 0x8200FF10

 // this is the 32-bit interface to the hw RNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit RNG requested
 //      x1 = 1, 64-bit RNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-bit PRNG, or hi-order 32-bits of 64-bit PRNG
 //      x2 = lo-order 32-bits of 64-bit PRNG
#define  SIP_RNG_32 0x8200FF11

 // this is the 64-bit interface to the PRNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit PRNG requested
 //      x1 = 1, 64-bit PRNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-or-64-bit PRNG
#define  SIP_PRNG_64 0xC200FF10

 // this is the 64-bit interface to the hw RNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit hw RNG requested
 //      x1 = 1, 64-bit hw RNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-or-64-bit PRNG
#define  SIP_RNG_64 0xC200FF11

 // this is the 64-bit interface to the MEMBANK function
 // in:  x0 = function id
 //      x1 = memory bank requested (1, 2, 3, etc)
 // out: x0     = -1, failure
 //             = -2, invalid parameter
 //      x0 [0] =  1, valid bank
 //             =  0, invalid bank
 //       [1:2] =  1, ddr  
 //             =  2, sram
 //             =  3, special
 //         [3] =  1, not the last bank
 //             =  0, last bank
 //      x1     =  physical start address (not valid unless x0[0]=1)
 //      x2     =  size in bytes (not valid unless x0[0]=1)
#define  SIP_MEMBANK_64 0xC200FF12

//-----------------------------------------------------------------------------

#endif // _SMC_H
