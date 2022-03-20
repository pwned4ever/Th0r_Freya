//
//  bypass.c
//  Ziyou
//
//  Created by Tanay Findley on 5/19/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

#include "bypass.h"
#include "common.h"
#include "cs_blob.h"
#include "offsets.h"
#include "PFOffs.h"
#include "OffsetHolder.h"
#include "OSObj.h"
#include "kernel_exec.h"
#include "vnode_utils.h"
#include "utilsZS.h"
#include <CommonCrypto/CommonDigest.h>
#include "amfi_utils.h"
#include <mach-o/fat.h>
#include "KernelUtils.h"

uint64_t ubc_cs_blob_allocate(vm_size_t size) {
    uint64_t size_p = kmem_alloc(sizeof(vm_size_t));
    if (!size_p) return 0;
    kwriteOwO(size_p, &size, sizeof(vm_size_t));
    uint64_t alloced = kexecute2(GETOFFSET(kalloc_canblock), size_p, 1, GETOFFSET(ubc_cs_blob_allocate_site), 0, 0, 0, 0);
    kmem_free(size_p, sizeof(vm_size_t));
    if (alloced) alloced = zm_fix_addr(alloced);
    return alloced;
}

void *load_bytes(FILE *file, off_t offset, size_t size) {
    void *buf = calloc(1, size);
    fseek(file, offset, SEEK_SET);
    fread(buf, size, 1, file);
    return buf;
}


uint64_t getCodeSignatureLC(FILE *file, int64_t *machOff) {
    size_t offset = 0;
    struct load_command *cmd = NULL;
    
    // Init at this
    *machOff = -1;
    
    uint32_t *magic = load_bytes(file, offset, sizeof(uint32_t));
    int ncmds = 0;
    
    // check magic
    if (*magic != 0xFEEDFACF && *magic != 0xBEBAFECA) {
        printf("[-] File is not an arm64 or FAT macho!\n");
        free(magic);
        return 0;
    }
    
    // FAT
    if(*magic == 0xBEBAFECA) {
        
        uint32_t arch_off = sizeof(struct fat_header);
        struct fat_header *fat = (struct fat_header*)load_bytes(file, 0, sizeof(struct fat_header));
        bool foundarm64 = false;
        
        int n = ntohl(fat->nfat_arch);
        printf("[*] Binary is FAT with %d architectures\n", n);
        
        while (n-- > 0) {
            struct fat_arch *arch = (struct fat_arch *)load_bytes(file, arch_off, sizeof(struct fat_arch));
            
            if (ntohl(arch->cputype) == 0x100000c) {
                printf("[*] Found arm64\n");
                offset = ntohl(arch->offset);
                foundarm64 = true;
                free(fat);
                free(arch);
                break;
            }
            free(arch);
            arch_off += sizeof(struct fat_arch);
        }
        
        if (!foundarm64) {
            printf("[-] Binary does not have any arm64 slice\n");
            free(fat);
            free(magic);
            return 0;
        }
    }
    
    free(magic);
    
    *machOff = offset;
    
    // get macho header
    struct mach_header_64 *mh64 = load_bytes(file, offset, sizeof(struct mach_header_64));
    ncmds = mh64->ncmds;
    free(mh64);
    
    // next
    offset += sizeof(struct mach_header_64);
    
    for (int i = 0; i < ncmds; i++) {
        cmd = load_bytes(file, offset, sizeof(struct load_command));
        
        // this!
        if (cmd->cmd == LC_CODE_SIGNATURE) {
            free(cmd);
            return offset;
        }
        
        // next
        offset += cmd->cmdsize;
        free(cmd);
    }
    
    return 0;
}

uint32_t swap_uint32( uint32_t val ) {
    val = ((val << 8) & 0xFF00FF00 ) | ((val >> 8) & 0xFF00FF );
    return (val << 16) | (val >> 16);
}

uint32_t read_magic(FILE* file, off_t offset) {
    uint32_t magic;
    fseek(file, offset, SEEK_SET);
    fread(&magic, sizeof(uint32_t), 1, file);
    return magic;
}

uint8_t *getCodeDirectory(const char* name) {
    
    FILE* fd = fopen(name, "r");
    
    uint32_t magic;
    fread(&magic, sizeof(magic), 1, fd);
    fseek(fd, 0, SEEK_SET);
    
    long off = 0, file_off = 0;
    int ncmds = 0;
    BOOL foundarm64 = false;
    
    if (magic == MH_MAGIC_64) { // 0xFEEDFACF
        struct mach_header_64 mh64;
        fread(&mh64, sizeof(mh64), 1, fd);
        off = sizeof(mh64);
        ncmds = mh64.ncmds;
    }
    else if (magic == MH_MAGIC) {
        printf("[-] %s is 32bit. What are you doing here?\n", name);
        fclose(fd);
        return NULL;
    }
    else if (magic == 0xBEBAFECA) { //FAT binary magic
        
        size_t header_size = sizeof(struct fat_header);
        size_t arch_size = sizeof(struct fat_arch);
        size_t arch_off = header_size;
        
        struct fat_header *fat = (struct fat_header*)load_bytes(fd, 0, header_size);
        struct fat_arch *arch = (struct fat_arch *)load_bytes(fd, arch_off, arch_size);
        
        int n = swap_uint32(fat->nfat_arch);
        printf("[*] Binary is FAT with %d architectures\n", n);
        
        while (n-- > 0) {
            magic = read_magic(fd, swap_uint32(arch->offset));
            
            if (magic == 0xFEEDFACF) {
                printf("[*] Found arm64\n");
                foundarm64 = true;
                struct mach_header_64* mh64 = (struct mach_header_64*)load_bytes(fd, swap_uint32(arch->offset), sizeof(struct mach_header_64));
                file_off = swap_uint32(arch->offset);
                off = swap_uint32(arch->offset) + sizeof(struct mach_header_64);
                ncmds = mh64->ncmds;
                break;
            }
            
            arch_off += arch_size;
            arch = load_bytes(fd, arch_off, arch_size);
        }
        
        if (!foundarm64) { // by the end of the day there's no arm64 found
            printf("[-] No arm64? RIP\n");
            fclose(fd);
            return NULL;
        }
    }
    else {
        printf("[-] %s is not a macho! (or has foreign endianness?) (magic: %x)\n", name, magic);
        fclose(fd);
        return NULL;
    }
    
    for (int i = 0; i < ncmds; i++) {
        struct load_command cmd;
        fseek(fd, off, SEEK_SET);
        fread(&cmd, sizeof(struct load_command), 1, fd);
        if (cmd.cmd == LC_CODE_SIGNATURE) {
            uint32_t off_cs;
            fread(&off_cs, sizeof(uint32_t), 1, fd);
            uint32_t size_cs;
            fread(&size_cs, sizeof(uint32_t), 1, fd);
            
            uint8_t *cd = malloc(size_cs);
            fseek(fd, off_cs + file_off, SEEK_SET);
            fread(cd, size_cs, 1, fd);
            fclose(fd);
            return cd;
        } else {
            off += cmd.cmdsize;
        }
    }
    fclose(fd);
    return NULL;
}


int cs_validate_csblob(const uint8_t *addr, size_t length, CS_CodeDirectory **rcd, CS_GenericBlob **rentitlements) {
    uint64_t rcdptr = kmem_alloc(8);
    uint64_t entptr = kmem_alloc(8);
    
    int ret = (int)kexecute2(GETOFFSET(cs_validate_csblob), (uint64_t)addr, length, rcdptr, entptr, 0, 0, 0);
    *rcd = (CS_CodeDirectory *)ReadKernel64(rcdptr);
    *rentitlements = (CS_GenericBlob *)ReadKernel64(entptr);
    
    kmem_free(rcdptr, 8);
    kmem_free(entptr, 8);
    
    return ret;
}

void getSHA256inplace(const uint8_t* code_dir, uint8_t *out) {
    if (code_dir == NULL) {
        printf("NULL passed to getSHA256inplace!\n");
        return;
    }
    uint32_t* code_dir_int = (uint32_t*)code_dir;
    
    uint32_t realsize = 0;
    for (int j = 0; j < 10; j++) {
        if (swap_uint32(code_dir_int[j]) == 0xfade0c02) {
            realsize = swap_uint32(code_dir_int[j+1]);
            code_dir += 4*j;
        }
    }
    
    CC_SHA256(code_dir, realsize, out);
}

const struct cs_hash *cs_find_md(uint8_t type) {
    return (struct cs_hash *)ReadKernel64(GETOFFSET(cs_find_md) + ((type - 1) * 8));
}




// load_code_signature manipulation

int bypassCodeSign(const char *filename) {
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            LOG("load_code_signature replacement by @Jakeashacks");
            LOG("loader by @Pwn20wnd");
        });
    }
    LOG("%s: Loading \"%s\"...", __FUNCTION__, filename);
    int rv = 0;
    FILE *file = NULL;
    uint64_t vnode = 0;
    uint64_t ubc_info = 0;
    uint64_t cs_blob = 0;
    int64_t mach_off = 0;
    uint64_t lc_cmd = 0;
    struct linkedit_data_command *lcp = NULL;
    uint64_t addr = 0;
    CS_GenericBlob *blob_buf = NULL;
    struct cs_blob *blob = NULL;
    CS_CodeDirectory *rcd = NULL;
    CS_GenericBlob *rentitlements = NULL;
    const unsigned char *md_base;
    uint8_t hash[CS_HASH_MAX_SIZE];
    int md_size = 0;
    uint64_t cd = 0;
    uint64_t entitlements = 0;
    vm_address_t new_mem_kaddr = 0;
    vm_size_t new_mem_size = 0;
    CS_CodeDirectory *new_cd = NULL;
    CS_GenericBlob const *new_entitlements = NULL;
    vm_offset_t new_blob_addr = 0;
    vm_size_t new_blob_size = 0;
    vm_size_t new_cdsize = 0;
    const CS_CodeDirectory *old_cd = NULL;
    CS_SuperBlob *new_superblob = NULL;
    vm_size_t len = 0;
    CS_CodeDirectory *_cd = NULL;
    CS_GenericBlob *_entitlements = NULL;
    CS_GenericBlob *newBlob = NULL;
    uint64_t ents = 0;
    off_t blob_start_offset = 0;
    off_t blob_end_offset = 0;
    uint64_t kblob = 0;
    uint8_t *code_directory = NULL;
    size_t blob_size = 0;
    size_t length = 0;
    
    if (!canRead(filename))
    {
        LOG("ERROR! File not found: %s", filename);
        rv = -100;
        goto out;
    }
    
    code_directory = getCodeDirectory(filename);
    if (code_directory == NULL) {
        rv = -1;
        goto out;
    }
    file = fopen(filename, "rb");
    if (file == NULL) {
        rv = -2;
        goto out;
    }
    vnode = vnodeForPath(filename);
    if (vnode == 0) {
        rv = -3;
        goto out;
    }
    ubc_info = ReadKernel64(vnode + off_v_ubcinfo);
    if (ubc_info == 0) {
        rv = -4;
        goto out;
    }
    cs_blob = ReadKernel64(ubc_info + off_ubcinfo_csblobs);
    if (cs_blob != 0) {
        WriteKernel32(ubc_info + 44, ReadKernel32(GETOFFSET(cs_blob_generation_count)));
        LOG("%s: Already loaded \"%s\"", __FUNCTION__, filename);
        rv = 0;
        goto out;
    }
    lc_cmd = getCodeSignatureLC(file, &mach_off);
    if (lc_cmd == 0 || mach_off < 0) {
        rv = -5;
        goto out;
    }
    lcp = load_bytes(file, lc_cmd, sizeof(struct linkedit_data_command));
    if (lcp == NULL) {
        rv = -6;
        goto out;
    }
    lcp->dataoff += mach_off;
    blob_size = lcp->datasize;
    addr = kmem_alloc(blob_size); //ubc_cs_blob_allocate(blob_size);
    if (addr == 0) {
        rv = -7;
        goto out;
    }
    blob_buf = load_bytes(file, lcp->dataoff, lcp->datasize);
    if (blob_buf == NULL) {
        rv = -8;
        goto out;
    }
    if (!wkbuffer(addr, (void *)blob_buf, lcp->datasize)) {
        rv = -9;
        goto out;
    }
    blob = malloc(sizeof(struct cs_blob));
    if (blob == NULL) {
        rv = -10;
        goto out;
    }
    blob->csb_mem_size = lcp->datasize;
    blob->csb_mem_offset = 0;
    blob->csb_mem_kaddr = addr;
    blob->csb_flags = 0;
    blob->csb_signer_type = CS_SIGNER_TYPE_UNKNOWN;
    blob->csb_platform_binary = 0;
    blob->csb_platform_path = 0;
    blob->csb_teamid = NULL;
    blob->csb_entitlements_blob = NULL;
    blob->csb_entitlements = NULL;
    blob->csb_reconstituted = 0;
    length = lcp->datasize;
    if (cs_validate_csblob((const uint8_t *)addr, length, &rcd, &rentitlements) != 0) {
        rv = -11;
        goto out;
    }
    cd = (uint64_t)rcd;
    rcd = malloc(sizeof(CS_CodeDirectory));
    if (!rkbuffer(cd, (void *)rcd, sizeof(CS_CodeDirectory))) {
        rv = -12;
        goto out;
    }
    if (rentitlements != NULL) {
        entitlements = (uint64_t)rentitlements;
        rentitlements = malloc(sizeof(CS_GenericBlob));
        if (rentitlements == NULL) {
            rv = -13;
            goto out;
        }
        if (!rkbuffer(entitlements, rentitlements, sizeof(CS_GenericBlob))) {
            rv = -14;
            goto out;
        }
    }
    blob->csb_cd = (const CS_CodeDirectory *)cd;
    blob->csb_entitlements_blob = (const CS_GenericBlob *)entitlements;
    blob->csb_hashtype = cs_find_md(rcd->hashType);
    if (blob->csb_hashtype == NULL || ReadKernel64((uint64_t)blob->csb_hashtype + offsetof(struct cs_hash, cs_digest_size)) > sizeof(hash)) {
        rv = -15;
        goto out;
    }
    blob->csb_hash_pageshift = rcd->pageSize;
    blob->csb_hash_pagesize = (1U << rcd->pageSize);
    blob->csb_hash_pagemask = blob->csb_hash_pagesize - 1;
    blob->csb_hash_firstlevel_pagesize = 0;
    blob->csb_flags = (ntohl(rcd->flags) & CS_ALLOWED_MACHO) | CS_VALID;
    blob->csb_end_offset = (((vm_offset_t)ntohl(rcd->codeLimit) + blob->csb_hash_pagemask) & ~((vm_offset_t)blob->csb_hash_pagemask));
    if((ntohl(rcd->version) >= CS_SUPPORTSSCATTER) && (ntohl(rcd->scatterOffset))) {
        const SC_Scatter *scatter = (const SC_Scatter*)
        ((const char*)rcd + ntohl(rcd->scatterOffset));
        blob->csb_start_offset = ((off_t)ntohl(scatter->base)) * blob->csb_hash_pagesize;
    } else {
        blob->csb_start_offset = 0;
    }
    md_base = (const unsigned char *)cd;
    md_size = ntohl(rcd->length);
    getSHA256inplace(code_directory, hash);
    memcpy(blob->csb_cdhash, hash, CS_CDHASH_LEN);
    blob->csb_cpu_type = 0x0100000c;
    blob->csb_base_offset = mach_off;
    blob->csb_signer_type = 0;
    blob->csb_flags = 0x24000005;
    blob->csb_platform_binary = 1;
    old_cd = blob->csb_cd;
    new_cdsize = htonl(ReadKernel32((uint64_t)old_cd + offsetof(CS_CodeDirectory, length)));
    new_blob_size = sizeof(CS_SuperBlob);
    new_blob_size += sizeof(CS_BlobIndex);
    new_blob_size += new_cdsize;
    if (blob->csb_entitlements_blob) {
        new_blob_size += sizeof(CS_BlobIndex);
        new_blob_size += ntohl(ReadKernel32((uint64_t)blob->csb_entitlements_blob + offsetof(CS_GenericBlob, length)));
    }
    new_blob_addr = ubc_cs_blob_allocate(new_blob_size);
    if (new_blob_addr == 0) {
        rv = -16;
        goto out;
    }
    new_superblob = (CS_SuperBlob *)new_blob_addr;
    WriteKernel32((uint64_t)new_superblob + offsetof(CS_SuperBlob, magic), htonl(CSMAGIC_EMBEDDED_SIGNATURE));
    WriteKernel32((uint64_t)new_superblob + offsetof(CS_SuperBlob, length), htonl((uint32_t)new_blob_size));
    if (blob->csb_entitlements_blob != NULL) {
        vm_size_t cd_offset = sizeof(CS_SuperBlob) + 2 * sizeof(CS_BlobIndex);
        vm_size_t ent_offset = cd_offset +  new_cdsize;
        WriteKernel32((uint64_t)new_superblob + offsetof(CS_SuperBlob, count), htonl(2));
        WriteKernel32((uint64_t)new_superblob + offsetof(CS_SuperBlob, index[0].type), htonl(CSSLOT_CODEDIRECTORY));
        WriteKernel32((uint64_t)new_superblob + offsetof(CS_SuperBlob, index[0].offset), htonl((uint32_t)cd_offset));
        WriteKernel32((uint64_t)new_superblob + offsetof(CS_SuperBlob, index[1].type), htonl(CSSLOT_ENTITLEMENTS));
        WriteKernel32((uint64_t)new_superblob + offsetof(CS_SuperBlob, index[1].offset), htonl((uint32_t)ent_offset));
        void *buf = malloc(ntohl(ReadKernel32((uint64_t)blob->csb_entitlements_blob + offsetof(CS_GenericBlob, length))));
        if (buf == NULL) {
            rv = -17;
            goto out;
        }
        if (!rkbuffer((uint64_t)blob->csb_entitlements_blob, buf, ntohl(ReadKernel32((uint64_t)blob->csb_entitlements_blob + offsetof(CS_GenericBlob, length))))) {
            rv = -18;
            goto out;
        }
        if (!wkbuffer((uint64_t)(new_blob_addr + ent_offset), buf, ntohl(ReadKernel32((uint64_t)blob->csb_entitlements_blob + offsetof(CS_GenericBlob, length))))) {
            rv = -19;
            goto out;
        }
        free(buf);
        buf = NULL;
        new_cd = (CS_CodeDirectory *)(new_blob_addr + cd_offset);
    } else {
        new_cd = (CS_CodeDirectory *)new_blob_addr;
    }
    void *buf = malloc(new_cdsize);
    if (buf == NULL) {
        rv = -20;
        goto out;
    }
    if (!rkbuffer((uint64_t)old_cd, buf, new_cdsize)) {
        rv = -21;
        goto out;
    }
    if (!wkbuffer((uint64_t)new_cd, buf, new_cdsize)) {
        rv = -22;
        goto out;
    }
    free(buf);
    buf = NULL;
    len = new_blob_size;
    if (cs_validate_csblob((const uint8_t *)new_blob_addr, len, &_cd, &_entitlements) != 0) {
        kexecute2(GETOFFSET(kfree), new_blob_addr, new_blob_size, 0, 0, 0, 0, 0);
        rv = -23;
        goto out;
    }
    new_entitlements = _entitlements;
    new_mem_size = new_blob_size;
    new_mem_kaddr = new_blob_addr;
    kmem_free(blob->csb_mem_kaddr, blob->csb_mem_size); //kexecute(GETOFFSET(kfree), blob->csb_mem_kaddr, blob->csb_mem_size, 0, 0, 0, 0, 0);
    addr = 0;
    blob->csb_mem_kaddr = new_mem_kaddr;
    blob->csb_mem_size = new_mem_size;
    blob->csb_cd = new_cd;
    if (new_entitlements == 0) {
        const char *newEntitlements = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
        "<plist version=\"1.0\">"
        "<dict>"
        "<key>platform-application</key>"
        "<true/>"
        "<key>com.apple.private.security.no-container</key>"
        "<true/>"
        "<key>com.apple.private.skip-library-validation</key>"
        "<true/>"
        "</dict>"
        "</plist>";
        newBlob = malloc(sizeof(CS_GenericBlob) + strlen(newEntitlements) + 1);
        if (newBlob == NULL) {
            rv = -24;
            goto out;
        }
        newBlob->magic = ntohl(CSMAGIC_EMBEDDED_ENTITLEMENTS);
        newBlob->length = ntohl(strlen(newEntitlements) + 1);
        memcpy(newBlob->data, newEntitlements, strlen(newEntitlements) + 1);
        new_entitlements = (CS_GenericBlob *)ubc_cs_blob_allocate(sizeof(CS_GenericBlob) + strlen(newEntitlements) + 1);
        if (new_entitlements == NULL) {
            rv = -25;
            goto out;
        }
        if (!wkbuffer((uint64_t)new_entitlements, newBlob, sizeof(CS_GenericBlob) + strlen(newEntitlements) + 1)) {
            rv = -26;
            goto out;
        }
    }
    blob->csb_entitlements_blob = new_entitlements;
    ents = kexecute2(GETOFFSET(osunserializexml), (uint64_t)new_entitlements + offsetof(CS_GenericBlob, data), 0, 0, 0, 0, 0, 0);
    if (ents == 0) {
        rv = -27;
        goto out;
    }
    ents = zm_fix_addr(ents);
    blob->csb_entitlements = (void *)ents;
    uint64_t OSBoolTrue = ReadKernel64(GETOFFSET(OSBoolean_True));
    if (OSBoolTrue == 0) {
        rv = -28;
        goto out;
    }
    if (OSDictionary_SetItem(ents, "platform-application", OSBoolTrue) != 1) {
        rv = -29;
        goto out;
    }
    if (OSDictionary_SetItem(ents, "com.apple.private.security.no-container", OSBoolTrue) != 1) {
        rv = -30;
        goto out;
    }
    if (OSDictionary_SetItem(ents, "com.apple.private.skip-library-validation", OSBoolTrue) != 1) {
        rv = -31;
        goto out;
    }
    blob->csb_reconstituted = 1;
    blob_start_offset = blob->csb_base_offset + blob->csb_start_offset;
    blob_end_offset = blob->csb_base_offset + blob->csb_end_offset;
    if (blob_start_offset >= blob_end_offset || blob_start_offset < 0 || blob_end_offset <= 0) {
        rv = -32;
        goto out;
    }
    uint64_t ui_control = ReadKernel64(ubc_info + 8);
    if (ui_control == 0) {
        rv = -33;
        goto out;
    }
    uint64_t moc_object = ReadKernel64(ui_control + 8);
    if (moc_object == 0) {
        rv = -34;
        goto out;
    }
    WriteKernel32(moc_object + 168, (ReadKernel32(moc_object + 168) & 0xFFFFFEFF) | (1 << 8));
    WriteKernel32(ubc_info + 44, ReadKernel32(GETOFFSET(cs_blob_generation_count)));
    blob->csb_next = 0;
    kblob = ubc_cs_blob_allocate(sizeof(struct cs_blob));
    if (kblob == 0) {
        rv = -35;
        goto out;
    }
    if (!wkbuffer(kblob, blob, sizeof(struct cs_blob))) {
        rv = -36;
        goto out;
    }
    WriteKernel64(ubc_info + off_ubcinfo_csblobs, kblob);
    LOG("%s: Done", __FUNCTION__);
    rv = 0;
out:
    LOG("%s: Cleaning up...", __FUNCTION__);
    if (file != NULL) {
        fclose(file);
        file = NULL;
    }
    if (addr != 0) {
        kmem_free(addr, blob_size); //kexecute(GETOFFSET(kfree), addr, blob_size, 0, 0, 0, 0, 0);
        addr = 0;
    }
    if (vnode != 0) {
        _vnode_put(vnode);
        vnode = 0;
    }
    ubc_info = 0;
    cs_blob = 0;
    mach_off = 0;
    lc_cmd = 0;
    if (lcp != NULL) {
        free(lcp);
        lcp = NULL;
    }
    if (blob_buf != NULL) {
        free(blob_buf);
        blob_buf = NULL;
    }
    if (blob != NULL) {
        free(blob);
        blob = NULL;
    }
    if (rcd != NULL) {
        free(rcd);
        rcd = NULL;
    }
    if (rentitlements != NULL) {
        free(rentitlements);
        rentitlements = NULL;
    }
    md_base = NULL;
    md_size = 0;
    cd = 0;
    new_mem_kaddr = 0;
    new_mem_size = 0;
    new_cd = NULL;
    new_entitlements = NULL;
    new_blob_addr = 0;
    new_blob_size = 0;
    new_cdsize = 0;
    old_cd = NULL;
    new_superblob = NULL;
    _cd = NULL;
    _entitlements = NULL;
    if (newBlob != NULL) {
        free(newBlob);
        newBlob = NULL;
    }
    ents = 0;
    blob_start_offset = 0;
    blob_end_offset = 0;
    if (code_directory != NULL) {
        free(code_directory);
        code_directory = NULL;
    }
    LOG("%s: rv: %d", __FUNCTION__, rv);
    if (rv == 0) {
        LOG("%s: Success", __FUNCTION__);
    } else {
        LOG("%s: Failure", __FUNCTION__);
    }
    return rv;
}
