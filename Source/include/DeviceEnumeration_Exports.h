///////////////////////////////////////////////////////////////////////////////
//
//  File      : DeviceEnumeration_Exports.h
//  Library   : libDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Import/export (visibility) macros for the DeviceEnumeration SDK.
//
//  Usage:
//    Included by IDeviceEnumerator.h; not used directly.
//
//

/**
 * @file DeviceEnumeration_Exports.h
 * @brief Declares the export/import symbols for the DeviceEnumeration module.
 */

#ifndef DEVICEENUMERATION_EXPORT_H
#define DEVICEENUMERATION_EXPORT_H

#ifdef _WIN32
    #include <windows.h>
    #include <objbase.h>
    #ifdef DEVICEENUMERATION_EXPORTS
        /**
         * @brief Exports DeviceEnumeration symbols from a Windows DLL.
         */
        #define DEVICEENUMERATION __declspec(dllexport)
    #else
        /**
         * @brief Imports DeviceEnumeration symbols from a Windows DLL.
         */
        #define DEVICEENUMERATION __declspec(dllimport)
    #endif
#else
    /**
     * @brief Exports DeviceEnumeration symbols on non-Windows builds.
     */
    #define DEVICEENUMERATION __attribute__((visibility("default")))
#endif

#endif // DEVICEENUMERATION_EXPORT_H
