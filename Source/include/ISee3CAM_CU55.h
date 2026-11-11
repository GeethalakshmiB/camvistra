///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU55.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU55 extension-unit (HID) controls:
//      AE ROI, exposure compensation, face and smile detection, flash,
//      flip, effects, anti-flicker, denoise, burst, frame rate
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU55::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU55.h @brief Declares the ISee3CAM_CU55 interface and the public types used by it. */
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
enum class SceneModeCU55 : uint8_t {
    SCENE_NORMAL   = 0x01,
    SCENE_DOCUMENT = 0x0C
};

enum class SpecialEffectCU55 : uint8_t {
    EFFECT_NORMAL      = 0x01,
    EFFECT_BLACK_WHITE = 0x04,
    EFFECT_GREYSCALE   = 0x07,
    EFFECT_NEGATIVE    = 0x08,
    EFFECT_SKETCH      = 0x10
};

enum class FlashModeCU55 : uint8_t {
    DISABLE = 0x00,
    STROBE  = 0x01,
    TORCH   = 0x02
};

enum class ROIAutoExpModeCU55 : uint8_t {
    AE_Face     = 0x00,
    AE_Full     = 0x01,
    AE_Manual   = 0x02,
    AE_Disabled = 0x03
};

enum class FlickerModeCU55 : uint8_t {
    MODE_AUTO    = 0x03,
    MODE_50Hz    = 0x01,
    MODE_60Hz    = 0x02,
    MODE_DISABLE = 0x00
};

enum class FlipModeCU55 : uint8_t {
    BOTH_DISABLE = 0x00,
    HORZ_ONLY    = 0x01,
    VERT_ONLY    = 0x02,
    BOTH_ENABLE  = 0x03
};

// ----------------------------------------------------------------
// Output structs (replaces Qt signals)
// ----------------------------------------------------------------
struct FaceDetectResultCU55 {
    uint8_t mode; // Stores mode.
    uint8_t embedData; // Stores embed data.
    uint8_t overlayRect; // Stores overlay rect.
};

struct SmileDetectResultCU55 {
    uint8_t mode; // Stores mode.
    uint8_t embedData; // Stores embed data.
};

struct ROIModeResultCU55 {
    uint8_t mode; // Stores mode.
    uint8_t winSize; // Stores win size.
};

namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU55 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU55::create(), instead of using See3CAM_CU55 directly.
 */
class CAMSDK ISee3CAM_CU55 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU55() = default;

    /**
     * @brief Creates the See3CAM_CU55 implementation.
     * @return Owning pointer to a newly created See3CAM_CU55 instance.
     */
    static std::unique_ptr<ISee3CAM_CU55> create();

    // Effect mode
    /** @brief Retrieves get effect mode. */
    virtual bool getEffectMode(uint8_t &outEffectMode) = 0;
    /** @brief Performs set effect mode. */
    virtual bool setEffectMode(SpecialEffectCU55 effect) = 0;

    // Denoise
    /** @brief Retrieves get denoise value. */
    virtual bool getDenoiseValue(uint8_t &outDenoise) = 0;
    /** @brief Sets set denoise value. */
    virtual bool setDenoiseValue(uint8_t denoiseVal) = 0;

    // Auto exposure ROI
    /** @brief Performs get auto exp roi. */
    virtual bool getAutoExpROI(ROIModeResultCU55 &outRoi) = 0;
    /** @brief Sets set auto exp roi. */
    virtual bool setAutoExpROI(ROIAutoExpModeCU55 roiMode,
                       uint32_t vidW, uint32_t vidH,
                       uint32_t xCord, uint32_t yCord,
                       uint8_t winSize) = 0;

    // Burst length
    /** @brief Performs get burst length. */
    virtual bool getBurstLength(uint8_t &outBurst) = 0;
    /** @brief Sets set burst length. */
    virtual bool setBurstLength(uint8_t burstLength) = 0;

    // Q Factor
    /** @brief Retrieves get qfactor. */
    virtual bool getQFactor(uint8_t &outQFactor) = 0;
    /** @brief Performs set qfactor. */
    virtual bool setQFactor(uint8_t qFactor) = 0;

    // Flip
    /** @brief Retrieves get flip mode. */
    virtual bool getFlipMode(uint8_t &outFlipMode) = 0;
    /** @brief Sets set flip mode. */
    virtual bool setFlipMode(bool horzFlip, bool vertFlip) = 0;

    // Face detection
    /** @brief Performs get face detect mode. */
    virtual bool getFaceDetectMode(FaceDetectResultCU55 &outFaceDetect) = 0;
    /** @brief Sets set face detect rect. */
    virtual bool setFaceDetectRect(bool enable, bool embedData, bool overlayRect) = 0;

    // Smile detection
    /** @brief Retrieves get smile detect mode. */
    virtual bool getSmileDetectMode(SmileDetectResultCU55 &outSmileDetect) = 0;
    /** @brief Performs set smile detect rect. */
    virtual bool setSmileDetectRect(bool enable, bool embedData) = 0;

    // Exposure compensation
    /** @brief Retrieves get exposure compensation. */
    virtual bool getExposureCompensation(uint32_t &outExpComp) = 0;
    /** @brief Sets set exposure compensation. */
    virtual bool setExposureCompensation(uint32_t expCompValue) = 0;

    // Frame rate
    /** @brief Performs get frame rate ctrl value. */
    virtual bool getFrameRateCtrlValue(uint8_t &outFrameRate) = 0;
    /** @brief Sets set frame rate ctrl value. */
    virtual bool setFrameRateCtrlValue(uint8_t frameRate) = 0;

    // Anti-flicker
    /** @brief Retrieves get anti flicker mode. */
    virtual bool getAntiFlickerMode(uint8_t &outFlicker) = 0;
    /** @brief Performs set anti flicker mode. */
    virtual bool setAntiFlickerMode(FlickerModeCU55 flickerMode) = 0;

    // Flash
    /** @brief Retrieves get flash mode. */
    virtual bool getFlashMode(uint8_t &outFlash) = 0;
    /** @brief Sets set flash mode. */
    virtual bool setFlashMode(FlashModeCU55 flashMode) = 0;

    // Save / serial
    /** @brief Performs get64 bit serial number. */
    virtual bool get64BitSerialNumber(uint64_t &outSerial) = 0;

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
