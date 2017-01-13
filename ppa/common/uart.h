/*
 * Copyright (c) 2016, NXP Semiconductors
 * All rights reserved.
 *
 * Author York Sun <york.sun@nxp.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of NXP Semiconductors nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * ALTERNATIVELY, this software may be distributed under the terms of the
 * GNU General Public License ("GPL") as published by the Free Software
 * Foundation, either version 2 of that License or (at your option) any
 * later version.
 *
 * THIS SOFTWARE IS PROVIDED BY NXP Semiconductors "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NXP Semiconductors BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef __UART_H__
#define __UART_H__

struct uart {
	unsigned char rbr;	/* 0 */
	unsigned char ier;
	unsigned char fcr;
	unsigned char lcr;
	unsigned char mcr;	/* 4 */
	unsigned char lsr;
	unsigned char msr;
	unsigned char scr;
};

#define thr rbr
#define dlb rbr
#define dmb ier

#define UART_LSR_TEMT_MASK	0x40
#define UART_LSR_THRE_MASK	0x20
#define UART_LCR_DLAB		0x80

#define UART_IER_INIT		0x00
#define UART_MCR_INIT		0x02
#define UART_FCR_INIT		0x07
#define UART_LCR_INIT		0x03	/* 8n1 */

void uart_init(void);
void putc(const char c);
void puts(const char *s);
void print_uint(unsigned long long n);
void print_hex(unsigned long long n);

#endif /* __UART_H__ */
