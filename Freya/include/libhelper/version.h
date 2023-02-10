//===---------------------------- version ----------------------------===//
//
//                         The Libhelper Project
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===------------------------------------------------------------------===//

#ifndef LIBHELPER_VERSION_H
#define LIBHELPER_VERSION_H

/***********************************************************************
* Libhelper Version.
*
*   Four definitions for Libhelper version info. The long version string
*   has a similar format to XNU's versioning. There is then a more human
*   readable "marketing" version number with a traditional Major.Minor.Rev
*   format, and finally two more definitions with the version Tag both
*   normal and capatalised.
*
***********************************************************************/

#define LIBHELPER_VERSION_LONG              "libhelper-1100.234.56.34~1"
#define LIBHELPER_VERSION_SHORT             "1.1.0"
#define LIBHELPER_VERSION_TAG               "Development"
#define LIBHELPER_VERSION_TAG_CAPS          "DEVELOPMENT"


/***********************************************************************
* Libhelper Platform.
*
*   The platform type, either "Darwin" for macOS/iOS et al. And "Linux"
*   for Linux-based systems. Only the correct one is defined, based on
*   the system used to compile Libhelper.
*
***********************************************************************/

#ifdef __APPLE__
#   define LIBHELPER_PLATFORM               "Darwin"
#else
#   define LIBHELPER_PLATFORM               "Linux"
#endif


/***********************************************************************
* Libhelper Architecture String.
*
*   The architecture type, either x86_64, arm64 or arm. It's prepended
*   with the long version, and the version tag. Only the correct one
*   is defined and is based on the system used to compile Libhelper.
*
***********************************************************************/

#ifdef __x86_64__
#   define LIBHELPER_VERS_WITH_ARCH     LIBHELPER_VERSION_LONG "/" LIBHELPER_VERSION_TAG_CAPS "_X86_64 x86_64"
#elif __arm__
#   define LIBHELPER_VERS_WITH_ARCH     LIBHELPER_VERSION_LONG "/" LIBHELPER_VERSION_TAG_CAPS "_ARM arm"
#elif __arm64__
#   define LIBHELPER_VERS_WITH_ARCH     LIBHELPER_VERSION_LONG "/" LIBHELPER_VERSION_TAG_CAPS "_ARM64 arm64"
#else 
#   define LIBHELPER_VERS_WITH_ARCH     LIBHELPER_VERSION_LONG "/" LIBHELPER_VERSION_TAG_CAPS "_NA unknown_architecture"
#endif

#endif /* libhelper_version_h */