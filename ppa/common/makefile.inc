#-----------------------------------------------------------------------------
# 
# Copyright (C) 2015-2017 Freescale Semiconductor, Inc. All rights reserved.
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
#-----------------------------------------------------------------------------
#
# Makefile - build AArch64 PPA
#
#-----------------------------------------------------------------------------

MONITOR_SRC = $(PRE_PATH)../monitor
ARMV8_SRC   = $(PRE_PATH)../armv8
PSCI_SRC    = $(PRE_PATH)../psci
CMN_SRC     = $(PRE_PATH)../common
DRVR_SRC    = $(PRE_PATH)../drivers
SOC_SRC     = $(PRE_PATH).
TEST_SRC    = $(PRE_PATH)../test
TOOL_SRC    = $(PRE_PATH)../../tools
SRC_DIR     = build/src
OBJ_DIR     = build/obj

BMAP   = -Map $(OBJ_DIR)/bootmain.64.map
BENTRY = --entry=0 -Ttext=0x0
MMAP   = -Map $(OBJ_DIR)/monitor.map

ifneq ($(TEXTBASE),)
MSCRIPT += -Ttext $(TEXTBASE)
else
TEXTBASE = 0
endif

MSCRIPT += --script $(OBJ_DIR)/ppa.ld -pie -Bsymbolic

CROSS_COMPILE	?= $(ARMV8_TOOLS_DIR)/$(ARMV8_TOOLS_PREFIX)

CC64		= $(CROSS_COMPILE)gcc
LD64		= $(CROSS_COMPILE)ld
OBJ64		= $(CROSS_COMPILE)objcopy
MKIMAGE		= mkimage
NM		= $(CROSS_COMPILE)nm

MAKE        = @make --no-print-directory
GENITS      = $(CMN_SRC)/gen_its

GIT_VERSION    := $(shell git describe --dirty --always 2>/dev/null)
CFLAGS		    = -fno-builtin -ggdb -mstrict-align -DVERSION=\"$(GIT_VERSION)\"
CFLAGS64		= $(CFLAGS) -Wa,-march=armv8-a -Wa,-EL -c -fno-stack-protector
LDFLAGS64		= --oformat=elf64-littleaarch64
ASFLAGS64		= -Wa,-march=armv8-a -Wa,-EL -x assembler-with-cpp -c
OPTFLAGS		= -dumpmachine

#------------------------------------------------

# add the prng driver files here
HASH_DRBG_HDRS =  $(wildcard  $(DRVR_SRC)/hash_drbg/include/*.h) 
HASH_DRBG_HDRS := $(notdir $(HASH_DRBG_HDRS))
HASH_DRBG_C =  $(wildcard  $(DRVR_SRC)/hash_drbg/src/*.c) 
HASH_DRBG_C := $(notdir $(HASH_DRBG_C))

#------------------------------------------------

TARGETS    =monitor.bin bootmain.64.bin
PRE_TARG   =monitor.elf

LINK_ASM   =ppa.ld.s
COMMON_ASM =utils.s
COMMON_C   =ppa_main.c uart.c lib.c
COMMON_HDRS=common.h types.h io.h uart.h lib.h errno.h lnkr.cmd

BUILD_ASM  =$(SRC_SOC) $(SRC_ARMV8) $(SRC_MNTR) $(SRC_PSCI) $(PLAT_ASM) $(COMMON_ASM) \
			$(TEST_ASM)
BUILD_C    =$(CSRC_SOC) $(SRC_PLAT) $(COMMON_C) $(DRIVER_C) $(DDR_C) $(HASH_DRBG_C)
HDRS_ASM   =$(HDRS_SOC) $(HDRS_PSCI) $(HDRS_ARMV8) $(HDRS_PLAT) $(COMMON_HDRS) \
	    $(HDRS_MNTR) $(DRIVER_HDRS) $(DDR_HDRS) $(HASH_DRBG_HDRS)
OBJECTS    =obj $(BUILD_ASM:.s=.o) $(BUILD_C:.c=.o) ppa.ld

#------------------------------------------------
# generic build targets:

#.NOTPARALLEL:

clean:
	@rm -f -r build

cleanout:
	@rm -f build/obj/*.*
	@rm -f build/src/*.*

#------------------------------------------------
GCC_VERSION_GE_62:=$(shell test `$(CC64) -dumpversion | sed 's/^\([0-9]\)\.\([0-9]\).*/\1\2/'` -ge 62 && echo true || echo false)

# relocate_rela is available in u-boot/tools folder

ifeq ($(GCC_VERSION_GE_62),false)
DO_STATIC_RELA_RELOC = \
        start=$$($(NM) $(1) | grep __rel_dyn_start | cut -f 1 -d ' '); \
        end=$$($(NM) $(1) | grep __rel_dyn_end | cut -f 1 -d ' '); \
        $(TOOL_SRC)/relocate-rela $(2) $(3) $$start $$end
else
DO_STATIC_RELA_RELOC =
endif


monitor.bin: monitor.elf ppa.its
monitor.elf: $(BUILD_C) $(BUILD_ASM) $(HDRS_ASM) $(COMMON_HDRS) $(OBJECTS)
bootmain.64.bin: bootmain.64.elf
bootmain.64.elf: $(BUILD_C) $(BUILD_ASM) $(HDRS_ASM) $(COMMON_HDRS) $(OBJECTS)

$(TARGETS):
	$(OBJ64) -v -O binary $(OBJ_DIR)/$< $(OBJ_DIR)/$@
	$(call DO_STATIC_RELA_RELOC,$(OBJ_DIR)/$<,$(OBJ_DIR)/$@,$(TEXTBASE))

$(PRE_TARG):
	$(LD64) $(MMAP) $(MSCRIPT) $(LDFLAGS64) $(wildcard $(OBJ_DIR)/*.o) -o $(OBJ_DIR)/$@

ppa.itb: ppa.its monitor.bin
	$(MKIMAGE) -f $(SRC_DIR)/ppa.its $(OBJ_DIR)/$@

bootmain.64.elf: $(HDRS_ASM) $(OBJECTS)
	$(LD64) $(BMAP) $(MSCRIPT) $(LDFLAGS64) $(wildcard $(OBJ_DIR)/*.o) -o $(OBJ_DIR)/$@

ppa.ld: ppa.ld.s lnkr.cmd src obj
	$(CC64) $(ASFLAGS64) $(PLATFLAGS) -P -E $(SRC_DIR)/$< -o $(OBJ_DIR)/$@ 

#------------------------------------------------

.s.o: $(BUILD_ASM) $(HDRS_ASM)
	$(CC64) $(ASFLAGS64) $(PLATFLAGS) $(SRC_DIR)/$< -o $(OBJ_DIR)/$@

.c.o: $(BUILD_C)
	$(CC64) $(CFLAGS64) $(PLATFLAGS) $(SRC_DIR)/$< -o $(OBJ_DIR)/$@

ppa.its: $(GENITS) src
	$(GENITS) $(SRC_DIR)/ppa.its

$(SRC_SOC): $(HDRS_SOC) $(LINK_ASM) src
	cp $(SOC_SRC)/$@ $(SRC_DIR)/$@

$(HDRS_SOC): src
	cp $(SOC_SRC)/$@ $(SRC_DIR)/$@

$(LINK_ASM): $(HDRS_SOC) $(COMMON_HDRS) src
	cp $(SOC_SRC)/$@ $(SRC_DIR)/$@

$(SRC_PSCI): $(HDRS_PSCI) src
	@cp $(PSCI_SRC)/$@ $(SRC_DIR)/$@

$(HDRS_PSCI): src
	@cp $(PSCI_SRC)/$@ $(SRC_DIR)/$@

$(CSRC_SOC): $(CHDRS_SOC) src
	@cp $(SOC_SRC)/$@ $(SRC_DIR)/$@

$(CHDRS_SOC): src
	@cp $(SOC_SRC)/$@ $(SRC_DIR)/$@

$(SRC_ARMV8): $(HDRS_ARMV8) src
	@cp $(ARMV8_SRC)/$@ $(SRC_DIR)/$@

$(HDRS_ARMV8): src
	@cp $(ARMV8_SRC)/$@ $(SRC_DIR)/$@

$(SRC_MNTR): $(HDRS_MNTR) src
	@cp $(MONITOR_SRC)/$@ $(SRC_DIR)/$@

$(HDRS_MNTR): src
	@cp $(MONITOR_SRC)/$@ $(SRC_DIR)/$@

$(SRC_PLAT): $(HDRS_PLAT) src
	@cp $(PLAT_PATH)/$@ $(SRC_DIR)/$@

$(HDRS_PLAT): src
	@cp $(PLAT_PATH)/$@ $(SRC_DIR)/$@

$(PLAT_ASM): src
	@cp $(PLAT_PATH)/$@ $(SRC_DIR)/$@

$(TEST_ASM): src
	@cp $(TEST_SRC)/$@ $(SRC_DIR)/$@

$(DDR_C): $(DDR_HDRS) src
	@cp $(DDR_PATH)/$@ $(SRC_DIR)/$@

$(DDR_HDRS): src
	@cp $(DDR_PATH)/$@ $(SRC_DIR)/$@

$(COMMON_ASM): $(HDRS_ARMV8) $(HDRS_PSCI) src
	@cp $(CMN_SRC)/$@ $(SRC_DIR)/$@

$(COMMON_C): $(COMMON_HDRS) src
	@cp $(CMN_SRC)/$@ $(SRC_DIR)/$@

$(COMMON_HDRS): src
	@cp $(CMN_SRC)/$@ $(SRC_DIR)/$@

$(DRIVER_C): $(DRIVER_HDRS) src
	@cp $(CMN_SRC)/$@ $(SRC_DIR)/$@

$(DRIVER_HDRS): src
	@cp $(CMN_SRC)/$@ $(SRC_DIR)/$@

$(HASH_DRBG_C): $(HASH_DRBG_HDRS) src
	@cp $(DRVR_SRC)/hash_drbg/src/$@ $(SRC_DIR)/$@

$(HASH_DRBG_HDRS): src
	@cp $(DRVR_SRC)/hash_drbg/include/$@ $(SRC_DIR)/$@

#------------------------------------------------

src: Makefile build
	@mkdir -p $(SRC_DIR)

obj: Makefile build
	@mkdir -p $(OBJ_DIR)

build: Makefile
	@mkdir -p build

#------------------------------------------------

