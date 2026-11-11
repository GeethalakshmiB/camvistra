///////////////////////////////////////////////////////////////////////////////
//
//  File      : Routecam_Exports.h
//  Library   : libRoutecamSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Import/export macros for the Routecam ONVIF SDK.
//
//  Usage:
//    Included by IRoutecamOnvif.h; not used directly.
//
//

#ifndef ROUTECAMONVIFSDK_EXPORT_H
#define ROUTECAMONVIFSDK_EXPORT_H
#ifdef _WIN32
#ifdef ROUTECAMONVIFSDK_EXPORTS
/**
 * @brief Exports Routecam ONVIF symbols from a Windows DLL.
 */
#define ROUTECAMONVIFSDK __declspec(dllexport)
#else
/**
 * @brief Imports Routecam ONVIF symbols from a Windows DLL.
 */
#define ROUTECAMONVIFSDK __declspec(dllimport)
#endif
#if 0 /* DEFINE_NO_DEPRECATED */
#ifndef ROUTECAMSDK_NO_DEPRECATED
#define ROUTECAMSDK_NO_DEPRECATED
#endif
#endif
#elif __linux__
/**
 * @brief Exports Routecam ONVIF symbols on Linux builds.
 */
#define ROUTECAMONVIFSDK __attribute__((visibility("default")))
#endif
#endif /* ROUTECAMONVIFSDK_EXPORT_H */
