///////////////////////////////////////////////////////////////////////////////
//
//  File      : IE-cam82_UVC.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    e-CAM82_USB extension-unit controls (firmware version, reset).
//
//  Usage:
//    auto cam = eCamSDK::IEcam82_USB::create();
//    cam->initialize(...);           // Windows: initUVCExtension(path)
//    cam->readFirmwareVersion(...);  cam->resetDevice();
//
//

/** @file IE-cam82_UVC.h @brief Declares the IEcam82_USB interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"

#ifdef _WIN32
EXTERN_C const GUID GUID_EXTENSION_UNIT_eCAM82_USB; // Stores guid extension unit e cam82 usb.
#elif __linux__
#include <linux/uvcvideo.h>
#include <linux/videodev2.h>
#endif
#include <string>
#include <cstring>

using namespace logSDK;

namespace eCamSDK {
  /**
   * @brief Abstract interface for the Ecam82_USB camera controls.
   *
   * Applications should hold the camera through this interface and obtain an
   * instance with IEcam82_USB::create(), instead of using Ecam82_USB directly.
   */
  class CAMSDK IEcam82_USB {
  public:
      /** @brief Releases the camera controller. */
      virtual ~IEcam82_USB() = default;

      /**
       * @brief Creates the Ecam82_USB implementation.
       * @return Owning pointer to a newly created Ecam82_USB instance.
       */
      static std::unique_ptr<IEcam82_USB> create();

#ifdef _WIN32
      /** @brief Opens the UVC extension unit for a device path. @param srcPath Windows device path. @return true on success. */
      virtual bool initUVCExtension(const wchar_t* srcPath) = 0;
#elif __linux__
      /** @brief Associates an open video descriptor with the UVC extension unit. @param fd Video descriptor. @return 0 on success. */
      virtual int initialize(int fd) = 0;
#endif

    /** @brief Retrieves read firmware version. */
    virtual bool readFirmwareVersion(std::string& firmwareVer) = 0;
    /** @brief Performs reset device. */
    virtual bool resetDevice() = 0;
  };

}  // namespace eCamSDK
