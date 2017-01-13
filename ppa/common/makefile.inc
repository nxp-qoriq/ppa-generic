#
# Makefile - build AArch64 PPA
#
# Copyright (C) 2015-2017 Freescale Semiconductor, Inc. All rights reserved.
#
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

MONITOR_SRC = $(PRE_PATH)../monitor
ARMV8_SRC   = $(PRE_PATH)../armv8
PSCI_SRC    = $(PRE_PATH)../psci
CMN_SRC     = $(PRE_PATH)../common
SOC_SRC     = $(PRE_PATH).
TEST_SRC    = $(PRE_PATH)../test
SRC_DIR     = build/src
OBJ_DIR     = build/obj

BMAP   = -Map $(OBJ_DIR)/bootmain.64.map
BENTRY = --entry=0 -Ttext=0x0
MMAP   = -Map $(OBJ_DIR)/monitor.map
MSCRIPT += --script $(OBJ_DIR)/ppa.ld

CROSS_COMPILE	?= $(ARMV8_TOOLS_DIR)/aarch64-none-elf-

CC64		= $(CROSS_COMPILE)gcc
LD64		= $(CROSS_COMPILE)ld
OBJ64		= $(CROSS_COMPILE)objcopy
MKIMAGE		= mkimage
MAKE        = @make --no-print-directory

#GIT_VERSION    := $(shell git describe --dirty --always)
CFLAGS		    = -fno-builtin -ggdb -mstrict-align -DVERSION=\"$(GIT_VERSION)\"
#CFLAGS		    = -fno-builtin -ggdb -mstrict-align
CFLAGS64		= $(CFLAGS) -Wa,-march=armv8-a -Wa,-EL -c
LDFLAGS64		= --oformat=elf64-littleaarch64
ASFLAGS64		= -Wa,-march=armv8-a -Wa,-EL -x assembler-with-cpp -c
OPTFLAGS		= -dumpmachine

#------------------------------------------------

TARGETS    =monitor.bin bootmain.64.bin
PRE_TARG   =monitor.elf

LINK_ASM   =ppa.ld.s
COMMON_ASM =utils.s
COMMON_C   =ppa_main.c
COMMON_HDRS=common.h lnkr.cmd

BUILD_ASM  =$(SRC_SOC) $(SRC_ARMV8) $(SRC_MNTR) $(SRC_PSCI) $(PLAT_ASM) $(COMMON_ASM) \
			$(TEST_ASM)
BUILD_C    =$(CSRC_SOC) $(SRC_PLAT) $(COMMON_C) $(DRIVER_C) $(DDR_C)
HDRS_ASM   =$(HDRS_SOC) $(HDRS_PSCI) $(HDRS_ARMV8) $(HDRS_PLAT) $(COMMON_HDRS) \
	    $(HDRS_MNTR) $(DRIVER_HDRS) $(DDR_HDRS)
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

monitor.bin: monitor.elf
monitor.elf: $(BUILD_C) $(BUILD_ASM) $(HDRS_ASM) $(COMMON_HDRS) $(OBJECTS)
bootmain.64.bin: bootmain.64.elf
bootmain.64.elf: $(BUILD_C) $(BUILD_ASM) $(HDRS_ASM) $(COMMON_HDRS) $(OBJECTS)

$(TARGETS):
	$(OBJ64) -v -O binary $(OBJ_DIR)/$< $(OBJ_DIR)/$@

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

ppa.its: src
	@cp $(CMN_SRC)/$@ $(SRC_DIR)/$@

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
	@cp $(CMMN_SRC)/$@ $(SRC_DIR)/$@

$(COMMON_C): $(COMMON_HDRS) src
	@cp $(CMMN_SRC)/$@ $(SRC_DIR)/$@

$(COMMON_HDRS): src
	@cp $(CMMN_SRC)/$@ $(SRC_DIR)/$@

$(DRIVER_C): $(DRIVER_HDRS) src
	@cp $(CMMN_SRC)/$@ $(SRC_DIR)/$@

$(DRIVER_HDRS): src
	@cp $(CMMN_SRC)/$@ $(SRC_DIR)/$@

#------------------------------------------------

src: Makefile build
	@mkdir -p $(SRC_DIR)

obj: Makefile build
	@mkdir -p $(OBJ_DIR)

build: Makefile
	@mkdir -p build

#------------------------------------------------

