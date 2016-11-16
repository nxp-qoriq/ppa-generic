#
# make include file - build AArch64 PPA
#
# Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
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
	$(MAKE) SIM_BUILD=0 monitor.bin
rdb_out:
	@echo 'build: image=bin \ $(GIC_FILE) \ $(INTER_FILE) \ debug $(DBG) \ test "$(TEST)"'
	@echo

# builds a fit image for the rdb board
rdb-fit: 
	$(MAKE) SIM_BUILD=0 rdb_fit_out
	$(MAKE) SIM_BUILD=0 ppa.itb
rdb_fit_out:
	@echo 'build: image=fit \ $(GIC_FILE) \ $(INTER_FILE) \ debug $(DBG) \ test "$(TEST)"'
	@echo

# -----------------------------------------------------------------------------

# add psci-related source and headers here
SRC_PSCI   =psci.s
HDRS_PSCI  =psci.h psci_data.h

# add soc-specific source and headers here
SRC_SOC    =soc.s vector.s
HDRS_SOC   =soc.h soc.mac

# add arm-specific source and headers here
SRC_ARMV8  =aarch64.s $(INTER_FILE).s $(GIC_FILE).s
HDRS_ARMV8 =aarch64.h

# add security-monitor source and headers here
SRC_MNTR   =monitor.s smc64.s smc32.s
HDRS_MNTR  =smc.h smc_data.h

# add platform-specific source and headers here
SRC_PLAT   =ddr_init.c i2c.c
HDRS_PLAT  =policy.h

# add platform-specific asm here
PLAT_ASM =

# add platform-test-specific asm files here
TEST_ASM =$(TEST_FILE)

# -----------------------------------------------------------------------------

