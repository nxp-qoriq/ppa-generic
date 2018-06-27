//-----------------------------------------------------------------------------
// 
// Copyright 2017-2018 NXP Semiconductors
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

  .section .text, "ax"
 
//-----------------------------------------------------------------------------

#include "soc.h"
#include "psci.h"
#include "aarch64.h"

//-----------------------------------------------------------------------------

.global _test_psci

//-----------------------------------------------------------------------------

.align 3
.equ  MPIDR_CORE_0,    0x00000000
.equ  MPIDR_CORE_1,    0x00000001
.equ  MPIDR_CORE_2,    0x00000100
.equ  MPIDR_CORE_3,    0x00000101
.equ  MPIDR_CORE_4,    0x00000200
.equ  MPIDR_CORE_5,    0x00000201
.equ  MPIDR_CORE_6,    0x00000300
.equ  MPIDR_CORE_7,    0x00000301
.equ  MPIDR_CORE_8,    0x00000400
.equ  MPIDR_CORE_9,    0x00000401
.equ  MPIDR_CORE_10,   0x00000500
.equ  MPIDR_CORE_11,   0x00000501
.equ  MPIDR_CORE_12,   0x00000600
.equ  MPIDR_CORE_13,   0x00000601
.equ  MPIDR_CORE_14,   0x00000700
.equ  MPIDR_CORE_15,   0x00000701

.equ  CONTEXT_CORE_1,  0x12345678
.equ  CONTEXT_CORE_2,  0x23456781
.equ  CONTEXT_CORE_3,  0x34567812
.equ  CONTEXT_CORE_4,  0x45678123
.equ  CONTEXT_CORE_5,  0x56781234
.equ  CONTEXT_CORE_6,  0x67812345
.equ  CONTEXT_CORE_7,  0x78123456
.equ  CONTEXT_CORE_8,  0x00008888
.equ  CONTEXT_CORE_9,  0x99990000
.equ  CONTEXT_CORE_10, 0x0A0A0A0A
.equ  CONTEXT_CORE_11, 0xB0B0B0B0
.equ  CONTEXT_CORE_12, 0xCC00CC00
.equ  CONTEXT_CORE_13, 0x00DD00DD
.equ  CONTEXT_CORE_14, 0xEEEEEEEE
.equ  CONTEXT_CORE_15, 0xFFFFFFFF

//.equ  PSCI_V_MAJOR,   0x00000001
//.equ  PSCI_V_MINOR,   0x00000000
.equ  PSCI_V_MAJOR,   0x00000000
.equ  PSCI_V_MINOR,   0x00000002

.equ  PSCI_V_MASK,    0xFFFF

//-----------------------------------------------------------------------------

_test_psci:
    dsb sy
    isb
    nop

    bl  check_fiq_mask_01
    bl  runTest01
    bl  check_fiq_mask_02
    
cpu_0_stop:
    b .

cpu_0_fiq_err_01:
    b .

cpu_0_fiq_err_02:
    b .

cpu_1_start:
    bl  check_fiq_mask_03
cpu_1_spin:
    b .

cpu_2_start:
    bl  check_fiq_mask_03
cpu_2_spin:
    b .

cpu_fiq_err:
    b .

runTest01:
    // execute PSCI_CPU_ON

    // (Core 1)     
    ldr  w1, =MPIDR_CORE_1
    adr  x2, cpu_1_start
    ldr  w3, =CONTEXT_CORE_1
    ldr  w0, =PSCI64_CPU_ON_ID
    smc  0x0
    nop
    nop

    //-------

    // (Core 2)
    ldr  w0, =PSCI64_CPU_ON_ID
    ldr  w1, =MPIDR_CORE_2
    adr  x2, cpu_2_start
    ldr  w3, =CONTEXT_CORE_2
    smc  0x0
    nop
    nop

    //-------

    ret

    //-------

check_fiq_mask_01:
    mrs  x0, daif
    tst  x0, #DAIF_FIQ_BIT
    b.ne cpu_0_fiq_err_01
    ret

check_fiq_mask_02:
    mrs  x0, daif
    tst  x0, #DAIF_FIQ_BIT
    b.ne cpu_0_fiq_err_02
    ret

check_fiq_mask_03:
    mrs  x0, daif
    tst  x0, #DAIF_FIQ_BIT
    b.ne cpu_fiq_err
    ret


