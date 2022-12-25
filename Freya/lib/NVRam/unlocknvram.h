#pragma once

int unlocknvram(void);
int locknvram(void);
kptr_t IOMalloc(vm_size_t size);
void IOFree(kptr_t address, vm_size_t size);

void util_debug(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_info(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_warning(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_error(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_printf(const char * _Nullable fmt, ...) __printflike(1, 2);
