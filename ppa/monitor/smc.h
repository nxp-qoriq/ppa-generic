// smc.h
// 
// header file for secure fw
//
// Copyright (c) 2016, Freescale Semiconductor, Inc. All rights reserved.
//

//-----------------------------------------------------------------------------

#ifndef _SMC_H
#define	_SMC_H

//-----------------------------------------------------------------------------

.equ REGISTER_OBFUSCATE, 0xA5A5A5A5A5A5A5A5

//-----------------------------------------------------------------------------

#define  SMC_EL2_IS_LE    0x0
#define  SMC_EL2_IS_BE    0x1

#define SMC_AARCH32_MODE  0x1
#define SMC_AARCH64_MODE  0x0

 // this is a size in bytes of each core's stack - the boot core
 // will automatically be allocated TWICE this amount
 // Note: offset must be a quadword multiple
#define STACK_OFFSET     0x400
#define STACK_BASE_ADDR  (OCRAM_BASE_ADDR + OCRAM_SIZE_IN_BYTES)

 // function return values
#define  SMC_SUCCESS         0
#define  SMC_UNIMPLEMENTED  -1
#define  SMC_INVALID        -2
#define  SMC_BAD_PARM       -3
#define  SMC_INVALID_EL     -4
#define  SMC_FAILURE        -5

#define  SIP_PRNG           0xFF10
#define  SIP_RNG            0xFF11
#define  SIP_MEMBANK        0xFF12

.equ SIP_PRNG_32BIT,  0
.equ SIP_PRNG_64BIT,  1
.equ SIP_RNG_32BIT,   0
.equ SIP_RNG_64BIT,   1

//-----------------------------------------------------------------------------

#define  SMC_FUNCTION_MASK  0xFFFF

 // smc function id's - these are "fast", non-preemptible functions

 // this function returns the number of implemented smc-sip functions
#define  SIP_COUNT_ID     0xC200FF00

 // this function returns the number of implemented smc-arch functions
#define  ARCH_COUNT_ID    0xC000FF00

 // this function will return to EL2 @ Aarch32
 // in:  x0 = function id
 //      x1 = start address for EL2 @ Aarch32
 //      x2 = first parameter to EL2
 //      x3 = second parameter to EL2
 //      x4 = 0, EL2 in LE (little-endian)
 //      x4 = 1, EL2 in BE (big-endian)
#define  ARCH_EL2_2_AARCH32_ID  0xC000FF04

 // this is the 32-bit interface to the PRNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit PRNG requested
 //      x1 = 1, 64-bit PRNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-bit PRNG, or hi-order 32-bits of 64-bit PRNG
 //      x2 = lo-order 32-bits of 64-bit PRNG
#define  SIP_PRNG_32 0x8200FF10

 // this is the 32-bit interface to the hw RNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit RNG requested
 //      x1 = 1, 64-bit RNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-bit PRNG, or hi-order 32-bits of 64-bit PRNG
 //      x2 = lo-order 32-bits of 64-bit PRNG
#define  SIP_RNG_32 0x8200FF11

 // this is the 64-bit interface to the PRNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit PRNG requested
 //      x1 = 1, 64-bit PRNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-or-64-bit PRNG
#define  SIP_PRNG_64 0xC200FF10

 // this is the 64-bit interface to the hw RNG function
 // in:  x0 = function id
 //      x1 = 0, 32-bit hw RNG requested
 //      x1 = 1, 64-bit hw RNG requested
 // out: x0 = 0, success
 //      x0 != 0, failure
 //      x1 = 32-or-64-bit PRNG
#define  SIP_RNG_64 0xC200FF11

 // this is the 64-bit interface to the MEMBANK function
 // in:  x0 = function id
 //      x1 = memory bank requested (1, 2, 3, etc)
 // out: x0     = -1, failure
 //             = -2, invalid parameter
 //      x0 [0] =  1, valid bank
 //             =  0, invalid bank
 //       [1:2] =  1, ddr  
 //             =  2, sram
 //             =  3, special
 //         [3] =  1, not the last bank
 //             =  0, last bank
 //      x1     =  physical start address (not valid unless x0[0]=1)
 //      x2     =  size in bytes (not valid unless x0[0]=1)
#define  SIP_MEMBANK_64 0xC200FF12

//-----------------------------------------------------------------------------

 // structure for recording memory bank data
 // in 'C' this looks like:
 // struct MemDataStruc {
 //          uint32_t  bankState,        // (0=invalid, 1=valid)
 //          uint32_t  bankType,         // (1=ddr, 2=sram, 3=peripheral)
 //          uint64_t  bankStartAddress, // physical address
 //          uint64_t  bankSizeInBytes
 //        } 
 // this structure will be populated by the platform-specific
 // ddr initialization, and consumed by the smc function SIP_MEMBANK_64

 // max size of the membank data region in bytes
 // Note: must be a 64-bit multiple
#define MEMBANK_REGION_MAX_SIZE 1024

 // keep these in synch with MemDataStruc
#define MEMBANK_DATA_SIZE      0x18  // size in bytes of MemDataStruc
#define MEMDATA_STATE_OFFSET   0x0
#define MEMDATA_TYPE_OFFSET    0x4
#define MEMDATA_ADDR_OFFSET    0x8
#define MEMDATA_SIZE_OFFSET    0x10

#define MEMBANK_STATE_INVALID  0x0
#define MEMBANK_STATE_VALID    0x1

#define MEMBANK_TYPE_DDR       0x1
#define MEMBANK_TYPE_SRAM      0x2
#define MEMBANK_TYPE_SPEC      0x3

#define MEMBANK_LAST           0x0
#define MEMBANK_NOT_LAST       0x8

 // field data
#define MEMBANK_INVALID        0x0  // bank state bit[0]
#define MEMBANK_VALID          0x1  // bank state bit[0]
#define MEMBANK_DDR            0x2  // bank state bit[2:1]
#define MEMBANK_SRAM           0x4  // bank state bit[2:1]
#define MEMBANK_SPECIAL        0x6  // bank state bit[2:1]
#define MEMBANK_NOT_LAST       0x8  // bank state bit[3]

//-----------------------------------------------------------------------------








#endif // _SMC_H
