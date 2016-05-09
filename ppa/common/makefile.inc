#
# Makefile - build AArch64 PPA
#
# Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
#
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

MONITOR_SRC = ../../monitor
ARMV8_SRC   = ../../armv8
PSCI_SRC    = ../../psci
CMN_SRC     = ../../common
SOC_SRC     = ../
PLAT_SRC    = ./
TEST_SRC    = ./
SRC_DIR     = build/src
OBJ_DIR     = build/obj

BMAP   = -Map $(OBJ_DIR)/bootmain.64.map
BENTRY = --entry=0 -Ttext=0x0
MMAP   = -Map $(OBJ_DIR)/monitor.map
MSCRIPT = --script $(OBJ_DIR)/ppa.ld

CROSS_COMPILE	?= $(ARMV8_TOOLS_DIR)/aarch64-none-elf-

CC64		= $(CROSS_COMPILE)gcc
LD64		= $(CROSS_COMPILE)ld
OBJ64		= $(CROSS_COMPILE)objcopy
MKIMAGE		= mkimage

CFLAGS64		= $(CFLAGS) -Wa,-march=armv8-a -Wa,-EL -c -DTEST=$(TEST_VAL)
LDFLAGS64		= --oformat=elf64-littleaarch64
ASFLAGS64		= -Wa,-march=armv8-a -Wa,-EL -x assembler-with-cpp -c -DTEST=$(TEST_VAL)
OPTFLAGS		= -dumpmachine

#------------------------------------------------

TARGETS    =monitor.bin monitor_test.bin bootmain.64.bin
PRE_TARG   =monitor.elf monitor_test.elf

LINK_ASM   =ppa.ld.s
COMMON_ASM =
COMMON_C   =ppa_main.c
COMMON_HDRS=common.h

BUILD_ASM  =$(SRC_SOC) $(SRC_ARMV8) $(SRC_MNTR) $(SRC_PSCI) $(PLAT_ASM) $(COMMON_ASM)
BUILD_C    =$(SRC_PLAT) $(COMMON_C)
HDRS_ASM   =$(HDRS_SOC) $(HDRS_PSCI) $(HDRS_ARMV8) $(HDRS_PLAT) $(COMMON_HDRS)
OBJECTS    =obj $(BUILD_ASM:.s=.o) $(BUILD_C:.c=.o) ppa.ld

TST_ASM    =$(SRC_SOC) $(SRC_ARMV8) $(SRC_MNTR) $(SRC_PSCI) $(PLAT_ASM) \
			$(COMMON_ASM) $(TEST_ASM)

TST_OBJECTS=obj $(TST_ASM:.s=.o) $(BUILD_C:.c=.o) ppa.ld

#------------------------------------------------
# generic build targets:

 # copies all source files for target 'all' to the source area - 
 # does not assemble/compile
prep:	$(BUILD_ASM) $(BUILD_C) $(HDRS_ASM) $(COMMON_HDRS) $(LINK_ASM)
prep_test:	$(TST_ASM) $(BUILD_C) $(HDRS_ASM) $(COMMON_HDRS) $(LINK_ASM)

clean:
	@rm -f -r build

#------------------------------------------------

monitor.bin: monitor.elf
monitor_test.bin: monitor_test.elf
bootmain.64.bin: bootmain.64.elf
monitor_test.elf: $(HDRS_ASM) $(COMMON_HDRS) $(TST_OBJECTS)
monitor.elf: $(HDRS_ASM) $(COMMON_HDRS) $(OBJECTS)

$(TARGETS):
	$(OBJ64) -v -O binary $(OBJ_DIR)/$< $(OBJ_DIR)/$@

$(PRE_TARG):
	$(LD64) $(MMAP) $(MSCRIPT) $(LDFLAGS64) $(wildcard $(OBJ_DIR)/*.o) -o $(OBJ_DIR)/$@

ppa.itb: ppa.its monitor.bin
	$(MKIMAGE) -f $(SRC_DIR)/$< $(OBJ_DIR)/$@

bootmain.64.elf: $(HDRS_ASM) $(TST_OBJECTS)
	$(LD64) $(BMAP) $(MSCRIPT) $(LDFLAGS64) $(wildcard $(OBJ_DIR)/*.o) -o $(OBJ_DIR)/$@

ppa.ld: ppa.ld.s Makefile obj
	$(CC64) $(ASFLAGS64) -P -E $(SRC_DIR)/$< -o $(OBJ_DIR)/$@ 

#------------------------------------------------

.s.o:
	$(CC64) $(ASFLAGS64) $(PLATFLAGS) $(SRC_DIR)/$< -o $(OBJ_DIR)/$@

.c.o:
	$(CC64) $(CFLAGS64) $(PLATFLAGS) $(SRC_DIR)/$< -o $(OBJ_DIR)/$@

ppa.its: src
	@cp $(CMN_SRC)/$@ $(SRC_DIR)/$@

$(SRC_SOC) $(HDRS_SOC): src
	@cp $(SOC_SRC)/$@ $(SRC_DIR)/$@

$(SRC_PSCI) $(HDRS_PSCI): src
	@cp $(PSCI_SRC)/$@ $(SRC_DIR)/$@

$(SRC_ARMV8) $(HDRS_ARMV8): src
	@cp $(ARMV8_SRC)/$@ $(SRC_DIR)/$@

$(SRC_MNTR): src
	@cp $(MONITOR_SRC)/$@ $(SRC_DIR)/$@

$(SRC_PLAT) $(HDRS_PLAT) $(LINK_ASM): src
	@cp $(PLAT_SRC)/$@ $(SRC_DIR)/$@

$(PLAT_ASM): src
	@cp $(PLAT_SRC)/$@ $(SRC_DIR)/$@

$(TEST_ASM): src
	@cp $(SOC_SRC)/$@ $(SRC_DIR)/$@

$(COMMON_C) $(COMMON_ASM) $(COMMON_HDRS): src
	@cp $(CMMN_SRC)/$@ $(SRC_DIR)/$@

#------------------------------------------------

src: Makefile build
	@mkdir -p $(SRC_DIR)

obj: Makefile build
	@mkdir -p $(OBJ_DIR)

build: Makefile
	@mkdir -p build

#------------------------------------------------

