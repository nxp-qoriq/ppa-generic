// smc.h
// 
// header file for secure fw
//
// Copyright (c) 2016, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _SMC_H
#define	_SMC_H

//-----------------------------------------------------------------------------

#define  SMC_EL2_IS_LE    0x0
#define  SMC_EL2_IS_BE    0x1

#define SMC_AARCH32_MODE  0x1
#define SMC_AARCH64_MODE  0x0

 // must be kept in synch with SmcDataStruc
 // Note: size must be a quad-word multiple
#define SMC_DATA_OFFSET   0xc0

 // function return values
#define  SMC_SUCCESS         0
#define  SMC_UNIMPLEMENTED  -1
#define  SMC_INVALID        -2
#define  SMC_BAD_PARM       -3
#define  SMC_INVALID_EL     -4

//-----------------------------------------------------------------------------

#define  SMC_FUNCTION_MASK  0xFFFF

 // smc function id's - these are "fast", non-preemptible functions

 // this function returns the number of implemented smc-sip functions
#define  SIP_COUNT_ID     0xC200FF00

 // this function returns the number of implemented smc-arch functions
#define  ARCH_COUNT_ID    0xC000FF00

 // this function will return to EL2 @ Aarch32
 // in:  x0 = function id
 //      x1 = start address for EL2 @ Aarch32
 //      x2 = first parameter to EL2
 //      x3 = second parameter to EL2
 //      x4 = 0, EL2 in LE (little-endian)
 //      x4 = 1, EL2 in BE (big-endian)
#define  ARCH_EL2_2_AARCH32_ID  0xC000FF04

//-----------------------------------------------------------------------------

.equ REGISTER_OBFUSCATE, 0xA5A5A5A5A5A5A5A5

#endif // _SMC_H
