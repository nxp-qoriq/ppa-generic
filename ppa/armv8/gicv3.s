// 
// ARM v8 AArch64 Secure Monitor
//
// Copyright (c) 2015-2016, Freescale Semiconductor, Inc. All rights reserved.
//

// This code includes:
// GICv3 EL3 initialization

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "soc.h"

//-----------------------------------------------------------------------------

.global _gic_init_percpu
.global _gic_init_common

//-----------------------------------------------------------------------------

 // this function performs one-time gic init, executed by the boot core
 // out: none
 // uses x0, x1
_gic_init_common:

    ldr  x1, =GICD_BASE_ADDR

     // disable interrupts at the distributor
    ldr  w0, [x1, #GICD_CTLR_OFFSET]
    bic  w0, w0, #GICD_CTLR_EN_GRP_MASK
    str  w0, [x1, #GICD_CTLR_OFFSET]
     // poll on RWP til write completes
1:
    ldr  w0, [x1, #GICD_CTLR_OFFSET]
    tst  w0, #GICD_CTLR_RWP_MASK
    b.ne 1b   
    
     // enable affinity routing for secure interrupts
    orr  w0, w0, #GICD_CTLR_ARE_S_MASK
    str  w0, [x1, #GICD_CTLR_OFFSET]
     // poll on RWP til write completes
2:
    ldr  w0, [x1, #GICD_CTLR_OFFSET]
    tst  w0, #GICD_CTLR_RWP_MASK
    b.ne 2b

     // enable GRP1 interrupts
    orr  w0, w0, #GICD_CTLR_EN_GRP_1NS
    orr  w0, w0, #GICD_CTLR_EN_GRP_1S
    str  w0, [x1, #GICD_CTLR_OFFSET]
     // poll on RWP til write completes
3:
    ldr  w0, [x1, #GICD_CTLR_OFFSET]
    tst  w0, #GICD_CTLR_RWP_MASK
    b.ne 3b

    ret

//-----------------------------------------------------------------------------

 // perform the per-cpu EL3 initialization of the GIC
 // in:   none
 // out:  none
 // uses: x0, x2, x1, x3
_gic_init_percpu:

     // get the base address of the gic redistributor
    ldr  x1, =GICR_RD_BASE_ADDR

	 // x1: ReDistributor Base Address

	 // Initialize gic ReDistributor for this core
	mrs	  x2, mpidr_el1
	lsr	  x3, x2, #32
     // w2 is aff3:aff2:aff1:aff0
	bfi	  x2, x3, #24, #8
	mov	  x3, x1
1:	ldr	  x0, [x3, 0x0008]
	lsr	  x0, x0, #32
     // w0 is aff3:aff2:aff1:aff0
	cmp	  w2, w0
	b.eq  2f
	add   x3, x3, #(2 << 16)
	b     1b

	 // x3: ReDistributor Base Address of Current CPU
2:	mov   w2, #~0x2
	ldr   w0, [x3, 0x0014]
     // clear procesor sleep
	and   w0, w0, w2
	str   w0, [x3, 0x0014]
	dsb   st
	isb
3:	ldr   w2, [x3, 0x0014]
     // wait children be alive
	tbnz  w2, #2, 3b

     // sgi base
	add   x2, x3, #(1 << 16)
	mov   w0, #~0
	str   w0, [x2, 0x0080]
     // SGIs|PPIs group1NS
	str   wzr, [x2, 0x0d00]
     // enable SGI 0
	mov   w0, #0x1
	str   w0, [x2, 0x0100]

	 // init cpu interface
	mrs   x2, s3_6_c12_c12_5

     // SRE & disable IRQ/FIQ bypass &
     // allow EL2 access to ICC_SRE_EL2
	orr   x2, x2, #0xf
	msr   s3_6_c12_c12_5, x2
	isb

	mrs   x2, s3_4_c12_c9_5
     // SRE & disable IRQ/FIQ bypass &
     // allow EL1 access to ICC_SRE_EL1
	orr   x2, x2, #0xf
	msr   s3_4_c12_c9_5, x2
	isb

     // enableGrp1NS | enableGrp1S
	mov   x2, #0x3
	msr   s3_6_c12_c12_7, x2
	isb

	msr   s3_6_c12_c12_4, xzr
	isb

     // NonSecure ICC_CTLR_EL1
	msr   s3_0_c12_c12_4, xzr
	isb

     // Non-Secure access to ICC_PMR_EL1
	mov   x2, #0x1 << 7
	msr   s3_0_c4_c6_0, x2

     // cpu interface setup

     // set SRE access for EL3
    mrs   x1, ICC_SRE_EL3
    orr   x1, x1, #ICC_SRE_EL3_SRE
    msr   ICC_SRE_EL3, x1

     // setup ICC_CTLR_EL3
    mrs   x2, ICC_CTLR_EL3
    bic   x2, x2, #ICC_CTLR_EL3_RM
    bic   x2, x2, #ICC_CTLR_EL3_EOIMODE_EL3
    orr   x2, x2, #ICC_CTLR_EL3_PMHE
    msr   ICC_CTLR_EL3, x2

    ret

//-----------------------------------------------------------------------------

