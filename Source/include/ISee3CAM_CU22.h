///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU22.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU22 extension-unit (HID) controls:
//      camera and sensor mode, LSC, colour kill, special effects, AE
//      ROI, anti-flicker, flip, denoise, burst
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU22::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU22.h @brief Declares the ISee3CAM_CU22 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief Sensor operating mode. */
enum class SensorModeCU22 : uint8_t {
    SENSOR_STANDARD = 0x01, ///< Standard (normal) mode
    SENSOR_HDR      = 0x03  ///< HDR mode
};

/** @brief Camera trigger / master mode. */
enum class CameraModeCU22 : uint8_t {
    CAMERA_MASTER  = 0x01, ///< Free-running (master) mode
    CAMERA_TRIGGER = 0x02  ///< External trigger mode
};

/** @brief Special image effects (colour processing mode). */
enum class SpecialEffectsCU22 : uint8_t {
    EFFECT_NORMAL    = 0x01, ///< Normal colour output
    EFFECT_GREYSCALE = 0x02  ///< Greyscale output
};

/** @brief Image flip / mirror orientation. */
enum class FlipModeCU22 : uint8_t {
    FLIP_NORMAL     = 0x01, ///< No flip
    FLIP_VERTICAL   = 0x02, ///< Vertical flip only
    FLIP_HORIZONTAL = 0x03, ///< Horizontal flip (mirror) only
    FLIP_BOTH       = 0x04  ///< Both horizontal and vertical flip
};

/** @brief Auto-exposure ROI selection mode. */
enum class ROIAutoExpModeCU22 : uint8_t {
    AUTO_EXP_CENTERED = 0x01, ///< Centred full-frame AE window
    AUTO_EXP_MANUAL   = 0x02, ///< Manual ROI window
    AUTO_EXP_DISABLED = 0x03  ///< AE ROI disabled
};

/** @brief Anti-flicker suppression mode. */
enum class AntiFlickerModeCU22 : uint8_t {
    ANTI_FLICKER_AUTO  = 0x01, ///< Automatic flicker detection
    ANTI_FLICKER_50HZ  = 0x02, ///< 50 Hz suppression
    ANTI_FLICKER_60HZ  = 0x03  ///< 60 Hz suppression
};

/** @brief Denoise enable / disable. */
enum class DenoiseModesCU22 : uint8_t {
    DENOISE_ENABLE  = 0x01, ///< Denoise processing enabled
    DENOISE_DISABLE = 0x02  ///< Denoise processing disabled
};

/** @brief Lens shading correction (LSC) profile. */
enum class LSCModeCU22 : uint8_t {
    LSC_WARM_WHITE   = 0x01, ///< Warm-white lighting profile
    LSC_BRIGHT_WHITE = 0x02, ///< Bright-white lighting profile
    LSC_DAYLIGHT     = 0x03  ///< Daylight / outdoor profile
};

// ----------------------------------------------------------------
// Output structs
// ----------------------------------------------------------------

/** @brief Result of getAutoExpROIMode(). */
struct ROIAutoExpResultCU22 {
    uint8_t mode;     ///< ROI mode (ROIAutoExpModeCU22)
    uint8_t xpos;    ///< Mapped X coordinate [0Ã¢â‚¬â€œ255]
    uint8_t ypos;    ///< Mapped Y coordinate [0Ã¢â‚¬â€œ255]
    uint8_t wnsize; ///< Window size index
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU22 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU22::create(), instead of using See3CAM_CU22 directly.
 */
class CAMSDK ISee3CAM_CU22 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU22() = default;

    /**
     * @brief Creates the See3CAM_CU22 implementation.
     * @return Owning pointer to a newly created See3CAM_CU22 instance.
     */
    static std::unique_ptr<ISee3CAM_CU22> create();

    // ---- Sensor mode ------------------------------------------------

    /**
     * @brief Retrieves the current sensor operating mode.
     * @param[out] outSensorMode Raw sensor mode byte (cast to SensorModeCU22).
     * @return true on success, false on communication or device error.
     */
    virtual bool getSensorMode(uint8_t &outSensorMode) = 0;

    /**
     * @brief Sets the sensor operating mode.
     * @param[in] sensorMode Desired mode (SensorModeCU22 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setSensorMode(SensorModeCU22 sensorMode) = 0;

    // ---- Camera (trigger) mode --------------------------------------

    /**
     * @brief Retrieves the current camera trigger / master mode.
     * @param[out] outCamMode Raw camera mode byte (cast to CameraModeCU22).
     * @return true on success, false on communication or device error.
     */
    virtual bool getCameraMode(uint8_t &outCamMode) = 0;

    /**
     * @brief Sets the camera trigger / master mode.
     * @param[in] camMode Desired mode (CameraModeCU22 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setCameraMode(CameraModeCU22 camMode) = 0;

    // ---- Special effects --------------------------------------------

    /**
     * @brief Retrieves the current special image effect (colour processing mode).
     * @param[out] outEffects Raw effect byte (cast to SpecialEffectsCU22).
     * @return true on success, false on communication or device error.
     */
    virtual bool getSpecialEffects(uint8_t &outEffects) = 0;

    /**
     * @brief Sets the special image effect.
     * @param[in] effects Desired effect (SpecialEffectsCU22 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setSpecialEffects(SpecialEffectsCU22 effects) = 0;

    // ---- Auto-exposure ROI ------------------------------------------

    /**
     * @brief Retrieves the current auto-exposure ROI configuration.
     * @param[out] outRoi Populated with mode, mapped x/y position, and window size.
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoExpROIMode(ROIAutoExpResultCU22 &outRoi) = 0;

    /**
     * @brief Configures the auto-exposure region of interest.
     * @param[in] roiMode  ROI mode (ROIAutoExpModeCU22 enum value).
     * @param[in] vidW     Video frame width in pixels (for coordinate mapping).
     * @param[in] vidH     Video frame height in pixels (for coordinate mapping).
     * @param[in] xCord    X coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] yCord    Y coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] winSize  Window size index for the ROI (manual mode only).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set auto exp roimode. */
    virtual bool setAutoExpROIMode(ROIAutoExpModeCU22 roiMode,
                           uint32_t vidW, uint32_t vidH,
                           uint32_t xCord, uint32_t yCord,
                           uint8_t winSize) = 0;

    // ---- Orientation / flip -----------------------------------------

    /**
     * @brief Retrieves the current image flip / mirror orientation.
     * @param[out] outFlipMode Raw orientation byte (cast to FlipModeCU22).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlipMode(uint8_t &outFlipMode) = 0;

    /**
     * @brief Sets image flip and mirror orientation.
     * @param[in] horzFlip true to flip the image horizontally (mirror).
     * @param[in] vertFlip true to flip the image vertically.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set flip mode. */
    virtual bool setFlipMode(bool horzFlip, bool vertFlip) = 0;

    // ---- Colour kill ------------------------------------------------

    /**
     * @brief Retrieves the current colour-kill value.
     * @param[out] outColorKill Raw colour-kill byte.
     * @return true on success, false on communication or device error.
     */
    virtual bool getColorKillValue(uint8_t &outColorKill) = 0;

    /**
     * @brief Sets the colour-kill value.
     * @param[in] colorKill Desired colour-kill value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setColorKillValue(uint8_t colorKill) = 0;

    // ---- Burst length -----------------------------------------------

    /**
     * @brief Retrieves the current burst-capture length.
     * @param[out] outBurstLen Number of frames per burst trigger.
     * @return true on success, false on communication or device error.
     */
    virtual bool getBurstLength(uint8_t &outBurstLen) = 0;

    /**
     * @brief Sets the burst-capture length.
     * @param[in] burstLen Number of frames to capture per burst trigger.
     * @return true on success, false on communication or device error.
     */
    virtual bool setBurstLength(uint8_t burstLen) = 0;

    // ---- Anti-flicker -----------------------------------------------

    /**
     * @brief Retrieves the current anti-flicker suppression mode.
     * @param[out] outFlicker Raw flicker mode byte (cast to AntiFlickerModeCU22).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAntiFlickerMode(uint8_t &outFlicker) = 0;

    /**
     * @brief Sets the anti-flicker suppression mode.
     * @param[in] flickerMode Desired mode (AntiFlickerModeCU22 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAntiFlickerMode(AntiFlickerModeCU22 flickerMode) = 0;

    // ---- Denoise ----------------------------------------------------

    /**
     * @brief Retrieves the current denoise processing state.
     * @param[out] outDenoise Raw denoise byte (cast to DenoiseModesCU22).
     * @return true on success, false on communication or device error.
     */
    virtual bool getDenoiseMode(uint8_t &outDenoise) = 0;

    /**
     * @brief Enables or disables denoise processing.
     * @param[in] denoiseMode DENOISE_ENABLE or DENOISE_DISABLE.
     * @return true on success, false on communication or device error.
     */
    virtual bool setDenoiseMode(DenoiseModesCU22 denoiseMode) = 0;

    // ---- LSC mode ---------------------------------------------------

    /**
     * @brief Retrieves the current lens shading correction (LSC) profile.
     * @param[out] outLscMode Raw LSC mode byte (cast to LSCModeCU22).
     * @return true on success, false on communication or device error.
     */
    virtual bool getLSCMode(uint8_t &outLscMode) = 0;

    /**
     * @brief Sets the lens shading correction (LSC) profile.
     * @param[in] lscMode Desired profile (LSCModeCU22 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setLSCMode(LSCModeCU22 lscMode) = 0;

    // ---- Restore default --------------------------------------------

    /**
     * @brief Restores all camera settings to their factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool restoreDefault() = 0;

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
