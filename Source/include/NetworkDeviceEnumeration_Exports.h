///////////////////////////////////////////////////////////////////////////////
//
//  File      : NetworkDeviceEnumeration_Exports.h
//  Library   : libNetworkDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Import/export macros for the network enumeration SDK; also pulls
//    in INetworkDevices.h.
//
//  Usage:
//    Include this header to use the network enumeration API.
//
//

#ifndef NETWORKDEVICEENUMERATION_EXPORT_H
#define NETWORKDEVICEENUMERATION_EXPORT_H

/**
 * @file NetworkDeviceEnumeration_Exports.h
 * @brief Declares the import/export macros and shared dependencies for the network enumeration module.
 */

#ifdef _WIN32
#include <windows.h>
#include <objbase.h>
#ifdef NETWORKDEVICEENUMERATION_EXPORTS
/**
 * @brief Exports network enumeration symbols from a Windows DLL.
 */
#define NETWORKDEVICEENUMERATION __declspec(dllexport)
#else
/**
 * @brief Imports network enumeration symbols from a Windows DLL.
 */
#define NETWORKDEVICEENUMERATION __declspec(dllimport)
#endif

#elif defined(__linux__)
/**
 * @brief Exports network enumeration symbols on Linux builds.
 */
#define NETWORKDEVICEENUMERATION __attribute__((visibility("default")))
#endif

#endif /* NETWORKDEVICEENUMERATION_EXPORT_H */

// Include additional required headers
#include <list>
#include "NetworkDeviceEnumeration_Enums.h"
#include "INetworkDevices.h"

// Declared here as well so this header also compiles when it is included
// from I*.h, before that header has declared the namespace.
namespace NetworkDeviceEnumeration {}

// Extern "C" block for ensuring C linkage when including the SDK in C code
extern "C" {
	/**
	 * @brief Exposes the NetworkDeviceEnumeration namespace to C-compatible consumers.
	 */
	using namespace NetworkDeviceEnumeration;
}
