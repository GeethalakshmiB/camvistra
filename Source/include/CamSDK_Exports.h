///////////////////////////////////////////////////////////////////////////////
//
//  File      : CamSDK_Exports.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Import/export (visibility) macros for the camera SDK.
//
//  Usage:
//    Included by every camera interface header; not used directly.
//
//

/** @file CamSDK_Exports.h
 * @brief Defines CAMSDK import and export visibility macros. */
#ifndef CAMSDK_EXPORT_H
#define CAMSDK_EXPORT_H

#ifdef _WIN32
  #ifdef CAMSDK_EXPORTS
    #define CAMSDK __declspec(dllexport)
  #else
    #define CAMSDK __declspec(dllimport)
  #endif
#elif __linux__
  #define CAMSDK __attribute__((visibility("default")))
#else
  #define CAMSDK
#endif

#endif /* CAMSDK_EXPORT_H */
