// 
// ARM v8 AArch64 Secure Monitor
//
// Copyright (c) 2015-2016, Freescale Semiconductor, Inc. All rights reserved.
//

// This code includes:
// ARM v8 specific functions

//-----------------------------------------------------------------------------

.section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"
#include "soc.h"
#include "psci.h"
#include "policy.h"

//-----------------------------------------------------------------------------

.global _flush_dcache_all
.global _flush_L1_dcache
.global _set_tcr
.global _is_EL2_supported
.global _set_spsr_4_exit
.global _set_endian_4_exit
.global _insert_endian_el2
.global _insert_endian_el1
.global _get_caller_EL
.global _init_core_EL3
.global _init_core_EL2
.global _init_core_EL1
.global _set_EL3_vectors

//-----------------------------------------------------------------------------

.equ TCR_EL3_IRGN_MASK,      0x300
.equ TCR_EL3_ORGN_MASK,      0xC00
.equ TCR_EL3_IRGN_CACHEABLE, 0x100
.equ TCR_EL3_ORGN_CACHEABLE, 0x400

//-----------------------------------------------------------------------------

 // this function cleans and invalidates all levels of the dcache
 // in:  none
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11

_flush_dcache_all:
    mov    x0, #0
    b      dcache_all_u

flush_dcache_level_u:
    lsl    x8, x0, #1
    msr    csselr_el1, x8           // select cache level
    isb                             // sync change of cssidr_el1
    mrs    x6, ccsidr_el1           // read the new cssidr_el1
    and    x2, x6, #7               // x2 <- log2(cache line size)-4
    add    x2, x2, #4               // x2 <- log2(cache line size)
    mov    x3, #0x3ff
    and    x3, x3, x6, lsr #3       // x3 <- max number of #ways
    clz    w5, w3                   // bit position of #ways
    mov    x4, #0x7fff
    and    x4, x4, x6, lsr #13      // x4 <- max number of #sets

     // x8 <- cache level << 1
     // x2  <- line length offset
     // x3  <- number of cache ways - 1
     // x4  <- number of cache sets - 1
     // x5  <- bit position of #ways

loop_set_u:
    mov    x6, x3                   // x6 <- working copy of #ways
loop_way_u:
    lsl    x7, x6, x5
    orr    x9, x8, x7               // map way and level to cisw value
    lsl    x7, x4, x2
    orr    x9, x9, x7               // map set number to cisw value
    tbz    w1, #0, 1f
    dc     isw, x9
    b      2f
1:  dc     cisw, x9                 // clean & invalidate by set/way
2:  subs   x6, x6, #1               // decrement the way
    b.ge   loop_way_u
    subs   x4, x4, #1               // decrement the set
    b.ge   loop_set_u
    b      next_level

dcache_all_u:
    mov    x1, x0
    dsb    sy
    mrs    x10, clidr_el1           // read clidr_el1
    lsr    x11, x10, #24
    and    x11, x11, #0x7           // x11 <- loc
    cbz    x11, end_flush_u         // if loc is 0, exit
    mov    x0, #0                   // start flush at cache level 0

     // x0  <- cache level
     // x10 <- clidr_el1
     // x11 <- loc
     // x15 <- return address

loop_level:
    lsl    x8, x0, #1
    add    x8, x8, x0               // x0 <- tripled cache level
    lsr    x8, x10, x8
    and    x8, x8, #7               // x8 <- cache type
    cmp    x8, #2
    b.lt   next_level               // skip if no cache or icache
    b      flush_dcache_level_u     // x1 = 0 flush, 1 invalidate
next_level:
    add    x0, x0, #1               // increment cache level
    cmp    x11, x0
    b.gt   loop_level

end_flush_u:
    msr    csselr_el1, xzr          // restore csselr_el1
    dsb    sy
    isb
    ret

//-----------------------------------------------------------------------------

 // clean and invalidate the L1 dcache
 // in:   none
 // out:  none
 // uses: x3-x10
_flush_L1_dcache:
    dsb  sy
     // select the L1 cache id register
    msr  csselr_el1, xzr
    isb
     // read the cache id register
    mrs  x6, ccsidr_el1
     // get the L offset
    and  x10, x6,  #7
    add  x10, x10, #4

     // extract the max way
    mov  x3, #0x3ff
    and  x3, x3, x6, lsr #3
     // get the bit position of the ways field
    clz  w5, w3

     // extract the max set
    mov  x4, #0x7fff
    and  x4, x4, x6, lsr #13

     // x3  -> number of cache ways - 1
     // x4  -> number of cache sets - 1
     // x5  -> bit position of ways
     // x10 -> L offset

loop_set:
     // load the working copy of the max way
    mov  x6, x3
loop_way:
     // insert #way and level to data reg
    lsl  x7, x6, x5
    orr x9, xzr, x7
     // insert #set to data reg
    lsl  x7, x4, x10
    orr  x9, x9, x7

     // clean and invalidate
    dc    cisw, x9
     // decrement the way
    subs  x6, x6, #1
    b.ge  loop_way
     // decrement the set
    subs  x4, x4, #1
    b.ge  loop_set

    isb
    ret

//-----------------------------------------------------------------------------

 // this function sets the TCR_EL3 register
 // in:  none
 // out: none
 // uses x0, x1, x2
_set_tcr:

     // read current tcr    
    mrs   x2, tcr_el3
    mov   x0, x2

     // clear the irgn bits
    ldr   x1, =TCR_EL3_IRGN_MASK
    bic   x0, x0, x1
     // clear the orgn bits
    ldr   x1, =TCR_EL3_ORGN_MASK
    bic   x0, x0, x1

     // insert inner cacheable
    ldr   x1, =TCR_EL3_IRGN_CACHEABLE
    orr   x0, x0, x1
     // insert outer cacheable
    ldr   x1, =TCR_EL3_ORGN_CACHEABLE
    orr   x0, x0, x1

     // write back the result if different
    cmp   x0, x2
    b.eq  1f
    msr   tcr_el3, x0
    isb
1:
    ret

//-----------------------------------------------------------------------------

 // this function sets the spsr value for a core exiting
 // from EL3 - if the hw supports EL2, then the core is
 // delivered to EL2, else it is delivered to EL1
 // in:  none
 // out: x0 = #CORE_EL2, if core going to EL2, else
 //      x0 = #CORE_EL1, if core going to EL1
 // uses x0, x1
_set_spsr_4_exit:

     // determine if we have hw support for EL2
    ldr  x1, =ID_AA64PFR0_MASK_EL2
    mrs  x0, id_aa64pfr0_el1
    and  x0, x0, x1

     // x0 = hw support for EL2 (0 means no support)

    cbz  x0, 1f
    mov  x1, #SPSR_FOR_EL2H
    mov  x0, #CORE_EL2
    b    2f

1:   // setup for exit to EL1
    mov  x1, #SPSR_FOR_EL1H
    mov  x0, #CORE_EL1
2:
     // set SPSR_EL3
    msr  spsr_el3, x1
    isb
    ret

//-----------------------------------------------------------------------------

 // this function determines if there is hw support for EL2
 // in:  none
 // out: x0 == 0, no EL2 support in hw
 //      x0 != 0, the hw supports EL2
 // uses x0, x1
_is_EL2_supported:

     // determine if we have hw support for EL2
    ldr  x1, =ID_AA64PFR0_MASK_EL2
    mrs  x0, id_aa64pfr0_el1
    and  x0, x0, x1

    ret

//-----------------------------------------------------------------------------

 // this function determines the endianness needed for a bootcore exit from el3,
 // and sets it in the appropriate sctlr_el2/sctlr_el1
 // in:  x0 = CORE_EL2, or CORE_EL1
 // out: none
 // uses x0, x1
_set_endian_4_exit:

    mov  x1, #CORE_EL2
    cmp  x0, x1
    b.ne 3f

     // set endianness for el2
    ldr  x1, =POLICY_EL2_EE
    cmp  x1, xzr
    b.ne 1f

     // set el2 EE = LE
    mrs  x0, sctlr_el2
    mov  x1, #SCTLR_EE_MASK
    bic  x0, x0, x1
    b    2f
1:
     // set el2 EE = BE
    mrs  x0, sctlr_el2
    mov  x1, #SCTLR_EE_MASK
    orr  x0, x0, x1
2:
     // writeback sctlr_el2
    msr  sctlr_el2, x0
    b    6f
3:
     // set endianness for el1
    ldr  x1, =POLICY_EL1_EE
    cmp  x1, xzr
    b.ne 4f

     // set el1 EE = LE
    mrs  x0, sctlr_el1
    mov  x1, #SCTLR_EE_MASK
    bic  x0, x0, x1
    b    5f
4:
     // set el1 EE = BE
    mrs  x0, sctlr_el1
    mov  x1, #SCTLR_EE_MASK
    orr  x0, x0, x1
5:
     // writeback sctlr_el1
    msr  sctlr_el1, x0
6:
    ret

 //----------------------------------------------------------------------------

 // this function extracts the endian bit from a saved SCTLR_ELx register,
 // and transfers it to sctlr_el2
 // in:  x0 = sctlr value with endianness to preserve
 // out: none
 // uses x0, x1, x2
_insert_endian_el2:

    mov  x1, #SCTLR_EE_MASK
    mrs  x2, sctlr_el2

     // extract endian bit from saved sctlr
    and  x0, x0, x1
     // clear endian bit in target sctlr
    bic  x2, x2, x1
    
     // insert endian bit into target sctlr
    orr  x2, x2, x0
     // writeback sctlr_el2
    msr  sctlr_el2, x2
    ret

 //----------------------------------------------------------------------------

 // this function extracts the endian bit from a saved SCTLR_ELx register,
 // and transfers it to sctlr_el1
 // in:  x0 = sctlr value with endianness to preserve
 // out: none
 // uses x0, x1, x2
_insert_endian_el1:

    mov  x1, #SCTLR_EE_MASK
    mrs  x2, sctlr_el1

     // extract endian bit from saved sctlr
    and  x0, x0, x1
     // clear endian bit in target sctlr
    bic  x2, x2, x1
    
     // insert endian bit into target sctlr
    orr  x2, x2, x0
     // writeback sctlr_el1
    msr  sctlr_el1, x2
    ret

 //----------------------------------------------------------------------------

 // this function returns the EL-level of the caller
 // in:  none
 // out: x0=0, caller is EL0
 //      x0=1, caller is EL1
 //      x0=2, caller is EL2
 //      x0=3, caller is EL3
 // uses: x0, x1
_get_caller_EL:
     // get the caller's EL from SPSR_EL3
    mrs   x1, spsr_el3
    mov   x0, xzr
    bfxil x0, x1, #2, #2
    ret

 //----------------------------------------------------------------------------

 // in:   none
 // uses: x0, x1, x2
_init_core_EL3:
    mov  x2, x30

     // initialize SCTLR_EL3
     // M,   bit [0]
     // A,   bit [1]
     // C,   bit [2]
     // SA,  bit [3]
     // I,   bit [12]
     // WXN, bit [19]
     // EE,  bit [25]
    mrs  x1, SCTLR_EL3
     // make sure icache is enabled
    orr  x0, x1, #SCTLR_I_MASK
     // make sure SA is enabled
    orr  x0, x0, #SCTLR_SA_MASK
    cmp  x0, x1
    b.eq 1f
     // writeback if we changed the value
    msr  SCTLR_EL3, x0
1:

     // initialize CPUECTLR
     // SMP, bit [6] = 1
    mrs  x1, S3_1_c15_c2_1
    orr  x1, x1, #0x40
    msr S3_1_c15_c2_1, x1

     // initialize CPTR_EL3
    msr  CPTR_EL3, xzr

     // determine if hw supports el2
    bl   _is_EL2_supported

     // x0 = EL2 support (0=none)

     // initialize SCR_EL3
     // NS,   bit[0]  = 1
     // IRQ,  bit[1]  = 0
     // FIQ,  bit[2]  = ?
     // EA,   bit[3]  = 0
     // Res1, bit[4]  = 1
     // Res1, bit[5]  = 1
     // SMD,  bit[7]  = 0
     // HCE,  bit[8]  = ?
     // SIF,  bit[9]  = ?
     // RW,   bit[10] = ?
     // ST,   bit[11] = 0
     // TWI,  bit[12] = 0
     // TWE,  bit[13] = 0
    mov  x1, #0x31
    cbz  x0, 2f
     // set HCE if el2 supported in hw
    orr  x1, x1, #0x100
2:
    ldr  x0, =POLICY_EL2_WIDTH
    cbz  x0, 3f
    orr  x1, x1, #0x400
3:
    ldr  x0, =POLICY_SIF_NS
    cbz  x0, 4f
    orr  x1, x1, #0x200
4:
    ldr  x0, =POLICY_FIQ_EL3
    cbz  x0, 5f
    orr  x1, x1, #0x4
5:
    msr  SCR_EL3, x1

     // initialize the value of ESR_EL3 to 0x0
    msr ESR_EL3, xzr

     // set the counter frequency
    ldr  x0, =COUNTER_FRQ_EL0
    msr  cntfrq_el0, x0

     // synchronize the system register writes
    isb

     // some of these bits are potentially cached in the tlb
    tlbi alle3
    dsb  sy
    isb
 
    mov  x30, x2
    ret

 //----------------------------------------------------------------------------

 // this function provides some basic core initialization at the EL2 level
 // in:  none
 // out: none
 // uses x0, x1
_init_core_EL2:

     // initialize hcr_el2
    mov  x1, xzr
    ldr  x0, =POLICY_EL1_WIDTH
    cbz  x0, 1f
    orr  x1, x1, #HCR_EL2_RW_AARCH64
1:
    msr  hcr_el2, x1

     // initialize sctlr_el2
    mrs  x0, sctlr_el2

     // clear C, A, M bits
    bic  x1, x0, #SCTLR_C_A_M_MASK
     // set SA
    orr  x1, x1, #SCTLR_SA_MASK
     // clear WXN bit
    bic  x1, x1, #SCTLR_WXN_MASK
     // disable icache
    bic  x1, x1, #SCTLR_I_MASK
     // clear EE
    bic  x1, x1, #SCTLR_EE_MASK
     // writeback new value if changed
    cmp  x1, x0
    b.eq 2f
    msr  sctlr_el2, x1

2:
     // initialize cptr_el2
    ldr  x0, =CPTR_EL2_RES1_MASK
    msr  cptr_el2, x0

     // synchronize the system register writes
    isb

     // some of these bits are potentially cached in the tlb
    tlbi alle3
    dsb  sy
    isb    
    ret

 //----------------------------------------------------------------------------

 // this function provides some basic core initialization at the EL1 level
 // in:  none
 // out: none
 // uses x0, x1
_init_core_EL1:

     // initialize sctlr_el1
    mrs  x0, sctlr_el1

     // clear C, A, M bits
    bic  x1, x0, #SCTLR_C_A_M_MASK
     // set SA
    orr  x1, x1, #SCTLR_SA_MASK
     // clear WXN bit
    bic  x1, x1, #SCTLR_WXN_MASK
     // disable icache
    bic  x1, x1, #SCTLR_I_MASK
     // clear EE
    bic  x1, x1, #SCTLR_EE_MASK
     // writeback new value if changed
    cmp  x1, x0
    b.eq 2f
    msr  sctlr_el1, x1

2:
     // synchronize the system register writes
    isb

     // some of these bits are potentially cached in the tlb
    tlbi alle3
    dsb  sy
    isb    
    ret

 //----------------------------------------------------------------------------

 // this function sets the value in VBAR_EL3
 // out: none
 // uses x0
_set_EL3_vectors: 

    adr  x0, _el3_vector_base
    msr  VBAR_EL3, x0
    ret

 //----------------------------------------------------------------------------
 //----------------------------------------------------------------------------
 //----------------------------------------------------------------------------

