///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_27CUG.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_27CUG extension-unit (HID) controls:
//      camera mode (RGB/IR), stream and strobe mode, IR brightness,
//      contrast and gain, orientation, exposure-compensation range
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_27CUG::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_27CUG.h @brief Declares the ISee3CAM_27CUG interface and the public types used by it. */
#pragma once

#include <memory>
#include <cstdint>
#include <string>

#include "CamSDK_Exports.h"

enum class StreamMode27CUG : uint8_t { MASTER = 1, TRIGGER = 2 };
enum class StrobeMode27CUG : uint8_t { OFF = 1, ON = 2 };
enum class CameraMode27CUG : uint8_t { RGB_IR = 1, RGB = 2, IR = 3 };
namespace eCamSDK {
/**
 * @brief Abstract interface for the See3CAM_27CUG camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_27CUG::create(), instead of using See3CAM_27CUG directly.
 */
class CAMSDK ISee3CAM_27CUG {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_27CUG() = default;

    /**
     * @brief Creates the See3CAM_27CUG implementation.
     * @return Owning pointer to a newly created See3CAM_27CUG instance.
     */
    static std::unique_ptr<ISee3CAM_27CUG> create();

#ifdef _WIN32
  /** @brief Initializes the HID extension unit from a device path.
   * @param devicePath Device path.
   * @return true on success. */
  virtual bool initFromDevicePath(TCHAR*) = 0;

  /** @brief Releases the Windows HID extension-unit handle. */
  virtual void deinitExtensionUnit() = 0;
#endif
  /** @brief Associates the controller with an open HID descriptor.
   *  @param fd HID descriptor.
   *  @return true on success. */
  virtual bool setHidFd(int) = 0;

  /** @brief Reads the current stream mode.
   *  @param value Output stream mode value.
   * @return true on success. */
  virtual bool getStreamMode(uint8_t&) = 0;

  /** @brief Sets the stream mode.
   *  @param mode Stream mode to apply.
   * @return true on success. */
  virtual bool setStreamMode(StreamMode27CUG) = 0;

  /** @brief Reads the current strobe mode.
   *  @param value Output strobe mode value.
   *  @return true on success. */
  virtual bool getStrobeMode(uint8_t&) = 0;

  /** @brief Sets the strobe mode.
   * @param mode Strobe mode to apply.
   * @return true on success. */
  virtual bool setStrobeMode(StrobeMode27CUG) = 0;

  /** @brief Reads the current camera mode.
   *  @param value Output camera mode value.
   *  @return true on success. */
  virtual bool getCameraMode(uint8_t&) = 0;

  /** @brief Sets the camera mode.
   *  @param mode Camera mode to apply.
   * @return true on success. */
  virtual bool setCameraMode(CameraMode27CUG) = 0;

  /** @brief Reads the orientation flags.
   *  @param value Output orientation value.
   *  @return true on success. */
  virtual bool getOrientation(uint8_t&) = 0;

  /** @brief Sets horizontal and vertical orientation.
   *  @param horizontalFlip Horizontal flip flag.
   * @param verticalFlip Vertical flip flag.
   *  @return true on success. */
  virtual bool setOrientation(bool, bool) = 0;

  /** @brief Reads the IR brightness value.
   *  @param value Output brightness.
   *  @return true on success. */
  virtual bool getBrightnessForIR(uint8_t&) = 0;

  /** @brief Sets the IR brightness value.
   *  @param value Brightness to apply.
   * @return true on success. */
  virtual bool setBrightnessForIR(uint8_t) = 0;

  /** @brief Reads the IR contrast value.
   *  @param value Output contrast.
   *  @return true on success. */
  virtual bool getContrastForIR(uint8_t&) = 0;

  /** @brief Sets the IR contrast value.
   *  @param value Contrast to apply.
   *  @return true on success. */
  virtual bool setContrastForIR(uint8_t) = 0;

  /** @brief Reads the IR gain value.
   *  @param value Output gain.
   *  @return true on success. */
  virtual bool getGainForIR(uint8_t&) = 0;

  /** @brief Sets the IR gain value.
   *  @param value Gain to apply.
   *  @return true on success. */
  virtual bool setGainForIR(uint8_t) = 0;

  /** @brief Reads the minimum exposure compensation.
   *  @param value Output compensation.
   *  @return true on success. */
  virtual bool getMinimumExposureCompensation(uint32_t&) = 0;

  /** @brief Sets the minimum exposure compensation.
   *  @param value Compensation to apply.
   *  @return true on success. */
  virtual bool setMinimumExposureCompensation(uint32_t) = 0;

  /** @brief Reads the maximum exposure compensation.
   *  @param value Output compensation.
   *  @return true on success. */
  virtual bool getMaximumExposureCompensation(uint32_t&) = 0;

  /** @brief Sets the maximum exposure compensation.
   *  @param value Compensation to apply.
   *  @return true on success. */
  virtual bool setMaximumExposureCompensation(uint32_t) = 0;

  /** @brief Reads the camera serial number.
   *  @param serialNumber Output serial number.
   *  @return true on success. */
  virtual bool getSerialNumber(std::string&) = 0;

  /** @brief Restores the camera's default settings.
   *  @return true on success. */
  virtual bool setToDefaultValues() = 0;
};
}  // namespace eCamSDK
