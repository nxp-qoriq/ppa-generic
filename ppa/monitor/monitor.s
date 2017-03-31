//-----------------------------------------------------------------------------
// 
// Copyright (c) 2015-2016, Freescale Semiconductor
// Copyright 2017 NXP Semiconductors
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Author Rod Dorris <rod.dorris@nxp.com>
// 
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "soc.h"
#include "aarch64.h"
#include "psci.h"
#include "soc.mac"
#include "policy.h"
#include "smc.h"

//-----------------------------------------------------------------------------

.global _secondary_core_init
.global _cpu_off_exit
.global _start_monitor_el3
.global _mon_core_restart
.global _init_membank_data
#if (PSCI_TEST)
.global _populate_membank_data
#endif

//-----------------------------------------------------------------------------

.align 16
_start_monitor_el3:
     // save the LR
    mov   x12, x30

#if (!SIMULATOR_BUILD) && (DEBUG_BUILD)
debug_stop:
    b  debug_stop
#endif

     // clean/invalidate the dcache
    mov x0, #0
    bl  _cln_inv_all_dcache
#if (L3_VIA_CCN504)
    mov x0, #1
    bl  _manual_L3_flush
#endif

     // invalidate the icache
    ic  iallu
    isb

     // invalidate tlb
    tlbi  alle3
    dsb   sy
    isb

     // initialize the psci data structures
    bl   _initialize_psci

     // setup the EL3 vectors
    bl   _set_EL3_vectors

     // start initializing the soc
    bl   _soc_init_percpu
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
 
     // configure GIC
    bl   _gic_init_common
    bl   _get_current_mask
    mov  x8, x0
    bl   _gic_init_percpu

     // x8 = core mask

     // setup the stack
    mov  x0, x8
    bl   init_stack_percpu
    
    bl   _ppa_main

     // initialize the Platform Security Policy here
    bl   _set_platform_security  

     // exit the monitor
    b    monitor_exit_EL3

//-----------------------------------------------------------------------------

 // this function performs the EL3 setup on the secondary cores
_secondary_core_init:
     // save the LR
    mov   x12, x30

     // setup the EL3 vectors
    bl  _set_EL3_vectors

     // get this cores bit mask
    bl   _get_current_mask
    mov  x8, x0

     // x0 = core mask lsb
     // x8 = core mask lsb

     // perform EL3 init on secondary core
    bl   _init_secondary_EL3

     // determine if hw supports el2
    bl   _is_EL2_supported

     // x0 = EL2 support (0=none)
    cbz  x0, 1f
     // perform EL2 init on secondary core
    mov  x0, x8
    bl   _init_secondary_EL2
    b    2f
1:
     // perform EL1 init on secondary core
    mov  x0, x8
    bl   _init_secondary_EL1
2:
     // set CNTVOFF to 0
    msr  cntvoff_el2, xzr

     // soc-specific init on secondary core
    bl   _soc_init_percpu

     // since this is a secondary core function, we
     // must be finished boot - trigger the exit
     // boot services call
    bl   exit_boot_svcs

     // perform any secondary-core platform security setup here
     //   configure secure mmu
     //   configure gic
    mov  x0, x8
    bl   _gic_init_percpu

     // setup runtime stack
    mov  x0, x8
    bl   init_stack_percpu

     // exit the EL3 area
    b    _secondary_exit

//-----------------------------------------------------------------------------

 // this function branches to the start address, changing
 // execution level from EL3 to EL2 in the process
 // in:   none
 // uses: x0, x1, x2
monitor_exit_EL3:

     // make sure that the soc initialization tasks completed
    bl   _soc_init_finish

#if (PSCI_TEST)
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

     // flush dcache
    mov x0, #1
    bl  _cln_inv_all_dcache
#if (L3_VIA_CCN504)
    mov x0, #0
    bl  _manual_L3_flush
#endif

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

 // this is the exit from the monitor for secondary cores coming out of reset
_secondary_exit:

     // get this cores bit mask
    bl   _get_current_mask
    mov  x6, x0

     // x0 = core mask (lsb)
     // x6 = core mask (lsb)

     // get the start addr
    mov  x1, #START_ADDR_DATA
    bl   _getCoreData

     // x0 = start address
     // x6 = core mask (lsb)

     // load start addr in ELR_EL3
    msr  elr_el3, x0

     // set the core state to released
    mov  x0, x6
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_RELEASED
    bl   _setCoreData

     // x6 = core mask (lsb)

     // setup the spsr
    mov  x0, x6
    bl   _set_spsr_4_startup

     // x6 = core mask lsb

     // get the context id into x0
    mov  x0, x6
    mov  x1, #CNTXT_ID_DATA
    bl   _getCoreData

     // x0 = context id

     // invalidate the icache
    ic  iallu
    isb

     // invalidate tlb
    tlbi  alle3
    dsb   sy
    isb

     // x0 = context id

     // exit EL3
    mov  x1,  #0
    mov  x2,  #0
    mov  x3,  #0
    mov  x4,  #0
    mov  x5,  #0
    mov  x6,  #0

     // clear the exclusive monitor and return from exception
    clrex
    isb
    eret

//-----------------------------------------------------------------------------

 // this is the exit from the monitor for cores coming out of sleep/suspend
_mon_core_restart:

     // get this cores bit mask
    bl   _get_current_mask
    mov  x8, x0

     // x0 = core mask (lsb)
     // x8 = core mask (lsb)

     // perform EL3 init on secondary core
    bl   _init_secondary_EL3

     // determine if hw supports el2
    bl   _is_EL2_supported

     // x0 = EL2 support (0=none)
    cbz  x0, 1f
     // perform EL2 init on core
    mov  x0, x8
    bl   _init_secondary_EL2
    b    2f
1:
     // perform EL1 init on core
    mov  x0, x8
    bl   _init_secondary_EL1
2:
     // get the start addr
    mov  x0, x8
    mov  x1, #START_ADDR_DATA
    bl   _getCoreData

     // x0 = start address
     // x8 = core mask (lsb)

     // load start addr in ELR_EL3
    msr  elr_el3, x0

     // set the core state to released
    mov  x0, x8
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_RELEASED
    bl   _setCoreData

     // x8 = core mask (lsb)

     // setup the spsr
    mov  x0, x8
    bl   _set_spsr_4_startup

     // setup the stack
    mov  x0, x8
    bl   init_stack_percpu

     // x8 = core mask lsb

     // get the saved link reg
    mov  x0, x8
    mov  x1, #LINK_REG_DATA
    bl   _getCoreData
    mov  x12, x0

     // x8  = core mask (lsb)
     // x12 = saved link reg

     // get the context id into x0
    mov  x0, x8
    mov  x1, #CNTXT_ID_DATA
    bl   _getCoreData

     // x0 = context id

     // invalidate the icache
    ic  iallu
    isb

     // invalidate tlb
    tlbi  alle3
    dsb   sy
    isb

     // x0 = context id

     // exit EL3
    mov  x1,  #0
    mov  x2,  #0
    mov  x3,  #0
    mov  x4,  #0
    mov  x5,  #0
    mov  x6,  #0
    mov  x7,  #0
    mov  x8,  #0

     // restore the LR
    mov  x30, x12

     // clear the exclusive monitor and return from exception
    clrex
    isb
    eret

//-----------------------------------------------------------------------------

 // this function makes any needed changes to the configuration when the end of
 // boot services is triggered.
 // in:  none
 // out: none
 // uses x0, x1, x11
exit_boot_svcs:
    mov  x11, x30

     // read the boot services flag
    adr  x0, boot_services_flag
    ldr  w1, [x0]
     // if we have already executed this service, don't execute again
    cbnz w1, 1f

     // set the flag
    mov  w1, #1
    str  w1, [x0]

     // put any global changes needed at end of boot services here
    
     // call into the soc-specific code for any soc configuration changes needed
    bl  _soc_exit_boot_svcs

1:
    mov  x30, x11
    ret

//-----------------------------------------------------------------------------

 // this function initializes the per-core stack area, and sets SP_EL3 to
 // point to the start of this area
 // Note: stack is full-descending
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2
init_stack_percpu:

     // x0 = core mask

     // generate a 0-based core number from the input mask
    clz   x1, x0
    mov   x0, #63
    sub   x0, x0, x1

     // x0 = current core number (0-based)

     // calculate the maximum core number
    mov   x1, #CPU_MAX_COUNT
    sub   x1, x1, #1

     // x0 = core number (0-based)
     // x1 = max core number (0-based)

     // get the offset factor
    sub   x1, x1, x0
     // get the absolute offset
    mov   x2, #STACK_OFFSET
    mul   x2, x2, x1

     // x0 = current core number (0-based)
     // x2 = absolute stack offset

     // get the top of the stack area
    mov   x1, #STACK_BASE_ADDR

     // x0 = current core number (0-based)
     // x1 = address of top of stack
     // x2 = absolute stack offset

     // get start of this cores stack
    sub   x1, x1, x2

     // x0 = current core number (0-based)
     // x1 = start of current cores stack

     // align to a quad-word boundary
    bic   x1, x1, #0xf

     // set the stack pointer
    mov   sp, x1

     // x0 = current core number (0-based)
     // x1 = start of current cores stack

     // initialize the stack area
    mov   x2, #STACK_OFFSET
     // if this is core 0, give it twice as much stack space
    cbnz  x0, 3f
    lsl   x2, x2, #1
3:
     // x2 = size of stack area in bytes
     // convert bytes to 16-byte chunks
    lsr   x2, x2, #4

     // x1 = start of current cores stack
     // x2 = size of stack area in 16-byte chunks
2:
     // descending-full stack - use pre-indexed addressing
    stp   xzr, xzr, [x1, #-16]!
    subs  x2, x2, #1
    b.gt  2b

    ret

//-----------------------------------------------------------------------------

 // this function sets up the memory bank info data areas in memory
 // Note: this function MUST be called before initializing ddr
 // in:  none
 // out: none
 // uses x0, x1, x2, x3
_init_membank_data:

 // only valid if ddr is being initialized
#if (DDR_INIT)

     // we want to allocate this data area directly below the EL3
     // stacks - calculate the size of the stack space
    mov   x0, #CPU_MAX_COUNT
    mov   x1, #STACK_OFFSET
    mul   x0, x0, x1
     // the bootcore is allocated 2x the normal stack size
    add   x0, x0, x1

     // x0 = total stack space

    mov   x1, #STACK_BASE_ADDR

     // find the bottom of the stack space
    sub   x0, x1, x0

     // x0 = bottom of stack

     // find bottom of memory bank data area
    mov   x1, #MEMBANK_REGION_MAX_SIZE
    sub   x0, x0, x1

     // x0 = bottom of memory bank data area
     // x1 = size of memory bank data area

     // store address of the memory bank count data
    adr  x3, _membank_count_addr
    bic  x0, x0, #0x7
    str  x0, [x3]

     // store address of the memory bank info data
    adr  x3, _membank_data_addr
    add  x2, x0, #0x8
    str  x2, [x3]

     // x0 = bottom of memory bank data area
     // x1 = size of memory bank data area

     // initialize the data area
    lsr   x1, x1, #3
     // x1 = number of double-words in region
1:
    str   xzr, [x0], #8
    sub   x1, x1, #1
    cbnz  x1, 1b

#endif

    ret

//-----------------------------------------------------------------------------

#if DDR_INIT
#if PSCI_TEST

#define  MEMBANK_COUNT  4
#define  BANK1_ADDR     0x0080000000
#define  BANK2_ADDR     0x8000000000
#define  BANK3_ADDR     OCRAM_BASE_ADDR
#define  BANK4_ADDR     0x00F0000000
#define  BANK1_SIZE     0x080000000       // 2GB
#define  BANK2_SIZE     0x200000000       // 8GB
#define  BANK3_SIZE     OCRAM_SIZE_IN_BYTES
#define  BANK4_SIZE     0x080000000       // 2GB

 // in:  none
 // out: none
 // uses x0, x1, x2, x3
_populate_membank_data:

     // get the address of the bank count var
    adr  x1, _membank_count_addr
    ldr  x2, [x1]

     // x2 = address of membank count data

     // store the number of banks
    mov  x1, #MEMBANK_COUNT
    str  x1, [x2] 

     // get the address of the first bank info struc
    adr  x1, _membank_data_addr
    ldr  x2, [x1]

     // x2 = address of first membank info struc

     // populate the first structure
    mov   w1, #MEMBANK_STATE_VALID
    str   w1, [x2, #MEMDATA_STATE_OFFSET]
    mov   w3, #MEMBANK_TYPE_DDR
    str   w3, [x2, #MEMDATA_TYPE_OFFSET]
    mov   x0, #BANK1_ADDR
    str   x0, [x2, #MEMDATA_ADDR_OFFSET]
    mov   x1, #BANK1_SIZE
    str   x1, [x2, #MEMDATA_SIZE_OFFSET]
   
     // move to the next data structure
    add   x2, x2, #MEMBANK_DATA_SIZE

     // populate the second structure
    mov   w1, #MEMBANK_STATE_VALID
    str   w1, [x2, #MEMDATA_STATE_OFFSET]
    mov   w3, #MEMBANK_TYPE_DDR
    str   w3, [x2, #MEMDATA_TYPE_OFFSET]
    mov   x0, #BANK2_ADDR
    str   x0, [x2, #MEMDATA_ADDR_OFFSET]
    mov   x1, #BANK2_SIZE
    str   x1, [x2, #MEMDATA_SIZE_OFFSET]
   
     // move to the next data structure
    add   x2, x2, #MEMBANK_DATA_SIZE

     // populate the third structure
    mov   w1, #MEMBANK_STATE_VALID
    str   w1, [x2, #MEMDATA_STATE_OFFSET]
    mov   w3, #MEMBANK_TYPE_DDR
    str   w3, [x2, #MEMDATA_TYPE_OFFSET]
    mov   x0, #BANK3_ADDR
    str   x0, [x2, #MEMDATA_ADDR_OFFSET]
    mov   x1, #BANK3_SIZE
    str   x1, [x2, #MEMDATA_SIZE_OFFSET]
   
     // move to the next data structure
    add   x2, x2, #MEMBANK_DATA_SIZE

     // populate the fourth structure
    mov   w1, #MEMBANK_STATE_INVALID
    str   w1, [x2, #MEMDATA_STATE_OFFSET]

    ret

#endif
#endif

//-----------------------------------------------------------------------------

boot_services_flag:
    .4byte 0x0

PPA_VERSION:
    .4byte  0x00040000

//-----------------------------------------------------------------------------

