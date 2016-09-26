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

 # include the basic SoC architecture
include $(PRE_PATH)soc.def

# -----------------------------------------------------------------------------

# select the gic file ------------
ifeq ($(GIC), GIC400)
	GIC_FILE=gicv2
else
ifeq ($(GIC), GIC500)
	GIC_FILE=gicv3
else
    $(error -> GIC type not set!)
endif
endif

# select the interconnect file ---
ifeq ($(INTERCONNECT), CCI400)
	INTER_FILE=cci400
    CCN504_L3=0
else
ifeq ($(INTERCONNECT), CCN504)
	INTER_FILE=ccn504
    CCN504_L3=1
else
    $(error -> Interconnect type not set!)
endif
endif

# select the debug/release build -
ifeq ($(DBG), on)
    DBG_BLD=1
    DBG_FLAGS=-Wl,-g -Wa,-g
else
    DBG=off
    DBG_BLD=0
    DBG_FLAGS=
endif

# -----------------------------------------------------------------------------

# include the test infrastructure
TEST_SRC= $(PRE_PATH)../test
include $(TEST_SRC)/test.mk

# -----------------------------------------------------------------------------

PLATFLAGS = $(DBG_FLAGS)                   \
	-DDEBUG_BUILD=$(DBG_BLD)               \
	-DSIMULATOR_BUILD=$(SIM_BUILD)         \
	-DPSCI_TEST=$(TEST_PSCI)               \
	-DCPU_MAX_COUNT=$(NUMBER_OF_CORES)     \
	-DCLUSTER_COUNT=$(NUMBER_OF_CLUSTERS)  \
	-DCPU_PER_CLUSTER=$(CORES_PER_CLUSTER) \
	-DSYMMETRICAL_CLUSTERS=$(CLUSTER_SYMMETRY) \
	-DL3_VIA_CCN504=$(CCN504_L3)           

# -----------------------------------------------------------------------------

# include the platform specifics
ifeq ($(MAKECMDGOALS), sim)
    # builds from the platform folder are not supported for target sim
    PLAT_PATH=platform-sim
    include $(PLAT_PATH)/plat.mk
else
    ifeq ($(MAKECMDGOALS), rdb)
        ifeq ($(PLAT_BUILD), 1)
            # for a platform-level build, the file is local
            PLAT_PATH=.
        else
            # non-platform build, need path to find file
            PLAT_PATH=platform-rdb
        endif
        include $(PLAT_PATH)/plat.mk
    else
        ifeq ($(MAKECMDGOALS), rdb-fit)
            ifeq ($(PLAT_BUILD), 1)
                # for a platform-level build, the file is local
                PLAT_PATH=.
            else
                # non-platform build, need path to find file
                PLAT_PATH=platform-rdb
            endif
            include $(PLAT_PATH)/plat.mk
        endif
    endif
endif

# -----------------------------------------------------------------------------

help:	help_out
help_out:
	@echo
	@echo 'make rdb|rdb-fit|sim [options]'
	@echo
	@echo 'options:'
	@echo '  TEST=smp_boot|hotplug|off_abort|suspend'
	@echo '  DBG=off|on'
	@echo

# -----------------------------------------------------------------------------

CMMN_SRC= $(PRE_PATH)../common
include $(CMMN_SRC)/makefile.inc

# -----------------------------------------------------------------------------

