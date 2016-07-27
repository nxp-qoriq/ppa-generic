// boot.h
// 
// header file for LS2088 bootrom code
//
// Copyright (c) 2015-2016, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _BOOT_H
#define	_BOOT_H

//-----------------------------------------------------------------------------

 // this macro reads MPIDR_EL1 and extracts the lo-order 16 bits
 // the parameters to this macro MUST be 64-bit registers
.macro Get_MPIDR_EL1 $p1, $p2

     // read mp affinity reg (MPIDR_EL1) into $p1
    mrs \$p1, MPIDR_EL1
     // extract the affinity 0 & 1 fields - bits [15:0]
    mov   \$p2, xzr
    bfxil \$p2, \$p1, #0, #16
.endm

//-----------------------------------------------------------------------------

.equ MAX_SOC_CORES,     0x8
.equ DISABLE_RETRY_CNT, 800

 // base addresses
.equ  PMU_BASE_ADDR,   0x01E30000
.equ  GICR_BASE_ADDR,  0x06100000
.equ  SEC_REGFILE_BASE_ADDR, 0x01E88000

 // register offsets -------------

 // dcfg block registers
.equ COREDISABLEDSR_OFFSET, 0x990
.equ SCRATCHRW7_OFFSET,     0x218
.equ SVR_OFFSET,            0x0A4
.equ GENCR1_OFFSET,         0x620
.equ BOOTLOCPTRL_OFFSET,    0x400
.equ BOOTLOCPTRH_OFFSET,    0x404
.equ RCWSR9_OFFSET,         0x120

 // reset block registers
.equ BRCORENBR_OFFSET,      0x090
.equ BRR_OFFSET,            0x060

 // pmu register offsets
.equ CLTBENR_OFFSET,        0x18A0

 // timer register offsets
.equ CNTCR_OFFSET,          0x0
.equ CNTCV_OFFSET,          0x8    // 64-bit register
.equ CNTFID0_OFFSET,        0x020

 // CCN-504 register offsets
.equ HNI_POS_CNTRL_OFFSET,      0x0
.equ HNI_SA_AUX_CTL_OFFSET,     0x500
.equ MN_OLY_RNF_NODEID_LIST,    0x180
.equ MN_OLY_RNIDVM_NODEID_LIST, 0x1A0

 // secure register file offsets
.equ TZSECURECR_OFFSET,         0x0
.equ TZGDCR_OFFSET,             0x80
.equ TZCLKOVRDR_OFFSET,         0x100
.equ CORE_HOLD_OFFSET,          0x140

 //--------------------------------

 // CCN-504 defines
.equ  L3_BASE_MN,     0x04000000
.equ  L3_BASE_HNI,    0x04080000
.equ  L3_BASE_HNF,    0x04200000
.equ  L3_BASE_RNI,    0x04800000
.equ  L3_SDCR_CLR,    0xFFFFFFFF
.equ  SA_AUX_CTL_SET, 0x4D7

 // device base addresses
.equ DEV_PCIEX1_BASE,   0x1000000000
.equ DEV_PCIEX2_BASE,   0x1200000000
.equ DEV_PCIEX3_BASE,   0x1400000000
.equ DEV_PCIEX4_BASE,   0x1600000000
.equ DEV_MEMCMPLX_BASE, 0x0080000000
.equ DEV_OCRAM_BASE,    0x0018000000
.equ DEV_TPORT_BASE,    0x0600000000
.equ DEV_IFC_BASE,      0x0030000000
.equ DEV_SERNOR_BASE,   0x0020000000

//-----------------------------------------------------------------------------

#endif // _BOOT_H