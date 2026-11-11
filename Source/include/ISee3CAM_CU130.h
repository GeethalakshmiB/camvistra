///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU130.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU130 extension-unit (HID) controls:
//      scene mode, special effects, AE ROI, exposure compensation, face
//      and smile detection, anti-flicker, orientation, denoise, burst
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU130::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU130.h @brief Declares the ISee3CAM_CU130 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------
enum class SceneModeCU130 : uint8_t {
    SCENE_NORMAL         = 0x01,
    SCENE_PORTRAIT       = 0x02,
    SCENE_LANDSCAPE      = 0x03,
    SCENE_SPORT          = 0x04,
    SCENE_CLOSE_UP       = 0x05,
    SCENE_NIGHT          = 0x06,
    SCENE_TWILIGHT       = 0x07,
    SCENE_BACKLIGHT      = 0x08,
    SCENE_HIGH_SENSITIVE = 0x09,
    SCENE_NIGHT_PORTRAIT = 0x0A,
    SCENE_BEACH          = 0x0B,
    SCENE_DOCUMENT       = 0x0C,
    SCENE_PARTY          = 0x0D,
    SCENE_FIREWORKS      = 0x0E,
    SCENE_SUNSET         = 0x0F,
    SCENE_AUTO_DETECT    = 0x10
};

enum class SpecialEffectCU130 : uint8_t {
    EFFECT_NORMAL         = 0x01,
    EFFECT_ALIEN          = 0x02,
    EFFECT_ANTIQUE        = 0x03,
    EFFECT_BLACK_WHITE    = 0x04,
    EFFECT_EMBOSS         = 0x05,
    EFFECT_EMBOSS_COLORED = 0x06,
    EFFECT_GRAY           = 0x07,
    EFFECT_NEGATIVE       = 0x08,
    EFFECT_BLUE           = 0x09,
    EFFECT_GREEN          = 0x0A,
    EFFECT_RED            = 0x0B,
    EFFECT_POSTERIZE_1    = 0x0C,
    EFFECT_POSTERIZE_2    = 0x0D,
    EFFECT_SEPIA_1        = 0x0E,
    EFFECT_SEPIA_2        = 0x0F,
    EFFECT_SKETCH         = 0x10,
    EFFECT_SOLARIZE       = 0x11,
    EFFECT_FOGGY          = 0x12
};

enum class FlipModeCU130 : uint8_t {
    FLIP_OFF_MIRROR_OFF = 0x00,
    FLIP_ON_MIRROR_OFF  = 0x01,
    FLIP_OFF_MIRROR_ON  = 0x02,
    FLIP_ON_MIRROR_ON   = 0x03
};

enum class ROIAutoExpModeCU130 : uint8_t {
    AE_Face     = 0x00,
    AE_Full     = 0x01,
    AE_Manual   = 0x02,
    AE_Disabled = 0x03
};

enum class FlickerModeCU130 : uint8_t {
    MODE_AUTO    = 0x00,
    MODE_50Hz    = 0x01,
    MODE_60Hz    = 0x02,
    MODE_DISABLE = 0x03
};

// ----------------------------------------------------------------
// Output structs (replaces Qt signals)
// ----------------------------------------------------------------
struct FaceDetectResultCU130 {
    uint8_t mode; // Stores mode.
    uint8_t embedData; // Stores embed data.
    uint8_t overlayrect; // Stores overlayrect.
};

struct SmileDetectResultCU130 {
    uint8_t mode; // Stores mode.
    uint8_t embedData; // Stores embed data.
};

struct ROIAutoExpResultCU130 {
    uint8_t mode; // Stores mode.
    uint8_t xPos; // Stores x pos.
    uint8_t yPos; // Stores y pos.
    uint8_t wnsize; // Stores wnsize.
};

namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU130 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU130::create(), instead of using See3CAM_CU130 directly.
 */
class CAMSDK ISee3CAM_CU130 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU130() = default;

    /**
     * @brief Creates the See3CAM_CU130 implementation.
     * @return Owning pointer to a newly created See3CAM_CU130 instance.
     */
    static std::unique_ptr<ISee3CAM_CU130> create();

    /**
     * @brief Retrieves the current scene mode from the camera.
     * @param[out] outSceneMode Raw scene mode byte (cast to SceneModeCU130).
     * @return true on success, false on communication or device error.
     */
    virtual bool getSceneMode(uint8_t &outSceneMode) = 0;

    /**
     * @brief Sets the scene mode on the camera.
     * @param[in] sceneMode Desired scene mode (SceneModeCU130 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setSceneMode(SceneModeCU130 sceneMode) = 0;

    /**
     * @brief Retrieves the currently applied special effect.
     * @param[out] outEffects Raw effect byte (cast to SpecialEffectCU130).
     * @return true on success, false on communication or device error.
     */
    virtual bool getSpecialEffects(uint8_t &outEffects) = 0;

    /**
     * @brief Applies a special visual effect to the camera output.
     * @param[in] effects Desired effect (SpecialEffectCU130 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setSpecialEffects(SpecialEffectCU130 effects) = 0;

    /**
     * @brief Retrieves the current denoise strength value.
     * @param[out] outDenoise Denoise level (0Ã¢â‚¬â€œ255).
     * @return true on success, false on communication or device error.
     */
    virtual bool getDenoiseValue(uint8_t &outDenoise) = 0;

    /**
     * @brief Sets the denoise strength on the camera.
     * @param[in] denoiseVal Denoise level (0Ã¢â‚¬â€œ255).
     * @return true on success, false on communication or device error.
     */
    virtual bool setDenoiseValue(uint8_t denoiseVal) = 0;

    /**
     * @brief Retrieves the current auto-exposure ROI configuration.
     * @param[out] outRoi Populated with mode, x/y position, and window size.
     * @return true on success, false on communication or device error.
     */
    virtual bool getAutoExpROIMode(ROIAutoExpResultCU130 &outRoi) = 0;

    /**
     * @brief Configures the auto-exposure region of interest.
     * @param[in] roiMode   ROI mode (face / full / manual / disabled).
     * @param[in] vidW      Video frame width in pixels (used for coordinate mapping).
     * @param[in] vidH      Video frame height in pixels (used for coordinate mapping).
     * @param[in] xCord     X coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] yCord     Y coordinate of the ROI centre (pixel units, manual mode only).
     * @param[in] winSize   Window size index for the ROI (manual mode only).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set auto exp roimode. */
    virtual bool setAutoExpROIMode(ROIAutoExpModeCU130 roiMode,
                           uint32_t vidW, uint32_t vidH,
                           uint32_t xCord, uint32_t yCord,
                           uint8_t winSize) = 0;

    /**
     * @brief Retrieves the current burst capture length.
     * @param[out] outBurst Number of frames captured per burst trigger.
     * @return true on success, false on communication or device error.
     */
    virtual bool getBurstLength(uint8_t &outBurst) = 0;

    /**
     * @brief Sets the burst capture length.
     * @param[in] burstLength Number of frames to capture per burst trigger.
     * @return true on success, false on communication or device error.
     */
    virtual bool setBurstLength(uint8_t burstLength) = 0;

    /**
     * @brief Retrieves the current JPEG quality (Q) factor.
     * @param[out] outQFactor Q factor value (higher = better quality).
     * @return true on success, false on communication or device error.
     */
    virtual bool getQFactor(uint8_t &outQFactor) = 0;

    /**
     * @brief Sets the JPEG quality (Q) factor.
     * @param[in] qFactor Desired Q factor value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setQFactor(uint8_t qFactor) = 0;

    /**
     * @brief Restores all camera settings to their factory defaults.
     * @return true on success, false on communication or device error.
     */
    virtual bool restoreDefault() = 0;

    /**
     * @brief Retrieves the current image flip/mirror orientation.
     * @param[out] outFlipMode Raw orientation byte (cast to FlipModeCU130).
     * @return true on success, false on communication or device error.
     */
    virtual bool getOrientation(uint8_t &outFlipMode) = 0;

    /**
     * @brief Sets the image flip and mirror orientation.
     * @param[in] horzFlip true to flip the image horizontally (mirror).
     * @param[in] vertFlip true to flip the image vertically.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set orientation. */
    virtual bool setOrientation(bool horzFlip, bool vertFlip) = 0;

    /**
     * @brief Retrieves the current face detection rectangle configuration.
     * @param[out] outFaceDetect Populated with enable state, embed-data flag, and overlay-rect flag.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFaceDetectionRect(FaceDetectResultCU130 &outFaceDetect) = 0;

    /**
     * @brief Configures face detection rectangle drawing on the camera.
     * @param[in] enable       true to enable face detection.
     * @param[in] embedData   true to embed face metadata in the stream.
     * @param[in] overlayRect true to overlay the detection rectangle on the frame.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set face detection rect. */
    virtual bool setFaceDetectionRect(bool enable, bool embedData, bool overlayRect) = 0;

    /**
     * @brief Retrieves the current smile detection state.
     * @param[out] outSmile Populated with enable state and embed-data flag.
     * @return true on success, false on communication or device error.
     */
    virtual bool getSmileDetectionState(SmileDetectResultCU130 &outSmile) = 0;

    /**
     * @brief Configures smile detection on the camera.
     * @param[in] enable     true to enable smile detection.
     * @param[in] embedData true to embed smile detection metadata in the stream.
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs set smile detection state. */
    virtual bool setSmileDetectionState(bool enable, bool embedData) = 0;

    /**
     * @brief Retrieves the current exposure compensation value.
     * @param[out] outExpComp Exposure compensation value in microseconds
     *             (range: EXPOSURECOMP_MIN_CU130 Ã¢â‚¬â€œ EXPOSURECOMP_MAX_CU130).
     * @return true on success, false on communication or device error.
     */
    /** @brief Performs get exposure compensation. */
    virtual bool getExposureCompensation(uint32_t &outExpComp) = 0;

    /**
     * @brief Sets the exposure compensation value.
     * @param[in] expCompValue Exposure compensation in microseconds
     *            (must be within EXPOSURECOMP_MIN_CU130 Ã¢â‚¬â€œ EXPOSURECOMP_MAX_CU130).
     * @return true on success, false if value is out of range or on device error.
     */
    /** @brief Performs set exposure compensation. */
    virtual bool setExposureCompensation(uint32_t expCompValue) = 0;

    /**
     * @brief Retrieves the current frame rate setting.
     * @param[out] outFrameRate Frame rate value reported by the camera.
     * @return true on success, false on communication or device error.
     */
    virtual bool getFrameRateValue(uint8_t &outFrameRate) = 0;

    /**
     * @brief Sets the camera frame rate.
     * @param[in] frameRate Desired frame rate value.
     * @return true on success, false on communication or device error.
     */
    virtual bool setFrameRateValue(uint8_t frameRate) = 0;

    /**
     * @brief Retrieves the current anti-flicker mode.
     * @param[out] outFlicker Raw flicker mode byte (cast to FlickerModeCU130).
     * @return true on success, false on communication or device error.
     */
    virtual bool getAntiFlickerMode(uint8_t &outFlicker) = 0;

    /**
     * @brief Sets the anti-flicker mode to suppress 50 Hz / 60 Hz banding.
     * @param[in] flickerMode Desired flicker suppression mode (FlickerModeCU130 enum value).
     * @return true on success, false on communication or device error.
     */
    virtual bool setAntiFlickerMode(FlickerModeCU130 flickerMode) = 0;

	/**
	 * @brief Reads the firmware version from the device.
	 * @param[out] version Reference to a string that will contain the firmware version (e.g., "v1.0.3").
	 * @return true on successful retrieval, false on communication or device error.
	 */
	virtual bool readFirmwareVersion(std::string &version) = 0;

	/** @brief Performs get camera unique id64. */
	virtual bool getCameraUniqueID64(std::string &uniqueID) = 0;

    /**
     * @brief (Linux only) Initialises the HID channel using an open file descriptor.
     * @param[in] fd Open file descriptor for the camera HID device node.
     * @return true on success, false on Windows (not applicable) or initialisation error.
     */
    virtual bool setHidFd(int fd) = 0;

    /** @name Windows-only initialisation */
    ///@{
#ifdef _WIN32
    /**
     * @brief (Windows only) Opens and initialises the HID extension unit for the camera.
     * @param[in] devicePath Wide-character device path obtained from the HID enumeration.
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
