//
//  ArchiveUtils.h
//  Slice
//
//  Created by Tanay Findley on 5/9/19.
//  Copyright © 2019 Slice Team. All rights reserved.
//

#ifndef ArchiveUtils_h
#define ArchiveUtils_h

#include <stdio.h>
#include <Foundation/Foundation.h>

void extractFile(NSString *fileToExtract, NSString *pathToExtractTo);
void extractSliceFile(NSString *fileToExtract);
void extractFileWithoutInjection(NSString *fileToExtract, NSString *pathToExtractTo);

#endif /* ArchiveUtils_h */
