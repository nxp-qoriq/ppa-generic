// 
// ARM v8 AArch64 PSCI v1.0
//
// Copyright (c) 2013-2015 Freescale Semiconductor, Inc. All rights reserved.
//

// This file includes:
// (1) PSCI functions SMC64 interface
// (2) PSCI functions SMC32 interface

//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"
#include "soc.h"
#include "soc.mac"
#include "psci.h"

//-----------------------------------------------------------------------------

.global _smc64_std_svc
.global _smc32_std_svc
.global _initialize_psci
.global _find_core
.global _save_core_sctlr
.global _psci_processAbort
.global _get_core_data

//-----------------------------------------------------------------------------

 // Note: x11 contains the function number
 //       x12 is used to save/restore the LR

_smc64_std_svc:
     // psci smc64 interface lives here

     // is this CPU_SUSPEND
    mov  w10, #0x0001
    cmp  w10, w11
    b.eq smc64_psci_cpu_suspend

     // is this CPU_ON
    mov  w10, #0x0003
    cmp  w10, w11
    b.eq smc64_psci_cpu_on

     // is this AFFINITY_INFO
    mov  w10, #0x0004
    cmp  w10, w11
    b.eq smc64_psci_affinity_info

     // if we are here then we have an unimplemented/unrecognized function
    b smc_func_unimplemented

//-----------------------------------------------------------------------------

 // Note: x11 contains the function number

_smc32_std_svc:
     // psci smc32 interface lives here

     // is this PSCI_VERSION
    mov  w10, #0x0000
    cmp  w10, w11
    b.eq smc32_psci_version

     // is this CPU_SUSPEND
    mov  w10, #0x0001
    cmp  w10, w11
    b.eq smc64_psci_cpu_suspend

     // is this CPU_OFF
    mov  w10, #0x0002
    cmp  w10, w11
    b.eq smc32_psci_cpu_off

     // is this CPU_ON
    mov  w10, #0x0003
    cmp  w10, w11
    b.eq smc64_psci_cpu_on

     // is this SYSTEM_OFF
    mov  w10, #0x0008
    cmp  w10, w11
    b.eq smc32_psci_system_off

     // is this SYSTEM_RESET
    mov  w10, #0x0009
    cmp  w10, w11
    b.eq smc32_psci_system_reset

     // is this PSCI_FEATURES
    mov  w10, #0x000A
    cmp  w10, w11
    b.eq smc32_psci_features

     // if we are here then we have an unimplemented/unrecognized function
    b smc_func_unimplemented

//-----------------------------------------------------------------------------

smc64_psci_cpu_suspend:
     // x0 = function id
     // x1 = power state
     // x2 = entry point address
     // x3 = context id
    mov  x12, x30
    mov  x8, x1
    mov  x9, x2
    mov  x10, x3
     // x8  = power state
     // x9  = entry point address
     // x10 = context id

     // check parameters
    ldr  x0, =POWER_STATE_MASK
    mvn  x0, x0
    and  x0, x1, x0
    cbnz x0, psci_invalid

     // power level
    ldr  x0, =POWER_LEVEL_MASK
    and  x0, x1, x0
    lsr  x0, x0, #24
    cmp  x0, #PWR_STATE_CORE_LVL
    b.eq power_state_core
    cmp  x0, #PWR_STATE_CLUSTER_LVL
    b.eq power_state_cluster
    cmp  x0, #PWR_STATE_SYSTEM_LVL
    b.eq power_state_system
    b    psci_invalid

 // if it is a core power state
power_state_core:
     // x8  = power state
     // x9  = entry point address
     // x10 = context id

    ldr  x0, =STATE_TYPE_MASK
    and  x0, x8, x0
    lsr  x0, x0, #16

    cmp  x0, #PWR_STATE_STANDBY
    b.eq core_in_standby
    cmp  x0, #PWR_STATE_PWR_DOWN
    b.eq core_in_powerdown
     // else we have an invalid parameter
    b    psci_invalid

core_in_standby:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_CORE_STANDBY
    cbz  x7, psci_unimplemented

    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x8, x0
    mov  x1, #CORE_STANDBY
    saveCoreData x0 x1 CORE_STATE_DATA

     // w8 = core mask lsb

     // put the core into standby
    mov  x0, x8
    bl   _soc_core_entr_stdby

     // cleanup after the core exits standby
    mov  x0, x8
    bl   _soc_core_exit_stdby

    mov  x0, x8
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA
    b    psci_success

core_in_powerdown:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_CORE_PWR_DWN
    cbz  x7, psci_unimplemented

     // x9  = entry point address
     // x10 = context id

    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x8, x0
    mov  x1, x10
    saveCoreData x0 x1 CNTXT_ID_DATA

     // x8 = core mask lsb
     // x9  = entry point address

     // save entry point address
    mov  x0, x8
    mov  x1, x9
    saveCoreData x0 x1 START_ADDR_DATA

     // x8 = core mask lsb

    mov  x0, x8
    mov  x1, #CORE_PWR_DOWN
    saveCoreData x0 x1 CORE_STATE_DATA

     // save cpuectlr
    mrs  x1, CPUECTLR_EL1
    mov  x0, x8
    bl   _save_CPUECTLR

     // save the core mask and enter power-down
    mov  x9, x8
    mov  x0, x9
    bl   _soc_core_entr_pwrdn

     // x9 = core mask lsb

    mov  x0, x9
    bl   _soc_core_exit_pwrdn

    mov  x0, x9
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA

     // restore cpuectlr
    mov  x0, x9
    bl   _get_saved_CPUECTLR
    msr  CPUECTLR_EL1, x0

     // set the spsr for exit from EL3
    bl   _set_spsr_4_exit

     // x9 = core mask lsb

     // return to entry point address
    mov  x0, x9
    getCoreData x0 START_ADDR_DATA
    msr  ELR_EL3, x0

    mov  x0, x9
    getCoreData x0 CNTXT_ID_DATA

     // we have a context id in x0 - don't overwrite this
     // with a status return code
    b    psci_completed

     //------------------------------------------

 // if it is a cluster power state
power_state_cluster:
     // x8  = power state
     // x9  = entry point address
     // x10 = context id

     // get mpidr, extract cluster number
    mrs  x0, mpidr_el1
    and  x0, x0, #MPIDR_CLUSTER_MASK

     // x0 = cluster number in mpidr format

     // see if this is the last active core of the cluster
    bl   core_on_cnt_clstr

     // if this is not the last active core of the cluster, return with error
    cmp  x0, #1
    b.gt psci_invalid

     // determine the power level
    ldr  x0, =STATE_TYPE_MASK
    and  x0, x8, x0
    lsr  x0, x0, #16

    cmp  x0, #PWR_STATE_STANDBY
    b.eq cluster_in_stdby
    cmp  x0, #PWR_STATE_PWR_DOWN
    b.eq cluster_in_pwrdn
     // else we have an invalid parameter
    b    psci_invalid

cluster_in_stdby:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_CLUSTER_STANDBY
    cbz  x7, psci_unimplemented

     // to put the cluster in stdby, we also have to 
     // put this core in stdby
    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x8, x0
    mov  x1, #CORE_STANDBY
    saveCoreData x0 x1 CORE_STATE_DATA

     // w8 = core mask lsb

    mov  x0, x8
    bl   _soc_clstr_entr_stdby

     // cleanup after the cluster exits standby
    mov  x0, x8
    bl   _soc_clstr_exit_stdby

    mov  x0, x8
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA
    b    psci_success

cluster_in_pwrdn:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_CLUSTER_PWR_DWN
    cbz  x7, psci_unimplemented

     // x9  = entry point address
     // x10 = context id

    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x12, x0
    mov  x1, x10
    saveCoreData x0 x1 CNTXT_ID_DATA

     // x9  = entry point address
     // x12 = core mask

     // save entry point address
    mov  x0, x12
    mov  x1, x9
    saveCoreData x0 x1 START_ADDR_DATA

     // x12 = core mask

     // to put the cluster in power down, we also
     // have to power-down this core
    mov  x0, x12
    mov  x1, #CORE_PWR_DOWN
    saveCoreData x0 x1 CORE_STATE_DATA

     // save cpuectlr
    mrs  x1, CPUECTLR_EL1
    mov  x0, x12
    bl   _save_CPUECTLR

    mov  x0, x12
    bl   _soc_clstr_entr_pwrdn

     // cleanup after the cluster exits power-down
    mov  x0, x12
    bl   _soc_clstr_exit_pwrdn

    mov  x0, x12
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA

     // restore cpuectlr
    mov  x0, x12
    bl   _get_saved_CPUECTLR
    msr  CPUECTLR_EL1, x0

     // set the spsr for exit from EL3
    bl   _set_spsr_4_exit

     // return to entry point address
    mov  x0, x12
    getCoreData x0 START_ADDR_DATA
    msr  ELR_EL3, x0

    mov  w0, w12
    getCoreData x0 CNTXT_ID_DATA

     // we have a context id in x0 - don't overwrite this
     // with a status return code
    b    psci_completed

     //------------------------------------------

 // if it is a system power state
power_state_system:
     // x8  = power state
     // x9  = entry point address
     // x10 = context id

     // see if this is the last active core of the system
    bl   core_on_cnt_sys

     // if this is not the last active core of the system, return with error
    cmp  x0, #1
    b.gt  psci_invalid

     // determine the power level
    ldr  x0, =STATE_TYPE_MASK
    and  x0, x8, x0
    lsr  x0, x0, #16

    cmp  x0, #PWR_STATE_STANDBY
    b.eq system_in_stdby
    cmp  x0, #PWR_STATE_PWR_DOWN
    b.eq system_in_pwrdn
     // else we have an invalid parameter
    b    psci_invalid

system_in_stdby:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_SYSTEM_STANDBY
    cbz  x7, psci_unimplemented

     // to put the system in stdby, we also have to 
     // put this core in stdby
    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x8, x0
    mov  x1, #CORE_STANDBY
    saveCoreData x0 x1 CORE_STATE_DATA

     // x8 = core mask lsb

    mov  x0, x8
    bl   _soc_sys_entr_stdby

     // cleanup after the system exits standby
    mov  x0, x8
    bl   _soc_sys_exit_stdby

    mov  x0, x8
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA
    b    psci_success

system_in_pwrdn:
     // see if this functionality is supported in the soc-specific code
    mov  x7, #SOC_SYSTEM_PWR_DWN
    cbz  x7, psci_unimplemented

     // x9  = entry point address
     // x10 = context id

    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb
    mov  x12, x0
    mov  x1, x10
    saveCoreData x0 x1 CNTXT_ID_DATA

     // x9  = entry point address
     // x12 = core mask

     // save entry point address
    mov  x0, x12
    mov  x1, x9
    saveCoreData x0 x1 START_ADDR_DATA

     // x12 = core mask

    mov  x0, x12
    mov  x1, #CORE_PWR_DOWN
    saveCoreData x0 x1 CORE_STATE_DATA

     // save cpuectlr
    mrs  x1, CPUECTLR_EL1
    mov  x0, x12
    bl   _save_CPUECTLR

    mov  x0, x12
    bl   _soc_sys_entr_pwrdn

     // cleanup after the system exits power-down
    mov  x0, x12
    bl   _soc_sys_exit_pwrdn

     // x12 = core mask lsb

    mov  x0, x12
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA

     // restore cpuectlr
    mov  x0, x12
    bl   _get_saved_CPUECTLR
    msr  CPUECTLR_EL1, x0

     // clear SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    bic  x0, x0, #0x2
    msr  SCR_EL3, x0

    mov  x0, x12
    mov  x1, #CORE_RELEASED
    saveCoreData x0 x1 CORE_STATE_DATA

     // set the spsr for exit from EL3
    bl   _set_spsr_4_exit

     // return to entry point address
    mov  x0, x12
    getCoreData x0 START_ADDR_DATA
    msr  ELR_EL3, x0

    mov  w0, w12
    getCoreData x0 CNTXT_ID_DATA

     // we have a context id in x0 - don't overwrite this
     // with a status return code
    b    psci_completed

//-----------------------------------------------------------------------------

smc64_psci_cpu_on:
     // x0   = function id 
     // x1   = target cpu (mpidr)
     // x2   = start address
     // x3   = context id

	 // save the LR
    mov  x12, x30

	 // save input parms
	mov  x6, x1
    mov  x7, x2
    mov  x8, x3

     // get EL level of caller
    bl   _get_caller_EL
    cmp   x0, #CORE_EL1
    b.eq  1f
    cmp   x0, #CORE_EL2
    b.eq  1f
    b     psci_denied 
1:
     // get spsr_el3 in x4
    mrs   x4, spsr_el3

     // x4   = spsr_el3 of caller
     // x6   = target cpu (mpidr)
     // x7   = start address
     // x8   = context id

     // get the core mask
    mov  x0, x6
    bl   _get_core_mask_lsb
    cbnz x0, 4f
     // we have an invalid parameter (mpidr)
    b    psci_invalid
4:
    mov  x5, x0

     // x4   = spsr_el3 of caller
     // x5   = core mask (lsb)
     // x6   = target cpu (mpidr)
     // x7   = start address
     // x8   = context id

     // check if core disabled
    bl   _soc_ck_disabled
    cbnz w0, psci_disabled

     // check core data area to see if core cannot be turned on
     // read the core state
    mov  x0, x5
    getCoreData x0 CORE_STATE_DATA

    cmp  x0, #CORE_DISABLED
    b.eq psci_disabled
    cmp  x0, #CORE_PENDING
    b.eq psci_on_pending
    cmp  x0, #CORE_RELEASED
    b.eq psci_already_on
    mov  x9, x0

     // x4   = spsr_el3 of caller
     // x5   = core mask (lsb)
     // x6   = target cpu (mpidr)
     // x7   = start address
     // x8   = context id
     // x9   = core state (from data area)

     // save spsr_el3 in data area
    mov  x0, x5
    mov  x1, x4
    saveCoreData x0 x1 SPSR_EL3_DATA

     // save +
    and   x1, x4, #SPSR_EL_MASK
    mov   x0, x5
    bl    _save_core_sctlr

     // set start addr in data area
    mov  x0, x5
    mov  x1, x7
    saveCoreData x0 x1 START_ADDR_DATA

     // set context id in data area
    mov  x0, x5
    mov  x1, x8
    saveCoreData x0 x1 CNTXT_ID_DATA

     // load the soc with the address for the secondary core to jump to
     // when it completes execution in the bootrom
    adr  x0, _secondary_core_init
    bl   _soc_set_start_addr

     // reread the state here
    mov  x0, x5
    getCoreData x0 CORE_STATE_DATA
    mov  x9, x0
    
    cmp  x9, #CORE_IN_RESET
    b.eq core_in_reset
    cmp  x0, #CORE_OFF
    b.eq core_is_off
    cmp  x0, #CORE_OFF_PENDING
     // if state == CORE_OFF_PENDING, set abort
    mov  x0, x5
    bl   set_psci_abort
    ldr  x3, =PSCI_ABORT_CNT

7:
     // watch for abort to take effect
    mov  x0, x5
    getCoreData x0 CORE_STATE_DATA
    cmp  x0, #CORE_OFF
    b.eq core_is_off
    cmp  x0, #CORE_PENDING
    b.eq psci_success

     // loop til finished
    sub  x3, x3, #1
    cbnz x3, 7b

     // if we didn't see either CORE_OFF or CORE_PENDING, then this
     // core is in CORE_OFF_PENDING - exit with success, as the core will
     // respond to the abort request
    b   psci_success

 // this is where we start up a core out of reset
core_in_reset:
     // see if the soc-specific module supports this op
    ldr  x7, =SOC_CORE_RELEASE
    cbz  x7, psci_unimplemented

     // x5   = core mask (lsb)

     // set core state in data area
    mov  x0, x5
    mov  x1, #CORE_PENDING
    saveCoreData x0 x1 CORE_STATE_DATA

     // release the core from reset and wait til it's up (or timeout)
    mov   w0, w5
    bl    _soc_core_rls_wait
    cbz   x0, psci_success
     // the core failed to come out of reset
    b     psci_failure

 // this is where we start up a core that has been powered-down via CPU_OFF
core_is_off:
     // see if the soc-specific module supports this op
    ldr  x7, =SOC_CORE_RESTART
    cbz  x7, psci_unimplemented

     // x5 = core mask (lsb)

     // set core state in data area
    mov  x0, x5
    mov  x1, #CORE_PENDING
    saveCoreData x0 x1 CORE_STATE_DATA

     // put the core back into service
    mov  w0, w5
    bl   _soc_core_restart    
    b    psci_success

//-----------------------------------------------------------------------------

smc64_psci_affinity_info:
     // x1 = target_affinity
     // x2 = lowest_affinity

     // save the LR
    mov  x12, x30

     // core affinity?
    mov   x0, #0
    cmp   x2, x0
    b.eq  affinity_info_0

     // cluster affinity?
    mov   x0, #1
    cmp   x2, x0
    b.eq  affinity_info_1

     // no other processing elements are present
    b   psci_not_present

affinity_info_0:
     // status of an individual core
     // x1 = target_affinity

    mov   x0, x1
    bl    _get_core_mask_lsb
    cbz   x0, psci_not_present

     // x0 = core mask

     // process cores here
    getCoreData x0 CORE_STATE_DATA

     // x0 = core state

     // ck for core disabled
    ldr   x1, =CORE_DISABLED
    cmp   x0, x1
    b.ne  1f
    b     psci_disabled

1:
     // ck for core pending
    ldr   x1, =CORE_PENDING
    cmp   x0, x1
    b.ne  2f
    b     affinity_lvl_pend

2:
     // ck for core on
    ldr   x1, =CORE_RELEASED
    cmp   x0, x1
    b.ne  3f
    b     affinity_lvl_on

3:
     // must be core off
    b     affinity_lvl_off

affinity_info_1:
     // status of a cluster
     // x1 = target_affinity

     // isolate and check the cluster number
    mov   x2, xzr
    bfxil x2, x1, #8, #8
    ldr   x3, =CLUSTER_COUNT
    cmp   x3, x2
    b.le  psci_not_present

     // x2 = cluster number

    bl    get_cluster_state
    b     psci_success

//-----------------------------------------------------------------------------

smc32_psci_version:
     // save the LR
    mov  x12, x30

    ldr  x0, =PSCI_VERSION
    b    psci_completed

//-----------------------------------------------------------------------------

smc32_psci_cpu_off:
     // see if the soc-specific module supports this op
    ldr  x7, =SOC_CORE_OFF
    cbz  x7, psci_unimplemented

     // save link register initially in x12 
    mov  x12, x30

     // get EL level of core
     //  - err return if 0 or 3
    bl    _get_caller_EL
     // see if core is EL0
    mov   x1, #CORE_EL0
    cmp   x0, x1
    b.eq  psci_denied

     // see if core is EL3
    mov   x1, #CORE_EL3
    cmp   x0, x1
    b.eq  psci_denied

     // check if this is the last core on
     // cpu_off cannot be used to power-down the final core
    bl   coreOnCount
    cmp  x0, #1
    b.eq psci_denied

    mrs  x0, MPIDR_EL1      
    bl   _get_core_mask_lsb 
    mov  x10, x0
    getCoreData x0 CORE_STATE_DATA

     // x0  = core state
     // x10 = core mask lsb

     // only cores in the ON, or the ON_PENDING state can be turned OFF
    cmp  x0, #CORE_ON_MIN
    b.lt psci_denied

     // there are no further error returns
     // x10 = core mask lsb

     // change state of core in data area
    mov  x0, x10 
    mov  x1, #CORE_OFF_PENDING
    saveCoreData x0 x1 CORE_STATE_DATA

     // shutdown the core - phase 1
    mov  x0, x10 
    bl   _soc_core_phase1_off

     // x10 = core mask (lsb)

     //  check for abort flag - if the abort flag is set, that means
     // that while we are in the process of shutting this core down,
     // we have received a request to power it up - this can happen
     // becasue of the extreme latency to shut a core down
    mov  x0, x10
    bl   get_psci_abort
    cbz  x0, 4f

     // process the abort
    mov  x0, x10
    bl   _psci_processAbort
    b    2f

4:
     // x10 = core mask (lsb)
  
    // save link register in data area
    mov  x0, x10
    mov  x1, x12
    saveCoreData x0 x1 LINK_REG_DATA

     // x10 = core mask (lsb)

     // shutdown the core - phase 2
    mov  x0, x10
    bl   _soc_core_phase2_off

     // x10 = core mask (lsb) 

     //  check for abort flag - if the abort flag is set, that means
     // that while we are in the process of shutting this core down,
     // we have received a request to power it up - this can happen
     // because of the extreme latency to shut a core down
    mov  x0, x10
    bl   get_psci_abort
    cbz  x0, 5f

     // process the abort
    mov  x0, x10
    bl   _psci_processAbort
    b    3f

5:
     // shutdown the core
    mov  x0, x10
    bl   _soc_core_entr_off

     // start the core back up
    bl   _soc_core_exit_off

     // x10 = core mask (lsb)
3:
     // cleanup from phase2
    mov  x0, x10
    bl   _soc_core_phase2_clnup
2:
     // cleanup from phase1
    mov  x0, x10
    bl   _soc_core_phase1_clnup

     // xfer to the monitor
    b    _mon_core_restart

//-----------------------------------------------------------------------------

smc32_psci_system_off:
     // see if the soc-specific module supports this op
    ldr  x7, =SOC_SYSTEM_OFF
    cbz  x7, psci_unimplemented

//-----------------------------------------------------------------------------

smc32_psci_system_reset:
     // see if the soc-specific module supports this op
    ldr  x7, =SOC_SYSTEM_RESET
    cbz  x7, psci_unimplemented

     // save link register
    mov  x12, x30

     // system reset is soc-specific
    bl   _soc_sys_reset
    b    psci_completed

//-----------------------------------------------------------------------------

smc32_psci_features:
    b  psci_unimplemented

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// returns for affinity_info

affinity_lvl_on:
    mov  x0, #AFFINITY_LEVEL_ON
    b    psci_completed

     //------------------------------------------

affinity_lvl_off:
    mov  x0, #AFFINITY_LEVEL_OFF
    b    psci_completed

     //------------------------------------------

affinity_lvl_pend:
    mov  x0, #AFFINITY_LEVEL_PEND
    b    psci_completed

//-----------------------------------------------------------------------------
// psci std returns

psci_disabled:
    ldr  w0, =PSCI_DISABLED
    b    psci_completed

     //------------------------------------------

psci_not_present:
    ldr  w0, =PSCI_NOT_PRESENT
    b    psci_completed

     //------------------------------------------

psci_on_pending:
    ldr  w0, =PSCI_ON_PENDING
    b    psci_completed

     //------------------------------------------

psci_already_on:
    ldr  w0, =PSCI_ALREADY_ON
    b    psci_completed

     //------------------------------------------

psci_failure:
    ldr  w0, =PSCI_INTERNAL_FAILURE
    b    psci_completed

     //------------------------------------------

psci_unimplemented:
    ldr  w0, =PSCI_NOT_SUPPORTED
    b    psci_completed

     //------------------------------------------

psci_denied:
    ldr  w0, =PSCI_DENIED
    b    psci_completed

     //------------------------------------------

psci_invalid:
    ldr  w0, =PSCI_INVALID_PARMS
    b    psci_completed

     //------------------------------------------

psci_success:
    mov  x0, #PSCI_SUCCESS

psci_completed:
     // restore the LR
    mov  x30, x12
     // zero-out the scratch registers
    mov  x1,  #0
    mov  x2,  #0
    mov  x3,  #0
    mov  x4,  #0
    mov  x5,  #0
    mov  x6,  #0
    mov  x7,  #0
    mov  x8,  #0
    mov  x9,  #0
    mov  x10, #0
    mov  x11, #0
    mov  x12, #0
     // return from exception
    eret

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

 // this function initializes the core data areas
 // only executed by the boot core
 // in:   none
 // out:  none
 // uses: x0, x1, x2, x3, x4, x5
_initialize_psci:
     // save link reg
    mov   x5, x30

     // init bootcore data
    mov   x3, #1
    mov   x2, #CORE_RELEASED
    mov   x4, #CPU_MAX_COUNT
1:
     // x2 = core state
     // x3 = core mask bit
     // x4 = loop counter

    mov   x0, x3
    bl    _get_core_data

     // x0 = core data area base address

    str   x2,  [x0, #STATE_DATA_OFFSET]
    str   wzr, [x0, #SPSR_EL3_DATA_OFFSET]
    str   xzr, [x0, #CNTXT_DATA_OFFSET]
    str   xzr, [x0, #START_DATA_OFFSET]
    str   xzr, [x0, #LR_DATA_OFFSET]
    str   wzr, [x0, #GICC_CTLR_DATA_OFFSET]
    str   wzr, [x0, #ABORT_FLAG_OFFSET]

     // loop control
    sub  x4, x4, #1
    cbz  x4, 3f

     // generate the next core mask bit
    lsl  x3, x3, #1

     // set core state in x2
    mov  x0, x3
    bl   _soc_ck_disabled
    mov  x2, #CORE_IN_RESET
    cbz  x0, 1b
    mov  x2, #CORE_DISABLED
    b    1b
3:
    mov   x30, x5
    ret

//-----------------------------------------------------------------------------

 // this function returns the state of a cluster
 // in:  x0 = 0-based cluster number
 // out: x0 = AFFINITY_LEVEL_ON (at least one core of the cluster is ON)
 //      x0 = AFFINITY_LEVEL_OFF (all cores of the cluster are [OFF | DISABLED | RESET])
 //      x0 = AFFINITY_LEVEL_PEND (at least one core is ON_PENDING and no cores are ON)
 // uses: x0, x1, x2, x3, x4, x5, x6
get_cluster_state:
     // save link register
    mov   x6, x30

    mov   x3, #CPU_PER_CLUSTER
    mov   x4, #AFFINITY_LEVEL_OFF
    orr   x5, xzr, x0, LSL #8

     // x3 = loop count
     // x4 = cluster state
     // x5 = mpidr of core
3:
    mov   x0, x5
    bl    _get_core_mask_lsb
    getCoreData x0 CORE_STATE_DATA

    mov   x1, #CORE_RELEASED
    cmp   x0, x1
    b.eq  1f

    mov   x1, #CORE_PENDING

    b.ne  4f
    mov   x4, #AFFINITY_LEVEL_PEND
4:
     // increment to next core
    add   x5, x5, #1
     // decrement loop counter
    sub   x3, x3, #1
     // exit if done
    cbz   x3, 2f
    b     3b

1:
    mov   x4, #AFFINITY_LEVEL_ON
2:
    mov   x0, x4
    mov   x30, x6
    ret

//-----------------------------------------------------------------------------

 // this function selects the base address to a cpu data area
 // in:  x0 = core mask lsb
 // out: x0 = base address to core data area
 // uses x0
_get_core_data:

    cmp   x0, #CORE_0_MASK
    b.ne  1f
    adr   x0, cpu0_data
    b     99f    
1:
    cmp   x0, #CORE_1_MASK
    b.ne  2f
    adr   x0, cpu1_data
    b     99f    
2:

.if (CPU_MAX_COUNT > 2)
    cmp   x0, #CORE_2_MASK
    b.ne  3f
    adr   x0, cpu2_data
    b     99f    
3:
    cmp   x0, #CORE_3_MASK
    b.ne  4f
    adr   x0, cpu3_data
    b     99f    
4:
.endif

.if (CPU_MAX_COUNT > 4)
    cmp   x0, #CORE_4_MASK
    b.ne  5f
    adr   x0, cpu4_data
    b     99f    
5:
    cmp   x0, #CORE_5_MASK
    b.ne  6f
    adr   x0, cpu5_data
    b     99f    
6:
    cmp   x0, #CORE_6_MASK
    b.ne  7f
    adr   x0, cpu6_data
    b     99f    
7:
    cmp   x0, #CORE_7_MASK
    b.ne  8f
    adr   x0, cpu7_data
    b     99f    
8:
.endif

.if (CPU_MAX_COUNT > 8)
    cmp   x0, #CORE_8_MASK
    b.ne  9f
    adr   x0, cpu8_data
    b     99f    
9:
    cmp   x0, #CORE_9_MASK
    b.ne  10f
    adr   x0, cpu9_data
    b     99f    
10:
    cmp   x0, #CORE_10_MASK
    b.ne  11f
    adr   x0, cpu10_data
    b     99f    
11:
    cmp   x0, #CORE_11_MASK
    b.ne  12f
    adr   x0, cpu11_data
    b     99f    
12:
.endif

.if (CPU_MAX_COUNT > 12)
    cmp   x0, #CORE_12_MASK
    b.ne  13f
    adr   x0, cpu12_data
    b     99f    
13:
    cmp   x0, #CORE_13_MASK
    b.ne  14f
    adr   x0, cpu13_data
    b     99f    
14:
    cmp   x0, #CORE_14_MASK
    b.ne  15f
    adr   x0, cpu14_data
    b     99f    
15:
    cmp   x0, #CORE_15_MASK
    b.ne  16f
    adr   x0, cpu15_data
    b     99f    
16:
.endif

 // if assembly stops here, you need to add more data areas
.if (CPU_MAX_COUNT > 16)
.err
.endif

99:
    ret

//-----------------------------------------------------------------------------

 // this function stores the sctlr_elx value of the calling entity
 // in:   w0 = core mask (lsb)
 //       w1 = SPSR EL-level (must be one of: SPSR_EL1, SPSR_EL2)
 // uses: x0, x1, x2
_save_core_sctlr:
    mov   x2, x30

     // x0 = core mask lsb

    cmp   w1, #SPSR_EL1
    b.eq  1f
    mrs   x1, sctlr_el2
    b     2f
1:
    mrs   x1, sctlr_el1
2:

     // x0 = core mask lsb
     // x1 = sctlr value to save

    saveCoreData x0 x1 SCTLR_DATA

    mov   x30, x2 
    ret

//-----------------------------------------------------------------------------

 // this function returns the abort flag value of the specified core
 // in:   w0 = core mask (lsb)
 // out:  x0 = abort value
 // uses: x0, x1
get_psci_abort:

    mov   x1, x30
    bl    _get_core_data
    add   x0, x0, #ABORT_FLAG_OFFSET
    dc    ivac, x0
    dsb   sy
    isb  
    ldr   w0, [x0]  
    mov   x30, x1 
    ret

//-----------------------------------------------------------------------------

 // this function returns the abort flag value of the specified core
 // in:   w0 = core mask (lsb)
 // out:  none
 // uses: x0, x1, x2
set_psci_abort:

    mov   x2, x30
    bl    _get_core_data
    ldr   w1, =CORE_ABORT_OP 
    add   x0, x0, #ABORT_FLAG_OFFSET
    str   w1, [x0]  
    dc    cvac, x0
    dsb   sy
    isb  
    mov   x30, x2 
    ret

//-----------------------------------------------------------------------------

 // this function returns the saved SCTLR value
 // in:   w0 = core mask (lsb)
 // out:  w0 = SCTLR value
 // uses: x0, x1
_get_saved_CPUECTLR:

    mov   x1, x30
    bl    _get_core_data
    add   x0, x0, #CPUECTLR_OFFSET
    dc    ivac, x0
    dsb   sy
    isb  
    ldr   w0, [x0]
    mov   x30, x1 
    ret

//-----------------------------------------------------------------------------

 // this function saves the caller's sctlr
 // in:   w0 = core mask (lsb)
 //       w1 = SCTLR value
 // uses: x0, x1, x2
_save_CPUECTLR:

    mov   x2, x30
    bl    _get_core_data
    add   x0, x0, #CPUECTLR_OFFSET
    str   w1, [x0] 
    dc    cvac, x0
    dsb   sy
    isb  
    mov   x30, x2 
    ret

//-----------------------------------------------------------------------------

 // this function processes a request to abort CPU_OFF - an abort request can
 // occur if we are processing CPU_OFF, and a CPU_ON is issued for the same core
 // in:   w0 = core mask (lsb)
 // out:  none
 // uses: x0, x1, x2
_psci_processAbort:

    mov   x2, x30
    bl    _get_core_data
     // clear the abort flag
    str   wzr, [x0, #ABORT_FLAG_OFFSET] 

     // set the core state to CORE_PENDING
    ldr   w1, =CORE_PENDING
    str   w1, [x0, #STATE_DATA_OFFSET]  
    mov   x30, x2 
    ret

//-----------------------------------------------------------------------------

 // this function locates a core that is available to perform an
 // initialization task
 // in:  none
 // out: x0 = 0, no available core
 //      x0 = core mask lsb of available core
 // uses x0, x1, x2, x3, x4 
_find_core:

    mov  x2, x30

     // start the search at core 1
    mov  x4, #2
3:
     // see if core is disabled
    mov  x0, x4
    bl    _soc_ck_disabled
    cbnz  x0, 1f

     // see if core is in reset - this is the state we want
    mov  x0, x4
    getCoreData x0 CORE_STATE_DATA
    ldr  x3, =CORE_IN_RESET
    cmp  x0, x3
    mov  x0, x4
    b.eq 2f 
1:
    cmp  x4, #CORE_MASK_MAX
    mov  x0, xzr
    b.eq 2f

    lsl  x4, x4, #1
    b    3b
2:
    mov  x30, x2
    ret

//-----------------------------------------------------------------------------

 // this function returns the number of cores that are ON in the LS2080, based on
 // the core state read from each core's data area. The current core will be counted
 // as 'ON' if its data area indicates so
 // in:   none
 // out:  x0 = number of cores that are ON
 // uses: x0, x1, x2, x3, x4, x5
coreOnCount:
    mov x3, x30    
    ldr x4, =CPU_MAX_COUNT 
    mov x2, xzr
    mov x5, #1

     // x2 = number of cores on
     // x3 = LR
     // x4 = loop count
     // x5 = core mask lsb
1:  
    mov  x0, x5
    getCoreData x0 CORE_STATE_DATA

     // if core state <= CORE_OFF_MAX, core is OFF
    cmp  x0, #CORE_OFF_MAX
    b.ls 2f
     // core is not OFF, so increment count                  
    add  x2, x2, #1

2:  
     // decrement loop counter
    sub  x4, x4, #1
    cbz  x4, 3f
     // shift mask bit to select next core
    lsl  x5, x5, #1
    b    1b

3:
     // put result in R0, and restore link register
    mov  x0, x2     
    mov  x30, x3     
    ret

//-----------------------------------------------------------------------------

 // this function determines if a given mpidr value is valid for this SoC
 // in:  x0 = mpidr[15:0]
 // out: x0 == 0, mpidr not valid
 //      x0 != 0, mpidr is valid
 // uses x0, x1, x2
is_mpidr_valid:

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

 //----------------------------------------------------------------------------

 // this function returns the number of active cores in the given cluster
 // in:  x0 = cluster number (mpidr format)
 // out: x0 = count of cores running
 // uses x0, x1, x2, x3, x4, x5, x6
core_on_cnt_clstr:
    mov  x6, x30
    and  x4, x0, #MPIDR_CLUSTER_MASK
    ldr  x3, =CPU_PER_CLUSTER
    mov  x5, xzr

     // x3 = loop count
     // x4 = core mpidr
     // x5 = accumulated count of running cores
     // x6 = saved link reg

3:
    mov  x0, x4
    bl   _get_core_mask_lsb

     // x0 = core mask lsb
    getCoreData x0 CORE_STATE_DATA

     // x0 = core state
    cmp  x0, #CORE_OFF_MAX
    b.le 1f
    add  x5, x5, #1
1:
     // decrement the loop count and exit if finished
    sub  x3, x3, #1
    cbz  x3, 2f

     // increment to the next core
    add  x4, x4, #1
    b    3b

2:
     // xfer the count to the output reg
    mov  x0, x5
    mov  x30, x6
    ret

 //----------------------------------------------------------------------------

 // this function returns the number of active cores in the system
 // in:  none
 // out: x0 = count of cores running
 // uses x0, x1, x2, x3, x4, x5, x6
core_on_cnt_sys:
    mov  x6, x30
    ldr  x3, =CPU_MAX_COUNT
    mov  x4, #1
    mov  x5, xzr

     // x3 = loop count
     // x4 = core mask lsb
     // x5 = accumulated count of running cores
     // x6 = saved link reg

3:
    mov  x0, x4
    getCoreData x0 CORE_STATE_DATA

     // x0 = core state
    cmp  x0, #CORE_OFF_MAX
    b.le 1f
    add  x5, x5, #1
1:
     // decrement the loop count and exit if finished
    sub  x3, x3, #1
    cbz  x3, 2f

     // increment to the next core
    lsl  x4, x4, #1
    b    3b
2:
     // xfer the count to the output reg
    mov  x0, x5
    mov  x30, x6
    ret

 //----------------------------------------------------------------------------

 // include the data areas
#include "psci_data.h"

.align 4
save_gicd_ctlr:
    .4byte  0x0

     // the reservation granule, as read from the CTL_EL0 register, is 16-words
     // we need to reserve this much space to insure that there are no unexpected
     // accesses that will disturb the exclusive-access methodology
//.align 4
//lock_01:
//    .4byte  0x0  // lock at word 0
//    .4byte  0x0  // reserved for reservation granule word 01
//    .4byte  0x0  // reserved for reservation granule word 02
//    .4byte  0x0  // reserved for reservation granule word 03
//    .4byte  0x0  // reserved for reservation granule word 04
//    .4byte  0x0  // reserved for reservation granule word 05
//    .4byte  0x0  // reserved for reservation granule word 06
//    .4byte  0x0  // reserved for reservation granule word 07
//    .4byte  0x0  // reserved for reservation granule word 08
//    .4byte  0x0  // reserved for reservation granule word 09
//    .4byte  0x0  // reserved for reservation granule word 0A
//    .4byte  0x0  // reserved for reservation granule word 0B
//    .4byte  0x0  // reserved for reservation granule word 0C
//    .4byte  0x0  // reserved for reservation granule word 0D
//    .4byte  0x0  // reserved for reservation granule word 0E
//    .4byte  0x0  // reserved for reservation granule word 0F

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

