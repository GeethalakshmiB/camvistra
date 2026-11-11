///////////////////////////////////////////////////////////////////////////////
//
//  File      : Routecam_Enums.h
//  Library   : libRoutecamSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Data structures and enums used by the Routecam ONVIF API.
//
//  Usage:
//    Included by IRoutecamOnvif.h; no functions to call.
//
//

/**
 * @file Routecam_Enums.h
 * @brief Shared data structures and enumerations used by the Routecam ONVIF API.
 */

#pragma once

#define MAX_PATH 260

#include <map>

// struct ImageProperty
// {
// 	char Compression[5];
// 	int width;
// 	int height;
// 	int fps;
// };

/**
 * @brief Enumerates the camera quality settings exposed by the Routecam API.
 */
typedef enum {
	GOPSIZE,
	VIDEO_BITRATE_MODE,
	BITRATE,
	I_FRAME_QP,
	MIN_QP,
	MAX_QP
} QualitySettings;

/**
 * @brief Stores the min, max, and current values for a quality setting.
 */
struct QualitySettingsRange {
	/** Identifier for the quality setting. */
	int id{};
	/** Current configured value. */
	int current{};
	/** Minimum supported value. */
	int min{};
	/** Maximum supported value. */
	int max{};
};

enum CameraProperty {
	PropertyBrightness = 0,
	PropertySaturation,
	PropertyContrast,
	PropertySharpness,
	PropertyExposureAuto,
	PropertyExposureTime,
	PropertyAntiFlicker,
	PropertyMaxExposureTime,
	PropertyMinExposureTime,
	PropertyGain,
	PropertyWhiteBalanceAuto,
	PropertyWhitBalanceYrGain,
	PropertyWhitBalanceYbGain,
	PropertyWDR,
	PropertyBackLightCompensation
};

/**
 * @brief Contains the core device identity information reported by the ONVIF camera.
 */
struct DeviceInfo {
	/** Device manufacturer name. */
	char manufacturer[128];
	/** Camera model name. */
	char name[128];
	/** Firmware revision string. */
	char firmwareVersion[128];
	/** Device serial number string. */
	char serialNumber[128];
	/** Hardware identifier or product code. */
	char hardwareId[128];
};

/**
 * @brief Stores the network settings for a camera interface.
 */
struct NetworkInterface {
	/** Indicates whether DHCP is enabled for the interface. */
	bool DHCP;
	/** Interface IP address string. */
	char ipAddress[32];
	/** Interface subnet mask string. */
	char subnetMask[32];
	/** Gateway address string. */
	char gateway[32];
};

/**
 * @brief Stores the default camera configuration values for each supported property.
 */
struct CameraConfigDefault {
	/** Mapping from camera property to its default value. */
	std::map<CameraProperty, int> defaultCameraPropertyValues;
};
