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

 // smc-sip function id's - these are "fast", non-preemptible functions

 // this function returns the number of implemented smc-sip functions
.equ  SIP_COUNT_ID,         0xFF00

 // this function will return to EL2 @ Aarch32
 // in:  x0 = start address for EL2 @ Aarch32
 //      x1 = 0, EL2 in LE (little-endian)
 //      x1 = 1, EL2 in BE (big-endian)
.equ  SIP_EL2_2_AARCH32_ID, 0x0020

//-----------------------------------------------------------------------------

#endif // _SMC_H
