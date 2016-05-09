// soc.h
// 
// header file for LS2080 SoC
//
// Copyright (c) 2015-2016, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _SOC_H
#define	_SOC_H

 // number of cpu's, clusters in this SoC
#define CPU_MAX_COUNT            0x8
#define CLUSTER_COUNT            0x4
#define CPU_PER_CLUSTER          0x2    

 // pwr mgmt features supported in the soc-specific code:
 //   value == 0x0, the soc code does not support this feature
 //   value != 0x0, the soc code supports this feature
#define SOC_CORE_RELEASE      0x1
#define SOC_CORE_RESTART      0x0
#define SOC_CORE_OFF          0x0
#define SOC_CORE_STANDBY      0x0
#define SOC_CORE_PWR_DWN      0x0  
#define SOC_CLUSTER_STANDBY   0x0
#define SOC_CLUSTER_PWR_DWN   0x0  
#define SOC_SYSTEM_STANDBY    0x0
#define SOC_SYSTEM_PWR_DWN    0x0 
#define SOC_SYSTEM_OFF        0x0 
#define SOC_SYSTEM_RESET      0x0 

#define RESET_SUCCESS         0x0
#define RESET_FAILURE         0x1

 // base addresses
#define DCFG_BASE_ADDR     0x01E00000
#define TIMER_BASE_ADDR    0x023E0000
#define RESET_BASE_ADDR    0x01E60000
#define GICR_BASE_ADDR     0x06100000

 // dcfg block register offsets
#define DCFG_SCRATCHRW7_OFFSET  0x218
#define DCFG_COREDISR_OFFSET    0x94

 // timer frequency - 25mhz
#define  COUNTER_FRQ_EL0 0x017D7840

 // OCRAM
#define  OCRAM_BASE_ADDR     0x18000000
#define  OCRAM_MID_ADDR      0x18010000
#define  OCRAM_SIZE_IN_BYTES 0x20000
#define  OCRAM_INIT_RETRY    0x2000

//-----------------------------------------------------------------------------

#endif // _SOC_H
