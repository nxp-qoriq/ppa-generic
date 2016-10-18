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
#include "smc.h"

//-----------------------------------------------------------------------------

.global smc32_handler
.global _smc_success
.global _smc_unimplemented
.global _smc_invalid
.global _smc_invalid_el
.global _smc_completed

.global _init_smc_percpu
.global _save_smc_volatile
.global _restore_smc_volatile
.global _save_aarch32_nvolatile
.global _restore_aarch32_nvolatile
.global _get_aarch_flag

//-----------------------------------------------------------------------------

.equ SIP_REVISION_MAJOR, 0x1
.equ SIP_REVISION_MINOR, 0x0

.equ SIP_ROMUUID_PART1,  0x39080483    // bytes [3:0]
.equ SIP_ROMUUID_PART2,  0xADA93B0E    // bytes [7:4]
.equ SIP_ROMUUID_PART3,  0x1A7841A7    // bytes [11:8]
.equ SIP_ROMUUID_PART4,  0xD3205C97    // bytes [15:12]

.equ SIP32_FUNCTION_COUNT, 0x3

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

     // if we are here then we have an unimplemented/unrecognized function
    b    _smc_unimplemented

     //------------------------------------------

 // this function returns the number of smc32 SIP functions implemented
 // the count includes *this* function
smc32_sip_count:
    mov  x0, #SIP32_FUNCTION_COUNT
    b    _smc_completed

     //------------------------------------------

 // this function returns the SIP UUID for the secure monitor
 // resident in the bootrom
smc32_sip_UUID:
    ldr  x0, =SIP_ROMUUID_PART1
    ldr  x1, =SIP_ROMUUID_PART2
    ldr  x2, =SIP_ROMUUID_PART3
    ldr  x3, =SIP_ROMUUID_PART4
    b    _smc_completed

     //------------------------------------------

 // this function returns the major and minor revision numbers
 // of this secure monitor
smc32_sip_REVISION:
    ldr  x0, =SIP_REVISION_MAJOR
    ldr  x1, =SIP_REVISION_MINOR
    b    _smc_completed

     //------------------------------------------

smc32_no_services:
     // w11 contains the requested function id
     // w10 contains the call count function id
    mov   w10, #0xFF00
    cmp   w10, w11
    b.ne  _smc_unimplemented
     // call count is zero
    mov   w0, #0
     // b     smc32_func_completed
     // Note: fall-thru condition, if you insert code after this line,
     //       then uncomment the branch above

_smc_success:
    mov   x0, #SMC_SUCCESS
    b     _smc_completed
    
_smc_unimplemented:
    mov   x0, #SMC_UNIMPLEMENTED
    mov   x1, #0
    mov   x2, #0
    mov   x3, #0
    mov   x4, #0
    b     _smc_completed
    
_smc_invalid:
    mov   x0, #SMC_INVALID
    mov   x1, #0
    mov   x2, #0
    mov   x3, #0
    mov   x4, #0
    b     _smc_completed
    
_smc_invalid_el:
    mov   x0, #SMC_INVALID_EL
    mov   x1, #0
    mov   x2, #0
    mov   x3, #0
    mov   x4, #0
    b     _smc_completed

_smc_completed:
     // zero-out the scratch registers
    mov  x5,  #0
    mov  x6,  #0
    mov  x7,  #0
    mov  x8,  #0
    mov  x9,  #0
    mov  x10, #0
    mov  x11, #0
    mov  x12, #0
     // return from exception
    eret

     //------------------------------------------

__dead_loop:
    wfe
    b __dead_loop

//-----------------------------------------------------------------------------

 // this function initializes the per-core smc data area, and sets SP_EL3 to
 // point to the start of this area
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1
_init_smc_percpu:

     // x0 = core mask

     // generate a 0-based core number from the input mask
    clz   x1, x0
    mov   x0, #63
    sub   x0, x0, x1

     // x0 = core number (0-based)

     // calculate the offset to the start of the core data area
    mov   x1, #SMC_DATA_OFFSET
    mul   x1, x1, x0

     // x1 = offset to start of core data area

     // get the base address of the data areas
    adr   x0, _smc0_data

     // add offset to this core's data area
    add   x1, x1, x0

     // set the stack pointer
    mov  sp, x1

     // initialize the data area
    str   xzr, [sp, #0x0]
    str   xzr, [sp, #0x8]
    str   xzr, [sp, #0x10]
    str   xzr, [sp, #0x18]
    str   xzr, [sp, #0x20]
    str   xzr, [sp, #0x28]
    str   xzr, [sp, #0x30]
    str   xzr, [sp, #0x38]
    str   xzr, [sp, #0x40]
    str   xzr, [sp, #0x48]
    str   xzr, [sp, #0x50]
    str   xzr, [sp, #0x58]
    str   xzr, [sp, #0x60]
    str   xzr, [sp, #0x68]
    str   xzr, [sp, #0x70]
    str   xzr, [sp, #0x78]

    ret

//-----------------------------------------------------------------------------

 // this function saves registers (0-3) for the smc32/64 interface
 // Note: this function is not valid until _init_smc_percpu() has been run
 //       on this core
 // in:  none
 // out: none
 // uses none
_save_smc_volatile:

     // save registers
    str   x0,  [sp, #0x8]
    str   x1,  [sp, #0x10]
    str   x2,  [sp, #0x18]
    str   x3,  [sp, #0x20]
    dsb   sy
    isb

    ret

//-----------------------------------------------------------------------------

 // this function restores registers (0-3) for the smc32/64 interface
 // Note: this function is not valid until _init_smc_percpu() has been run
 //       on this core
 // in:  none
 // out: none
 // uses none
_restore_smc_volatile:

     // restore registers
    ldr   x0,  [sp, #0x8]
    ldr   x1,  [sp, #0x10]
    ldr   x2,  [sp, #0x18]
    ldr   x3,  [sp, #0x20]
    dsb   sy
    isb

    ret

//-----------------------------------------------------------------------------

 // this function saves the registers for the Aarch32 interface
 // Note: this function is not valid until _init_smc_percpu() has been run
 //       on this core
 // in:  none
 // out: none
 // uses x5
_save_aarch32_nvolatile:

     // save registers
    str   x0,  [sp, #0x8]
    str   x1,  [sp, #0x10]
    str   x2,  [sp, #0x18]
    str   x3,  [sp, #0x20]
    str   x4,  [sp, #0x28]
    str   x5,  [sp, #0x30]
    str   x6,  [sp, #0x38]
    str   x7,  [sp, #0x40]
    str   x8,  [sp, #0x48]
    str   x9,  [sp, #0x50]
    str   x10, [sp, #0x58]
    str   x11, [sp, #0x60]
    str   x12, [sp, #0x68]
    str   x13, [sp, #0x70]
    str   x14, [sp, #0x78]

     // set the aarch32 flag
    mov   x5, #SMC_AARCH32_MODE
    str   x5,  [sp, #0x0]

    dsb  sy
    isb
    ret

//-----------------------------------------------------------------------------

 // this function restores the non-volatile registers for the Aarch32 interface
 // Note: this function is not valid until _init_smc_percpu() has been run
 //       on this core
 // in:  none
 // out: none
 // uses x0, x1, x4
_restore_aarch32_nvolatile:

     // clear the aarch32 flag
    str   xzr,  [sp, #0x0]

     // restore the non-volatile registers
    ldr   x4,  [sp, #0x28]
    ldr   x5,  [sp, #0x30]
    ldr   x6,  [sp, #0x38]
    ldr   x7,  [sp, #0x40]
    ldr   x8,  [sp, #0x48]
    ldr   x9,  [sp, #0x50]
    ldr   x10, [sp, #0x58]
    ldr   x11, [sp, #0x60]
    ldr   x12, [sp, #0x68]
    ldr   x13, [sp, #0x70]
    ldr   x14, [sp, #0x78]

     // clear the data area
    str   xzr, [sp, #0x28]
    str   xzr, [sp, #0x30]
    str   xzr, [sp, #0x38]
    str   xzr, [sp, #0x40]
    str   xzr, [sp, #0x48]
    str   xzr, [sp, #0x50]
    str   xzr, [sp, #0x58]
    str   xzr, [sp, #0x60]
    str   xzr, [sp, #0x68]
    str   xzr, [sp, #0x70]
    str   xzr, [sp, #0x78]

    dsb  sy
    isb
    ret

//-----------------------------------------------------------------------------

 // this function returns the execution state the smc was called from
 // in:  none
 // out: x0 = SMC_AARCH32_MODE or SMC_AARCH64_MODE
 // uses x0,
_get_aarch_flag:

    ldr  x0, [sp, #0x0]

    ret

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

 // include the data areas
#include "smc_data.h"

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------


