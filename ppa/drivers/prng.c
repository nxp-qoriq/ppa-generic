//
// Copyright (C) 2017 NXP Semiconductors, Inc. All rights reserved.
//
//-----------------------------------------------------------------------------

unsigned long long 
_get_PRNG(
    int  prngWidth
    )
{

    unsigned long long  result = 0;

    if (0 == prngWidth) {
         // return a 32-bit prng
        result = 0x12345678;
    }
    else {
         // return a 64-bit prng
        result = 0x0123456789ABCDEF;
    }

    return (result);

}  // _get_PRNG()

//-----------------------------------------------------------------------------

