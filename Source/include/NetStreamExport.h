///////////////////////////////////////////////////////////////////////////////
//
//  File      : NetStreamExport.h
//  Library   : libNetStreamSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Import/export macros for the network streaming SDK.
//
//  Usage:
//    Included by INetStream.h; not used directly.
//
//

/** @file NetStreamExport.h @brief Defines NetStreamSDK import and export macros. */
#ifndef NETSTREAM_EXPORT_H
#define NETSTREAM_EXPORT_H
#ifdef _WIN32
#ifdef NETSTREAM_EXPORTS
#define NETSTREAM_API __declspec(dllexport)
#else
#define NETSTREAM_API __declspec(dllimport)
#endif
#if 0 /* DEFINE_NO_DEPRECATED */
#ifndef NETSTREAM_API_NO_DEPRECATED
#define NETSTREAM_API_NO_DEPRECATED
#endif
#endif
#elif __linux__
#define NETSTREAM_API __attribute__((visibility("default")))
#endif
#endif /* NETSTREAM_EXPORT_H */
