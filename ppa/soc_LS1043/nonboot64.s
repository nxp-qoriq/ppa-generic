// 
// ARM v8 AArch64 Bootrom 
//
// Copyright (c) 2013-2014, Freescale Semiconductor, Inc. All rights reserved.
//

// This romcode includes:
// (1) EL3 code for non-boot cores

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "soc.h"

//-----------------------------------------------------------------------------

.global non_boot_core
 
//-----------------------------------------------------------------------------

non_boot_core:
     // read mp affinity reg (MPIDR_EL1)
    mrs x4, MPIDR_EL1
     // see if this core needs to be disabled
    mov   x0, x4
    bl    _get_core_mask_lsb
    mov   w3, w0
     // read COREDISR
    mov   w0, #0x94     
    bl    read_reg_dcfg
    tst   w0, w3
    b.ne  core_disable

     // x4 = mpidr_el1

     // see if this core has been released
     // read COREBCR and check if this core's bit has been cleared
    mov   x0, x4
    bl    get_core_mask_msb
    mov   w3, w0

1:
    mov   w0, #0x680
    bl    read_reg_scfg
    tst   w0, w3
    b.eq  2f        // core is released

     // core is not released, so enter wfe
    wfe
    b     1b
    
2:
     // perform the EL3 init
    bl    initialize_EL3

     // determine start address
    bl    get_exec_addr
    
     // branch to the start address
    br    x0

//-----------------------------------------------------------------------------

 // disable a core til the next reset
 // uses x0, x1, x2
core_disable:
     // turn off caches in SCTRL
    mrs  x1, SCTLR_EL3
    mov  x0, #0x1004
    bic  x1, x1, x0
    msr  SCTLR_EL3, x1

     // clean & inv L1 dcache
    bl  _flush_L1_dcache 

     // clear SMP and set retention control in CPUECTLR
    mov  x1, #0x2
    msr  S3_1_c15_c2_1, x1

     // disable interrupts in DAIF
    mov  x0, 0x3c0
    msr  daif, x0

     // set OSDLR_EL1.DK
    mov  x1, #1
    msr  osdlr_el1, x1

     // enable the generic timer counter
    //adr  x2, ADDR_TIMER_BASE
    //ldr  w0, [x2]
    //mov  w1, #1
    //str  w1, [x0, #0x0]

     // set the initial count value
    //mov  w1, #0x07000000
    //str  w1, [x0, #0x8]

     // enable the timer clocks
    //adr  x2, ADDR_PMU_BASE
    //ldr  w0, [x2]
    //mov  x1, 0xff
    //str  x1, [x0, #0x18a0]

     // disable the core - only reset brings the core back from this
    isb
    dsb  #0xF
disable_loop:
    wfi
    b  disable_loop



//-----------------------------------------------------------------------------

 // this function returns a 64-bit execution address of the core in x0
 // out: x0, start address
 // uses x0, x1, x2 
get_exec_addr:
     // get the 64-bit base address of the scfg block
    ldr  w1, =SCFG_BASE_ADDR

     // read the 32-bit BOOTLOCPTRL register (offset 0x604 in the scfg block)
    ldr  w0, [x1, #0x604]
     // swap bytes for BE
    rev  w2, w0

     // read the 32-bit BOOTLOCPTRH register (offset 0x600 in the scfg block)
    ldr  w0, [x1, #0x600]
    rev  w1, w0
     // create a 64-bit BOOTLOCPTR address
    orr  x0, x2, x1, LSL #32
    ret

//-----------------------------------------------------------------------------

