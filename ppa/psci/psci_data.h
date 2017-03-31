//-----------------------------------------------------------------------------
// 
// Copyright (c) 2013-2016 Freescale Semiconductor, Inc.
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
//
// This file includes:
// per-cpu data areas
//
//-----------------------------------------------------------------------------

 // these fields MUST be 64-bit width - the access macros depend on it!
 // if you add/subtract a field, you must adjust CORE_DATA_OFFSET and
 // CORE_SP_OFFSET in psci.h
.macro CoreDataStruc
    .8byte  0x0  // core state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
    .8byte  0x0  // AUX_01
    .8byte  0x0  // AUX_02
    .8byte  0x0  // AUX_03
    .8byte  0x0  // AUX_04
    .8byte  0x0  // AUX_05
    .8byte  0x0  // scr_el3
    .8byte  0x0  // hcr_el2
.endm

//-----------------------------------------------------------------------------

.align 4
_cpu0_data:
    CoreDataStruc

cpu1_data:
    CoreDataStruc

.if (CPU_MAX_COUNT > 2)
cpu2_data:
    CoreDataStruc
cpu3_data:
    CoreDataStruc
.endif

.if (CPU_MAX_COUNT > 4)
cpu4_data:
    CoreDataStruc
cpu5_data:
    CoreDataStruc
cpu6_data:
    CoreDataStruc
cpu7_data:
    CoreDataStruc
.endif

.if (CPU_MAX_COUNT > 8)
cpu8_data:
    CoreDataStruc
cpu9_data:
    CoreDataStruc
cpu10_data:
    CoreDataStruc
cpu11_data:
    CoreDataStruc
.endif

.if (CPU_MAX_COUNT > 12)
cpu12_data:
    CoreDataStruc
cpu13_data:
    CoreDataStruc
cpu14_data:
    CoreDataStruc
cpu15_data:
    CoreDataStruc
.endif

 // if assembly stops here, you need to add more data areas
.if (CPU_MAX_COUNT > 16)
.err
.endif

//-----------------------------------------------------------------------------

