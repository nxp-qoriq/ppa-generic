// 
// ARM v8 AArch64 Secure Monitor
//
// Copyright (c) 2015-2016, Freescale Semiconductor, Inc. All rights reserved.
//

// This code includes:
// (1) platform EL3 initialization

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "soc.h"
#include "soc.mac"
#include "aarch64.h"
#include "psci.h"
#include "policy.h"

//-----------------------------------------------------------------------------

.global _secondary_core_init
.global _cpu_off_exit
.global _start_monitor_el3
.global _mon_core_restart

//-----------------------------------------------------------------------------

.align 16
_start_monitor_el3:
     // save the LR
    mov   x12, x30

     // clean/invalidate the dcache
    mov x0, #1
    bl  _cln_inv_all_dcache

     // invalidate the icache
    ic  iallu
    isb

     // invalidate tlb
    tlbi  alle3
    dsb   sy
    isb

     // configure the c-runtime
    bl set_runtime_env

     // initialize the psci data structures
    bl   _initialize_psci

// save the link register to a data area here

    bl  _ppa_main

     // setup the EL3 vectors
    bl   _set_EL3_vectors

     // start initializing the soc
    bl   _soc_init_start

     // perform EL3 init on the core
    bl   _init_core_EL3

     // determine if hw supports el2
    bl   _is_EL2_supported

     // x0 = EL2 support (0=none)
    cbz  x0, 1f
     // perform basic EL2 init on the core
    bl   _init_core_EL2
    b    2f
1:
     // perform basic EL1 init on the core
    bl   _init_core_EL1
2:
     // setup the interconnect
    bl   _init_interconnect
 
     // initialize the Platform Security Policy here
    bl   _set_platform_security  

     // configure GIC
    bl   _gic_init_common
    bl   _gic_init_percpu

     // setup i2c and initialize ddr
    bl   _init_i2c 
    bl   _init_ddr

     // exit the monitor
    b   monitor_exit_EL3

//-----------------------------------------------------------------------------

 // this function performs the EL3 setup on the secondary cores
_secondary_core_init:
     // save the LR
    mov   x12, x30

     // configure c-runtime support for this core
    bl set_runtime_env

     // setup the EL3 vectors
    bl  _set_EL3_vectors

     // perform EL3 init on secondary core
    bl  _init_core_EL3

     // determine if hw supports el2
    bl   _is_EL2_supported

     // x0 = EL2 support (0=none)
    cbz  x0, 1f
     // perform EL2 init on secondary core
    bl  _init_core_EL2
    b   2f
1:
     // perform EL1 init on secondary core
    bl  _init_core_EL1
2:
     // set CNTVOFF to 0
    msr cntvoff_el2, xzr

     // perform any secondary-core platform security setup here
     //   configure secure mmu
     //   configure gic
    bl   _gic_init_percpu

     // exit the EL3 area
    b    _secondary_core_exit

//-----------------------------------------------------------------------------

 // this function branches to the start address, changing
 // execution level from EL3 to EL2 in the process
 // in:   none
 // uses: x0, x1, x2
monitor_exit_EL3:

     // make sure that the soc initialization tasks completed
    bl   _soc_init_finish

#if (TEST)
     // set the exit address to be our test code entry point
    adr  x0, _test_psci
    bl   _soc_set_start_addr
#endif

     // determine start address of bootloader
    bl  _soc_get_start_addr

     // x0 = start address
    
     // set ELR_EL3
    msr  elr_el3, x0

     // set the spsr value for exit
    bl   _set_spsr_4_exit

     // x0 = CORE_EL2 or CORE_EL1

     // set endianness for next level
    bl   _set_endian_4_exit

     // flush dcache
    mov x0, #1
    bl  _cln_inv_all_dcache

     // invalidate the icache
    ic  iallu
    isb

     // invalidate tlb
    tlbi alle3
    dsb  sy
    isb

     // disable dcache and mmu
    mrs  x2, sctlr_el3
    bic  x2, x2, #SCTLR_M_MASK
    bic  x2, x2, #SCTLR_C_MASK
    msr  sctlr_el3, x2
    isb

     // restore the LR
    mov  x30, x12

     // cleanup
    mov  x0,   #0
    mov  x1,   #0
    mov  x2,   #0
    mov  x3,   #0
    mov  x4,   #0
    mov  x5,   #0
    mov  x6,   #0
    mov  x7,   #0
    mov  x8,   #0
    mov  x9,   #0
    mov  x10,  #0
    mov  x11,  #0
    mov  x12,  #0

     // switch to the specified exception level
    clrex
    isb
    eret

//-----------------------------------------------------------------------------

 // this function exits the secondary core from EL3
_secondary_core_exit:

     // get this cores bit mask
    bl   _get_current_mask
    mov  x4, x0

     // get the start addr and load in ELR_EL3
    getCoreData x0 START_ADDR_DATA
    msr  elr_el3, x0

     // x4 = core_mask_lsb

     // set the core state to released
    mov  x0, x4
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA

     // x4 = core_mask_lsb

     // set the spsr value for exit
    bl   _set_spsr_4_exit
    mov  x6, x0

     // set the target endianness

     // get the saved sctlr 
    mov  x0, x4
    getCoreData x0 SCTLR_DATA

     // x0 = saved sctlr
     // x4 = core mask lsb
     // x6 = target EL-level

    cmp  x6, #CORE_EL2
    b.ne 1f
     // insert saved endianness to sctlr_el2
    bl   _insert_endian_el2
    b    2f
1:
     // insert saved endianness to sctlr_el1
    bl   _insert_endian_el1
2:
     // x4 = core_mask_lsb

     // get the context id into x0
    mov  x0, x4
    getCoreData x0 CNTXT_ID_DATA

     // invalidate the icache
    ic  iallu
    isb

     // invalidate tlb
    tlbi  alle3
    dsb   sy
    isb

     // exit EL3
    mov  x1,  #0
    mov  x2,  #0
    mov  x3,  #0
    mov  x4,  #0
    mov  x5,  #0
    mov  x6,  #0

     // restore the LR
    mov  x30, x12

     // clear the exclusive monitor
    clrex
    isb
    eret

//-----------------------------------------------------------------------------

 // this function finishes the init on a restarted core, and
 // exits it from the monitor
_mon_core_restart:

     // get this cores bit mask
    bl   _get_current_mask
    mov  x4, x0

     // get the start addr and load in ELR_EL3
    getCoreData x0 START_ADDR_DATA
    msr  elr_el3, x0

     // x4 = core mask (lsb)

     // set the core state to released
    mov  x0, x4
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA

     // set the spsr value for exit
    bl   _set_spsr_4_exit
    mov  x6, x0

     // x4 = core mask (lsb)

     // restore the link register
    mov  x0, x4
    getCoreData x0 LINK_REG_DATA
    mov  x12, x0

     // x4 = core mask (lsb)

     // get the context id into x0
    mov  x0, x4
    getCoreData x0 CNTXT_ID_DATA

     // invalidate icache
    ic iallu
    isb

     // exit EL3
    mov  x1,  #0
    mov  x2,  #0
    mov  x3,  #0
    mov  x4,  #0
    mov  x5,  #0
    mov  x6,  #0

     // restore the LR
    mov  x30, x12

    clrex
    isb
    eret

//-----------------------------------------------------------------------------

 // this function sets up c runtime env
set_runtime_env:

     // BSS Section need not be zeroized - linker Will padd with zero

     // set Core Stack - SPSel - EL3
    mov x0, #1
    msr spsel, x0
    m_get_cur_stack_top x0, x1, x2
    mov sp, x0

    ret

//-----------------------------------------------------------------------------

PPA_VERSION:
    .4byte  0x00040000

//-----------------------------------------------------------------------------

