//-----------------------------------------------------------------------------
// 
// Copyright (c) 2016, NXP Semiconductors
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
// Author York Sun <york.sun@nxp.com>
// 
//-----------------------------------------------------------------------------

#ifndef __LSCH3_H_
#define __LSCH3_H_

#define CONFIG_CHIP_SELECTS_PER_CTRL		4
#define CONFIG_PHYS_64BIT

#define CCI_HN_F_0_BASE			0x04200000
#define CCI_HN_F_1_BASE			0x04210000
#define CCN_HN_F_SAM_CTL		0x8
#define CCN_HN_F_SAM_NODEID_MASK	0x7f
#define CCN_HN_F_SAM_NODEID_DDR0	0x4
#define CCN_HN_F_SAM_NODEID_DDR1	0xe

#define CONFIG_SYS_FSL_DDR_ADDR		0x01080000
#define CONFIG_SYS_FSL_DDR2_ADDR	0x01090000
#define CONFIG_SYS_FSL_DDR3_ADDR	0x08210000

#define CONFIG_SYS_IFC_ADDR		0x02240000
#define CONFIG_SYS_I2C_BASE		0x02000000

#define CAAM_BASE_ADDR           0x08000000
#define CAAM_JR0_OFFSET           0x10000
#define CAAM_JR1_OFFSET           0x20000
#define CAAM_JR2_OFFSET           0x30000
#define CAAM_JR3_OFFSET           0x40000
#define CONFIG_SYS_FSL_CCSR_SEC_LE

struct sysinfo {
	unsigned long freq_platform;
	unsigned long freq_ddr_pll0;
	unsigned long freq_ddr_pll1;
};

#define FSL_CHASSIS_RCWSR0			0x01e00100
#define FSL_CHASSIS_RCWSR0_SYS_PLL_RAT_SHIFT	2
#define FSL_CHASSIS_RCWSR0_SYS_PLL_RAT_MASK	0x1f
#define FSL_CHASSIS_RCWSR0_MEM_PLL_RAT_SHIFT	10
#define FSL_CHASSIS_RCWSR0_MEM_PLL_RAT_MASK	0x3f
#define FSL_CHASSIS_RCWSR0_MEM2_PLL_RAT_SHIFT	18
#define FSL_CHASSIS_RCWSR0_MEM2_PLL_RAT_MASK	0x3f

void get_clocks(struct sysinfo *sys);

#endif /* __LSCH3_H_ */
