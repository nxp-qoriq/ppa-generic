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
rdb:	SIM_BUILD=0
rdb:	cleanout rdb_out monitor.bin monitor.elf
rdb_out:
	@echo 'build: image=bin \ $(GIC_FILE) \ $(INTER_FILE) \ debug $(DBG) \ test "$(TEST)"'
	@echo

# builds a fit image for the rdb board
rdb-fit:	SIM_BUILD=0
rdb-fit:	cleanout rdb_fit_out ppa.itb monitor.bin
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

CSRC_SOC   =
CHDRS_SOC  =

# add arm-specific source and headers here
SRC_ARMV8  =aarch64.s $(INTER_FILE).s $(GIC_FILE).s
HDRS_ARMV8 =aarch64.h

# add security-monitor source and headers here
SRC_MNTR   =monitor.s smc64.s smc32.s
HDRS_MNTR  =smc.h

# add platform-specific source and headers here
SRC_PLAT   =ddr_init.c
HDRS_PLAT  =policy.h config.h ls1046ardb.h

# add platform-specific asm here
PLAT_ASM =

# add platform-test-specific asm files here
TEST_ASM =$(TEST_FILE)

DRIVER_C = utility.c regs.c ddr.c ddrc.c dimm.c opts.c debug.c crc32.c spd.c \
	   addr.c uart.c i2c.c timer.c
DRIVER_HDRS = utility.h lsch2.h immap.h ddr.h dimm.h opts.h regs.h debug.h \
	      errno.h io.h i2c.h lib.h timer.h uart.h
# -----------------------------------------------------------------------------
MSCRIPT = -Ttext=0x40100000
