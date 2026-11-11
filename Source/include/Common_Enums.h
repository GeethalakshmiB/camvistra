///////////////////////////////////////////////////////////////////////////////
//
//  File      : Common_Enums.h
//  Library   : libLogger.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Shared enums (Result codes, camera types, ...) used by every SDK.
//
//  Usage:
//    Included through ILogger.h; no functions to call.
//
//

/**
 * @file Common_Enums.h
 * @brief Shared enum definitions used across the logging and camera libraries.
 */

/**
 * @brief Names of the supported camera types.
 */

#pragma once

typedef enum
{
    /** No camera type is selected. */
    NONE = 0,
    /** Integrated camera device. */
    INTEGRATED_CAM,
    /** E-Cam 212 USB camera. */
    E_CAM212_USB
} ECameraNames;

/**
 * @brief Result codes returned by camera and logger operations.
 */
typedef enum {
	/** Operation completed successfully. */
	Ok = 1,
	/** The APIs are not initialized. */
	Failed = -1,
	/** The device node is invalid. */
	InvalidDeviceUrl = -2,
	/** The camera has not been opened. */
	CameraNotOpened = -3,
	/** The camera is already opened. */
	CameraAlreadyOpened = -4,
	/** No device is connected. */
	NoDeviceConnected = -5,
	/** One or more parameter values are invalid. */
	InvalidValue = -6,
	/** I/O timed out while reading. */
	TimeoutError = -7,
	/** Device is not initialized. */
	DeviceNotInitialized = -8,
	/** Current instance is not initialized. */
	NotInitialized = -9,
	/** Stream information is invalid. */
	InvalidStreamInfo = -10,
	/** Decoder is invalid. */
	InvalidDecoder = -11,
	/** Codec is invalid. */
	InvalidCodec = -12,
	/** Null value was supplied. */
	NullValue = -13,
	/** The component is already initialized. */
	AlreadyInitialized = -14,
	/** An exception occurred. */
	Exception = -15,
	/** The file path is invalid. */
	InvalidFilePath = -16,
	/** A requested resource was not found. */
	NotFound = -17,
	/** The state was not de-initialized as expected. */
	NotDeInitialized = -18,
	/** The provided node is invalid. */
	InvalidNode = -19,
	/** The requested device index is invalid. */
	InvalidDeviceIndex = -20,
	/** An OS-level system call failed. */
	SysCallFail = -21,
	/** The device does not support the requested operation. */
	DeviceNotCapable = -22,
	/** Callback execution failed. */
	CallBackFailed = -23,
	/** Failed to read a property value. */
	PropertyValueGetFailed = -24,
	/** Failed to set a property value. */
	PropertyValueSetFailed = -25,
	/** The frame type is invalid. */
	InvalidFrameType = -26,
	/** No streaming session is active. */
	NoStreaming = -27,
	/** A streaming session is already active. */
	AlreadyStreaming = -28,
	/** HID write operation failed. */
	HidWriteFail = -29,
	/** HID read operation failed. */
	HidReadFail = -30,
	/** Unclassified generic error. */
	Others = -40,
	/** PulseAudio connection failed. */
	ErrorPAConnectFailed = -41,
	/** PulseAudio enumeration failed. */
	ErrorPAEnumerationFailed = -42
} Result;
