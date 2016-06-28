// 
// ARM v8 AArch64
//
// Copyright (c) 2015-2016 Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// functions pertaining to the LS2080 SOC

//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"
#include "soc.h"
#include "soc.mac"
#include "psci.h"
#include "policy.h"

//-----------------------------------------------------------------------------

.global _soc_sys_reset
.global _soc_ck_disabled
.global _soc_set_start_addr
.global _soc_get_start_addr
.global _soc_core_release
.global _soc_core_rls_wait

.global _get_core_mask_lsb
.global _get_current_mask

.global _soc_init_start
.global _soc_init_finish
.global _is_mpidr_valid
.global _set_platform_security
.global _soc_core_restart

.global _soc_core_entr_stdby
.global _soc_core_exit_stdby
.global _soc_core_entr_pwrdn
.global _soc_core_exit_pwrdn
.global _soc_clstr_entr_stdby
.global _soc_clstr_exit_stdby
.global _soc_clstr_entr_pwrdn
.global _soc_clstr_exit_pwrdn
.global _soc_sys_entr_stdby
.global _soc_sys_exit_stdby
.global _soc_sys_entr_pwrdn
.global _soc_sys_exit_pwrdn
.global _soc_core_entr_off
.global _soc_core_exit_off
.global _soc_core_phase1_off
.global _soc_core_phase2_off
.global _soc_core_phase1_clnup
.global _soc_core_phase2_clnup

//-----------------------------------------------------------------------------

 // register offsets
.equ BOOTLOCPTRL_OFFSET,    0x400
.equ BOOTLOCPTRH_OFFSET,    0x404
.equ COREDISR_OFFSET,       0x94
.equ RST_RSTCR_OFFSET,      0x0
.equ RST_RSTRQMR1_OFFSET,   0x10
.equ RST_RSTRQSR1_OFFSET,   0x18
.equ BRR_OFFSET,            0x60

 // bit masks
.equ RSTCR_RESET_REQ,       0x2
.equ RSTRQSR1_SWRR,         0x800

.equ RESET_RETRY_CNT,       800

.equ TZPC_BASE,              0x02200000
.equ TZPCDECPROT_0_SET_BASE, 0x02200804
.equ TZPCDECPROT_1_SET_BASE, 0x02200810
.equ TZPCDECPROT_2_SET_BASE, 0x0220081C

.equ TZASC_REGION_ATTRIBUTES_0_0, 0x01100110
.equ TZASC_REGION_ATTRIBUTES_0_1, 0x01110110
.equ TZASC_REGION_ID_ACCESS_0_0,  0x01100114
.equ TZASC_REGION_ID_ACCESS_0_1,  0x01110114

 // retry count for releasing cores from reset - should be > 0
.equ  CORE_RELEASE_CNT,    800 

 // retry count for core restart
.equ  RESTART_RETRY_CNT,  3000

//-----------------------------------------------------------------------------

 // this function starts the initialization tasks of the soc, using secondary cores
 // if they are available
 // in: 
 // out: 
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10
_soc_init_start:
    mov   x10, x30

     // make sure the personality has been established by releasing cores
     // that are marked "to-be-disabled" from reset
    bl  release_disabled  // 0-3

     // init the task flags
    bl  init_task_flags   // 0-1

     // save start address
    bl  _soc_get_start_addr   // 0-2
    adr x1, saved_bootlocptr
    str x0, [x1]

     // see if we are initializing ocram
    ldr x0, =POLICY_USING_ECC
    cbz x0, 1f
     // initialize the OCRAM for ECC

     // get a secondary core to initialize the upper half of ocram
    bl  _find_core      // 0-4
    cbz x0, 2f
    bl  init_task_1     // 0-4   
5:
     // wait til task 1 has started
    bl  get_task1_start // 0-1
    cbnz x0, 4f
    b    5b
4:
     // get a secondary core to initialize the lower
     // half of ocram
    bl  _find_core      // 0-4
    cbz x0, 3f
    bl  init_task_2     // 0-4
6:
     // wait til task 2 has started
    bl  get_task2_start // 0-1
    cbnz x0, 7f
    b    6b
2:
     // there are no secondary cores available, so the
     // boot core will have to init upper ocram
    bl  _ocram_init_upper // 0-9
3:
     // there are no secondary cores available, so the
     // boot core will have to init lower ocram
    bl  _ocram_init_lower // 0-9
    b   1f
7:
     // set SCRATCHRW7 to 0x0
    ldr  x0, =DCFG_SCRATCHRW7_OFFSET
    mov  x1, xzr
    bl   _write_reg_dcfg

     // clear bootlocptr
    mov  x0, xzr
    bl    _soc_set_start_addr

1:
    mov   x30, x10
    ret

//-----------------------------------------------------------------------------

 // this function completes the initialization tasks of the soc
 // in: 
 // out: 
 // uses x0, x1, x2, x3, x4
_soc_init_finish:
    mov   x4, x30

     // are we initializing ocram?
    ldr x0, =POLICY_USING_ECC
    cbz x0, 4f

     // if the ocram init is not completed, wait til it is
1:
    bl   get_task1_done
    cbnz x0, 2f
    wfe
    b    1b    
2:
    bl   get_task2_done
    cbnz x0, 3f
    wfe
    b    2b    
3:
     // set the task 1 core state to IN_RESET
    bl   get_task1_core
    cbz  x0, 5f
     // x0 = core mask lsb of the task 1 core
    mov  w1, #CORE_IN_RESET
    saveCoreData x0 x1 CORE_STATE_DATA
5:
     // set the task 2 core state to IN_RESET
    bl   get_task2_core
    cbz  x0, 4f
     // x0 = core mask lsb of the task 2 core
    mov  w1, #CORE_IN_RESET
    saveCoreData x0 x1 CORE_STATE_DATA
4:
     // restore bootlocptr
    adr  x1, saved_bootlocptr
    ldr  x0, [x1]
    bl    _soc_set_start_addr

    mov   x30, x4
    ret

//-----------------------------------------------------------------------------

 // write a register in the DCFG block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2
_write_reg_dcfg:
    ldr  x2, =DCFG_BASE_ADDR
    str  w1, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the DCFG block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
_read_reg_dcfg:
    ldr  x2, =DCFG_BASE_ADDR
    ldr  w1, [x2, x0]
    mov  w0, w1
    ret

//-----------------------------------------------------------------------------

 // this function returns the bit mask corresponding to the mpidr_el1 value.
 // the mask is returned in w0.
 // this bit mask references the core in the SoC registers such as
 // BRR, COREDISABLEDSR where the LSB represents core0
 // in:   x0  - mpidr_el1 value for the core
 // out:  w0  = core mask (non-zero)
 //       w0  = 0 for error (bad input mpidr value)
 // uses x0, x1, x2
_get_core_mask_lsb:
     // generate a lsb-based mask for the core - this algorithm assumes 2 cores
     // per cluster, and must be adjusted if that is not the case
     // SoC core = ((cluster << 1) + core)
     // mask = (1 << SoC core)
    mov   w1, wzr
    mov   w2, wzr
    bfxil w1, w0, #8, #8  // extract cluster
    bfxil w2, w0, #0, #8  // extract cpu #

     // error checking
    cmp   w1, #CLUSTER_COUNT
    b.ge  1f
    cmp   w2, #CPU_PER_CLUSTER
    b.ge  1f

    lsl   w1, w1, #1
    add   w1, w1, w2
    mov   w2, #0x1
    lsl   w0, w2, w1
    ret

1:
    mov   w0, wzr
    ret

//-----------------------------------------------------------------------------

 // this function returns an mpidr value for a core, given a core_mask_lsb
 // in:  x0 = core mask lsb
 // out: x0 = affinity2:affinity1:affinity0, where affinity is 8-bits
 // uses x0, x1
get_mpidr_value:

    mov  w1, wzr
    tst  x0, #1
    b.eq 1f
    orr  w1, w1, #1

1:
     // extract the cluster number
    lsr  w0, w0, #1
    orr  w0, w1, w0, lsl #8

    ret

//-----------------------------------------------------------------------------

 // this function returns the lsb bit mask corresponding to the current core
 // the mask is returned in w0.
 // this bit mask references the core in the SoC registers such as
 // BRR, COREDISR where the LSB represents core0
 // in:   none
 // out:  w0 = core mask
 // uses: x0, x1, x2
_get_current_mask:

     // get the cores mpidr value
    mrs  x1, MPIDR_EL1

     // extract the affinity 0 & 1 fields - bits [15:0]
    mov   x0, xzr
    bfxil x0, x1, #0, #16

     // generate a lsb-based mask for the core - this algorithm assumes 2 cores
     // per cluster, and must be adjusted if that is not the case
     // SoC core = ((cluster << 1) + core)
     // mask = (1 << SoC core)
    mov   w1, wzr
    mov   w2, wzr
    bfxil w1, w0, #8, #8  // extract cluster
    bfxil w2, w0, #0, #8  // extract cpu #
    lsl   w1, w1, #1
    add   w1, w1, w2
    mov   w2, #0x1
    lsl   w0, w2, w1
    ret

//-----------------------------------------------------------------------------

 // this function returns a 64-bit execution address of the core in x0
 // out: x0, address found in BOOTLOCPTRL/H
 // uses x0, x1, x2 
_soc_get_start_addr:
     // get the base address of the dcfg block
    ldr  x1, =DCFG_BASE_ADDR

     // read the 32-bit BOOTLOCPTRL register
    ldr  w0, [x1, #BOOTLOCPTRL_OFFSET]

     // read the 32-bit BOOTLOCPTRH register
    ldr  w2, [x1, #BOOTLOCPTRH_OFFSET]

     // create a 64-bit BOOTLOCPTR address
    orr  x0, x0, x2, LSL #32
    ret

//-----------------------------------------------------------------------------

 // this function writes a 64-bit address to bootlocptrh/l
 // in:  x0, 64-bit address to write to BOOTLOCPTRL/H
 // uses x0, x1, x2
 _soc_set_start_addr:
     // get the 64-bit base address of the dcfg block
    ldr  x2, =DCFG_BASE_ADDR

     // write the 32-bit BOOTLOCPTRL register
    mov  x1, x0
    str  w1, [x2, #BOOTLOCPTRL_OFFSET]

     // write the 32-bit BOOTLOCPTRH register
    lsr  x1, x0, #32
    str  w1, [x2, #BOOTLOCPTRH_OFFSET]
    ret

//-----------------------------------------------------------------------------

 // this function determines if a core is disabled via COREDISR
 // in:  w0  = core_mask_lsb
 // out: w0  = 0, core not disabled
 //      w0 != 0, core disabled
 // uses x0, x1
_soc_ck_disabled:

     // get base addr of dcfg block
    ldr  x1, =DCFG_BASE_ADDR

     // read COREDISR
    ldr  w1, [x1, #COREDISR_OFFSET]

     // test core bit
    and  w0, w1, w0
    ret

//-----------------------------------------------------------------------------

 // this function releases a secondary core from reset
 // in:   x0 = core_mask_lsb
 // out:  none
 // uses: x0, x1, x2
_soc_core_release:

     // write 1 to SCRATCHRW7
    ldr  x2, =DCFG_BASE_ADDR
    mov  w1, #1
    str  w1, [x2, #DCFG_SCRATCHRW7_OFFSET]

     // read-modify-write BRRL
    ldr  x2, =RESET_BASE_ADDR
    ldr  w1, [x2, #BRR_OFFSET]
    orr  w1, w1, w0
    str  w1, [x2, #BRR_OFFSET]
    dsb  sy
    isb

     // send event
    sev
    isb
    sev
    isb
    ret

//-----------------------------------------------------------------------------

 // this function releases a secondary core from reset, and waits til the
 // core signals it is up, or until we exceed the retry count
 // in:   x0 = core_mask_lsb
 // out:  x0 == 0, success
 //       x0 != 0, failure
 // uses: x0, x1, x2, x3, x4
_soc_core_rls_wait:
    mov  x4, x30

     // write 1 to SCRATCHRW7
    ldr  x2, =DCFG_BASE_ADDR
    mov  w1, #1
    str  w1, [x2, #DCFG_SCRATCHRW7_OFFSET]

     // read-modify-write BRRL
    ldr  x2, =RESET_BASE_ADDR
    ldr  w1, [x2, #BRR_OFFSET]
    orr  w1, w1, w0
    str  w1, [x2, #BRR_OFFSET]
    dsb  sy
    isb

     // send event
    sev
    isb

     // x0 = core_mask_lsb

    mov  x2, x0
    ldr  x3, =CORE_RELEASE_CNT

     // x2 = core_mask_lsb
     // x3 = retry count
1:
    sev
    isb
    mov  x0, x2
    getCoreData x0 CORE_STATE_DATA

     // see if the core has signaled that it is up
    cmp  x0, #CORE_RELEASED
    mov  x0, xzr
    b.eq 2f

     // see if we used up our retries
    sub  x3, x3, #1
    mov  x0, #1
    cbz  x3, 2f

     // loop back and try again
    b    1b
2:
    mov  x30, x4
    ret

//-----------------------------------------------------------------------------

 // part of CPU_ON
 // this function restarts a core shutdown via _soc_core_entr_off
 // in:  x0 = core mask lsb (of the target cpu)
 // out: x0 == 0, on success
 //      x0 != 0, on failure
 // uses x0, x1, x2, x3, x4, x5
_soc_core_restart:
    mov  x5, x30
    mov  x4, x0

     // x4 = core mask lsb

     // pgm GICD_CTLR - enable secure grp0 
    mov  x1, #GICD_BASE_ADDR
    ldr  w2, [x1, #GICD_CTLR_OFFSET]
    orr  w2, w2, #GICD_CTLR_EN_GRP_0
    str  w2, [x1, #GICD_CTLR_OFFSET]
    dsb sy
    isb
     // poll on RWP til write completes
4:
    ldr  w2, [x1, #GICD_CTLR_OFFSET]
    tst  w2, #GICD_CTLR_RWP_MASK
    b.ne 4b   

     // x1 = gicd base addr
     // x4 = core mask lsb

    mov  x0, x4
    bl   get_mpidr_value

     // x0 = mpidr of target core
     // x1 = gicd base addr
     // x4 = core mask lsb of target core

     // generate a target core for SGI 15
    mov  x2, #ICC_SGI0R_EL1_INTID
     // extract affinity 0 and insert as target list
    bfxil x2, x0, #0, #8
     // extract affinity1
    and  w3, w0, #MPIDR_AFFINITY1_MASK
    orr  x2, x2, x3, lsl #8
     // fire the SGI
    msr  ICC_SGI0R_EL1, x2

     // x1 = gicd base addr
     // x4 = core mask lsb

    ldr  x3, =RESTART_RETRY_CNT

1:
    mov  x0, x4
    getCoreData x0 CORE_STATE_DATA

    cmp  x0, #CORE_RELEASED
    b.eq 2f    

     // decrement the retry cnt and see if we're finished
    sub  x3, x3, #1
    cbnz x3, 1b

     // load '1' on failure
//    mov  x0, #1
//    b    3f 

2:
     // load '0' on success
    mov  x0, xzr
3:
    mov  x30, x5
    ret

//-----------------------------------------------------------------------------

_soc_core_entr_stdby:

    ret

//-----------------------------------------------------------------------------

_soc_core_exit_stdby:

    ret

//-----------------------------------------------------------------------------

_soc_core_entr_pwrdn:

    ret

//-----------------------------------------------------------------------------

_soc_core_exit_pwrdn:

    ret

//-----------------------------------------------------------------------------

_soc_clstr_entr_stdby:

    ret

//-----------------------------------------------------------------------------

_soc_clstr_exit_stdby:

    ret

//-----------------------------------------------------------------------------

_soc_clstr_entr_pwrdn:

    ret

//-----------------------------------------------------------------------------

_soc_clstr_exit_pwrdn:

    ret

//-----------------------------------------------------------------------------

_soc_sys_entr_stdby:

    ret

//-----------------------------------------------------------------------------

_soc_sys_exit_stdby:

    ret

//-----------------------------------------------------------------------------

_soc_sys_entr_pwrdn:

    ret

//-----------------------------------------------------------------------------

_soc_sys_exit_pwrdn:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function programs ARM core registers in preparation for shutting down
 // the core
 // in:   x0 = core_mask_lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8
_soc_core_phase1_off:
    mov  x8, x30

     // mask interrupts by setting DAIF[7:4] to 'b1111
    mrs  x1, DAIF
    ldr  x0, =DAIF_SET_MASK
    orr  x1, x1, x0
    msr  DAIF, x1 

     // disable dcache, mmu, and icache for EL1 and EL2 by clearing
     // bits 0, 2, and 12 of SCTLR_EL1 and SCTLR_EL2 (MMU, dcache, icache)
    ldr x0, =SCTLR_I_C_M_MASK
    mrs x1, SCTLR_EL1
    bic x1, x1, x0
    msr SCTLR_EL1, x1 

    mrs x1, SCTLR_EL2
    bic x1, x1, x0
    msr SCTLR_EL2, x1 

     // disable only dcache for EL3 by clearing SCTLR_EL3[2] 
    mrs x1, SCTLR_EL3
    ldr x0, =SCTLR_C_MASK
    bic x1, x1, x0      
    msr SCTLR_EL3, x1 
    isb

     // cln/inv L1 dcache
    mov  x0, #1
    bl   _cln_inv_L1_dcache

     // FIQ taken to EL3, set SCR_EL3[FIQ]
    mrs   x0, scr_el3
    orr   x0, x0, #SCR_FIQ_MASK
    msr   scr_el3, x0

    dsb  sy
    isb

    mov  x30, x8               
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function programs SoC & GIC registers in preparation for shutting down
 // the core
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8
_soc_core_phase2_off:
    mov   x8, x30

    mov  x7, x0
     // x7 = core mask lsb

     // get redistributor rd base addr for this core
    mov  x0, x7
    bl   get_gic_rd_base
    mov  x6, x0

     // get redistributor sgi base addr for this core
    mov  x0, x7
    bl   get_gic_sgi_base
    mov  x5, x0

     // x5 = gicr sgi base addr
     // x6 = gicr rd  base addr
     // x7 = core mask lsb

     // disable SGI 15 at redistributor - GICR_ICENABLER0
    mov  w3, #GICR_ICENABLER0_SGI15
    str  w3, [x5, #GICR_ICENABLER0_OFFSET]
2:
     // poll on rwp bit in GICR_CTLR
    ldr  w4, [x6, #GICR_CTLR_OFFSET]
    tst  w4, #GICR_CTLR_RWP_MASK
    b.ne 2b

     // disable GRP1 interrupts at cpu interface
    msr  ICC_IGRPEN1_EL1, xzr

     // disable GRP0 ints at cpu interface
    msr  ICC_IGRPEN0_EL1, xzr

     // program the redistributor - poll on GICR_CTLR.RWP as needed

     // define SGI 15 as Grp0 - GICR_IGROUPR0
    ldr  w4, [x5, #GICR_IGROUPR0_OFFSET]
    bic  w4, w4, #GICR_IGROUPR0_SGI15
    str  w4, [x5, #GICR_IGROUPR0_OFFSET]

     // define SGI 15 as Grp0 - GICR_IGRPMODR0
    ldr  w3, [x5, #GICR_IGRPMODR0_OFFSET]
    bic  w3, w3, #GICR_IGRPMODR0_SGI15
    str  w3, [x5, #GICR_IGRPMODR0_OFFSET]

     // set priority of SGI 15 to highest (0x0) - GICR_IPRIORITYR3
    ldr  w4, [x5, #GICR_IPRIORITYR3_OFFSET]
    bic  w4, w4, #GICR_IPRIORITYR3_SGI15_MASK
    str  w4, [x5, #GICR_IPRIORITYR3_OFFSET]

     // enable SGI 15 at redistributor - GICR_ISENABLER0
    mov  w3, #GICR_ISENABLER0_SGI15
    str  w3, [x5, #GICR_ISENABLER0_OFFSET]
3:
     // poll on rwp bit in GICR_CTLR
    ldr  w4, [x6, #GICR_CTLR_OFFSET]
    tst  w4, #GICR_CTLR_RWP_MASK
    b.ne 3b

     // program the cpu interface

     // set int priority filter - ICC_PMR_EL1
    mrs  x4, ICC_PMR_EL1
    orr  w4, w4, #ICC_PMR_EL1_P_FILTER
    msr  ICC_PMR_EL1, x4

     // enable GRP0 ints - ICC_IGRPEN0_EL1
    mov  x3, #ICC_IGRPEN0_EL1_EN
    msr  ICC_IGRPEN0_EL1, x3

    mov  x30, x8
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function performs the final steps to shutdown the core
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5
_soc_core_entr_off:
    mov  x5, x30
    mov  x3, x0

     // x3 = core mask lsb

     // get redistributor sgi base addr for this core
    mov  x0, x3
    bl   get_gic_sgi_base
    mov  x4, x0

     // x3 = core mask lsb
     // x4 = gicr sgi base addr

     // change state of core in data area
    mov  x0, x3
    mov  x1, #CORE_OFF
    saveCoreData x0 x1 CORE_STATE_DATA

     // disable EL3 icache by clearing SCTLR_EL3[12]
    mrs  x1, SCTLR_EL3
    bic  x1, x1, #SCTLR_I_MASK     
    msr  SCTLR_EL3, x1 

     // invalidate icache
    ic iallu
    dsb  sy
    isb

     // clear any pending interrupts
    mvn  w1, wzr
    str  w1, [x4, #GICR_ICPENDR0_OFFSET]

1:
     // enter low-power state by executing wfi
    wfi

     // read iar to get the interrupt id
    mrs  x2, ICC_IAR0_EL1

     // clear the interrupt
    msr  ICC_EOIR0_EL1, x2 

     // see if we got hit by SGI 15
    cmp  x2, #ICC_IAR0_EL1_SGI15
    b.ne 1b
    
     // check if core has been turned on
    mov  x0, x3 
    getCoreData x0 CORE_STATE_DATA
    cmp  x0, #CORE_PENDING
    b.ne 1b

     // if we get here, then we have exited the wfi

    mov  x30, x5
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function starts the process of starting a core back up
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5
_soc_core_exit_off:
    mov  x5, x30
    mov  x3, x0

     // x3 = core mask lsb

     // disable forwarding of GRP0 ints at cpu interface
    msr  ICC_IGRPEN0_EL1, xzr

     // get redistributor sgi base addr for this core
    mov  x0, x3
    bl   get_gic_sgi_base
    mov  x4, x0

     // x3 = core mask lsb
     // x4 = gicr sgi base addr

     // clear pending SGIs
    mvn  w1, wzr
    str  w1, [x4, #GICR_ICPENDR0_OFFSET]

     // enable icache in SCTLR_EL3
    mrs  x1, SCTLR_EL3
    orr  x1, x1, #SCTLR_I_MASK
    msr  SCTLR_EL3, x1 
    isb

    mov  x30, x5
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function cleans up from phase 1 of the core shutdown sequence
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x3
_soc_core_phase1_clnup:
    mov  x3, x30

     // x0 = core mask lsb

     // clr SCR_EL3[FIQ]
    mrs   x0, scr_el3
    bic   x0, x0, #SCR_FIQ_MASK
    msr   scr_el3, x0

    isb
    mov  x30, x3
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function cleans up from phase 2 of the core shutdown sequence
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5
_soc_core_phase2_clnup:
    mov  x5, x30
    mov  x3, x0

     // x3 = core mask lsb

     // get redistributor rd base addr for this core
    mov  x0, x3
    bl   get_gic_rd_base
    mov  x4, x0

     // get redistributor sgi base addr for this core
    mov  x0, x3
    bl   get_gic_sgi_base
    mov  x3, x0

     // x3 = gicr sgi base addr
     // x4 = gicr rd  base addr

     // disable GRP0 ints at redistributor - GICR_ICENABLER0
     // read-modify-write-read-tst
    ldr  w1, [x3, #GICR_ICENABLER0_OFFSET]
3:
    orr  w1, w1, #GICR_ICENABLER0_SGI15
    str  w1, [x3, #GICR_ICENABLER0_OFFSET]
2:
     // poll on rwp bit in GICR_CTLR
    ldr  w2, [x4, #GICR_CTLR_OFFSET]
    tst  w2, #GICR_CTLR_RWP_MASK
    b.ne 2b
    ldr  w1, [x3, #GICR_ICENABLER0_OFFSET]
    tst  w1, #GICR_ICENABLER0_SGI15
    b.ne 3b

    dsb sy
    isb

    mov  x30, x5
    ret

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

 // this function requests a reset of the entire SOC
 // in:  none
 // out: x0 = [PSCI_SUCCESS | PSCI_INTERNAL_FAILURE | PSCI_NOT_SUPPORTED]
 // uses: x0, x1, x2, x3, x4, x5, x6
_soc_sys_reset:

     // save link register
    mov  x3, x30

     // make sure the mask is cleared in the reset request mask register
    ldr  x0, =RST_RSTRQMR1_OFFSET
    mov  w1, wzr
    bl   _write_reg_reset

     // set the reset request
    ldr  x4, =RST_RSTCR_OFFSET
    mov  x0, x4
    ldr  w1, =RSTCR_RESET_REQ
    bl   _write_reg_reset

     // x4 = RST_RSTCR_OFFSET

     // just in case this address range is mapped as cacheable,
     // flush the write out of the dcaches
    ldr  x2, =RESET_BASE_ADDR
    add  x2, x2, x4
    dc   cvac, x2
    dsb  st
    isb

     // now poll on the status bit til it goes high
    ldr  x5, =RST_RSTRQSR1_OFFSET
    ldr  x4, =RSTRQSR1_SWRR
    ldr  x6, =RESET_RETRY_CNT
1:
    mov  x0, x5
    bl   _read_reg_reset
     // test status bit
    tst  x0, x4
    mov  x0, #PSCI_SUCCESS
    b.ne 2f

     // decrement retry count and test
    sub  x6, x6, #1
    cmp  x6, xzr
    b.ne 1b

     // signal failure and return
    ldr  x0, =PSCI_INTERNAL_FAILURE
2:
    mov  x30, x3
    ret

//-----------------------------------------------------------------------------

 // write a register in the RESET block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2
_write_reg_reset:
    ldr  x2, =RESET_BASE_ADDR
    str  w1, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the RESET block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1
_read_reg_reset:
    ldr  x1, =RESET_BASE_ADDR
    ldr  w0, [x1, x0]
    ret

//-----------------------------------------------------------------------------

 // this function initializes the upper-half of OCRAM for ECC checking
 // in:  none
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9
_ocram_init_upper:

     // set the start flag
    adr  x8, init_task1_flags
    mov  w9, #1
    str  w9, [x8]

     // use 64-bit accesses to r/w all locations of the upper-half of OCRAM
    ldr  x0, =OCRAM_BASE_ADDR
    ldr  x1, =OCRAM_SIZE_IN_BYTES
     // divide size in half
    lsr  x1, x1, #1
     // add size to base addr to get start addr of upper half
    add  x0, x0, x1
     // convert bytes to 64-byte chunks (using quad load/store pair ops)
    lsr  x1, x1, #6

     // x0 = start address
     // x1 = size in 64-byte chunks
1:
     // for each location, read and write-back
    ldp  x2, x3, [x0]
    ldp  x4, x5, [x0, #16]
    ldp  x6, x7, [x0, #32]
    ldp  x8, x9, [x0, #48]
    stp  x2, x3, [x0]
    stp  x4, x5, [x0, #16]
    stp  x6, x7, [x0, #32]
    stp  x8, x9, [x0, #48]

    sub  x1, x1, #1
    cbz  x1, 2f
    add  x0, x0, #64
    b    1b

2:
     // make sure the data accesses are complete
    dsb  sy
    isb

     // set the done flag
    adr  x6, init_task1_flags
    mov  w7, #1
    str  w7, [x6, #4]

     // clean the registers
    mov  x0, #0
    mov  x1, #0
    mov  x2, #0
    mov  x3, #0
    mov  x4, #0
    mov  x5, #0
    mov  x6, #0
    mov  x7, #0
    mov  x8, #0
    mov  x9, #0
    ret

//-----------------------------------------------------------------------------

 // this function initializes the lower-half of OCRAM for ECC checking
 // in:  none
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9
_ocram_init_lower:

     // set the start flag
    adr  x8, init_task2_flags
    mov  w9, #1
    str  w9, [x8]

     // use 64-bit accesses to r/w all locations of the upper-half of OCRAM
    ldr  x0, =OCRAM_BASE_ADDR
    ldr  x1, =OCRAM_SIZE_IN_BYTES
     // divide size in half
    lsr  x1, x1, #1
     // convert bytes to 64-byte chunks (using quad load/store pair ops)
    lsr  x1, x1, #6

     // x0 = start address
     // x1 = size in 64-byte chunks
1:
     // for each location, read and write-back
    ldp  x2, x3, [x0]
    ldp  x4, x5, [x0, #16]
    ldp  x6, x7, [x0, #32]
    ldp  x8, x9, [x0, #48]
    stp  x2, x3, [x0]
    stp  x4, x5, [x0, #16]
    stp  x6, x7, [x0, #32]
    stp  x8, x9, [x0, #48]

    sub  x1, x1, #1
    cbz  x1, 2f
    add  x0, x0, #64
    b    1b

2:
     // make sure the data accesses are complete
    dsb  sy
    isb

     // set the done flag
    adr  x6, init_task2_flags
    mov  w7, #1
    str  w7, [x6, #4]

     // clean the registers
    mov  x0, #0
    mov  x1, #0
    mov  x2, #0
    mov  x3, #0
    mov  x4, #0
    mov  x5, #0
    mov  x6, #0
    mov  x7, #0
    mov  x8, #0
    mov  x9, #0
    ret

//-----------------------------------------------------------------------------

 // this is soc initialization task 1
 // this function releases a secondary core to init the upper half of OCRAM
 // in:  x0 = core mask lsb of the secondary core to put to work
 // out: none
 // uses x0, x1, x2, x3, x4
init_task_1:

    mov  x3, x30
    mov  x4, x0

     // set the core state to WORKING_INIT
    mov  w1, #CORE_WORKING_INIT
    saveCoreData x0 x1 CORE_STATE_DATA

     // save the core mask
    mov  x0, x4
    bl   set_task1_core

     // load bootlocptr with start addr
    adr  x0, prep_init_ocram_hi
    bl   _soc_set_start_addr

     // release secondary core
    mov  x0, x4
    bl  _soc_core_release

    mov  x30, x3
    ret

//-----------------------------------------------------------------------------

 // this is soc initialization task 2
 // this function releases a secondary core to init the lower half of OCRAM
 // in:  x0 = core mask lsb of the secondary core to put to work
 // out: none
 // uses x0, x1, x2, x3, x4
init_task_2:

    mov  x3, x30
    mov  x4, x0

     // set the core state to WORKING_INIT
    mov  w1, #CORE_WORKING_INIT
    saveCoreData x0 x1 CORE_STATE_DATA

     // save the core mask
    mov  x0, x4
    bl   set_task2_core

     // load bootlocptr with start addr
    adr  x0, prep_init_ocram_lo
    bl   _soc_set_start_addr

     // release secondary core
    mov  x0, x4
    bl  _soc_core_release

    mov  x30, x3
    ret

//-----------------------------------------------------------------------------

 // this function initializes the soc init task flags
 // in:  none
 // out: none
 // uses x0, x1
init_task_flags:

    adr  x0, init_task1_flags
    adr  x1, init_task2_flags
    str  wzr, [x0]
    str  wzr, [x0, #4]
    str  wzr, [x0, #8]
    str  wzr, [x1]
    str  wzr, [x1, #4]
    str  wzr, [x1, #8]
    adr  x0, init_task3_flags
    str  wzr, [x0]
    str  wzr, [x0, #4]
    str  wzr, [x0, #8]

    ret

//-----------------------------------------------------------------------------

 // this function returns the state of the task 1 start flag
 // in:  
 // out: 
 // uses x0, x1
get_task1_start:

    adr  x1, init_task1_flags
    ldr  w0, [x1]
    ret

//-----------------------------------------------------------------------------

 // this function returns the state of the task 1 done flag
 // in:  
 // out: 
 // uses x0, x1
get_task1_done:

    adr  x1, init_task1_flags
    ldr  w0, [x1, #4]
    ret

//-----------------------------------------------------------------------------

 // this function returns the core mask of the core performing task 1
 // in:  
 // out: x0 = core mask lsb of the task 1 core
 // uses x0, x1
get_task1_core:

    adr  x1, init_task1_flags
    ldr  w0, [x1, #8]
    ret

//-----------------------------------------------------------------------------

 // this function saves the core mask of the core performing task 1
 // in:  x0 = core mask lsb of the task 1 core
 // out:
 // uses x0, x1
set_task1_core:

    adr  x1, init_task1_flags
    str  w0, [x1, #8]
    ret

//-----------------------------------------------------------------------------

 // this function returns the state of the task 2 start flag
 // in:  
 // out: 
 // uses x0, x1
get_task2_start:

    adr  x1, init_task2_flags
    ldr  w0, [x1]
    ret

//-----------------------------------------------------------------------------

 // this function returns the state of the task 2 done flag
 // in:  
 // out: 
 // uses x0, x1
get_task2_done:

    adr  x1, init_task2_flags
    ldr  w0, [x1, #4]
    ret

//-----------------------------------------------------------------------------

 // this function returns the core mask of the core performing task 2
 // in:  
 // out: x0 = core mask lsb of the task 2 core
 // uses x0, x1
get_task2_core:

    adr  x1, init_task2_flags
    ldr  w0, [x1, #8]
    ret

//-----------------------------------------------------------------------------

 // this function saves the core mask of the core performing task 2
 // in:  x0 = core mask lsb of the task 2 core
 // out:
 // uses x0, x1
set_task2_core:

    adr  x1, init_task2_flags
    str  w0, [x1, #8]
    ret

//-----------------------------------------------------------------------------

 // this function determines if a given mpidr value is valid for this SoC
 // in:  x0 = mpidr[15:0]
 // out: x0 == 0, mpidr not valid
 //      x0 != 0, mpidr is valid
 // uses x0, x1, x2
_is_mpidr_valid:

     // compare the 0-based affinity 1 field (cluster #) with the number
     // of clusters in this SoC
    and  x1, x0, #MPIDR_AFFINITY1_MASK
    lsr  x1, x1, #MPIDR_AFFINITY1_OFFSET
     // compare to the cluster count of this SoC
    ldr  x2, =CLUSTER_COUNT
    cmp  x2, x1
    b.le 2f

     // compare the 0-based affinity 0 field (core number) with the
     // number of cores per cluster in this SoC
    and  x1, x0, #MPIDR_AFFINITY0_MASK
    ldr  x2, =CPU_PER_CLUSTER
    cmp  x2, x1
    b.le 2f

1:
     // the mpidr is valid
    mov  x0, #1
    b    3f
2:
     // the mpidr is not valid
    mov  x0, #0
3:
    ret

//-----------------------------------------------------------------------------

 // this function sets the security mechanisms in the SoC to implement the
 // Platform Security Policy
_set_platform_security:
    mov  x8, x30

     // initialize the tzasc
     // tzasc is missing from LS2080
     //bl   init_tzasc

     // initialize the tzpc
    bl   init_tzpc

     //   configure secure interrupts

     //   configure EL3 mmu

    mov  x30, x8
    ret

//-----------------------------------------------------------------------------

 // this function checks to see if cores which are to be disabled have been
 // released from reset - if not, it releases them
 // in:  none
 // out: none
 // uses x0, x1, x2, x3
release_disabled:

     // COREDISR has a bit set for each core which is to be disabled (bit 0 = core 0)
     // read COREDISR
    ldr  x0, =DCFG_BASE_ADDR
    ldr  w2, [x0, #COREDISR_OFFSET]

     // x2 = COREDISR

     // BRR has a bit set for each core that has been released (bit 0 = core 0)
     // read BRR
    ldr  x0, =RESET_BASE_ADDR
    ldr  w1, [x0, #BRR_OFFSET]

     // x0 = reset block base addr
     // x1 = BRR
     // x2 = COREDISR

    and  x3, x2, x1
     // have all "disabled" cores been released from reset?
    cmp  x2, x3
    b.eq 1f

     // some "disabled" cores have not been released from reset - release them
    orr  x1, x1, x2
    str  w1, [x0, #BRR_OFFSET]
1:
    ret

//-----------------------------------------------------------------------------

 // this function setc up the TrustZone Address Space Controller (TZASC)
 // in:  none
 // out: none
 // uses x0, x1
init_tzpc:

     // set Non Secure access for all devices protected via TZPC
	ldr	x1, =TZPCDECPROT_0_SET_BASE   // decode Protection-0 Set Reg
	mov	w0, #0xFF		              // set decode region to NS, Bits[7:0]
	str	w0, [x1]

	ldr	x1, =TZPCDECPROT_1_SET_BASE   // decode Protection-1 Set Reg
	mov	w0, #0xFF		              // set decode region to NS, Bits[7:0]
	str	w0, [x1]

	ldr	x1, =TZPCDECPROT_2_SET_BASE   // decode Protection-2 Set Reg
	mov	w0, #0xFF		              // set decode region to NS, Bits[7:0]
	str	w0, [x1]

	 // entire SRAM as NS
	ldr	x1, =TZPC_BASE	              // secure RAM region size Reg
	mov	w0, #0x00000000		          // 0x00000000 = no secure region
	str	w0, [x1]

    ret

//-----------------------------------------------------------------------------

 // this function setc up the TrustZone Address Space Controller (TZASC)
 // in:  none
 // out: none
 // uses x0, x1
init_tzasc:

	 // Set TZASC so that:
	 //  a. We use only Region0 whose global secure write/read is EN
	 //  b. We use only Region0 whose NSAID write/read is EN
	 //
	 // NOTE: As per the CCSR map doc, TZASC 3 and TZASC 4 are just
	 // 	  placeholders.

	ldr	x1, =TZASC_REGION_ATTRIBUTES_0_0
	ldr	w0, [x1]		              // region-0 Attributes Register
	orr	w0, w0, #1 << 31	          // set Sec global write en, Bit[31]
	orr	w0, w0, #1 << 30	          // set Sec global read en, Bit[30]
	str	w0, [x1]

	ldr	x1, =TZASC_REGION_ATTRIBUTES_0_1
	ldr	w0, [x1]		              // region-1 Attributes Register
	orr	w0, w0, #1 << 31	          // set Sec global write en, Bit[31]
	orr	w0, w0, #1 << 30	          // set Sec global read en, Bit[30]
	str	w0, [x1]

	ldr	x1, =TZASC_REGION_ID_ACCESS_0_0
	ldr	w0, [x1]		              // region-0 Access Register
	mov	w0, #0xFFFFFFFF		          // set nsaid_wr_en and nsaid_rd_en
	str	w0, [x1]

	ldr	x1, =TZASC_REGION_ID_ACCESS_0_1
	ldr	w0, [x1]		              // region-1 Attributes Register
	mov	w0, #0xFFFFFFFF		          // set nsaid_wr_en and nsaid_rd_en
	str	w0, [x1]

    ret

//-----------------------------------------------------------------------------

 // this function returns the redistributor base address for the core specified
 // in x1
 // in:  x0 - core mask lsb of specified core
 // out: x0 = redistributor rd base address for specified core
 // uses x0, x1, x2
get_gic_rd_base:
     // get the 0-based core number
    clz  w1, w0
    mov  w2, #0x20
    sub  w2, w2, w1
    sub  w2, w2, #1

     // x2 = core number / loop counter

    ldr  x0, =GICR_RD_BASE_ADDR
    mov  x1, #GICR_OFFSET
2:
    cbz  x2, 1f
    add  x0, x0, x1
    sub  x2, x2, #1
    b    2b
1:
    ret

//-----------------------------------------------------------------------------

 // this function returns the redistributor base address for the core specified
 // in x1
 // in:  x0 - core mask lsb of specified core
 // out: x0 = redistributor sgi base address for specified core
 // uses x0, x1, x2
get_gic_sgi_base:
     // get the 0-based core number
    clz  w1, w0
    mov  w2, #0x20
    sub  w2, w2, w1
    sub  w2, w2, #1

     // x2 = core number / loop counter

    ldr  x0, =GICR_SGI_BASE_ADDR
    mov  x1, #GICR_OFFSET
2:
    cbz  x2, 1f
    add  x0, x0, x1
    sub  x2, x2, #1
    b    2b
1:
    ret

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

 // DO NOT CALL THIS FUNCTION FROM THE BOOT CORE!!
 // this function uses a secondary core to initialize the upper portion of OCRAM
 // the core does not return from this function
prep_init_ocram_hi:

     // invalidate the icache
    ic  iallu
    isb

     // enable the icache, mmu on the secondary core
    mrs  x1, sctlr_el3
    orr  x1, x1, #SCTLR_I_MASK
    msr  sctlr_el3, x1
    isb

     // init the range of ocram
    bl  _ocram_init_upper

     // get the core mask
    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb

     // x0 = core mask lsb

     // turn off icache, mmu
    mrs  x1, sctlr_el3
    bic  x1, x1, #SCTLR_I_MASK
    bic  x1, x1, #SCTLR_M_MASK
    msr  sctlr_el3, x1

     // invalidate the icache
    ic  iallu
    isb

     // wakeup the bootcore - it might be asleep waiting for us to finish
    sev
    isb
    sev
    isb

     // do not proceed until SCRATCHRW7=0x0
    ldr  x3, =DCFG_SCRATCHRW7_OFFSET
1:
    mov  x0, x3
    bl   _read_reg_dcfg
    cbnz x0, 1b

     // read reset vector and branch to it
    mrs x0, rvbar_el3
    br  x0

//temp1:
//    b   temp1

//-----------------------------------------------------------------------------

 // DO NOT CALL THIS FUNCTION FROM THE BOOT CORE!!
 // this function uses a secondary core to initialize the lower portion of OCRAM
 // the core does not return from this function
prep_init_ocram_lo:

     // invalidate the icache
    ic  iallu
    isb

     // enable the icache, mmu on the secondary core
    mrs  x1, sctlr_el3
    orr  x1, x1, #SCTLR_I_MASK
    msr  sctlr_el3, x1
    isb

     // init the range of ocram
    bl  _ocram_init_lower

     // get the core mask
    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb

     // x0 = core mask lsb

     // turn off icache, mmu
    mrs  x1, sctlr_el3
    bic  x1, x1, #SCTLR_I_MASK
    bic  x1, x1, #SCTLR_M_MASK
    msr  sctlr_el3, x1

     // invalidate tlb
    tlbi  alle3
    dsb   sy
    isb

     // invalidate the icache
    ic  iallu
    isb

     // wakeup the bootcore - it might be asleep waiting for us to finish
    sev
    isb
    sev
    isb

     // do not proceed until SCRATCHRW7=0x0
    ldr  x3, =DCFG_SCRATCHRW7_OFFSET
1:
    mov  x0, x3
    bl   _read_reg_dcfg
    cbnz x0, 1b

     // read reset vector and branch to it
    mrs x0, rvbar_el3
    br  x0

//temp2:
//    b   temp2

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
psci_features_table:
    .4byte  PSCI_VERSION_ID         // psci_version
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  PSCI_CPU_OFF_ID         // cpu_off
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  PSCI_CPU_ON_ID          // cpu_on
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  PSCI_FEATURES_ID        // psci_features
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  PSCI_AFFINITY_INFO_ID   // psci_affinity_info
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  FEATURES_TABLE_END      // table terminating value - must always be last entry in table

.align 3

saved_bootlocptr:
    .8byte 0x0   // 
init_task1_flags:
    .4byte  0x0  // begin flag
    .4byte  0x0  // completed flag
    .4byte  0x0  // core mask
init_task2_flags:
    .4byte  0x0  // begin flag
    .4byte  0x0  // completed flag
    .4byte  0x0  // core mask
init_task3_flags:
    .4byte  0x0  // begin flag
    .4byte  0x0  // completed flag
    .4byte  0x0  // core mask

//-----------------------------------------------------------------------------






