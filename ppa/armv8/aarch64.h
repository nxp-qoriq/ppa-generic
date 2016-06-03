// aarch64.h
// 
// header file for secure fw
//
// Copyright (c) 2016, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _AARCH64_H
#define	_AARCH64_H

.equ  SPSR_MODE_MASK,  0x1F
.equ  SPSR_FOR_EL2H,   0x3C9
.equ  SPSR_FOR_EL1H,   0x3C5
.equ  SPSR_DAIF_MASK,  0x3C0
.equ  SPSR_MODE_EL2H,  0x009
.equ  SPSR_EL_MASK,    0xC
.equ  SPSR_EL0,        0x0
.equ  SPSR_EL1,        0x4
.equ  SPSR_EL2,        0x8
.equ  SPSR_EL3,        0xC

.equ  SPSR32_E_MASK,          0x200
.equ  SPSR32_DEFAULT,         0x1DA

.equ  SCTLR_EE_WXN_SA_A_MASK, 0x0208000A
.equ  SCTLR_EE_WXN_MASK,      0x02080000
.equ  SCTLR_EE_MASK,          0x02000000
.equ  SCTLR_WXN_MASK,         0x00080000
.equ  SCTLR_I_C_M_MASK,       0x00001005
.equ  SCTLR_I_MASK,           0x00001000
.equ  SCTLR_SA_A_MASK,        0x0000000A
.equ  SCTLR_C_M_MASK,         0x00000005
.equ  SCTLR_SA_C_A_M_MASK,    0x0000000F
.equ  SCTLR_C_A_M_MASK,       0x00000007
.equ  SCTLR_SA_MASK,          0x00000008
.equ  SCTLR_C_MASK,           0x00000004
.equ  SCTLR_A_MASK,           0x00000002
.equ  SCTLR_M_MASK,           0x00000001

.equ  CPTR_EL2_RES1_MASK,     0x33FF

.equ  DAIF_SET_MASK,          0x3C0

.equ  CPUECTLR_SMPEN_MASK,    0x40
.equ  CPUECTLR_SMPEN_EN,      0x40
.equ  CPUECTLR_RET_MASK,      0x7
.equ  CPUECTLR_RET_SET,       0x2
.equ  CPUECTLR_TIMER_MASK,    0x7
.equ  CPUECTLR_TIMER_8TICKS,  0x2

.equ  HCR_EL2_RW_AARCH64,       0x80000000

.equ  ID_AA64PFR0_MASK_EL2,   0xF00

.equ  MPIDR_AFFINITY0_MASK,   0x00FF
.equ  MPIDR_AFFINITY0_OFFSET, 0x0
.equ  MPIDR_AFFINITY0_SIZE,   0x8
.equ  MPIDR_AFFINITY1_MASK,   0xFF00
.equ  MPIDR_AFFINITY1_OFFSET, 0x8
.equ  MPIDR_AFFINITY1_SIZE,   0x8
.equ  MPIDR_CORE_MASK,        0x00FF
.equ  MPIDR_CLUSTER_MASK,     0xFF00

.equ  SCR_FIQ_MASK,           0x4
.equ  SCR_IRQ_MASK,           0x2
.equ  SCR_RW_MASK,            0x400

.equ  SPSEL_SP,               0x1

.equ  CLEAN_DCACHE,           0x0
.equ  CLN_INV_DCACHE,         0x1

//-----------------------------------------------------------------------------

.macro m_get_core_pos _res, _reg1
     // out: _res = Core Number
     //		(Cluster_num * Core_per_cluster + Core_num)
     // uses: _res, _reg1
    mrs \_reg1, MPIDR_EL1

     // _res = Cluster_num
    ubfx \_res, \_reg1, #MPIDR_AFFINITY1_OFFSET, #MPIDR_AFFINITY1_SIZE
    ldr \_reg1, =CPU_PER_CLUSTER

     // _res = CPU_PER_CLUSTER * Cluster
    mul \_res, \_reg1, \_res

    mrs \_reg1, MPIDR_EL1
     // _reg1 = Core_num
    ubfx \_reg1, \_reg1, #MPIDR_AFFINITY0_OFFSET, #MPIDR_AFFINITY0_SIZE

     // _res = (Cluster_num * Core_per_cluster + Core_num)
    add \_res, \_res, \_reg1

.endm

//-----------------------------------------------------------------------------

.macro m_get_core_stack_top _res, _core, _reg1
     // in: _core = Core Number in a register
     // out: _res = Stack Top of Core _core
     // uses: _res, _reg1

     // Get absolute address of STACKS TOP in case
     // of position independent code

     // Using ADRP intruction to access +/- 4GB Address
     // ADR would only give address within +/- 1MB
     // :lo12: gives lower 4KB offset within page
    adrp \_reg1, __STACKS_TOP__
    add \_reg1, \_reg1, :lo12:__STACKS_TOP__

     // Get SP for individual core. Core0 gets
     // SP as Stack_top
     // _res = Stack_top - Core_num * Stack_per_core
    ldr \_res, =__STACK_SIZE_PER_CPU_
    msub \_res, \_res, \_core, \_reg1
.endm

//-----------------------------------------------------------------------------

.macro m_get_cur_stack_top _res _reg1 _reg2
     // out: _res = SP for Current Core
     // uses: _res, _reg1, _reg2
    m_get_core_pos \_reg1, \_reg2
    m_get_core_stack_top \_res, \_reg1, \_reg2
.endm

//-----------------------------------------------------------------------------

#define CPUECTLR_EL1  S3_1_C15_C2_1

//-----------------------------------------------------------------------------


#endif // _AARCH64_H
