#include <inttypes.h>
#include <mach/mach.h>
#include <stdbool.h>

bool init_kexecute(void);
void term_kexecute(void);
uint64_t kexecute2(uint64_t addr, uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3, uint64_t x4, uint64_t x5, uint64_t x6);
void util_debug(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_info(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_warning(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_error(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_printf(const char * _Nullable fmt, ...) __printflike(1, 2);
