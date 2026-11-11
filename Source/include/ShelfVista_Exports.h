///////////////////////////////////////////////////////////////////////////////
//
//  File      : ShelfVista_Exports.h
//  Library   : libShelfVistaSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Import/export macros for the ShelfVista ONVIF SDK.
//
//  Usage:
//    Included by IShelfVistaOnvif.h; not used directly.
//
//

#ifndef SHELFVISTAONVIFSDK_EXPORT_H
#define SHELFVISTAONVIFSDK_EXPORT_H
#ifdef _WIN32
#include "ObjBase.h"


#ifdef SHELFVISTASDK_EXPORTS
#define SHELFVISTAONVIFSDK __declspec(dllexport)
#else
#define SHELFVISTAONVIFSDK __declspec(dllimport)
#endif
#if 0 /* DEFINE_NO_DEPRECATED */
#ifndef SHELFVISTASDK_NO_DEPRECATED
#define SHELFVISTASDK_NO_DEPRECATED
#endif
#endif
#elif __linux__
#define SHELFVISTAONVIFSDK __attribute__((visibility("default")))
#endif
#endif /* SHELFVISTAONVIFSDK_EXPORT_H */
