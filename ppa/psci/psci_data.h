
// 
// ARM v8 AArch64 PSCI v0.2, v1.0
//
// Copyright (c) 2013-2016 Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// cpu data areas

//-----------------------------------------------------------------------------

.align 3
cpu0_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu1_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr

.if (CPU_MAX_COUNT > 2)
cpu2_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu3_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
.endif

.if (CPU_MAX_COUNT > 4)
cpu4_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu5_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu6_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu7_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
.endif

.if (CPU_MAX_COUNT > 8)
cpu8_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu9_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu10_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu11_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
.endif

.if (CPU_MAX_COUNT > 12)
cpu12_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu13_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu14_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
cpu15_data:
    .8byte  0x0  // cpu state
    .8byte  0x0  // spsr_el3
    .8byte  0x0  // context_id
    .8byte  0x0  // start addr
    .8byte  0x0  // link addr
    .8byte  0x0  // GICC_CTLR 
    .8byte  0x0  // abort flag 
    .8byte  0x0  // sctlr_elx
    .8byte  0x0  // cpuectlr
.endif

 // if assembly stops here, you need to add more data areas
.if (CPU_MAX_COUNT > 16)
.err
.endif

//-----------------------------------------------------------------------------

