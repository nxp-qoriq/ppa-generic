// 
// ARM v8 AArch64 Secure FW 
//
// Copyright (c) 2014, Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// (1) EL3 exception vectors (and perhaps handlers) for the LS2080 SoC

//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "smc.h"

//-----------------------------------------------------------------------------

  .global _el3_vector_base
  .global __el3_dead_loop
  .global _smc_exit
 
//-----------------------------------------------------------------------------

 // EL3 exception vectors

   // VBAR_ELn bits [10:0] are RES0
  .align 11
_el3_vector_base:

   // current EL using SP0 ----------------------

     // synchronous exceptions
    b    synch_handler

     // IRQ interrupts
  .align 7  //allocates space for each ISR
     // put the irq vector offset in x3
    mov  x11, #0x80
    b    __el3_dead_loop

     // FIQ interrupts
  .align 7
     // put the fiq vector offset in x3
    mov  x11, #0x100
    b    __el3_dead_loop

     // serror exceptions
  .align 7
     // put the serror vector offset in x3
    mov  x11, #0x180
    b    __el3_dead_loop

   // current EL using SPx ----------------------
  
     // synchronous exceptions
  .align 7
    b  synch_handler

     // IRQ interrupts
  .align 7
    mov  x11, #0x280
    b    __el3_dead_loop

     // FIQ interrupts
  .align 7
    b  synch_handler

     // serror exceptions
  .align 7
    mov  x11, #0x380
    b    __el3_dead_loop

   // lower EL using AArch64 --------------------

     // synchronous exceptions
  .align 7
    b  synch_handler

     // IRQ interrupts
  .align 7
    mov  x11, #0x480
    b    __el3_dead_loop

     // FIQ interrupts
  .align 7
    mov  x11, #0x500
    b    __el3_dead_loop

     // serror exceptions
  .align 7
    mov  x11, #0x580
    b    __el3_dead_loop

   // lower EL using AArch32 --------------------

     // synchronous exceptions
  .align 7
    b  synch_handler

     // IRQ interrupts
  .align 7
    mov  x11, #0x680
    b    __el3_dead_loop

     // FIQ interrupts
  .align 7
    mov  x11, #0x700
    b    __el3_dead_loop

     // serror exceptions
  .align 7
    mov  x11, #0x780
    b    __el3_dead_loop

     //------------------------------------------

  .align 2
synch_handler:
     // save the volatile registers
     //  save these as pairs of registers to maintain the
     //  required 16-byte alignment on the stack
    stp   x0, x1, [sp, #-16]!
    stp   x2, x3, [sp, #-16]!
    dsb   sy
    isb

     // read the ESR_EL3 register to get exception type
    mrs   x1, ESR_EL3
     // extract the exception type
    mov   x2, xzr
    bfxil w2, w1, #26, #6

     // test if this is a A64 SMC exception
    cmp   w2, #0x17
    b.eq  a64smc_router

     // test if this is a A32 SMC exception
    cmp   w2, #0x13
    b.eq  a32smc_router

     // unhandled exception
    b    __el3_dead_loop

     //------------------------------------------

a64smc_router:
     // mask interrupts
    msr  DAIFset, #0xF

     // isolate and test bit [31] - must be '1' for "fast-calls"
    lsr   x2, x0, #31
    cbz   x2, _smc_unimplemented

     // extract bits [23:16] - must be 0x00 for "fast-calls"
    mov   x1, xzr
    bfxil x1, x0, #16, #8
    cbnz  x1, _smc_unimplemented

     // restore the volatile registers
     //  access these as pairs of registers to maintain the
     //  required 16-byte alignment on the stack
    ldp  x2, x3, [sp], #16
    ldp  x0, x1, [sp], #16
    dsb   sy
    isb

     // set the aarch64 flag
    mov   x5, #SMC_AARCH64_MODE
    str   x5,  [sp, #-16]!

     // test for smc32 or smc64 interface
    mov   x9, xzr
    bfxil x9, x0, #30, #1
    cbz   x9, smc32_handler
    b     smc64_handler

     //------------------------------------------

a32smc_router:
     // isolate and test bit [31] - must be '1' for "fast-calls"
    lsr   w2, w0, #31
    cbz   w2, _smc_unimplemented

     // extract bits [23:16] - must be 0x00 for "fast-calls"
    mov   w1, wzr
    bfxil w1, w0, #16, #8
    cbnz  w1, _smc_unimplemented

     // test for smc32 or smc64 interface
    mov   w2, wzr
    bfxil w2, w0, #30, #1
    cbz   w2, 1f

     // smc64 interface is not valid for a32 clients
    b     _smc_unimplemented

1:   // smc32 interface called from aarch32
     // mask interrupts
    msr  DAIFset, #0xF

     // restore the volatile registers
     //  access these as pairs of registers to maintain the
     //  required 16-byte alignment on the stack
    ldp  x2, x3, [sp], #16
    ldp  x0, x1, [sp], #16

     // save the non-volatile aarch32 registers
     //  save these as pairs of registers to maintain the
     //  required 16-byte alignment on the stack
    stp  x4,  x5,  [sp, #-16]!
    stp  x6,  x7,  [sp, #-16]!
    stp  x8,  x9,  [sp, #-16]!
    stp  x10, x11, [sp, #-16]!
    stp  x12, x13, [sp, #-16]!
    stp  x14, x15, [sp, #-16]!
    stp  x16, x17, [sp, #-16]!
    stp  x18, x30, [sp, #-16]!

     // set the aarch32 flag
    mov   x5, #SMC_AARCH32_MODE
    str   x5,  [sp, #-16]!

    dsb  sy
    isb
    b    smc32_handler

     //------------------------------------------

__el3_dead_loop:
    wfe
    b __el3_dead_loop

//-----------------------------------------------------------------------------

_smc_exit:

     // x0 = status code

     // called from aarch32 or aarch64? - get the flag off the
     // stack
    ldr   x4,  [sp], #16
    cbnz  x4, 1f

     // called from aarch64 -----------

     // restore the LR
    mov  x30, x12

     // zero-out the scratch registers
    ldr  x4,  =REGISTER_OBFUSCATE
    mvn  x5,  x4
    mov  x6,  x4
    mov  x7,  x5
    mov  x8,  x4
    mov  x9,  x5
    mov  x10, x4
    mov  x11, x5
    mov  x12, x4

    b    2f

1:   // called from aarch32 -----------

     // restore the aarch32 non-volatile registers
    ldp  x18, x30, [sp], #16
    ldp  x16, x17, [sp], #16
    ldp  x14, x15, [sp], #16
    ldp  x12, x13, [sp], #16
    ldp  x10, x11, [sp], #16
    ldp  x8,  x9,  [sp], #16
    ldp  x6,  x7,  [sp], #16
    ldp  x4,  x5,  [sp], #16
2:
    dsb  sy
    isb

     // return from exception
    eret

//-----------------------------------------------------------------------------


