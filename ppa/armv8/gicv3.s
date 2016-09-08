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

     // get starting base address of the redistributor
    ldr  x1, =GICR_RD_BASE_ADDR

	 // x1 = redistributor base addr

	 // initialize gic redistributor for this core
	mrs	  x2, mpidr_el1
	lsr	  x3, x2, #32

     // w2 = aff3:aff2:aff1:aff0 of this core

	bfi	  x2, x3, #24, #8
	mov	  x3, x1
1:
    ldr	  x0, [x3, #GICR_TYPER_OFFSET]
	lsr	  x0, x0, #32

     // w0 = aff3:aff2:aff1:aff0 of this redistributor

	cmp	  w2, w0
	b.eq  2f
	add   x3, x3, #GIC_RD_OFFSET
	b     1b

	 // x3 = redistributor base addr of this core
2:
    mov   w2, #~0x2
	ldr   w0, [x3, #GICR_WAKER_OFFSET]

     // clear procesor sleep
	and   w0, w0, w2
	str   w0, [x3, #GICR_WAKER_OFFSET]
	dsb   st
	isb
3:
    ldr   w2, [x3, #GICR_WAKER_OFFSET]

     // wait children be alive
	tbnz  w2, #2, 3b

     // get this cores sgi base addr
	add   x2, x3, #GIC_RD_2_SGI_OFFSET

	 // x2 = sgi base addr of this core
2:
	mov   w0, #~0
	str   w0, [x2, #GICR_IGROUPR0_OFFSET]
     // SGIs|PPIs group1NS
	str   wzr, [x2, #GICR_IGRPMODR0_OFFSET]
     // enable SGI 0
	mov   w0, #0x1
	str   w0, [x2, #GICR_ISENABLER0_OFFSET]

	 // init cpu interface
	mrs   x2, ICC_SRE_EL3

     // SRE & disable IRQ/FIQ bypass &
     // allow EL2 access to ICC_SRE_EL2
	orr   x2, x2, #0xf
	msr   ICC_SRE_EL3, x2
	isb

	mrs   x2, ICC_SRE_EL2
     // SRE & disable IRQ/FIQ bypass &
     // allow EL1 access to ICC_SRE_EL1
	orr   x2, x2, #0xf
	msr   ICC_SRE_EL2, x2
	isb

     // enableGrp1NS | enableGrp1S
	mov   x2, #0x3
	msr   ICC_IGRPEN1_EL3, x2
	isb

	msr   ICC_CTLR_EL3, xzr
	isb

     // NonSecure ICC_CTLR_EL1
	msr   ICC_CTLR_EL1, xzr
	isb

     // Non-Secure access to ICC_PMR_EL1
	mov   x2, #0x1 << 7
	msr   ICC_PMR_EL1, x2

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

