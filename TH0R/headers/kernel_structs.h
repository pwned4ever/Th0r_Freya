//
//  kernel_structs.h
//  Thanks pwn
//  Undecimus
//
//  Created by Pwn20wnd on 4/8/19.
//  Copyright © 2019 Pwn20wnd. All rights reserved.
//

#ifndef kernel_structs_h
#define kernel_structs_h

#include <sys/mount.h>
#include <stdio.h>

struct tqe_struct {
    uint64_t tqe_next;
    uint64_t tqe_prev;
};
struct tqh_struct {
    uint64_t tqh_first;
    uint64_t tqh_last;
};

struct vnode_struct {
    uint64_t v_lock[2];
    struct tqe_struct v_freelist;
    struct tqe_struct v_mntvnodes;
    struct tqh_struct v_ncchildren;
    uint64_t v_nclinks;
    uint64_t v_defer_reclaimlist;
    uint32_t v_listflag;            /* flags protected by the vnode_list_lock (see below) */
    uint32_t v_flag;            /* vnode flags (see below) */
    uint16_t v_lflag;            /* vnode local and named ref flags */
    uint8_t     v_iterblkflags;        /* buf iterator flags */
    uint8_t     v_references;            /* number of times io_count has been granted */
    int32_t     v_kusecount;            /* count of in-kernel refs */
    int32_t     v_usecount;            /* reference count of users */
    int32_t     v_iocount;            /* iocounters */
    uint64_t   v_owner;            /* void * act that owns the vnode */
    uint16_t v_type;            /* vnode type */
    uint16_t v_tag;                /* type of underlying data */
    uint32_t v_id;                /* identity of vnode contents */
    union {
        struct mount    *vu_mountedhere;/* ptr to mounted vfs (VDIR) */
        struct socket    *vu_socket;    /* unix ipc (VSOCK) */
        struct specinfo    *vu_specinfo;    /* device (VCHR, VBLK) */
        struct fifoinfo    *vu_fifoinfo;    /* fifo (VFIFO) */
        struct ubc_info *vu_ubcinfo;    /* valid for (VREG) */
    } v_un;
    uint64_t v_cleanblkhd;        /* clean blocklist head */
    uint64_t v_dirtyblkhd;        /* dirty blocklist head */
    uint64_t v_knotes;            /* knotes attached to this vnode */
    /*
     * the following 4 fields are protected
     * by the name_cache_lock held in
     * excluive mode
     */
    uint64_t    v_cred;            /* last authorized credential */
    uint64_t    v_authorized_actions;    /* current authorized actions for v_cred */
    int        v_cred_timestamp;    /* determine if entry is stale for MNTK_AUTH_OPAQUE */
    int        v_nc_generation;    /* changes when nodes are removed from the name cache */
    /*
     * back to the vnode lock for protection
     */
    int32_t        v_numoutput;            /* num of writes in progress */
    int32_t        v_writecount;            /* reference count of writers */
    const char *v_name;            /* name component of the vnode */
    uint64_t v_parent;            /* pointer to parent vnode */
    struct lockf *v_lockf;        /* advisory lock list head */
    int     (**v_op)(void *);        /* vnode operations vector */
    mount_t v_mount;            /* ptr to vfs we are in */
    void *    v_data;                /* private data for fs */
} ;

#endif /* kernel_structs_h */
