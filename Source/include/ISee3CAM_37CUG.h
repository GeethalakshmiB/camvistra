///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_37CUG.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_37CUG extension-unit (HID) controls:
//      camera/trigger mode, strobe, exposure and gain mode, fast AE,
//      target brightness, anti-flicker, statistics, temperature
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_37CUG::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_37CUG.h @brief Declares the ISee3CAM_37CUG interface and the public types used by it. */
#pragma once

#include <memory>

#include "CamSDK_Exports.h"

#include <cstdint>

enum class CameraMode37CUG : uint8_t {
    MASTER = 0x01,
    TRIGGER_EXPOSURE = 0x02
};

enum class Orientation37CUG : uint8_t {
    NORMAL = 0x01,
    VERTICAL_FLIP = 0x02,
    HORIZONTAL_FLIP = 0x03,
    BOTH_FLIP = 0x04
};

enum class GainMode37CUG : uint8_t {
    AUTO = 0x00,
    MANUAL = 0x01
};

enum class AutoGainFeature37CUG : uint8_t {
    CONTINUOUS = 0x00,
    SINGLE = 0x01,
    TRIGGER = 0x02
};

enum class ExposureMode37CUG : uint8_t {
    AUTO = 0x00,
    MANUAL = 0x01
};

enum class AutoExposureFeature37CUG : uint8_t {
    CONTINUOUS = 0x00,
    SINGLE_TRIGGER = 0x01
};

enum class AntiFlicker37CUG : uint8_t {
    HZ_50 = 0x00,
    HZ_60 = 0x01,
    DISABLE = 0x02
};

struct GainProperties37CUG {
    uint8_t mode; // Stores mode.
    uint8_t feature; // Stores feature.
    uint16_t minimum; // Stores minimum.
    uint16_t maximum; // Stores maximum.
    uint16_t current; // Stores current.
    uint8_t step; // Stores step.
};

struct ExposureProperties37CUG {
    uint8_t mode; // Stores mode.
    uint8_t feature; // Stores feature.
    uint32_t seconds; // Stores seconds.
    uint32_t milliSeconds; // Stores milli seconds.
    uint32_t microSeconds; // Stores micro seconds.
};

struct RangeProperties37CUG {
    uint32_t minimum; // Stores minimum.
    uint32_t maximum; // Stores maximum.
    uint32_t step; // Stores step.
    uint32_t current; // Stores current.
};

struct CropRangeProperties37CUG {
    uint16_t size; // Stores size.
    uint16_t minimum; // Stores minimum.
    uint16_t maximum; // Stores maximum.
    uint8_t step; // Stores step.
};

struct GainRangeProperties37CUG {
    uint16_t gain; // Stores gain.
    uint16_t minimum; // Stores minimum.
    uint16_t maximum; // Stores maximum.
    uint8_t step; // Stores step.
};

struct SelfTriggerProperties37CUG {
    uint8_t mode; // Stores mode.
    CropRangeProperties37CUG horizontalCrop; // Stores horizontal crop.
    CropRangeProperties37CUG verticalCrop; // Stores vertical crop.
    uint32_t exposure; // Stores exposure.
    uint16_t highLevel; // Stores high level.
    uint16_t lowLevel; // Stores low level.
    uint32_t highCount; // Stores high count.
    uint32_t lowCount; // Stores low count.
    uint8_t sensingMode; // Stores sensing mode.
    uint8_t forceMode; // Stores force mode.
    uint32_t highDetectedPixels; // Stores high detected pixels.
    uint32_t lowDetectedPixels; // Stores low detected pixels.
    GainRangeProperties37CUG sensingGain; // Stores sensing gain.
    GainRangeProperties37CUG capturingGain; // Stores capturing gain.
};

struct ISPFirmwareVersion37CUG {
    uint8_t major; // Stores major.
    uint8_t minor; // Stores minor.
    uint8_t patch; // Stores patch.
    uint8_t build; // Stores build.
};

namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_37CUG camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_37CUG::create(), instead of using See3CAM_37CUG directly.
 */
class CAMSDK ISee3CAM_37CUG {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_37CUG() = default;

    /**
     * @brief Creates the See3CAM_37CUG implementation.
     * @return Owning pointer to a newly created See3CAM_37CUG instance.
     */
    static std::unique_ptr<ISee3CAM_37CUG> create();

#ifdef _WIN32
    /** @brief Initializes init from device path. */
    virtual bool initFromDevicePath(TCHAR *devicePath) = 0;
    /** @brief Performs deinit extension unit. */
    virtual void deinitExtensionUnit() = 0;
#endif
    /** @brief Sets set hid fd. */
    virtual bool setHidFd(int fd) = 0;

    /** @brief Retrieves get camera mode. */
    virtual bool getCameraMode(uint8_t &mode) = 0;
    /** @brief Performs set camera mode. */
    virtual bool setCameraMode(CameraMode37CUG mode) = 0;
    /** @brief Retrieves get orientation. */
    virtual bool getOrientation(Orientation37CUG &orientation) = 0;
    /** @brief Sets set orientation. */
    virtual bool setOrientation(bool horizontal, bool vertical) = 0;
    /** @brief Retrieves get gain mode. */
    virtual bool getGainMode(GainProperties37CUG &properties) = 0;
    /** @brief Sets set gain mode. */
    virtual bool setGainMode(GainMode37CUG mode, AutoGainFeature37CUG feature, uint16_t manualGain) = 0;
    /** @brief Performs get strobe mode. */
    virtual bool getStrobeMode(uint8_t &mode) = 0;
    /** @brief Sets set strobe mode. */
    virtual bool setStrobeMode(uint8_t mode) = 0;
    /** @brief Retrieves get burst length. */
    virtual bool getBurstLength(uint8_t &length) = 0;
    /** @brief Sets set burst length. */
    virtual bool setBurstLength(uint8_t length) = 0;
    /** @brief Retrieves get exposure mode. */
    virtual bool getExposureMode(ExposureProperties37CUG &properties) = 0;
    /** @brief Performs set exposure mode. */
    virtual bool setExposureMode(ExposureMode37CUG mode, AutoExposureFeature37CUG feature,
                         uint32_t seconds, uint32_t milliSeconds, uint32_t microSeconds) = 0;
    /** @brief Retrieves get target brightness. */
    virtual bool getTargetBrightness(RangeProperties37CUG &properties) = 0;
    /** @brief Sets set target brightness. */
    virtual bool setTargetBrightness(uint16_t brightness) = 0;
    /** @brief Retrieves get anti flicker mode. */
    virtual bool getAntiFlickerMode(uint8_t &mode) = 0;
    /** @brief Performs set anti flicker mode. */
    virtual bool setAntiFlickerMode(AntiFlicker37CUG mode) = 0;
    /** @brief Retrieves read statistics. */
    virtual bool readStatistics(uint32_t &seconds, uint32_t &milliSeconds,
                        uint32_t &microSeconds, uint8_t &gain) = 0;
    /** @brief Retrieves read temperature. */
    virtual bool readTemperature(float &temperature) = 0;
    /** @brief Retrieves get fast auto exposure. */
    virtual bool getFastAutoExposure(uint8_t &mode) = 0;
    /** @brief Performs set fast auto exposure. */
    virtual bool setFastAutoExposure(uint8_t mode) = 0;
    /** @brief Retrieves get self trigger. */
    virtual bool getSelfTrigger(SelfTriggerProperties37CUG &properties) = 0;
    /** @brief Sets set self trigger. */
    virtual bool setSelfTrigger(uint8_t mode, uint16_t videoWidth, uint16_t videoHeight,
                         uint16_t hCropPos, uint16_t vCropPos,
                         uint16_t hCropSize, uint16_t vCropSize,
                         uint32_t exposure, uint16_t highLevel, uint16_t lowLevel,
                         uint32_t highCount, uint32_t lowCount,
                         uint8_t sensingMode, uint8_t forceMode,
                         uint32_t highDetectedPixels, uint32_t lowDetectedPixels,
                         uint16_t sensingGain, uint16_t capturingGain) = 0;
    /** @brief Performs get exposure compensation. */
    virtual bool getExposureCompensation(uint32_t &seconds, uint32_t &milliSeconds, uint32_t &microSeconds) = 0;
    /** @brief Sets set exposure compensation. */
    virtual bool setExposureCompensation(uint32_t seconds, uint32_t milliSeconds, uint32_t microSeconds) = 0;
    /** @brief Retrieves get faetarget brightness. */
    virtual bool getFAETargetBrightness(RangeProperties37CUG &properties) = 0;
    /** @brief Sets set faetarget brightness. */
    virtual bool setFAETargetBrightness(uint16_t brightness) = 0;
    /** @brief Retrieves get faeexecution frames. */
    virtual bool getFAEExecutionFrames(uint8_t &frames) = 0;
    /** @brief Performs set faeexecution frames. */
    virtual bool setFAEExecutionFrames(uint8_t frames) = 0;
    /** @brief Sets set to default values. */
    virtual bool setToDefaultValues() = 0;
    /** @brief Retrieves read ispfirmware version. */
    virtual bool readISPFirmwareVersion(ISPFirmwareVersion37CUG &version) = 0;
};

} // namespace eCamSDK
