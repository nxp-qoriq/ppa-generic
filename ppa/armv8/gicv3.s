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

.equ  GICR_ISENABLER0_SGI0,  0x1
.equ  GICR_WAKER_PROCSLEEP,  0x2
.equ  GICR_WAKER_CHILDSLEEP, 0x4

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
 // in:   x0 = core mask lsb
 // out:  none
 // uses: x0, x2, x1, x3, x4, x5, x6, x7
_gic_init_percpu:
    mov   x7, x30
    mov   x6, x0

     // x6 = core mask lsb

    mov   x0, x6
    bl    _get_gic_rd_base
    mov   x5, x0

     // x5 = gic rd base addr for this core
     // x6 = core mask lsb

     // clear ProcessorSleep
    ldr   w3, [x5, #GICR_WAKER_OFFSET]
    bic   w3, w3, #GICR_WAKER_PROCSLEEP
    str   w3, [x5, #GICR_WAKER_OFFSET]
     
     // poll on ChildrenAsleep to go low
1:
    ldr   w3, [x5, #GICR_WAKER_OFFSET]
    tst   w3, #GICR_WAKER_CHILDSLEEP
    b.ne  1b

    mov   x0, x6
    bl    _get_gic_sgi_base
    mov   x5, x0

     // x5 = gic sgi base addr for this core
     // x6 = core mask lsb

     // set all PPI/SGI  as group1 
     // except set SGI15 as group0
    mvn   w0,  wzr
    bic   w0,  w0, #GICR_IGROUPR0_SGI15
    str   w0,  [x5, #GICR_IGROUPR0_OFFSET]
	str   wzr, [x5, #GICR_IGRPMODR0_OFFSET]

     // enable SGI 0
	mov   w0, #GICR_ISENABLER0_SGI0
	str   w0, [x5, #GICR_ISENABLER0_OFFSET]

     // enable system register access @ EL3
     // disable IRQ/FIQ bypass @ EL3
     // allow el2 access
    mov   x1, #0xF
	msr   ICC_SRE_EL3, x1
    isb

     // enable system register access @ EL2
     // disable IRQ/FIQ bypass @ EL2
     // allow el1 access
    mov   x1, #0xF
	msr   ICC_SRE_EL2, x1

     // enable grp1 NS | enable grp1 S
    mov   x2, #0x3
	msr   ICC_IGRPEN1_EL3, x2

     // initialize the el1 control register
	msr   ICC_CTLR_EL1, xzr

     // set a default priority filter
    mov   x2, #ICC_PMR_EL1_P_FILTER
	msr   ICC_PMR_EL1, x2

     // setup ICC_CTLR_EL3
    mrs   x2, ICC_CTLR_EL3
    bic   x2, x2, #ICC_CTLR_EL3_RM
    bic   x2, x2, #ICC_CTLR_EL3_EOIMODE_EL3
    orr   x2, x2, #ICC_CTLR_EL3_PMHE
    msr   ICC_CTLR_EL3, x2

    isb
    mov  x30, x7
    ret

//-----------------------------------------------------------------------------

