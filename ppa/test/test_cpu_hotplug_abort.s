// 
// ARM v8 AArch64 Bootrom 
//
// Copyright (c) 2013-2014, Freescale Semiconductor, Inc. All rights reserved.
//

// This romcode includes:
// (1) PSCI test code (executes @ EL2)

//-----------------------------------------------------------------------------

  .section .text, "ax"
 
//-----------------------------------------------------------------------------
    
#include "soc.h"
#include "psci.h"

//-----------------------------------------------------------------------------

  .global _test_psci

//-----------------------------------------------------------------------------

.align 3
.equ  MPIDR_CORE_0,   0x00000000
.equ  MPIDR_CORE_1,   0x00000001
.equ  MPIDR_CORE_2,   0x00000002
.equ  MPIDR_CORE_3,   0x00000003
.equ  MPIDR_CORE_4,   0x00000100

.equ  CONTEXT_CORE_0, 0x01234567
.equ  CONTEXT_CORE_1, 0x12345678
.equ  CONTEXT_CORE_2, 0xA9876543
.equ  CONTEXT_CORE_3, 0x10208070
.equ  CONTEXT_CORE_4, 0x93827160
.equ  CONTEXT_CORE_1_AGAIN, 0x23456789

//.equ  PSCI_V_MAJOR,   0x00000001
//.equ  PSCI_V_MINOR,   0x00000000
.equ  PSCI_V_MAJOR,   0x00000000
.equ  PSCI_V_MINOR,   0x00000002

//-----------------------------------------------------------------------------

.ltorg

//-----------------------------------------------------------------------------

.align 3
_test_psci:

     // test PSCI_CPU_ON (core 1)
     // x0 = function id = 0xC4000003
     // x1 = mpidr       = 0x0001
     // x2 = start addr  = core_1a_entry
     // x3 = context id  = CONTEXT_CORE_1
    dsb sy
    isb
    nop
    ldr  x0, =PSCI64_CPU_ON_ID
    ldr  x1, =MPIDR_CORE_1
    adr  x2, core_1a_entry
    ldr  x3, =CONTEXT_CORE_1
    smc  0x0
    nop
    nop
    nop

     // test PSCI_CPU_ON (core 2)
     // x0 = function id = 0xC4000003
     // x1 = mpidr       = 0x0002
     // x2 = start addr  = core_2a_entry
     // x3 = context id  = CONTEXT_CORE_2
    nop
    ldr  x0, =PSCI64_CPU_ON_ID
    ldr  x1, =MPIDR_CORE_2
    adr  x2, core_2a_entry
    ldr  x3, =CONTEXT_CORE_2
    smc  0x0
    nop
    nop
    nop

     // test PSCI_CPU_ON (core 3)
     // x0 = function id = 0xC4000003
     // x1 = mpidr       = 0x0003
     // x2 = start addr  = core_3a_entry
     // x3 = context id  = CONTEXT_CORE_3
    nop
    ldr  x0, =PSCI64_CPU_ON_ID
    ldr  x1, =MPIDR_CORE_3
    adr  x2, core_3a_entry
    ldr  x3, =CONTEXT_CORE_3
    smc  0x0
    nop
    nop
    nop

1:
     // test AFFINITY_INFO of core 1
     // x0 = function id = 0xC4000004
     // x1 = mpidr       = 0x0001
     // x2 = level       = 0x0
    ldr  x0, =PSCI64_AFFINITY_INFO_ID
    ldr  x1, =MPIDR_CORE_1
    mov  x2, #0
    smc  0x0
    nop
    nop
    nop
     // test the return value
    ldr  x1, =AFFINITY_LEVEL_OFF
    cmp  x0, x1
    b.ne 1b

     // test PSCI_CPU_ON (core 1)
     // x0 = function id = 0xC4000003
     // x1 = mpidr       = 0x0001
     // x2 = start addr  = core_1a_entry
     // x3 = context id  = CONTEXT_CORE_1
    dsb sy
    isb
    nop
    ldr  x0, =PSCI64_CPU_ON_ID
    mov  x1, #MPIDR_CORE_1
    adr  x2, core_1c_entry
    ldr  x3, =CONTEXT_CORE_1_AGAIN
    smc  0x0
    nop
    nop
    nop

2:
     // test AFFINITY_INFO of core 1
     // x0 = function id = 0xC4000004
     // x1 = mpidr       = 0x0001
     // x2 = level       = 0x0
    ldr  x0, =PSCI64_AFFINITY_INFO_ID
    ldr  x1, =MPIDR_CORE_1
    mov  x2, #0
    smc  0x0
    nop
    nop
    nop
     // test the return value
    ldr  x1, =AFFINITY_LEVEL_ON
    cmp  x0, x1
    b.ne 2b

core_0_stop:
    b  core_0_stop

//-----------------------------------------------------------------------------

core_1a_entry:
     // test PSCI_CPU_OFF
     // x0 = function id = 0x84000002
    ldr x0, =PSCI_CPU_OFF_ID
    smc 0x0
    nop
    nop
    nop
core_1b_entry:
    b   core_1b_entry
core_1c_entry:
    b   core_1c_entry

core_2a_entry:
    b   core_2a_entry

core_3a_entry:
    b   core_3a_entry

//-----------------------------------------------------------------------------

