//-----------------------------------------------------------------------------
//
// Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. 
// Copyright 2017 NXP Semiconductors
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
//-----------------------------------------------------------------------------

char __bss_start[0] __attribute__((section(".__bss_start")));
char __bss_end[0] __attribute__((section(".__bss_end")));
char __rel_dyn_start[0] __attribute__((section(".__rel_dyn_start")));
char __rel_dyn_end[0] __attribute__((section(".__rel_dyn_end")));


#if (DDR_INIT)

void _init_membank_data(void) __attribute__ ((weak));
void _init_membank_data(void)
{
}

void _init_ddr(void) __attribute__ ((weak));
void _init_ddr(void)
{
}

void uart_init(void) __attribute__ ((weak));
void uart_init(void)
{
}

void timer_init(void) __attribute__ ((weak));
void timer_init(void)
{
}

void i2c_init(void) __attribute__ ((weak));
void i2c_init(void)
{
}

void soc_errata(void) __attribute__ ((weak));
void soc_errata(void)
{
}

#if (PSCI_TEST)
void _populate_membank_data(void) __attribute__ ((weak));
void _populate_membank_data(void)
{
}

#endif
#endif

//-----------------------------------------------------------------------------

int _ppa_main(void)
{

#if (DDR_INIT)
    _init_membank_data();
#if (PSCI_TEST)
    _populate_membank_data();
#else
    uart_init();
    soc_errata();
    timer_init();
    i2c_init();
    _init_ddr();
#endif
#endif

	return 0;
}

//-----------------------------------------------------------------------------

