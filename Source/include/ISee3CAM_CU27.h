///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU27.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU27 extension-unit (HID) controls:
//      AWB preset and lock, AE metering and lock, flicker, denoise,
//      roll, burst, Q-factor
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU27::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU27.h @brief Declares the ISee3CAM_CU27 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief AWB preset white balance mode. */
enum class AWBPresetModeCU27 : uint8_t {
    AWB_PRESET_CLOUDY              = 0x01, ///< Cloudy
    AWB_PRESET_DAYLIGHT            = 0x02, ///< Daylight
    AWB_PRESET_FLASH               = 0x03, ///< Flash
    AWB_PRESET_COOLWHITE_FLUOR     = 0x04, ///< Cool white fluorescent
    AWB_PRESET_TUNGSTEN            = 0x05, ///< Tungsten
    AWB_PRESET_CANDLELIGHT         = 0x06, ///< Candlelight
    AWB_PRESET_HORIZON             = 0x07, ///< Horizon
    AWB_PRESET_CUSTOM              = 0x08, ///< Custom
    AWB_PRESET_AUTO                = 0x09  ///< Auto
};

/** @brief AWB lock status. */
enum class AWBLockStatusCU27 : uint8_t {
    AWB_LOCK_OFF = 0x00, ///< AWB lock disabled
    AWB_LOCK_ON  = 0x01  ///< AWB lock enabled
};

/** @brief Auto exposure metering mode. */
enum class AEMeteringModeCU27 : uint8_t {
    AE_OFF                   = 0x00, ///< Auto exposure off
    AE_CENTER_WEIGHTED_AVG   = 0x01, ///< Centre-weighted average
    AE_ALL_BLOCK_INTEGRAL    = 0x02, ///< All-block integral
    AE_SMALL_AREA            = 0x05, ///< Small area
    AE_LARGE_AREA            = 0x06  ///< Large area
};

/** @brief Auto exposure lock status. */
enum class AELockStatusCU27 : uint8_t {
    AE_LOCK_OFF = 0x00, ///< AE lock disabled
    AE_LOCK_ON  = 0x01  ///< AE lock enabled
};

/** @brief Flicker detection mode. */
enum class FlickerModeCU27 : uint8_t {
    FLICKER_AUTO = 0x00, ///< Auto detection
    FLICKER_50HZ = 0x01, ///< 50 Hz suppression
    FLICKER_60HZ = 0x02, ///< 60 Hz suppression
    FLICKER_OFF  = 0x04  ///< Flicker detection disabled
};

/** @brief Denoise enable/disable mode. */
enum class DenoiseModesCU27 : uint8_t {
    DENOISE_DISABLE = 0x00, ///< Denoise disabled
    DENOISE_ENABLE  = 0x01  ///< Denoise enabled
};

// ----------------------------------------------------------------
// Output structs
// ----------------------------------------------------------------

/** @brief ISP firmware version components from readISPFirmwareVersion(). */
struct ISPFirmwareVersionCU27 {
    uint8_t major;    ///< Major version
    uint8_t minor1;   ///< Minor version byte 1
    uint8_t minor2;   ///< Minor version byte 2
    uint8_t minor3;   ///< Minor version byte 3
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU27 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU27::create(), instead of using See3CAM_CU27 directly.
 */
class CAMSDK ISee3CAM_CU27 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU27() = default;

    /**
     * @brief Creates the See3CAM_CU27 implementation.
     * @return Owning pointer to a newly created See3CAM_CU27 instance.
     */
    static std::unique_ptr<ISee3CAM_CU27> create();

    // ---- AWB preset mode --------------------------------------------

    /**
     * @brief Retrieves the current AWB preset mode.
     * @param[out] outMode Raw AWB preset mode byte (cast to AWBPresetModeCU27).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAWBPresetMode(uint8_t &outMode) = 0;

    /**
     * @brief Sets the AWB preset mode.
     * @param[in] mode Desired AWB preset mode (AWBPresetModeCU27 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAWBPresetMode(AWBPresetModeCU27 mode) = 0;

    // ---- AWB lock status --------------------------------------------

    /**
     * @brief Retrieves the current AWB lock status.
     * @param[out] outStatus Raw AWB lock status byte (cast to AWBLockStatusCU27).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAWBLockStatus(uint8_t &outStatus) = 0;

    /**
     * @brief Sets the AWB lock status.
     * @param[in] lockStatus Desired AWB lock state (AWBLockStatusCU27 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAWBLockStatus(AWBLockStatusCU27 lockStatus) = 0;

    // ---- AE metering mode -------------------------------------------

    /**
     * @brief Retrieves the current auto exposure metering mode.
     * @param[out] outMode Raw AE metering mode byte (cast to AEMeteringModeCU27).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAEMeteringMode(uint8_t &outMode) = 0;

    /**
     * @brief Sets the auto exposure metering mode.
     * @param[in] mode Desired AE metering mode (AEMeteringModeCU27 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAEMeteringMode(AEMeteringModeCU27 mode) = 0;

    // ---- AE lock status ---------------------------------------------

    /**
     * @brief Retrieves the current auto exposure lock status.
     * @param[out] outStatus Raw AE lock status byte (cast to AELockStatusCU27).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAELockStatus(uint8_t &outStatus) = 0;

    /**
     * @brief Sets the auto exposure lock status.
     * @param[in] lockStatus Desired AE lock state (AELockStatusCU27 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAELockStatus(AELockStatusCU27 lockStatus) = 0;

    // ---- Flicker mode -----------------------------------------------

    /**
     * @brief Retrieves the current flicker detection mode.
     * @param[out] outMode Raw flicker mode byte (cast to FlickerModeCU27).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlickerMode(uint8_t &outMode) = 0;

    /**
     * @brief Sets the flicker detection mode.
     * @param[in] mode Desired flicker mode (FlickerModeCU27 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setFlickerMode(FlickerModeCU27 mode) = 0;

    // ---- JPEG Q-factor ----------------------------------------------

    /**
     * @brief Retrieves the current JPEG Q-factor value.
     * @param[out] outQ Current Q-factor [0-255].
     * @return true on success, false on communication or device error.
     */
    virtual bool getQFactor(uint8_t &outQ) = 0;

    /**
     * @brief Sets the JPEG Q-factor value.
     * @param[in] q Desired Q-factor [0-255].
     * @return true on success, false on communication or device error.
     */
    virtual bool setQFactor(uint8_t q) = 0;

    // ---- Burst length -----------------------------------------------

    /**
     * @brief Retrieves the current burst capture length.
     * @param[out] outBurst Current burst length value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getBurstLength(uint8_t &outBurst) = 0;

    /**
     * @brief Sets the burst capture length.
     * @param[in] burst Desired burst length value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setBurstLength(uint8_t burst) = 0;

    // ---- Denoise mode -----------------------------------------------

    /**
     * @brief Retrieves the current denoise mode.
     * @param[out] outMode Raw denoise mode byte (cast to DenoiseModesCU27).
     * @return true on success, false on communication or device error.
     */
    virtual bool getDenoiseMode(uint8_t &outMode) = 0;

    /**
     * @brief Sets the denoise mode.
     * @param[in] mode Desired denoise mode (DenoiseModesCU27 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setDenoiseMode(DenoiseModesCU27 mode) = 0;

    // ---- Roll value -------------------------------------------------

    /**
     * @brief Retrieves the current roll value.
     * @param[out] outRoll Current roll value [0-255].
     * @return true on success, false on communication or device error.
     */
    virtual bool getRollValue(uint8_t &outRoll) = 0;

    /**
     * @brief Sets the roll value.
     * @param[in] roll Desired roll value [0-255].
     * @return true on success, false on communication or device error.
     */
    virtual bool setRollValue(uint8_t roll) = 0;

    // ---- ISP firmware version ---------------------------------------

    /**
     * @brief Reads the ISP firmware version from the camera.
     * @param[out] outVer Populated with the four firmware version components.
     * @return true on success, false on communication or device error.
     */
    virtual bool readISPFirmwareVersion(ISPFirmwareVersionCU27 &outVer) = 0;

    // ---- Restore default --------------------------------------------

    /**
     * @brief Restores all camera settings to their factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool setToDefault() = 0;

    // ---- Firmware version / unique ID -------------------------------

    /**
     * @brief Reads the firmware version from the device.
     * @param[out] version Reference to a string that will contain the firmware version (e.g., "1.0.3.0").
     * @return true on successful retrieval, false on communication or device error.
     */
    virtual bool readFirmwareVersion(std::string &version) = 0;

    /**
     * @brief Reads the 64-bit unique ID of the camera.
     * @param[out] uniqueID Reference to a string where the unique ID will be stored.
     * @return true if the unique ID is successfully read, false on communication or device error.
     */
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
