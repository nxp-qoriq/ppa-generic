// 
// ARM v8 AArch64 Bootrom 
//
// Copyright (c) 2013-2016, Freescale Semiconductor, Inc. All rights reserved.
// Copyright (c) 2017, NXP Semiconductors, Inc. All rights reserved.
//

// This romcode includes:
// (1) EL3 secure monitor - SMC32 interface

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"
#include "smc.h"

//-----------------------------------------------------------------------------

.global smc32_handler
.global _smc_success
.global _smc_unimplemented
.global _smc_invalid
.global _smc_invalid_el

//-----------------------------------------------------------------------------

.equ SIP_REVISION_MAJOR, 0x1
.equ SIP_REVISION_MINOR, 0x0

.equ SIP_ROMUUID_PART1,  0x39080483    // bytes [3:0]
.equ SIP_ROMUUID_PART2,  0xADA93B0E    // bytes [7:4]
.equ SIP_ROMUUID_PART3,  0x1A7841A7    // bytes [11:8]
.equ SIP_ROMUUID_PART4,  0xD3205C97    // bytes [15:12]

.equ SIP32_FUNCTION_COUNT, 0x5

//-----------------------------------------------------------------------------

smc32_handler:
     // secure monitor smc32 interface lives here
     // Note: this secure monitor only implements "fast calls", thus
     //       interrupts are disabled during execution of the call

     // per the ARM SMC Calling convention:
     // w0     = function id 
     // w1-w5  = function parameters 
     // w6     = session id (optional) 
     // w7     = hypervisor client id
     // w8     = indirect result location register
     // w9-w15 = volatile/scratch

     // mask interrupts
    msr  DAIFset, #0xF

     // invalidate tlb
    tlbi alle3
    dsb  sy
    isb

     // extract bits 31:24 to see what class of function this is
    mov   w9, wzr
    mov   w11, wzr
    bfxil w9, w0, #24, #8
     // extract bits 15:0 (the function number)
    bfxil w11, w0, #0, #16

     // Note: x11 contains the function number

     // is it SMC32: ARM Architecture Call?
    cmp  w9, #0x80
    b.eq smc32_no_services
     // is it SMC32: CPU Service Call?
    cmp  w9, #0x81
    b.eq smc32_no_services
     // is it SMC32: SiP Service Call?
    cmp  w9, #0x82
    b.eq smc32_sip_svc
     // is it SMC32: OEM Service Call?
    cmp  w9, #0x83
    b.eq smc32_no_services
     // is it SMC32: Std Service Call?
    cmp  w9, #0x84
    b.eq _smc32_std_svc
     // is it SMC32: Trusted App Call?
    cmp  w9, #0xB0
    b.eq _smc_unimplemented
     // is it SMC32: Trusted App Call?
    cmp  w9, #0xB1
    b.eq _smc_unimplemented
     // is it SMC32: Trusted OS Call? (multiple ranges)
    lsr  w10, w9, #4
    cmp  w10, #0xB
    b.eq smc32_no_services

     // if we are here then we have an unimplemented/unrecognized function
    b _smc_unimplemented

     //------------------------------------------

     // Note: w11 contains the function number

smc32_sip_svc:
     // SIP service call COUNT function is 0xFF00
    mov  w10, #0xFF00
    cmp  w10, w11
    b.eq smc32_sip_count

     // SIP service call UUID function is 0xFF01
    mov  w10, #0xFF01
    cmp  w10, w11
    b.eq smc32_sip_UUID

     // SIP service call function reserved 0xFF02

     // SIP service call REVISION function is 0xFF03
    mov  w10, #0xFF03
    cmp  w10, w11
    b.eq smc32_sip_REVISION

     // SIP service call PRNG_32
    mov  w10, #SIP_PRNG
    cmp  w10, w11
    b.eq smc32_sip_PRNG

     // SIP service call RNG_32
    mov  w10, #SIP_RNG
    cmp  w10, w11
    b.eq smc32_sip_RNG

     // if we are here then we have an unimplemented/unrecognized function
    b    _smc_unimplemented

     //------------------------------------------

 // this function returns the number of smc32 SIP functions implemented
 // the count includes *this* function
smc32_sip_count:
     // save link register
    mov  x12, x30

    mov  x0, #SIP32_FUNCTION_COUNT
    b    _smc_exit

     //------------------------------------------

 // this function returns the SIP UUID for the secure monitor
 // resident in the bootrom
smc32_sip_UUID:
     // save link register
    mov  x12, x30

    ldr  x0, =SIP_ROMUUID_PART1
    ldr  x1, =SIP_ROMUUID_PART2
    ldr  x2, =SIP_ROMUUID_PART3
    ldr  x3, =SIP_ROMUUID_PART4
    b    _smc_exit

     //------------------------------------------

 // this function returns the major and minor revision numbers
 // of this secure monitor
smc32_sip_REVISION:
     // save link register
    mov  x12, x30

    ldr  x0, =SIP_REVISION_MAJOR
    ldr  x1, =SIP_REVISION_MINOR
    b    _smc_exit

     //------------------------------------------

 // this is the 32-bit interface to the PRNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit PRNG requested
 //      x1 = 1, 64-bit PRNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-bit PRNG, or hi-order 32-bits of 64-bit PRNG
 //      x2 = lo-order 32-bits of 64-bit PRNG
smc32_sip_PRNG:
     // make sure bits 63:32 in the registers containing input parameters
     // are zeroed-out (input parameters are in x0-x1)
    lsl  x0, x0, #32
    lsl  x1, x1, #32
    lsr  x0, x0, #32
    lsr  x1, x1, #32
    mov  x12, x30

    cbz  x1, 1f
     // 64-bit PRNG
    mov  x0, #SIP_PRNG_64BIT
    bl   _get_PRNG
     // hi-order bits in w1
    and  x1, xzr, x0, lsr #32
     // lo-order bits in w2
    mov  w2, w0
    b    2f

1:   // 32-bit PRNG
    mov  x0, #SIP_PRNG_32BIT
    bl   _get_PRNG
     // result in w1
    mov  w1, w0

2:
    mov  x30, x12
    b    _smc_success

     //------------------------------------------

 // this is the 32-bit interface to the hw RNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit hw RNG requested
 //      x1 = 1, 64-bit hw RNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-bit RNG, or hi-order 32-bits of 64-bit RNG
 //      x2 = lo-order 32-bits of 64-bit RNG
smc32_sip_RNG:
     // make sure bits 63:32 in the registers containing input parameters
     // are zeroed-out (input parameters are in x0-x1)
    lsl  x0, x0, #32
    lsl  x1, x1, #32
    lsr  x0, x0, #32
    lsr  x1, x1, #32
    mov  x12, x30

    cbz  x1, 1f
     // 64-bit RNG
    mov  x0, #SIP_RNG_64BIT
//    bl   _get_RNG
     // hi-order bits in w1
    and  x1, xzr, x0, lsr #32
     // lo-order bits in w2
    mov  w2, w0
    b    2f

1:   // 32-bit RNG
    mov  x0, #SIP_RNG_32BIT
//    bl   _get_RNG
     // result in w1
    mov  w1, w0

2:
    mov  x30, x12
    b    _smc_success

     //------------------------------------------

smc32_no_services:
    mov   x12, x30
    b    _smc_unimplemented

_smc_failure:
    mov   x0, #SMC_FAILURE
    b     _smc_exit
    
_smc_success:
    mov   x0, #SMC_SUCCESS
    b     _smc_exit
    
_smc_invalid:
    mov   x0, #SMC_INVALID
    b     _smc_exit
    
_smc_invalid_el:
    mov   x0, #SMC_INVALID_EL
    b     _smc_exit

_smc_unimplemented:
    mov   x0, #SMC_UNIMPLEMENTED
    b     _smc_exit
    
     //------------------------------------------

__dead_loop:
    wfe
    b __dead_loop

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------


