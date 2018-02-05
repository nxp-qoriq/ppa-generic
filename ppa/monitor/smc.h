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
#define  SIP_PREFETCH       0xFF13

.equ SIP_PRNG_32BIT,  0
.equ SIP_PRNG_64BIT,  1
.equ SIP_RNG_32BIT,   0
.equ SIP_RNG_64BIT,   1

//-----------------------------------------------------------------------------

 // this macro isolates EL3 so that there are fewer visible artifacts
 // between execution levels for speculative execution side channels
.macro EL3_IsolateOnEntry
#if ((CORE == 72) || (CORE == 57))
     // temporarily save a couple of working registers
    stp   x0, x1, [sp, #-0x40]

     // disable and re-enable the mmu - this has the side effect
     // of invalidating BTB
    mrs   x0, sctlr_el3
    bic   x1, x0, #SCTLR_M_MASK
    msr   sctlr_el3, x1
    isb

     // re-enable the mmu
    msr   sctlr_el3, x0
    isb

     // disable branch prediction
    mrs  x0, CPUACTLR_EL1
     // disable static branch predictor
    orr  x0, x0, #CPUACTLR_DIS_SBP_MASK
     // disable branch target buffer
    orr  x0, x0, #CPUACTLR_DIS_BTB_MASK
     // disable indirect predictor
    orr  x0, x0, #CPUACTLR_DIS_INP_MASK
    msr  CPUACTLR_EL1, x0
    isb

     // save the ttbr0_el2 and vbar_el2
    mrs  x0, vbar_el2
    mrs  x1, ttbr0_el2
    stp  x0, x1, [sp, #-16]!
     //load dummy values
    msr  vbar_el2, xzr
    msr  ttbr0_el2, xzr

     // save the ttbr0_el1 and vbar_el1
    mrs  x0, vbar_el1
    mrs  x1, ttbr0_el1
    stp  x0, x1, [sp, #-16]!
     //load dummy values
    msr  vbar_el1, xzr
    msr  ttbr0_el1, xzr

     // save the ttbr1_el1 and vttbr_el2
    mrs  x0, vttbr_el2
    mrs  x1, ttbr1_el1
    stp  x0, x1, [sp, #-16]!
     //load dummy values
    msr  vttbr_el2, xzr
    msr  ttbr1_el1, xzr

     // restore the temp working regs
    ldp  x0, x1, [sp, #-16]
#endif
.endm

//-----------------------------------------------------------------------------

 // this macro performs any necessary unwinding of the EL3 isolation performed
 // above before we return to a lower exception level
 // Note: this macro must be the last thing invoked before the eret instruction
.macro EL3_ExitToNS
#if ((CORE == 72) || (CORE == 57))
     // temporarily save a couple of working registers
    stp   x0, x1, [sp, #-0x10]

     // get the saved values for vttbr_el2, ttbr1_el1
    ldp  x0, x1, [sp], #16
     // restore vttbr_el2, ttbr1_el1
    msr  vttbr_el2,  x0
    msr  ttbr1_el1, x1

     // get the saved values for vbar_el1, ttbr0_el1
    ldp  x0, x1, [sp], #16
     // restore vbar_el1, ttbr0_el1
    msr  vbar_el1,  x0
    msr  ttbr0_el1, x1

     // get the saved values for vbar_el2, ttbr0_el2
    ldp  x0, x1, [sp], #16
     // restore vbar_el2, ttbr0_el2
    msr  vbar_el2,  x0
    msr  ttbr0_el2, x1

     // re-enable branch prediction
    mrs  x0, CPUACTLR_EL1
     // enable static branch predictor
    bic  x0, x0, #CPUACTLR_DIS_SBP_MASK
     // enable branch target buffer
    bic  x0, x0, #CPUACTLR_DIS_BTB_MASK
     // enable indirect predictor
    bic  x0, x0, #CPUACTLR_DIS_INP_MASK
    msr  CPUACTLR_EL1, x0

     // restore the temp work registers
    ldp  x0, x1, [sp, #-0x40]
#endif
     // invalidate any el3 page translations
    tlbi alle3
.endm

//-----------------------------------------------------------------------------

 // this macro re-enables branch prediction when going from EL3 to secure EL1
 // via the SPD interface
.macro EL3_ExitToSPD
#if ((CORE == 72) || (CORE == 57))
     // reenable branch prediction
    mrs  x0, CPUACTLR_EL1
     // enable static branch predictor
    bic  x0, x0, #CPUACTLR_DIS_SBP_MASK
     // enable branch target buffer
    bic  x0, x0, #CPUACTLR_DIS_BTB_MASK
     // enable indirect predictor
    bic  x0, x0, #CPUACTLR_DIS_INP_MASK
    msr  CPUACTLR_EL1, x0
#endif
     // invalidate any el3 page translations
    tlbi alle3
.endm

//-----------------------------------------------------------------------------

 // this macro adjusts the isolation between exception levels as we return from
 // the SPD to a lower exception level on the non-secure side of the machine
 // Note: this macro must be the last thing invoked before the eret instruction
.macro SPD_ExitToNS
#if ((CORE == 72) || (CORE == 57))
     // temporarily save a couple of working registers
    stp   x0, x1, [sp, #-0x10]

     // get the saved values for vttbr_el2, ttbr1_el1
    ldp  x0, x1, [sp], #16
     // restore vttbr_el2, ttbr1_el1
    msr  vttbr_el2,  x0
    msr  ttbr1_el1, x1

     // get the saved values for vbar_el1, ttbr0_el1
    ldp  x0, x1, [sp], #16
     // restore vbar_el1, ttbr0_el1
    msr  vbar_el1,  x0
    msr  ttbr0_el1, x1

     // get the saved values for vbar_el2, ttbr0_el2
    ldp  x0, x1, [sp], #16
     // restore vbar_el2, ttbr0_el2
    msr  vbar_el2,  x0
    msr  ttbr0_el2, x1

     // restore the temp work registers
    ldp  x0, x1, [sp, #-0x40]
#endif
     // invalidate any el3 page translations
    tlbi alle3
.endm

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

 // this is the 64-bit interface to the LOAD-STORE PREFETCH DISABLE function
 // in:  x0 = function id
 //      x1 = core mask for cores to have prefetch disabled,
 //           where bit[0] = core0, bit[1] = core1, etc - if bit is set,
 //           then prefetch (CPUACTLR[56]) is disabled for that core.
 // out: none
#define  SIP_PREFETCH_DISABLE_64 0xC200FF13

//-----------------------------------------------------------------------------

#endif // _SMC_H
