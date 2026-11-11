///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU55_MH.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU55_MH extension-unit (HID) controls:
//      stream mode, flash mode, orientation, serial number
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU55_MH::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU55_MH.h @brief Declares the ISee3CAM_CU55_MH interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>


// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------
enum class StreamModeCU55_MH : uint8_t {
    MASTER  = 0x00,
    TRIGGER = 0x01
};

enum class FlashModeCU55_MH : uint8_t {
    OFF    = 0x00,
    STROBE = 0x01,
    TORCH  = 0x02
};

enum class RollControlCU55_MH : uint8_t {
    NORMAL     = 0x00,
    HORIZONTAL = 0x01,
    VERTICAL   = 0x02,
    BOTH       = 0x03
};

namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU55_MH camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU55_MH::create(), instead of using See3CAM_CU55_MH directly.
 */
class CAMSDK ISee3CAM_CU55_MH {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU55_MH() = default;

    /**
     * @brief Creates the See3CAM_CU55_MH implementation.
     * @return Owning pointer to a newly created See3CAM_CU55_MH instance.
     */
    static std::unique_ptr<ISee3CAM_CU55_MH> create();

    /** @brief Retrieves get stream mode. */
    virtual bool getStreamMode(uint8_t &outStreamMode) = 0;
    /** @brief Sets set stream mode. */
    virtual bool setStreamMode(StreamModeCU55_MH streamMode) = 0;

    /** @brief Performs get flash mode. */
    virtual bool getFlashMode(uint8_t &outFlashMode) = 0;
    /** @brief Sets set flash mode. */
    virtual bool setFlashMode(FlashModeCU55_MH flashMode) = 0;

    /** @brief Retrieves get orientation. */
    virtual bool getOrientation(uint8_t &outFlipMode) = 0;
    /** @brief Sets set orientation. */
    virtual bool setOrientation(bool horzFlip, bool vertFlip) = 0;

    /** @brief Performs restore default. */
    virtual bool restoreDefault() = 0;

    /** @brief Performs get64 bit serial number. */
    virtual bool get64BitSerialNumber(uint64_t &outSerial) = 0;
    /** @brief Retrieves read firmware version. */
    virtual bool readFirmwareVersion(std::string &version) = 0;

    /** @brief Performs set hid fd. */
    virtual bool setHidFd(int fd) = 0;

#ifdef _WIN32
    /** @brief Initializes init from device path. */
    virtual bool initFromDevicePath(TCHAR *devicePath) = 0;
    /** @brief Performs deinit extension unit. */
    virtual void deinitExtensionUnit() = 0;
#endif
};

} // namespace eCamSDK
