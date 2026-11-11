///////////////////////////////////////////////////////////////////////////////
//
//  File      : AudioDeviceEnumeration_Exports.h
//  Library   : libAudioDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Import/export macros for the audio enumeration SDK; also pulls in
//    IAudioDevices.h.
//
//  Usage:
//    Include this header to use the audio enumeration API.
//
//

#ifndef AUDIODEVICEENUMERATION_EXPORT_H
#define AUDIODEVICEENUMERATION_EXPORT_H

/**
 * @file AudioDeviceEnumeration_Exports.h
 * @brief Declares the export/import macros and shared dependencies for the audio enumeration module.
 */

#ifdef _WIN32
#include <windows.h>
#include <objbase.h>
#ifdef AUDIODEVICEENUMERATION_EXPORTS
/**
 * @brief Exports the audio enumeration symbols from the Windows DLL.
 */
#define AUDIODEVICEENUMERATION __declspec(dllexport)
#else
/**
 * @brief Imports the audio enumeration symbols from the Windows DLL.
 */
#define AUDIODEVICEENUMERATION __declspec(dllimport)
#endif

#elif defined(__linux__)
/**
 * @brief Exports the audio enumeration symbols on Linux builds.
 */
#define AUDIODEVICEENUMERATION __attribute__((visibility("default")))
#endif

// Include additional required headers (inside guard to avoid circular includes)
#include <list>
#include "AudioDeviceEnumeration_Enums.h"
#include "IAudioDevices.h"

#endif /* AUDIODEVICEENUMERATION_EXPORT_H */

// Declared here as well so this header also compiles when it is included
// from I*.h, before that header has declared the namespace.
namespace AudioDeviceEnumeration {}

// Extern "C" block for ensuring C linkage when including the SDK in C code
extern "C" {
	/**
	 * @brief Imports the audio enumeration namespace for C-compatible consumers.
	 */
	using namespace AudioDeviceEnumeration;
}
