///////////////////////////////////////////////////////////////////////////////
//
//  File      : UsbDeviceEnumeration_Exports.h
//  Library   : libUsbDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Import/export macros for the USB enumeration SDK; also pulls in
//    IUsbDevices.h.
//
//  Usage:
//    Include this header to use the USB enumeration API.
//
//

#ifndef USBDEVICEENUMERATION_EXPORT_H
#define USBDEVICEENUMERATION_EXPORT_H

/**
 * @file UsbDeviceEnumeration_Exports.h
 * @brief Declares the export/import symbols and common dependencies for the USB enumeration module.
 */

#ifdef _WIN32
#include <windows.h>
#include <objbase.h>
#ifdef USBDEVICEENUMERATION_EXPORTS
/**
 * @brief Exports the USB device enumeration symbols from the Windows DLL.
 */
#define USBDEVICEENUMERATION __declspec(dllexport)
#else
/**
 * @brief Imports the USB device enumeration symbols from the Windows DLL.
 */
#define USBDEVICEENUMERATION __declspec(dllimport)
#endif

#elif defined(__linux__)
/**
 * @brief Exports the USB device enumeration symbols on Linux builds.
 */
#define USBDEVICEENUMERATION __attribute__((visibility("default")))
#endif

// Include additional required headers (inside guard to avoid circular includes)
#include <list>
#include "UsbDeviceEnumeration_Enums.h"
#include "IUsbDevices.h"

#endif /* USBDEVICEENUMERATION_EXPORT_H */

// Declared here as well so this header also compiles when it is included
// from I*.h, before that header has declared the namespace.
namespace UsbDeviceEnumeration {}

// Extern "C" block for ensuring C linkage when including the SDK in C code
extern "C" {
	/**
	 * @brief Imports the USB device enumeration namespace for C-compatible consumers.
	 */
	using namespace UsbDeviceEnumeration;
}
