//-----------------------------------------------------------------------------
// 
// Copyright (c) 2015-2016 Freescale Semiconductor, Inc.
// Copyright 2017 NXP Semiconductors
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Author Rod Dorris <rod.dorris@nxp.com>
// 
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

.global _get_current_mask

.global _soc_init_start
.global _soc_init_finish
.global _soc_init_percpu
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
.global _soc_sys_off
.global _soc_core_entr_off
.global _soc_core_exit_off
.global _soc_core_phase1_off
.global _soc_core_phase2_off
.global _soc_core_phase1_clnup
.global _soc_core_phase2_clnup

.global _get_gic_rd_base
.global _get_gic_sgi_base
.global _soc_exit_boot_svcs
.global _soc_check_sec_enabled

 // only valid if ddr is being initialized
#if (DDR_INIT)
.global _membank_count_addr
.global _membank_data_addr
#endif

.global _init_task1_flags
.global _init_task2_flags
.global _init_task3_flags
.global _init_task4_flags

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

 // this function performs any soc-specific initialization that is needed on 
 // a per-core basis
 // in:  none
 // out: none
 // uses none
_soc_init_percpu:

    ret

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

     // zero-out the membank global vars
    adr   x2, _membank_count_addr
    stp   xzr, xzr, [x2]

     // init the task flags
    bl  _init_task_flags   // 0-1

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
    bl  _get_task1_start // 0-1
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
    bl  _get_task2_start // 0-1
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
    bl   _get_task1_done
    cbnz x0, 2f
    wfe
    b    1b    
2:
    bl   _get_task2_done
    cbnz x0, 3f
    wfe
    b    2b    
3:
     // set the task 1 core state to IN_RESET
    bl   _get_task1_core
    cbz  x0, 5f
     // x0 = core mask lsb of the task 1 core
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_WFE
    bl   _setCoreData
5:
     // set the task 2 core state to IN_RESET
    bl   _get_task2_core
    cbz  x0, 4f
     // x0 = core mask lsb of the task 2 core
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_WFE
    bl   _setCoreData
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

 // this function returns an mpidr value for a core, given a core_mask_lsb
 // in:  x0 = core mask lsb
 // out: x0 = affinity2:affinity1:affinity0, where affinity is 8-bits
 // uses x0, x1
get_mpidr_value:

     // convert a core mask to an SoC core number
    clz  w0, w0
    mov  w1, #31
    sub  w0, w1, w0

     // get the mpidr core number from the SoC core number
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

 // this function determines if a core is disabled via COREDISABLEDSR
 // in:  w0  = core_mask_lsb
 // out: w0  = 0, core not disabled
 //      w0 != 0, core disabled
 // uses x0, x1
_soc_ck_disabled:

     // get base addr of dcfg block
    ldr  x1, =DCFG_BASE_ADDR

     // read COREDISABLEDSR
    ldr  w1, [x1, #COREDISABLEDSR_OFFSET]

     // test core bit
    and  w0, w1, w0

    ret

//-----------------------------------------------------------------------------

 // this function releases a secondary core from reset
 // in:   x0 = core_mask_lsb
 // out:  none
 // uses: x0, x1, x2, x3
_soc_core_release:
    mov   x3, x30
    mov   x2, x0

     // x2 = core mask

     // get mpidr value of target core
    mov   x0, x2
    bl    get_mpidr_value

     // x0 = mpidr
     // x2 = core mask

     // write mpidr value of target core to SCRATCHRW7
    mov  x1, #DCFG_BASE_ADDR
    str  w0, [x1, #DCFG_SCRATCHRW7_OFFSET]

     // x2 = core mask

     // read-modify-write BRRL
    mov  x1, #RESET_BASE_ADDR
    ldr  w0, [x1, #BRR_OFFSET]
    orr  w0, w0, w2
    str  w0, [x1, #BRR_OFFSET]
    dsb  sy
    isb

     // send event
    sev
    isb

    mov   x30, x3
    ret

//-----------------------------------------------------------------------------

 // this function releases a secondary core from reset, and waits til the
 // core signals it is up, or until we exceed the retry count
 // in:   x0 = core_mask_lsb
 // out:  x0 == 0, success
 //       x0 != 0, failure
 // uses: x0, x1, x2, x3, x4, x5
_soc_core_rls_wait:
    mov   x5, x30
    mov   x4, x0

     // x4 = core mask

     // get mpidr value of target core
    mov   x0, x4
    bl    get_mpidr_value

     // x0 = mpidr
     // x4 = core mask

     // write mpidr value of target core to SCRATCHRW7
    mov  x1, #DCFG_BASE_ADDR
    str  w0, [x1, #DCFG_SCRATCHRW7_OFFSET]

     // x4 = core mask

     // read-modify-write BRRL
    mov  x1, #RESET_BASE_ADDR
    ldr  w0, [x1, #BRR_OFFSET]
    orr  w0, w0, w4
    str  w0, [x1, #BRR_OFFSET]
    dsb  sy
    isb

     // send event
    sev
    isb

    mov  x3, #CORE_RELEASE_CNT

     // x3 = retry count
     // x4 = core_mask_lsb
1:
    sev
    isb
    mov  x0, x4
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

     // x0 = core state

     // see if the core has signaled that it is up
    cmp  x0, #CORE_RELEASED
    mov  x0, xzr
    b.eq 2f

#if 0
     // see if we used up our retries
    sub  x3, x3, #1
    mov  x0, #1
    cbz  x3, 2f
#endif

     // loop back and try again
    b    1b
2:
    mov  x30, x5
    ret

//-----------------------------------------------------------------------------

 // part of CPU_ON
 // this function restarts a core shutdown via _soc_core_entr_off
 // in:  x0 = core mask lsb (of the target cpu)
 // out: x0 == 0, on success
 //      x0 != 0, on failure
 // uses x0, x1, x2, x3, x4, x5, x6
_soc_core_restart:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core into PW15
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x10
_soc_core_entr_stdby:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function performs any necessary cleanup after the calling core has
 // exited PW15
 // in:  x0 = core mask lsb
 // out: none
 // uses x0,
_soc_core_exit_stdby:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core into a power-down state
 // the calling core will enter PW20
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x9, x10
_soc_core_entr_pwrdn:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function performs any necessary cleanup after the calling core has
 // exited PW20
 // in:  x0 = core mask lsb
 // out: none
 // uses x0,
_soc_core_exit_pwrdn:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the final core of the specified cluster into PW15
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x10
_soc_clstr_entr_stdby:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function performs any necessary cleanup after the calling core has
 // exited PW15
 // in:  x0 = core mask lsb
 // out: none
 // uses x0,
_soc_clstr_exit_stdby:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the final core of the specified cluster into a
 // power-down state - the calling core will enter PW20
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x9, x10
_soc_clstr_entr_pwrdn:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function performs any necessary cleanup after the calling core has
 // exited PW20
 // in:  x0 = core mask lsb
 // out: none
 // uses x0,
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

 // part of SYSTEM_OFF
 // this function turns off the SoC clocks
 // Note: this function is not intended to return, and the only allowable
 //       recovery is POR
 // in:  x0 = core mask lsb
 // out: x0 = 0, success
 //      x0 < 0, failure
 // uses 
_soc_sys_off:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function programs ARM core registers in preparation for shutting down
 // the core
 // in:   x0 = core_mask_lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8
_soc_core_phase1_off:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function programs SoC & GIC registers in preparation for shutting down
 // the core
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8
_soc_core_phase2_off:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function performs the final steps to shutdown the core
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6
_soc_core_entr_off:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function starts the process of starting a core back up
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5
_soc_core_exit_off:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function cleans up from phase 1 of the core shutdown sequence
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x3
_soc_core_phase1_clnup:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function cleans up from phase 2 of the core shutdown sequence
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5
_soc_core_phase2_clnup:

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
    mov  x3, x30

     // make sure the mask is cleared in the reset request mask register
    mov  x0, #RST_RSTRQMR1_OFFSET
    mov  w1, wzr
    bl   _write_reg_reset

     // set the reset request
    mov  x4, #RST_RSTCR_OFFSET
    mov  x0, x4
    mov  w1, #RSTCR_RESET_REQ
    bl   _write_reg_reset

     // x4 = RST_RSTCR_OFFSET

     // just in case this address range is mapped as cacheable,
     // flush the write out of the dcaches
    mov  x2, #RESET_BASE_ADDR
    add  x2, x2, x4
    dc   cvac, x2
    dsb  st
    isb

     // now poll on the status bit til it goes high
    mov  x5, #RST_RSTRQSR1_OFFSET
    mov  x4, #RSTRQSR1_SWRR
    mov  x6, #RESET_RETRY_CNT
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

 // this is soc initialization task 1
 // this function releases a secondary core to init the upper half of OCRAM
 // in:  x0 = core mask lsb of the secondary core to put to work
 // out: none
 // uses x0, x1, x2, x3, x4, x5
init_task_1:
    mov  x5, x30
    mov  x4, x0

     // set the core state to WORKING_INIT
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_WORKING_INIT
    bl   _setCoreData

     // save the core mask
    mov  x0, x4
    bl   _set_task1_core

     // load bootlocptr with start addr
    adr  x0, _prep_init_ocram_hi
    bl   _soc_set_start_addr

     // release secondary core
    mov  x0, x4
    bl  _soc_core_release

    mov  x30, x5
    ret

//-----------------------------------------------------------------------------

 // this is soc initialization task 2
 // this function releases a secondary core to init the lower half of OCRAM
 // in:  x0 = core mask lsb of the secondary core to put to work
 // out: none
 // uses x0, x1, x2, x3, x4, x5
init_task_2:
    mov  x5, x30
    mov  x4, x0

     // set the core state to WORKING_INIT
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_WORKING_INIT
    bl   _setCoreData

     // save the core mask
    mov  x0, x4
    bl   _set_task2_core

     // load bootlocptr with start addr
    adr  x0, _prep_init_ocram_lo
    bl   _soc_set_start_addr

     // release secondary core
    mov  x0, x4
    bl  _soc_core_release

    mov  x30, x5
    ret

//-----------------------------------------------------------------------------

 // this function sets the security mechanisms in the SoC to implement the
 // Platform Security Policy
_set_platform_security:
    mov  x8, x30

     // initialize the tzasc
    bl   init_tzasc

     // initialize the tzpc
    bl   init_tzpc

     // initialize secmon
    bl  initSecMon

    mov  x30, x8
    ret

//-----------------------------------------------------------------------------

 // this function makes any needed soc-specific configuration changes when boot
 // services end
_soc_exit_boot_svcs:
    mov  x10, x30

     // reset secmon
    bl  resetSecMon

    mov  x30, x10
    ret

//-----------------------------------------------------------------------------
 // this function checks SVR for security enabled
 // out: x2 = 1 of SEC enabled, 0 for SEC disabled
 // uses x0, x1, x2, x10
_soc_check_sec_enabled:
    mov  x10, x30
    mov  x0, #DCFG_SVR_OFFSET
    bl   _read_reg_dcfg

    mov  x2, #1
     // Check for SEC bit
    and  w0, w0, #SVR_SEC_MASK
    cmp  w0, #SVR_SEC_MASK
    b.ne 1f	  
    mov  x2, #0
    
1:
    mov x30, x10
    ret

//-----------------------------------------------------------------------------

 // this function checks to see if cores which are to be disabled have been
 // released from reset - if not, it releases them
 // in:  none
 // out: none
 // uses x0, x1, x2, x3
release_disabled:

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
_get_gic_rd_base:
     // get the 0-based core number
    clz  w1, w0
    mov  w2, #0x20
    sub  w2, w2, w1
    sub  w2, w2, #1

     // x2 = core number / loop counter

    ldr  x0, =GICR_RD_BASE_ADDR
    mov  x1, #GIC_RD_OFFSET
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
_get_gic_sgi_base:
     // get the 0-based core number
    clz  w1, w0
    mov  w2, #0x20
    sub  w2, w2, w1
    sub  w2, w2, #1

     // x2 = core number / loop counter

    ldr  x0, =GICR_SGI_BASE_ADDR
    mov  x1, #GIC_SGI_OFFSET
2:
    cbz  x2, 1f
    add  x0, x0, x1
    sub  x2, x2, #1
    b    2b
1:
    ret

//-----------------------------------------------------------------------------

 // this function performs any needed initialization on SecMon for boot services
initSecMon:

     // read the register hpcomr
    ldr  x1, =SECMON_BASE_ADDR
    ldr  w0, [x1, #SECMON_HPCOMR_OFFSET]
     // turn off secure access for the privileged registers
    orr  w0, w0, #SECMON_HPCOMR_NPSWAEN
     // write back
    str  w0, [x1, #SECMON_HPCOMR_OFFSET]

    ret

//-----------------------------------------------------------------------------

 // this function resets SecMon after boot services are completed
resetSecMon:

     // read the register hpcomr
    ldr  x1, =SECMON_BASE_ADDR
    ldr  w0, [x1, #SECMON_HPCOMR_OFFSET]
     // re-enable secure access for the privileged registers
    bic  w0, w0, #SECMON_HPCOMR_NPSWAEN
     // write back
    str  w0, [x1, #SECMON_HPCOMR_OFFSET]

    ret

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

psci_features_table:
    .4byte  PSCI_VERSION_ID           // psci_version
    .4byte  PSCI_FUNC_IMPLEMENTED     // implemented
    .4byte  PSCI_CPU_OFF_ID           // cpu_off
    .4byte  PSCI_FUNC_IMPLEMENTED     // implemented
    .4byte  PSCI64_CPU_ON_ID          // cpu_on
    .4byte  PSCI_FUNC_IMPLEMENTED     // implemented
    .4byte  PSCI_FEATURES_ID          // psci_features
    .4byte  PSCI_FUNC_IMPLEMENTED     // implemented
    .4byte  PSCI64_AFFINITY_INFO_ID   // psci_affinity_info
    .4byte  PSCI_FUNC_IMPLEMENTED     // implemented
    .4byte  FEATURES_TABLE_END        // table terminating value - must always be last entry in table

.align 9  // 64-byte aligned
saved_bootlocptr:
    .8byte 0x0   // 
_init_task1_flags:
    .4byte  0x0  // begin flag
    .4byte  0x0  // completed flag
    .4byte  0x0  // core mask
_init_task2_flags:
    .4byte  0x0  // begin flag
    .4byte  0x0  // completed flag
    .4byte  0x0  // core mask
_init_task3_flags:
    .4byte  0x0  // begin flag
    .4byte  0x0  // completed flag
    .4byte  0x0  // core mask
_init_task4_flags:
    .4byte  0x0  // begin flag
    .4byte  0x0  // completed flag
    .4byte  0x0  // core mask

//-----------------------------------------------------------------------------

 // only used if ddr is being initialized
 // Note: keep these two locations contiguous
.align 4

 // address in memory of number of memory banks
 // this is a pointer-to-a-pointer (**)
_membank_count_addr:
    .8byte  0x0
 // address in memory of start of memory bank data structures
 // Note: number of valid structures determined by value found
 //       at **_membank_count_addr
_membank_data_addr:
    .8byte  0x0

//-----------------------------------------------------------------------------






