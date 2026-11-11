///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU512M.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU512M extension-unit (HID) controls:
//      stream mode, flash mode, orientation, unique ID
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU512M::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU512M.h @brief Declares the ISee3CAM_CU512M interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>


// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief Streaming trigger mode. */
enum class StreamModeCU512M : uint8_t {
    MASTER  = 0x01, ///< Free-running (master) mode
    TRIGGER = 0x02  ///< External trigger mode
};

/** @brief Flash / torch output mode. */
enum class FlashModeCU512M : uint8_t {
    DISABLE = 0x00, ///< Flash disabled
    STROBE  = 0x01, ///< Strobe flash
    TORCH   = 0x02  ///< Continuous torch
};

/** @brief Image flip / mirror orientation. */
enum class FlipModeCU512M : uint8_t {
    NORMAL     = 0x00, ///< No flip
    HORIZONTAL = 0x01, ///< Horizontal flip (mirror)
    VERTICAL   = 0x02, ///< Vertical flip
    ROTATE_180 = 0x03  ///< Both horizontal and vertical flip (rotate 180Ã‚Â°)
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU512M camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU512M::create(), instead of using See3CAM_CU512M directly.
 */
class CAMSDK ISee3CAM_CU512M {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU512M() = default;

    /**
     * @brief Creates the See3CAM_CU512M implementation.
     * @return Owning pointer to a newly created See3CAM_CU512M instance.
     */
    static std::unique_ptr<ISee3CAM_CU512M> create();

    // ---- Stream mode ------------------------------------------------

    /**
     * @brief Retrieves the current streaming trigger mode.
     * @param[out] outStreamMode Raw stream mode byte (cast to StreamModeCU512M).
     * @return true on success, false on communication or device error.
     */
    virtual bool getStreamMode(uint8_t &outStreamMode) = 0;

    /**
     * @brief Sets the streaming trigger mode.
     * @param[in] streamMode Desired mode (StreamModeCU512M enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setStreamMode(StreamModeCU512M streamMode) = 0;

    // ---- Flash mode -------------------------------------------------

    /**
     * @brief Retrieves the current flash / torch output mode.
     * @param[out] outFlashMode Raw flash mode byte (cast to FlashModeCU512M).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlashMode(uint8_t &outFlashMode) = 0;

    /**
     * @brief Sets the flash / torch output mode.
     * @param[in] flashMode Desired mode (FlashModeCU512M enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setFlashMode(FlashModeCU512M flashMode) = 0;

    // ---- Orientation / flip -----------------------------------------

    /**
     * @brief Retrieves the current image flip / mirror orientation.
     * @param[out] outFlipMode Raw orientation byte (cast to FlipModeCU512M).
     * @return true on success, false on communication or device error.
     */
    virtual bool getOrientation(uint8_t &outFlipMode) = 0;

    /**
     * @brief Sets image flip and mirror orientation.
     * @param[in] horzFlip true to flip the image horizontally (mirror).
     * @param[in] vertFlip true to flip the image vertically.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set orientation. */
    virtual bool setOrientation(bool horzFlip, bool vertFlip) = 0;

    // ---- Factory restore --------------------------------------------

    /**
     * @brief Restores all camera settings to their factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool restoreDefault() = 0;

    /** @brief Reads the firmware version as "major.minor1.minor2.minor3". */
    virtual bool readFirmwareVersion(std::string &version) = 0;
    /** @brief Reads the camera's 64-bit unique ID (serial number). */
    virtual bool getCameraUniqueID64(std::string &uniqueID) = 0;

    // ---- Initialisation ---------------------------------------------

    /**
     * @brief (Linux only) Initialises the HID channel using an open file descriptor.
     * @param[in] fd Open file descriptor for the camera HID device node.
     * @return true on success; always false on Windows.
     */
    virtual bool setHidFd(int fd) = 0;

    /** @name Windows-only initialisation */
    ///@{
#ifdef _WIN32
    /**
     * @brief (Windows only) Opens and initialises the HID extension unit from a device path.
     * @param[in] devicePath Wide-character device path from HID enumeration.
     * @return true on success, false if the device could not be opened.
     */
    virtual bool initFromDevicePath(TCHAR *devicePath) = 0;

    /**
     * @brief (Windows only) Closes the HID extension unit and releases the device handle.
     */
    virtual void deinitExtensionUnit() = 0;
#endif
    ///@}
};

} // namespace eCamSDK
