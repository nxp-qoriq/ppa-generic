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

#define TOP_OF_OCRAM		0x1801ffff      /* 128K */
#define DDR_TEST_TABLE		(TOP_OF_OCRAM - 4096 * 3 + 1)
#define TOP_OF_STACK		(DDR_TEST_TABLE - 1)

#define CONFIG_SYS_FSL_IFC_BANK_COUNT	8

#define CONFIG_SYSCLK_FREQ	100000000
#define CONFIG_DDRCLK_FREQ	133333333

#define CONFIG_SPD_EEPROM0	0x51
#define CONFIG_SPD_EEPROM1	0x52
#define CONFIG_SPD_EEPROM2	0x53
#define CONFIG_SPD_EEPROM3	0x54
#define CONFIG_SPD_EEPROM4	0x55
#define CONFIG_SPD_EEPROM5	0x56

#define CONFIG_SYS_NUM_DDR_CTLRS	2
#define CONFIG_SYS_DIMM_SLOTS_PER_CTLR	2
#define CONFIG_FSL_DDR_BIST
/*
#define CONFIG_SHMOO_DDR
#define CONFIG_DDR_TEST_LOOPS	1
*/

#define UART_BASE	0x21c0500
#define UART_BAUD_DIV	190     /* 115200 from 700MHz plat clk */
