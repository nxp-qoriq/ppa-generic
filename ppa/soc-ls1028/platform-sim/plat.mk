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
sim:
	$(MAKE) SIM_BUILD=1 sim_out
	$(MAKE) SIM_BUILD=1 sim_bin
sim_out:
	@echo 'build: image=sim \ $(GIC_FILE) \ $(INTER_FILE) \ debug $(DBG) \ test "$(TEST)"'
	@echo
sim_bin: bootmain.64.elf.rom.rmh0.rmh

# -----------------------------------------------------------------------------

# add psci-related source and headers here
SRC_PSCI   =psci.s
HDRS_PSCI  =psci.h psci_data.h

# add soc-specific source and headers here
SRC_SOC    =bootmain.64.s nonboot64.s soc.s
HDRS_SOC   =soc.h soc.mac boot.h

# add soc-specific C source and headers here
CSRC_SOC   =
CHDRS_SOC  =

# add arm-specific source and headers here
SRC_ARMV8  =aarch64.s $(INTER_FILE).s $(GIC_FILE).s
HDRS_ARMV8 =aarch64.h

# add security-monitor source and headers here
SRC_MNTR   =monitor.s smc64.s smc32.s vector.s
HDRS_MNTR  =smc.h

 # add platform-specific asm sources here
PLAT_ASM =

# add platform-specific C source and headers here
SRC_PLAT   =
HDRS_PLAT  =policy.h

 # add platform-test-specific asm sources here
TEST_ASM =$(TEST_FILE)

ifeq ($(DDR_BLD), 1)
  # add soc-specific C source and headers here
  CSRC_SOC   =
  CHDRS_SOC  =

  # add ddr-specific source and headers here
  DDR_C    =ddr_init.c
  DDR_HDRS =config.h plat.h

  # add sources for the ddr, i2c, and uart drivers here
  DRIVER_C = utility.c regs.c ddr.c ddrc.c dimm.c opts.c debug.c crc32.c spd.c \
	addr.c uart.c i2c.c timer.c
  DRIVER_HDRS = utility.h lsch3.h immap.h ddr.h dimm.h opts.h regs.h debug.h \
	errno.h io.h i2c.h lib.h timer.h uart.h
else
  CSRC_SOC    =
  CHDRS_SOC   =
  DDR_C       =
  DDR_HDRS    =
  DRIVER_C    =
  DRIVER_HDRS =
endif

# -----------------------------------------------------------------------------

bootmain.64.elf.rom.rmh0.rmh: bootmain.64.elf bootmain.64.bin
	perl $(CMMN_SRC)/elf-to-rmh.prl -f $(OBJ_DIR)/bootmain.64.elf > $(OBJ_DIR)/log.txt

# -----------------------------------------------------------------------------

