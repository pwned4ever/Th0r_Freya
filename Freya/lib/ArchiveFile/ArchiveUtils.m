//
//  ArchiveUtils.c
//  Slice
//
//  Created by Tanay Findley on 5/9/19.
//  Copyright © 2019 Slice Team. All rights reserved.
//

#include "ArchiveUtils.h"
#include "common.h"
#include "amfi_utils.h"
#include "ArchiveFile.h"
#include "utilsZS.h"


void extractFile(NSString *fileToExtract, NSString *pathToExtractTo)
{
    ArchiveFile *file2Extract = [ArchiveFile archiveWithFile:fileToExtract];
    [file2Extract extractToPath:pathToExtractTo];
    
    chdir("/");
    NSMutableArray *arrayToInject = [NSMutableArray new];
    NSDictionary *filesToInject = file2Extract.files;
    for (NSString *file in filesToInject.allKeys) {
        if (cdhashFor(file) != nil) {
            [arrayToInject addObject:file];
        }
    }
    util_info("Injecting...");
    for (NSString *fileToInject in arrayToInject)
    {
        if (![file2Extract isEqual:@"testbin"])
        {
            util_info("CURRENTLY INJECTING: %s", [fileToInject UTF8String]);
            trust_file(fileToInject);
        } else {
            LOG("SKIPPING testbin");
        }
    }
}

void extractFileWithoutInjection(NSString *fileToExtract, NSString *pathToExtractTo)
{
    ArchiveFile *file2Extract = [ArchiveFile archiveWithFile:fileToExtract];
    [file2Extract extractToPath:pathToExtractTo];
    chdir("/");
}


void extractSliceFile(NSString *fileToExtract)
{
    ArchiveFile *file2Extract = [ArchiveFile archiveWithFile:fileToExtract];
    [file2Extract extractToPath:@"/freya"];
    
    chdir("/");
    NSMutableArray *arrayToInject = [NSMutableArray new];
    NSDictionary *filesToInject = file2Extract.files;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtURL:[NSURL URLWithString:@"/freya"] includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:nil];
    _assert(directoryEnumerator != nil, @"Failed to enable SSH.", true);
    for (NSURL *URL in directoryEnumerator) {
        NSString *path = [URL path];
        if (cdhashFor(path) != nil) {
            if (![arrayToInject containsObject:path]) {
                [arrayToInject addObject:path];
            }
        }
    }
    
    LOG("Injecting...");
    for (NSString *fileToInject in arrayToInject)
    {
        LOG("CURRENTLY INJECTING: %@", fileToInject);
        trust_file(fileToInject);
    }
}
