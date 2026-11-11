///////////////////////////////////////////////////////////////////////////////
//
//  File      : IDensiCAM.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    DensiCAM controls: exposure, white balance, gain, gamma, image
//    tuning, LED, capture mode, firmware update and config save.
//
//  Usage:
//    auto cam = eCamSDK::IDensiCAM::create();
//    cam->initialize(fd);            // Windows: initUVCExtension(path)
//    cam->get...() / cam->set...()
//
//

/** @file IDensiCAM.h @brief Declares the IDensiCAM interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>
#include <cstring>
#include <functional>
#include <thread>
#include <atomic>

#ifdef _WIN32
EXTERN_C const GUID GUID_EXTENSION_UNIT_DensiCAM; // Stores guid extension unit densi cam.
#elif __linux__
#include <linux/uvcvideo.h>
#include <linux/videodev2.h>
#endif


using namespace logSDK;

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

enum class DensiCAMImageCapture : uint8_t {
	ButtonCaptureSoftware = 0x01,
	TwainCamVistra = 0x02
};

enum class DensiCAMSceneMode : uint8_t {
	Intraoral = 0x01,
	Face = 0x02
};

enum class HidEventType
{
	NONE = 0,
	VIDEO_RECORD_TOGGLE,
	IMAGE_CAPTURE,
	BUTTON_CAPTURE
};

using HidEventCallback = std::function<void(HidEventType)>;

// ----------------------------------------------------------------
// Output structs
// ----------------------------------------------------------------

struct DensiCAMControlRange {
	uint8_t min;  // Minimum value the control accepts
	uint8_t max;  // Maximum value the control accepts
	uint8_t def;  // Factory default value of the control
	uint8_t cur;  // Current value read back from the device
	uint8_t res;  // Step/resolution between valid values
};

struct DensiCAMControlRange16 {
	uint16_t min;  // Minimum value the control accepts
	uint16_t max;  // Maximum value the control accepts
	uint16_t def;  // Factory default value of the control
	uint16_t cur;  // Current value read back from the device
	uint16_t res;  // Step/resolution between valid values
};

struct DensiCAMControlRange32 {
	uint32_t min;  // Minimum value the control accepts
	uint32_t max;  // Maximum value the control accepts
	uint32_t def;  // Factory default value of the control
	uint32_t cur;  // Current value read back from the device
	uint32_t res;  // Step/resolution between valid values
};

struct DensiCAMUniqueID {
	uint32_t part1;  // First (high) 32 bits of the device's 64-bit unique ID
	uint32_t part2;  // Second (low) 32 bits of the device's 64-bit unique ID
};

namespace eCamSDK {

	/**
	 * @brief Abstract interface for the DensiCAM camera controls.
	 *
	 * Applications should hold the camera through this interface and obtain an
	 * instance with IDensiCAM::create(), instead of using DensiCAM directly.
	 */
	class CAMSDK IDensiCAM {
	public:
		/** @brief Releases the camera controller. */
		virtual ~IDensiCAM() = default;

		/**
		 * @brief Creates the DensiCAM implementation.
		 * @return Owning pointer to a newly created DensiCAM instance.
		 */
		static std::unique_ptr<IDensiCAM> create();

#ifdef __linux__
		/** @brief Associates an open video descriptor with the UVC extension unit. @param fd Video descriptor. @return 0 on success. */
		virtual int initialize(int fd) = 0;
#endif
#ifdef _WIN32
		/** @brief Opens the UVC extension unit for a Windows device path. @param srcPath Device path. @return true on success. */
		virtual bool initUVCExtension(const wchar_t* srcPath) = 0;
#endif

		/** @brief Sets set hid event callback. */
		virtual void setHidEventCallback(HidEventCallback cb) = 0;

		/** @brief Performs set hid fd. */
		virtual bool setHidFd(int fd) = 0;

#ifdef _WIN32
		/** @brief Initializes init from device path. */
		virtual bool initFromDevicePath(TCHAR *devicePath) = 0;
		/** @brief Performs deinit extension unit. */
		virtual void deinitExtensionUnit() = 0;
#endif

		// ---- Common Controls ----
		/** @brief Performs read firmware version. */
		virtual bool readFirmwareVersion(std::string& outVersion) = 0;
		/** @brief Retrieves get unique id. */
		virtual bool getUniqueID(DensiCAMUniqueID& outUID) = 0;
		/** @brief Performs device reset. */
		virtual bool deviceReset() = 0;
		/** @brief Performs trigger firmware update. */
		virtual bool triggerFirmwareUpdate() = 0;
		/** @brief Performs send oscode. */
		virtual bool sendOSCode(bool isLinux, uint8_t& outStatus) = 0;

		// ---- Extension Controls (Control ID: 0x06) ----
		/** @brief Performs get pixel target value. */
		virtual bool getPixelTargetValue(uint16_t& outValue, uint8_t& outStatus) = 0;
		/** @brief Sets set pixel target value. */
		virtual bool setPixelTargetValue(uint16_t value) = 0;
		/** @brief Retrieves get denoise value. */
		virtual bool getDenoiseValue(uint8_t& outValue, uint8_t& outStatus) = 0;
		/** @brief Sets set denoise value. */
		virtual bool setDenoiseValue(uint8_t value) = 0;
		/** @brief Retrieves get orientation. */
		virtual bool getOrientation(uint8_t& outValue, uint8_t& outStatus) = 0;
		/** @brief Performs set orientation. */
		virtual bool setOrientation(uint8_t value) = 0;
		/** @brief Performs reset device. */
		virtual bool resetDevice() = 0;
		/** @brief Performs restore defaults. */
		virtual bool restoreDefaults() = 0;

		// ---- Command Controls (Control ID: 0x07) ----
		/** @brief Performs get brightness. */
		virtual bool getBrightness(DensiCAMControlRange& outRange, uint8_t& outStatus) = 0;
		/** @brief Sets set brightness. */
		virtual bool setBrightness(uint8_t value) = 0;
		/** @brief Retrieves get contrast. */
		virtual bool getContrast(DensiCAMControlRange& outRange, uint8_t& outStatus) = 0;
		/** @brief Sets set contrast. */
		virtual bool setContrast(uint8_t value) = 0;
		/** @brief Retrieves get saturation. */
		virtual bool getSaturation(DensiCAMControlRange& outRange, uint8_t& outStatus) = 0;
		/** @brief Performs set saturation. */
		virtual bool setSaturation(uint8_t value) = 0;
		/** @brief Retrieves get sharpness. */
		virtual bool getSharpness(DensiCAMControlRange& outRange, uint8_t& outStatus) = 0;
		/** @brief Sets set sharpness. */
		virtual bool setSharpness(uint8_t value) = 0;
		/** @brief Retrieves get gamma. */
		virtual bool getGamma(DensiCAMControlRange16& outRange, uint8_t& outStatus) = 0;
		/** @brief Sets set gamma. */
		virtual bool setGamma(uint16_t value) = 0;
		/** @brief Performs get manual white balance. */
		virtual bool getManualWhiteBalance(DensiCAMControlRange16& outRange, uint8_t& outStatus) = 0;
		/** @brief Sets set manual white balance. */
		virtual bool setManualWhiteBalance(uint16_t value) = 0;
		/** @brief Retrieves get auto white balance. */
		virtual bool getAutoWhiteBalance(uint8_t& outValue, uint8_t& outStatus) = 0;
		/** @brief Sets set auto white balance. */
		virtual bool setAutoWhiteBalance(uint8_t value) = 0;
		/** @brief Retrieves get gain. */
		virtual bool getGain(DensiCAMControlRange& outRange, uint8_t& outStatus) = 0;
		/** @brief Performs set gain. */
		virtual bool setGain(uint8_t value) = 0;
		/** @brief Retrieves get manual exposure. */
		virtual bool getManualExposure(DensiCAMControlRange32& outRange, uint8_t& outStatus) = 0;
		/** @brief Sets set manual exposure. */
		virtual bool setManualExposure(uint32_t value) = 0;
		/** @brief Retrieves get auto exposure. */
		virtual bool getAutoExposure(uint8_t& outValue, uint8_t& outStatus) = 0;
		/** @brief Sets set auto exposure. */
		virtual bool setAutoExposure(uint8_t value) = 0;
		/** @brief Performs get led. */
		virtual bool getLED(uint8_t& outValue, uint8_t& outStatus) = 0;
		/** @brief Sets set led. */
		virtual bool setLED(uint8_t value) = 0;
		/** @brief Performs save configuration. */
		virtual bool saveConfiguration() = 0;
		/** @brief Retrieves get image capture mode. */
		virtual bool getImageCaptureMode(uint8_t& outMode, uint8_t& outStatus) = 0;
		/** @brief Sets set image capture mode. */
		virtual bool setImageCaptureMode(DensiCAMImageCapture mode) = 0;
		/** @brief Performs get scene mode. */
		virtual bool getSceneMode(uint8_t& outMode, uint8_t& outStatus) = 0;
		/** @brief Sets set scene mode. */
		virtual bool setSceneMode(DensiCAMSceneMode mode) = 0;
	};

} // namespace eCamSDK
