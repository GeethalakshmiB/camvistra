///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU81.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU81 extension-unit (HID) controls:
//      camera mode, auto exposure/WB, AE ROI, face detection, effects,
//      flip, anti-flicker, denoise, burst, frame rate, config save
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU81::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU81.h @brief Declares the ISee3CAM_CU81 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>


// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------

/** @brief Camera operating mode. */
enum class CameraModeCU81 : uint8_t {
    HDR_MODE    = 0x01, ///< HDR mode
    LINEAR_MODE = 0x02  ///< Linear mode
};

/** @brief Special image effects mode. */
enum class SpecialEffectsCU81 : uint8_t {
    EFFECT_NORMAL      = 0x01, ///< Normal (no effect)
    EFFECT_BLACK_WHITE = 0x04, ///< Black and White
    EFFECT_GREYSCALE   = 0x07, ///< Greyscale
    EFFECT_NEGATIVE    = 0x08, ///< Negative
    EFFECT_SKETCH      = 0x10  ///< Sketch
};

/** @brief Auto-exposure ROI mode. */
enum class ROIAutoExpModeCU81 : uint8_t {
    AE_Full     = 0x01, ///< Full-frame AE
    AE_Manual   = 0x02, ///< Manual ROI window
    AE_Disabled = 0x03  ///< AE ROI disabled
};

/** @brief Image flip / mirror orientation. */
enum class FlipModeCU81 : uint8_t {
    FLIP_NORMAL     = 0x00, ///< No flip
    FLIP_HORIZONTAL = 0x01, ///< Horizontal flip (mirror)
    FLIP_VERTICAL   = 0x02, ///< Vertical flip
    FLIP_BOTH       = 0x03  ///< Both horizontal and vertical flip
};

/** @brief Anti-flicker suppression mode. */
enum class AntiFlickerModeCU81 : uint8_t {
    MODE_AUTO    = 0x00, ///< Auto detect
    MODE_50Hz    = 0x01, ///< 50 Hz suppression
    MODE_60Hz    = 0x02, ///< 60 Hz suppression
    MODE_DISABLE = 0x03  ///< Anti-flicker disabled
};

/** @brief Configuration save mode. */
enum class SaveConfigCU81 : uint8_t {
    DEFAULT      = 0x00, ///< Save to default slot
    USER_DEFINED = 0x01  ///< Save to user-defined slot
};

// ----------------------------------------------------------------
// Output structs (replace Qt signals)
// ----------------------------------------------------------------

/** @brief Result of getAutoExpROIMode(). */
struct ROIAutoExpResultCU81 {
    uint8_t mode;     ///< ROI mode (ROIAutoExpModeCU81)
    uint8_t xpos;    ///< Mapped X coordinate [0-255]
    uint8_t ypos;    ///< Mapped Y coordinate [0-255]
    uint8_t wnsize; ///< Window size index
};

/** @brief Result of getFaceDetectMode(). */
struct FaceDetectResultCU81 {
    uint8_t state;        ///< Face detect enable state
    uint8_t embedData;   ///< Embed data state
    uint8_t overlayrect; ///< Overlay rectangle state
};

// ----------------------------------------------------------------
// Namespace & class
// ----------------------------------------------------------------
namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU81 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU81::create(), instead of using See3CAM_CU81 directly.
 */
class CAMSDK ISee3CAM_CU81 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU81() = default;

    /**
     * @brief Creates the See3CAM_CU81 implementation.
     * @return Owning pointer to a newly created See3CAM_CU81 instance.
     */
    static std::unique_ptr<ISee3CAM_CU81> create();

    // ---- Camera mode ------------------------------------------------

    /**
     * @brief Retrieves the current camera operating mode (HDR or Linear).
     * @param[out] outMode Raw mode byte (cast to CameraModeCU81).
     * @return true on success, false on communication or device error.
     */
    virtual bool getCameraMode(uint8_t &outMode) = 0;

    /**
     * @brief Sets the camera operating mode.
     * @param[in] mode Desired mode (CameraModeCU81 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setCameraMode(CameraModeCU81 mode) = 0;

    // ---- Special effects --------------------------------------------

    /**
     * @brief Retrieves the current special effects mode.
     * @param[out] outEffect Raw effect mode byte (cast to SpecialEffectsCU81).
     * @return true on success, false on communication or device error.
     */
    virtual bool getEffectMode(uint8_t &outEffect) = 0;

    /**
     * @brief Sets the special effects mode.
     * @param[in] effect Desired effect (SpecialEffectsCU81 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setEffectMode(SpecialEffectsCU81 effect) = 0;

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
    virtual bool getAutoExpROIMode(ROIAutoExpResultCU81 &outRoi) = 0;

    /**
     * @brief Configures the auto-exposure region of interest.
     * @param[in] roiMode ROI mode (ROIAutoExpModeCU81).
     * @param[in] vidW    Video frame width in pixels (for coordinate mapping).
     * @param[in] vidH    Video frame height in pixels (for coordinate mapping).
     * @param[in] xCord   X coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] yCord   Y coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] winSize Window size index (manual mode only).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set roiauto exposure. */
    virtual bool setROIAutoExposure(ROIAutoExpModeCU81 roiMode,
                            uint32_t vidW, uint32_t vidH,
                            uint32_t xCord, uint32_t yCord,
                            uint8_t winSize) = 0;

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

    // ---- Q Factor ---------------------------------------------------

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

    // ---- Orientation / flip -----------------------------------------

    /**
     * @brief Retrieves the current image flip / mirror orientation.
     * @param[out] outFlip Raw orientation byte (cast to FlipModeCU81).
     * @return true on success, false on communication or device error.
     */
    virtual bool getFlipMode(uint8_t &outFlip) = 0;

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
     * @param[out] outExp Exposure compensation value [EXPOSURECOMP_MIN_CU81 - EXPOSURECOMP_MAX_CU81].
     * @return true on success, false on communication or device error.
     */
    virtual bool getExposureCompensation(uint32_t &outExp) = 0;

    /**
     * @brief Sets the exposure compensation value.
     * @param[in] expComp Desired value [EXPOSURECOMP_MIN_CU81 - EXPOSURECOMP_MAX_CU81].
     * @return true on success, false if the value is out of range or on device error.
     */
    virtual bool setExposureCompensation(uint32_t expComp) = 0;

    // ---- Frame rate control -----------------------------------------

    /**
     * @brief Retrieves the current frame rate control value.
     * @param[out] outRate Current frame rate value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFrameRateCtrlValue(uint8_t &outRate) = 0;

    /**
     * @brief Sets the frame rate control value.
     * @param[in] rate Desired frame rate value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setFrameRateCtrlValue(uint8_t rate) = 0;

    // ---- Anti-flicker -----------------------------------------------

    /**
     * @brief Retrieves the current anti-flicker detection mode.
     * @param[out] outMode Raw flicker mode byte (cast to AntiFlickerModeCU81).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAntiFlickerMode(uint8_t &outMode) = 0;

    /**
     * @brief Sets the anti-flicker detection mode.
     * @param[in] mode Desired mode (AntiFlickerModeCU81 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAntiFlickerMode(AntiFlickerModeCU81 mode) = 0;

    // ---- Face detection ---------------------------------------------

    /**
     * @brief Retrieves the current face detection rectangle configuration.
     * @param[out] outFace Populated with enable state, embed data state, and overlay rect state.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFaceDetectMode(FaceDetectResultCU81 &outFace) = 0;

    /**
     * @brief Configures the face detection rectangle.
     * @param[in] enable       true to enable face detection rectangle.
     * @param[in] embedData   true to embed face detection data in the frame.
     * @param[in] overlayRect true to display the overlay rectangle.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set face detection rect. */
    virtual bool setFaceDetectionRect(bool enable, bool embedData, bool overlayRect) = 0;

    // ---- Auto exposure (read-only) ----------------------------------

    /**
     * @brief Retrieves the current auto exposure value from the camera.
     * @param[out] outExposure 4-byte auto exposure value (MSB first).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoExposure(uint32_t &outExposure) = 0;

    // ---- Auto white balance (read-only) -----------------------------

    /**
     * @brief Retrieves the current auto white balance value from the camera.
     * @param[out] outWb 2-byte white balance value.
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoWhiteBalance(uint32_t &outWb) = 0;

    // ---- Save configuration -----------------------------------------

    /**
     * @brief Saves the current camera configuration.
     * @param[in] configMode Save slot (SaveConfigCU81 enum value).
     * @return true on success, false on communication or device error.
     *
     * @note This command uses SAVE_CONFIGURATION_CU81 (0x42) in the camID
     *       position of the packet rather than CAMERA_CONTROL_CU81 (0xAC),
     *       matching the original firmware protocol.
     */
    /** @brief Performs save configuration. */
    virtual bool saveConfiguration(SaveConfigCU81 configMode) = 0;

    // ---- Restore default --------------------------------------------

    /**
     * @brief Restores all camera settings to their factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool setToDefault() = 0;

    // ---- Firmware version / unique ID -------------------------------

    /**
     * @brief Reads the firmware version from the device.
     * @param[out] version Formatted firmware version string (e.g., "1.0.3.0").
     * @return true on successful retrieval, false on communication or device error.
     */
    virtual bool readFirmwareVersion(std::string &version) = 0;

    /**
     * @brief Reads the 64-bit unique ID of the camera.
     * @param[out] uniqueID String containing the unique camera identifier.
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
