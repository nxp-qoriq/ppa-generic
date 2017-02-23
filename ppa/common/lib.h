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

#ifndef __LIB_H__
#define __LIB_H__

#include "config.h"
#include "errno.h"
#include "uart.h"

#ifdef CONFIG_SYS_LSCH3
#include "lsch3.h"
#elif defined(CONFIG_SYS_LSCH2)
#include "lsch2.h"
#else
#error "Unknown chassis"
#endif

typedef int bool;
#define true	1
#define false	0
#define NULL ((void *)0)

#define offsetof(type, member) ((unsigned long)&((type *)0)->member)
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

#define min(x, y) ({				\
        typeof(x) _min1 = (x);			\
        typeof(y) _min2 = (y);			\
        (void) (&_min1 == &_min2);		\
        _min1 < _min2 ? _min1 : _min2; })

#define max(x, y) ({				\
        typeof(x) _max1 = (x);			\
        typeof(y) _max2 = (y);			\
        (void) (&_max1 == &_max2);		\
        _max1 > _max2 ? _max1 : _max2; })

static inline void bzero(register void *b, register unsigned long len)
{
	while(len--)
		*(unsigned char *)b++ = 0;
}


static inline int fls1(register unsigned long mask)
{
	register int i;

	if (mask == 0)
		return 0;

	for (i = 1; mask != 1; i++) {
		mask >>= 1;
	}

	return i;
}

static inline unsigned long ilog2(register unsigned long x)
{
	return fls1(x) - 1;
}

unsigned int crc32(unsigned int crc, const void *buf, unsigned int size);

#ifdef DEBUG
#define debug(s) puts(s)
#define debug_int(s, a) { puts(s); print_uint(a); puts("\n"); }
#define debug_hex(s, a) { puts(s); print_hex(a); puts("\n"); }
#else
#define debug(s) {}
#define debug_int(s, a) {}
#define debug_hex(s, a) {}
#endif

static inline void hang(void)
{
	while(1)
		;
}

static inline void panic(char *s)
{
	puts(s);
	hang();
}

void memcpy(void *dest, const void *src, register unsigned long count);

#endif /* __LIB_H__ */
