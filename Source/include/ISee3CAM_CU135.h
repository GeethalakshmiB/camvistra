///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU135.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU135 extension-unit (HID) controls:
//      stream mode, scene/effects, HDR, AE ROI, exposure compensation,
//      face and smile detection, flicker, orientation, denoise, burst
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU135::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU135.h @brief Declares the ISee3CAM_CU135 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>

// ----------------------------------------------------------------
// Exposure compensation limits
// ----------------------------------------------------------------
#define EXPOSURE_COMP_MIN_CU135                     8000
#define EXPOSURE_COMP_MAX_CU135                     1000000


// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief Camera scene mode. */
enum class SceneModeCU135 : uint8_t {
    SCENE_NORMAL   = 0x01, ///< Normal scene
    SCENE_DOCUMENT = 0x0C  ///< Document scene
};

/** @brief Special image effects. */
enum class SpecialEffectCU135 : uint8_t {
    EFFECT_NORMAL      = 0x01, ///< No effect
    EFFECT_BLACK_WHITE = 0x04, ///< Black and white
    EFFECT_GREYSCALE   = 0x07, ///< Greyscale
    EFFECT_NEGATIVE    = 0x08, ///< Negative
    EFFECT_SKETCH      = 0x10  ///< Sketch
};

/** @brief iHDR mode. */
enum class HDRModeCU135 : uint8_t {
    HDR_OFF    = 0x01, ///< HDR disabled
    HDR_AUTO   = 0x02, ///< Automatic HDR
    HDR_MANUAL = 0x03  ///< Manual HDR with an explicit exposure value
};

/** @brief Streaming trigger mode. */
enum class StreamModeCU135 : uint8_t {
    STREAM_MASTER  = 0x00, ///< Free-running (master) mode
    STREAM_TRIGGER = 0x01  ///< External trigger mode
};

/** @brief Image flip / mirror orientation. */
enum class FlipModeCU135 : uint8_t {
    FLIP_NORMAL     = 0x00, ///< No flip
    FLIP_HORIZONTAL = 0x01, ///< Horizontal flip (mirror)
    FLIP_VERTICAL   = 0x02, ///< Vertical flip
    FLIP_BOTH       = 0x03  ///< Both horizontal and vertical flip
};

/** @brief Auto-exposure ROI mode. */
enum class ROIAutoExpModeCU135 : uint8_t {
    AE_Face     = 0x00, ///< Face-based AE
    AE_Full     = 0x01, ///< Full-frame AE
    AE_Manual   = 0x02, ///< Manual ROI window
    AE_Disabled = 0x03  ///< AE ROI disabled
};

/** @brief Anti-flicker / flicker detection mode. */
enum class FlickerModeCU135 : uint8_t {
    MODE_AUTO    = 0x00, ///< Auto-detect flicker frequency
    MODE_50Hz    = 0x01, ///< Force 50 Hz suppression
    MODE_60Hz    = 0x02, ///< Force 60 Hz suppression
    MODE_DISABLE = 0x03  ///< Disable flicker suppression
};

// ----------------------------------------------------------------
// Output structs
// ----------------------------------------------------------------

/** @brief Result of getExpROIMode(). */
struct ROIAutoExpResultCU135 {
    uint8_t mode;     ///< ROI mode (ROIAutoExpModeCU135)
    uint8_t xpos;    ///< Mapped X coordinate [0Ã¢â‚¬â€œ255]
    uint8_t ypos;    ///< Mapped Y coordinate [0Ã¢â‚¬â€œ255]
    uint8_t wnsize; ///< Window size index
};

/** @brief Result of getHDRMode(). */
struct HDRModeResultCU135 {
    uint8_t mode;  ///< HDR mode (HDRModeCU135)
    uint8_t value; ///< HDR value (relevant in manual mode)
};

/** @brief Result of getFaceDetectionRect(). */
struct FaceDetectResultCU135 {
    uint8_t state;        ///< Face detection rect state (enable/disable)
    uint8_t embedData;   ///< Embed data state (enable/disable)
    uint8_t overlayrect; ///< Overlay rect state (enable/disable)
};

/** @brief Result of getSmileDetection(). */
struct SmileDetectResultCU135 {
    uint8_t state;      ///< Smile detection state (enable/disable)
    uint8_t embedData; ///< Embed data state (enable/disable)
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU135 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU135::create(), instead of using See3CAM_CU135 directly.
 */
class CAMSDK ISee3CAM_CU135 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU135() = default;

    /**
     * @brief Creates the See3CAM_CU135 implementation.
     * @return Owning pointer to a newly created See3CAM_CU135 instance.
     */
    static std::unique_ptr<ISee3CAM_CU135> create();

    // ---- Platform initialisation ------------------------------------

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

    /**
     * @brief (Linux only) Initialises the HID channel using an open file descriptor.
     * @param[in] fd Open file descriptor for the camera HID device node.
     * @return true on success; always false on Windows.
     */
    virtual bool setHidFd(int fd) = 0;

    // ---- Scene mode -------------------------------------------------

    /**
     * @brief Retrieves the current scene mode.
     * @param[out] outSceneMode Raw scene mode byte (cast to SceneModeCU135).
     * @return true on success, false on communication or device error.
     */
    virtual bool getSceneMode(uint8_t &outSceneMode) = 0;

    /**
     * @brief Sets the scene mode.
     * @param[in] sceneMode Desired mode (SceneModeCU135 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setSceneMode(SceneModeCU135 sceneMode) = 0;

    // ---- Special effects --------------------------------------------

    /**
     * @brief Retrieves the current special image effect.
     * @param[out] outEffects Raw effect byte (cast to SpecialEffectCU135).
     * @return true on success, false on communication or device error.
     */
    virtual bool getSpecialEffects(uint8_t &outEffects) = 0;

    /**
     * @brief Sets the special image effect.
     * @param[in] effects Desired effect (SpecialEffectCU135 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setSpecialEffects(SpecialEffectCU135 effects) = 0;

    // ---- Denoise ----------------------------------------------------

    /**
     * @brief Retrieves the current denoise value.
     * @param[out] outDenoise Denoise value [0Ã¢â‚¬â€œ255].
     * @return true on success, false on communication or device error.
     */
    virtual bool getDenoiseValue(uint8_t &outDenoise) = 0;

    /**
     * @brief Sets the denoise value.
     * @param[in] denoise Denoise value to apply [0Ã¢â‚¬â€œ255].
     * @return true on success, false on communication or device error.
     */
    virtual bool setDenoiseValue(uint8_t denoise) = 0;

    // ---- Exposure ROI -----------------------------------------------

    /**
     * @brief Retrieves the current auto-exposure ROI configuration.
     * @param[out] outRoi Populated with mode, mapped x/y position, and window size.
     * @return true on success, false on communication or device error.
     */
    virtual bool getExpROIMode(ROIAutoExpResultCU135 &outRoi) = 0;

    /**
     * @brief Configures the auto-exposure region of interest.
     * @param[in] roiMode  ROI mode (full-frame, face, manual, or disabled).
     * @param[in] vidW     Video frame width in pixels (for coordinate mapping).
     * @param[in] vidH     Video frame height in pixels (for coordinate mapping).
     * @param[in] xCord    X coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] yCord    Y coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] winSize  Window size index for the ROI (manual mode only).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set exp roimode. */
    virtual bool setExpROIMode(ROIAutoExpModeCU135 roiMode,
                       uint32_t vidW, uint32_t vidH,
                       uint32_t xCord, uint32_t yCord,
                       uint8_t winSize) = 0;

    // ---- Burst length -----------------------------------------------

    /**
     * @brief Retrieves the current burst capture length.
     * @param[out] outBurstLen Burst length value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getBurstLength(uint8_t &outBurstLen) = 0;

    /**
     * @brief Sets the burst capture length.
     * @param[in] burstLen Number of images to capture in burst mode.
     * @return true on success, false on communication or device error.
     */
    virtual bool setBurstLength(uint8_t burstLen) = 0;

    // ---- HDR mode ---------------------------------------------------

    /**
     * @brief Retrieves the current iHDR mode and value.
     * @param[out] outHdr Populated with HDR mode and value (relevant in manual mode).
     * @return true on success, false on communication or device error.
     */
    virtual bool getHDRMode(HDRModeResultCU135 &outHdr) = 0;

    /**
     * @brief Sets the iHDR mode.
     * @param[in] hdrMode  Desired HDR mode (HDRModeCU135 enum value).
     * @param[in] hdrValue HDR exposure value (relevant when hdrMode is HDR_MANUAL).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set hdrmode. */
    virtual bool setHDRMode(HDRModeCU135 hdrMode, uint8_t hdrValue) = 0;

    // ---- Q-factor ---------------------------------------------------

    /**
     * @brief Retrieves the current JPEG Q-factor.
     * @param[out] outQFactor Q-factor value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getQFactor(uint8_t &outQFactor) = 0;

    /**
     * @brief Sets the JPEG Q-factor.
     * @param[in] qFactor Q-factor value to apply.
     * @return true on success, false on communication or device error.
     */
    virtual bool setQFactor(uint8_t qFactor) = 0;

    // ---- Stream mode ------------------------------------------------

    /**
     * @brief Retrieves the current streaming trigger mode.
     * @param[out] outStreamMode Raw stream mode byte (cast to StreamModeCU135).
     * @return true on success, false on communication or device error.
     */
    virtual bool getStreamMode(uint8_t &outStreamMode) = 0;

    /**
     * @brief Sets the streaming trigger mode.
     * @param[in] streamMode Desired mode (StreamModeCU135 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setStreamMode(StreamModeCU135 streamMode) = 0;

    // ---- Factory restore --------------------------------------------

    /**
     * @brief Restores all camera settings to factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool setToDefault() = 0;

    // ---- Orientation / flip -----------------------------------------

    /**
     * @brief Retrieves the current image flip / mirror orientation.
     * @param[out] outFlipMode Raw orientation byte (cast to FlipModeCU135).
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

    // ---- Face detection rect ----------------------------------------

    /**
     * @brief Retrieves the current face detection rectangle configuration.
     * @param[out] outFaceDetect Populated with state, embed-data flag, and overlay-rect flag.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFaceDetectionRect(FaceDetectResultCU135 &outFaceDetect) = 0;

    /**
     * @brief Configures the face detection rectangle.
     * @param[in] enable       true to enable face detection rectangle.
     * @param[in] embedData   true to embed detection data in the stream.
     * @param[in] overlayRect true to draw the detection rectangle as an overlay.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set face detection rect. */
    virtual bool setFaceDetectionRect(bool enable, bool embedData, bool overlayRect) = 0;

    /**
     * @brief Enables or disables the face rectangle overlay independently.
     *
     * Used to temporarily suppress the overlay rectangle before still capture
     * or video recording, and to restore it afterwards.
     *
     * @param[in] enable true to enable the face rectangle overlay, false to disable it.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs enable disable face rectangle. */
    virtual bool enableDisableFaceRectangle(bool enable) = 0;

    // ---- Smile detection --------------------------------------------

    /**
     * @brief Retrieves the current smile detection configuration.
     * @param[out] outSmileDetect Populated with state and embed-data flag.
     * @return true on success, false on communication or device error.
     */
    virtual bool getSmileDetection(SmileDetectResultCU135 &outSmileDetect) = 0;

    /**
     * @brief Configures smile detection.
     * @param[in] enable     true to enable smile detection.
     * @param[in] embedData true to embed detection data in the stream.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set smile detection. */
    virtual bool setSmileDetection(bool enable, bool embedData) = 0;

    // ---- Exposure compensation --------------------------------------

    /**
     * @brief Retrieves the current exposure compensation value.
     * @param[out] outExposure Exposure compensation value in microseconds
     *             (range: EXPOSURE_COMP_MIN_CU135 Ã¢â‚¬â€œ EXPOSURE_COMP_MAX_CU135).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs get exposure compensation. */
    virtual bool getExposureCompensation(uint32_t &outExposure) = 0;

    /**
     * @brief Sets the exposure compensation value.
     * @param[in] exposure Desired exposure compensation in microseconds
     *            (range: EXPOSURE_COMP_MIN_CU135 Ã¢â‚¬â€œ EXPOSURE_COMP_MAX_CU135).
     * @return true on success, false if the value is out of range or on device error.
     */
    /** @brief Performs set exposure compensation. */
    virtual bool setExposureCompensation(uint32_t exposure) = 0;

    // ---- Frame rate control -----------------------------------------

    /**
     * @brief Retrieves the current frame rate control value.
     * @param[out] outFrameRate Frame rate value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFrameRateCtrlValue(uint8_t &outFrameRate) = 0;

    /**
     * @brief Sets the frame rate control value.
     * @param[in] frameRate Desired frame rate value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setFrameRateCtrlValue(uint8_t frameRate) = 0;

    // ---- Anti-flicker detection -------------------------------------

    /**
     * @brief Retrieves the current anti-flicker / flicker detection mode.
     * @param[out] outFlickerMode Raw flicker mode byte (cast to FlickerModeCU135).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlickerDetection(uint8_t &outFlickerMode) = 0;

    /**
     * @brief Sets the anti-flicker / flicker detection mode.
     * @param[in] flickerMode Desired mode (FlickerModeCU135 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setFlickerDetection(FlickerModeCU135 flickerMode) = 0;
};

} // namespace eCamSDK
