//
//  PFOffs.h
//  Ziyou
//
//  Created by Tanay Findley on 4/9/19.
//  Copyright © 2019 Tanay Findley. All rights reserved.
//

#ifndef PFOffs_h
#define PFOffs_h

#include <stdio.h>
#include "common.h"

#define ISADDR(val) ((val) >= 0xffff000000000000 && (val) != 0xffffffffffffffff)
#define SETOFFSET(offset, val) (offs.offset = val)
#define GETOFFSET(offset) offs.offset

typedef struct {
    kptr_t zone_map_ref;
    kptr_t kernel_task;
    kptr_t vnode_put;
    kptr_t vfs_context_current;
    kptr_t vnode_lookup;
    kptr_t add_x0_x0_0x40_ret;
    kptr_t fs_lookup_snapshot_metadata_by_name_and_return_name;
    kptr_t apfs_jhash_getvnode;
    kptr_t vnode_get_snapshot;
    kptr_t shenanigans;
    kptr_t trustcache;
    kptr_t pmap_load_trust_cache;
    kptr_t kernel_task_offset_all_image_info_addr;
    kptr_t lck_mtx_lock;
    kptr_t lck_mtx_unlock;
    
    kptr_t paciza_pointer__l2tp_domain_module_start;
    kptr_t paciza_pointer__l2tp_domain_module_stop;
    
    kptr_t l2tp_domain_inited;
    kptr_t sysctl__net_ppp_l2tp;
    kptr_t sysctl_unregister_oid;
    kptr_t mov_x0_x4__br_x5;
    kptr_t mov_x9_x0__br_x1;
    kptr_t mov_x10_x3__br_x6;
    kptr_t kernel_forge_pacia_gadget;
    kptr_t kernel_forge_pacda_gadget;
    kptr_t IOUserClient__vtable;
    kptr_t IORegistryEntry__getRegistryEntryID;
    kptr_t OSBoolean_True;
    kptr_t osunserializexml;
    kptr_t smalloc;
    
    kptr_t allproc;
    kptr_t strlen;
    
    kptr_t kfree;
    
    kptr_t cs_blob_generation_count;
    kptr_t ubc_cs_blob_allocate_site;
    kptr_t cs_validate_csblob;
    kptr_t cs_find_md;
    
    kptr_t kalloc_canblock;
    
    kptr_t proc_rele;
    
    kptr_t IOMalloc;
    kptr_t IOFree;
} pf_offsets_t;

extern pf_offsets_t offs;

extern int (*pmap_load_trust_cache)(uint64_t kernel_trust, size_t length);
int _pmap_load_trust_cache(uint64_t kernel_trust, size_t length);

#endif /* PFOffs_h */
