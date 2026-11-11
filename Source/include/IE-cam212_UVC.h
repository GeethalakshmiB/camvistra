///////////////////////////////////////////////////////////////////////////////
//
//  File      : IE-cam212_UVC.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    e-CAM212_USB extension-unit controls: AE mode, HDR, flip, serial
//    number, exposure-compensation range, firmware version, reset.
//
//  Usage:
//    auto cam = eCamSDK::IEcam212_USB::create();
//    cam->initialize("/dev/videoN"); // Windows: initUVCExtension(path)
//    cam->get...() / cam->set...()
//
//

/** @file IE-cam212_UVC.h @brief Declares the IEcam212_USB interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"

#ifdef _WIN32
EXTERN_C const GUID GUID_EXTENSION_UNIT_eCAM212_USB; // Stores guid extension unit e cam212 usb.
#elif __linux__
#include <linux/uvcvideo.h>
#include <linux/videodev2.h>
#endif
#include <string>
#include <cstring>

using namespace logSDK;

namespace eCamSDK {
  /**
   * @brief Abstract interface for the Ecam212_USB camera controls.
   *
   * Applications should hold the camera through this interface and obtain an
   * instance with IEcam212_USB::create(), instead of using Ecam212_USB directly.
   */
  class CAMSDK IEcam212_USB {
  public:
      /** @brief Releases the camera controller. */
      virtual ~IEcam212_USB() = default;

      /**
       * @brief Creates the Ecam212_USB implementation.
       * @return Owning pointer to a newly created Ecam212_USB instance.
       */
      static std::unique_ptr<IEcam212_USB> create();

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
    /** @brief Performs read serial number. */
    virtual bool readSerialNumber(std::string& serialNum) = 0;
    /** @brief Performs writ serial number. */
    virtual bool writSerialNumber(const std::string& serialNum) = 0;
    /** @brief Retrieves read exposure compensation min. */
    virtual bool readExposureCompensationMin(PropertyRange* gControlValue) = 0;
    /** @brief Sets write exposure compensation min. */
    virtual bool writeExposureCompensationMin(int value) = 0;
    /** @brief Retrieves read exposure compensation max. */
    virtual bool readExposureCompensationMax(PropertyRange* gControlValue) = 0;
    /** @brief Performs write exposure compensation max. */
    virtual bool writeExposureCompensationMax(int value) = 0;
    /** @brief Retrieves get hdr. */
    virtual bool getHDR(bool* flag) = 0;
    /** @brief Sets set hdr. */
    virtual bool setHDR(bool flag) = 0;
    /** @brief Retrieves get aemode. */
    virtual bool getAEMode(int* mode) = 0;
    /** @brief Sets set aemode. */
    virtual bool setAEMode(int mode) = 0;
    /** @brief Performs read horizontal flip. */
    virtual bool readHorizontalFlip(bool* value) = 0;
    /** @brief Sets write horizontal flip. */
    virtual bool writeHorizontalFlip(bool value) = 0;
    /** @brief Retrieves read vertical flip. */
    virtual bool readVerticalFlip(bool* value) = 0;
    /** @brief Sets write vertical flip. */
    virtual bool writeVerticalFlip(bool value) = 0;
  };

}  // namespace eCamSDK
