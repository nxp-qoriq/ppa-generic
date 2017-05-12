#------------------------------------------------------------------------------
# 
# Copyright (C) 2015-2016 Freescale Semiconductor, Inc.
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
ifeq ($(INTERCONNECT), CCN508)
	INTER_FILE=ccn508
	CCN504_L3=0
else
    $(error -> Interconnect type not set!)
endif
endif
endif

# select the debug/release build -
ifeq ($(dbg), on)
	DBG_BLD=1
	DBG_FLAGS=-Wl,-g -Wa,-g
else
	dbg=off
	DBG_BLD=0
	DBG_FLAGS=
endif

# select if ddr is initialized
ifeq ($(ddr), on)
    $(error -> DDR init not [yet] supported on this platform!)
	DDR_BLD=1
    I2C_BLD=1
    UART_BLD=1
else
    ddr=off
	DDR_BLD=0
    I2C_BLD=0
    UART_BLD=0
endif

# -----------------------------------------------------------------------------

# include the test infrastructure
TEST_SRC= $(PRE_PATH)../test
include $(TEST_SRC)/test.mk

# -----------------------------------------------------------------------------

PLATFLAGS = $(DBG_FLAGS)                   \
	-DDEBUG_BUILD=$(DBG_BLD)               \
    -DDDR_INIT=$(DDR_BLD)                  \
	-DSIMULATOR_BUILD=$(SIM_BUILD)         \
	-DPSCI_TEST=$(TEST_PSCI)               \
	-DCPU_MAX_COUNT=$(NUMBER_OF_CORES)     \
	-DCLUSTER_COUNT=$(NUMBER_OF_CLUSTERS)  \
	-DCPU_PER_CLUSTER=$(CORES_PER_CLUSTER) \
	-DSYMMETRICAL_CLUSTERS=$(CLUSTER_SYMMETRY) \
	-DL3_VIA_CCN504=$(CCN504_L3)            \
	-DCNFG_DDR=$(DDR_BLD)                  \
	-DCNFG_I2C=$(I2C_BLD)                  \
	-DCNFG_UART=$(UART_BLD)                \
    -DLSCH=$(CHASSIS)

# -----------------------------------------------------------------------------

# include the platform specifics
ifeq ($(PLAT_BUILD), 1)
     # for a platform-level build, the file is local
    PLAT_PATH=.
else
    ifeq ($(MAKECMDGOALS), clean)
        PLAT_PATH=
    endif
    ifeq ($(MAKECMDGOALS), cleanout)
        PLAT_PATH=
    endif

    ifeq ($(MAKECMDGOALS), sim)
        PLAT_PATH=platform-sim
    endif
    ifeq ($(MAKECMDGOALS), sim_out)
        PLAT_PATH=platform-sim
    endif
    ifeq ($(MAKECMDGOALS), sim_bin)
        PLAT_PATH=platform-sim
    endif

    ifeq ($(MAKECMDGOALS), rdb)
        PLAT_PATH=platform-rdb
    endif
    ifeq ($(MAKECMDGOALS), rdb_out)
        PLAT_PATH=platform-rdb
    endif
    ifeq ($(MAKECMDGOALS), rdb_bin)
        PLAT_PATH=platform-rdb
    endif

    ifeq ($(MAKECMDGOALS), rdb-fit)
        PLAT_PATH=platform-rdb
    endif
    ifeq ($(MAKECMDGOALS), rdb_fit_out)
        PLAT_PATH=platform-rdb
    endif
    ifeq ($(MAKECMDGOALS), rdb_fit_bin)
        PLAT_PATH=platform-rdb
    endif

    ifeq ($(MAKECMDGOALS), qds)
        $(error -> qds board not supported!)
        PLAT_PATH=platform-qds
    endif
    ifeq ($(MAKECMDGOALS), qds_out)
        $(error -> qds board not supported!)
        PLAT_PATH=platform-qds
    endif
    ifeq ($(MAKECMDGOALS), qds_bin)
        $(error -> qds board not supported!)
        PLAT_PATH=platform-qds
    endif
    ifeq ($(MAKECMDGOALS), qds-fit)
        $(error -> qds board not supported!)
        PLAT_PATH=platform-qds
    endif
    ifeq ($(MAKECMDGOALS), qds_fit_out)
        $(error -> qds board not supported!)
        PLAT_PATH=platform-qds
    endif
    ifeq ($(MAKECMDGOALS), qds_fit_bin)
        $(error -> qds board not supported!)
build clean         PLAT_PATH=platform-qds
    endif
endif
ifneq ($(PLAT_PATH),)
    include $(PLAT_PATH)/plat.mk
endif

# set the path to the ddr-specific sources
ifeq ($(PLAT_PATH), platform-sim)
    ifeq ($(plat), rdb)
        DDR_PATH=platform-rdb
    else
        ifeq ($(plat), qds)
            DDR_PATH=
            $(error -> qds board not supported!)
        else
            ifeq ($(DDR), on)
                DDR_PATH=
                $(error -> simulated ddr platform (plat) not specified!)
            else
                DDR_PATH=
            endif
        endif
    endif
else
    DDR_PATH=$(PLAT_PATH)
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
	@echo '  DDR=off|on'
	@echo

# -----------------------------------------------------------------------------

CMMN_SRC= $(PRE_PATH)../common
include $(CMMN_SRC)/makefile.inc

# -----------------------------------------------------------------------------

