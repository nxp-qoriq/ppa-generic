#
# make include file - build AArch64 PPA
#
# Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
#
# -----------------------------------------------------------------------------
#
# sim platform specific definitions
#
# supported targets:
#   sim - binary image linked with bootrom code
#
# -----------------------------------------------------------------------------
#
# builds a ppa bound in with the bootrom code, suitable for execution on any target which
# does not contain bootrom (simulator, emulator)
sim:	SIM_BUILD=1
sim:	cleanout sim_out bootmain.64.bin bootmain.64.elf bootmain.64.elf.rom.rmh0.rmh
sim_out:
	@echo 'build: image=sim \ $(GIC_FILE) \ $(INTER_FILE) \ debug $(DBG) \ test "$(TEST)"'
	@echo

# -----------------------------------------------------------------------------

# add psci-related source and headers here
SRC_PSCI   =psci.s
HDRS_PSCI  =psci.h psci_data.h

# add soc-specific source and headers here
SRC_SOC    =bootmain.64.s nonboot64.s soc.s vector.s
HDRS_SOC   =soc.h soc.mac boot.h

# add arm-specific source and headers here
SRC_ARMV8  =aarch64.s $(INTER_FILE).s $(GIC_FILE).s
HDRS_ARMV8 =aarch64.h

# add security-monitor source and headers here
SRC_MNTR   =monitor.s smc64.s smc32.s
HDRS_MNTR  =smc.h

# add platform-specific source and headers here
SRC_PLAT   =ddr_init.c i2c.c
HDRS_PLAT  =policy.h

 # add platform-specific asm sources here
PLAT_ASM =

 # add platform-test-specific asm sources here
TEST_ASM =$(TEST_FILE)

# -----------------------------------------------------------------------------

bootmain.64.elf.rom.rmh0.rmh: bootmain.64.elf
	perl $(CMMN_SRC)/elf-to-rmh.prl -f $(OBJ_DIR)/bootmain.64.elf > $(OBJ_DIR)/log.txt

# -----------------------------------------------------------------------------

