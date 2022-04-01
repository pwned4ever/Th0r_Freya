//
//  shenanigans.h
//  Ziyou
//
//  Created by Tanay Findley on 7/12/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

#ifndef shenanigans_h
#define shenanigans_h

#include <stdio.h>
#include "common.h"

void runShenPatch(void);
kptr_t get_kernel_cred_addr(void);
uint64_t give_creds_to_process_at_addr(uint64_t proc, uint64_t cred_addr);
kptr_t get_kernel_proc_struct_addr(void);
//kptr_t get_proc_struct_for_pid(pid_t pid);
#endif /* shenanigans_h */
