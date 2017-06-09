#------------------------------------------------------------------------------
#
# Copyright (C) 2015-2017 Freescale Semiconductor, Inc. 
# Copyright 2017 NXP Semiconductors
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Author Rod Dorris <rod.dorris@nxp.com>
# 
#------------------------------------------------------------------------------
#
# qds platform specific definitions
#
# supported targets:
#   qds     - binary image
#   qds_fit - fit image
#
# -----------------------------------------------------------------------------
#
 # builds a binary image for the qds board
qds: 
	$(MAKE) SIM_BUILD=0 qds_out
	$(MAKE) SIM_BUILD=0 qds_bin
qds_out:
	@echo 'build: image=bin \ $(GIC_FILE) \ $(INTER_FILE) \ ddr $(ddr) \ debug $(dbg) \ test "$(test)"'
	@echo
qds_bin: monitor.bin

 # builds a fit image for the qds board
qds-fit: 
	$(MAKE) SIM_BUILD=0 qds_fit_out
	$(MAKE) SIM_BUILD=0 qds_fit_bin
qds_fit_out:
	@echo 'build: image=fit \ $(GIC_FILE) \ $(INTER_FILE) \ ddr $(ddr) \ debug $(dbg) \ test "$(test)"'
	@echo
qds_fit_bin: ppa.itb

# -----------------------------------------------------------------------------

 # add soc-specific asm source and headers here
SRC_SOC    =soc.s
HDRS_SOC   =soc.h soc.mac

 # add soc-specific C source and headers here
CSRC_SOC   =errata.c
CHDRS_SOC  =

 # add arm-specific source and headers here
SRC_ARMV8  =aarch64.s $(INTER_FILE).s $(GIC_FILE).s
HDRS_ARMV8 =aarch64.h

 # add security-monitor source and headers here
SRC_MNTR   =monitor.s smc64.s smc32.s vector.s
HDRS_MNTR  =smc.h

 # add platform-specific asm here
PLAT_ASM =

 # add platform-specific source and headers here
SRC_PLAT   =
HDRS_PLAT  =policy.h

 # add platform-test-specific asm files here
TEST_ASM =$(TEST_FILE)

ifeq ($(DDR_BLD), 1)
   # add ddr-specific source and headers here
  DDR_C    =ddr_init.c
  DDR_HDRS =plat.h config.h
  DDR_CMN_C    = ddr.c ddrc.c dimm.c utility.c regs.c opts.c debug.c crc32.c \
                 spd.c addr.c timer.c
  DDR_CMN_HDRS = ddr.h dimm.h utility.h immap.h opts.h regs.h debug.h \
                 timer.h
  UART_C = uart.c
  I2C_C  = i2c.c
else
  DDR_C        =
  DDR_HDRS     =
  DDR_CMN_C    =
  DDR_CMN_HDRS =
  UART_C       =
  I2C_C        =
endif

# -----------------------------------------------------------------------------

TEXTBASE=0x40100000
