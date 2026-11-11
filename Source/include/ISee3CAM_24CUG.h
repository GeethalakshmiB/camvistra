///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_24CUG.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_24CUG extension-unit (HID) controls:
//      stream mode, AE ROI, exposure compensation, face detect, flash,
//      flicker, flip, effects, denoise, burst, Q-factor, frame rate
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_24CUG::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_24CUG.h @brief Declares the ISee3CAM_24CUG interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief Special image effects mode. */
enum class SpecialEffects24CUG : uint8_t {
    EFFECT_NORMAL      = 0x01, ///< Normal (no effect)
    EFFECT_BLACK_WHITE = 0x04, ///< Black and White
    EFFECT_GREYSCALE   = 0x07, ///< Greyscale
    EFFECT_NEGATIVE    = 0x08, ///< Negative
    EFFECT_SKETCH      = 0x10  ///< Sketch
};

/** @brief Auto-exposure ROI mode. */
enum class ROIAutoExpMode24CUG : uint8_t {
    AE_Face     = 0x00, ///< Face-based AE
    AE_Full     = 0x01, ///< Full-frame AE
    AE_Manual   = 0x02, ///< Manual ROI window
    AE_Disabled = 0x03  ///< AE ROI disabled
};

/** @brief Image flip / mirror orientation. */
enum class FlipMode24CUG : uint8_t {
    FLIP_NORMAL     = 0x00, ///< No flip
    FLIP_HORIZONTAL = 0x01, ///< Horizontal flip (mirror)
    FLIP_VERTICAL   = 0x02, ///< Vertical flip
    FLIP_BOTH       = 0x03  ///< Both horizontal and vertical flip
};

/** @brief Flash / strobe output mode. */
enum class FlashMode24CUG : uint8_t {
    FLASH_OFF    = 0x00, ///< Flash disabled
    FLASH_STROBE = 0x01  ///< Strobe flash
};

/** @brief Anti-flicker suppression mode. */
enum class FlickerMode24CUG : uint8_t {
    MODE_DISABLE = 0x00,  ///< Anti-flicker disabled
    MODE_50Hz    = 0x01, ///< 50 Hz suppression
    MODE_60Hz    = 0x02, ///< 60 Hz suppression
    MODE_AUTO    = 0x03 ///< Auto detect
};

/** @brief Streaming trigger mode. */
enum class StreamMode24CUG : uint8_t {
    MODE_MASTER  = 0x00, ///< Free-running (master) mode
    MODE_TRIGGER = 0x01  ///< External trigger mode
};

// ----------------------------------------------------------------
// Output structs (replace Qt signals)
// ----------------------------------------------------------------

/** @brief Result of getAutoExpROIMode(). */
struct ROIAutoExpResult24CUG {
    uint8_t mode;     ///< ROI mode (ROIAutoExpMode24CUG)
    uint8_t xpos;    ///< Mapped X coordinate [0-255]
    uint8_t ypos;    ///< Mapped Y coordinate [0-255]
    uint8_t wnsize; ///< Window size index
};

/** @brief Result of getFaceDetectMode(). */
struct FaceDetectResult24CUG {
    uint8_t state;        ///< Face detect enable state
    uint8_t embedData;   ///< Embed data state
    uint8_t overlayrect; ///< Overlay rectangle state
};

/** @brief Result of getStreamMode(). */
struct StreamModeResult24CUG {
    uint8_t mode;               ///< Stream mode (StreamMode24CUG)
    uint8_t autofunclock; ///< Auto function lock state (0 = unlocked, 1 = locked)
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_24CUG camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_24CUG::create(), instead of using See3CAM_24CUG directly.
 */
class CAMSDK ISee3CAM_24CUG {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_24CUG() = default;

    /**
     * @brief Creates the See3CAM_24CUG implementation.
     * @return Owning pointer to a newly created See3CAM_24CUG instance.
     */
    static std::unique_ptr<ISee3CAM_24CUG> create();

    // ---- Special effects --------------------------------------------

    /**
     * @brief Retrieves the current special effects mode.
     * @param[out] outEffectMode Raw effect mode byte (cast to SpecialEffects24CUG).
     * @return true on success, false on communication or device error.
     */
    virtual bool getEffectMode(uint8_t &outEffectMode) = 0;

    /**
     * @brief Sets the special effects mode.
     * @param[in] effect Desired effect (SpecialEffects24CUG enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setEffectMode(SpecialEffects24CUG effect) = 0;

    // ---- Denoise ----------------------------------------------------

    /**
     * @brief Retrieves the current denoise value.
     * @param[out] outDenoise Current denoise level [0-255].
     * @return true on success, false on communication or device error.
     */
    virtual bool getDenoiseValue(uint8_t &outDenoise) = 0;

    /**
     * @brief Sets the denoise value.
     * @param[in] denoiseVal Desired denoise level [0-255].
     * @return true on success, false on communication or device error.
     */
    virtual bool setDenoiseValue(uint8_t denoiseVal) = 0;

    // ---- Auto-exposure ROI ------------------------------------------

    /**
     * @brief Retrieves the current auto-exposure ROI configuration.
     * @param[out] outRoi Populated with mode, mapped x/y position, and window size.
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoExpROIMode(ROIAutoExpResult24CUG &outRoi) = 0;

    /**
     * @brief Configures the auto-exposure region of interest.
     * @param[in] roiMode  ROI mode (ROIAutoExpMode24CUG).
     * @param[in] vidW     Video frame width in pixels (for coordinate mapping).
     * @param[in] vidH     Video frame height in pixels (for coordinate mapping).
     * @param[in] xCord    X coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] yCord    Y coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] winSize  Window size index (manual mode only).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set auto exp roimode. */
    virtual bool setAutoExpROIMode(ROIAutoExpMode24CUG roiMode,
                           uint32_t vidW, uint32_t vidH,
                           uint32_t xCord, uint32_t yCord,
                           uint8_t winSize) = 0;

    // ---- Q Factor ---------------------------------------------------

    /**
     * @brief Retrieves the current JPEG Q-factor value.
     * @param[out] outQFactor Current Q-factor [0-255].
     * @return true on success, false on communication or device error.
     */
    virtual bool getQFactor(uint8_t &outQFactor) = 0;

    /**
     * @brief Sets the JPEG Q-factor value.
     * @param[in] qFactor Desired Q-factor [0-255].
     * @return true on success, false on communication or device error.
     */
    virtual bool setQFactor(uint8_t qFactor) = 0;

    // ---- Orientation / flip -----------------------------------------

    /**
     * @brief Retrieves the current image flip / mirror orientation.
     * @param[out] outFlipMode Raw orientation byte (cast to FlipMode24CUG).
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

    // ---- Face detection ---------------------------------------------

    /**
     * @brief Retrieves the current face detection rectangle configuration.
     * @param[out] outFaceDetect Populated with enable state, embed data state, and overlay rect state.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFaceDetectMode(FaceDetectResult24CUG &outFaceDetect) = 0;

    /**
     * @brief Configures the face detection rectangle.
     * @param[in] enable       true to enable face detection rectangle.
     * @param[in] embedData   true to embed face detection data in the frame.
     * @param[in] overlayRect true to display the overlay rectangle.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set face detection rect. */
    virtual bool setFaceDetectionRect(bool enable, bool embedData, bool overlayRect) = 0;

    // ---- Exposure compensation --------------------------------------

    /**
     * @brief Retrieves the current exposure compensation value.
     * @param[out] outExposureComp Exposure compensation value [EXPOSURECOMP_MIN_24CUG - EXPOSURECOMP_MAX_24CUG].
     * @return true on success, false on communication or device error.
     */
    virtual bool getExposureCompensation(uint32_t &outExposureComp) = 0;

    /**
     * @brief Sets the exposure compensation value.
     * @param[in] exposureComp Desired value [EXPOSURECOMP_MIN_24CUG - EXPOSURECOMP_MAX_24CUG].
     * @return true on success, false if value is out of range or on device error.
     */
    virtual bool setExposureCompensation(uint32_t exposureComp) = 0;

    // ---- Frame rate control -----------------------------------------

    /**
     * @brief Retrieves the current frame rate control value.
     * @param[out] outFrameRate Current frame rate value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFrameRateCtrlValue(uint8_t &outFrameRate) = 0;

    /**
     * @brief Sets the frame rate control value.
     * @param[in] frameRate Desired frame rate value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setFrameRateCtrlValue(uint8_t frameRate) = 0;

    // ---- Flash / strobe ---------------------------------------------

    /**
     * @brief Retrieves the current flash / strobe state.
     * @param[out] outFlashMode Raw flash mode byte (cast to FlashMode24CUG).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlashState(uint8_t &outFlashMode) = 0;

    /**
     * @brief Sets the flash / strobe state.
     * @param[in] flashMode Desired mode (FlashMode24CUG enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setFlashState(FlashMode24CUG flashMode) = 0;

    // ---- Flicker detection ------------------------------------------

    /**
     * @brief Retrieves the current anti-flicker detection mode.
     * @param[out] outFlickerMode Raw flicker mode byte (cast to FlickerMode24CUG).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlickerDetection(uint8_t &outFlickerMode) = 0;

    /**
     * @brief Sets the anti-flicker detection mode.
     * @param[in] flickerMode Desired mode (FlickerMode24CUG enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setFlickerDetection(FlickerMode24CUG flickerMode) = 0;

    // ---- Burst length -----------------------------------------------

    /**
     * @brief Retrieves the current burst capture length.
     * @param[out] outBurstLength Current burst length value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getBurstLength(uint8_t &outBurstLength) = 0;

    /**
     * @brief Sets the burst capture length.
     * @param[in] burstLength Desired burst length value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setBurstLength(uint8_t burstLength) = 0;

    // ---- Stream mode ------------------------------------------------

    /**
     * @brief Retrieves the current streaming trigger mode and auto-function lock state.
     * @param[out] outStreamMode Populated with stream mode and autoFunctionLock flag.
     * @return true on success, false on communication or device error.
     */
    virtual bool getStreamMode(StreamModeResult24CUG &outStreamMode) = 0;

    /**
     * @brief Sets the streaming trigger mode and auto-function lock.
     * @param[in] streamMode        Desired mode (StreamMode24CUG enum value).
     * @param[in] autoFunctionLock true to lock auto functions during trigger mode.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set stream mode. */
    virtual bool setStreamMode(StreamMode24CUG streamMode, bool autoFunctionLock) = 0;

    // ---- Restore default --------------------------------------------

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
