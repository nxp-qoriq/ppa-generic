 //Function IDs
.equ cpu_on_id, 0xc4000003
.equ cpu_off_id, 0x84000002
.equ affinity_info_id, 0xc4000004

 //CPU affinities
.equ mpidr_cpu0, 0x0
.equ mpidr_cpu1, 0x1
.equ mpidr_cpu2, 0x2
.equ mpidr_cpu3, 0x3

 //Context IDs
.equ contextID_cpu1, 0x1111
.equ contextID_cpu2, 0x2222
.equ contextID_cpu3, 0x3333

 //Bit Masks
.equ icm_mask, 0x1005
.equ interrupt_mask, 0x3c0
.equ endian_mask, 0x02000000

#include "soc.h"

 //Assuming this code is running on core 0 and that all other cores are powered off
 //x0 is function ID for CPU_ON
 //X1 is affinities of target processor, as described in MPIDR_EL!
 //x2 is entry point address for when target core starts processing
 //x3 is context ID, this isn't currently relevant
cpu_on_test:
     //Turn on core 1
    ldr x0, =cpu_on_id
    ldr x1, =mpidr_cpu1
    adr x2, core1_start
    ldr x3, =contextID_cpu1
    smc 0x0
    cbnz x0, cpu1_on_failure

     //Attempt to turn on core 1 again
     //This should return ON_PENDING (-5)
    ldr x0, =cpu_on_id
    ldr x1, =mpidr_cpu1
    adr x2, core1_start
    ldr x3, =contextID_cpu1
    smc 0x0

    cmp x0, #-5
    b.ne not_on_pending

     //Test invalid cluster #
     //This should return INVALID_PARAMETERS (-2)
    ldr x0, =cpu_on_id
    mov x1, #CLUSTER_COUNT
    lsl x1, x1, #8
    adr x2, core1_start
    ldr x3, =contextID_cpu1
    smc 0x0
    cmp x0, #-2
    b.ne not_invalid_cluster

     //Test invalid cpu #
     //This should return INVALID_PARAMETERS (-2)
    ldr x0, =cpu_on_id
    mov x1, #CPU_PER_CLUSTER
    adr x2, core1_start
    ldr x3, =contextID_cpu1
    smc 0x0
    cmp x0, #-2
    b.ne not_invalid_cpu

     //Test invalid cpu and cluster #
     //This should return INVALID_PARAMETERS (-2)
    ldr x0, =cpu_on_id
    mov x1, #CLUSTER_COUNT
    lsl x1, x1, #8
    orr x1, x1, #CPU_PER_CLUSTER
    adr x2, core1_start
    ldr x3, =contextID_cpu1
    smc 0x0
    cmp x0, #-2
    b.ne not_invalid_cpu_and_cluster

     //Change to Big Endian to check if other powered cores start in big endian
    mrs x0, sctlr_el2
    orr x0, x0, #endian_mask
    msr sctlr_el2, x0

     //Test for unaligned start address
    ldr x0, =cpu_on_id
    ldr x1, =mpidr_cpu2
    adr x2, core2_start
    add x2, x2, #1
    ldr x3, =contextID_cpu2
    smc 0x0
    cmp x0, #-2
    b.ne not_unaligned_address

     //Test for illegal start address
    ldr x0, =cpu_on_id
    ldr x1, mpidr_cpu2
    mov x2, #0
    ldr x3, =contextID_cpu2
    smc 0x0
    cmp x0, #-2
    b.ne not_illegal_address

     //Turn on core 2
    ldr x0, =cpu_on_id
    ldr x1, =mpidr_cpu2
    adr x2, core2_start
    ldr x3, =contextID_cpu2
    smc 0x0
    cbnz x0, cpu2_on_failure

 //This loop has core 0 constantly turning core 1 back on
core0_start:
	ldr x0, =affinity_info_id
	ldr x1, =mpidr_cpu1,
	mov x2, #0
	smc 0x0
    cmp x0, #1
    b.ne core0_start

    ldr x0, =cpu_on_id
    ldr x1, =mpidr_cpu1
    adr x2, core1_start
    ldr x3, =contextID_cpu1
    smc 0x0
    cbnz x0, cpu1_on_failure
    
    b core0_start

 //Code for core 1 to execute
core1_start:
	 //Test contextID
	ldr x1, =contextID_cpu1
	cmp x0, x1
	b.ne contextID_not_received

	 //Test MMU and cache enable bits (should be disabled)
	mrs x0, sctlr_el2
	tst x0, #icm_mask
	b.ne icm_bits_set

     //Test if core 1 is Little Endian
    tst x0, #endian_mask
    b.ne wrong_endianness

	 //Test Interrupt mask bits
	mrs x0, daif
	cmp x0, #interrupt_mask
	b.ne unmasked_interrupts

     //Check stack pointer
    mrs x0, spsel
    cbz x0, wrong_stack_pointer

	 //Turn core 1 off
	ldr x0, =cpu_off_id
	smc 0x0
	b off_denied

 //Code for core 2 to execute
core2_start:
	 //Test contextID
	ldr x1, =contextID_cpu2
	cmp x0, x1
	b.ne contextID_not_received

	 //Test MMU and cache enable bits (should be disabled)
	mrs x0, sctlr_el2
	tst x0, #icm_mask
	b.ne icm_bits_set

	 //Test if core 2 has been set to Big Endiann
	tst x0, #endian_mask
	b.eq wrong_endianness

	 //Test Interrupt mask bits
	mrs x0, daif
	cmp x0, #interrupt_mask
	b.ne unmasked_interrupts

     //Check stack pointer
    mrs x0, spsel
    cbz x0, wrong_stack_pointer

     //Turn on core 3
    ldr x0, =cpu_on_id
    ldr x1, =mpidr_cpu3
    adr x2, core3_start
    ldr x3, =contextID_cpu3
    smc 0x0
    cbnz x0, cpu3_on_failure

 //Loop indefinitely
core2_loop:
    b core2_loop


 //Code for core 3 to execute
core3_start:
	 //Test contextID
	ldr x1, =contextID_cpu3
	cmp x0, x1
	b.ne contextID_not_received

	 //Test MMU and cache enable bits (should be disabled)
	mrs x0, sctlr_el2
	tst x0, #icm_mask
	b.ne icm_bits_set

	 //Test if core 2 has been set to Big Endiann
	tst x0, #endian_mask
	b.eq wrong_endianness

	 //Test Interrupt mask bits
	mrs x0, daif
	cmp x0, #interrupt_mask
	b.ne unmasked_interrupts

     //Check stack pointer
    mrs x0, spsel
    cbz x0, wrong_stack_pointer

 //indefinitely attempt to turn core 3 on
core3_loop:
	 //This should return ALREADY_ON (-4)
    ldr x0, =cpu_on_id
    ldr x1, =mpidr_cpu3
    adr x2, core3_start
    ldr x3, =contextID_cpu3
    smc 0x0

    cmp x0, #-4
    b.eq core3_loop

 //CPU_ON did not return ALREADY_ON
not_already_on:
    b not_already_on

 //CPU_ON did not return ON_PENDING
not_on_pending:
    b not_on_pending

 //CPU_ON did not return INVALID_PARAMETERS after passing invalid cluster
not_invalid_cluster:
    b not_invalid_cluster

 //CPU_ON did not return INVALID_PARAMETERS after passing invalid core
not_invalid_cpu:
    b not_invalid_cpu

 //CPU_ON did not return INVALID_PARAMETERS after passing invalid cluster and core
not_invalid_cpu_and_cluster:
    b not_invalid_cpu_and_cluster

 //CPU_ON did not return INVALID_PARAMETERS after passing unaligned address
not_unaligned_address:
    b not_unaligned_address

 //CPU_ON did not return INVALID_PARAMETERS after passing invalid address
not_illegal_address:
    b not_illegal_address

 //CPU_OFF failed to power off a core
off_denied:
	b off_denied

 //The contextID was not properly passed to the powered on core
contextID_not_received
	b contextID_not_received

 //The powered on core did not start with the correct endianness
wrong_endianness:
	b wrong_endianness

 //The powered on core did not start with all interrupts masked
unmasked_interrupts:
	b unmasked_interrupts

 //The powered core did not start up with the MMU and caches disabled
icm_bits_set:
	b icm_bits_set

 //The core is using sp_el0 as its stack pointer
wrong_stack_pointer:
    b wrong_stack_pointer

 //Core 1 did not start up as expected
cpu1_on_failure:
	b cpu1_on_failure

 //Core 2 did not start up as expected
cpu2_on_failure:
    b cpu2_on_failure

 //Core 3 did not start up as expected
cpu3_on_failure:
    b cpu3_on_failure