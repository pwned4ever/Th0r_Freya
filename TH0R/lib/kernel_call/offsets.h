#ifndef offsets_h
#define offsets_h

// proc_t
extern unsigned off_p_pid; // 0x60
extern unsigned off_task; // 0x10
extern unsigned off_p_uid; // 0x28
extern unsigned off_p_gid; // 0x2C
extern unsigned off_p_ruid; // 0x30
extern unsigned off_p_rgid; // 0x34
extern unsigned off_p_ucred; // 0xF8
extern unsigned off_p_csflags; // 0x290
extern unsigned off_p_comm; // 0x250
extern unsigned off_p_textvp; // 0x230
extern unsigned off_p_textoff; // 0x238
extern unsigned off_p_cputype; // 0x2A8
extern unsigned off_p_cpu_subtype; // 0x2AC

// task_t
extern unsigned off_itk_self; // 0xD8
extern unsigned off_itk_sself; // 0xE8
extern unsigned off_itk_bootstrap; // 0x2B8
extern unsigned off_itk_space; // 0x300

// ipc_port_t
extern unsigned off_ip_mscount; // 0x9C
extern unsigned off_ip_srights; // 0xA0
extern unsigned off_ip_kobject; // 0x68

// ucred
extern unsigned off_ucred_cr_uid; // 0x18
extern unsigned off_ucred_cr_ruid; // 0x1c
extern unsigned off_ucred_cr_svuid; // 0x20
extern unsigned off_ucred_cr_ngroups; // 0x24
extern unsigned off_ucred_cr_groups; // 0x28
extern unsigned off_ucred_cr_rgid; // 0x68
extern unsigned off_ucred_cr_svgid; // 0x6c
extern unsigned off_ucred_cr_label; // 0x78

// vnode
extern unsigned off_v_type; // 0x70
extern unsigned off_v_id; // 0x74
extern unsigned off_v_ubcinfo; // 0x78
extern unsigned off_v_flags; // 0x54
extern unsigned off_v_mount; // 0xD8; // vnode::v_mount
extern unsigned off_v_specinfo; // 0x78; // vnode::v_specinfo

// ubc_info
extern unsigned off_ubcinfo_csblobs; // 0x50; // ubc_info::csblobs

// cs_blob
extern unsigned off_csb_cputype; // 0x8
extern unsigned off_csb_flags; // 0x12
extern unsigned off_csb_base_offset; // 0x16
extern unsigned off_csb_entitlements_offset; // 0x90
extern unsigned off_csb_signer_type; // 0xA0
extern unsigned off_csb_platform_binary; // 0xA8
extern unsigned off_csb_platform_path; // 0xAC
extern unsigned off_csb_cd; // 0x80

// task
extern unsigned off_t_flags; // 0x3A0

// mount
extern unsigned off_specflags; // 0x10
extern unsigned off_mnt_flag; // 0x70
extern unsigned off_mnt_data; // 0x8F8


extern unsigned off_special; // 2 * sizeof(long)
extern unsigned off_ipc_space_is_table; // 0x20

extern unsigned off_amfi_slot; // 0x8
extern unsigned off_sandbox_slot; // 0x10

#define CS_VALID 0x0000001 /* dynamically valid */
#define CS_ADHOC 0x0000002 /* ad hoc signed */
#define CS_GET_TASK_ALLOW 0x0000004 /* has get-task-allow entitlement */
#define CS_INSTALLER 0x0000008 /* has installer entitlement */

#define CS_HARD 0x0000100 /* don't load invalid pages */
#define CS_KILL 0x0000200 /* kill process if it becomes invalid */
#define CS_CHECK_EXPIRATION 0x0000400 /* force expiration checking */
#define CS_RESTRICT 0x0000800 /* tell dyld to treat restricted */
#define CS_ENFORCEMENT 0x0001000 /* require enforcement */
#define CS_REQUIRE_LV 0x0002000 /* require library validation */
#define CS_ENTITLEMENTS_VALIDATED 0x0004000

#define CS_ALLOWED_MACHO 0x00ffffe

#define CS_EXEC_SET_HARD 0x0100000 /* set CS_HARD on any exec'ed process */
#define CS_EXEC_SET_KILL 0x0200000 /* set CS_KILL on any exec'ed process */
#define CS_EXEC_SET_ENFORCEMENT 0x0400000 /* set CS_ENFORCEMENT on any exec'ed process */
#define CS_EXEC_SET_INSTALLER 0x0800000 /* set CS_INSTALLER on any exec'ed process */

#define CS_KILLED 0x1000000 /* was killed by kernel for invalidity */
#define CS_DYLD_PLATFORM 0x2000000 /* dyld used to load this is a platform binary */
#define CS_PLATFORM_BINARY 0x4000000 /* this is a platform binary */
#define CS_PLATFORM_PATH 0x8000000 /* platform binary by the fact of path (osx only) */

#define CS_DEBUGGED 0x10000000 /* process is currently or has previously been debugged and allowed to run with invalid pages */
#define CS_SIGNED 0x20000000 /* process has a signature (may have gone invalid) */
#define CS_DEV_CODE 0x40000000 /* code is dev signed, cannot be loaded into prod signed code (will go away with rdar://problem/28322552) */

_Bool offs_init(void);

#endif
