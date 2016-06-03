// 
// ARM v8 AArch64 Bootrom 
//
// Copyright (c) 2014, 2016 Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// (1) EL3 exception vectors

//-----------------------------------------------------------------------------

  .section .text, "ax"

  .global _el3_vector_base
  .global __el3_dead_loop
 
//-----------------------------------------------------------------------------

 // EL3 exception vectors

   // VBAR_ELn bits [10:0] are RES0
  .align 11
_el3_vector_base:

   // current EL using SP0 ----------------------

     // synchronous exceptions
    mov  x11, #0x00 //x11 contains debugging codes
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
    mov  x11, #0x200
    b  synch_handler

     // IRQ interrupts
  .align 7
    mov  x11, #0x280
    b    __el3_dead_loop

     // FIQ interrupts
  .align 7
    mov  x11, #0x300
    b  synch_handler

     // serror exceptions
  .align 7
    mov  x11, #0x380
    b    __el3_dead_loop

   // lower EL using AArch64 --------------------

     // synchronous exceptions
  .align 7
    mov  x11, #0x400
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
    mov  x11, #0x600
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
     // read the ESR_EL3 register to get exception type
    mrs   x9, ESR_EL3
     // extract the exception type
    mov   x10, xzr
    bfxil w10, w9, #26, #6

     // test if this is a A64 SMC exception
    cmp   w10, #0x17
    b.eq  a64smc_router

     // test if this is a A32 SMC exception
    cmp   w10, #0x13
    b.eq  a32smc_router

     // unhandled exception
    b    __el3_dead_loop

     //------------------------------------------

a64smc_router:
     // isolate and test bit [31] - must be '1' for "fast-calls"
    lsr   x10, x0, #31
    cbz   x10, smc_func_unimplemented

     // extract bits [23:16] - must be 0x00 for "fast-calls"
    mov   x9, xzr
    bfxil x9, x0, #16, #8
    cbnz  x9, smc_func_unimplemented

     // test for smc32 or smc64 interface
    mov   x10, xzr
    bfxil x10, x0, #30, #1
    cbz   x10, smc32_handler
    b     smc64_handler

     //------------------------------------------

a32smc_router:
     // isolate and test bit [31] - must be '1' for "fast-calls"
    lsr   w10, w0, #31
    cbz   w10, smc_func_unimplemented

     // extract bits [23:16] - must be 0x00 for "fast-calls"
    mov   w9, wzr
    bfxil w9, w0, #16, #8
    cbnz  w9, smc_func_unimplemented

     // test for smc32 or smc64 interface
    mov   w10, wzr
    bfxil w10, w0, #30, #1
    cbz   w10, smc32_handler

     // smc64 interface is not valid for a32 clients
    b     smc_func_unimplemented

     //------------------------------------------

__el3_dead_loop:
    wfe
    b __el3_dead_loop

//-----------------------------------------------------------------------------

