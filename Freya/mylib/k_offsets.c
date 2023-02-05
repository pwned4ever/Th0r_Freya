//
//  k_offsets.c
//  ios-fuzzer
//
//  Created by Quote on 2021/1/26.
//  Copyright © 2021 Quote. All rights reserved.
//

#include <string.h>
#include "mycommon.h"
#include "utils.h"
#define Q_INTERNAL
#include "k_offsets.h"

static void offsets_base_iOS_14_x(void)
{
    kc_kernel_basePF = 0xFFFFFFF007004000;

    SIZE(ipc_entryPF)              = 0x18;
    OFFSET(ipc_entryPF, ie_objectPF) =  0x0;

    OFFSET(ipc_port, ip_bitsPF)       =  0x0;
    OFFSET(ipc_port, ip_referencesPF) =  0x4;
    OFFSET(ipc_port, ip_kobjectPF)    = 0x68;

    OFFSET(ipc_space, is_table_sizePF) = 0x14;
    OFFSET(ipc_space, is_tablePF)      = 0x20;

    OFFSET(task, mapPF) = 0x28;
    OFFSET(task, itk_spacePF) = 0x330;
#if __arm64e__
    OFFSET(task, bsd_infoPF) = 0x3a0;
    OFFSET(task, t_flagsPF) = 0x3f4;
#else
    OFFSET(task, bsd_infoPF) = 0x390;
    OFFSET(task, t_flagsPF) = 0x3d8;
#endif

    OFFSET(proc, le_nextPF) = 0x00;
    OFFSET(proc, le_prevPF) = 0x08;
    OFFSET(proc, taskPF) = 0x10;
    OFFSET(proc, p_pidPF) = 0x68;
    OFFSET(proc, p_ucredPF) = 0xf0;
    OFFSET(proc, p_fdPF) = 0xf8;

    OFFSET(filedesc, fd_ofilesPF) = 0x00;
    OFFSET(fileproc, fp_globPF) = 0x10;
    OFFSET(fileglob, fg_dataPF) = 0x38;
    OFFSET(pipe, bufferPF) = 0x10;

    OFFSET(ucred, cr_posixPF) = 0x18;

    SIZE(posix_credPF) = 0x60;

    OFFSET(OSDictionary, countPF)      = 0x14;
    OFFSET(OSDictionary, capacityPF)   = 0x18;
    OFFSET(OSDictionary, dictionaryPF) = 0x20;

    OFFSET(OSString, stringPF) = 0x10;

    OFFSET(IOSurfaceRootUserClient, surfaceClientsPF) = 0x118;
    OFFSET(IOSurfaceClient, surfacePF) = 0x40;
    OFFSET(IOSurface, valuesPF) = 0xe8;
}

static void offsets_iPhone6s_18A373(void)
{
    offsets_base_iOS_14_x();
}

static void offsets_iPhone11_18A373(void)
{
    offsets_base_iOS_14_x();

    OFFSET(thread, jop_pidPF) = 0x510;
}

static void offsets_iPhone12pro_18C66(void)
{
    offsets_base_iOS_14_x();

    OFFSET(thread, jop_pidPF) = 0x518;
}

struct device_def {
    const char *name;
    const char *model;
    const char *build;
    void (*init)(void);
};

static struct device_def devices[] = {
    { "iPhone 6s", "N71AP", "18A373", offsets_iPhone6s_18A373 },
    { "iPhone 11", "N104AP", "18A373", offsets_iPhone11_18A373 },
    { "iPhone 12 pro", "D53pAP", "18C66", offsets_iPhone12pro_18C66 },
    { "iPhone ?", "?", "*", offsets_base_iOS_14_x },
};

void kernel_offsets_init(void)
{
    for (int i = 0; i < arrayn(devices); i++) {
        struct device_def *dev = &devices[i];
        if (!strcmp(g_exp.model, dev->model) && !strcmp(g_exp.osversion, dev->build)) {
            dev->init();
            return;
        }
        if (!strcmp(dev->build, "*")) {
            util_warning("fallback to default iOS 14.x offsets");
            dev->init();
            return;
        }
    }
    fail_info("no device defination");
}
