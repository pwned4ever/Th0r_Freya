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
extern unsigned off_v_name;
extern unsigned off_v_parent;
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
extern unsigned off_mnt_devvp;
extern unsigned off_mnt_next;
extern unsigned off_mnt_vnodelist;
extern unsigned off_specflags; // 0x10
extern unsigned off_mnt_flag; // 0x70
extern unsigned off_mnt_data; // 0x8F8
extern unsigned off_apfs_data_flag;


extern unsigned off_special; // 2 * sizeof(long)
extern unsigned off_ipc_space_is_table; // 0x20

extern unsigned off_amfi_slot; // 0x8
extern unsigned off_sandbox_slot; // 0x10


_Bool offs_init(void);

#endif
