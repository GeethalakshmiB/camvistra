///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU200M.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU200M extension-unit (HID) controls:
//      stream mode, flash mode, orientation, unique ID
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU200M::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU200M.h @brief Declares the ISee3CAM_CU200M interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------
enum class StreamModeCU200M : uint8_t {
    MASTER  = 0x01,
    TRIGGER = 0x02
};

enum class FlashModeCU200M : uint8_t {
    DISABLE = 0x00,
    STROBE  = 0x01,
    TORCH   = 0x02
};

enum class FlipModeCU200M : uint8_t {
    NORMAL     = 0x00,
    HORIZONTAL = 0x01,
    VERTICAL   = 0x02,
    ROTATE_180 = 0x03
};

namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU200M camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU200M::create(), instead of using See3CAM_CU200M directly.
 */
class CAMSDK ISee3CAM_CU200M {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU200M() = default;

    /**
     * @brief Creates the See3CAM_CU200M implementation.
     * @return Owning pointer to a newly created See3CAM_CU200M instance.
     */
    static std::unique_ptr<ISee3CAM_CU200M> create();

    /** @brief Retrieves get stream mode. */
    virtual bool getStreamMode(uint8_t &outStreamMode) = 0;
    /** @brief Sets set stream mode. */
    virtual bool setStreamMode(StreamModeCU200M streamMode) = 0;

    /** @brief Performs get flash mode. */
    virtual bool getFlashMode(uint8_t &outFlashMode) = 0;
    /** @brief Sets set flash mode. */
    virtual bool setFlashMode(FlashModeCU200M flashMode) = 0;

    /** @brief Retrieves get orientation. */
    virtual bool getOrientation(uint8_t &outFlipMode) = 0;
    /** @brief Sets set orientation. */
    virtual bool setOrientation(bool horzFlip, bool vertFlip) = 0;

    /** @brief Performs restore default. */
    virtual bool restoreDefault() = 0;

    /** @brief Reads the firmware version as "major.minor1.minor2.minor3". */
    virtual bool readFirmwareVersion(std::string &version) = 0;
    /** @brief Reads the camera's 64-bit unique ID (serial number). */
    virtual bool getCameraUniqueID64(std::string &uniqueID) = 0;

    /** @brief Sets set hid fd. */
    virtual bool setHidFd(int fd) = 0;

#ifdef _WIN32
    /** @brief Performs init from device path. */
    virtual bool initFromDevicePath(TCHAR *devicePath) = 0;
    /** @brief Performs deinit extension unit. */
    virtual void deinitExtensionUnit() = 0;
#endif
};

} // namespace eCamSDK
