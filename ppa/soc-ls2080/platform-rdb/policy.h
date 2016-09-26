// policy.h
// 
// header file for platform security policy defines
//
// Copyright (c) 2015, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _POLICY_H
#define	_POLICY_H

 // the following defines affect the PLATFORM SECURITY POLICY

 // set this to 0x0 if secure instruction fetch from non-secure memory is allowed
 // set this to 0x1 if secure instruction fetch from non-secure memory is prohibited
 // sets SCR_EL3.SIF (bit[9])
.equ  POLICY_SIF_NS, 0x0

 // set this to 0x0 if FIQ interrupts are not reserved for EL3
 // set this to 0x1 if FIQ interrupts are reserved for EL3
 // sets SCR_EL3.FIQ (bit[2])
.equ  POLICY_FIQ_EL3, 0x1

 // set this to 0x0 if the platform is not using/responding to ECC errors
 // set this to 0x1 if ECC is being used (we have to do some init)
.equ  POLICY_USING_ECC, 0x0

 // the following affect system performance

 // set this to 0x0 to optimize PCIe write traffic
 // set this to 0x1 to optimize WRIOP packet data writes
.equ  POLICY_PERF_WRIOP, 0x0

 // the following are general system settings

 // set this to 0x0 if EL2 is Aarch32
 // set this to 0x1 if EL2 is Aarch64
 // sets SCR_EL3.RW (bit[10])
.equ  POLICY_EL2_WIDTH, 0x1

 // set this to 0x0 if EL2 is little endian (LE)
 // set this to 0x1 if EL2 is big endian (BE)
 // sets SCTLR_EL2.EE
.equ  POLICY_EL2_EE, 0x0

 // set this to 0x0 if EL1 is Aarch32
 // set this to 0x1 if EL1 is Aarch64
 // sets HCR_EL2.RW (bit[31])
.equ  POLICY_EL1_WIDTH, 0x1

 // set this to 0x0 if EL1 is little endian (LE)
 // set this to 0x1 if EL1 is big endian (BE)
 // sets SCTLR_EL1.EE
.equ  POLICY_EL1_EE, 0x0

//-----------------------------------------------------------------------------

#endif // _POLICY_H
