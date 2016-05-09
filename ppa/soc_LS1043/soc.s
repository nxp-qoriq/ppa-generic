// 
// ARM v8 AArch64 Secure FW
//
// Copyright (c) 2016 Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// (1) LS1043 specific functions

//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"
#include "soc.h"
#include "soc.mac"
#include "policy.h"
#include "psci.h"

//-----------------------------------------------------------------------------

#define SWLPM20_WA 1

//-----------------------------------------------------------------------------

.global _soc_sys_reset
.global _soc_ck_disabled
.global _soc_set_start_addr
.global _soc_get_start_addr
.global _soc_core_release
.global _soc_core_rls_wait
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
.global _soc_core_restart

.global _get_current_mask
.global _get_core_mask_lsb

.global _soc_init_start
.global _soc_init_finish
.global _set_platform_security

//-----------------------------------------------------------------------------

.equ  RESTART_RETRY_CNT,  1600

 // retry count for releasing cores from reset - should be > 0
.equ  CORE_RELEASE_CNT,   800 

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core into standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0
_soc_core_entr_stdby:

     // X0 = core mask lsb

     // IRQ taken to EL3, set SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    orr  x0, x0, #0x2
    msr  SCR_EL3, x0

    dsb  sy
    isb
    wfi
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function performs any necessary cleanup after the calling core has
 // exited standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0
_soc_core_exit_stdby:

     // X0 = core mask lsb

     // clear SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    bic  x0, x0, #0x2
    msr  SCR_EL3, x0

    isb
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core into a power-down state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8
_soc_core_entr_pwrdn:
    mov   x8, x30

     // x0 = core mask lsb

     // disable dcache, mmu, and icache for EL1 and EL2
    ldr x2, =SCTLR_I_C_M_MASK
    mrs x1, SCTLR_EL1
    bic x1, x1, x2
    msr SCTLR_EL1, x1

    mrs x1, SCTLR_EL2
    bic x1, x1, x2
    msr SCTLR_EL2, x1

    bl  _flush_L1_dcache

     // disable only dcache for EL3 by clearing SCTLR_EL3[2]
    mrs x1, SCTLR_EL3
    ldr x2, =SCTLR_C_MASK

    bic x1, x1, x2
    msr SCTLR_EL3, x1

     // IRQ taken to EL3, set SCR_EL3[IRQ]
    mrs  x1, SCR_EL3
    orr  x1, x1, #SCR_IRQ_MASK
    orr  x1, x1, #0x2
    msr  SCR_EL3, x1

     // enable CPU retention and make sure SMPEN = 1
    mrs  x1, CPUECTLR_EL1
    bic  x1, x1, #CPUECTLR_RET_MASK
    orr  x1, x1, #CPUECTLR_RET_SET
    orr  x1, x1, #CPUECTLR_SMPEN_EN
    msr  CPUECTLR_EL1, x1

     // x0 = core mask lsb

     // enable soc retention for this core
    ldr  x2, =SCFG_BASE_ADDR
    ldr  w1, [x2, #SCFG_RETREQCR_OFFSET]
    rev  w3, w1
    orr  w3, w3, w0
    rev  w1, w3
    str  w1, [x2, #SCFG_RETREQCR_OFFSET]

     // set ph20 for this core
    ldr  x2, =RCPM_BASE_ADDR
    rev  w3, w0
    str  w3, [x2, #RCPM_PCPH20SETR_OFFSET]

    isb
    wfi

    mov  x30, x8
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function cleans up after a core exits power-down
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3
_soc_core_exit_pwrdn:

     // x0 = core mask lsb

     // clear the PH20 state for this core in question
    ldr  x2, =RCPM_BASE_ADDR
    rev  w3, w0
    str  w3, [x2, #RCPM_PCPH20CLRR_OFFSET]

     // clear the retention request for this core
    ldr  x2, =SCFG_BASE_ADDR
    ldr  w1, [x2, #SCFG_RETREQCR_OFFSET]
    rev  w3, w1
    orr  w3, w3, w0
    rev  w1, w3
    str  w1, [x2, #SCFG_RETREQCR_OFFSET]

     // disable CPU retention
    mrs  x0, CPUECTLR_EL1
    bic  x0, x0, #CPUECTLR_RET_MASK
    msr  CPUECTLR_EL1, x0

     // clear SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    bic  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

    isb
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the cluster into a standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2
_soc_clstr_entr_stdby:
    mov  x2, x30

     // x0 = core mask lsb

     // put the final core of the cluster into a standby state
    bl   _soc_core_entr_stdby
    mov  x30, x2
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function exits the cluster from a standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2
_soc_clstr_exit_stdby:
    mov  x2, x30

     // x0 = core mask lsb

    bl   _soc_core_exit_stdby
    mov  x30, x2
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core into a power-down state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9
_soc_clstr_entr_pwrdn:
    mov   x9, x30

     // x0 = core mask lsb

     // all we need to do is power-down the final core of this cluster
    bl   _soc_core_entr_pwrdn
    mov  x30, x9
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function cleans up after a cluster exits power-down
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4
_soc_clstr_exit_pwrdn:
     mov  x4, x30

     // x0 = core mask lsb

     // cleanup from the core power-down
    bl   _soc_core_exit_pwrdn
    mov  x30, x4
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the system into a standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2
_soc_sys_entr_stdby:
    mov  x2, x30

     // x0 = core mask lsb

     // put the final core of the cluster into a standby state
    bl   _soc_core_entr_stdby
    mov  x30, x2
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function exits the system from a standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2
_soc_sys_exit_stdby:
    mov  x2, x30

     // x0 = core mask lsb

    bl   _soc_core_exit_stdby
    mov  x30, x2
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core, and potentially the soc, into a
 // low-power state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9
_soc_sys_entr_pwrdn:
    mov   x9, x30

     // x0 = core mask lsb

// need sw LPM20 sequence

    mov  x30, x9
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function performs any necessary cleanup after the soc has exited
 // a low-power state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0
_soc_sys_exit_pwrdn:

     // x0 = core mask lsb

// need sw LMP20 cleanup here

    ret

//-----------------------------------------------------------------------------

 // this function resets the system via SoC-specific methods
 // in:  none
 // out: x0 = PSCI_SUCCESS
 //      x0 = PSCI_INTERNAL_FAILURE
 // uses x0, x1, x2, x3, x4
_soc_sys_reset:

    ldr  x2, =DCFG_BASE_ADDR

     // make sure the mask is cleared in the reset request mask register
    mov  w1, wzr
    str  w1, [x2, #DCFG_RSTRQMR1_OFFSET]

     // x2 = DCFG_BASE_ADDR

     // set the reset request
    ldr  w1, =RSTCR_RESET_REQ
    ldr  x4, =DCFG_RSTCR_OFFSET
    rev  w0, w1
    str  w0, [x2, x4]

     // x2 = DCFG_BASE_ADDR
     // x4 = DCFG_RSTCR_OFFSET

     // just in case this address range is mapped as cacheable,
     // flush the write out of the dcaches
    add  x4, x2, x4
    dc   cvac, x4
    dsb  st
    isb

     // x2 = DCFG_BASE_ADDR

     // now poll on the status bit til it goes high
    ldr  w3, =RESET_RETRY_CNT
    ldr  w4, =RSTRQSR1_SWRR
1:
    ldr  w0, [x2, #DCFG_RSTRQSR1_OFFSET]
    rev  w1, w0
     // see if we have exceeded the retry count
    cbz  w3, 2f
     // decrement retry count and test return value
    sub  w3, w3, #1
    tst  w1, w4
    b.eq 1b

     // if the reset occurs, the following code is not expected
     // to execute.....

     // if we are here then the status bit is set
    ldr  x0, =PSCI_SUCCESS
    b    3f
2:
     // signal failure and return
    ldr  x0, =PSCI_INTERNAL_FAILURE
3:
    ret

//-----------------------------------------------------------------------------

 // this function determines if a core is disabled via COREDISR
 // in:  w0  = core_mask_lsb
 // out: w0  = 0, core not disabled
 //      w0 != 0, core disabled
 // uses x0, x1, x2
_soc_ck_disabled:

     // get base addr of dcfg block
    ldr  x1, =DCFG_BASE_ADDR

     // read COREDISR
    ldr  w1, [x1, #DCFG_COREDISR_OFFSET]
    rev  w2, w1

     // test core bit
    and  w0, w2, w0
    ret

//-----------------------------------------------------------------------------

 // part of CPU_ON
 // this function releases a secondary core from reset
 // in:   x0 = core_mask_lsb
 // out:  none
 // uses: x0, x1, x2, x3
_soc_core_release:

#if (SIMULATOR_BUILD)
     // x0 = core mask lsb

    mov  w2, w0
    CoreMaskMsb w2, w3

     // x0 = core mask lsb
     // x2 = core mask msb

#else
     // x0 = core mask lsb

    mov  x2, x0

#endif
     // write COREBCR 
    ldr   x1, =SCFG_BASE_ADDR
    rev   w3, w2
    str   w3, [x1, #SCFG_COREBCR_OFFSET]
    isb

     // x0 = core mask lsb

     // read-modify-write BRR
    ldr  x1, =DCFG_BASE_ADDR
    ldr  w2, [x1, #DCFG_BRR_OFFSET]
    rev  w3, w2
    orr  w3, w3, w0
    rev  w2, w3
    str  w2, [x1, #DCFG_BRR_OFFSET]
    isb

     // send event
    sev
    isb
    ret

//-----------------------------------------------------------------------------

 // part of CPU_ON
 // this function releases a secondary core from reset, and waits til the
 // core signals it is up, or until we exceed the retry count
 // in:   x0 = core_mask_lsb
 // out:  x0 == 0, success
 //       x0 != 0, failure
 // uses: x0, x1, x2, x3, x4, x5
_soc_core_rls_wait:
    mov  x4, x30
    mov  x5, x0

     // release the core from reset
    bl   _soc_core_release

     // x5 = core_mask_lsb

    ldr  x3, =CORE_RELEASE_CNT

     // x3 = retry count
     // x5 = core_mask_lsb
1:
    sev
    isb
    mov  x0, x5
    getCoreData x0 CORE_STATE_DATA

     // see if the core has signaled that it is up
    cmp  x0, #CORE_RELEASED
    mov  x0, xzr
    b.eq 2f

     // see if we used up our retries
    sub  w3, w3, #1
    mov  x0, #1
    cbz  w3, 2f

     // loop back and try again
    b    1b
2:
    mov  x30, x4
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

#if (SWLPM20_WA)

#else

     // x0 = core mask lsb

     // set CPUECTLR[2:0] for timer ticks before core enters retention
    mrs   x4, S3_1_C15_C2_1
    mov   x1, x4
    bl    _save_CPUECTLR
    ldr   x0, =CPUECTLR_TIMER_8TICKS
    bfxil x4, x0, #0, #3 
     // set CPUECTLR.SMPEN to 1 (regardless of ARM specs) 
    orr  x4, x4, #CPUECTLR_SMPEN_MASK
    msr  S3_1_C15_C2_1, x4

#endif

     // clean/invalidate L1 dcache
    bl  _flush_L1_dcache

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

     // mask interrupts by setting DAIF[7:6] (IRQ and FIQ) to 1
    mrs  x1, DAIF
    ldr  x0, =DAIF_SET_MASK
    orr  x1, x1, x0
    msr  DAIF, x1 

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
 // uses x0, x1, x2, x3, x4, x5, x6
_soc_core_phase2_off:
    mov  x6, x30

     // x0 = core mask lsb
    mov  x4, x0

     // save GICC_CTLR
    ldr  x5, =GICC_BASE_ADDR
    ldr  w1, [x5, #GICC_CTLR_OFFSET]
    mov  w3, w1
    saveCoreData x0 x1 GICC_CTLR_DATA

     // x3 = GICC_CTRL
     // x4 = core mask lsb
     // x5 = GICC_BASE_ADDR

     // disable signaling of grp 0 ints
    bic  w3, w3, #GICC_CTLR_EN_GRP0
    str  w3, [x5, #GICC_CTLR_OFFSET]

     // set the priority filter
    ldr  w1, [x5, #GICC_PMR_OFFSET]
    orr  w1, w1, #GICC_PMR_FILTER
    str  w1, [x5, #GICC_PMR_OFFSET]

     // enable signaling of group 0 by setting GICC_CTLR[0] = 1
     // enable GRP0 = FIQ
    ldr  w3, [x5, #GICC_CTLR_OFFSET]
    orr  w3, w3, #GICC_CTLR_EN_GRP0
    orr  w3, w3, #GICC_CTLR_FIQ_EN_MASK
    bic  w3, w3, #GICC_CTLR_EOImodeS_MASK
    bic  w3, w3, #GICC_CTLR_ACKCTL_MASK
//    bic  w3, w3, #GICC_CTLR_EN_GRP1
    orr  w3, w3, #GICC_CTLR_EN_GRP1
    str  w3, [x5, #GICC_CTLR_OFFSET]

#if (SWLPM20_WA)

#else
     // x4 = core mask lsb

     // set SYS_Counter_CNTCR[0] to 1 to enable timer
    ldr  x1, =SYS_COUNTER_BASE
    ldr  w2, [x1, #SYS_COUNTER_CNTCR_OFFSET]
    rev  w3, w2
    orr  w2, w2, #CNTCR_EN_MASK
    rev  w3, w2
    str  w3, [x1, #SYS_COUNTER_CNTCR_OFFSET]
     
    mov  x0, x4
     // x0 = core mask lsb

    mov  w2, w0
    CoreMaskMsb w2, w3

     // x0 = core mask lsb
     // x2 = core mask msb

     // enable retention request
    ldr  x1, =SCFG_BASE_ADDR
    ldr  w3, [x1, #SCFG_RETREQCR_OFFSET]
    rev  w3, w3
    orr  w3, w3, w2
    rev  w3, w3
    str  w3, [x1, #SCFG_RETREQCR_OFFSET]

     // x0 = core mask lsb

     // set RCPM_PH20SETR[core number] to 1 to request core be put into PH20
    ldr  x1, =RCPM_BASE_ADDR
    rev  x2, x0
    str  x2, [x1, #RCPM_PCPH20SETR_OFFSET]

#endif

    dsb  sy
    isb
    mov  x30, x6
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function performs the final steps to shutdown the core
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3
_soc_core_entr_off:
    mov  x4, x30
    mov  x3, x0

     // x0 = core mask lsb

     // change state of core in data area
    mov  x1, #CORE_OFF
    saveCoreData x0 x1 CORE_STATE_DATA

     // disable EL3 icache by clearing SCTLR_EL3[12]
    mrs x1, SCTLR_EL3
    ldr x2, =SCTLR_I_MASK
    bic x1, x1, x2      
    msr SCTLR_EL3, x1 

     // invalidate icache
    ic iallu
    dsb  sy
    isb

     // x3  = core mask (lsb)

3:
     // enter low-power state by executing wfi
    wfi

     // check if core has been turned on
    mov  x0, x3 
    getCoreData x0 CORE_STATE_DATA

    cmp  x0, #CORE_PENDING
    b.ne 3b

    mov  x30, x4
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function starts the process of starting a core back up
 // in:  none
 // out: none
 // uses x0, x1
_soc_core_exit_off:

     // clear the pending SGI
    ldr  x1, =GICD_BASE_ADDR
    ldr  x0, =GICD_CPENDSGIR_CLR_MASK
    str  w0, [x1, #GICD_CPENDSGIR3_OFFSET]

     // enable icache in SCTLR_EL3
    mrs  x0, SCTLR_EL3
    orr  x0, x0, #SCTLR_I_MASK
    msr  SCTLR_EL3, x0

    dsb sy
    isb
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

#if (SWLPM20_WA)

#else

     // restore cpuectlr
    bl   _get_saved_CPUECTLR
    msr  S3_1_C15_C2_1, x0 

#endif   

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
 // uses x0, x1, x2, x3, x4
_soc_core_phase2_clnup:
    mov  x4, x30

     // x0 = core mask lsb

#if (SWLPM20_WA)

#else

     // set the clear bit in the RCPM_PH20CLRR
    ldr  x1, =RCPM_BASE_ADDR
    rev  x2, x0
    str  x2, [x1, #RCPM_PCPH20CLRR_OFFSET]

    mov  w2, w0
    CoreMaskMsb w2, w3

     // x0 = core mask lsb
     // x2 = core mask msb

     // clear retention request
    ldr  x1, =SCFG_BASE_ADDR
    ldr  w3, [x1, #SCFG_RETREQCR_OFFSET]
    rev  w3, w3
    bic  w3, w3, w2
    rev  w3, w3
    str  w3, [x1, #SCFG_RETREQCR_OFFSET]

#endif

     // x0 = core mask lsb

     // restore GICC_CTLR
    getCoreData x0 GICC_CTLR_DATA
    ldr  x2, =GICC_BASE_ADDR
    str  w0, [x2, #GICC_CTLR_OFFSET]

    dsb  sy
    isb
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

     // x0 = core mask lsb

#if (SWLPM20_WA)

#else
     // x0 = core mask lsb

     // set the clear bit in the RCPM_PH20CLRR
    ldr  x1, =RCPM_BASE_ADDR
    rev  x2, x0
    str  x2, [x1, #RCPM_PCPH20CLRR_OFFSET]

    mov  w2, w0
    CoreMaskMsb w2, w3

     // x0 = core mask lsb
     // x2 = core mask msb

     // clear retention request
    ldr  x1, =SCFG_BASE_ADDR
    ldr  w3, [x1, #SCFG_RETREQCR_OFFSET]
    rev  w3, w3
    bic  w3, w3, w2
    rev  w3, w3
    str  w3, [x1, #SCFG_RETREQCR_OFFSET]
    dsb sy
    isb

#endif

     // x0 = core mask lsb

     // disable forwarding of group 0 interrupts by setting GICD_CTLR[0] = 0
    ldr  x2, =GICD_BASE_ADDR
    ldr  w1, [x2, #GICD_CTLR_OFFSET]
    bic  w1, w1, #GICD_CTLR_EN_GRP0
    str  w1, [x2, #GICD_CTLR_OFFSET]
    dsb sy
    isb

     // x0 = core mask lsb
     // x2 = GICD_BASE_ADDR

     // set interrupt ID 15 to group 0 by setting GICD_IGROUP0[15] = 0 
    ldr  w1, [x2, #GICD_IGROUPR0_OFFSET]
    bic  w1, w1, #GICD_IGROUP0_SGI15
    str  w1, [x2, #GICD_IGROUPR0_OFFSET]

     // set the priority of SGI 15 to highest
    ldr  w1, [x2, #GICD_IPRIORITYR3_OFFSET]
    bic  w1, w1, #GICD_IPRIORITY_SGI15_MASK
    str  w1, [x2, #GICD_IPRIORITYR3_OFFSET]
    
     // x0 = core mask lsb
     // x2 = GICD_BASE_ADDR

     // enable forwarding of SGI 15 by setting GICD_ISENABLER0[15] = 1
    ldr  w1, [x2, #GICD_ISENABLER0_OFFSET]
    orr  w1, w1, #GICD_ISENABLE0_SGI15
    str  w1, [x2, #GICD_ISENABLER0_OFFSET]

     // enable forwarding of group 0 interrupts by setting GICD_CTLR[0] = 1
    ldr  w1, [x2, #GICD_CTLR_OFFSET]
    orr  w1, w1, #GICD_CTLR_EN_GRP0
    orr  w1, w1, #GICD_CTLR_EN_GRP1
    str  w1, [x2, #GICD_CTLR_OFFSET]
    dsb sy
    isb

     // activate SGI 15
//    ldr  x1, =GICD_ISACTIVER0_SGI15
//    str  w1, [x2, #GICD_ISACTIVER0_OFFSET]

     // x0 = core mask lsb
     // x2 = GICD_BASE_ADDR

     // fire SGI by writing to GICD_SGIR the following values:
     // [25:24] = 0x0 (forward interrupt to the CPU interfaces specified in CPUTargetList field)
     // [23:16] = core mask lsb[7:0] (forward interrupt to target cpu)
     // [15]    = 0 (forward SGI only if it is configured as group 0 interrupt)
     // [3:0]   = 0xF (interrupt ID = 15)
    lsl  w1, w0, #16
    orr  w1, w1, #0xF
    str  w1, [x2, #GICD_SGIR_OFFSET]
    dsb sy
    isb

    mov  x4, x0

     // x2 = GICD_BASE_ADDR
     // x4 = target core mask lsb

     // get current core mask
    bl   _get_current_mask

     // x0 = current core mask lsb
     // x2 = GICD_BASE_ADDR
     // x4 = target core mask lsb

     // set the interrupt pending
    lsl  w0, w0, #GICD_SPENDSGIR3_SGI15_OFFSET
    str  w1, [x2, #GICD_SPENDSGIR3_OFFSET]

     // get the state of the core and loop til the
     // core state is "RELEASED" or until timeout 

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

 // this function loads a 64-bit execution address of the core in the soc registers
 // BOOTLOCPTRL/H
 // in:  x0, 64-bit address to write to BOOTLOCPTRL/H
 // uses x0, x1, x2, x3 
_soc_set_start_addr:
     // get the 64-bit base address of the scfg block
    ldr  x2, =SCFG_BASE_ADDR

     // write the 32-bit BOOTLOCPTRL register (offset 0x604 in the scfg block)
    mov  x1, x0
    rev  w3, w1
    str  w3, [x2, #BOOTLOCPTRL_OFFSET]

     // write the 32-bit BOOTLOCPTRH register (offset 0x600 in the scfg block)
    lsr  x1, x0, #32
    rev  w3, w1
    str  w3, [x2, #BOOTLOCPTRH_OFFSET]
    ret

//-----------------------------------------------------------------------------

 // this function returns a 64-bit execution address of the core in x0
 // out: x0, address found in BOOTLOCPTRL/H
 // uses x0, x1, x2 
_soc_get_start_addr:
     // get the 64-bit base address of the scfg block
    ldr  x1, =SCFG_BASE_ADDR

     // read the 32-bit BOOTLOCPTRL register (offset 0x604 in the scfg block)
    ldr  w0, [x1, #BOOTLOCPTRL_OFFSET]
     // swap bytes for BE
    rev  w2, w0

     // read the 32-bit BOOTLOCPTRH register (offset 0x600 in the scfg block)
    ldr  w0, [x1, #BOOTLOCPTRH_OFFSET]
    rev  w1, w0
     // create a 64-bit BOOTLOCPTR address
    orr  x0, x2, x1, LSL #32
    ret

//-----------------------------------------------------------------------------

 // this function programs the GIC for a Group0 SGI targeted at the core
 // in:  none
 // out: none
 // uses x0, x1, x2
enableSGI:

     // set interrupt ID 15 to group 0 by setting GICD_IGROUP0[15] to 0 
    ldr  w2, =GICD_BASE_ADDR
    ldr  w0, [x2, #GICD_IGROUPR0_OFFSET]
    ldr  w1, =GICD_IGROUP0_SGI15
    bic  w0, w0, w1
    str  w0, [x2, #GICD_IGROUPR0_OFFSET]

     // x2 = GICD_BASE_ADDR

     // enable forwarding of group 0 interrupts by setting GICD_CTLR[0] to 1
    ldr  w0, [x2, #GICD_CTLR_OFFSET]
    ldr  w1, =GICD_CTLR_EN_GRP0
    orr  w0, w0, w1
    str  w0, [x2, #GICD_CTLR_OFFSET]

     // enable signaling of group 0 by setting GICC_CTLR[1:0] to 0b01 
    ldr    w2, =GICC_BASE_ADDR
    ldr    w0, [x2, #GICC_CTLR_OFFSET]
    ldr    w1, =GICC_CTLR_EN_GRP0
    bfxil  w0, w1, #0, #2
    str    w0, [x2, #GICC_CTLR_OFFSET]

    isb
    ret

//-----------------------------------------------------------------------------

 // this function enables/disables the SoC retention request for the core,
 // using a read-modify-write methodology
 // in:  w0 = core mask (msb)
 //      w1 = set or clear bit specified in core mask (0 = clear, 1 = set)
 // out: none
 // uses x0, x1, x2, x3
retention_ctrl:
    ldr  w2, =SCFG_BASE_ADDR
    ldr  w3, [x2, #SCFG_RETREQCR_OFFSET]

     // byte swap for BE
    rev  w3, w3
    bic  w3, w3, w0
    cmp  w1, #0
    b.eq 1f
    orr  w3, w3, w0
1:
    rev  w3, w3
    str  w3, [x2, #SCFG_RETREQCR_OFFSET]
    ret

//-----------------------------------------------------------------------------

 // this function clears a pending SGI 15 interrupt
 // in:  none
 // out: none
 // uses x0, x1
clearSGI:
    ldr  w1, =GICD_BASE_ADDR
    ldr  w0, =GICD_CPENDSGIR_CLR_MASK
    str  w0, [x1, #GICD_CPENDSGIR3_OFFSET]
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
    mrs  x0, MPIDR_EL1

     // generate a lsb-based mask for the core - this algorithm assumes 4 cores
     // per cluster, and must be adjusted if that is not the case
     // SoC core = ((cluster << 2) + core)
     // mask = (1 << SoC core)
    mov   w1, wzr
    mov   w2, wzr
    bfxil w1, w0, #8, #8  // extract cluster
    bfxil w2, w0, #0, #8  // extract cpu #
    lsl   w1, w1, #2
    add   w1, w1, w2
    mov   w2, #0x1
    lsl   w0, w2, w1
    ret

//-----------------------------------------------------------------------------

 // this function starts the initialization tasks of the soc, using secondary cores
 // if they are available
 // in: 
 // out: 
 // uses x0, x1, x2, x3, x4, x5
_soc_init_start:


    ret

//-----------------------------------------------------------------------------

 // this function completes the initialization tasks of the soc
 // in: 
 // out: 
 // uses x0, x1, x2, x3, x4
_soc_init_finish:


    ret

//-----------------------------------------------------------------------------

 // this function sets the security mechanisms in the SoC to implement the
 // Platform Security Policy
_set_platform_security:


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
     // generate a lsb-based mask for the core - this algorithm assumes 4 cores
     // per cluster, and must be adjusted if that is not the case
     // SoC core = ((cluster << 2) + core)
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

    lsl   w1, w1, #2
    add   w1, w1, w2
    mov   w2, #0x1
    lsl   w0, w2, w1
    ret

1:
    mov   w0, wzr
    ret

//-----------------------------------------------------------------------------

 // write a register in the SCFG block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_scfg:
    ldr  w2, =SCFG_BASE_ADDR
     // swap for BE
    rev  w3, w1
    str  w3, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the SCFG block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_scfg:
    ldr  w2, =SCFG_BASE_ADDR
    ldr  w1, [x2, x0]
     // swap for BE
    rev  w0, w1
    ret

//-----------------------------------------------------------------------------

 // write a register in the DCFG block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_dcfg:
    ldr  w2, =DCFG_BASE_ADDR
     // swap for BE
    rev  w3, w1
    str  w3, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the DCFG block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_dcfg:
    ldr  w2, =DCFG_BASE_ADDR
    ldr  w1, [x2, x0]
     // swap for BE
    rev  w0, w1
    ret

//-----------------------------------------------------------------------------

 // write a register in the RCPM block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_rcpm:
    ldr  w2, =RCPM_BASE_ADDR
     // swap for BE
    rev  w3, w1
    str  w3, [x2, x0]
    ret
//-----------------------------------------------------------------------------

 // read a register in the RCPM block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_rcpm:
    ldr  w2, =RCPM_BASE_ADDR
    ldr  w1, [x2, x0]
     // swap for BE
    rev  w0, w1
    ret

//-----------------------------------------------------------------------------

 // write a register in the SYS_COUNTER block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_sys_counter:
    ldr  w2, =SYS_COUNTER_BASE
     // swap for BE
    rev  w3, w1
    str  w3, [x2, x0]
    ret
//-----------------------------------------------------------------------------

 // read a register in the SYS_COUNTER block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_sys_counter:
    ldr  w2, =SYS_COUNTER_BASE
    ldr  w1, [x2, x0]
     // swap for BE
    rev  w0, w1
    ret

//-----------------------------------------------------------------------------

 // write a register in the GIC400 distributor block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_gicd:
    ldr  w2, =GICD_BASE_ADDR
    str  w1, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the GIC400 distributor block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_gicd:
    ldr  w2, =GICD_BASE_ADDR
    ldr  w0, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // write a register in the GIC400 CPU interface block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_gicc:
    ldr  w2, =GICC_BASE_ADDR
    str  w1, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the GIC400 CPU interface block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_gicc:
    ldr  w2, =GICC_BASE_ADDR
    ldr  w0, [x2, x0]
    ret

//-----------------------------------------------------------------------------





//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

