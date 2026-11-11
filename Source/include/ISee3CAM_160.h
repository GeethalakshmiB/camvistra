///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_160.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_160 extension-unit (HID) controls:
//      AF (mode, ROI, lens position, CAF range), AE/AWB lock and
//      metering, flicker, burst, Q-factor
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_160::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_160.h @brief Declares the ISee3CAM_160 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief Auto-focus operating mode. */
enum class AFMode160 : uint8_t {
    ONESHOT    = 0x01, ///< Single-shot auto-focus
    CONTINUOUS = 0x06  ///< Continuous auto-focus (CAF)
};

/** @brief Auto-white-balance preset mode. */
enum class AWBPresetMode160 : uint8_t {
    CLOUDY                    = 0x01, ///< Cloudy daylight
    DAYLIGHT                  = 0x02, ///< Clear daylight
    FLASH                     = 0x03, ///< Flash illumination
    COOLWHITE_FLUORESCENT     = 0x04, ///< Cool-white fluorescent
    TUNGSTEN                  = 0x05, ///< Tungsten / incandescent
    CANDLELIGHT               = 0x06, ///< Candlelight
    HORIZON                   = 0x07, ///< Horizon / shade
    CUSTOM                    = 0x08, ///< User-defined custom
    AUTO                      = 0x09  ///< Automatic AWB
};

/** @brief AWB lock state. */
enum class AWBLockStatus160 : uint8_t {
    LOCK_OFF = 0x00, ///< AWB lock disabled
    LOCK_ON  = 0x01  ///< AWB lock enabled
};

/** @brief Auto-exposure metering mode. */
enum class AEMeteringMode160 : uint8_t {
    AE_OFF                  = 0x00, ///< Auto-exposure off
    CENTER_WEIGHTED_AVG     = 0x01, ///< Centre-weighted average metering
    ALL_BLOCK_INTEGRAL      = 0x02, ///< All-block integral metering
    SMALL_AREA              = 0x05, ///< Small-area spot metering
    LARGE_AREA              = 0x06  ///< Large-area metering
};

/** @brief AE lock state. */
enum class AELockStatus160 : uint8_t {
    LOCK_OFF = 0x00, ///< AE lock disabled
    LOCK_ON  = 0x01  ///< AE lock enabled
};

/** @brief Anti-flicker / frequency detection mode. */
enum class FlickerMode160 : uint8_t {
    AUTO_DETECTION = 0x00, ///< Automatic frequency detection
    FIFTY_HZ       = 0x01, ///< Force 50 Hz suppression
    SIXTY_HZ       = 0x02, ///< Force 60 Hz suppression
    FLICKER_OFF    = 0x04  ///< Disable anti-flicker
};

/** @brief Continuous auto-focus scan range. */
enum class CAFScanRange160 : uint8_t {
    MACRO            = 0x00, ///< Macro (close-up) range
    NORMAL           = 0x01, ///< Normal range
    FULL             = 0x02, ///< Full scan range
    FOCUS_INFINITY   = 0x03, ///< Infinity focus range
    HYPERFOCAL       = 0x04  ///< Hyperfocal distance
};

/** @brief AF lock state. */
enum class AFLockStatus160 : uint8_t {
    LOCK_OFF = 0x00, ///< AF lock disabled
    LOCK_ON  = 0x01  ///< AF lock enabled
};

/** @brief Manual lens position mode. */
enum class LensPosition160 : uint8_t {
    LENS_INFINITY = 0x01, ///< Focus set to infinity
    NORMAL        = 0x02, ///< Normal focus position
    BARCODE       = 0x03, ///< Barcode / near-field position
    LENS_MACRO    = 0x04, ///< Macro (very close) position
    INITIAL_DAC   = 0x05, ///< Initial DAC position
    CUSTOM        = 0x06  ///< Custom user-specified DAC position
};

/** @brief AF enable / disable status. */
enum class AFStatus160 : uint8_t {
    AF_ON  = 0x00, ///< Auto-focus enabled
    AF_OFF = 0x06  ///< Auto-focus disabled (manual focus)
};

/** @brief AF ROI selection mode. */
enum class AFROIMode160 : uint8_t {
    CENTERED    = 0x00, ///< Centred / full-frame AF window
    CUSTOM_AREA = 0x01  ///< User-defined custom AF window
};

// ----------------------------------------------------------------
// Output structs
// ----------------------------------------------------------------

/** @brief Parsed firmware version from readFirmwareVersion(). */
struct FirmwareVersion160 {
    uint8_t byte1; ///< ISP firmware version byte 1 (major)
    uint8_t byte2; ///< ISP firmware version byte 2
    uint8_t byte3; ///< ISP firmware version byte 3
    uint8_t byte4; ///< ISP firmware version byte 4 (minor)
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_160 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_160::create(), instead of using See3CAM_160 directly.
 */
class CAMSDK ISee3CAM_160 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_160() = default;

    /**
     * @brief Creates the See3CAM_160 implementation.
     * @return Owning pointer to a newly created See3CAM_160 instance.
     */
    static std::unique_ptr<ISee3CAM_160> create();

    // ---- Auto-focus mode ----------------------------------------

    /**
     * @brief Retrieves the current auto-focus operating mode.
     * @param[out] outAfMode Raw AF mode byte (cast to AFMode160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAFMode(uint8_t &outAfMode) = 0;

    /**
     * @brief Sets the auto-focus operating mode.
     * @param[in] afMode Desired AF mode (AFMode160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAFMode(AFMode160 afMode) = 0;

    // ---- AWB preset mode ----------------------------------------

    /**
     * @brief Retrieves the current auto-white-balance preset mode.
     * @param[out] outAwbMode Raw AWB preset byte (cast to AWBPresetMode160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAWBPresetMode(uint8_t &outAwbMode) = 0;

    /**
     * @brief Sets the auto-white-balance preset mode.
     * @param[in] awbMode Desired AWB preset (AWBPresetMode160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAWBPresetMode(AWBPresetMode160 awbMode) = 0;

    // ---- AWB lock status ----------------------------------------

    /**
     * @brief Retrieves the current AWB lock state.
     * @param[out] outLock Raw lock status byte (cast to AWBLockStatus160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAWBLockStatus(uint8_t &outLock) = 0;

    /**
     * @brief Sets the AWB lock state.
     * @param[in] lock Desired lock state (AWBLockStatus160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAWBLockStatus(AWBLockStatus160 lock) = 0;

    // ---- AE metering mode ---------------------------------------

    /**
     * @brief Retrieves the current auto-exposure metering mode.
     * @param[out] outMode Raw metering mode byte (cast to AEMeteringMode160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAEMeteringMode(uint8_t &outMode) = 0;

    /**
     * @brief Sets the auto-exposure metering mode.
     * @param[in] mode Desired metering mode (AEMeteringMode160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAEMeteringMode(AEMeteringMode160 mode) = 0;

    // ---- AE lock status -----------------------------------------

    /**
     * @brief Retrieves the current auto-exposure lock state.
     * @param[out] outLock Raw AE lock byte (cast to AELockStatus160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAELockStatus(uint8_t &outLock) = 0;

    /**
     * @brief Sets the auto-exposure lock state.
     * @param[in] lock Desired AE lock state (AELockStatus160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAELockStatus(AELockStatus160 lock) = 0;

    // ---- Flicker detection --------------------------------------

    /**
     * @brief Retrieves the current flicker / anti-flicker detection mode.
     * @param[out] outFlicker Raw flicker mode byte (cast to FlickerMode160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlickerMode(uint8_t &outFlicker) = 0;

    /**
     * @brief Sets the flicker detection mode.
     * @param[in] flicker Desired flicker mode (FlickerMode160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setFlickerMode(FlickerMode160 flicker) = 0;

    // ---- JPEG Q-factor ------------------------------------------

    /**
     * @brief Retrieves the current JPEG quality (Q-factor) value.
     * @param[out] outQFactor Current Q-factor value [0Ã¢â‚¬â€œ255].
     * @return true on success, false on communication or device error.
     */
    virtual bool getQFactor(uint8_t &outQFactor) = 0;

    /**
     * @brief Sets the JPEG quality (Q-factor) value.
     * @param[in] qValue Desired Q-factor value [0Ã¢â‚¬â€œ255].
     * @return true on success, false on communication or device error.
     */
    virtual bool setQFactor(uint8_t qValue) = 0;

    // ---- CAF scan range -----------------------------------------

    /**
     * @brief Retrieves the current continuous auto-focus scan range.
     * @param[out] outRange Raw CAF scan range byte (cast to CAFScanRange160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getCAFScanRange(uint8_t &outRange) = 0;

    /**
     * @brief Sets the continuous auto-focus scan range.
     * @param[in] range Desired CAF scan range (CAFScanRange160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setCAFScanRange(CAFScanRange160 range) = 0;

    // ---- AF lock status -----------------------------------------

    /**
     * @brief Retrieves the current auto-focus lock state.
     * @param[out] outLock Raw AF lock byte (cast to AFLockStatus160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAFLockStatus(uint8_t &outLock) = 0;

    /**
     * @brief Sets the auto-focus lock state.
     * @param[in] lock Desired AF lock state (AFLockStatus160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAFLockStatus(AFLockStatus160 lock) = 0;

    // ---- Manual lens position -----------------------------------

    /**
     * @brief Retrieves the current manual lens position mode.
     * @param[out] outPosition Raw lens position byte (cast to LensPosition160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getManualLensPosition(uint8_t &outPosition) = 0;

    /**
     * @brief Sets the manual lens position mode.
     * @param[in] position Desired lens position (LensPosition160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setManualLensPosition(LensPosition160 position) = 0;

    // ---- AF status (enable / disable) ---------------------------

    /**
     * @brief Retrieves the current auto-focus enable/disable status.
     * @param[out] outStatus Raw AF status byte (cast to AFStatus160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAFStatus(uint8_t &outStatus) = 0;

    /**
     * @brief Enables or disables auto-focus.
     * @param[in] status Desired AF state (AFStatus160 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAFStatus(AFStatus160 status) = 0;

    // ---- AF ROI mode --------------------------------------------

    /**
     * @brief Retrieves the current auto-focus ROI mode.
     * @param[out] outRoiMode Raw ROI mode byte (cast to AFROIMode160).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAFROIMode(uint8_t &outRoiMode) = 0;

    /**
     * @brief Sets the auto-focus ROI to centred (full-frame) mode.
     * @return true on success, false on communication or device error.
     */
    virtual bool setAFROICenteredMode() = 0;

    /**
     * @brief Sets a custom auto-focus ROI window.
     *
     * Coordinates are in sensor pixels.  The byte ordering sent to the camera
     * differs per platform to match the native HID protocol layout:
     *   - Linux  : packet order is [xMax, yMin, xMin, yMax].
     *   - Windows: packet order is [xMin, xMax, yMin, yMax].
     *
     * @param[in] xMin  Left edge of the focus window (pixels).
     * @param[in] xMax  Right edge of the focus window (pixels).
     * @param[in] yMin  Top edge of the focus window (pixels).
     * @param[in] yMax  Bottom edge of the focus window (pixels).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set afroicustom mode. */
    virtual bool setAFROICustomMode(uint16_t xMin, uint16_t xMax,
                            uint16_t yMin, uint16_t yMax) = 0;

    // ---- Burst length -------------------------------------------

    /**
     * @brief Retrieves the current burst capture length.
     * @param[out] outBurst Number of frames captured per burst trigger [1Ã¢â‚¬â€œN].
     * @return true on success, false on communication or device error.
     */
    virtual bool getBurstLength(uint8_t &outBurst) = 0;

    /**
     * @brief Sets the burst capture length.
     * @param[in] burstLength Number of frames to capture per burst trigger.
     * @return true on success, false on communication or device error.
     */
    virtual bool setBurstLength(uint8_t burstLength) = 0;

    // ---- Firmware version ---------------------------------------

    /**
     * @brief Reads the ISP firmware version from the camera.
     * @param[out] outVersion Populated with the four firmware version bytes.
     * @return true on success, false on communication or device error.
     */
    virtual bool readFirmwareVersion(FirmwareVersion160 &outVersion) = 0;

    // ---- Unique ID ----------------------------------------------

    /**
     * @brief Reads the 64-bit unique device serial number.
     * @param[out] outUniqueId Hex string containing the unique ID.
     * @return true on success, false on communication or device error.
     */
    virtual bool getUniqueID64(std::string &outUniqueId) = 0;

    // ---- Restore default ----------------------------------------

    /**
     * @brief Restores all camera settings to their factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool restoreDefault() = 0;

    // ---- Initialisation -----------------------------------------

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
