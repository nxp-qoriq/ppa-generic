// 
// ARM v8 AArch64 Bootrom 
//
// Copyright (c) 2013-2016, Freescale Semiconductor, Inc. All rights reserved.
//

// This romcode includes:
// (1) EL3 secure monitor - SMC32 interface

//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"

//-----------------------------------------------------------------------------

  .global smc32_handler
  .global smc_func_unimplemented

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
    b.eq smc_func_unimplemented
     // is it SMC32: Trusted App Call?
    cmp  w9, #0xB1
    b.eq smc_func_unimplemented
     // is it SMC32: Trusted OS Call? (multiple ranges)
    lsr  w10, w9, #4
    cmp  w10, #0xB
    b.eq smc32_no_services

     // if we are here then we have an unimplemented/unrecognized function
    b smc_func_unimplemented

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

     // if we are here then we have an unimplemented/unrecognized function
    b    smc_func_unimplemented

     //------------------------------------------

 // this function returns the number of smc32 SIP functions implemented
 // the count includes *this* function
smc32_sip_count:
    adr  x4, SIP32_FUNCTION_COUNT
    ldr  w0, [x4]
    b    smc32_func_completed

     //------------------------------------------

 // this function returns the SIP UUID for the secure monitor
 // resident in the bootrom
smc32_sip_UUID:
     // save the LR
    mov  x12, x30
    adr  x4, SIP_ROMUUID_PART1
    ldr  w0, [x4]
    adr  x5, SIP_ROMUUID_PART2
    ldr  w1, [x5]
    adr  x6, SIP_ROMUUID_PART3
    ldr  w2, [x6]
    adr  x7, SIP_ROMUUID_PART4
    ldr  w3, [x7]
    b    smc32_func_completed

     //------------------------------------------

 // this function returns the major and minor revision numbers
 // of this secure monitor
smc32_sip_REVISION:
     // save the LR
    mov  x12, x30
    adr  x4, SIP_REVISION_MAJOR
    ldr  w0, [x4]
    adr  x4, SIP_REVISION_MINOR
    ldr  w1, [x4]
    b    smc32_func_completed

     //------------------------------------------

smc32_no_services:
     // w11 contains the requested function id
     // w10 contains the call count function id
    mov   w10, #0xFF00
    cmp   w10, w11
    b.ne  smc_func_unimplemented
     // call count is zero
    mov   w0, #0
     // b     smc32_func_completed
     // Note: fall-thru condition, if you insert code after this line,
     //       then uncomment the branch above

smc32_func_completed:
     // zero-out the scratch registers
    mov x7,  #0
    mov x8,  #0
    mov x9,  #0
    mov x10, #0
    mov x11, #0
     // return from exception
    eret

smc_func_unimplemented:
     // put the unimplemented result value 0xFFFFFFFF in w0
    adr  x11, SMC_FUNC_UNIMPLEMENTED
    ldr  w0, [x11]
    mov x9,  #0
    mov x10, #0
    mov x11, #0
     // return to the caller
    eret

     //------------------------------------------

__dead_loop:
    wfe
    b __dead_loop

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

 // return values, error codes used in smc32 sip calls
SIP32_SUCCESS:
    .long 0x0           // 0
SMC_FUNC_UNIMPLEMENTED:
    .long 0xFFFFFFFF    // -1

SIP_REVISION_MAJOR:
    .long 0x1
SIP_REVISION_MINOR:
    .long 0x0

SIP_ROMUUID_PART1:
    .long 0x39080483    // bytes [3:0]
SIP_ROMUUID_PART2:
    .long 0xada93b0e    // bytes [7:4]
SIP_ROMUUID_PART3:
    .long 0x1a7841a7    // bytes [11:8]
SIP_ROMUUID_PART4:
    .long 0xd3205c97    // bytes [15:12]

SIP32_FUNCTION_COUNT:
    .long 0x3

//-----------------------------------------------------------------------------

