#pragma once

int unlocknvram(void);
int locknvram(void);
kptr_t IOMalloc(vm_size_t size);
void IOFree(kptr_t address, vm_size_t size);
