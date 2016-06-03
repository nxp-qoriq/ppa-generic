// 
// ARM v8 AArch64 Secure Monitor
//
// Copyright (c) 2015-2016, NXP Semiconductor, Inc. All rights reserved.
//

// This code includes:
// (1) EL3 secure monitor

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "policy.h"

//-----------------------------------------------------------------------------

.global _init_interconnect

//-----------------------------------------------------------------------------

 // CCN-504 defines
.equ  L3_BASE_MN,            0x04000000
.equ  L3_BASE_HNI,           0x04080000
.equ  L3_BASE_HNF,           0x04200000
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

//-----------------------------------------------------------------------------

 // this function sets snoop mode and dvm domains in the L3 cache
 // in:  none
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7
_init_interconnect:

     // set the WUO bit for system performance
    mov  x0, #POLICY_PERF_WRIOP
    mov  x2, #RNI_12_OFFSET
    cbz  x0, 1f
    mov  x2, #RNI_20_OFFSET
1:
    ldr  x1, =L3_BASE_RNI
    add  x1, x1, x2
    ldr  x0, [x1, #RNI_AUX_CTL_OFFSET]
    orr  x0, x0, #RNI_AUX_CTL_WUO
    str  x0, [x1, #RNI_AUX_CTL_OFFSET]
    
     // terminate the pos barriers in sa_aux_ctl reg
    ldr  x1, =L3_BASE_HNI
    ldr  x0, [x1, #SA_AUX_CTRL_OFFSET]
    orr  x0, x0, #SA_AUX_CTRL_PTB
     // set ser_devne_wr
    orr  x0, x0, #SA_AUX_CTRL_SDW
    str  x0, [x1, #SA_AUX_CTRL_OFFSET]

     // read the oly_rnf_nodeid_list register for rnf regions
    ldr  x1, =L3_BASE_MN
    ldr  x4, [x1, #OLYRNF_LIST_OFFSET]

     // read the oly_rnidvm_nodeid_list for dvm domains
    ldr  x1, =L3_BASE_MN
    ldr  x5, [x1, #OLYRNIDVM_LIST_OFFSET]
     // orr the rnf_nodeid values in with the dvm_nodeid values 
    orr  x5, x5, x4

    ldr  x1, =L3_BASE_HNF
    mov  x2, #0x220
    mov  x3, #0x210
    ldr  x6, =L3_SDCR_CLR

     // x1 = hnf base address
     // x2 = sdcr_clr offset, dvm_clr offset
     // x3 = sdcr_set offset, dvm_set offset
     // x4 = sdcr node ids
     // x5 = dvm domain ids
     // x6 = sdcr/dvm clr value
     // x7 = region count

    mov  x7, #8
write_sdcr_regs:
    str  x6, [x1, x2]
    str  x4, [x1, x3]
    add  x1, x1, #0x10000
    subs x7, x7, #1
    b.ne write_sdcr_regs   

     // write to dvm_clr, dvm_set regs
    ldr  w1, =L3_BASE_MN
    str  x6, [x1, x2]
    str  x5, [x1, x3]

    dsb  #0xf

    mov  x0, #RETRY_CNT      // retry count for simulator models
    mov  x2, #0x200
poll_mn_ddcr:
    ldr  x6, [x1, x2]
    cmp  x6, x5
    b.eq 1f
    subs x0, x0, #1
    b.ne poll_mn_ddcr
1:
    ldr  w1, =L3_BASE_HNF
    mov  x7, #8
2:
    mov  x0, #RETRY_CNT      // retry count for simulator models
poll_hnf_sdcr:
    ldr  x6, [x1, x2]
    cmp  x6, x4
    b.eq 3f
    subs x0, x0, #1
    b.ne poll_hnf_sdcr
3:
    add  x1, x1, #0x10000
    subs x7, x7, #1
    b.ne 2b  

    ret

//-----------------------------------------------------------------------------

