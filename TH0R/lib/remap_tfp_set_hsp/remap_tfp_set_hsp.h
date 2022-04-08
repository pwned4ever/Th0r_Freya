//
//  remap_tfp_set_hsp.h
//  Ziyou
//
//  Created by Tanay Findley on 4/9/19.
//  Copyright © 2019 Tanay Findley. All rights reserved.
//

#ifndef remap_tfp_set_hsp_h
#define remap_tfp_set_hsp_h


#define __FILENAME__ (__builtin_strrchr(__FILE__, '/') ? __builtin_strrchr(__FILE__, '/') + 1 : __FILE__)
#define _assert(test, message, fatal) do \
if (!(test)) { \
int saved_errno = errno; \
LOG("__assert(%d:%s)@%s:%u[%s]", saved_errno, #test, __FILENAME__, __LINE__, __FUNCTION__); \
} \
while (false)

#include <stdio.h>

void util_debug(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_info(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_warning(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_error(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_printf(const char * _Nullable fmt, ...) __printflike(1, 2);

extern int F_OFFS;
uint64_t get_address_of_port(pid_t pid, mach_port_t port);
int setHSP4(void);
uint64_t get_proc_struct_for_pid(pid_t pid);
#endif /* remap_tfp_set_hsp_h */
