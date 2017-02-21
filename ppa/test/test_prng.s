// 
// ARM v8 AArch64 Bootrom 
//
// Copyright (c) 2013-2014, Freescale Semiconductor, Inc. All rights reserved.
//

// This romcode includes:
// (1) PSCI test code (executes @ EL2)

//-----------------------------------------------------------------------------

  .section .text, "ax"
 
//-----------------------------------------------------------------------------
    
#include "soc.h"
#include "psci.h"
#include "smc.h"

//-----------------------------------------------------------------------------

  .global _test_psci

//-----------------------------------------------------------------------------

.align 3
.equ  PSCI_V_MAJOR,   0x00000000
.equ  PSCI_V_MINOR,   0x00000002

//-----------------------------------------------------------------------------

.ltorg

//-----------------------------------------------------------------------------

.align 3
_test_psci:
    b  _test_psci

     // call psci version to trigger the end of boot services
    ldr  x0, =PSCI_VERSION_ID
    smc  0x0
    nop
    nop
    nop
     // test for return value in x0

     // call the prng 64-bit interface for a 32-bit seed
     // x0 = function id
     // x1 = 0, 32-bit seed returned
     // 32-bit prng seed is returned in x1
    ldr  x0, =SIP_PRNG_64
    mov  x1, xzr
    smc  0x0
    nop
    nop
    nop
     // test for return value in x1

     // call the prng 64-bit interface for a 64-bit seed
     // x0 = function id
     // x1 = 1, 64-bit seed returned
     // 64-bit prng seed is returned in x1
    ldr  x0, =SIP_PRNG_64
    mov  x1, #1
    smc  0x0
    nop
    nop
    nop
     // test for return value in x1

end_test:
    b  end_test

//-----------------------------------------------------------------------------

