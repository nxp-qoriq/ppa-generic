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

.equ  MEMBANK_LAST_BANK_MASK, 0x8

//-----------------------------------------------------------------------------

.ltorg

//-----------------------------------------------------------------------------

.align 3
_test_psci:
    bl    run_test

end_test:
    b     end_test

run_test:
    mov   x19, xzr
1:
     // test for return value in x0
    ldr   x0, =SIP_MEMBANK_64
    mov   x1, x19
    smc   0x0
    nop
    nop
    nop
     // check the return value in x0 to see if this was the last bank
    tst   x0, #MEMBANK_LAST_BANK_MASK
    b.eq  2f
     // not the last bank, so increment bank number and go again
    add   x19, x19, #1
    b     1b
2:
    ret

//-----------------------------------------------------------------------------

