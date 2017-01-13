//
// Copyright (C) 2015, 2016 Freescale Semiconductor, Inc. All rights reserved.
//
//-----------------------------------------------------------------------------

int _ppa_main(void)
{
	return 0;
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
