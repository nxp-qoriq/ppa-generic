//-----------------------------------------------------------------------------
// 
// Copyright (c) 2015-2016, Freescale Semiconductor, Inc. All rights reserved.
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
//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "policy.h"

//-----------------------------------------------------------------------------

.global _init_interconnect
.global _manual_L3_flush

//-----------------------------------------------------------------------------

 // CCN-504 defines
.equ  L3_BASE_MN,            0x04000000
.equ  L3_BASE_HNI,           0x04080000
.equ  L3_BASE_HNF,           0x04200000
.equ  HNF_NODE_BASE_ADDR,    0x04200000
.equ  L3_BASE_RNI,           0x04800000
.equ  L3_SDCR_CLR,           0xFFFFFFFF
.equ  SA_AUX_CTRL_OFFSET,    0x0500
.equ  OLYRNF_LIST_OFFSET,    0x180
.equ  OLYRNIDVM_LIST_OFFSET, 0x1A0
.equ  RNI_12_OFFSET,         0x0C0000
.equ  RNI_20_OFFSET,         0x140000
.equ  RNI_AUX_CTL_OFFSET,    0x0500

.equ  RETRY_CNT,             800

.equ  SA_AUX_CTRL_PTB,       0x10
.equ  SA_AUX_CTRL_SDW,       0x200
.equ  RNI_AUX_CTL_WUO,       0x10

.equ  PRR_OFFSET,         0x10
.equ  PSR_OFFSET,         0x18
.equ  HNF_NODE_OFFSET,    0x10000
.equ  P_STATE_MASK,       0xF
.equ  REGION_BITMAP_MASK, 0x3

.equ  HNF_REGION_COUNT, 8
.equ  L3_PSTATE_FULL,   3
.equ  L3_PSTATE_HALF,   2
.equ  L3_PSTATE_SFONLY, 1
.equ  L3_PSTATUS_FULL,        0xC
.equ  L3_PSTATUS_HALF,        0x8
.equ  L3_PSTATUS_FULL_2_HALF, 0xF
.equ  L3_PSTATUS_HALF_2_FULL, 0xB
.equ  L3_PSTATUS_SFONLY,      0x4

 // the tick-count values are dependent upon the value
 // written to the frequency counter
.equ  TICKS_PER_USEC,         12
.equ  TICKS_PER_100_USEC,     1200
.equ  TICKS_PER_200_USEC,     2400
.equ  TICKS_PER_300_USEC,     3600

//-----------------------------------------------------------------------------

 // in:  none
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7
_init_interconnect:

    ret

 //----------------------------------------------------------------------------
 // this function flushes (clean+invalidate) the L3 cache nodes in
 // the CCN-508 device
 // in:  none
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10
_manual_L3_flush:

    ret

 //----------------------------------------------------------------------------

 // this function resets the L3 hnf region nodes to their original pstate after
 // a flush operation
 // in:  x0 = region pstate bitmap
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7
reset_pstate:

    ret

 //----------------------------------------------------------------------------

 // this function polls the L3 regions which have a non-null entry in the
 // region bitmap (x0), until they have a pstate corresponding to their
 // 2-bit entry in the bitmap
 // in:  x0, pstate bitmap of regions to poll, each pair of bits contains
 //          the state we are polling that region for
 //          Ex: region 0=bits[1:0], region 1=bits[3:2], region 2=bits[5:4]
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7
poll_L3_pstate:

    ret

 //----------------------------------------------------------------------------
 //----------------------------------------------------------------------------

