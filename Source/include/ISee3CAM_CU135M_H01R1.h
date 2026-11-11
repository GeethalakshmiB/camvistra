///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU135M_H01R1.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU135M_H01R1 extension-unit (HID) controls:
//      stream mode, auto exposure/gain limits, AE ROI, black level,
//      brightness, flash, flip, anti-flicker, cross-still, statistics
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU135M_H01R1::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU135M_H01R1.h @brief Declares the ISee3CAM_CU135M_H01R1 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief Streaming trigger mode. */
enum class StreamModeCU135M : uint8_t {
    MODE_MASTER  = 0x00, ///< Free-running (master) mode
    MODE_TRIGGER = 0x01  ///< External trigger mode
};

/** @brief Flash / torch output mode. */
enum class FlashModeCU135M : uint8_t {
    FLASH_OFF    = 0x00, ///< Flash disabled
    FLASH_STROBE = 0x01, ///< Strobe flash
    FLASH_TORCH  = 0x02  ///< Continuous torch
};

/** @brief Image flip / mirror orientation. */
enum class FlipModeCU135M : uint8_t {
    FLIP_NORMAL     = 0x00, ///< No flip
    FLIP_HORIZONTAL = 0x01, ///< Horizontal flip (mirror)
    FLIP_VERTICAL   = 0x02, ///< Vertical flip
    FLIP_BOTH       = 0x03  ///< Both horizontal and vertical flip
};

/** @brief Auto-exposure ROI mode. */
enum class ROIAutoExpModeCU135M : uint8_t {
    AE_Full   = 0x01, ///< Full-frame AE
    AE_Manual = 0x02  ///< Manual ROI window
};

/** @brief Black-level correction enable. */
enum class BlackLevelAdjCU135M : uint8_t {
    ENABLE  = 0x01, ///< Enable black-level correction
    DISABLE = 0x02  ///< Disable black-level correction
};

/** @brief Gain control mode. */
enum class GainModeCU135M : uint8_t {
    AUTO_GAIN   = 0x00, ///< Automatic gain control
    MANUAL_GAIN = 0x01  ///< Manual gain value
};

/** @brief Auto-gain trigger behaviour. */
enum class AutoGainCU135M : uint8_t {
    CONTINUOUS  = 0x00, ///< Continuously adjust gain
    SINGLE_SHOT = 0x01  ///< Single-shot gain adjustment
};

/** @brief Exposure trigger mode. */
enum class ExposureModeCU135M : uint8_t {
    CONTINUOUS_EXPOSURE  = 0x00, ///< Continuous AE
    SINGLE_SHOT_EXPOSURE = 0x01  ///< Single-shot AE
};

/** @brief Anti-flicker suppression mode. */
enum class AntiFlickerCU135M : uint8_t {
    MODE_50Hz    = 0x00, ///< 50 Hz suppression
    MODE_60Hz    = 0x01, ///< 60 Hz suppression
    MODE_DISABLE = 0x02  ///< Anti-flicker disabled
};

// ----------------------------------------------------------------
// Output structs (replace Qt signals)
// ----------------------------------------------------------------

/** @brief Result of getAutoExpROIMode(). */
struct ROIAutoExpResultCU135M {
    uint8_t mode;     ///< ROI mode (ROIAutoExpModeCU135M)
    uint8_t xpos;    ///< Mapped X coordinate [0Ã¢â‚¬â€œ255]
    uint8_t ypos;    ///< Mapped Y coordinate [0Ã¢â‚¬â€œ255]
    uint8_t wnsize; ///< Window size index
};

/** @brief Result of getBrightness(). */
struct BrightnessResultCU135M {
    uint16_t min_value;  ///< Minimum allowed brightness
    uint16_t max_value;  ///< Maximum allowed brightness
    uint16_t value;      ///< Current brightness value
    uint32_t step_value; ///< Brightness step size
};

/** @brief Result of getAutoGainMode(). */
struct GainModeResultCU135M {
    uint8_t  gain_mode;        ///< GainModeCU135M
    uint8_t  auto_gain_mode;   ///< AutoGainCU135M
    uint16_t gain_value;       ///< Current gain value (manual mode)
    uint16_t gain_min;         ///< Minimum gain slider value
    uint16_t gain_max;         ///< Maximum gain slider value
    uint32_t gain_step;        ///< Gain step size
};

/** @brief Result of getAutoGainLimit(). */
struct GainLimitResultCU135M {
    uint16_t lower_limit; ///< Current lower gain limit
    uint16_t upper_limit; ///< Current upper gain limit
    uint16_t min_value;   ///< Minimum achievable gain
    uint16_t max_value;   ///< Maximum achievable gain
    uint32_t step_value;  ///< Gain limit step size
};

/** @brief Result of readStatistics(). */
struct StatisticsResultCU135M {
    uint32_t exposure; ///< Current auto-exposure value (Ã‚Âµs)
    uint16_t gain;     ///< Current auto-gain value
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU135M_H01R1 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU135M_H01R1::create(), instead of using See3CAM_CU135M_H01R1 directly.
 */
class CAMSDK ISee3CAM_CU135M_H01R1 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU135M_H01R1() = default;

    /**
     * @brief Creates the See3CAM_CU135M_H01R1 implementation.
     * @return Owning pointer to a newly created See3CAM_CU135M_H01R1 instance.
     */
    static std::unique_ptr<ISee3CAM_CU135M_H01R1> create();

    // ---- Stream mode ------------------------------------------------

    /**
     * @brief Retrieves the current streaming trigger mode.
     * @param[out] outStreamMode Raw stream mode byte (cast to StreamModeCU135M).
     * @return true on success, false on communication or device error.
     */
    virtual bool getStreamMode(uint8_t &outStreamMode) = 0;

    /**
     * @brief Sets the streaming trigger mode.
     * @param[in] streamMode Desired mode (StreamModeCU135M enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setStreamMode(StreamModeCU135M streamMode) = 0;

    // ---- Flash mode -------------------------------------------------

    /**
     * @brief Retrieves the current flash / torch output mode.
     * @param[out] outFlashMode Raw flash mode byte (cast to FlashModeCU135M).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlashMode(uint8_t &outFlashMode) = 0;

    /**
     * @brief Sets the flash / torch output mode.
     * @param[in] flashMode Desired mode (FlashModeCU135M enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setFlashMode(FlashModeCU135M flashMode) = 0;

    // ---- Orientation ------------------------------------------------

    /**
     * @brief Retrieves the current image flip / mirror orientation.
     * @param[out] outFlipMode Raw orientation byte (cast to FlipModeCU135M).
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

    // ---- Auto-exposure ROI ------------------------------------------

    /**
     * @brief Retrieves the current auto-exposure ROI configuration.
     * @param[out] outRoi Populated with mode, mapped x/y position, and window size.
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoExpROIMode(ROIAutoExpResultCU135M &outRoi) = 0;

    /**
     * @brief Configures the auto-exposure region of interest.
     * @param[in] roiMode  ROI mode (full-frame or manual window).
     * @param[in] vidW     Video frame width in pixels (for coordinate mapping).
     * @param[in] vidH     Video frame height in pixels (for coordinate mapping).
     * @param[in] xCord    X coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] yCord    Y coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] winSize  Window size index for the ROI (manual mode only).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set auto exp roimode. */
    virtual bool setAutoExpROIMode(ROIAutoExpModeCU135M roiMode,
                           uint32_t vidW, uint32_t vidH,
                           uint32_t xCord, uint32_t yCord,
                           uint8_t winSize) = 0;

    // ---- Black-level correction -------------------------------------

    /**
     * @brief Retrieves the current black-level correction state.
     * @param[out] outBlackLevel Raw black-level byte (cast to BlackLevelAdjCU135M).
     * @return true on success, false on communication or device error.
     */
    virtual bool getBlackLevel(uint8_t &outBlackLevel) = 0;

    /**
     * @brief Enables or disables black-level correction.
     * @param[in] blackLevel ENABLE or DISABLE (BlackLevelAdjCU135M enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setBlackLevel(BlackLevelAdjCU135M blackLevel) = 0;

    // ---- Target brightness ------------------------------------------

    /**
     * @brief Retrieves the current target brightness and its valid range.
     * @param[out] outBrightness Populated with current value, min, max, and step.
     * @return true on success, false on communication or device error.
     */
    virtual bool getBrightness(BrightnessResultCU135M &outBrightness) = 0;

    /**
     * @brief Sets the target brightness value.
     * @param[in] brightnessValue Desired brightness (within the reported minÃ¢â‚¬â€œmax range).
     * @return true on success, false on communication or device error.
     */
    virtual bool setBrightness(uint16_t brightnessValue) = 0;

    // ---- Auto gain mode ---------------------------------------------

    /**
     * @brief Retrieves the current gain mode and all gain parameters.
     * @param[out] outGain Populated with mode, auto-gain feature, current value, range, and step.
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoGainMode(GainModeResultCU135M &outGain) = 0;

    /**
     * @brief Configures the gain control mode.
     * @param[in] gainMode      AUTO_GAIN or MANUAL_GAIN.
     * @param[in] autoGainMode CONTINUOUS or SINGLE_SHOT (relevant in auto mode).
     * @param[in] gainValue     Manual gain value (relevant in manual mode).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set auto gain mode. */
    virtual bool setAutoGainMode(GainModeCU135M gainMode,
                         AutoGainCU135M autoGainMode,
                         uint16_t gainValue) = 0;

    // ---- Auto gain limit --------------------------------------------

    /**
     * @brief Retrieves the auto-gain upper/lower limits and the valid slider range.
     * @param[out] outGainLimit Populated with lower/upper limits, min/max values, and step.
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoGainLimit(GainLimitResultCU135M &outGainLimit) = 0;

    /**
     * @brief Sets the auto-gain lower and upper limits.
     * @param[in] lowerLimit Lower gain boundary (must be Ã¢â€°Â¤ upperLimit).
     * @param[in] upperLimit Upper gain boundary.
     * @return true on success, false if limits are invalid or on device error.
     */
    /** @brief Performs set auto gain limit. */
    virtual bool setAutoGainLimit(uint16_t lowerLimit, uint16_t upperLimit) = 0;

    // ---- Auto-exposure mode -----------------------------------------

    /**
     * @brief Retrieves the current auto-exposure trigger mode.
     * @param[out] outExpMode Raw exposure mode byte (cast to ExposureModeCU135M).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoExposureMode(uint8_t &outExpMode) = 0;

    /**
     * @brief Sets the auto-exposure trigger mode.
     * @param[in] expMode CONTINUOUS_EXPOSURE or SINGLE_SHOT_EXPOSURE.
     * @return true on success, false on communication or device error.
     */
    virtual bool setAutoExposureMode(ExposureModeCU135M expMode) = 0;

    // ---- Exposure limits --------------------------------------------

    /**
     * @brief Retrieves the current auto-exposure lower limit.
     * @param[out] outLowerLimit Exposure lower limit in microseconds.
     * @return true on success, false on communication or device error.
     */
    virtual bool getExposureLowerLimit(uint32_t &outLowerLimit) = 0;

    /**
     * @brief Sets the auto-exposure lower limit.
     * @param[in] lowerLimit Lower exposure limit in microseconds
     *            (must be Ã¢â€°Â¥ EXPOSURE_LIMIT_MIN_CU135M_H01R1 and Ã¢â€°Â¤ upper limit).
     * @return true on success, false if value is out of range or on device error.
     */
    /** @brief Performs set exposure lower limit. */
    virtual bool setExposureLowerLimit(uint32_t lowerLimit) = 0;

    /**
     * @brief Retrieves the current auto-exposure upper limit.
     * @param[out] outUpperLimit Exposure upper limit in microseconds.
     * @return true on success, false on communication or device error.
     */
    virtual bool getExposureUpperLimit(uint32_t &outUpperLimit) = 0;

    /**
     * @brief Sets the auto-exposure upper limit.
     * @param[in] upperLimit Upper exposure limit in microseconds
     *            (must be Ã¢â€°Â¤ EXPOSURE_LIMIT_MAX_CU135M_H01R1 and Ã¢â€°Â¥ lower limit).
     * @return true on success, false if value is out of range or on device error.
     */
    /** @brief Performs set exposure upper limit. */
    virtual bool setExposureUpperLimit(uint32_t upperLimit) = 0;

    // ---- Anti-flicker -----------------------------------------------

    /**
     * @brief Retrieves the current anti-flicker suppression mode.
     * @param[out] outFlicker Raw flicker mode byte (cast to AntiFlickerCU135M).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAntiFlickerMode(uint8_t &outFlicker) = 0;

    /**
     * @brief Sets the anti-flicker suppression mode.
     * @param[in] flickerMode Desired mode (AntiFlickerCU135M enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAntiFlickerMode(AntiFlickerCU135M flickerMode) = 0;

    // ---- Statistics -------------------------------------------------

    /**
     * @brief Reads the live auto-exposure and auto-gain statistics from the camera.
     * @param[out] outStats Populated with current exposure (Ã‚Âµs) and gain values.
     * @return true on success, false on communication or device error.
     */
    virtual bool readStatistics(StatisticsResultCU135M &outStats) = 0;

    // ---- Misc -------------------------------------------------------

    /**
     * @brief Restores all camera settings to their factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool restoreDefault() = 0;

    /**
     * @brief Sets gain, brightness, and exposure properties for cross-resolution still capture.
     * @param[in] enable true to apply cross-still properties, false to disable.
     * @return true on success, false on communication or device error.
     */
    virtual bool setCrossStillProperties(bool enable) = 0;

	 /**
	 * @brief Reads the firmware version from the device.
	 * @param[out] version Reference to a string that will contain the firmware version (e.g., "v1.0.3").
	 * @return true on successful retrieval, false on communication or device error.
	 */
	virtual bool readFirmwareVersion(std::string &version) = 0;

	 /**
	 * @brief Reads the firmware version from the device.
	 * @param[out] version Reference to a string that will contain the firmware version (e.g., "v1.0.3").
	 * @return true on successful retrieval, false on communication or device error.
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
