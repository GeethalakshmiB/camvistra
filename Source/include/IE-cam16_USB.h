///////////////////////////////////////////////////////////////////////////////
//
//  File      : IE-cam16_USB.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    e-CAM16_USB extension-unit controls (firmware version).
//
//  Usage:
//    auto cam = eCamSDK::IEcam16_USB::create();
//    cam->initialize(fd);            // Windows: initUVCExtension(path)
//    cam->readFirmwareVersion(...);
//
//

/** @file IE-cam16_USB.h @brief Declares the IEcam16_USB interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"

#ifdef _WIN32
#include <windows.h>
#include <setupapi.h>
#include <initguid.h>
#include <usbiodef.h>
#pragma comment(lib, "setupapi.lib")

#elif __linux__
#include <linux/uvcvideo.h>
#include <linux/videodev2.h>
#include <linux/usb/ch9.h>
#include <linux/usbdevice_fs.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <cerrno>
#include <cstring>
#endif

#include <string>
#include <sstream>
#include <iomanip>
#include <algorithm>

using namespace logSDK;

namespace eCamSDK {

	/**
	 * @brief Abstract interface for the Ecam16_USB camera controls.
	 *
	 * Applications should hold the camera through this interface and obtain an
	 * instance with IEcam16_USB::create(), instead of using Ecam16_USB directly.
	 */
	class CAMSDK IEcam16_USB {
	public:
		/** @brief Releases the camera controller. */
		virtual ~IEcam16_USB() = default;

		/**
		 * @brief Creates the Ecam16_USB implementation.
		 * @return Owning pointer to a newly created Ecam16_USB instance.
		 */
		static std::unique_ptr<IEcam16_USB> create();

		// â”€â”€ Platform init â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#ifdef _WIN32
		// Parse VID/PID from srcPath, enumerate SetupAPI, cache REV_ as bcdDevice
		/** @brief Performs init uvcextension. */
		virtual bool initUVCExtension(const wchar_t* srcPath) = 0;

#elif __linux__
		// Store the already-opened file descriptor
		/** @brief Initializes initialize. */
		virtual int initialize(const char* videoPath) = 0;
#endif

		// â”€â”€ Public API â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

		// Windows : decodes cachedBcdDevice (set during initUVCExtension)
		// Linux   : issues GET_DESCRIPTOR via ioctl on fileDescriptor
		// Result  : firmwareVer formatted as "MM.mm" e.g. "50.10"
		/** @brief Performs read firmware version. */
		virtual bool readFirmwareVersion(std::string& firmwareVer) = 0;
	};

} // namespace eCamSDK
