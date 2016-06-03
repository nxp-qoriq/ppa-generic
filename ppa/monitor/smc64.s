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
.global _EL2_width
.global _EL2_endian

//-----------------------------------------------------------------------------

 // function classes
.equ  SMC64_ARM_ARCH,   0xC0
.equ  SMC64_CPU_SVC,    0xC1
.equ  SMC64_SIP_SVC,    0xC2
.equ  SMC64_OEM_SVC,    0xC3
.equ  SMC64_STD_SVC,    0xC4
.equ  SMC64_TRSTD_APP,  0xF0
.equ  SMC64_TRSTD_APP2, 0xF1

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
    b.eq smc64_no_services
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
    b.eq smc_func_unimplemented
     // is it SMC64: Trusted App Call?
    cmp  x9, #SMC64_TRSTD_APP2
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
    mov  w10, #SIP_COUNT_ID
    cmp  w10, w11
    b.eq smc64_sip_count

    mov  w10, #SIP_EL2_2_AARCH32_ID
    cmp  w10, w11
    b.eq smc64_sip_el2_2_aarch32

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

 // this function allows changing the execution width of EL2 to Aarch32
 // in:  x0 = start address for EL2 @ aarch32 execution
 //      x1 = 0, EL2 is LE
 //      x1 = 1, EL2 is BE
 // out: none
 // uses x0, x1, x2
smc64_sip_el2_2_aarch32:
    
     // set ELR_EL3 = x0
    msr  elr_el3, x0

     // set SCR_EL3.RW = Aarch32
    mrs  x2, scr_el3
    bic  x2, x2, #SCR_RW_MASK
    msr  scr_el3, x2

     // set SPSR_EL3
    ldr  x0, =SPSR32_DEFAULT
    cbz  x1, 1f
    orr  x0, x0, #SPSR32_E_MASK
1:
    msr  scr_el3, x3

     // set sctlr_el2.ee
    mrs  x2, sctlr_el2
    bic  x2, x2, #SCTLR_EE_MASK
    cbz  x1, 2f
    orr  x2, x2, #SCTLR_EE_MASK
2:
    msr  sctlr_el2, x2

     // set EL2 width data (mem area)
    adr  x0, _EL2_width
    mov  x2, #1
    str  x2, [x0]

     // set EL2 endian data (mem area)
    adr  x0, _EL2_endian
    mov  x2, x1
    cbz  x1, 3f
    mov  x2, #1
3:
    str  x2, [x0]

     // invalidate the icache
    ic iallu
    dsb sy
    isb

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
    mov  x1,  #0
    mov  x2,  #0
    mov  x3,  #0
    mov  x4,  #0
    mov  x5,  #0
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

.align 3
_EL2_width:
    .8byte  0x0  // 0 = EL2 @ Aarch64, 1 = EL2 @ Aarch32
 // Note: this field is valid only if EL2 = Aarch32
_EL2_endian:
    .8byte  0x0  // 0 = LE EL2, 1 = BE EL2

//-----------------------------------------------------------------------------

