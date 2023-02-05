//
//  FreyaRemove.h
//  Freya
//
//  Created by Marcel C on 2023-01-20.
//  Copyright © 2023 Th0r Team. All rights reserved.
//

#ifndef FreyaRemove_h
#define FreyaRemove_h

#import <sys/types.h>
#import <sys/stat.h>
#include <stdio.h>
#include <stdbool.h>

#include <stddef.h>
#include <stdint.h>
#include <sys/time.h>

#define showMSG(msg, wait, destructive) showAlert(@"freya", msg, wait, destructive)
#define showPopup(msg, wait, destructive) showThePopup(@"", msg, wait, destructive)
#define __FILENAME__ (__builtin_strrchr(__FILE__, '/') ? __builtin_strrchr(__FILE__, '/') + 1 : __FILE__)
#define _assert(test, message, fatal) do \
if (!(test)) { \
int saved_errno = errno; \
LOG("__assert(%d:%s)@%s:%u[%s]", saved_errno, #test, __FILENAME__, __LINE__, __FUNCTION__); \
} \
while (false)
void removingFreyaiOS(void);
void util_hexprint(void *data, size_t len, const char *desc);
void util_hexprint_width(void *data, size_t len, int width, const char *desc);
void util_nanosleep(uint64_t nanosecs);
void util_msleep(unsigned int ms);
_Noreturn void fail_info(const char *info);
void fail_if(bool cond, const char *fmt, ...)  __printflike(2, 3);
//void move_in_jbResources();
// don't like macro
void util_debug(const char *fmt, ...) __printflike(1, 2);
void util_info(const char *fmt, ...) __printflike(1, 2);
void util_warning(const char *fmt, ...) __printflike(1, 2);
void util_error(const char *fmt, ...) __printflike(1, 2);
void util_printf(const char *fmt, ...) __printflike(1, 2);

#endif /* FreyaRemove_h */
