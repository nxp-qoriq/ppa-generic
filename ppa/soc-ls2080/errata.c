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

#include "lib.h"
#include "io.h"
#include "i2c.h"

#define SVR			0x01e000a4
#define SVR_WO_E		0xFFFFFE
#define SVR_LS2085		0x870100
#define SVR_SOC_VER(svr)	(((svr) >> 8) & SVR_WO_E)

bool soc_has_dp_ddr(void)
{
	unsigned int svr = in_le32((void *)SVR);

	/* LS2085A has DP_DDR */
	if (SVR_SOC_VER(svr) == SVR_LS2085)
		return true;

	return false;
}

/* Fix me: shall avoid setting register for disabled DDR controller */
static void erratum_a008336(void)
{
	unsigned int *eddrtqcr1;

	eddrtqcr1 = (void *)0x70012c000ULL + 0x800;
	out_le32(eddrtqcr1, 0x63b30002);

	eddrtqcr1 = (void *)0x70012d000ULL + 0x800;
	out_le32(eddrtqcr1, 0x63b30002);
}

/* Fix me: shall check if DDRC is enabled */
static void erratum_a008514(void)
{
	const unsigned int *eddrtqcr1 = (void *)0x700132000ULL + 0x800;

	if (soc_has_dp_ddr())
		out_le32(eddrtqcr1, 0x63b20002);
}

static void erratum_a009203(void)
{
	struct ls_i2c *ccsr_i2c = (void *)CONFIG_SYS_I2C_BASE;

	i2c_out(&ccsr_i2c->dbg, I2C_GLITCH_EN);
}

void soc_errata(void)
{
	erratum_a008514();
	erratum_a008336();
	erratum_a009203();
}
