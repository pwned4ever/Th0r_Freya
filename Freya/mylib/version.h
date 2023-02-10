//===---------------------------- version.h -------------------------------===//
//
//                                Img4Helper
//
// 	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
// 	but WITHOUT ANY WARRANTY; without even the implied warranty of
// 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// 	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
// 	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===-----------------------------------------------------------------------===//

#ifndef IMG4HELPER_VERSION_H
#define IMG4HELPER_VERSION_H

#ifdef __APPLE__
#   define BUILD_TARGET         "darwin"
#   define BUILD_TARGET_CAP     "Darwin"
#else
#   define BUILD_TARGET         "linux"
#   define BUILD_TARGET_CAP     "Linux"
#endif

#ifdef __x86_64__
#   define BUILD_ARCH           "x86_64"
#elif __arm__
#   define BUILD_ARCH           "arm64"
#endif

#define IMG4HELPER_VERSION_NUMBER    "1.0.0"
#define IMG4HELPER_VERSION_TAG       "Release"

#define IMG4HELPER_DEBUG             1

#endif /* img4helper_version_h */