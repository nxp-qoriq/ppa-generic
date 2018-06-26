//---------------------------------------------------------------------------
// 
// Copyright 2017 NXP Semiconductor
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
// Author Rod Dorris <rod.dorris@nxp.com>
// 
//---------------------------------------------------------------------------

#ifndef _GICV3_H
#define	_GICV3_H

//-----------------------------------------------------------------------------

#define GIC_RD_OFFSET       0x00020000  // offset between redistributors
#define GIC_SGI_OFFSET      0x00020000  // offset between SGI's
#define GIC_RD_2_SGI_OFFSET 0x00010000  // offset from rd base to sgi base

 // gic register offsets
#define GICD_CTLR_OFFSET        0x0
#define GICD_CLR_SPI_SR         0x58
#define GICD_IGROUPR_2          0x88
#define GICD_ISENABLER_2        0x108
#define GICD_ICENABLER_2        0x188
#define GICD_ICPENDR_2          0x288
#define GICD_ICACTIVER_2        0x388
#define GICD_IPRIORITYR_22      0x458
#define GICD_ICFGR_5            0xC14
#define GICD_IGRPMODR_2         0xD08

#define GICD_IROUTER60_OFFSET   0x61e0
#define GICD_IROUTER76_OFFSET   0x6260
#define GICD_IROUTER89_OFFSET   0x62C8
#define GICD_IROUTER112_OFFSET  0x6380
#define GICD_IROUTER113_OFFSET  0x6388

#define GICR_ICENABLER0_OFFSET  0x180
#define GICR_CTLR_OFFSET        0x0
#define GICR_IGROUPR0_OFFSET    0x80
#define GICR_IGRPMODR0_OFFSET   0xD00
#define GICR_IPRIORITYR3_OFFSET 0x40C
#define GICR_ICPENDR0_OFFSET    0x280
#define GICR_ISENABLER0_OFFSET  0x100
#define GICR_TYPER_OFFSET       0x8
#define GICR_WAKER_OFFSET       0x14
#define GICR_ICACTIVER0_OFFSET  0x380
#define GICR_ICFGR0_OFFSET      0xC00

 // gic bitfields
#define GICD_CTLR_EN_GRP_MASK   0x7
#define GICD_CTLR_EN_GRP_1NS    0x2
#define GICD_CTLR_EN_GRP_1S     0x4
#define GICD_CTLR_EN_GRP_0      0x1
#define GICD_CTLR_ARE_S_MASK    0x10
#define GICD_CTLR_RWP_MASK      0x80000000

#define GICR_ICENABLER0_SGI15   0x00008000
#define GICR_CTLR_RWP_MASK      0x8
#define GICR_CTLR_DPG0_MASK     0x2000000
#define GICR_IGROUPR0_SGI15     0x00008000
#define GICR_IGRPMODR0_SGI15    0x00008000
#define GICR_ISENABLER0_SGI15   0x00008000
#define GICR_IPRIORITYR3_SGI15_MASK  0xFF000000
#define GICR_ICPENDR0_SGI15     0x8000

#define GIC_SPI_89_MASK         0x02000000
#define GIC_SPI89_PRIORITY_MASK 0xFF00
#define GIC_IRM_SPI89           0x80000000

#define GICD_IROUTER_VALUE      0x100
#define GICR_WAKER_SLEEP_BIT    0x2
#define GICR_WAKER_ASLEEP       (1 << 2 | 1 << 1)

#define ICC_SRE_EL3_SRE          0x1
#define ICC_IGRPEN0_EL1_EN       0x1
#define ICC_CTLR_EL3_CBPR_EL1S   0x1
#define ICC_CTLR_EL3_RM          0x20
#define ICC_CTLR_EL3_EOIMODE_EL3 0x4
#define ICC_CTLR_EL3_PMHE        0x40
#define ICC_PMR_EL1_P_FILTER     0xFF
#define ICC_IAR0_EL1_SGI15       0xF
#define ICC_SGI0R_EL1_INTID      0x0F000000
#define ICC_IAR0_INTID_SPI_89    0x59

#define  ICC_IGRPEN0_EL1 S3_0_C12_C12_6
#define  ICC_IGRPEN1_EL1 S3_0_C12_C12_7
#define  ICC_SGI0R_EL1   S3_0_C12_C11_7
#define  ICC_PMR_EL1     S3_0_C4_C6_0
#define  ICC_IAR0_EL1    S3_0_C12_C8_0
#define  ICC_EOIR0_EL1   S3_0_C12_C8_1
#define  ICC_SRE_EL3     S3_6_C12_C12_5
#define  ICC_CTLR_EL3    S3_6_C12_C12_4
#define  ICC_SRE_EL2     S3_4_C12_C9_5
#define  ICC_IGRPEN1_EL3 S3_6_C12_C12_7
#define  ICC_CTLR_EL1    S3_0_C12_C12_4

#endif // _GICV3_H
