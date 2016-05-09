// 
// ARM v8 AArch64 Bootrom 
//
// Copyright (c) 2013-2016, Freescale Semiconductor, Inc. All rights reserved.
//

// This romcode includes:
// (1) EL3 secure monitor - SMC64 interface

//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"

//-----------------------------------------------------------------------------

  .global smc64_handler

//-----------------------------------------------------------------------------

smc64_handler:
     // secure monitor smc64 interface lives here
     // Note: this secure monitor only implements "fast calls", thus
     //       interrupts are disabled during execution of the call

     // per the ARM SMC Calling convention:
     // x0     = function id 
     // x1-x5  = function parameters 
     // x6     = session id (optional) 
     // x7     = hypervisor client id
     // x8     = indirect result location register
     // x9-x15 = volatile/scratch

     // mask interrupts
    msr  DAIFset, #0xF

     // invalidate tlb
    tlbi alle3
    dsb  sy
    isb

     // extract bits 31:24 to see what class of function this is
    mov   x9, xzr
    bfxil x9, x0, #24, #8
     // extract bits 15:0 (the function number)
    mov   x11, xzr
    bfxil x11, x0, #0, #16

     // Note: x11 contains the function number

     // is it SMC64: ARM Architecture Call?
    cmp  x9, #0xC0
    b.eq smc64_no_services
     // is it SMC64: CPU Service Call?
    cmp  x9, #0xC1
    b.eq smc64_no_services
     // is it SMC64: SiP Service Call?
    cmp  x9, #0xC2
    b.eq smc64_sip_svc
     // is it SMC64: OEM Service Call?
    cmp  x9, #0xC3
    b.eq smc64_no_services
     // is it SMC64: Std Service Call?
    cmp  x9, #0xC4
    b.eq _smc64_std_svc
     // is it SMC64: Trusted App Call?
    cmp  x9, #0xF0
    b.eq smc_func_unimplemented
     // is it SMC64: Trusted App Call?
    cmp  x9, #0xF1
    b.eq smc_func_unimplemented
     // is it SMC64: Trusted OS Call? (multiple ranges)
    lsr  x10, x9, #4
    cmp  x10, #0xF
    b.eq smc64_no_services

     // if we are here then we have an unimplemented/unrecognized function
    b smc_func_unimplemented

     //------------------------------------------

     // Note: x11 contains the function number

smc64_sip_svc:
     // SIP64 service call COUNT function is 0xFF00
    mov  w10, #0xFF00
    cmp  w10, w11
    b.eq smc64_sip_count

    b    smc_func_unimplemented 

     //------------------------------------------

 // this function returns the number of smc64 SIP functions implemented
 // the count includes *this* function
smc64_sip_count:
    adr  x4, SIP64_FUNCTION_COUNT
    ldr  x0, [x4]
    mov  x4,  #0
    b    smc64_func_completed

     //------------------------------------------

smc64_no_services:
     // w11 contains the requested function id
     // w10 contains the call count function id
    mov   w10, #0xFF00
    cmp   w10, w11
    b.ne  smc_func_unimplemented
     // call count is zero
    mov   w0, #0
     // b     smc64_func_completed
     // Note: fall-thru condition, if you insert code after this line,
     //       then uncomment the branch above

smc64_func_completed:
     // zero-out the scratch registers
    mov  x6,  #0
    mov  x7,  #0
    mov  x8,  #0
    mov  x9,  #0
    mov  x10, #0
    mov  x11, #0
     // return from exception
    eret

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

 // return values
SIP64_SUCCESS:
    .long 0x0           // 0

 // for error codes used in both smc32 & smc64 sip calls, see secmon32.s

 // error codes used in smc64 calls
SIP64_INVALID_EL:
    .long 0xFFFFFFFE    // -2

SIP64_FUNCTION_COUNT:
     // include A64 psci functions also
    .long 0x3

//-----------------------------------------------------------------------------

