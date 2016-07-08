// 
// ARM v8 AArch64 PSCI testcode 
//
// Copyright (c) 2013-2016, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

.align 3
.equ  DCFG_BASE_ADDR, 0x01E00000
.equ  PERIPH_BASE,    0x04000000
.equ  L3_BASE_MN,     0x04000000
.equ  L3_BASE_HNI,    0x04080000
.equ  L3_BASE_HNF,    0x04200000
.equ  L3_BASE_RNI,    0x04800000
.equ  L3_SDCR_CLR,    0xFFFFFFFF

//.equ  PSCI_V_MAJOR,   0x00000001
//.equ  PSCI_V_MINOR,   0x00000000
.equ  PSCI_V_MAJOR,   0x00000000
.equ  PSCI_V_MINOR,   0x00000002

//-----------------------------------------------------------------------------

  .section .text, "ax"
 
//-----------------------------------------------------------------------------

.global _test_psci

//-----------------------------------------------------------------------------

#include "soc.h"
#include "psci.h"

//-----------------------------------------------------------------------------

.equ  MPIDR_CORE_0,   0x00000000
.equ  MPIDR_CORE_1,   0x00000001
.equ  MPIDR_CORE_2,   0x00000100
.equ  MPIDR_CORE_3,   0x00000101
.equ  MPIDR_CORE_4,   0x00000200
.equ  MPIDR_CORE_5,   0x00000201
.equ  MPIDR_CORE_6,   0x00000300
.equ  MPIDR_CORE_7,   0x00000301

.equ  CONTEXT_CORE_1, 0x12345678
.equ  CONTEXT_CORE_2, 0x23456781
.equ  CONTEXT_CORE_3, 0x34567812
.equ  CONTEXT_CORE_4, 0x45678123
.equ  CONTEXT_CORE_5, 0x56781234
.equ  CONTEXT_CORE_6, 0x67812345
.equ  CONTEXT_CORE_7, 0x78123456

//-----------------------------------------------------------------------------

_test_psci:
    dsb sy
    isb
    nop

   // b  _test_psci

    // test PSCI_CPU_ON

    //-------
    // (Core 1)     
    ldr  w1, =MPIDR_CORE_1
    adr  x2, cpu_1_start
    ldr  w3, =CONTEXT_CORE_1
    ldr  w0, =PSCI_CPU_ON_ID
    smc  0x0
    nop
    nop
    nop

    //-------
    // (Core 2)
    ldr  w0, =PSCI_CPU_ON_ID
    ldr  w1, =MPIDR_CORE_2
    adr  x2, cpu_2_start
    ldr  w3, =CONTEXT_CORE_2
    smc  0x0
    nop
    nop
    nop

    //-------
    // (Core 3)
    ldr  w0, =PSCI_CPU_ON_ID
    ldr  w1, =MPIDR_CORE_3
    adr  x2, cpu_3_start
    ldr  w3, =CONTEXT_CORE_3
    smc  0x0
    nop
    nop
    nop

    //-------
    // (Core 4)
    ldr  w0, =PSCI_CPU_ON_ID
    ldr  w1, =MPIDR_CORE_7
    adr  x2, cpu_7_start
    ldr  w3, =CONTEXT_CORE_7
    smc  0x0
    nop
    nop
    nop

    //-------
    // (Core 5)
    ldr  w0, =PSCI_CPU_ON_ID
    ldr  w1, =MPIDR_CORE_5
    adr  x2, cpu_5_start
    ldr  w3, =CONTEXT_CORE_5
    smc  0x0
    nop
    nop
    nop

    //-------
    // (Core 6)
    ldr  w0, =PSCI_CPU_ON_ID
    ldr  w1, =MPIDR_CORE_6
    adr  x2, cpu_6_start
    ldr  w3, =CONTEXT_CORE_6
    smc  0x0
    nop
    nop
    nop

    //-------
    // (Core 7)
    ldr  w0, =PSCI_CPU_ON_ID
    ldr  w1, =MPIDR_CORE_4
    adr  x2, cpu_4_start
    ldr  w3, =CONTEXT_CORE_4
    smc  0x0
    nop
    nop
    nop

_cpu_0_loop:
    b  _cpu_0_loop

cpu_1_start:
    ldr  w9, =CONTEXT_CORE_1
    bl context_id_chk
cpu_1_pass:
    b cpu_1_pass

cpu_2_start:
    ldr  w9, =CONTEXT_CORE_2
    bl context_id_chk
cpu_2_pass:
    b cpu_2_pass

cpu_3_start:
    ldr  w9, =CONTEXT_CORE_3
    bl context_id_chk
cpu_3_pass:
    b cpu_3_pass

cpu_4_start:
    ldr  w9, =CONTEXT_CORE_4
    bl context_id_chk
cpu_4_pass:
    b cpu_4_pass

cpu_5_start:
    ldr  w9, =CONTEXT_CORE_5
    bl context_id_chk
cpu_5_pass:
    b cpu_5_pass

cpu_6_start:
    ldr  w9, =CONTEXT_CORE_6
    bl context_id_chk
cpu_6_pass:
    b cpu_6_pass

cpu_7_start:
    ldr  w9, =CONTEXT_CORE_7
    bl context_id_chk
cpu_7_pass:
    b cpu_7_pass

 // CPU_ON context id check
context_id_chk:
    cmp w0, w9
    b.ne context_chk_fail
    ret
context_chk_fail: 
     // context did not match
    b context_chk_fail


