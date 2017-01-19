//
// Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
//
//-----------------------------------------------------------------------------

#if (DDR_INIT)

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

#endif

//-----------------------------------------------------------------------------

int _ppa_main(void)
{

#if (DDR_INIT)
    uart_init();
    soc_errata();
    timer_init();
    i2c_init();
    _init_ddr();
#endif

	return 0;
}

//-----------------------------------------------------------------------------

