// 
// ARM v8 AArch64 Secure Monitor
//
// Copyright (c) 2015-2016, NXP Semiconductor, Inc. All rights reserved.
//

// This code includes:
// (1) initialization code for the ARM interconnect

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "soc.h"

//-----------------------------------------------------------------------------

.global _init_interconnect

//-----------------------------------------------------------------------------

 // cci-400 register offsets
.equ SNOOP_CNTRL_SLV0,     0x1000
.equ SNOOP_CNTRL_SLV1,     0x2000
.equ SNOOP_CNTRL_SLV2,     0x3000
.equ SNOOP_CNTRL_SLV3,     0x4000
.equ SNOOP_CNTRL_SLV4,     0x5000
.equ SNOOP_STATUS,         0x000C

 // cci-400 register bit masks
.equ SNOOP_CNTRL_SNP_EN,   0x1         // enable snooping on this interface
.equ SNOOP_CNTRL_DVM_EN,   0x2         // enable dvm messaging on this interface
.equ SNOOP_CNTRL_SNP_SUPP, 0x40000000  // interface supports snooping
.equ SNOOP_CNTRL_DVM_SUPP, 0x80000000  // interface supports dvm messaging
.equ STATUS_PENDING,       0x1

//-----------------------------------------------------------------------------

 // this function performs initialization on the cci-400
 // in:  none
 // out: none
 // uses x0, 
_init_interconnect:

     // get the base address of the cci-400
    mov  x0, #CCI_400_BASE_ADDR

     // set snoop, dvm mode for slave interface 3 (gpp cluster 0)
    mov  x3, #SNOOP_CNTRL_SLV3
    ldr  w1, [x0, x3]
    orr  w1, w1, #SNOOP_CNTRL_SNP_EN
    orr  w1, w1, #SNOOP_CNTRL_DVM_EN
    str  w1, [x0, x3]

     // see if snoop, dvm are needed for slave interface 4 (gpp cluster 1)
    mov  x3, #SNOOP_CNTRL_SLV4
    ldr  w1, [x0, x3]
    mov  w2, w1
    tst  w1, #SNOOP_CNTRL_DVM_SUPP
    b.eq 1f
    orr  w1, w1, #SNOOP_CNTRL_DVM_EN
1:
    tst  w1, #SNOOP_CNTRL_SNP_SUPP
    b.eq 2f
    orr  w1, w1, #SNOOP_CNTRL_SNP_EN
2:
    cmp  w2, w1
    b.eq 3f
    str  w1, [x0, x3]
3:
     // set dvm for slave interface 2 (TCU)
    ldr  w1, [x0, #SNOOP_CNTRL_SLV2]
    orr  w1, w1, #SNOOP_CNTRL_DVM_EN
    str  w1, [x0, #SNOOP_CNTRL_SLV2]
    isb

     // poll on the status register till the changes are applied
    mov  w2, #CCI400_PEND_CNT
4:
    ldr  w1, [x0, #SNOOP_STATUS]
    tst  w1, #STATUS_PENDING
     // if no change pending, exit
    b.eq 5f
     // decrement the retry count
    sub  w2, w2, #1
     // if retries maxed out, exit
    cbz  w2, 5f
     // else loop and try again
    b    4b
5:
    ret

//-----------------------------------------------------------------------------

