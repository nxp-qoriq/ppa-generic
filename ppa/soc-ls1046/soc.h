//-----------------------------------------------------------------------------
// 
// Copyright (c) 2015, 2016 Freescale Semiconductor, Inc.
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

#ifndef _SOC_H
#define	_SOC_H

 // pwr mgmt features supported in the soc-specific code:
 //   value == 0x0  the soc code does not support this feature
 //   value != 0x0  the soc code supports this feature
#define SOC_CORE_RELEASE       0x1
#define SOC_CORE_RESTART       0x1
#define SOC_CORE_OFF           0x1
#define SOC_CORE_STANDBY       0x1
#define SOC_CORE_PWR_DWN       0x1  
#define SOC_CLUSTER_STANDBY    0x0
#define SOC_CLUSTER_PWR_DWN    0x0  
#define SOC_SYSTEM_STANDBY     0x0
#define SOC_SYSTEM_PWR_DWN     0x1
#define SOC_SYSTEM_OFF         0x0 
#define SOC_SYSTEM_RESET       0x1 

 // set this switch to 1 if you need to keep the debug block
 // clocked during system power-down
#define DEBUG_ACTIVE  0

 // base addresses
#define SCFG_BASE_ADDR            0x01570000
#define DCFG_BASE_ADDR            0x01EE0000
#define RCPM_BASE_ADDR            0x01EE2000
#define SYS_COUNTER_BASE          0x02B00000
#define WDT1_BASE                 0x02AD0000
#define WDT3_BASE                 0x02A70000
#define WDT4_BASE                 0x02A80000
#define WDT5_BASE                 0x02A90000
#define TIMER_BASE_ADDR           0x02B00000
#define TZASC_BASE_ADDR           0x01500000
#define CSU_BASE_ADDR             0x01510000
#define CCI_400_BASE_ADDR         0x01180000

 // retry count for cci400 status bit
#define CCI400_PEND_CNT           0x800

 // register offsets
#define SCFG_COREBCR_OFFSET       0x0680
#define SCFG_RETREQCR_OFFSET      0x0424
#define SCFG_COREPMCR_OFFSET      0x042C
#define COREPMCR_WFIL2EN	  0x1

#define SYS_COUNTER_CNTCR_OFFSET  0x0

#define RCPM_PCPH20SETR_OFFSET    0x0D4
#define RCPM_PCPH20CLRR_OFFSET    0x0D8
#define RCPM_POWMGTCSR_OFFSET     0x130
#define RCPM_IPPDEXPCR0_OFFSET    0x140
#define RCPM_POWMGTCSR_LPM20_REQ  0x00100000

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

 // 25mhz
#define  COUNTER_FRQ_EL0  0x017D7840    

 //----------------------------------------------------------------------------

 // base addresses
#if (SIMULATOR_BUILD)
#define GICD_BASE_ADDR  0x01401000
#define GICC_BASE_ADDR  0x01402000
#else
#define GICD_BASE_ADDR  0x01410000
#define GICC_BASE_ADDR  0x01420000
#endif

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

 // OCRAM
#define  OCRAM_BASE_ADDR     0x10000000
#define  OCRAM_MID_ADDR      0x10010000
#define  OCRAM_SIZE_IN_BYTES 0x20000
#define  OCRAM_INIT_RETRY    0x2000

 // defines for the ddr driver
#define CONFIG_SYS_FSL_ERRATUM_A008511
#define CONFIG_SYS_FSL_ERRATUM_A009803
#define CONFIG_SYS_FSL_ERRATUM_A009942
#define CONFIG_SYS_FSL_ERRATUM_A010165

//-----------------------------------------------------------------------------

#define CPUECTLR_EL1		S3_1_C15_C2_1

#endif // _SOC_H
