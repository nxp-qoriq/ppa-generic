// soc.h
// 
// header file for LS2080 SoC
//
// Copyright (c) 2015-2016, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _SOC_H
#define	_SOC_H

 // pwr mgmt features supported in the soc-specific code:
 //   value == 0x0, the soc code does not support this feature
 //   value != 0x0, the soc code supports this feature
#define SOC_CORE_RELEASE      0x1
#define SOC_CORE_RESTART      0x1
#define SOC_CORE_OFF          0x1
#define SOC_CORE_STANDBY      0x1
#define SOC_CORE_PWR_DWN      0x1
#define SOC_CLUSTER_STANDBY   0x1
#define SOC_CLUSTER_PWR_DWN   0x1  
#define SOC_SYSTEM_STANDBY    0x0
#define SOC_SYSTEM_PWR_DWN    0x0 
#define SOC_SYSTEM_OFF        0x0 
#define SOC_SYSTEM_RESET      0x1 

#define RESET_SUCCESS         0x0
#define RESET_FAILURE         0x1

 // base addresses
#define DCFG_BASE_ADDR     0x01E00000
#define TIMER_BASE_ADDR    0x023E0000
#define RESET_BASE_ADDR    0x01E60000
#define SECMON_BASE_ADDR   0x01E90000

 // secmon register offsets and bitfields
#define SECMON_HPCOMR_OFFSET  0x4
#define SECMON_HPCOMR_NPSWAEN 0x80000000

#define TIMER_CNTCR_OFFSET 0x0

#define GICR_RD_BASE_ADDR   0x06100000
#define GICR_SGI_BASE_ADDR  0x06110000
#define GICD_BASE_ADDR      0x06000000
#define GIC_RD_OFFSET       0x00020000  // offset between redistributors
#define GIC_SGI_OFFSET      0x00020000  // offset between SGI's
#define GIC_RD_2_SGI_OFFSET 0x00010000  // offset from rd base to sgi base

 // gic register offsets
#define GICD_CTLR_OFFSET        0x0
#define GICR_ICENABLER0_OFFSET  0x180
#define GICR_CTLR_OFFSET        0x0
#define GICR_IGROUPR0_OFFSET    0x80
#define GICR_IGRPMODR0_OFFSET   0xD00
#define GICR_IPRIORITYR3_OFFSET 0x40C
#define GICR_ICPENDR0_OFFSET    0x280
#define GICR_ISENABLER0_OFFSET  0x100
#define GICR_TYPER_OFFSET       0x8
#define GICR_WAKER_OFFSET       0x14
#define GICR_ICACTIVER0_OFFSET  0x380
#define GICR_ICFGR0_OFFSET      0xC00

 // gic bitfields
#define GICD_CTLR_EN_GRP_MASK  0x7
#define GICD_CTLR_EN_GRP_1NS   0x2
#define GICD_CTLR_EN_GRP_1S    0x4
#define GICD_CTLR_EN_GRP_0     0x1
#define GICD_CTLR_ARE_S_MASK   0x10
#define GICD_CTLR_RWP_MASK     0x80000000
#define GICR_ICENABLER0_SGI15  0x00008000
#define GICR_CTLR_RWP_MASK     0x8
#define GICR_IGROUPR0_SGI15    0x00008000
#define GICR_IGRPMODR0_SGI15   0x00008000
#define GICR_ISENABLER0_SGI15  0x00008000
#define GICR_IPRIORITYR3_SGI15_MASK  0xFF000000
#define GICR_ICPENDR0_SGI15    0x8000

#define ICC_SRE_EL3_SRE          0x1
#define ICC_IGRPEN0_EL1_EN       0x1
#define ICC_CTLR_EL3_RM          0x20
#define ICC_CTLR_EL3_EOIMODE_EL3 0x4
#define ICC_CTLR_EL3_PMHE        0x40
#define ICC_PMR_EL1_P_FILTER     0xFF
#define ICC_IAR0_EL1_SGI15       0xF
#define ICC_SGI0R_EL1_INTID      0x0F000000

 // timer control bitfields
#define CNTCR_EN_MASK   0x1
#define CNTCR_EN        0x1
#define CNTCR_DIS       0x0

 // dcfg block register offsets
#define DCFG_SCRATCHRW7_OFFSET  0x218
#define COREDISABLEDSR_OFFSET   0x990

 // System Counter Offset and Bit Mask
#define SYS_COUNTER_CNTCR_OFFSET	0x0
#define SYS_COUNTER_CNTCR_EN		0x00000001

 // timer frequency - 25mhz
#define  COUNTER_FRQ_EL0 0x017D7840

 // OCRAM
#define  OCRAM_BASE_ADDR     0x18000000
#define  OCRAM_MID_ADDR      0x18010000
#define  OCRAM_SIZE_IN_BYTES 0x20000
#define  OCRAM_INIT_RETRY    0x2000

#define  ICC_IGRPEN0_EL1 S3_0_C12_C12_6
#define  ICC_IGRPEN1_EL1 S3_0_C12_C12_7
#define  ICC_SGI0R_EL1   S3_0_C12_C11_7
#define  ICC_PMR_EL1     S3_0_C4_C6_0
#define  ICC_IAR0_EL1    S3_0_C12_C8_0
#define  ICC_EOIR0_EL1   S3_0_C12_C8_1
#define  ICC_SRE_EL3     S3_6_C12_C12_5
#define  ICC_CTLR_EL3    S3_6_C12_C12_4
#define  ICC_SRE_EL2     S3_4_C12_C9_5
#define  ICC_IGRPEN1_EL3 S3_6_C12_C12_7
#define  ICC_CTLR_EL1    S3_0_C12_C12_4

//-----------------------------------------------------------------------------

#endif // _SOC_H
