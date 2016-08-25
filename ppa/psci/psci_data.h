
// 
// ARM v8 AArch64 PSCI v0.2, v1.0
//
// Copyright (c) 2013-2016 Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// per-cpu data areas

//-----------------------------------------------------------------------------

 // these fields MUST be 64-bit width - the access macros depend on it!
 // if you add/subtract a field, you must adjust CORE_DATA_OFFSET in psci.h
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
    .8byte  0x0  // AUX_06
    .8byte  0x0  // AUX_07
.endm

//-----------------------------------------------------------------------------

.align 3
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

