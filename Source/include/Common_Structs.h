///////////////////////////////////////////////////////////////////////////////
//
//  File      : Common_Structs.h
//  Library   : libLogger.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Shared data structures (Frame, ImageProperty, PropertyRange,
//    DeviceDetails, ...) used by every SDK.
//
//  Usage:
//    Included through ILogger.h; no functions to call.
//
//

/**
 * @file Common_Structs.h
 * @brief Shared data structures used by camera and logging interfaces.
 */

#pragma once

#include <vector>
#include <cstdint>
#include <iostream>

/**
 * @brief Describes the output characteristics of an image frame.
 */
struct ImageProperty {
	/** Compression format used for the image payload. */
	char Compression[8];
	/** Width of the decoded image in pixels. */
	int width;
	/** Height of the decoded image in pixels. */
	int height;
	/** Frames per second reported by the camera. */
	float fps;
	/** Indicates whether the image stream uses NV12 content instead of raw MJPEG. */
	bool isNV12Decoded;
};

/**
 * @brief Stores a frame buffer and metadata for one image plane.
 */
 struct FrameBuffer {
	/** Raw image bytes for the frame payload. */
	std::vector<unsigned char> frame_data;
	/** Width of the frame in pixels. */
	uint16_t width = 0;
	/** Height of the frame in pixels. */
	uint16_t height = 0;
	/** String representing the pixel format, such as RGB or YUYV. */
	char pixel_format[8];
	/** Total size of the frame payload in bytes. */
	uint32_t total_size;
} ;

/**
 * @brief Represents a pair of RGB and IR frame buffers.
 */
 struct Frame {
	/** RGB frame buffer. */
	FrameBuffer rgb, ir;
} ;

/**
 * @brief Captures supported property range information for a device control.
 */
  struct PropertyRange{
	/** Property identifier. */
	int id{};
	/** Minimum property value. */
	int min{};
	/** Maximum property value. */
	int max{};
	/** Current property value. */
	int cur{};
	/** Step size for adjustments. */
	int step{};
	/** Default property value. */
	int defaultVal{};
	/** Auto/manual property flag. */
	int automan{};
};

/**
 * @brief Contains information about a connected device.
 */
struct DeviceDetails {
	/** Device index as reported by the system. */
	int deviceIndex = 0;
	/** Human-readable device name. */
	char DeviceName[128];
	/** Device IP address when connected over a network. */
	char DeviceIP[128];
	/** Device type such as Ethernet, Wi-Fi, or USB. */
	char type[32];
	/** ALSA hardware identifier used for mixer operations. */
	char alsaHwId[32];

	/** USB vendor identifier. */
	char vid[8];
	/** USB product identifier. */
	char pid[8];
	/** USB device path or system node. */
	char devicePath[256];
	/** USB serial number when available. */
	char serialNo[64];
};
