#import <UIKit/UIDevice.h>
#import "offsets.h"
#import "log.h"

#define SYSTEM_VERSION_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define SYSTEM_VERSION_BETWEEN_OR_EQUAL_TO(a, b) (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(a) && SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(b))

// proc_t
unsigned off_p_pid = 0x60;
unsigned off_task = 0x10;
unsigned off_p_uid = 0x28;
unsigned off_p_gid = 0x2C;
unsigned off_p_ruid = 0x30;
unsigned off_p_rgid = 0x34;
unsigned off_p_ucred = 0xF8;
unsigned off_p_csflags = 0x290;
unsigned off_p_comm = 0x250;
unsigned off_p_textvp = 0x230;
unsigned off_p_textoff = 0x238;
unsigned off_p_cputype = 0x2A8;
unsigned off_p_cpu_subtype = 0x2AC;

// task_t
unsigned off_itk_self = 0xD8;
unsigned off_itk_sself = 0xE8;
unsigned off_itk_bootstrap = 0x2B8;
unsigned off_itk_space = 0x300;

// ipc_port_t
unsigned off_ip_mscount = 0x9C;
unsigned off_ip_srights = 0xA0;
unsigned off_ip_kobject = 0x68;

// ucred
unsigned off_ucred_cr_uid = 0x18;
unsigned off_ucred_cr_ruid = 0x1c;
unsigned off_ucred_cr_svuid = 0x20;
unsigned off_ucred_cr_ngroups = 0x24;
unsigned off_ucred_cr_groups = 0x28;
unsigned off_ucred_cr_rgid = 0x68;
unsigned off_ucred_cr_svgid = 0x6c;
unsigned off_ucred_cr_label = 0x78;

// vnode
unsigned off_v_type = 0x70;
unsigned off_v_id = 0x74;
unsigned off_v_ubcinfo = 0x78;
unsigned off_v_flags = 0x54;
unsigned off_v_mount = 0xD8; // vnode::v_mount
unsigned off_v_specinfo = 0x78; // vnode::v_specinfo
unsigned off_v_name = 0xb8;
unsigned off_v_parent = 0xc0;



// ubc_info
unsigned off_ubcinfo_csblobs = 0x50; // ubc_info::csblobs

// cs_blob
unsigned off_csb_cputype = 0x8;
unsigned off_csb_flags = 0x12;
unsigned off_csb_base_offset = 0x16;
unsigned off_csb_entitlements_offset = 0x90;
unsigned off_csb_signer_type = 0xA0;
unsigned off_csb_platform_binary = 0xA8;
unsigned off_csb_platform_path = 0xAC;
unsigned off_csb_cd = 0x80;

// task
unsigned off_t_flags = 0x3A0;

// mount
unsigned off_mnt_devvp = 0x980;
unsigned off_mnt_next = 0x0;
unsigned off_mnt_vnodelist = 0x40;
unsigned off_specflags = 0x10;
unsigned off_mnt_flag = 0x70;
unsigned off_mnt_data = 0x8F8;
//apfs
unsigned off_apfs_data_flag = 0x31;

unsigned off_special = 2 * sizeof(long);
unsigned off_ipc_space_is_table = 0x20;

unsigned off_amfi_slot = 0x8;
unsigned off_sandbox_slot = 0x10;

_Bool offs_init() {
    if (SYSTEM_VERSION_BETWEEN_OR_EQUAL_TO(@"11.0", @"12.0") && !SYSTEM_VERSION_EQUAL_TO(@"12.0")) {
        off_p_pid = 0x10;
        off_task = 0x18;
        off_p_uid = 0x30;
        off_p_gid = 0x34;
        off_p_ruid = 0x38;
        off_p_rgid = 0x3C;
        off_p_ucred = 0x100;
        off_p_csflags = 0x2A8;
        off_p_comm = 0x268;
        off_p_textvp = 0x248;
        off_p_textoff = 0x250;
        off_p_cputype = 0x2C0;
        off_p_cpu_subtype = 0x2C4;
        off_itk_space = 0x308;
        off_csb_platform_binary = 0xA4;
        off_csb_platform_path = 0xA8;
    } else if (SYSTEM_VERSION_BETWEEN_OR_EQUAL_TO(@"12.0", @"13.0") && !SYSTEM_VERSION_EQUAL_TO(@"13.0")) {
        off_p_pid = 0x60;
        off_task = 0x10;
        off_p_uid = 0x28;
        off_p_gid = 0x2C;
        off_p_ruid = 0x30;
        off_p_rgid = 0x34;
        off_p_ucred = 0xF8;
        off_p_csflags = 0x290;
        off_p_comm = 0x250;
        off_p_textvp = 0x230;
        off_p_textoff = 0x238;
        off_p_cputype = 0x2A8;
        off_p_cpu_subtype = 0x2AC;
        off_itk_space = 0x300;
        off_csb_platform_binary = 0xA8;
        off_csb_platform_path = 0xAC;
    } else {
        ERROR("iOS version unsupported.");
        return false;
    }
    return true;
}
