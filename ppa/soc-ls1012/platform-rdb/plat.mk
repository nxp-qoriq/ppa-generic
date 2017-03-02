#
# make include file - build AArch64 PPA
#
# Copyright (C) 2015-2017 Freescale Semiconductor, Inc. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# rdb platform specific definitions
#
# supported targets:
#   rdb     - binary image
#   rdb_fit - fit image
#
# -----------------------------------------------------------------------------
#
# builds a binary image for the rdb board
rdb: 
	$(MAKE) SIM_BUILD=0 rdb_out
	$(MAKE) SIM_BUILD=0 rdb_bin
rdb_out:
	@echo 'build: image=bin \ $(GIC_FILE) \ $(INTER_FILE) \ ddr $(DDR) \ debug $(DBG) \ test "$(TEST)"'
	@echo
rdb_bin: monitor.bin

# builds a fit image for the rdb board
rdb-fit: 
	$(MAKE) SIM_BUILD=0 rdb_fit_out
	$(MAKE) SIM_BUILD=0 rdb_fit_bin
rdb_fit_out:
	@echo 'build: image=fit \ $(GIC_FILE) \ $(INTER_FILE) \ ddr $(DDR) \ debug $(DBG) \ test "$(TEST)"'
	@echo
rdb_fit_bin: ppa.itb

# -----------------------------------------------------------------------------

# add psci-related source and headers here
SRC_PSCI   =psci.s
HDRS_PSCI  =psci.h psci_data.h

# add soc-specific source and headers here
SRC_SOC    =soc.s
HDRS_SOC   =soc.h soc.mac

# add soc-specific C source and headers here
CSRC_SOC   =
CHDRS_SOC  =

# add arm-specific source and headers here
SRC_ARMV8  =aarch64.s $(INTER_FILE).s $(GIC_FILE).s
HDRS_ARMV8 =aarch64.h

# add security-monitor source and headers here
SRC_MNTR   =monitor.s smc64.s smc32.s vector.s
HDRS_MNTR  =smc.h

# add platform-specific asm here
PLAT_ASM =

# add platform-specific C source and headers here
SRC_PLAT   =
HDRS_PLAT  =policy.h

# add platform-test-specific asm files here
TEST_ASM =$(TEST_FILE)

# add platform-specific source and headers here
ifeq ($(DDR_BLD), 1)
  # add ddr-specific source and headers here
  DDR_C    =ddr_init.c
  DDR_HDRS =config.h

  DRIVER_C = fsl_mmdc.c uart.c timer.c
  DRIVER_HDRS = fsl_mmdc.h lsch2.h errno.h io.h lib.h timer.h uart.h
else
  DDR_C       =
  DDR_HDRS    =
  DRIVER_C    =
  DRIVER_HDRS =
endif

# -----------------------------------------------------------------------------

MSCRIPT = -Ttext=0x40100000
