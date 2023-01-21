//
//  k_offsets.h
//  ios-fuzzer
//
//  Created by Quote on 2021/1/26.
//  Copyright © 2021 Quote. All rights reserved.
//

#ifndef k_offsets_h
#define k_offsets_h

// Generate the name for an offset.
#define OFFSET(base_, object_)      _##base_##__##object_##__offset_

// Generate the name for the size of an object.
#define SIZE(object_)               _##object_##__size_

#ifdef Q_INTERNAL
#define qexternal
#else
#define qexternal extern
#endif

// Parameters for ipc_entry.
qexternal size_t SIZE(ipc_entryPF);
qexternal size_t OFFSET(ipc_entryPF, ie_objectPF);

// Parameters for ipc_port.
qexternal size_t OFFSET(ipc_port, ip_bitsPF);
qexternal size_t OFFSET(ipc_port, ip_referencesPF);
qexternal size_t OFFSET(ipc_port, ip_kobjectPF);

// Parameters for struct ipc_space.
qexternal size_t OFFSET(ipc_space, is_table_sizePF);
qexternal size_t OFFSET(ipc_space, is_tablePF);

// Parameters for struct thread.
qexternal size_t OFFSET(thread, jop_pidPF); // struct thread { struct machine_thread { jop_pid } }

// Parameters for struct task.
qexternal size_t OFFSET(task, mapPF);
qexternal size_t OFFSET(task, itk_spacePF);
qexternal size_t OFFSET(task, bsd_infoPF);
qexternal size_t OFFSET(task, t_flagsPF);

qexternal size_t OFFSET(proc, le_nextPF);
qexternal size_t OFFSET(proc, le_prevPF);
qexternal size_t OFFSET(proc, taskPF);
qexternal size_t OFFSET(proc, p_ucredPF);
qexternal size_t OFFSET(proc, p_pidPF);
qexternal size_t OFFSET(proc, p_fdPF);

qexternal size_t OFFSET(filedesc, fd_ofilesPF);
qexternal size_t OFFSET(fileproc, fp_globPF);
qexternal size_t OFFSET(fileglob, fg_dataPF);
qexternal size_t OFFSET(pipe, bufferPF);

qexternal size_t OFFSET(ucred, cr_posixPF);

qexternal size_t SIZE(posix_credPF);

// Parameters for OSDictionary.
qexternal size_t OFFSET(OSDictionary, countPF);
qexternal size_t OFFSET(OSDictionary, capacityPF);
qexternal size_t OFFSET(OSDictionary, dictionaryPF);

// Parameters for OSString.
qexternal size_t OFFSET(OSString, stringPF);

// Parameters for IOSurfaceRootUserClient.
qexternal size_t OFFSET(IOSurfaceRootUserClient, surfaceClientsPF);
qexternal size_t OFFSET(IOSurfaceClient, surfacePF);
qexternal size_t OFFSET(IOSurface, valuesPF);

qexternal kptr_t kc_kernel_basePF;
qexternal kptr_t kc_kernel_mapPF;
qexternal kptr_t kc_kernel_taskPF;
qexternal kptr_t kc_IOSurfaceClient_vtPF;
qexternal kptr_t kc_IOSurfaceClient_vt_0PF;

#undef qexternal

void kernel_offsets_init(void);

#endif /* k_offsets_h */
