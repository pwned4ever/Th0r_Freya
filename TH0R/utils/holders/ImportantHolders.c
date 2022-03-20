//
//  VarHolder.c
//  Ziyou
//
//  Created by Tanay Findley on 4/7/19.
//  Copyright © 2019 Tanay Findley. All rights reserved.
//
#include <mach/port.h>

mach_port_t tfp0 = MACH_PORT_NULL;
uint64_t kbase;
uint64_t ktask;
uint A12 = 0;
uint64_t task_self_addr_cache;
uint64_t selfproc_ffs = 0;

uint64_t get_selfproc()
{
    return selfproc_ffs;
}

void set_selfproc(uint64_t proc)
{
    selfproc_ffs = proc;
}


void set_task_self_addr(uint64_t tsa)
{
    task_self_addr_cache = tsa;
}

void setA12(uint a12)
{
    A12 = a12;
}

void set_tfp0(mach_port_t tfp0wo)
{
    tfp0 = tfp0wo;
}
