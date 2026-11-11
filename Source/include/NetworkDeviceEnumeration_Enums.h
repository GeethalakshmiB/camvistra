///////////////////////////////////////////////////////////////////////////////
//
//  File      : NetworkDeviceEnumeration_Enums.h
//  Library   : libNetworkDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Shared enums and compatibility definitions for network enumeration.
//
//  Usage:
//    Included internally; no functions to call.
//
//

/**
 * @file NetworkDeviceEnumeration_Enums.h
 * @brief Shared enums and compatibility definitions for the network enumeration module.
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

//struct DeviceDetails {
//    char DeviceName[MAX_PATH];      // Common: Human-readable name (e.g., "RouteCam-123", "LogiCam USB")
//    char DeviceIP[MAX_PATH];         // Network: IP address (e.g., "192.168.1.5")
//    char type[32];             // Common: "Ethernet", "Wi-Fi", "USB", etc.
//
//    // USB-specific fields
//    char vid[8];               // USB Vendor ID (e.g., "046D")
//    char pid[8];               // USB Product ID (e.g., "0825")
//    char devicePath[256];      // USB Device node or system path (e.g., "/dev/video0")
//    char serialNo[64];        // USB Serial Number (if available)
//};

/**
 * @brief Stores the runtime address and mask information for a network adapter.
 */
struct AdapterInfo {
	/** IPv4 address in network byte order. */
	uint32_t ip;
	/** IPv4 subnet mask in network byte order. */
	uint32_t mask;
	/** Connection type reported by the host OS, such as Ethernet or Wi-Fi. */
	std::string type;
};
