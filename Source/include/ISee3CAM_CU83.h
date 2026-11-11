///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU83.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU83 extension-unit (HID) controls:
//      stream mode, special mode, AE ROI, face detection, wake-on-
//      motion, flash, orientation, anti-flicker, denoise, burst
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU83::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU83.h @brief Declares the ISee3CAM_CU83 interface and the public types used by it. */
#pragma once

#include <memory>
#include <cstdint>

#include "CamSDK_Exports.h"

enum class SpecialModeCU83 : uint8_t {
  NORMAL = 0x01,
  BLACK_WHITE = 0x04,
  GREYSCALE = 0x07,
  NEGATIVE = 0x08,
  SKETCH = 0x10
};
enum class AutoExpRoiModeCU83 : uint8_t { FULL = 0x01, MANUAL = 0x02 };
enum class AntiFlickerCU83 : uint8_t { AUTO = 0, HZ_50 = 1, HZ_60 = 2, DISABLE = 3 };
enum class BinaryModeCU83 : uint8_t { DISABLE = 0, ENABLE = 1 };
enum class StreamModeCU83 : uint8_t { MASTER = 0, TRIGGER = 1 };
enum class FlashModeCU83 : uint8_t { STROBE_OFF = 0, STROBE_ON = 1 };
struct RoiAutoExposureCU83 {
  uint8_t mode, windowSize; // Stores mode and window size.
};
struct FaceDetectionCU83 {
  uint8_t enabled, overlay, embeddedData; // Stores enabled and overlay and embedded data.
};

namespace eCamSDK {
/**
 * @brief Abstract interface for the See3CAM_CU83 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU83::create(), instead of using See3CAM_CU83 directly.
 */
class CAMSDK ISee3CAM_CU83 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU83() = default;

    /**
     * @brief Creates the See3CAM_CU83 implementation.
     * @return Owning pointer to a newly created See3CAM_CU83 instance.
     */
    static std::unique_ptr<ISee3CAM_CU83> create();

#ifdef _WIN32
  /** @brief Initializes init from device path. */
  virtual bool initFromDevicePath(TCHAR*) = 0;

  /** @brief Performs deinit extension unit. */
  virtual void deinitExtensionUnit() = 0;
#endif
  /** @brief Performs set hid fd. */
  virtual bool setHidFd(int) = 0;

  /** @brief Retrieves get special mode. */
  virtual bool getSpecialMode(uint8_t&) = 0;

  /** @brief Sets set special mode. */
  virtual bool setSpecialMode(SpecialModeCU83) = 0;

  /** @brief Performs get denoise value. */
  virtual bool getDenoiseValue(uint8_t&) = 0;

  /** @brief Sets set denoise value. */
  virtual bool setDenoiseValue(uint8_t) = 0;

  /** @brief Retrieves get auto exp roi. */
  virtual bool getAutoExpROI(RoiAutoExposureCU83&) = 0;

  /** @brief Performs set auto exp roi. */
  virtual bool setAutoExpROI(AutoExpRoiModeCU83, uint32_t, uint32_t, uint32_t, uint32_t, uint8_t) = 0;

  /** @brief Retrieves get orientation. */
  virtual bool getOrientation(uint8_t&) = 0;

  /** @brief Sets set orientation. */
  virtual bool setOrientation(bool, bool) = 0;

  /** @brief Performs get exposure compensation. */
  virtual bool getExposureCompensation(uint32_t&) = 0;

  /** @brief Sets set exposure compensation. */
  virtual bool setExposureCompensation(uint32_t) = 0;

  /** @brief Retrieves get frame rate ctrl value. */
  virtual bool getFrameRateCtrlValue(uint8_t&, uint8_t&, uint8_t&) = 0;

  /** @brief Performs set frame rate ctrl value. */
  virtual bool setFrameRateCtrlValue(uint8_t) = 0;

  /** @brief Retrieves get burst length. */
  virtual bool getBurstLength(uint8_t&) = 0;

  /** @brief Sets set burst length. */
  virtual bool setBurstLength(uint8_t) = 0;

  /** @brief Performs get anti flicker mode. */
  virtual bool getAntiFlickerMode(uint8_t&) = 0;

  /** @brief Sets set anti flicker mode. */
  virtual bool setAntiFlickerMode(AntiFlickerCU83) = 0;

  /** @brief Retrieves get wake on motion. */
  virtual bool getWakeOnMotion(uint8_t&) = 0;

  /** @brief Performs set wake on motion. */
  virtual bool setWakeOnMotion(BinaryModeCU83) = 0;

  /** @brief Retrieves get face detection. */
  virtual bool getFaceDetection(FaceDetectionCU83&) = 0;

  /** @brief Sets set face detection. */
  virtual bool setFaceDetection(bool, bool, bool) = 0;

  /** @brief Performs get stream mode. */
  virtual bool getStreamMode(uint8_t&) = 0;

  /** @brief Sets set stream mode. */
  virtual bool setStreamMode(StreamModeCU83) = 0;

  /** @brief Retrieves get flash mode. */
  virtual bool getFlashMode(uint8_t&) = 0;

  /** @brief Performs set flash mode. */
  virtual bool setFlashMode(FlashModeCU83) = 0;

  /** @brief Sets set to default values. */
  virtual bool setToDefaultValues() = 0;
};
}  // namespace eCamSDK
