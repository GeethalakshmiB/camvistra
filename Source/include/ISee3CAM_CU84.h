///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU84.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU84 extension-unit (HID) controls:
//      stream mode, exposure, WB pro mode, RGB gain, motion detection,
//      face detection, flash, flip, effects, denoise, burst
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU84::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU84.h @brief Declares the ISee3CAM_CU84 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>


// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief Special effect / colour filter mode. */
enum class SpecialEffectCU84 : uint8_t {
    NORMAL      = 0x01, ///< Normal (no effect)
    BLACK_WHITE = 0x04, ///< Black and white
    GREYSCALE   = 0x07, ///< Greyscale
    NEGATIVE    = 0x08, ///< Negative
    SKETCH      = 0x10  ///< Sketch
};

/** @brief Auto-exposure region-of-interest mode. */
enum class ROIAutoExpModeCU84 : uint8_t {
    FULL_ROI   = 0x01, ///< Full-frame AE
    MANUAL_ROI = 0x02  ///< Manual ROI window
};

/** @brief Image flip / mirror orientation. */
enum class FlipModeCU84 : uint8_t {
    NORMAL     = 0x00, ///< No flip
    HORIZONTAL = 0x01, ///< Horizontal flip (mirror)
    VERTICAL   = 0x02, ///< Vertical flip
    BOTH       = 0x03  ///< Both horizontal and vertical flip
};

/** @brief Anti-flicker suppression mode. */
enum class AntiFlickerCU84 : uint8_t {
    MODE_AUTO    = 0x00, ///< Auto-detect
    MODE_50Hz    = 0x01, ///< 50 Hz suppression
    MODE_60Hz    = 0x02, ///< 60 Hz suppression
    MODE_DISABLE = 0x03  ///< Anti-flicker disabled
};

/** @brief Streaming trigger mode. */
enum class StreamModeCU84 : uint8_t {
    MASTER_MODE  = 0x00, ///< Free-running (master) mode
    TRIGGER_MODE = 0x01  ///< External trigger mode
};

/** @brief Flash / strobe output mode. */
enum class FlashModeCU84 : uint8_t {
    STROBE_OFF = 0x00, ///< Flash disabled
    STROBE_ON  = 0x01  ///< Strobe flash enabled
};

// ----------------------------------------------------------------
// Output structs (replace Qt signals / multiple out-params)
// ----------------------------------------------------------------

/** @brief Result of getAutoExpROIMode(). */
struct ROIAutoExpResultCU84 {
    uint8_t mode;     ///< ROI mode (ROIAutoExpModeCU84)
    uint8_t xpos;    ///< Mapped X coordinate [0Ã¢â‚¬â€œ255]
    uint8_t ypos;    ///< Mapped Y coordinate [0Ã¢â‚¬â€œ255]
    uint8_t wnsize; ///< Window size index
};

/** @brief Result of getFrameRateCtrl(). */
struct FrameRateResultCU84 {
    uint8_t ctrl_value; ///< Current frame-rate control value
    uint8_t min_fps;    ///< Minimum supported frame rate
    uint8_t max_fps;    ///< Maximum supported frame rate
};

/** @brief Result of getFaceDetection(). */
struct FaceDetectResultCU84 {
    uint8_t option;       ///< Face detection enable option
    uint8_t overlayrect; ///< Overlay rectangle enable flag
    uint8_t embedData;   ///< Embed data enable flag
};

/** @brief Result of getExposure(). */
struct ExposureResultCU84 {
    uint8_t  mode;  ///< Exposure mode (0 = auto, 1 = manual)
    uint32_t value; ///< Exposure value (microseconds in manual mode)
};

/** @brief Result of getWBProMode(). */
struct WBProModeResultCU84 {
    uint8_t  proMode; ///< White-balance pro mode value
    uint32_t rGain;   ///< Current red channel gain
    uint32_t gGain;   ///< Current green channel gain
    uint32_t bGain;   ///< Current blue channel gain
    uint32_t gain_min; ///< Minimum achievable RGB gain
    uint32_t gain_max; ///< Maximum achievable RGB gain
};

/** @brief Result of getRGBGain(). */
struct RGBGainResultCU84 {
    uint32_t rGain; ///< Current red channel gain
    uint32_t gGain; ///< Current green channel gain
    uint32_t bGain; ///< Current blue channel gain
};

/** @brief Result of getMotionDetectSensitivity(). */
struct MotionDetectSensitivityResultCU84 {
    uint16_t current; ///< Current sensitivity value
    uint16_t minimum; ///< Minimum sensitivity
    uint16_t maximum; ///< Maximum sensitivity
};

/** @brief Result of getMotionDetectZoneMask(). */
struct MotionDetectZoneMaskResultCU84 {
    uint16_t zone[9]; ///< Zone mask values for zones 0Ã¢â‚¬â€œ8
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU84 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU84::create(), instead of using See3CAM_CU84 directly.
 */
class CAMSDK ISee3CAM_CU84 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU84() = default;

    /**
     * @brief Creates the See3CAM_CU84 implementation.
     * @return Owning pointer to a newly created See3CAM_CU84 instance.
     */
    static std::unique_ptr<ISee3CAM_CU84> create();

    // ---- Special effects --------------------------------------------

    /**
     * @brief Retrieves the current special colour effect.
     * @param[out] outEffect Raw effect byte (cast to SpecialEffectCU84).
     * @return true on success, false on communication or device error.
     */
    virtual bool getSpecialEffect(uint8_t &outEffect) = 0;

    /**
     * @brief Sets the special colour effect.
     * @param[in] effect Desired effect (SpecialEffectCU84 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setSpecialEffect(SpecialEffectCU84 effect) = 0;

    // ---- Denoise ----------------------------------------------------

    /**
     * @brief Retrieves the current denoise level.
     * @param[out] outDenoise Denoise value [0Ã¢â‚¬â€œ255].
     * @return true on success, false on communication or device error.
     */
    virtual bool getDenoiseValue(uint8_t &outDenoise) = 0;

    /**
     * @brief Sets the denoise level.
     * @param[in] denoiseValue Desired denoise value [0Ã¢â‚¬â€œ255].
     * @return true on success, false on communication or device error.
     */
    virtual bool setDenoiseValue(uint8_t denoiseValue) = 0;

    // ---- Auto-exposure ROI ------------------------------------------

    /**
     * @brief Retrieves the current auto-exposure ROI configuration.
     * @param[out] outRoi Populated with mode, mapped x/y position, and window size.
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoExpROIMode(ROIAutoExpResultCU84 &outRoi) = 0;

    /**
     * @brief Configures the auto-exposure region of interest.
     * @param[in] roimode  ROI mode (full-frame or manual window).
     * @param[in] vidW     Video frame width in pixels (for coordinate mapping).
     * @param[in] vidH     Video frame height in pixels (for coordinate mapping).
     * @param[in] xCord    X coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] yCord    Y coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] wnsize  Window size index for the ROI (manual mode only).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set auto exp roimode. */
    virtual bool setAutoExpROIMode(ROIAutoExpModeCU84 roimode,
                           uint32_t vidW, uint32_t vidH,
                           uint32_t xCord, uint32_t yCord,
                           uint8_t wnsize) = 0;

    // ---- Burst length -----------------------------------------------

    /**
     * @brief Retrieves the current still-capture burst length.
     * @param[out] outburstlength Number of images captured per burst trigger.
     * @return true on success, false on communication or device error.
     */
    virtual bool getBurstLength(uint8_t &outburstlength) = 0;

    /**
     * @brief Sets the still-capture burst length.
     * @param[in] burstlength Desired number of images per burst.
     * @return true on success, false on communication or device error.
     */
    virtual bool setBurstLength(uint8_t burstlength) = 0;

    // ---- Orientation / flip -----------------------------------------

    /**
     * @brief Retrieves the current image flip / mirror orientation.
     * @param[out] outFlipMode Raw orientation byte (cast to FlipModeCU84).
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

    // ---- Exposure compensation --------------------------------------

    /**
     * @brief Retrieves the current exposure compensation value.
     * @param[out] outExpComp Exposure compensation value in the range
     *             [EXPOSURE_COMP_MIN_CU84, EXPOSURE_COMP_MAX_CU84].
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs get exposure compensation. */
    virtual bool getExposureCompensation(uint32_t &outExpComp) = 0;

    /**
     * @brief Sets the exposure compensation value.
     * @param[in] expComp Desired value in the range
     *            [EXPOSURE_COMP_MIN_CU84, EXPOSURE_COMP_MAX_CU84].
     * @return true on success, false if value is out of range or on device error.
     */
    /** @brief Performs set exposure compensation. */
    virtual bool setExposureCompensation(uint32_t expComp) = 0;

    // ---- Frame rate control -----------------------------------------

    /**
     * @brief Retrieves the current frame-rate control setting and its limits.
     * @param[out] outFps Populated with current control value, minimum fps, and maximum fps.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFrameRateCtrl(FrameRateResultCU84 &outFps) = 0;

    /**
     * @brief Sets the frame-rate control value.
     * @param[in] frameRate Desired frame-rate control value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setFrameRateCtrl(uint8_t frameRate) = 0;

    // ---- Anti-flicker -----------------------------------------------

    /**
     * @brief Retrieves the current anti-flicker suppression mode.
     * @param[out] outFlicker Raw flicker mode byte (cast to AntiFlickerCU84).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAntiFlickerMode(uint8_t &outFlicker) = 0;

    /**
     * @brief Sets the anti-flicker suppression mode.
     * @param[in] flickerMode Desired mode (AntiFlickerCU84 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAntiFlickerMode(AntiFlickerCU84 flickerMode) = 0;

    // ---- Stream mode ------------------------------------------------

    /**
     * @brief Retrieves the current streaming trigger mode.
     * @param[out] outStreamMode Raw stream mode byte (cast to StreamModeCU84).
     * @return true on success, false on communication or device error.
     */
    virtual bool getStreamMode(uint8_t &outStreamMode) = 0;

    /**
     * @brief Sets the streaming trigger mode.
     * @param[in] streamMode Desired mode (StreamModeCU84 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setStreamMode(StreamModeCU84 streamMode) = 0;

    // ---- Flash mode -------------------------------------------------

    /**
     * @brief Retrieves the current flash / strobe output mode.
     * @param[out] outFlashMode Raw flash mode byte (cast to FlashModeCU84).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlashMode(uint8_t &outFlashMode) = 0;

    /**
     * @brief Sets the flash / strobe output mode.
     * @param[in] flashMode Desired mode (FlashModeCU84 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setFlashMode(FlashModeCU84 flashMode) = 0;

    // ---- Face detection ---------------------------------------------

    /**
     * @brief Retrieves the current face-detection configuration.
     * @param[out] outFaceDetect Populated with enable option, overlay-rectangle flag, and embed-data flag.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFaceDetection(FaceDetectResultCU84 &outFaceDetect) = 0;

    /**
     * @brief Configures the face-detection feature.
     * @param[in] enableRect  true to enable face-detection rectangles.
     * @param[in] overlayrect true to enable overlay rectangles on detected faces.
     * @param[in] embedData   true to embed face-detection metadata in the stream.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set face detection. */
    virtual bool setFaceDetection(bool enableRect, bool overlayrect, bool embedData) = 0;

    // ---- Q-factor ---------------------------------------------------

    /**
     * @brief Retrieves the current JPEG Q-factor.
     * @param[out] outQFactor Q-factor value [1Ã¢â‚¬â€œ100].
     * @return true on success, false on communication or device error.
     */
    virtual bool getQFactor(uint8_t &outQFactor) = 0;

    /**
     * @brief Sets the JPEG Q-factor.
     * @param[in] qFactor Desired Q-factor value [1Ã¢â‚¬â€œ100].
     * @return true on success, false on communication or device error.
     */
    virtual bool setQFactor(uint8_t qFactor) = 0;

    // ---- Motion detection sensitivity (extended) --------------------

    /**
     * @brief Retrieves motion-detection sensitivity and its valid range.
     * @param[out] outSensitivity Populated with current, minimum, and maximum sensitivity.
     * @return true on success, false on communication or device error.
     */
    virtual bool getMotionDetectSensitivity(MotionDetectSensitivityResultCU84 &outSensitivity) = 0;

    /**
     * @brief Sets the motion-detection sensitivity.
     * @param[in] sensitivity Desired sensitivity value (within the reported range).
     * @return true on success, false on communication or device error.
     */
    virtual bool setMotionDetectSensitivity(uint16_t sensitivity) = 0;

    // ---- Motion detection zone mask (extended) ----------------------

    /**
     * @brief Retrieves the motion-detection zone mask values for all nine zones.
     * @param[out] outZoneMask Populated with 16-bit mask values for zones 0Ã¢â‚¬â€œ8.
     * @return true on success, false on communication or device error.
     */
    virtual bool getMotionDetectZoneMask(MotionDetectZoneMaskResultCU84 &outZoneMask) = 0;

    // ---- Exposure (extended) ----------------------------------------

    /**
     * @brief Retrieves the current exposure mode and value.
     * @param[out] outExposure Populated with exposure mode and value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getExposure(ExposureResultCU84 &outExposure) = 0;

    /**
     * @brief Sets the exposure mode and value.
     * @param[in] mode  Exposure mode (0 = auto, 1 = manual).
     * @param[in] value Exposure value in microseconds (relevant in manual mode).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set exposure. */
    virtual bool setExposure(uint8_t mode, uint32_t value) = 0;

    // ---- White-balance pro mode (extended) --------------------------

    /**
     * @brief Retrieves the white-balance pro mode and all RGB gain parameters.
     * @param[out] out_wb Populated with pro mode, current R/G/B gains, and gain range.
     * @return true on success, false on communication or device error.
     */
    virtual bool getWBProMode(WBProModeResultCU84 &out_wb) = 0;

    /**
     * @brief Sets the white-balance pro mode.
     * @param[in] proMode Desired white-balance pro mode value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setWBProMode(uint8_t proMode) = 0;

    // ---- RGB gain (extended) ----------------------------------------

    /**
     * @brief Retrieves the current RGB channel gains.
     * @param[out] outGain Populated with current R, G, and B gain values.
     * @return true on success, false on communication or device error.
     */
    virtual bool getRGBGain(RGBGainResultCU84 &outGain) = 0;

    /**
     * @brief Sets the RGB channel gains.
     * @param[in] setMode  Gain application mode (e.g. 0 = apply immediately).
     * @param[in] rGain    Desired red channel gain.
     * @param[in] gGain    Desired green channel gain.
     * @param[in] bGain    Desired blue channel gain.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set rgbgain. */
    virtual bool setRGBGain(uint8_t setMode, uint32_t rGain, uint32_t gGain, uint32_t bGain) = 0;

    // ---- Restore defaults -------------------------------------------

    /**
     * @brief Restores all camera settings to their factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool restoreDefault() = 0;

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
     * @param[in] device_path Wide-character device path from HID enumeration.
     * @return true on success, false if the device could not be opened.
     */
    virtual bool initFromDevicePath(TCHAR *device_path) = 0;

    /**
     * @brief (Windows only) Closes the HID extension unit and releases the device handle.
     */
    virtual void deinitExtensionUnit() = 0;
#endif
    ///@}
};

} // namespace eCamSDK
