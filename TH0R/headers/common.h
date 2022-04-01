#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>             // uint*_t
#include <stdbool.h>
#include <mach-o/loader.h>
#ifdef __OBJC__
#include <Foundation/Foundation.h>
#define LOG(str, args...) do { NSLog(@"[*] " str "\n", ##args); } while(false)
#else
#include <CoreFoundation/CoreFoundation.h>
extern void NSLog(CFStringRef, ...);
#define LOG(str, args...) do { NSLog(CFSTR("[*] " str "\n"), ##args); } while(false)
#endif
#define ADDR                 "0x%016llx"


typedef uint64_t kptr_t;
#define KPTR_NULL ((kptr_t) 0)
#define KERN_POINTER_VALID(val) ((val) >= 0xffff000000000000 && (val) != 0xffffffffffffffff)

#endif
