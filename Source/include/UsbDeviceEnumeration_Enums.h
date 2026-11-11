///////////////////////////////////////////////////////////////////////////////
//
//  File      : UsbDeviceEnumeration_Enums.h
//  Library   : libUsbDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Platform compatibility definitions for the USB enumeration SDK.
//
//  Usage:
//    Included internally; no functions to call.
//
//

/**
 * @file UsbDeviceEnumeration_Enums.h
 * @brief Platform compatibility definitions for the USB enumeration module.
 */

#pragma once

#define MAX_PATH 260
#ifdef __linux__
/**
 * @brief Compatibility typedef for Windows-style UINT on Linux builds.
 */
typedef unsigned int UINT;
#endif

#include <string>
#include "ILogger.h"
