//-----------------------------------------------------------------------------
// 
// Copyright (c) 2016 Freescale Semiconductor, Inc.
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
#include "policy.h"
#include "psci.h"

//-----------------------------------------------------------------------------

#define SWLPM20_WA 1

#define DAIF_DATA  AUX_01_DATA

#define DEVDISR2_MASK_OFFSET  0x0
#define DEVDISR5_MASK_OFFSET  0x4
#define DEVDISR1_DATA_OFFSET  0x8
#define DEVDISR2_DATA_OFFSET  0xC
#define DEVDISR3_DATA_OFFSET  0x10
#define DEVDISR4_DATA_OFFSET  0x14
#define DEVDISR5_DATA_OFFSET  0x18
#define CPUACTLR_DATA_OFFSET  0x1C

#define IPSTPACK_RETRY_CNT    0x10000
#define DDR_SLEEP_RETRY_CNT   0x10000
#define CPUACTLR_EL1          S3_1_C15_C2_0
#define CPUACTLR_L1PCTL_MASK  0x0000E000
#define DDR_SDRAM_CFG_2_FRCSR 0x80000000
#define DDR_SDRAM_CFG_2_OFFSET 0x114
#define DDR_TIMING_CFG_4_OFFSET 0x160
#define DDR_CNTRL_BASE_ADDR   0x01080000

#define DLL_LOCK_MASK   0x3
#define DLL_LOCK_VALUE  0x2

#define ERROR_DDR_SLEEP       -1
#define ERROR_DDR_WAKE        -2
#define ERROR_NO_QUIESCE      -3

#define CORE_RESTARTABLE     0
#define CORE_NOT_RESTARTABLE 1

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
.global _soc_sys_off
.global _soc_core_entr_off
.global _soc_core_exit_off
.global _soc_core_phase1_off
.global _soc_core_phase2_off
.global _soc_core_phase1_clnup
.global _soc_core_phase2_clnup
.global _soc_core_restart

.global _get_current_mask
.global _getCoreData
.global _setCoreData

.global _soc_init_start
.global _soc_init_finish
.global _soc_init_percpu
.global _set_platform_security

.global _gic_base_addr

.global _soc_exit_boot_svcs

.global _soc_check_sec_enabled

 // only valid if ddr is being initialized
#if (DDR_INIT)
.global _membank_count_addr
.global _membank_data_addr
#endif

//-----------------------------------------------------------------------------

.equ  RESTART_RETRY_CNT,  3000

 // retry count for releasing cores from reset - should be > 0
.equ  CORE_RELEASE_CNT,   800 

//-----------------------------------------------------------------------------

 // this function performs any soc-specific initialization that is needed on 
 // a per-core basis
 // in:  none
 // out: none
 // uses none
_soc_init_percpu:

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core into standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8
_soc_core_entr_stdby:
    mov  x8, x30

     // X0 = core mask lsb

     // IRQ taken to EL3, set SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    orr  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

     // clean the L1 dcache
    mov  x0, xzr
    bl   _cln_inv_L1_dcache

    dsb  sy
    isb
    wfi

    mov  x30, x8
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
    bic  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

    isb
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core into a power-down state
 // ph20 is defeatured for this device, so pw15 is the lowest core pwr state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8
_soc_core_entr_pwrdn:
    mov  x8, x30

     // X0 = core mask lsb

     // mask interrupts by setting DAIF[7:4] to 'b1111
    mrs  x1, DAIF
    ldr  x0, =DAIF_SET_MASK
    orr  x1, x1, x0
    msr  DAIF, x1 

     // IRQ taken to EL3, set SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    orr  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

     // disable icache, dcache, mmu @ EL2 & EL1
    mov  x1, #SCTLR_I_C_M_MASK
    mrs  x0, sctlr_el1
    bic  x0, x0, x1
    msr  sctlr_el1, x0

     // disable dcache @ EL3
    mrs  x0, sctlr_el3
    bic  x0, x0, #SCTLR_C_MASK
    msr  sctlr_el3, x0

     // cln/inv L1 dcache
    mov  x0, #1
    bl   _cln_inv_L1_dcache

    dsb  sy
    isb
    wfi

    mov  x30, x8
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function cleans up after a core exits power-down
 // in:  x0 = core mask lsb
 // out: none
 // uses x0
_soc_core_exit_pwrdn:

     // X0 = core mask lsb

     // clear SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    bic  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

     // invalidate icache
    ic  iallu
    isb

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the cluster into a standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10
_soc_clstr_entr_stdby:
    mov  x10, x30

     // X0 = core mask lsb

     // IRQ taken to EL3, set SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    orr  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

     // clean L1/L2 dcache
    mov  x0, xzr
    bl   _cln_inv_all_dcache

    wfi

    mov  x30, x10
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function exits the cluster from a standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0
_soc_clstr_exit_stdby:

     // clear SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    bic  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core into a power-down state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10
_soc_clstr_entr_pwrdn:
    mov  x10, x30

     // X0 = core mask lsb

     // mask interrupts by setting DAIF[7:4] to 'b1111
    mrs  x1, DAIF
    ldr  x0, =DAIF_SET_MASK
    orr  x1, x1, x0
    msr  DAIF, x1 

     // IRQ taken to EL3, set SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    orr  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

     // disable icache, dcache, mmu @ EL2 & EL1
    mov  x1, #SCTLR_I_C_M_MASK
    mrs  x0, sctlr_el1
    bic  x0, x0, x1
    msr  sctlr_el1, x0

     // disable dcache @ EL3
    mrs  x0, sctlr_el3
    bic  x0, x0, #SCTLR_C_MASK
    msr  sctlr_el3, x0

     // cln/inv all dcache
    mov  x0, #1
    bl   _cln_inv_all_dcache

    dsb  sy
    isb
    wfi

    mov  x30, x10
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function cleans up after a cluster exits power-down
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4
_soc_clstr_exit_pwrdn:

     // clear SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    bic  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

     // invalidate icache
    ic  iallu
    isb

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the system into a standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10
_soc_sys_entr_stdby:
    mov  x10, x30

     // X0 = core mask lsb

     // IRQ taken to EL3, set SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    orr  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

     // clean L1/L2 dcache
    mov  x0, xzr
    bl   _cln_inv_all_dcache

    dsb  sy
    isb
    wfi

    mov  x30, x10
    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function exits the system from a standby state
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2
_soc_sys_exit_stdby:

     // clear SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    bic  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

    ret

//-----------------------------------------------------------------------------

 // part of CPU_SUSPEND
 // this function puts the calling core, and potentially the soc, into a
 // low-power state
 // in:  x0 = core mask lsb
 // out: x0 = 0, success
 //      x0 < 0, failure
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x13, x14, x15, x16, x17
_soc_sys_entr_pwrdn:
    mov  x10, x30

     // x0 = core mask lsb

     // save DAIF
    mrs  x2, DAIF
    mov  x6, x2
    mov  x1, #DAIF_DATA
    bl   _setCoreData

     // x6 = DAIF

     // mask interrupts at the core
    ldr  x0, =DAIF_SET_MASK
    orr  x6, x6, x0
    msr  DAIF, x6

     // disable icache, dcache, mmu @ EL1
    mov  x1, #SCTLR_I_C_M_MASK
    mrs  x0, sctlr_el1
    bic  x0, x0, x1
    msr  sctlr_el1, x0

     // disable dcache for EL3
    mrs x1, SCTLR_EL3
    bic x1, x1, #SCTLR_C_MASK
     // make sure icache is enabled
    orr x1, x1, #SCTLR_I_MASK      
    msr SCTLR_EL3, x1 
    isb

     // clean and invalidate all levels of dcache
    mov x0, #1
    bl  _cln_inv_all_dcache

     // set WFIL2_EN in SCFG_COREPMCR
    ldr  x0, =SCFG_COREPMCR_OFFSET
    ldr  x1, =COREPMCR_WFIL2
    bl   write_reg_scfg

     // set OVRD_EN in RCPM2_POWMGTDCR
    ldr  x0, =RCPM2_POWMGTDCR_OFFSET
    ldr  x1, =POWMGTDCR_OVRD_EN
    bl   write_reg_rcpm2

     // IRQ taken to EL3, set SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    orr  x0, x0, #SCR_IRQ_MASK
    msr  SCR_EL3, x0

     // read IPPDEXPCR0 @ RCPM_IPPDEXPCR0
    ldr  x0, =RCPM_IPPDEXPCR0_OFFSET
    bl   read_reg_rcpm
    mov  x7, x0

     // build an override mask for IPSTPCR4/IPSTPACK4/DEVDISR5
    mov  x5, xzr
    ldr  x6, =IPPDEXPCR_MASK2
    and  x6, x6, x7
    cbz  x6, 1f

     // x5 = override mask
     // x6 = IPPDEXPCR bits for DEVDISR5
     // x7 = IPPDEXPCR

     // get the overrides
    orr  x4, x5, #DEVDISR5_I2C_1
    tst  x6, #IPPDEXPCR_I2C1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR5_LPUART1
    tst  x6, #IPPDEXPCR_LPUART1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR5_FLX_TMR
    tst  x6, #IPPDEXPCR_FLX_TMR1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR5_OCRAM1
    tst  x6, #IPPDEXPCR_OCRAM1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR5_GPIO
    tst  x6, #IPPDEXPCR_GPIO1
    csel x5, x5, x4, EQ
1:    
     // store the DEVDISR5 override mask
    adr  x2, soc_data_area
    str  w5, [x2, #DEVDISR5_MASK_OFFSET]

     // build an override mask for IPSTPCR1/IPSTPACK1/DEVDISR2
    mov  x5, xzr
    ldr  x6, =IPPDEXPCR_MASK1
    and  x6, x6, x7
    cbz  x6, 2f

     // x5 = override mask
     // x6 = IPPDEXPCR bits for DEVDISR2

     // get the overrides
    orr  x4, x5, #DEVDISR2_FMAN1_MAC1
    tst  x6, #IPPDEXPCR_MAC1_1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC2
    tst  x6, #IPPDEXPCR_MAC1_2
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC3
    tst  x6, #IPPDEXPCR_MAC1_3
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC4
    tst  x6, #IPPDEXPCR_MAC1_4
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC5
    tst  x6, #IPPDEXPCR_MAC1_5
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC6
    tst  x6, #IPPDEXPCR_MAC1_6
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC9
    tst  x6, #IPPDEXPCR_MAC1_9
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1
    tst  x6, #IPPDEXPCR_FM1
    csel x5, x5, x4, EQ
    
2:
     // store the DEVDISR2 override mask
    adr  x2, soc_data_area
    str  w5, [x2, #DEVDISR2_MASK_OFFSET]

     // x5 = DEVDISR2 override mask

     // write IPSTPCR0 - no overrides
    ldr  x0, =RCPM2_IPSTPCR0_OFFSET
    ldr  x1, =IPSTPCR0_VALUE
    bl   write_reg_rcpm2

     // x5 = DEVDISR2 override mask

     // write IPSTPCR1 - overrides possible
    ldr  x0, =RCPM2_IPSTPCR1_OFFSET
    ldr  x1, =IPSTPCR1_VALUE
    bic  x1, x1, x5
    bl   write_reg_rcpm2

     // write IPSTPCR2 - no overrides
    ldr  x0, =RCPM2_IPSTPCR2_OFFSET
    ldr  x1, =IPSTPCR2_VALUE
    bl   write_reg_rcpm2

     // write IPSTPCR3 - no overrides
    ldr  x0, =RCPM2_IPSTPCR3_OFFSET
    ldr  x1, =IPSTPCR3_VALUE
    bl   write_reg_rcpm2

     // write IPSTPCR4 - overrides possible
    adr  x2, soc_data_area
    ldr  w6, [x2, #DEVDISR5_MASK_OFFSET]
    ldr  x0, =RCPM2_IPSTPCR4_OFFSET
    ldr  x1, =IPSTPCR4_VALUE
    bic  x1, x1, x6
    bl   write_reg_rcpm2

     // x5 = DEVDISR2 override mask
     // x6 = DEVDISR5 override mask

     // poll on IPSTPACK0
    ldr  x3, =RCPM2_IPSTPACKR0_OFFSET
    ldr  x4, =IPSTPCR0_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
3:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 14f
    sub  x7, x7, #1
    cbnz x7, 3b

14:
     // poll on IPSTPACK1
    ldr  x3, =IPSTPCR1_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
    bic  x4, x3, x5
    ldr  x3, =RCPM2_IPSTPACKR1_OFFSET
4:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 15f
    sub  x7, x7, #1
    cbnz x7, 4b

15:
     // poll on IPSTPACK2
    ldr  x3, =RCPM2_IPSTPACKR2_OFFSET
    ldr  x4, =IPSTPCR2_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
5:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 16f
    sub  x7, x7, #1
    cbnz x7, 5b

16:
     // poll on IPSTPACK3
    ldr  x3, =RCPM2_IPSTPACKR3_OFFSET
    ldr  x4, =IPSTPCR3_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
6:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 17f
    sub  x7, x7, #1
    cbnz x7, 6b

17:
     // poll on IPSTPACK4
    ldr  x3, =IPSTPCR4_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
    bic  x4, x3, x6
    ldr  x3, =RCPM2_IPSTPACKR4_OFFSET
7:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 18f
    sub  x7, x7, #1
    cbnz x7, 7b

18:
    adr  x7, soc_data_area

     // x5 = DEVDISR2 override mask
     // x6 = DEVDISR5 override mask
     // x7 = [soc_data_area]

     // save DEVDISR1 and load new value
    mov  x0, #DCFG_DEVDISR1_OFFSET
    bl   read_reg_dcfg
    mov  w13, w0
    mov  x0, #DCFG_DEVDISR1_OFFSET
    ldr  x1, =DEVDISR1_VALUE
    bl   write_reg_dcfg

     // save DEVDISR2 and load new value
    mov  x0, #DCFG_DEVDISR2_OFFSET
    bl   read_reg_dcfg
    mov  w14, w0
    mov  x0, #DCFG_DEVDISR2_OFFSET
    ldr  x1, =DEVDISR2_VALUE
    bic  x1, x1, x5
    bl   write_reg_dcfg

     // x6 = DEVDISR5 override mask
     // x7 = [soc_data_area]

     // save DEVDISR3 and load new value
    mov  x0, #DCFG_DEVDISR3_OFFSET
    bl   read_reg_dcfg
    mov  w15, w0
    mov  x0, #DCFG_DEVDISR3_OFFSET
    ldr  x1, =DEVDISR3_VALUE
    bl   write_reg_dcfg

     // save DEVDISR4 and load new value
    mov  x0, #DCFG_DEVDISR4_OFFSET
    bl   read_reg_dcfg
    mov  w16, w0
    mov  x0, #DCFG_DEVDISR4_OFFSET
    ldr  x1, =DEVDISR4_VALUE
    bl   write_reg_dcfg

     // save DEVDISR5 and load new value
    mov  x0, #DCFG_DEVDISR5_OFFSET
    bl   read_reg_dcfg
    mov  w17, w0
    mov  x0, #DCFG_DEVDISR5_OFFSET
    ldr  x1, =DEVDISR5_VALUE
    bic  x1, x1, x6
    bl   write_reg_dcfg

     // x7 = [soc_data_area]

     // save cpuactlr and disable data prefetch
    mrs  x0, CPUACTLR_EL1
    str  w0, [x7, #CPUACTLR_DATA_OFFSET]
    bic  x0, x0, #CPUACTLR_L1PCTL_MASK
    msr  CPUACTLR_EL1, x0

     // x6 = DEVDISR5 override mask

     // setup registers for cache-only execution
    ldr  x5, =IPSTPCR4_VALUE
    bic  x5, x5, x6
    mov  x6, #DDR_CNTRL_BASE_ADDR
    mov  x7, #DCSR_RCPM2_BASE
    mov  x8, #DCFG_BASE_ADDR
    dsb sy
    isb

     // set the DLL_LOCK cycle count
    ldr  w1, [x6, #DDR_TIMING_CFG_4_OFFSET]
    rev  w2, w1
    bic  w2, w2, #DLL_LOCK_MASK
    orr  w2, w2, #DLL_LOCK_VALUE
    rev  w1, w2
    str  w1, [x6, #DDR_TIMING_CFG_4_OFFSET]

     // x5  = ipstpcr4 (IPSTPCR4_VALUE bic DEVDISR5_MASK)
     // x6  = DDR_CNTRL_BASE_ADDR
     // x7  = DCSR_RCPM2_BASE
     // x8  = DCFG_BASE_ADDR
     // w13 = DEVDISR1 saved value
     // w14 = DEVDISR2 saved value
     // w15 = DEVDISR3 saved value
     // w16 = DEVDISR4 saved value
     // w17 = DEVDISR5 saved value

     // enter the cache-only sequence
    mov  x9, #CORE_RESTARTABLE
    bl   final_shutdown
    
     // when we are here, the core has come out of wfi and the SoC is back up

    mov  x30, x10
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

     // clear SCR_EL3[IRQ]
    mrs  x0, SCR_EL3
    bic  x0, x0, #0x2
    msr  SCR_EL3, x0

    ret

//-----------------------------------------------------------------------------

 // part of SYSTEM_OFF
 // this function turns off the SoC clocks
 // Note: this function is not intended to return, and the only allowable
 //       recovery is POR
 // in:  x0 = core mask lsb
 // out: x0 = 0, success
 //      x0 < 0, failure
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x13, x14, x15, x16, x17
_soc_sys_off:
    mov  x10, x30

     // x0 = core mask lsb

     // save DAIF
    mrs  x2, DAIF
    mov  x6, x2
    mov  x1, #DAIF_DATA
    bl   _setCoreData

     // x6 = DAIF

     // mask interrupts at the core
    ldr  x0, =DAIF_SET_MASK
    orr  x6, x6, x0
    msr  DAIF, x6

     // disable icache, dcache, mmu @ EL1
    mov  x1, #SCTLR_I_C_M_MASK
    mrs  x0, sctlr_el1
    bic  x0, x0, x1
    msr  sctlr_el1, x0

     // disable dcache for EL3
    mrs x1, SCTLR_EL3
    bic x1, x1, #SCTLR_C_MASK
     // make sure icache is enabled
    orr x1, x1, #SCTLR_I_MASK      
    msr SCTLR_EL3, x1 
    isb

     // clean and invalidate all levels of dcache
    mov x0, #1
    bl  _cln_inv_all_dcache

     // set WFIL2_EN in SCFG_COREPMCR
    ldr  x0, =SCFG_COREPMCR_OFFSET
    ldr  x1, =COREPMCR_WFIL2
    bl   write_reg_scfg

     // set OVRD_EN in RCPM2_POWMGTDCR
    ldr  x0, =RCPM2_POWMGTDCR_OFFSET
    ldr  x1, =POWMGTDCR_OVRD_EN
    bl   write_reg_rcpm2

     // read IPPDEXPCR0 @ RCPM_IPPDEXPCR0
    ldr  x0, =RCPM_IPPDEXPCR0_OFFSET
    bl   read_reg_rcpm
    mov  x7, x0

     // build an override mask for IPSTPCR4/IPSTPACK4/DEVDISR5
    mov  x5, xzr
    ldr  x6, =IPPDEXPCR_MASK2
    and  x6, x6, x7
    cbz  x6, 1f

     // x5 = override mask
     // x6 = IPPDEXPCR bits for DEVDISR5
     // x7 = IPPDEXPCR

     // get the overrides
    orr  x4, x5, #DEVDISR5_I2C_1
    tst  x6, #IPPDEXPCR_I2C1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR5_LPUART1
    tst  x6, #IPPDEXPCR_LPUART1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR5_FLX_TMR
    tst  x6, #IPPDEXPCR_FLX_TMR1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR5_OCRAM1
    tst  x6, #IPPDEXPCR_OCRAM1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR5_GPIO
    tst  x6, #IPPDEXPCR_GPIO1
    csel x5, x5, x4, EQ
1:    
     // store the DEVDISR5 override mask
    adr  x2, soc_data_area
    str  w5, [x2, #DEVDISR5_MASK_OFFSET]

     // build an override mask for IPSTPCR1/IPSTPACK1/DEVDISR2
    mov  x5, xzr
    ldr  x6, =IPPDEXPCR_MASK1
    and  x6, x6, x7
    cbz  x6, 2f

     // x5 = override mask
     // x6 = IPPDEXPCR bits for DEVDISR2

     // get the overrides
    orr  x4, x5, #DEVDISR2_FMAN1_MAC1
    tst  x6, #IPPDEXPCR_MAC1_1
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC2
    tst  x6, #IPPDEXPCR_MAC1_2
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC3
    tst  x6, #IPPDEXPCR_MAC1_3
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC4
    tst  x6, #IPPDEXPCR_MAC1_4
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC5
    tst  x6, #IPPDEXPCR_MAC1_5
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC6
    tst  x6, #IPPDEXPCR_MAC1_6
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1_MAC9
    tst  x6, #IPPDEXPCR_MAC1_9
    csel x5, x5, x4, EQ
    
    orr  x4, x5, #DEVDISR2_FMAN1
    tst  x6, #IPPDEXPCR_FM1
    csel x5, x5, x4, EQ
    
2:
     // store the DEVDISR2 override mask
    adr  x2, soc_data_area
    str  w5, [x2, #DEVDISR2_MASK_OFFSET]

     // x5 = DEVDISR2 override mask

     // write IPSTPCR0 - no overrides
    ldr  x0, =RCPM2_IPSTPCR0_OFFSET
    ldr  x1, =IPSTPCR0_VALUE
    bl   write_reg_rcpm2

     // x5 = DEVDISR2 override mask

     // write IPSTPCR1 - overrides possible
    ldr  x0, =RCPM2_IPSTPCR1_OFFSET
    ldr  x1, =IPSTPCR1_VALUE
    bic  x1, x1, x5
    bl   write_reg_rcpm2

     // write IPSTPCR2 - no overrides
    ldr  x0, =RCPM2_IPSTPCR2_OFFSET
    ldr  x1, =IPSTPCR2_VALUE
    bl   write_reg_rcpm2

     // write IPSTPCR3 - no overrides
    ldr  x0, =RCPM2_IPSTPCR3_OFFSET
    ldr  x1, =IPSTPCR3_VALUE
    bl   write_reg_rcpm2

     // write IPSTPCR4 - overrides possible
    adr  x2, soc_data_area
    ldr  w6, [x2, #DEVDISR5_MASK_OFFSET]
    ldr  x0, =RCPM2_IPSTPCR4_OFFSET
    ldr  x1, =IPSTPCR4_VALUE
    bic  x1, x1, x6
    bl   write_reg_rcpm2

     // x5 = DEVDISR2 override mask
     // x6 = DEVDISR5 override mask

     // poll on IPSTPACK0
    ldr  x3, =RCPM2_IPSTPACKR0_OFFSET
    ldr  x4, =IPSTPCR0_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
3:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 14f
    sub  x7, x7, #1
    cbnz x7, 3b

14:
     // poll on IPSTPACK1
    ldr  x3, =IPSTPCR1_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
    bic  x4, x3, x5
    ldr  x3, =RCPM2_IPSTPACKR1_OFFSET
4:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 15f
    sub  x7, x7, #1
    cbnz x7, 4b

15:
     // poll on IPSTPACK2
    ldr  x3, =RCPM2_IPSTPACKR2_OFFSET
    ldr  x4, =IPSTPCR2_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
5:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 16f
    sub  x7, x7, #1
    cbnz x7, 5b

16:
     // poll on IPSTPACK3
    ldr  x3, =RCPM2_IPSTPACKR3_OFFSET
    ldr  x4, =IPSTPCR3_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
6:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 17f
    sub  x7, x7, #1
    cbnz x7, 6b

17:
     // poll on IPSTPACK4
    ldr  x3, =IPSTPCR4_VALUE
    ldr  x7, =IPSTPACK_RETRY_CNT
    bic  x4, x3, x6
    ldr  x3, =RCPM2_IPSTPACKR4_OFFSET
7:
    mov  x0, x3
    bl   read_reg_rcpm2
    cmp  x0, x4
    b.eq 18f
    sub  x7, x7, #1
    cbnz x7, 7b

18:
    adr  x7, soc_data_area

     // x5 = DEVDISR2 override mask
     // x6 = DEVDISR5 override mask
     // x7 = [soc_data_area]

     // save DEVDISR1 and load new value
    mov  x0, #DCFG_DEVDISR1_OFFSET
    bl   read_reg_dcfg
    mov  w13, w0
    mov  x0, #DCFG_DEVDISR1_OFFSET
    ldr  x1, =DEVDISR1_VALUE
    bl   write_reg_dcfg

     // save DEVDISR2 and load new value
    mov  x0, #DCFG_DEVDISR2_OFFSET
    bl   read_reg_dcfg
    mov  w14, w0
    mov  x0, #DCFG_DEVDISR2_OFFSET
    ldr  x1, =DEVDISR2_VALUE
    bic  x1, x1, x5
    bl   write_reg_dcfg

     // x6 = DEVDISR5 override mask
     // x7 = [soc_data_area]

     // save DEVDISR3 and load new value
    mov  x0, #DCFG_DEVDISR3_OFFSET
    bl   read_reg_dcfg
    mov  w15, w0
    mov  x0, #DCFG_DEVDISR3_OFFSET
    ldr  x1, =DEVDISR3_VALUE
    bl   write_reg_dcfg

     // save DEVDISR4 and load new value
    mov  x0, #DCFG_DEVDISR4_OFFSET
    bl   read_reg_dcfg
    mov  w16, w0
    mov  x0, #DCFG_DEVDISR4_OFFSET
    ldr  x1, =DEVDISR4_VALUE
    bl   write_reg_dcfg

     // save DEVDISR5 and load new value
    mov  x0, #DCFG_DEVDISR5_OFFSET
    bl   read_reg_dcfg
    mov  w17, w0
    mov  x0, #DCFG_DEVDISR5_OFFSET
    ldr  x1, =DEVDISR5_VALUE
    bic  x1, x1, x6
    bl   write_reg_dcfg

     // x7 = [soc_data_area]

     // save cpuactlr and disable data prefetch
    mrs  x0, CPUACTLR_EL1
    str  w0, [x7, #CPUACTLR_DATA_OFFSET]
    bic  x0, x0, #CPUACTLR_L1PCTL_MASK
    msr  CPUACTLR_EL1, x0

     // x6 = DEVDISR5 override mask

     // setup registers for cache-only execution
    ldr  x5, =IPSTPCR4_VALUE
    bic  x5, x5, x6
    mov  x6, #DDR_CNTRL_BASE_ADDR
    mov  x7, #DCSR_RCPM2_BASE
    mov  x8, #DCFG_BASE_ADDR
    dsb sy
    isb

     // set the DLL_LOCK cycle count
    ldr  w1, [x6, #DDR_TIMING_CFG_4_OFFSET]
    rev  w2, w1
    bic  w2, w2, #DLL_LOCK_MASK
    orr  w2, w2, #DLL_LOCK_VALUE
    rev  w1, w2
    str  w1, [x6, #DDR_TIMING_CFG_4_OFFSET]

     // x5  = ipstpcr4 (IPSTPCR4_VALUE bic DEVDISR5_MASK)
     // x6  = DDR_CNTRL_BASE_ADDR
     // x7  = DCSR_RCPM2_BASE
     // x8  = DCFG_BASE_ADDR
     // w13 = DEVDISR1 saved value
     // w14 = DEVDISR2 saved value
     // w15 = DEVDISR3 saved value
     // w16 = DEVDISR4 saved value
     // w17 = DEVDISR5 saved value

     // enter the cache-only sequence
    mov  x9, #CORE_NOT_RESTARTABLE
    bl   final_shutdown
    
     // execution should not return to here

    mov  x30, x10
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
    mov  x5, x30
    mov  x4, x0

     // release the core from reset
    bl   _soc_core_release

     // x4 = core_mask_lsb

    ldr  x3, =CORE_RELEASE_CNT

     // x3 = retry count
     // x4 = core_mask_lsb
1:
    sev
    isb
    mov  x0, x4
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

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
    mov  x30, x5
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
 // uses x0, x1, x2, x3, x4, x5, x6
_soc_core_phase2_off:
    mov  x6, x30

     // x0 = core mask lsb
    mov  x4, x0

     // configure the cpu interface

     // disable signaling of ints
    Get_GICC_Base_Addr x5

    ldr  w3, [x5, #GICC_CTLR_OFFSET]
    bic  w3, w3, #GICC_CTLR_EN_GRP0
    bic  w3, w3, #GICC_CTLR_EN_GRP1
    str  w3, [x5, #GICC_CTLR_OFFSET]
    dsb  sy
    isb

     // x3 = GICC_CTRL
     // x4 = core mask lsb
     // x5 = GICC_BASE_ADDR

     // set the priority filter
    ldr  w2, [x5, #GICC_PMR_OFFSET]
    orr  w2, w2, #GICC_PMR_FILTER
    str  w2, [x5, #GICC_PMR_OFFSET]

     // setup GICC_CTLR
    bic  w3, w3, #GICC_CTLR_ACKCTL_MASK
    orr  w3, w3, #GICC_CTLR_FIQ_EN_MASK
    orr  w3, w3, #GICC_CTLR_EOImodeS_MASK
    orr  w3, w3, #GICC_CTLR_CBPR_MASK
    str  w3, [x5, #GICC_CTLR_OFFSET]

     // x3 = GICC_CTRL
     // x4 = core mask lsb

     // setup the banked-per-core GICD registers
    Get_GICD_Base_Addr x5

     // define SGI15 as Grp0
    ldr  w2, [x5, #GICD_IGROUPR0_OFFSET]
    bic  w2, w2, #GICD_IGROUP0_SGI15
    str  w2, [x5, #GICD_IGROUPR0_OFFSET]

     // set priority of SGI 15 to highest...
    ldr  w2, [x5, #GICD_IPRIORITYR3_OFFSET]
    bic  w2, w2, #GICD_IPRIORITY_SGI15_MASK
    str  w2, [x5, #GICD_IPRIORITYR3_OFFSET]

     // enable SGI 15
    ldr  w2, [x5, #GICD_ISENABLER0_OFFSET]
    orr  w2, w2, #GICD_ISENABLE0_SGI15
    str  w2, [x5, #GICD_ISENABLER0_OFFSET]

     // x3 = GICC_CTRL

     // enable the cpu interface

    Get_GICC_Base_Addr x5
    orr  w3, w3, #GICC_CTLR_EN_GRP0
    str  w3, [x5, #GICC_CTLR_OFFSET]
    dsb  sy
    isb

    mov  x30, x6
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function performs the final steps to shutdown the core
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6
_soc_core_entr_off:
    mov  x6, x30
    mov  x5, x0

     // x0 = core mask lsb

     // change state of core in data area
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_OFF
    bl   _setCoreData

     // disable EL3 icache by clearing SCTLR_EL3[12]
    mrs x1, SCTLR_EL3
    ldr x2, =SCTLR_I_MASK
    bic x1, x1, x2      
    msr SCTLR_EL3, x1 

     // invalidate icache
    ic iallu
    dsb  sy
    isb

     // clear any pending SGIs
    ldr   x2, =GICD_CPENDSGIR_CLR_MASK
    Get_GICD_Base_Addr x4

    add   x0, x4, #GICD_CPENDSGIR3_OFFSET
    str   w2, [x0]

     // x4 = GICD_BASE_ADDR
     // x5 = core mask (lsb)

3:
     // enter low-power state by executing wfi
    wfi

     // x4 = GICD_BASE_ADDR
     // x5 = core mask (lsb)

     // see if we got hit by SGI 15
    add   x0, x4, #GICD_SPENDSGIR3_OFFSET
    ldr   w2, [x0]
    and   w2, w2, #GICD_SPENDSGIR3_SGI15_MASK
    cbz   w2, 4f

     // clear the pending SGI
    ldr   x2, =GICD_CPENDSGIR_CLR_MASK
    add   x0, x4, #GICD_CPENDSGIR3_OFFSET
    str   w2, [x0]
4:
     // check if core has been turned on
    mov  x0, x5 
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

     // x0 = core state

    cmp  x0, #CORE_PENDING
    b.ne 3b

     // if we get here, then we have exited the wfi

    mov  x30, x6
    ret

//-----------------------------------------------------------------------------

 // part of CPU_OFF
 // this function starts the process of starting a core back up
 // in:  x0 = core mask lsb
 // out: none
 // uses x0, x1
_soc_core_exit_off:

    Get_GICC_Base_Addr x1

     // read GICC_IAR
    ldr  w0, [x1, #GICC_IAR_OFFSET]

     // write GICC_EIOR - signal end-of-interrupt
    str  w0, [x1, #GICC_EOIR_OFFSET]

     // write GICC_DIR - disable interrupt
    str  w0, [x1, #GICC_DIR_OFFSET]

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

     // disable signaling of grp0 ints
    Get_GICC_Base_Addr x2
    ldr  w3, [x2, #GICC_CTLR_OFFSET]
    bic  w3, w3, #GICC_CTLR_EN_GRP0
    str  w3, [x2, #GICC_CTLR_OFFSET]
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

    Get_GICD_Base_Addr x4

     // x0 = core mask lsb
     // x4 = GICD_BASE_ADDR

     // enable forwarding of group 0 interrupts by setting GICD_CTLR[0] = 1
    ldr  w1, [x4, #GICD_CTLR_OFFSET]
    orr  w1, w1, #GICD_CTLR_EN_GRP0
    str  w1, [x4, #GICD_CTLR_OFFSET]
    dsb sy
    isb

     // x0 = core mask lsb
     // x4 = GICD_BASE_ADDR

     // fire SGI by writing to GICD_SGIR the following values:
     // [25:24] = 0x0 (forward interrupt to the CPU interfaces specified in CPUTargetList field)
     // [23:16] = core mask lsb[7:0] (forward interrupt to target cpu)
     // [15]    = 0 (forward SGI only if it is configured as group 0 interrupt)
     // [3:0]   = 0xF (interrupt ID = 15)
    lsl  w1, w0, #16
    orr  w1, w1, #0xF
    str  w1, [x4, #GICD_SGIR_OFFSET]
    dsb sy
    isb

     // x0 = core mask lsb

     // get the state of the core and loop til the
     // core state is "RELEASED" or until timeout 

    ldr  x3, =RESTART_RETRY_CNT
    mov  x4, x0

     // x4 = core mask lsb

1:
    mov  x0, x4
    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

     // x0 =  core state

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
    Get_GICD_Base_Addr x2
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
    Get_GICC_Base_Addr x2
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
    Get_GICD_Base_Addr x1

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
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10
_soc_init_start:
    mov   x10, x30

     // zero-out the membank global vars
    adr   x2, _membank_count_addr
    stp   xzr, xzr, [x2]

     // get the address of the gic base address area
    adr   x5, _gic_base_addr

     // read SVR and get the SoC version
    mov   x0, #DCFG_SVR_OFFSET
    bl    read_reg_dcfg

     // x0 =  svr
     // x5 = _gic_base_addr

    and   w0, w0, #SVR_MINOR_REV_MASK
    cmp   w0, #SVR_MINOR_REV_0
    b.ne  8f

     // load the gic base addresses for rev 1.0 parts
    ldr   x2, =GICD_BASE_ADDR_4K
    ldr   x3, =GICC_BASE_ADDR_4K
    b     10f    
8:
     // for rev 1.1 and later parts, the GIC base addresses
     // can be at 4k or 64k offsets

     // read the scfg reg GIC400_ADDR_ALIGN
    mov   x0, #SCFG_GIC400_ADDR_ALIGN_OFFSET
    bl    read_reg_scfg

     // x0 = GIC400_ADDR_ALIGN value
    and   x0, x0, #GIC400_ADDR_ALIGN_4KMODE_MASK
    mov   x1, #GIC400_ADDR_ALIGN_4KMODE_EN
    cmp   x0, x1
    b.ne  9f
    
     // load the base addresses for 4k offsets
    ldr   x2, =GICD_BASE_ADDR_4K
    ldr   x3, =GICC_BASE_ADDR_4K
    b     10f
9:
     // load the base address for 64k offsets
    ldr   x2, =GICD_BASE_ADDR_64K
    ldr   x3, =GICC_BASE_ADDR_64K
10:
     // x5 = _gic_base_addr

     // store the base addresses
    str   x2, [x5]
    str   x3, [x5, #8]

     //---------------------------

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
    mov  x1, #CORE_STATE_DATA
    mov  x2, #CORE_WFE
    bl   _setCoreData
5:
     // set the task 2 core state to IN_RESET
    bl   get_task2_core
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

 // this function sets the security mechanisms in the SoC to implement the
 // Platform Security Policy
_set_platform_security:


    ret

//-----------------------------------------------------------------------------

 // this function makes any needed soc-specific configuration changes when boot
 // services end
_soc_exit_boot_svcs:

    ret

//-----------------------------------------------------------------------------
 // this function checks SVR for security enabled
 // out: x2 = 1 of SEC enabled, 0 for SEC disabled
 // uses x0, x1, x2, x10
_soc_check_sec_enabled:
    mov  x10, x30
    mov  x0, #DCFG_SVR_OFFSET
    bl   read_reg_dcfg

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

 // write a register in the SCFG block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_scfg:
    ldr  x2, =SCFG_BASE_ADDR
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
    ldr  x2, =SCFG_BASE_ADDR
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
    ldr  x2, =DCFG_BASE_ADDR
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
    ldr  x2, =DCFG_BASE_ADDR
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
    ldr  x2, =RCPM_BASE_ADDR
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
    ldr  x2, =RCPM_BASE_ADDR
    ldr  w1, [x2, x0]
     // swap for BE
    rev  w0, w1
    ret

//-----------------------------------------------------------------------------

 // write a register in the DCSR-RCPM2 block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_rcpm2:
    ldr  x2, =DCSR_RCPM2_BASE
     // swap for BE
    rev  w3, w1
    str  w3, [x2, x0]
    ret
//-----------------------------------------------------------------------------

 // read a register in the DCSR-RCPM2 block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_rcpm2:
    ldr  x2, =DCSR_RCPM2_BASE
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
    ldr  x2, =SYS_COUNTER_BASE
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
    ldr  x2, =SYS_COUNTER_BASE
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
    Get_GICD_Base_Addr x2
    str  w1, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the GIC400 distributor block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_gicd:
    Get_GICD_Base_Addr x2
    ldr  w0, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // write a register in the GIC400 CPU interface block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_gicc:
    Get_GICC_Base_Addr x2
    str  w1, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the GIC400 CPU interface block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_gicc:
    Get_GICC_Base_Addr x2
    ldr  w0, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // read a register in the ddr controller block
 // in:  x0 = offset
 // out: w0 = value read
 // uses x0, x1, x2
read_reg_ddr:
    ldr  x2, =DDR_CNTRL_BASE_ADDR
    ldr  w0, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // write a register in the ddr controller block
 // in:  x0 = offset
 // in:  w1 = value to write
 // uses x0, x1, x2, x3
write_reg_ddr:
    ldr  x2, =DDR_CNTRL_BASE_ADDR
    str  w1, [x2, x0]
    ret

//-----------------------------------------------------------------------------

 // this function initializes the upper-half of OCRAM for ECC checking
 // in:  none
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10
_ocram_init_upper:
    mov  x10, x30

     // set the start flag
    adr  x8, init_task1_flags
    mov  w9, #1
    str  w9, [x8]

     // get the start address and size of the upper region
    mov  x0, #OCRAM_REGION_UPPER
    bl   _get_ocram_2_init

     // x0 = start address
     // x1 = size in bytes

     // convert bytes to 64-byte chunks (we are using quad load/store pairs)
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

     // restore link register
    mov  x30, x10

     // clean the registers
    mov  x0,  #0
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

    ret

//-----------------------------------------------------------------------------

 // this function initializes the lower-half of OCRAM for ECC checking
 // in:  none
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10
_ocram_init_lower:
    mov  x10, x30

     // set the start flag
    adr  x8, init_task2_flags
    mov  w9, #1
    str  w9, [x8]

     // get the start address and size of the lower region
    mov  x0, #OCRAM_REGION_LOWER
    bl   _get_ocram_2_init

     // x0 = start address
     // x1 = size in bytes

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

     // restore link register
    mov  x30, x10

     // clean the registers
    mov  x0,  #0
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
    bl   set_task1_core

     // load bootlocptr with start addr
    adr  x0, prep_init_ocram_hi
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
    bl   set_task2_core

     // load bootlocptr with start addr
    adr  x0, prep_init_ocram_lo
    bl   _soc_set_start_addr

     // release secondary core
    mov  x0, x4
    bl  _soc_core_release

    mov  x30, x5
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

 // this function returns the specified data field value from the specified cpu
 // core data area
 // in:  x0 = core mask lsb
 //      x1 = data field name/offset
 // out: x0 = data value
 // uses x0, x1, x2
_getCoreData:
     // x0 = core mask
     // x1 = field offset

     // generate a 0-based core number from the input mask
    clz   x2, x0
    mov   x0, #63
    sub   x0, x0, x2

     // x0 = core number (0-based)
     // x1 = field offset

    mov   x2, #CORE_DATA_OFFSET
    mul   x2, x2, x0
    add   x1, x1, x2

     // x1 = cumulative offset to data field

    adr   x2, _cpu0_data

     // a53 errata
    add   x2, x2, x1
    dc    ivac, x2
    dsb   sy
    isb 
 
     // read data
    ldr   x0, [x2]
    ret
    
//-----------------------------------------------------------------------------

 // this function writes the specified data value into the specified cpu
 // core data area
 // in:  x0 = core mask lsb
 //      x1 = data field name/offset
 //      x2 = data value to write/store
 // out: none
 // uses x0, x1, x2, x3
_setCoreData:
     // x0 = core mask
     // x1 = field offset
     // x2 = data value

    clz   x3, x0
    mov   x0, #63
    sub   x0, x0, x3

     // x0 = core number (0-based)
     // x1 = field offset
     // x2 = data value

    mov   x3, #CORE_DATA_OFFSET
    mul   x3, x3, x0
    add   x1, x1, x3

     // x1 = cumulative offset to data field
     // x2 = data value

    adr   x3, _cpu0_data
    str   x2, [x3, x1]

     // a53 errata
    add   x3, x3, x1
    dc    cvac, x3
    dsb   sy
    isb  
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

     // enable the icache on the secondary core
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

    mov  x5, x0

     // x5 = core mask lsb

1:
     // see if our state has changed to CORE_PENDING
    mov   x0, x5
    mov   x1, #CORE_STATE_DATA
    bl    _getCoreData

     // x0 = core state

    cmp   x0, #CORE_PENDING
    b.eq  2f
     // if not core_pending, then wfe
    wfe
    b  1b

2:
     // branch to the start code in the monitor
    adr  x0, _secondary_core_init
    br   x0

//-----------------------------------------------------------------------------

 // DO NOT CALL THIS FUNCTION FROM THE BOOT CORE!!
 // this function uses a secondary core to initialize the lower portion of OCRAM
 // the core does not return from this function
prep_init_ocram_lo:

     // invalidate the icache
    ic  iallu
    isb

     // enable the icache on the secondary core
    mrs  x1, sctlr_el3
    orr  x1, x1, #SCTLR_I_MASK
    msr  sctlr_el3, x1
    isb

     // init the range of ocram
    bl  _ocram_init_lower    // 0-9

     // get the core mask
    mrs  x0, MPIDR_EL1
    bl   _get_core_mask_lsb  // 0-2

     // x0 = core mask lsb

     // turn off icache
    mrs  x1, sctlr_el3
    bic  x1, x1, #SCTLR_I_MASK
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

    mov  x5, x0

     // x5 = core mask lsb

1:
     // see if our state has changed to CORE_PENDING
    mov   x0, x5
    mov   x1, #CORE_STATE_DATA
    bl    _getCoreData

     // x0 = core state

    cmp   x0, #CORE_PENDING
    b.eq  2f
     // if not core_pending, then wfe
    wfe
    b  1b

2:
     // branch to the start code in the monitor
    adr  x0, _secondary_core_init
    br   x0

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

 // this function will shutdown ddr and the final core - it will do this
 // by loading itself into the icache and then executing from there
 // in:  x5  = ipstpcr4 (IPSTPCR4_VALUE bic DEVDISR5_MASK)
 //      x6  = DDR_CNTRL_BASE_ADDR
 //      x7  = DCSR_RCPM2_BASE
 //      x8  = DCFG_BASE_ADDR
 //      x9  = 0, restartable
 //          = 1, non-restartable
 //      w13 = DEVDISR1 saved value
 //      w14 = DEVDISR2 saved value
 //      w15 = DEVDISR3 saved value
 //      w16 = DEVDISR4 saved value
 //      w17 = DEVDISR5 saved value
 // out: none
 // uses x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x13, x14, x15, x16, x17

 // 4Kb aligned
.align 12
final_shutdown:

    mov  x0, xzr
    b    touch_line_0
start_line_0:
    mov  x0, #1
    mov  x2, #DDR_SDRAM_CFG_2_FRCSR         // put ddr in self refresh - start
    ldr  w3, [x6, #DDR_SDRAM_CFG_2_OFFSET]
    rev  w4, w3
    orr  w4, w4, w2
    rev  w3, w4
    str  w3, [x6, #DDR_SDRAM_CFG_2_OFFSET]  // put ddr in self refresh - end
    orr  w3, w5, #DEVDISR5_MEM              // quiesce ddr clocks - start
    rev  w4, w3
    str  w4, [x7, #RCPM2_IPSTPCR4_OFFSET]   // quiesce ddr clocks - end

    mov  w3, #DEVDISR5_MEM
    rev  w3, w3                             // polling mask
    mov  x2, #DDR_SLEEP_RETRY_CNT           // poll on ipstpack4 - start
touch_line_0:
    cbz  x0, touch_line_1

start_line_1:
    ldr  w1, [x7, #RCPM2_IPSTPACKR4_OFFSET]
    tst  w1, w3
    b.ne 1f
    subs x2, x2, #1
    b.gt start_line_1                       // poll on ipstpack4 - end

     // if we get here, we have a timeout err
    rev  w4, w5
    str  w4, [x7, #RCPM2_IPSTPCR4_OFFSET]   // re-enable ddr clks interface
    mov  x0, #ERROR_DDR_SLEEP               // load error code
    b    2f
1:
    str  w4, [x8, #DCFG_DEVDISR5_OFFSET]    // disable ddr cntrlr clk in devdisr5
5:
    wfi                                     // stop the final core

    cbnz x9, 5b                             // if non-restartable, keep in wfi
    rev  w4, w5
    str  w4, [x8, #DCFG_DEVDISR5_OFFSET]    // re-enable ddr in devdisr5
    str  w4, [x7, #RCPM2_IPSTPCR4_OFFSET]   // re-enable ddr clk in ipstpcr4
touch_line_1:
    cbz  x0, touch_line_2

start_line_2:
    ldr  w1, [x7, #RCPM2_IPSTPACKR4_OFFSET] // poll on ipstpack4 - start
    tst  w1, w3
    b.eq 2f
    nop
    b    start_line_2                       // poll on ipstpack4 - end
2:
    mov  x2, #DDR_SDRAM_CFG_2_FRCSR         // take ddr out-of self refresh - start
    ldr  w3, [x6, #DDR_SDRAM_CFG_2_OFFSET]
    rev  w4, w3
    bic  w4, w4, w2
    rev  w3, w4
    mov  x1, #DDR_SLEEP_RETRY_CNT           // wait for ddr cntrlr clock - start
3:    
    subs x1, x1, #1
    b.gt 3b                                 // wait for ddr cntrlr clock - end
    str  w3, [x6, #DDR_SDRAM_CFG_2_OFFSET]  // take ddr out-of self refresh - end
    rev  w1, w17
touch_line_2:
    cbz  x0, touch_line_3

start_line_3:
    str  w1, [x8, #DCFG_DEVDISR5_OFFSET]    // reset devdisr5
    rev  w1, w16
    str  w1, [x8, #DCFG_DEVDISR4_OFFSET]    // reset devdisr4
    rev  w1, w15
    str  w1, [x8, #DCFG_DEVDISR3_OFFSET]    // reset devdisr3
    rev  w1, w14
    str  w1, [x8, #DCFG_DEVDISR2_OFFSET]    // reset devdisr2
    rev  w1, w13
    str  w1, [x8, #DCFG_DEVDISR1_OFFSET]    // reset devdisr1
    str  wzr, [x7, #RCPM2_IPSTPCR4_OFFSET]  // reset ipstpcr4
    str  wzr, [x7, #RCPM2_IPSTPCR3_OFFSET]  // reset ipstpcr3
    str  wzr, [x7, #RCPM2_IPSTPCR2_OFFSET]  // reset ipstpcr2
    str  wzr, [x7, #RCPM2_IPSTPCR1_OFFSET]  // reset ipstpcr1
    str  wzr, [x7, #RCPM2_IPSTPCR0_OFFSET]  // reset ipstpcr0
    b    continue_restart
touch_line_3:
    cbz  x0, start_line_0

 // execute here after ddr is back up
continue_restart:
    mov  x6, x0

     // clear POWMGTDCR
    mov  x1, #DCSR_RCPM2_BASE
    str  wzr, [x1, #RCPM2_POWMGTDCR_OFFSET]

     // clear WFIL2_EN in SCFG_COREPMCR
    mov  x1, #SCFG_BASE_ADDR
    str  wzr, [x1, #SCFG_COREPMCR_OFFSET]

     // if x0 = 1, all is well
     // if x0 < 1, we had an error
    mov  x0, x6
    cmp  x0, #1
    b.ne 4f
    mov  x0, #0
4:
    ret

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------

psci_features_table:
    .4byte  PSCI_VERSION_ID         // psci_version
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  PSCI_CPU_OFF_ID         // cpu_off
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  PSCI64_CPU_ON_ID        // cpu_on
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  PSCI_FEATURES_ID        // psci_features
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  PSCI64_AFFINITY_INFO_ID // psci_affinity_info
    .4byte  PSCI_FUNC_IMPLEMENTED   // implemented
    .4byte  FEATURES_TABLE_END      // table terminating value - must always be last entry in table

.align 3
soc_data_area:
    .4byte  0x0  // soc storage 1, offset 0x0
    .4byte  0x0  // soc storage 2, offset 0x4
    .4byte  0x0  // soc storage 3, offset 0x8
    .4byte  0x0  // soc storage 4, offset 0xC
    .4byte  0x0  // soc storage 5, offset 0x10
    .4byte  0x0  // soc storage 6, offset 0x14
    .4byte  0x0  // soc storage 7, offset 0x18
    .4byte  0x0  // soc storage 8, offset 0x1C

.align 3
_gic_base_addr:
    .8byte  0x0  // gicd base address
    .8byte  0x0  // gicc base address

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

