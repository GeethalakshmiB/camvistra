////////////////////////////////////////////////////////////////////////////////
//
//  File      : AudioDeviceEnumeration_Enums.h
//  Library   : libAudioDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Shared compatibility definitions for audio enumeration.
//
//  Usage:
//    Included internally; no functions to call.
//
//

/**
 * @file AudioDeviceEnumeration_Enums.h
 * @brief Shared compatibility definitions for the audio enumeration module.
 */

#pragma once

#define MAX_PATH 260
#ifdef __linux__
/**
 * @brief Compatibility typedef used for Windows-style UINT definitions on Linux.
 */
typedef unsigned int UINT;
#endif

#include <string>
#include "ILogger.h"
