#------------------------------------------------------------------------------
# 
# Copyright (C) 2015, 2016 Freescale Semiconductor, Inc.
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

# select the test files ----------
ifeq ($(test), smp_boot)
	TEST_PSCI=1
    ifeq ($(NUMBER_OF_CLUSTERS), 1)
        TEST_FILE=test_cpu_on_1cluster.s
    else
    ifeq ($(NUMBER_OF_CLUSTERS), 2)
        TEST_FILE=test_cpu_on_2cluster.s
    else
    ifeq ($(NUMBER_OF_CLUSTERS), 4)
        TEST_FILE=test_cpu_on_4cluster.s
    else
    ifeq ($(NUMBER_OF_CLUSTERS), 8)
        TEST_FILE=test_cpu_on_8cluster.s
    else
        $(error -> Number of Clusters not set!)
    endif
    endif
    endif
    endif
else
ifeq ($(test), speed_boot)
	TEST_PSCI=1
    ifeq ($(NUMBER_OF_CLUSTERS), 1)
        TEST_FILE=test_sboot_1cluster.s
    else
    ifeq ($(NUMBER_OF_CLUSTERS), 2)
        TEST_FILE=test_sboot_2cluster.s
    else
    ifeq ($(NUMBER_OF_CLUSTERS), 4)
        TEST_FILE=test_sboot_4cluster.s
    else
    ifeq ($(NUMBER_OF_CLUSTERS), 8)
        TEST_FILE=test_sboot_8cluster.s
    else
        $(error -> Number of Clusters not set!)
    endif
    endif
    endif
    endif
else
ifeq ($(test), hotplug)
	TEST_PSCI=1
    TEST_FILE=test_cpu_hotplug.s
else
ifeq ($(test), cpu_errata)
	TEST_PSCI=1
    TEST_FILE=test_cpu_errata.s
else
ifeq ($(test), off_abort)
	TEST_PSCI=1
    TEST_FILE=test_cpu_hotplug_abort.s
else
ifeq ($(test), suspend)
    ifeq ($(NUMBER_OF_CLUSTERS), 1)
	    TEST_PSCI=1
        TEST_FILE=test_cpu_suspend_1cluster.s
    else
	    TEST_PSCI=1
        TEST_FILE=test_cpu_suspend_2cluster.s
    endif
else
ifeq ($(test), aarch32)
	TEST_PSCI=1
    TEST_FILE=test_aarch32_2core.s
else
ifeq  ($(test), aarch32BE)
	TEST_PSCI=1
    TEST_FILE=test_aarch32_2coreBE.s
else
ifeq  ($(test), prng)
	TEST_PSCI=1
    TEST_FILE=test_prng.s
else
ifeq  ($(test), membank)
	TEST_PSCI=1
    TEST_FILE=test_membank_data.s
else
ifeq  ($(TEST), sys_off)
	TEST_PSCI=1
    ifeq ($(NUMBER_OF_CORES), 1)
        TEST_FILE=test_sysoff_1core.s
    else
        TEST_FILE=test_sysoff_multi.s
    endif
else
    test=none
	TEST_PSCI=0
    TEST_FILE=
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# -----------------------------------------------------------------------------

