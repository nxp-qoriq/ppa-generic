//
// Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
//
//-----------------------------------------------------------------------------

#include "common.h"
#include "soc.h"

//-----------------------------------------------------------------------------

OUTPUT_FORMAT("elf64-littleaarch64")
OUTPUT_ARCH(aarch64)
ENTRY(_reset_vector_el3)

//-----------------------------------------------------------------------------

 // The code is position independent

SECTIONS
{
    .text . : {
        __PPA_PROG_START__ = .;
        *bootmain.64.o(.text*)
        *(.text*)
        *(.rodata*)
        __PPA_PROG_END__ = .;
    }

    .data . : {
        __DATA_START__ = .;
        *(.data*)
        __DATA_END__ = .;
    }

    .bss : ALIGN(16) {
     // Fill unused section with zero
    FILL(0) ;
        __BSS_START__ = .;
        *(.bss*)
        __BSS_END__ = .;
    }

     // Stack must be last section
    stacks (NOLOAD) : {
        __STACKS_BASE__ = .;
    }

     // Place Stack End at PPA Limit to allow max Stack Depth

    ASSERT(. <= PPA_SIZE, "Not sufficient space") . = PPA_SIZE ;

    __PPA_END__ = PPA_SIZE;

    __STACKS_TOP__ = ROUNDDOWN(__PPA_END__, CORE_SP_ALIGNMENT);

    __STACK_SIZE__ = __STACKS_TOP__ - __STACKS_BASE__ ;

     // Divide Stack Equally Between Cores.
     // Exact integer division is not neccesary.
     // STACK PER CPU must be CORE_SP_ALIGNMENT to avoid
     // Stack alignment fault.

    __STACK_SIZE_PER_CPU_ = ROUNDDOWN((__STACK_SIZE__ / CPU_MAX_COUNT), CORE_SP_ALIGNMENT);

     // Actual stack size must be g/e than required
    ASSERT( __STACK_SIZE_PER_CPU_ >= REQ_CORE_STACK_SIZE , "Not enough space left for minimum required stack") __BSS_SIZE__ = SIZEOF(.bss);

}

//-----------------------------------------------------------------------------





