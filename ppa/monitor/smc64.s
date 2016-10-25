// 
// ARM v8 AArch64 Secure FW
//
// Copyright (c) 2013-2016, Freescale Semiconductor, Inc. All rights reserved.
//

// This code includes:
// (1) EL3 secure monitor - SMC64 interface

//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"
#include "smc.h"

//-----------------------------------------------------------------------------

.global smc64_handler
.global _initialize_smc
.global _getEL2Width

//-----------------------------------------------------------------------------

 // function classes
.equ  SMC64_ARM_ARCH,   0xC0
.equ  SMC64_CPU_SVC,    0xC1
.equ  SMC64_SIP_SVC,    0xC2
.equ  SMC64_OEM_SVC,    0xC3
.equ  SMC64_STD_SVC,    0xC4
.equ  SMC64_TRSTD_APP,  0xF0
.equ  SMC64_TRSTD_APP2, 0xF1

.equ  SIP64_FUNCTION_COUNT,  0x3
.equ  ARCH64_FUNCTION_COUNT, 0x2

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
    cmp  x9, #SMC64_ARM_ARCH
    b.eq smc64_arch_svc
     // is it SMC64: CPU Service Call?
    cmp  x9, #SMC64_CPU_SVC
    b.eq smc64_no_services
     // is it SMC64: SiP Service Call?
    cmp  x9, #SMC64_SIP_SVC
    b.eq smc64_sip_svc
     // is it SMC64: OEM Service Call?
    cmp  x9, #SMC64_OEM_SVC
    b.eq smc64_no_services
     // is it SMC64: Std Service Call?
    cmp  x9, #SMC64_STD_SVC
    b.eq _smc64_std_svc
     // is it SMC64: Trusted App Call?
    cmp  x9, #SMC64_TRSTD_APP
    b.eq _smc_unimplemented
     // is it SMC64: Trusted App Call?
    cmp  x9, #SMC64_TRSTD_APP2
    b.eq _smc_unimplemented
     // is it SMC64: Trusted OS Call? (multiple ranges)
    lsr  x10, x9, #4
    cmp  x10, #0xF
    b.eq smc64_no_services

     // if we are here then we have an unimplemented/unrecognized function
    b _smc_unimplemented

     //------------------------------------------

     // Note: x11 contains the function number

smc64_arch_svc:
         // ARCH64 service call COUNT function is 0xFF00
    ldr  x10, =ARCH_COUNT_ID
    and  w10, w10, #SMC_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_arch_count

    ldr  x10, =ARCH_EL2_2_AARCH32_ID
    and  w10, w10, #SMC_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_arch_el2_2_aarch32

    b    _smc_unimplemented 

     //------------------------------------------

     // Note: x11 contains the function number

smc64_sip_svc:
     // SIP64 service call COUNT function is 0xFF00
    ldr  x10, =SIP_COUNT_ID
    and  w10, w10, #SMC_FUNCTION_MASK
    cmp  w10, w11
    b.eq smc64_sip_count

    b    _smc_unimplemented 

     //------------------------------------------

 // this function returns the number of smc64 SIP functions implemented
 // the count includes *this* function
smc64_sip_count:
    mov  x0, #SIP64_FUNCTION_COUNT
    mov  x4,  #0
    mov  x3,  #0
    mov  x2,  #0
    mov  x1,  #0
    b    _smc_success

     //------------------------------------------

 // this function returns the number of smc64 SIP functions implemented
 // the count includes *this* function
smc64_arch_count:
    mov  x0, #ARCH64_FUNCTION_COUNT
    mov  x4,  #0
    mov  x3,  #0
    mov  x2,  #0
    mov  x1,  #0
    b    _smc_success

     //------------------------------------------

 // this function allows changing the execution width of EL2 from Aarch64
 // to Aarch32
 // Note: MUST be called from EL2 @ Aarch64
 // in:  x1 = start address for EL2 @ Aarch32
 //      x2 = first parameter to pass to EL2 @ Aarch32
 //      x3 = second parameter to pass to EL2 @ Aarch32
 // uses x0, x1, x2, x3, x12
smc64_arch_el2_2_aarch32:
    mov   x12, x30

     // x1 = start address
     // x2 = parm 1
     // x3 = parm2

     // check that we were called from EL2 @ Aarch64 - return "invalid" if not
    mrs  x0, spsr_el3
     // see if we were called from Aarch32
    tst  x0, #SPSR_EL3_M4
    b.ne _smc_invalid

     // see if we were called from EL2
    and   x0, x0, SPSR_EL_MASK
    cmp   x0, SPSR_EL2
    b.ne  _smc_invalid_el

     // set ELR_EL3
    msr  elr_el3, x1

     // set scr_el3
    mov  x0, #SCR_EL3_4_EL2_AARCH32
    msr  scr_el3, x0

     // set sctlr_el2
    ldr   x1, =SCTLR_EL2_RES1
    msr  sctlr_el2, x1

     // set spsr_el3
    ldr  x0, =SPSR32_EL2_LE
    msr  spsr_el3, x0

     // x2 = parm 1
     // x3 = parm2

     // set the parameters to be passed-thru to EL2 @ Aarch32
    mov  x1, x2
    mov  x2, x3

     // x1 = parm 1
     // x2 = parm2

     // invalidate the icache
    ic iallu
    dsb sy
    isb

     // finish
    mov  x30, x12
    b    _smc_success

     //------------------------------------------

smc64_no_services:
     // w11 contains the requested function id
     // w10 contains the call count function id
    mov   w10, #0xFF00
    cmp   w10, w11
    b.ne  _smc_unimplemented
     // call count is zero
    mov   w0, #0
    b     _smc_completed

//-----------------------------------------------------------------------------

 // this function initializes any smc data
 // in:  none
 // out: none
 // uses 
_initialize_smc:

    ret

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

