/*
 * Copyright (c) 2016, NXP Semiconductors
 * All rights reserved.
 *
 * Author York Sun <york.sun@nxp.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of NXP Semiconductors nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * ALTERNATIVELY, this software may be distributed under the terms of the
 * GNU General Public License ("GPL") as published by the Free Software
 * Foundation, either version 2 of that License or (at your option) any
 * later version.
 *
 * THIS SOFTWARE IS PROVIDED BY NXP Semiconductors "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NXP Semiconductors BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef __LSCH2_H_
#define __LSCH2_H_

#define CONFIG_SYS_FSL_CCSR_GUR_BE
#define CONFIG_SYS_FSL_CCSR_DDR_BE

#define CONFIG_CHIP_SELECTS_PER_CTRL		4

#define CONFIG_SYS_FSL_DDR_ADDR		0x01080000
#define CONFIG_SYS_I2C_BASE		0x02180000

#define CONFIG_SYS_FSL_ERRATUM_A008511
#define CONFIG_SYS_FSL_ERRATUM_A009803
#define CONFIG_SYS_FSL_ERRATUM_A009942
#define CONFIG_SYS_FSL_ERRATUM_A010165


struct sysinfo {
	unsigned long freq_platform;
	unsigned long freq_ddr_pll0;
	unsigned long freq_ddr_pll1;
};

#define FSL_CHASSIS_RCWSR0			0x01ee0100
#define FSL_CHASSIS_RCWSR0_SYS_PLL_RAT_SHIFT	25
#define FSL_CHASSIS_RCWSR0_SYS_PLL_RAT_MASK	0x1f
#define FSL_CHASSIS_RCWSR0_MEM_PLL_RAT_SHIFT	16
#define FSL_CHASSIS_RCWSR0_MEM_PLL_RAT_MASK	0x3f
#define FSL_CHASSIS_RCWSR0_MEM2_PLL_RAT_SHIFT	8
#define FSL_CHASSIS_RCWSR0_MEM2_PLL_RAT_MASK	0x3f

void get_clocks(struct sysinfo *sys);

#endif /* __LSCH2_H_ */
