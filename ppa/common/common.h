//
// Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
//
//-----------------------------------------------------------------------------

#ifndef _COMMON_H
#define _COMMON_H

 // Define the minimum required Stack. Linker File tries to allocate as much
 // as possible to stack

#define REQ_CORE_STACK_SIZE 0x1000

 // SP is aligned to 16bytes for armv8 aarch64
#define CORE_SP_ALIGNMENT	16

 // ROUNDDOWN e to b bytes boundary.
 // b must be power of two

#define ROUNDDOWN(e, b)  (e & ~(b - 1))

 // Checks e is aligned to b bytes boundary.
 // b must be power of 2

#define IS_ALIGNED(e, b) (!(e & (b - 1)))

 // PPA Size = 2MB
#define PPA_SIZE	(1 << 21)

#endif






