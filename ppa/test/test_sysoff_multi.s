// 
// ARM v8 AArch64 PSCI test code
//
// Copyright (c) 2017, NXP Semiconductors, Inc. All rights reserved.
//

// This includes:
// (1) PSCI test code (executes @ EL2)

//-----------------------------------------------------------------------------

  .section .text, "ax"
 
//-----------------------------------------------------------------------------
    
#include "soc.h"
#include "psci.h"

//-----------------------------------------------------------------------------

  .global _test_psci

//-----------------------------------------------------------------------------

.align 12
.equ  MPIDR_CORE_0,   0x00000000
.equ  MPIDR_CORE_1,   0x00000001

.equ  CONTEXT_CORE_0, 0x01234567
.equ  CONTEXT_CORE_1, 0x12345678

//.equ  PSCI_V_MAJOR,   0x00000001
//.equ  PSCI_V_MINOR,   0x00000000
.equ  PSCI_V_MAJOR,   0x00000000
.equ  PSCI_V_MINOR,   0x00000002

//-----------------------------------------------------------------------------

.ltorg

//-----------------------------------------------------------------------------

_test_psci:

 //------------------------------------

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
     // loop til the core comes up
    ldr  x1, =AFFINITY_LEVEL_ON
    cmp  x0, x1
    b.ne 1b

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
     // loop til the core goes down
    ldr  x1, =AFFINITY_LEVEL_OFF
    cmp  x0, x1
    b.ne 2b

     // call SYSTEM_OFF to shutdown the system
     // x0 = function id = PSCI_SYSTEM_OFF = 0x84000008
    dsb sy
    isb
    nop
    ldr  x0, =PSCI_SYSTEM_OFF
    smc  0x0
    nop
    nop

core_0_fail:
    b     core_0_fail

 //------------------------------------

core_1a_entry:
    ldr  w9, =CONTEXT_CORE_1
    bl context_id_chk
core_1b_next:
     // shut this core down
     // x0 = function id = 0x84000002
    ldr x0, =PSCI_CPU_OFF_ID
    smc 0x0
    nop
    nop
    nop
core_1c_fail:
    b     core_1c_fail

 //------------------------------------

 // CPU_ON context id check
context_id_chk:
    cmp w0, w9
    b.ne context_chk_fail
    ret
context_chk_fail: 
     // context did not match
    b context_chk_fail

 //------------------------------------

