///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_130E.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_130E extension-unit (HID) controls:
//      AE/AF/AWB, ROI, scene/effect, face detect, HDR, flash, flip,
//      stream mode, burst, denoise, Q-factor, frame rate
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_130E::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_130E.h @brief Declares the ISee3CAM_130E interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <functional>
#include <string>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------
enum class SceneMode130E : uint8_t {
    SCENE_NORMAL   = 0x01,
    SCENE_DOCUMENT = 0x0C
};

enum class SpecialEffect130E : uint8_t {
    EFFECT_NORMAL      = 0x01,
    EFFECT_BLACK_WHITE = 0x04,
    EFFECT_GREYSCALE   = 0x07,
    EFFECT_NEGATIVE    = 0x08,
    EFFECT_SKETCH      = 0x10
};

enum class AfMode130E : uint8_t {
    Continuous     = 0x01,
    OneShot        = 0x02,
    AfDisabled     = 0x03
};

enum class FlashMode130E : uint8_t {
    DISABLE = 0x00,
    STROBE  = 0x01,
    TORCH   = 0x02
};

enum class ROIAfMode130E : uint8_t {
    AF_Centered = 0x01,
    AF_Manual   = 0x02,
    AF_Disabled = 0x03
};

enum class ROIAutoExpMode130E : uint8_t {
    AE_Face     = 0x00,
    AE_Full     = 0x01,
    AE_Manual   = 0x02,
    AE_Disabled = 0x03
};

enum class HDRMode130E : uint8_t {
    HdrOff    = 0x01,
    HdrAuto   = 0x02,
    HdrManual = 0x03
};

enum class FlickerMode130E : uint8_t {
    MODE_AUTO    = 0x03,
    MODE_50Hz    = 0x01,
    MODE_60Hz    = 0x02,
    MODE_DISABLE = 0x00
};

enum class StreamMode130E : uint8_t {
    STREAM_MASTER  = 0x00,
    STREAM_TRIGGER = 0x01
};

enum class FlipMode130E : uint8_t {
    BOTH_DISABLE = 0x00,
    HORZ_ONLY    = 0x01,
    VERT_ONLY    = 0x02,
    BOTH_ENABLE  = 0x03
};

enum class AFRectMode130E : uint8_t {
    Disable = 0x00,
    Enable  = 0x01
};

enum class FaceDetectMode130E : uint8_t {
    Face_Detect_Disable = 0x00,
    Face_Detect_Enable  = 0x01
};

enum class EmbedDataMode130E : uint8_t {
    Disable = 0x00,
    Enable  = 0x01
};

enum class OverlayRectMode130E : uint8_t {
    Disable = 0x00,
    Enable  = 0x01
};

enum class AutoSaveConfig130E : uint8_t {
	DISABLE = 0x00,
	ENABLE = 0x01
};

// ----------------------------------------------------------------
// Output structs (replaces Qt signals)
// ----------------------------------------------------------------
struct GainValues {
    uint8_t min;      // Minimum gain value supported by the camera for this color channel
    uint8_t max;      // Maximum gain value supported by the camera for this color channel
    uint8_t current;  // Gain value currently applied to this color channel
};

struct FaceDetectResult {
    FaceDetectMode130E mode; // Stores mode.
    EmbedDataMode130E embedData; // Stores embed data.
    OverlayRectMode130E overlayRect; // Stores overlay rect.
};

struct HDRResult {
    HDRMode130E mode; // Stores mode.
    uint8_t value;  // HDR strength value reported by the camera (meaningful in manual mode)
};

struct AutoFocusROIResult {
    ROIAfMode130E mode; // Stores mode.
    uint8_t winSize; // Stores win size.
};

struct AutoExpROIResult {
    ROIAutoExpMode130E mode; // Stores mode.
    uint8_t winSize;  // Current ROI window size reported by the camera
};

namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_130E camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_130E::create(), instead of using See3CAM_130E directly.
 */
class CAMSDK ISee3CAM_130E {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_130E() = default;

    /**
     * @brief Creates the See3CAM_130E implementation.
     * @return Owning pointer to a newly created See3CAM_130E instance.
     */
    static std::unique_ptr<ISee3CAM_130E> create();

    // Scene mode
    /** @brief Retrieves get scene mode. */
    virtual bool getSceneMode(uint8_t &outSceneMode) = 0;
    /** @brief Performs set scene mode. */
    virtual bool setSceneMode(SceneMode130E sceneMode) = 0;

    // Effect mode
    /** @brief Retrieves get effect mode. */
    virtual bool getEffectMode(uint8_t &outEffectMode) = 0;
    /** @brief Sets set effect mode. */
    virtual bool setEffectMode(SpecialEffect130E effect) = 0;

    // Denoise
    /** @brief Performs get denoise value. */
    virtual bool getDenoiseValue(uint8_t &outDenoise) = 0;
    /** @brief Sets set denoise value. */
    virtual bool setDenoiseValue(uint8_t denoiseVal) = 0;

    // Auto focus mode
    /** @brief Retrieves get auto focus mode. */
    virtual bool getAutoFocusMode(uint8_t &outAfMode) = 0;
    /** @brief Performs set auto focus mode. */
    virtual bool setAutoFocusMode(AfMode130E afMode) = 0;

    // AF ROI
    /** @brief Retrieves get auto focus roi. */
    virtual bool getAutoFocusROI(AutoFocusROIResult &outRoi) = 0;
    /** @brief Sets set auto focus roi. */
    virtual bool setAutoFocusROI(ROIAfMode130E roiMode,
                         uint32_t vidW, uint32_t vidH,
                         uint32_t xCord, uint32_t yCord,
                         uint8_t winSize) = 0;

    // Auto exposure ROI
    /** @brief Performs get auto exp roi. */
    virtual bool getAutoExpROI(AutoExpROIResult &outRoi) = 0;
    /** @brief Sets set auto exp roi. */
    virtual bool setAutoExpROI(ROIAutoExpMode130E roiMode,
                       uint32_t vidW, uint32_t vidH,
                       uint32_t xCord, uint32_t yCord,
                       uint8_t winSize) = 0;

    // Burst length
    /** @brief Performs get burst length. */
    virtual bool getBurstLength(uint8_t &outBurst) = 0;
    /** @brief Sets set burst length. */
    virtual bool setBurstLength(uint8_t burstLength) = 0;

    // HDR
    /** @brief Retrieves get hdrmode. */
    virtual bool getHDRMode(HDRResult &outHdr) = 0;
    /** @brief Performs set hdrmode. */
    virtual bool setHDRMode(HDRMode130E hdrMode, uint8_t hdrValue) = 0;

    // Q Factor
    /** @brief Retrieves get qfactor. */
    virtual bool getQFactor(uint8_t &outQFactor) = 0;
    /** @brief Sets set qfactor. */
    virtual bool setQFactor(uint8_t qFactor) = 0;

    // AF rectangle
    /** @brief Performs get afrect mode. */
    virtual bool getAFRectMode(AFRectMode130E &outMode) = 0;
    /** @brief Performs enable disable afrect. */
    virtual bool enableDisableAFRect(bool enable) = 0;
    /** @brief Performs enable disable afrect2. */
    virtual bool enableDisableAFRect2(bool enable) = 0;

    // Stream mode
    /** @brief Performs get stream mode. */
    virtual bool getStreamMode(uint8_t &outStreamMode) = 0;
    /** @brief Sets set stream mode. */
    virtual bool setStreamMode(StreamMode130E streamMode) = 0;

    // Flip
    /** @brief Retrieves get flip mode. */
    virtual bool getFlipMode(FlipMode130E &outFlipMode) = 0;
    /** @brief Performs set flip mode. */
    virtual bool setFlipMode(bool horzFlip, bool vertFlip) = 0;

    // Face detection
    /** @brief Retrieves get face detect mode. */
    virtual bool getFaceDetectMode(FaceDetectResult &outFaceDetect) = 0;
    /** @brief Sets set face detect rect. */
    virtual bool setFaceDetectRect(bool enable, bool embedData, bool overlayRect) = 0;

    // Exposure compensation
    /** @brief Performs get exposure compensation. */
    virtual bool getExposureCompensation(uint32_t &outExpComp) = 0;
    /** @brief Sets set exposure compensation. */
    virtual bool setExposureCompensation(uint32_t expCompValue) = 0;

    // Frame rate
    /** @brief Retrieves get frame rate ctrl value. */
    virtual bool getFrameRateCtrlValue(uint8_t &outFrameRate) = 0;
    /** @brief Performs set frame rate ctrl value. */
    virtual bool setFrameRateCtrlValue(uint8_t frameRate) = 0;

    // Anti-flicker
    /** @brief Retrieves get anti flicker mode. */
    virtual bool getAntiFlickerMode(uint8_t &outFlicker) = 0;
    /** @brief Sets set anti flicker mode. */
    virtual bool setAntiFlickerMode(FlickerMode130E flickerMode) = 0;

    // White balance / exposure (read-only)
    /** @brief Performs get auto white balance. */
    virtual bool getAutoWhiteBalance(uint16_t &outAWB) = 0;
    /** @brief Retrieves get auto exposure. */
    virtual bool getAutoExposure(uint32_t &outExposure) = 0;

    // Flash
    /** @brief Retrieves get flash mode. */
    virtual bool getFlashMode(uint8_t &outFlash) = 0;
    /** @brief Performs set flash mode. */
    virtual bool setFlashMode(FlashMode130E flashMode) = 0;

    // AF position
    /** @brief Retrieves get auto focus position. */
    virtual bool getAutoFocusPosition(uint8_t &outPosition) = 0;

    // RGB gains
    /** @brief Performs get red gain. */
    virtual bool getRedGain(GainValues &outGain) = 0;
    /** @brief Sets set red gain. */
    virtual bool setRedGain(uint8_t redGain) = 0;
    /** @brief Retrieves get blue gain. */
    virtual bool getBlueGain(GainValues &outGain) = 0;
    /** @brief Sets set blue gain. */
    virtual bool setBlueGain(uint8_t blueGain) = 0;
    /** @brief Retrieves get green gain. */
    virtual bool getGreenGain(GainValues &outGain) = 0;
    /** @brief Performs set green gain. */
    virtual bool setGreenGain(uint8_t greenGain) = 0;

    // Save / serial
    /** @brief Performs save configuration. */
    virtual bool saveConfiguration() = 0;
    /** @brief Performs get64 bit serial number. */
    virtual bool get64BitSerialNumber(uint64_t &outSerial) = 0;

	//Auto Save Configuration
	/** @brief Performs get auto save configuration. */
	virtual bool getAutoSaveConfiguration(AutoSaveConfig130E& autoSaveMode) = 0;
	/** @brief Sets set auto save configuration. */
	virtual bool setAutoSaveConfiguration(AutoSaveConfig130E autoSaveMode) = 0;

    // Set to default
    /** @brief Sets set to default. */
    virtual bool setToDefault() = 0;

    //Read firmware version
    /** @brief Performs read firmware version. */
    virtual bool readFirmwareVersion(std::string &version) = 0;

    // Linux: Initialize with file descriptor
    /** @brief Sets set hid fd. */
    virtual bool setHidFd(int fd) = 0;

    // Windows: Initialize with device path
#ifdef _WIN32
    /** @brief Performs init from device path. */
    virtual bool initFromDevicePath(TCHAR *devicePath) = 0;
	/** @brief Performs deinit extension unit. */
	virtual void deinitExtensionUnit() = 0;
#endif
};

} // namespace eCamSDK
