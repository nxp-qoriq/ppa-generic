// 
// ARM v8 utility functions
//
// Copyright (c) 2013-2016 Freescale Semiconductor, Inc. All rights reserved.
//
//-----------------------------------------------------------------------------

  .section .text, "ax"

//-----------------------------------------------------------------------------

#include "aarch64.h"
#include "psci.h"

//-----------------------------------------------------------------------------

.global _get_core_mask_lsb
.global _get_cluster_state
.global _core_on_cnt_clstr
.global _is_mpidr_valid

//-----------------------------------------------------------------------------
 // This function returns the bit mask corresponding to the mpidr_el1 value.
 // the mask is returned in w0.
 // this bit mask references the core in SoC registers such as
 // BRR, COREDISABLEDSR where the LSB represents core0
 //
#if (SYMMETRICAL_CLUSTERS)
 // This algorithm assumes that all clusters are symmetrical, that
 // each cluster contains the same number of cores. If that is true for
 // this SoC, then this function is appropriate.
 //
 // in:   x0  - mpidr_el1 value for the core
 // out:  w0  = core mask (non-zero)
 //       w0  = 0 for error (bad input mpidr value)
 // uses x0, x1, x2
_get_core_mask_lsb:
     //
     // generate a lsb-based mask for the core
     // SoC core = ((cluster * cpu_per_cluster) + core)
     // mask = (1 << SoC core)
    mov   w1, wzr
    mov   w2, wzr
    bfxil w1, w0, #8, #8  // extract cluster
    bfxil w2, w0, #0, #8  // extract cpu #

    mov   w0, wzr

     // error checking
    cmp   w1, #CLUSTER_COUNT
    b.ge  1f
    cmp   w2, #CPU_PER_CLUSTER
    b.ge  1f

    mov   w0, #CPU_PER_CLUSTER
    mul   w1, w1, w0
    add   w1, w1, w2
    mov   w2, #0x1
    lsl   w0, w2, w1
1:
    ret
#else
     // if the clusters are not symmetrical, then add an appropriate
     // function in the specific device soc.s file.
#endif

//-----------------------------------------------------------------------------

 // this function returns the state of a cluster

#if (SYMMETRICAL_CLUSTERS)
 // in:  x0 = 0-based cluster number
 // out: x0 = AFFINITY_LEVEL_ON (at least one core of the cluster is ON)
 //      x0 = AFFINITY_LEVEL_OFF (all cores of the cluster are [OFF | DISABLED | RESET])
 //      x0 = AFFINITY_LEVEL_PEND (at least one core is ON_PENDING and no cores are ON)
 // uses: x0, x1, x2, x3, x4, x5, x6
_get_cluster_state:
     // save link register
    mov   x6, x30

    mov   x3, #CPU_PER_CLUSTER
    mov   x4, #AFFINITY_LEVEL_OFF
    orr   x5, xzr, x0, LSL #8

     // x3 = loop count
     // x4 = cluster state
     // x5 = mpidr of core
3:
    mov   x0, x5
    bl    _get_core_mask_lsb

     // x0 = core mask lsb

    mov   x1, #CORE_STATE_DATA
    bl    _getCoreData

     // x0 = core state

    mov   x1, #CORE_RELEASED
    cmp   x0, x1
    b.eq  1f

    mov   x1, #CORE_PENDING

    b.ne  4f
    mov   x4, #AFFINITY_LEVEL_PEND
4:
     // increment to next core
    add   x5, x5, #1
     // decrement loop counter
    sub   x3, x3, #1
     // exit if done
    cbz   x3, 2f
    b     3b

1:
    mov   x4, #AFFINITY_LEVEL_ON
2:
    mov   x0, x4
    mov   x30, x6
    ret

#else
     // if the clusters are not symmetrical, then add an appropriate
     // function in the specific device soc.s file.
#endif

//-----------------------------------------------------------------------------

 // this function returns the number of active cores in the given cluster

#if (SYMMETRICAL_CLUSTERS)
 // in:  x0 = cluster number (mpidr format)
 // out: x0 = count of cores running
 // uses x0, x1, x2, x3, x4, x5, x6
_core_on_cnt_clstr:
    mov  x6, x30

    and  x4, x0, #MPIDR_CLUSTER_MASK
    mov  x3, #CPU_PER_CLUSTER
    mov  x5, xzr

     // x3 = loop count
     // x4 = core mpidr
     // x5 = accumulated count of running cores
     // x6 = saved link reg

3:
    mov  x0, x4
    bl   _get_core_mask_lsb

     // x0 = core mask lsb

    mov  x1, #CORE_STATE_DATA
    bl   _getCoreData

     // x0 = core state

    cmp  x0, #CORE_OFF_MAX
    b.le 1f
    add  x5, x5, #1
1:
     // decrement the loop count and exit if finished
    sub  x3, x3, #1
    cbz  x3, 2f

     // increment to the next core
    add  x4, x4, #1
    b    3b

2:
     // xfer the count to the output reg
    mov  x0, x5
    mov  x30, x6
    ret

#else
     // if the clusters are not symmetrical, then add an appropriate
     // function in the specific device soc.s file.
#endif

//-----------------------------------------------------------------------------

 // this function determines if a given mpidr value is valid for this SoC

#if (SYMMETRICAL_CLUSTERS)
 // in:  x0 = mpidr[15:0]
 // out: x0 == 0, mpidr not valid
 //      x0 != 0, mpidr is valid
 // uses x0, x1, x2
_is_mpidr_valid:

     // compare the 0-based affinity 1 field (cluster #) with the number
     // of clusters in this SoC
    and  x1, x0, #MPIDR_AFFINITY1_MASK
    lsr  x1, x1, #MPIDR_AFFINITY1_OFFSET
     // compare to the cluster count of this SoC
    ldr  x2, =CLUSTER_COUNT
    cmp  x2, x1
    b.le 2f

     // compare the 0-based affinity 0 field (core number) with the
     // number of cores per cluster in this SoC
    and  x1, x0, #MPIDR_AFFINITY0_MASK
    mov  x2, #CPU_PER_CLUSTER
    cmp  x2, x1
    b.le 2f

1:
     // the mpidr is valid
    mov  x0, #1
    b    3f
2:
     // the mpidr is not valid
    mov  x0, #0
3:
    ret

#else
     // if the clusters are not symmetrical, then add an appropriate
     // function in the specific device soc.s file.
#endif

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

