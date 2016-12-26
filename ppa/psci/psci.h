// psci.h
// 
// header file for psci.s
//
// Copyright (c) 2015, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _PSCI_H
#define	_PSCI_H

 // version number
//.equ PSCI_VERSION,    0x00010000
.equ PSCI_VERSION,    0x00000002

 // core execution level
.equ CORE_EL0, 		  0x0
.equ CORE_EL1, 		  0x1
.equ CORE_EL2, 		  0x2
.equ CORE_EL3, 		  0x3

 // core abort current op
.equ CORE_ABORT_OP,  0x1

 // core state
 // OFF states 0x0 - 0xF
.equ CORE_IN_RESET,    0x0
.equ CORE_DISABLED,    0x1
.equ CORE_OFF,         0x2
.equ CORE_STANDBY,     0x3
.equ CORE_PWR_DOWN,    0x4
.equ CORE_WFE,         0x6
.equ CORE_WFI,         0x7
.equ CORE_LAST,		   0x8
.equ CORE_OFF_PENDING, 0x9
.equ CORE_WORKING_INIT,0xA

 // ON states 0x10 - 0x1F
.equ CORE_PENDING,    0x10
.equ CORE_RELEASED,   0x11
 // highest off state
.equ CORE_OFF_MAX,	  0xF
 // lowest on state
.equ CORE_ON_MIN,     0x10	

 // return values
.equ PSCI_SUCCESS,          0x0
.equ PSCI_NOT_SUPPORTED,    0xFFFFFFFF
.equ PSCI_INVALID_PARMS,    0xFFFFFFFE
.equ PSCI_DENIED,           0xFFFFFFFD
.equ PSCI_ALREADY_ON,       0xFFFFFFFC
.equ PSCI_ON_PENDING,       0xFFFFFFFB
.equ PSCI_INTERNAL_FAILURE, 0xFFFFFFFA
.equ PSCI_NOT_PRESENT,      0xFFFFFFF9
.equ PSCI_DISABLED,         0xFFFFFFF8

 // affinity_info returns
.equ AFFINITY_LEVEL_ON,   0x0
.equ AFFINITY_LEVEL_OFF,  0x1
.equ AFFINITY_LEVEL_PEND, 0x2

 // mask for testing address alignment
.equ ALIGNED_32BIT_MASK,  0x3

 // core ID data area constants - correspond to core_mask_lsb
.equ CORE_0_MASK,       0x1
.equ CORE_1_MASK,       0x2

.if (CPU_MAX_COUNT > 2)
.equ CORE_2_MASK,       0x4
.equ CORE_3_MASK,       0x8
.endif

.if (CPU_MAX_COUNT > 4)
.equ CORE_4_MASK,       0x10
.equ CORE_5_MASK,       0x20
.equ CORE_6_MASK,       0x40
.equ CORE_7_MASK,       0x80
.endif

.if (CPU_MAX_COUNT > 8)
.equ CORE_8_MASK,       0x100
.equ CORE_9_MASK,       0x200
.equ CORE_10_MASK,      0x400
.equ CORE_11_MASK,      0x800
.equ CORE_12_MASK,      0x1000
.equ CORE_13_MASK,      0x2000
.equ CORE_14_MASK,      0x4000
.equ CORE_15_MASK,      0x8000
.endif

 // if assembly stops here, you need to add more mask defs
.if (CPU_MAX_COUNT > 16)
.err
.endif

.equ CORE_MASK_MAX, (1 << (CPU_MAX_COUNT - 1))

 // affinity level field of power_state parameter for cpu_suspend 
.equ PWR_STATE_CORE_LVL,     0x0
.equ PWR_STATE_CLUSTER_LVL,  0x1
.equ PWR_STATE_SYSTEM_LVL,   0x2

 // stateType field of power_state parameter for cpu_suspend
.equ PWR_STATE_STANDBY,      0x0
.equ PWR_STATE_PWR_DOWN,     0x1

 // power_state parameter bitmap for cpu_suspend
 // Bits [25:24] : PowerLevel
 // Bits [16]    : StateType
 // other bits are reserved, and zero by default
.equ POWER_LEVEL_MASK,		0x03000000
.equ STATE_TYPE_MASK,		0x00010000
.equ POWER_STATE_MASK,		(POWER_LEVEL_MASK | STATE_TYPE_MASK)

 // psci function id's for smc64 interface
 // these functions are callable only from Aarch64
.equ PSCI64_CPU_SUSPEND_ID,   0xC4000001
.equ PSCI64_CPU_ON_ID,        0xC4000003
.equ PSCI64_AFFINITY_INFO_ID, 0xC4000004

 // psci function id's for smc32 interface
 // these functions are callable from Aarch64 and Aarch32
.equ PSCI_VERSION_ID,         0x84000000
.equ PSCI32_CPU_SUSPEND_ID,   0x84000001
.equ PSCI_CPU_OFF_ID,         0x84000002
.equ PSCI32_CPU_ON_ID,        0x84000003
.equ PSCI32_AFFINITY_INFO_ID, 0x84000004
.equ PSCI_SYSTEM_OFF,         0x84000008
.equ PSCI_SYSTEM_RESET_ID,    0x84000009
.equ PSCI_FEATURES_ID,        0x8400000A

.equ PSCI_FUNCTION_MASK,    0xFFFF

.equ FEATURES_TABLE_END,    0x0FF00000
.equ PSCI_FUNC_IMPLEMENTED, 0x0

.equ RESET_RETRY_CNT,       800
.equ PSCI_ABORT_CNT,        100

.equ AARCH32_MODE,    0x1
.equ AARCH64_MODE,    0x0

 // data area offsets - must be in synch with CoreDataStruc in psci_data.h
.equ CORE_STATE_DATA,   0x0
.equ SPSR_EL3_DATA,     0x8
.equ CNTXT_ID_DATA,     0x10
.equ START_ADDR_DATA,   0x18
.equ LINK_REG_DATA,     0x20
.equ GICC_CTLR_DATA,    0x28
.equ ABORT_FLAG_DATA,   0x30
.equ SCTLR_DATA,        0x38
.equ CPUECTLR_DATA,     0x40
.equ AUX_01_DATA,       0x48  // usage defined per SoC
.equ AUX_02_DATA,       0x50  // usage defined per SoC
.equ AUX_03_DATA,       0x58  // usage defined per SoC
.equ AUX_04_DATA,       0x60  // expansion
.equ AUX_05_DATA,       0x68  // expansion
.equ SCR_EL3_DATA,      0x70
.equ HCR_EL2_DATA,      0x78

 // width of a core data area - must be in synch
 //  w/CoreDataStruc in psci_data.h
.equ CORE_DATA_OFFSET,  0x80


//-----------------------------------------------------------------------------

 // this macro acquires a lock for a critical section
.macro Acquire_Lock_01 $p1, $p2, $p3

    adr  \$p1, lock_01
    mov  \$p2, #1

10:
     // read lock with acquire
    ldaxr \$p3, [\$p1]
    cbnz  \$p3, 10b

     // lock is unacquired - attempt to acquire it
    stxr  \$p3, \$p2, [\$p1]
    cbnz  \$p3, 10b
.endm

//-----------------------------------------------------------------------------

 // this macro releases a previously acquired lock
.macro Release_Lock_01 $p1

    adr  \$p1, lock_01
    stlr  wzr, [\$p1]
.endm

//-----------------------------------------------------------------------------

#endif // _PSCI_H
