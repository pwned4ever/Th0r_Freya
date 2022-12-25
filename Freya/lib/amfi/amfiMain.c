//
//  amfiMain.c
//  TH0R
//
//  Created by M CIANCHINO on 2022-05-28.
//  Copyright © 2022 Th0r Team. All rights reserved.
//

#include "amfiMain.h"
#include <sys/event.h>
#import <mach/mach.h>
#import <sys/event.h>

#include <mach/mach.h>
#include <mach/task.h>
#include <sys/signal.h>
#include "libproc.h"
#include <dlfcn.h>
#include <stdio.h>
#include <pthread.h>
#include <CoreFoundation/CoreFoundation.h>

extern void NSLog(CFStringRef, ...);
#include <unistd.h>
#include <stdlib.h> // exit
#include <mach-o/loader.h> // for Mach-O handling
#include <mach-o/fat.h>

    uint64_t amfidTEXTaddress =  0;


#ifdef _11
    uint32_t MVSACI_offset =  0x100004150  -  0x100000000;
#else
    uint32_t MVSACI_offset =  0x100004140  -  0x100000000;
#endif

//
// Missing headers
//
kern_return_t mach_vm_write
(
 vm_map_t target_task,
 mach_vm_address_t address,
 vm_offset_t data,
 mach_msg_type_number_t dataCnt
 );

kern_return_t mach_vm_read_overwrite
(
 vm_map_t target_task,
 mach_vm_address_t address,
 mach_vm_size_t size,
 vm_offset_t data,
 mach_msg_type_number_t *dataCnt
 );

FILE *OUT = NULL;
void debug (char *Msg, ...)
{

 static char buffer[2048];
    va_list args;
    va_start (args, Msg);
    vsprintf (buffer, Msg, args);
    va_end (args);
    NSLog(CFSTR("DEBUG: %s\n"), buffer);
    fprintf(OUT, "DEBUG: %s\n", buffer);

}
void status (char *Msg, ...)
{

static char buffer[2048];
    va_list args;
    va_start (args, Msg);
    vsprintf (buffer, Msg, args);
    va_end (args);
    NSLog(CFSTR("%s\n"), buffer);
    fprintf(OUT, "%s\n", buffer);
}

void error (char *Msg, ...)
{

static char buffer[2048];
    va_list args;
    va_start (args, Msg);
    vsprintf (buffer, Msg, args);
    va_end (args);
    NSLog(CFSTR("ERROR: %s\n"), buffer);
    fprintf(OUT, "Error: %s\n", buffer);
    //exit(strlen(Msg)); // :-)
}

pid_t findPidOfProcess (char *ProcName) {


     char buffer[256];

    int rc = 0 ;
    int pid = 0;
    
    // Brute force-ish. Better would be to get list of pids first..

    for (pid = 1; pid < 65536; pid++)
    {
        // Interesting behavior: proc_name only works for processes with same uid.
        rc = proc_name(pid, // int pid,
             buffer, //  void * buffer,
             256);   // uint32_t buffersize)


        //if (rc){ printf("PID %d: %s\n", pid, buffer);}
    
        if (rc  && strcmp(buffer,ProcName) == 0)
        {
            return pid;
        }
    }

    return 0;


}




// Code signing support
#define ALGORITHM_SHA256    256
#define ALGORITHM_SHA1        1

int algorithm = ALGORITHM_SHA256;

const struct ccdigest_info *ccsha256_di(void);

void cchmac(const struct ccdigest_info *di, unsigned long key_len,
            const void *key, unsigned long data_len, const void *data,
            unsigned char *mac);


void ccdigest(const struct ccdigest_info *di, unsigned long len,
              const void *data, void *digest);


static inline unsigned char *mysha1 (void *Data, int Len)
{

    static unsigned char sha256[32] = {0};
    ccdigest(ccsha256_di(),
             0x1000, // data_len
             Data,    // const void *data
             sha256); // unsigned char *mac);
    
    return (sha256);
}

int MISdoNotValidateSignatureButCopyInfo(char *Path, void *Options, char *outDict)
{
 // Not yet
    return 0;
        
} //doNotValidateCodeSignatureButCopyInfo




const struct ccdigest_info *ccsha256_di(void);
const struct ccdigest_info *ccsha1_di(void);

void cchmac(const struct ccdigest_info *di, unsigned long key_len,
            const void *key, unsigned long data_len, const void *data,
            unsigned char *mac);


void ccdigest(const struct ccdigest_info *di, unsigned long len,
              const void *data, void *digest);


static inline unsigned char doSHA256 (void *Data, int Len, unsigned char *Buf)
{

    static unsigned char sha256[32] = {0};
    ccdigest(ccsha256_di(),
             Len, // data_len
             Data,    // const void *data
             Buf); // unsigned char *mac);
    
    return (Buf);
}
static inline unsigned char doSHA1 (void *Data, int Len, unsigned char *Buf)
{

    static unsigned char sha1[32] = {0};
    ccdigest(ccsha1_di(),
             Len, // data_len
             Data,    // const void *data
             Buf); // unsigned char *mac);
    
    return (Buf);
}


#define FAULTING_ADDRESS 0x454d41524542494c  // De profondu lacu

unsigned char *cdHashOfFile(char *Path, int Algorithm )
{
        struct stat stBuf ;
    
        if (access (Path, F_OK)) {
        fprintf(stderr,"File %s apparently not found!\n", Path); return NULL;
    }

        int fd = open (Path, O_RDONLY);
        
        if (fd == -1) { fprintf(stderr,"Unable to open File %s - %s\n", Path ,strerror(errno)); return NULL; }
                   
        int rc = fstat (fd,&stBuf);
    
 //    NSLog(CFSTR("Processing file %s\n"), Path);
                   
                   char *fileContents = malloc(stBuf.st_size);

                   read (fd, fileContents, stBuf.st_size);
                   
                   
    close(fd);

           
                   struct mach_header_64 *mh = (struct mach_header_64 *) fileContents;
                   
           if (mh->magic != MH_MAGIC_64) {

                // Give FAT a change...

                if (mh->magic == FAT_CIGAM) {
                    struct fat_header *fh = (struct fat_header *) mh;
                    fprintf(OUT, "# fat archs: %d\n", ntohl(fh->nfat_arch));

                    struct fat_arch *fa = (struct fat_arch *) (fh +1);

                    int arch = 0;
                    for (arch = 0; arch <  ntohl(fh->nfat_arch); arch++)
                    {
                        fprintf(OUT, "ARCH: 0x%x\n", fa->cputype);
                    if (fa->cputype == 0xc000001) {  // CPU_TYPE_ARM64)
                        fprintf(OUT, "Adjusting header to 0x%x\n", ntohl(fa->offset));
                        mh = (struct mach_header_64 *) (fileContents + ntohl(fa->offset));
                    }
                        fa++; // maybe next arch?:
                    } // end for
#if 0
struct fat_header {
        uint32_t        magic;          /* FAT_MAGIC or FAT_MAGIC_64 */
        uint32_t        nfat_arch;      /* number of structs that follow */
};

struct fat_arch {
        cpu_type_t      cputype;        /* cpu specifier (int) */
        cpu_subtype_t   cpusubtype;     /* machine specifier (int) */
        uint32_t        offset;         /* file offset to this object file */
        uint32_t        size;           /* size of this object file */
        uint32_t        align;          /* alignment as a power of 2 */
};
#endif
                    printf ("MH MAGIC IS NOW %x\n", mh->magic);

                }

                else { error ("Found magic 0x%x at off file - this is not an MH_MAGIC_64 nor a FAT_MAGIC..\n", mh->magic); return(NULL);}
            }

                   fprintf (OUT,"Got Header with %d Load commands\n", mh->ncmds);
                   
                   int lcNum = 0;
                   struct load_command *lc =  (struct load_command *) ((char *)mh + sizeof(struct mach_header_64));
                   
                   while (lcNum < mh->ncmds -1)
                   {
                       lc = (struct load_command *)((char *)lc + lc->cmdsize);
                       lcNum++;
                       
                   }
                   
                   //    printf("Load command %d - 0x%x (0x%x)\n", lcNum, lc->cmd, LC_CODE_SIGNATURE);
                   
                   if (lc->cmd != LC_CODE_SIGNATURE) {
                       debug( "Last load command is not an LC_CODE_SIGNATURE...\n");
            free(fileContents);
                       return NULL;;
                   }
                   
                   // Want to get the code signature blob:
                   struct linkedit_data_command *ldc = (struct linkedit_data_command *) lc;
                   int csBlobOffset = ldc->dataoff;
                   int csBlobSize = ldc->datasize;
                   
           struct blobDesc {
                uint32_t blobType;
                uint32_t blobOffset;
            };

                   struct superblob {
                       uint32_t magic;
                       uint32_t size;
                       uint32_t numBlobs;
                       struct blobDesc    blobDesc[0];
                       
                   } *b = (struct superblob *) ((char *)mh + ldc->dataoff);
                   
        
                   
    
    if (memmem(b, ntohl(b->size), "Apple Worldwide Developer Relations",
            strlen("Apple Worldwide Developer Relations"))) {
        debug("Request for a dev signed party - allowing this\n");
    }
    else
    if (memmem(b,ntohl(b->size), "Apple Certi", 10)) {
    free(fileContents);
        debug("Request for an App store binary - not touching this\n");
        return NULL;
    }
    
                   
    struct __CodeDirectory {
        uint32_t magic;                                 /* magic number (CSMAGIC_CODEDIRECTORY) */
        uint32_t length;                                /* total length of CodeDirectory blob */
        uint32_t version;                               /* compatibility version */
        uint32_t flags;                                 /* setup and mode flags */
        uint32_t hashOffset;                    /* offset of hash slot element at index zero */
        uint32_t identOffset;                   /* offset of identifier string */
        uint32_t nSpecialSlots;                 /* number of special hash slots */
        uint32_t nCodeSlots;                    /* number of ordinary (code) hash slots */
        uint32_t codeLimit;                             /* limit to main image signature range */
        uint8_t hashSize;                               /* size of each hash in bytes */
        uint8_t hashType;                               /* type of hash (cdHashType* constants) */
        uint8_t platform;                                       /* unused (must be zero) */
        uint8_t pageSize;                               /* log2(page size in bytes); 0 => infinite */
        uint32_t spare2;                                /* unused (must be zero) */
          } *cdb;
    int kSecCodeMagicCodeDirectory = 0xfade0c02;        /* CodeDirectory */

        cdb  =  (struct __CodeDirectory *) ((char *) b + ntohl(b->blobDesc[0].blobOffset));
    int numBlob = 0;

     status("GOT BLOB, MAGIC: 0x%x, offset: %x,  type: %x\n",
                  ntohl(cdb->magic), ntohl(b->blobDesc[0].blobOffset),
                    ntohl(b->blobDesc[0].blobType));

    int matchingBlob = 0;


    int match = 0;
    while     (numBlob < ntohl(b->numBlobs))
    {
        if (cdb->magic != htonl (kSecCodeMagicCodeDirectory))
        {
            fprintf(OUT, "Blob Magic: 0x%x - not a code directory (!= 0x%x)\n",
            ntohl(cdb->magic), htonl (kSecCodeMagicCodeDirectory));
        }
        else // is a code directory.
            if
            (cdb->hashSize != (Algorithm == ALGORITHM_SHA256 ? 32 : 20))
        {
            fprintf(OUT,"Blob %d hash size: %d (need %d)\n",
                cdb->hashSize,
                (Algorithm == ALGORITHM_SHA256 ? 32 : 20));
        }
        else
        {
            // MATCH
            match++;
            break;
        }
        numBlob++;
            cdb  =  (struct __CodeDirectory *) ((char *) b + ntohl(b->blobDesc[numBlob].blobOffset));
 /*
     status("GOT BLOB, MAGIC: 0x%x, offset: %x,  type: %x\n",
                  ntohl(cdb->magic), ntohl(b->blobDesc[numBlob].blobOffset),
                    ntohl(b->blobDesc[numBlob].blobType));
*/
        
        
    } // while
        

                   
    if (!match) { fprintf(stderr,"Can't find a CD Blob match\n"); return (NULL); }

        printf("CD Blob magic: 0x%x (CodeDir: 0x%lx)\n", ntohl(cdb->magic),kSecCodeMagicCodeDirectory);
        uint32_t cdSize = ntohl(cdb->length);
                   
        static unsigned char cdHash[32];
    
        switch (Algorithm)
        {
        case ALGORITHM_SHA256:
         doSHA256(cdb, cdSize, cdHash);
    break;
     
        case ALGORITHM_SHA1:
            
        status("Doing SHA1\n");
                   doSHA1(cdb, cdSize, cdHash);
        break;
     
    }
                   
    free(fileContents);
  
    return  (char *)cdHash;
}
     


// End code signing support
uint64_t MVSACI_addr = 0;



mach_port_t    g_AmfidPort = MACH_PORT_NULL;

int exceptionHandler (mach_port_t ExceptionPort)
{

#define BUFSIZE 0x1000
    mach_msg_header_t* msg = (mach_msg_header_t *) alloca(BUFSIZE);;
    for(;;){
            kern_return_t kr;
 
            kr = mach_msg(msg,
                           MACH_RCV_MSG | MACH_MSG_TIMEOUT_NONE, // no timeout
                           0,
                           BUFSIZE,
                           ExceptionPort,
                           0,
                           0);
        

        
        // We get this from mach_exc.defs, with an application of mig
        // Note that packing the structure is essential since it is
        // not aligned on any boundaries..
#pragma pack(1)
            struct  mach_exc_msg {
            mach_msg_header_t Head;
            /* start of the kernel processed data */
            mach_msg_body_t msgh_body;
            mach_msg_port_descriptor_t thread;
            mach_msg_port_descriptor_t task;
            /* end of the kernel processed data */
            NDR_record_t NDR;
            exception_type_t exception;
            mach_msg_type_number_t codeCnt;
            int64_t code[2];
            int flavor;
            mach_msg_type_number_t old_stateCnt;
            natural_t old_state[614];
            }  ;
#pragma pack()
          struct mach_exc_msg *excMsg =  (struct mach_exc_msg *)msg;

        // Ian Beer uses thread_get_state() - which he would need, since he uses exception_raise,
        // but if you use raise_state_identity, you get everything.
 
        if ((excMsg->Head.msgh_id !=2405) && (excMsg->Head.msgh_id != 2407))
        {
          fprintf(stderr, "Message isn't 2407.. this is weird\n");
        }
        
#if 0
        // from osfmk/mach/arm/_structs.h:
        _STRUCT_ARM_THREAD_STATE64
        {
            __uint64_t    __x[29];  /* General purpose registers x0-x28 */
            __uint64_t    __fp;             /* Frame pointer x29 */
            __uint64_t    __lr;             /* Link register x30 */
            __uint64_t    __sp;             /* Stack pointer x31 */
            __uint64_t    __pc;             /* Program counter */
            __uint32_t    __cpsr;   /* Current program status register */
            __uint32_t    __pad;    /* Same size for 32-bit or 64-bit clients */
        };

#endif
       //  hexDump(excMsg, 0x300, 0);
        printf("TASK: 0x%x, Thread: 0x%x - CODE: 0x%llx/0x%llx, flavor: %x\n",
                excMsg->task, excMsg->thread, excMsg->code[0], excMsg->code[1], excMsg->flavor);
        mach_port_t thread_port = excMsg->thread.name;
        mach_port_t task_port = excMsg->task.name;

        
#ifndef TEST
        _STRUCT_ARM_THREAD_STATE64 * old_state = (_STRUCT_ARM_THREAD_STATE64 *) malloc (614*4); //  = (_STRUCT_ARM_THREAD_STATE64 *)excMsg->old_state;
          mach_msg_type_number_t  cnt = 68; //sizeof(ARM_THREAD_STATE64)/4;;
        kr = thread_get_state(thread_port,  //
                              ARM_THREAD_STATE64, // thread_state_flavor_t flavor
                              (thread_state_t)old_state,
                              &cnt);

        
     //   dumpARMThreadState64(old_state);
        
        uint64_t fileNameAddr = old_state->__x[25];
        uint64_t optionsAddr  = old_state->__x[1];
        
        char *fileName = malloc(0x200);
        uint64_t fileNameSize = 0x200 ;
        
    // kr = task_get_special_port (mach_task_self(), TASK_DEBUG_CONTROL_PORT, &g_AmfidPort);
         kr =     mach_vm_read_overwrite(task_port, // target_task
                                        fileNameAddr, // address
                                        fileNameSize, // mach_vm_size_t size
                                    (mach_vm_address_t )fileName,
                                        &fileNameSize);
        
        debug("Got request - kr: %d - FileName (@0x%llx): %s (fileNameSize : %d)\n", kr, fileNameAddr, fileName, fileNameSize);

        unsigned char *cdh;

    cdh = cdHashOfFile(fileName, algorithm);

        if (!cdh) { mach_vm_write (task_port,
                                   old_state->__pc, MVSACI_addr,sizeof(uint64_t));
            
            old_state->__pc =MVSACI_addr;
                    debug("File error or not self signed... redirected to original MVSACI @0x%llx\n", MVSACI_addr);
        }
        else
                {
        kr = mach_vm_write(task_port,
                            old_state->__x[24],
            (mach_vm_address_t) cdh,
                20); // yep, 20, not 32..

    if (kr ==0 ) {

        debug("written cdhash for algorithm %d (0x%x 0x%x 0x%x...0x%x) to 0x%llx - kr %d\n",
             algorithm,
            cdh[0], cdh[1], cdh[2], cdh[19], old_state->__x[24] , kr);


        }
    else {
        error ("Error %d writing CDHash back into AMFI at 0x%llx\n",
            kr, old_state->__x[24]);
          }
        uint32_t one = 1;
        kr = mach_vm_write(task_port,  old_state->__x[20],
            (mach_vm_address_t) &one,sizeof(one));
        
        // Legacy VPN plugins :
        // uint32_t five = 5;
        // kr = mach_vm_write (AmfidPort, old_state->__x[28], &five, sizeof(five));
        // recover
        
#ifdef _11
        old_state->__pc = (old_state->__lr &  0xfffffffffffff000) + 0x1000; // resume
#else
        old_state->__pc = (old_state->__lr &  0xfffffffffffff000) + 0x0ef4; // resume
#endif
        }

        printf("will resume at 0x%llx\n",old_state->__pc);

        // -------------------------------
#pragma pack(1)
        typedef struct {
            mach_msg_header_t Head;
            NDR_record_t NDR;
            kern_return_t RetCode;
          /*  int flavor;
            mach_msg_type_number_t new_stateCnt;
            natural_t new_state[614];*/
          
        } excReplyMsg;

#pragma pack(0)
      
        
//#if 0
        kr = thread_set_state(thread_port,  //
               ARM_THREAD_STATE64, // thread_state_flavor_t flavor
                (thread_state_t)old_state,
                 cnt);

        printf("set state %d - Cnt: %d\n",kr, cnt);
//#endif
        
        
        excReplyMsg excReply = {0};
        
      //  memcpy(excReply.new_state, old_state, sizeof (*old_state));
   //     excReply.new_stateCnt= excMsg->old_stateCnt ;;
        
        excReply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(excMsg->Head.msgh_bits), 0);
        excReply.Head.msgh_size = sizeof(excReply);
        excReply.Head.msgh_remote_port = excMsg->Head.msgh_remote_port;
        excReply.Head.msgh_local_port = MACH_PORT_NULL;
        excReply.Head.msgh_id = excMsg->Head.msgh_id + 100;
      //  excReply.flavor= excMsg->flavor;
    
        
        excReply.NDR = excMsg->NDR;
        excReply.RetCode = KERN_SUCCESS;

        kr = mach_msg(&excReply.Head,
                       MACH_SEND_MSG|MACH_MSG_OPTION_NONE,
                       (mach_msg_size_t)sizeof(excReply),
                       0,
                       MACH_PORT_NULL,
                       MACH_MSG_TIMEOUT_NONE,
                       MACH_PORT_NULL);
        
      //   mach_port_deallocate(mach_task_self(), thread_port);
 //       mach_port_deallocate(mach_task_self(), task_port);

       // printf("sent reply - %d -  Flavor %d, %d bytes,  %x\n", excReply.Head.msgh_id , excReply.flavor,
       //             excReply.new_stateCnt ,kr);
       //  printf("REPLY KR: %d\n", kr);
        //dumpARMThreadState64(excReply.new_state);
    fflush(NULL);
#endif // TEST
        
    }
                
    return 0;
}

void setExceptionHandlerForTask(mach_port_t Victim, void *Handler)
{

    mach_port_t exc_port;
    // Chapter 11 of the old MOXiI book, if anyone's interested..
    mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &exc_port);
    mach_port_insert_right(mach_task_self(), exc_port, exc_port, MACH_MSG_TYPE_MAKE_SEND);
        
#ifndef TEST
    kern_return_t kr = task_set_exception_ports(Victim,
                                                EXC_MASK_ALL,
                                                exc_port,
                                               EXCEPTION_DEFAULT |  MACH_EXCEPTION_CODES,
                                                ARM_THREAD_STATE64);
#endif
        
    pthread_t exception_handling_thread;
    pthread_create(&exception_handling_thread, NULL, Handler, (void *) (mach_port_t) exc_port);

    printf("SET EXCEPTION HANDLER\n");
    
} // setExceptionHandlerForTask


#define FAULTING_ADDRESS 0x454d41524542494c  // De profondu lacu

int castrateAmfid (mach_port_t AmfidPort)
{

    status("Got AMFId's port (0x%x) - Let's castrate this bastard\n", AmfidPort);
    
    // The quick and dirty way is to do it with Ian's method. This also has the upside of enabling
    // an effective hook on all third party application startup (or library validations)
    // A better way is to patch up AMFId's code because there's plenty of space to fit in
    // a SHA-256 CDHash calculator and just jump to it instead of MISValidateSignatureAndCopyInfo
    
    // Anyway:
    // (TvOS 11.1, BEE6...CC3 , 270.20.2.0.0)
    //
    // __DATA  __la_symbol_ptr  0x100004150 0x02D1 libmis.dylib    _MISValidateSignatureAndCopyInfo

    pid_t amfidPid = 0;

    kern_return_t kr = pid_for_task (AmfidPort, &amfidPid);
while (amfidPid  <1 )
{
    if (amfidPid = -1) { debug("Error getting PID from task port. Was I handed an invalid task port?\n"); }

    status("HERE - 0x%x, %d\n", AmfidPort, amfidPid);
    printf("Sleeping\n");
fflush(NULL);
    sleep(1);
       pid_t amfidPid = findPidOfProcess("amfid");

    mach_port_deallocate (mach_task_self(), AmfidPort);
    kern_return_t kr = task_for_pid(mach_task_self(), amfidPid, &AmfidPort);

    printf("TFP ON %d - KR %d port %x\n", amfidPid, kr, AmfidPort);
    printf("KR %d on port %x\n", kr, AmfidPort);
    amfidPid = 0 ;
        kr = pid_for_task (AmfidPort, &amfidPid);
 }

    
    struct proc_regionwithpathinfo  regionsWithPaths;
    
    
    int reg = 0 ;
    uint64_t addr = 0;
    int size = 0 ;
    status("Getting region info:\n");
fflush(NULL);
    
    int rc = proc_pidinfo( amfidPid,
                          PROC_PIDREGIONPATHINFO,
                          addr,  // uint64_t arg,
                          &regionsWithPaths,
                          sizeof (struct proc_regionwithpathinfo));;
    
    status("Set exception handler:\n");
    setExceptionHandlerForTask(AmfidPort, exceptionHandler);
    

    amfidTEXTaddress = regionsWithPaths.prp_prinfo.pri_address;
    
    uint64_t len = sizeof(void *);
    uint64_t faultingAddr ;
retry:
    kr  = mach_vm_read_overwrite (AmfidPort,
                       amfidTEXTaddress + MVSACI_offset, sizeof(void *) ,
                       &MVSACI_addr,
             &len);

    
    if (kr == KERN_SUCCESS) {
    
 void *h = dlopen("libmis.dylib", 0);
    void *MISValidateSignatureAndCopyInfo = (void *) dlsym(h, "MISValidateSignatureAndCopyInfo");

            debug("Original address of MVSACI: 0x%llx\n", MVSACI_addr);
        debug("NOW SET TO %llx\n", MISValidateSignatureAndCopyInfo);
        MVSACI_addr = (uint64_t) MISValidateSignatureAndCopyInfo;
    

    }
    else
    {
        error("Unable to read amfid's memory\n");
    return -1;
        sleep(2);
    }

    
    faultingAddr = FAULTING_ADDRESS;

status("HERE STILL\n");
fflush(NULL);
    
    kr = mach_vm_write(AmfidPort,
            amfidTEXTaddress + MVSACI_offset,
            &faultingAddr, sizeof(void *));
    
    if (kr ==0 ) { status("patched AMFI through port 0x%x  @0x%llx to Faulting addr: 0x%llx\n",AmfidPort,amfidTEXTaddress + MVSACI_offset, faultingAddr );}
    else
    {
    printf("KR: %d\n", kr);
        error("Failed to patch AMFI @0x%llx\n",amfidTEXTaddress + MVSACI_offset );
     }

    uint64_t tryAgain;
    kr  = mach_vm_read_overwrite (AmfidPort,
                       amfidTEXTaddress + MVSACI_offset, sizeof(void *) ,
                       &tryAgain,
             &len);

    status("TRY AGAIN : 0x%llx\n", tryAgain);
    
    return 0;
}

struct kevent ke;
int getKqueueForPid (pid_t pid)
{
    // This is a direct rip from Listing 3-1 in the first edition of MOXiI:
    int kq = kqueue();
    if (kq == -1) { perror("kqueue"); printf("UNABLE TO CREATE KQUEUE\n"); return -1;}

    // Set process fork/exec notifications
    else {
    EV_SET(&ke, pid, EVFILT_PROC, EV_ADD, NOTE_EXIT_DETAIL , 0, NULL);
    // Register event
    int rc = kevent(kq, &ke, 1, NULL, 0, NULL);
    
    if (rc < 0) { perror ("kevent"); printf("UNABLE TO GET KEVENT\n"); return -2;}

    }
    return kq;
}

#ifndef TEST

int mainamfi (int argc, char **argv)
{


    // Ain't no terminating us
    // First find amfid
    OUT = fopen ("/tmp/amfidebilitate.out", "w");
    if (!OUT) { OUT = stdout;}



    if (argc > 1)
    {
        if (strcmp(argv[1], "sha1") == 0) {
            printf("WILL USE SHA-1\n");
            algorithm = ALGORITHM_SHA1;
            }

        else {
            printf("WILL USE SHA-256\n");
            algorithm = ALGORITHM_SHA256;

            }

    }
    status ("THIS IS AMFIDEBILITATE - Compiled on " __DATE__ "/" __TIME__);
    sleep(3);
    mach_port_t tsp = MACH_PORT_NULL;
    kern_return_t kr = task_get_special_port (mach_task_self(), TASK_DEBUG_CONTROL_PORT, &tsp);


    kr = KERN_SUCCESS;
    tsp = 0xbb07;
    tsp= MACH_PORT_NULL;




        
#define CS_OPS_ENTITLEMENTS_BLOB 7
        
  struct blob {
        uint32_t type;
        uint32_t len;
        char data[0];
        
        
    };

    struct blob *entBlob = alloca(1024); int entBlobLen = 1024;
        bzero (entBlob, entBlobLen);
   
    extern int csops (pid_t, int, char * ,int *);
       int  rc = csops (getpid(), CS_OPS_ENTITLEMENTS_BLOB, entBlob, &entBlobLen);
    extern int errno;
       if (rc) printf("CSOPS RC: %d, %s\n", rc,strerror(errno));
       else {
    printf("RETRIEVED BLOB: %s\n", entBlob->data);
       }


#if 0
    if (kr == KERN_SUCCESS)
    {
        pid_t amfidPid = 0 ;
        kern_return_t kr = pid_for_task(tsp, &amfidPid);
        while (kr == 5) {
        status("retrying -- amfid - Pid: %d (KR %d)\n", amfidPid, kr);
    //  kr = task_get_special_port (mach_task_self(), TASK_DEBUG_CONTROL_PORT, &tsp);
        kr = pid_for_task(tsp, &amfidPid);
        sleep(1);
        }
        g_AmfidPort = tsp;

    }
#endif

    // Got it. Don't want no signals
    signal(1, SIG_IGN);
    signal(2, SIG_IGN);
    signal(15, SIG_IGN);

    pid_t amfidPid;

    if (tsp == MACH_PORT_NULL)
    {
    debug("Using task_for_pid. Please make sure you've platformized me..\n");
    
    if (getuid()) {
        error ("I have to run as root\n");
    }

    amfidPid  = findPidOfProcess("amfid");
    if (!amfidPid) { error ("I can't find amfid!\n"); }
    
    g_AmfidPort = MACH_PORT_NULL;
    
    kern_return_t kr = task_for_pid (mach_task_self(),
                     amfidPid,
                     &g_AmfidPort);

    if (kr != KERN_SUCCESS) { error("Can't get amfid's task port\n"); exit(12); }
    else { status("GOT AMFID (PID %d)'s  PORT %d\n", amfidPid,  g_AmfidPort); }
    }

    castrateAmfid(g_AmfidPort);

    // Main thread continues to listen for the off chance that amfid will be killed -
    // yes, people - it can happen - either due to a bug of mine, but more likely
    // because launchd will be fed up with it being idle.
    // Anyway, in either case we need to redo this.


    pid_t pid = amfidPid; // PID to monitor
    int kq; // The kqueue file descriptor int rc; // collecting return values int done;

    getKqueueForPid (amfidPid);


    for (;;) {

        kq = getKqueueForPid(amfidPid);
        struct kevent ke;
        memset(&ke, '\0', sizeof(struct kevent));
        // This blocks until an event matching the filter occurs
        rc = kevent(kq, NULL, 0, &ke, 1, NULL);

        if (rc >= 0) {
        // Don't really care about the kevent - we know it's only because AMFI's dead

        close (kq);
        status ("AMFI has died!\n");
        // TODO: Hook launchd, because it will respawn amfid. Though that's a pain
        
        pid_t new_amfidPid = findPidOfProcess("amfid");
        while (! new_amfidPid) {
        sleep(1);
            new_amfidPid = findPidOfProcess("amfid");
        }

        amfidPid = new_amfidPid;
        kern_return_t kr = task_for_pid (mach_task_self(),
                     amfidPid,
                     &g_AmfidPort);

        castrateAmfid (g_AmfidPort);
    
    
        status("*Sigh* Long live amfi - %d... ZZzzz\n", amfidPid);

        }
    } // end for

}

#else

int mainamfi2 (int argc, char **argv) {
    OUT =stderr;
    unsigned char *h = cdHashOfFile(argv[1], ALGORITHM_SHA256);

    
    printf("HERE\n");

    if (h) {
        printf("Hash : 0x%x 0x%x...0x%x\n", h[0],  h[1], h[31]);
    }
            

    return 0;


}

#endif
