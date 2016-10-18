
// 
// ARM SMC Calling Convention
//
// Copyright (c) 2013-2016 Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// per-cpu smc data areas

//-----------------------------------------------------------------------------

 // these fields MUST be 64-bit width - the access macros depend on it!
 // if you add/subtract a field, you must adjust SMC_DATA_OFFSET in smc.h
.macro SmcDataStruc
    .8byte  0x0  // execution mode flag (0=aarch64, 1=aarch32)
    .8byte  0x0  // x0
    .8byte  0x0  // x1
    .8byte  0x0  // x2
    .8byte  0x0  // x3
    .8byte  0x0  // x4
    .8byte  0x0  // x5
    .8byte  0x0  // x6
    .8byte  0x0  // x7
    .8byte  0x0  // x8
    .8byte  0x0  // x9
    .8byte  0x0  // x10
    .8byte  0x0  // x11
    .8byte  0x0  // x12
    .8byte  0x0  // x13
    .8byte  0x0  // x14
.endm

//-----------------------------------------------------------------------------

.align 4
_smc0_data:
     // core 0 data
    SmcDataStruc

     // core 1 data
    SmcDataStruc

.if (CPU_MAX_COUNT > 2)
     // core 2 data
    SmcDataStruc
     // core 3 data
    SmcDataStruc
.endif

.if (CPU_MAX_COUNT > 4)
     // core 4 data
    SmcDataStruc
     // core 5 data
    SmcDataStruc
     // core 6 data
    SmcDataStruc
     // core 7 data
    SmcDataStruc
.endif

.if (CPU_MAX_COUNT > 8)
     // core 8 data
    SmcDataStruc
     // core 9 data
    SmcDataStruc
     // core 10 data
    SmcDataStruc
     // core 11 data
    SmcDataStruc
.endif

.if (CPU_MAX_COUNT > 12)
     // core 12 data
    SmcDataStruc
     // core 13 data
    SmcDataStruc
     // core 14 data
    SmcDataStruc
     // core 15 data
    SmcDataStruc
.endif

 // if assembly stops here, you need to add more smc data areas
.if (CPU_MAX_COUNT > 16)
.err
.endif

//-----------------------------------------------------------------------------

