#
# Makefile - build AArch64 PPA
#
# Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
#
# -----------------------------------------------------------------------------
# Define the following environment variables (and make sure they point to your
# gcc ARM toolchain):
#
# ARMV8_TOOLS_DIR=/c/utils/linaro_gcc/gcc-linaro-aarch64-none-elf-4.8-2014.01_win32/bin
# ARMV8_TOOLS_PREFIX=aarch64-none-elf-
# FILE_NAMES_DIR=/tmp
# export ARMV8_TOOLS_DIR
# export ARMV8_TOOLS_PREFIX
# export FILE_NAMES_DIR
#
# Put the tools dir on your path:
#
# PATH=$ARMV8_TOOLS_DIR:$PATH
#
# -----------------------------------------------------------------------------
# build targets:

 # the std binary image
all:	TEST_VAL:=0
all:	monitor.bin

 # builds the FIT image for uboot, uefi loading
fit:	TEST_VAL:=0
fit:	ppa.itb monitor.bin

 # generates an image with test code included
test:	TEST_VAL:=1
test:	monitor_test.bin

 # generates a FIT image with test code included
fit_test:	TEST_VAL:=1
fit_test:	ppa_test.itb monitor_test.bin

#------------------------------------------------

 # platform-specific build flags
PLATFLAGS = -DSIMULATOR_BUILD=0

#------------------------------------------------

# add psci-related source and headers here
SRC_PSCI   =psci.s
HDRS_PSCI  =psci.h psci_data.h

# add soc-specific source and headers here
SRC_SOC    =soc.s vector.s
HDRS_SOC   =soc.h soc.mac

# add arm-specific source and headers here
SRC_ARMV8  =aarch64.s ccn504.s gicv3.s
HDRS_ARMV8 =aarch64.h

# add security-monitor source and headers here
SRC_MNTR   =monitor.s smc64.s smc32.s
HDRS_MNTR  =

# add platform-specific source and headers here
SRC_PLAT   =ddr_init.c i2c.c
HDRS_PLAT  =policy.h

# add platform-specific asm here
PLAT_ASM =

# add platform-test-specific asm files here
TEST_ASM =test_psci.s

# -----------------------------------------------------------------------------

CMMN_SRC= ../../common
include $(CMMN_SRC)/makefile.inc

# -----------------------------------------------------------------------------

