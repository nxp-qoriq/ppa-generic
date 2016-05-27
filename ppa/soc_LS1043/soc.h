// soc.h
// 
// header file for SoC-specific defines
//
// Copyright (c) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _SOC_H
#define	_SOC_H

 // base addresses
#define SCFG_BASE_ADDR            0x01570000
#define DCFG_BASE_ADDR            0x01EE0000
#define RCPM_BASE_ADDR            0x01EE2000
#define DCSR_RCPM2_BASE           0x20170000
#define SYS_COUNTER_BASE          0x02b00000
#define WDT1_BASE                 0x02AD0000
#define WDT3_BASE                 0x02A70000  
#define WDT4_BASE                 0x02A80000
#define WDT5_BASE                 0x02A90000

 // register offsets
#define SCFG_COREBCR_OFFSET       0x0680
#define SCFG_RETREQCR_OFFSET      0x0424
#define SCFG_COREPMCR_OFFSET      0x042C

#define SYS_COUNTER_CNTCR_OFFSET  0x0

#define RCPM_PCPH20SETR_OFFSET    0x0D4
#define RCPM_PCPH20CLRR_OFFSET    0x0D8
#define RCPM_POWMGTCSR_OFFSET     0x130
#define RCPM_IPPDEXPCR0_OFFSET    0x140

#define BOOTLOCPTRL_OFFSET        0x604
#define BOOTLOCPTRH_OFFSET        0x600

#define DCFG_BRR_OFFSET           0x00E4
#define DCFG_RSTCR_OFFSET         0x00B0
#define DCFG_COREDISR_OFFSET      0x0094
#define DCFG_RSTRQSR1_OFFSET      0x0C8
#define DCFG_RSTRQMR1_OFFSET      0x0C0

#define DCFG_DEVDISR1_OFFSET      0x70
#define DCFG_DEVDISR2_OFFSET      0x74
#define DCFG_DEVDISR3_OFFSET      0x78
#define DCFG_DEVDISR4_OFFSET      0x7C
#define DCFG_DEVDISR5_OFFSET      0x80

#define RCPM2_IPSTPCR0_OFFSET     0x8
#define RCPM2_IPSTPCR1_OFFSET     0xC
#define RCPM2_IPSTPCR2_OFFSET     0x10
#define RCPM2_IPSTPCR3_OFFSET     0x14
#define RCPM2_IPSTPCR4_OFFSET     0x28

#define RCPM2_IPSTPACKR0_OFFSET   0x18
#define RCPM2_IPSTPACKR1_OFFSET   0x1C
#define RCPM2_IPSTPACKR2_OFFSET   0x20
#define RCPM2_IPSTPACKR3_OFFSET   0x24
#define RCPM2_IPSTPACKR4_OFFSET   0x2C
#define RCPM2_POWMGTDCR_OFFSET    0x0

 // bitfield masks
#define CNTCR_EN_MASK             0x1
#define RSTCR_RESET_REQ           0x2
#define RSTRQSR1_SWRR             0x100000
#define COREPMCR_WFIL2            0x1
#define POWMGTDCR_OVRD_EN         0x80000000

#define IPPDEXPCR_MAC1_1          0x80000000    // DEVDISR2_FMAN1_MAC1
#define IPPDEXPCR_MAC1_2          0x40000000    // DEVDISR2_FMAN1_MAC2
#define IPPDEXPCR_MAC1_3          0x20000000    // DEVDISR2_FMAN1_MAC3
#define IPPDEXPCR_MAC1_4          0x10000000    // DEVDISR2_FMAN1_MAC4
#define IPPDEXPCR_MAC1_5          0x08000000    // DEVDISR2_FMAN1_MAC5
#define IPPDEXPCR_MAC1_6          0x04000000    // DEVDISR2_FMAN1_MAC6
#define IPPDEXPCR_MAC1_9          0x00800000    // DEVDISR2_FMAN1_MAC9
#define IPPDEXPCR_I2C1            0x00080000    // DEVDISR5_I2C_1
#define IPPDEXPCR_LPUART1         0x00040000    // DEVDISR5_LPUART1
#define IPPDEXPCR_FLX_TMR1        0x00020000    // DEVDISR5_FLX_TMR
#define IPPDEXPCR_OCRAM1          0x00010000    // DEVDISR5_OCRAM1
#define IPPDEXPCR_GPIO1           0x00000040    // DEVDISR5_GPIO
#define IPPDEXPCR_FM1             0x00000008    // DEVDISR2_FMAN1

#define IPPDEXPCR_MASK1           0xFC800008    // overrides for DEVDISR2
#define IPPDEXPCR_MASK2           0x000F0040    // overriddes for DEVDISR5

#define IPSTPCR0_VALUE            0xA000C201
#define IPSTPCR1_VALUE            0x00000080
#define IPSTPCR2_VALUE            0x000C0000
#define IPSTPCR3_VALUE            0x38000000
#define IPSTPCR4_VALUE            0x10A13BFC

#define DEVDISR1_QE               0x00000001
#define DEVDISR1_SEC              0x00000200
#define DEVDISR1_USB1             0x00004000
#define DEVDISR1_SATA             0x00008000
#define DEVDISR1_USB2             0x00010000
#define DEVDISR1_USB3             0x00020000
#define DEVDISR1_DMA2             0x00400000
#define DEVDISR1_DMA1             0x00800000
#define DEVDISR1_ESDHC            0x20000000
#define DEVDISR1_PBL              0x80000000

#define DEVDISR2_FMAN1            0x00000080
#define DEVDISR2_FMAN1_MAC9       0x00800000
#define DEVDISR2_FMAN1_MAC6       0x04000000
#define DEVDISR2_FMAN1_MAC5       0x08000000
#define DEVDISR2_FMAN1_MAC4       0x10000000
#define DEVDISR2_FMAN1_MAC3       0x20000000
#define DEVDISR2_FMAN1_MAC2       0x40000000
#define DEVDISR2_FMAN1_MAC1       0x80000000

#define DEVDISR3_BMAN             0x00040000
#define DEVDISR3_QMAN             0x00080000
#define DEVDISR3_PEX3             0x20000000
#define DEVDISR3_PEX2             0x40000000
#define DEVDISR3_PEX1             0x80000000

#define DEVDISR4_QSPI             0x08000000
#define DEVDISR4_DUART2           0x10000000
#define DEVDISR4_DUART1           0x20000000

#define DEVDISR5_ICMMU            0x00000001
#define DEVDISR5_I2C_1            0x00000002
#define DEVDISR5_I2C_2            0x00000004
#define DEVDISR5_I2C_3            0x00000008
#define DEVDISR5_I2C_4            0x00000010
#define DEVDISR5_WDG_5            0x00000020
#define DEVDISR5_WDG_4            0x00000040
#define DEVDISR5_WDG_3            0x00000080
#define DEVDISR5_DSPI1            0x00000100
#define DEVDISR5_WDG_2            0x00000200
#define DEVDISR5_FLX_TMR          0x00000400
#define DEVDISR5_WDG_1            0x00000800
#define DEVDISR5_LPUART6          0x00001000
#define DEVDISR5_LPUART5          0x00002000
#define DEVDISR5_LPUART3          0x00008000
#define DEVDISR5_LPUART2          0x00010000
#define DEVDISR5_LPUART1          0x00020000
#define DEVDISR5_DBG              0x00200000
#define DEVDISR5_GPIO             0x00400000
#define DEVDISR5_IFC              0x00800000
#define DEVDISR5_OCRAM2           0x01000000
#define DEVDISR5_OCRAM1           0x02000000
#define DEVDISR5_LPUART4          0x10000000
#define DEVDISR5_DDR              0x80000000

#define DEVDISR1_VALUE            0xA0C3C201
#define DEVDISR2_VALUE            0xCC0C0080
#define DEVDISR3_VALUE            0xE00C0000
#define DEVDISR4_VALUE            0x38000000
#define DEVDISR5_VALUE            0x13A33BFC

 // number of cpu's, clusters in this SoC
#define CPU_MAX_COUNT             0x4
#define CLUSTER_COUNT             0x1
#define CPU_PER_CLUSTER           0x4

 // 25mhz
#define  COUNTER_FRQ_EL0  0x017D7840    

 // pwr mgmt features supported in the soc-specific code:
 //   value == 0x0  the soc code does not support this feature
 //   value != 0x0  the soc code supports this feature
#define SOC_CORE_RELEASE       0x1
#define SOC_CORE_RESTART       0x1
#define SOC_CORE_OFF           0x1
#define SOC_CORE_STANDBY       0x1
#define SOC_CORE_PWR_DWN       0x1  
#define SOC_CLUSTER_STANDBY    0x1
#define SOC_CLUSTER_PWR_DWN    0x1  
#define SOC_SYSTEM_STANDBY     0x1
#define SOC_SYSTEM_PWR_DWN     0x1 
#define SOC_SYSTEM_OFF         0x0 
#define SOC_SYSTEM_RESET       0x1 

 //----------------------------------------------------------------------------

 // base addresses
#define GICD_BASE_ADDR  0x01401000
#define GICC_BASE_ADDR  0x01402000

 // bitfield masks
#define GICC_CTLR_EN_GRP0           0x1
#define GICC_CTLR_EN_GRP1           0x2
#define GICC_CTLR_EOImodeS_MASK     0x200
#define GICC_CTLR_DIS_BYPASS        0x60
#define GICC_CTLR_CBPR_MASK         0x10
#define GICC_CTLR_FIQ_EN_MASK       0x8
#define GICC_CTLR_ACKCTL_MASK       0x4
#define GICC_PMR_FILTER             0xFF

#define GICD_CTLR_EN_GRP0           0x1
#define GICD_CTLR_EN_GRP1           0x2
#define GICD_IGROUP0_SGI15          0x8000 
#define GICD_ISENABLE0_SGI15        0x8000 
#define GICD_ICENABLE0_SGI15        0x8000 
#define GICD_ISACTIVER0_SGI15       0x8000 
#define GICD_CPENDSGIR_CLR_MASK     0xFF000000
#define GICD_IPRIORITY_SGI15_MASK   0xFF000000
#define GICD_SPENDSGIR3_SGI15_MASK  0xFF000000
#define GICD_SPENDSGIR3_SGI15_OFFSET  0x18

 // register offsets
#define GICD_CTLR_OFFSET          0x0
#define GICD_CPENDSGIR3_OFFSET    0xF1C
#define GICD_SPENDSGIR3_OFFSET    0xF2C
#define GICD_SGIR_OFFSET          0xF00
#define GICD_IGROUPR0_OFFSET      0x080
#define GICD_TYPER_OFFSET         0x0004
#define GICD_ISENABLER0_OFFSET    0x0100
#define GICD_ICENABLER0_OFFSET    0x0180
#define GICD_IPRIORITYR3_OFFSET   0x040C
#define GICD_ISENABLERn_OFFSET    0x0100
#define GICD_ISACTIVER0_OFFSET    0x300

#define GICC_CTLR_OFFSET          0x0
#define GICC_PMR_OFFSET           0x0004
#define GICC_IAR_OFFSET           0x000C
#define GICC_DIR_OFFSET           0x1000
#define GICC_EOIR_OFFSET          0x0010

//-----------------------------------------------------------------------------

#define CPUECTLR_EL1		S3_1_C15_C2_1

#endif // _SOC_H
