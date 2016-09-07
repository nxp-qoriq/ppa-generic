// 
// ARM v8 AArch64 Secure Monitor
//
// Copyright (c) 2015-2016, Freescale Semiconductor, Inc. All rights reserved.
//

// This code includes:
// GICv2 EL3 initialization

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "soc.h"
#include "soc.mac"

//-----------------------------------------------------------------------------

.global _gic_init_percpu
.global _gic_init_common

//-----------------------------------------------------------------------------

 // this function performs one-time gic init, executed by the boot core
 // out: none
 // uses x0, x1, x2, x3
_gic_init_common:

    Get_GICD_Base_Addr x0

    mov   w2, #0x3                   // EnableGrp0 | EnableGrp1
    str   w2, [x0, GICD_CTLR_OFFSET] // Secure GICD_CTLR
    ldr   w2, [x0, GICD_TYPER_OFFSET]
    and   w3, w2, #0x1f              // ITLinesNumber
    cbz   w3, 1f                     // No SPIs
    add   x1, x0, (GICD_IGROUPR0_OFFSET + 4)
    mov   w2, #~0                    // Config SPIs as Grp1
0:  
    str   w2, [x1], #0x4
    sub   w3, w3, #0x1
    cbnz  w3, 0b
1:
      ret

//-----------------------------------------------------------------------------

 // this function performs per-cpu gic init, executed by each core
 // out: none
 // uses x0, x1, x2, x3
_gic_init_percpu:

     // initialize distributor

    Get_GICD_Base_Addr x0

    mov   w2, #~0                         // Config SGIs and PPIs as Grp1
    str   w2, [x0, GICD_IGROUPR0_OFFSET]  // GICD_IGROUPR0
    mov   w2, #0x1                        // Enable SGI 0
    str   w2, [x0, GICD_ISENABLERn_OFFSET]

     // initialize Cpu Interface

    Get_GICC_Base_Addr x1
    mov   w2, #0x1e7                      // Disable IRQ/FIQ Bypass &
                                          //  enable Ack Group1 Interrupt &
                                          //  enableGrp0 & EnableGrp1
    str   w2, [x1, GICC_CTLR_OFFSET]      // Secure GICC_CTLR
    mov   w2, #0x1 << 7                   // Non-Secure access to GICC_PMR
    str   w2, [x1, GICC_PMR_OFFSET]
    ret

//-----------------------------------------------------------------------------

