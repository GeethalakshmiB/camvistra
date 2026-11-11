///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU31.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU31 extension-unit (HID) controls:
//      camera and trigger mode, AE/AWB windows, masks and overlays,
//      preset mode, noise reduction, embedded data, temperature
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU31::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU31.h @brief Declares the ISee3CAM_CU31 interface and the public types used by it. */
#pragma once

#include <memory>

#include <cstdint>
#include <string>

#include "CamSDK_Exports.h"

enum class OrientationCU31 : uint8_t { NORMAL = 0, HORIZONTAL = 1, VERTICAL = 2, ROTATE_180 = 3 };
enum class RNRStatusCU31 : uint8_t { DISABLE = 0, ENABLE = 1 };
enum class TriggerModeCU31 : uint8_t { DISABLE = 0, READOUT = 1, SHUTTER = 2 };
enum class AutoExposureCU31 : uint8_t { RELEASE = 0, HOLD = 1 };
enum class AutoWhiteBalanceCU31 : uint8_t { RELEASE = 0, HOLD = 1 };
enum class AntiFlickerCU31 : uint8_t { AUTO = 0, HZ_50 = 1, HZ_60 = 2, DISABLE = 3 };
enum class CameraModeCU31 : uint8_t { AUTO = 0, LOW_LIGHT = 1, LED = 2 };
enum class PresetModeCU31 : uint8_t { MANUAL = 0, USER_1 = 1, USER_2 = 2 };
enum class PresetOperationCU31 : uint8_t { SELECT = 0, SAVE = 1, SET_DEFAULT = 2 };

struct WindowDimensionsCU31 {
  uint16_t width, height, xStart, yStart; // Stores width and height and x start and y start.
};
struct MaskDimensionsCU31 {
  uint8_t id, state; // Stores id and state.
  uint16_t width, height, xStart, yStart; // Stores width and height and x start and y start.
};
struct PresetPropertiesCU31 {
  uint8_t mode, operation; // Stores mode and operation.
};
struct UVCControlValuesCU31 {
  int16_t brightness; // Stores brightness.
  uint16_t contrast; // Stores contrast.
  uint16_t saturation; // Stores saturation.
  uint16_t sharpness; // Stores sharpness.
  uint16_t gain; // Stores gain.
  uint16_t exposureMode; // Stores exposure mode.
  uint16_t exposureTime; // Stores exposure time.
};
struct ISPFirmwareVersionCU31 {
  uint8_t major, minor1, minor2, minor3; // Stores major and minor1 and minor2 and minor3.
};

namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU31 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU31::create(), instead of using See3CAM_CU31 directly.
 */
class CAMSDK ISee3CAM_CU31 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU31() = default;

    /**
     * @brief Creates the See3CAM_CU31 implementation.
     * @return Owning pointer to a newly created See3CAM_CU31 instance.
     */
    static std::unique_ptr<ISee3CAM_CU31> create();

#ifdef _WIN32
  /** @brief Performs init from device path. */
  virtual bool initFromDevicePath(TCHAR* devicePath) = 0;

  /** @brief Performs deinit extension unit. */
  virtual void deinitExtensionUnit() = 0;
#endif
  /** @brief Sets set hid fd. */
  virtual bool setHidFd(int fd) = 0;

  /** @brief Performs get orientation. */
  virtual bool getOrientation(uint8_t& value) = 0;

  /** @brief Sets set orientation. */
  virtual bool setOrientation(bool horizontal, bool vertical) = 0;

  /** @brief Retrieves get raw noise reduction status. */
  virtual bool getRawNoiseReductionStatus(uint8_t& value) = 0;

  /** @brief Performs set raw noise reduction status. */
  virtual bool setRawNoiseReductionStatus(RNRStatusCU31 value) = 0;

  /** @brief Retrieves get trigger mode. */
  virtual bool getTriggerMode(uint8_t& value) = 0;

  /** @brief Sets set trigger mode. */
  virtual bool setTriggerMode(TriggerModeCU31 value) = 0;

  /** @brief Performs get aeconvergence speed. */
  virtual bool getAEConvergenceSpeed(uint8_t& value) = 0;

  /** @brief Sets set aeconvergence speed. */
  virtual bool setAEConvergenceSpeed(uint8_t value) = 0;

  /** @brief Retrieves get auto exposure status. */
  virtual bool getAutoExposureStatus(uint8_t& value) = 0;

  /** @brief Performs set auto exposure status. */
  virtual bool setAutoExposureStatus(AutoExposureCU31 value) = 0;

  /** @brief Retrieves get awbstatus. */
  virtual bool getAWBStatus(uint8_t& value) = 0;

  /** @brief Sets set awbstatus. */
  virtual bool setAWBStatus(AutoWhiteBalanceCU31 value) = 0;

  /** @brief Performs read temperature. */
  virtual bool readTemperature(float& value) = 0;

  /** @brief Retrieves get anti flicker mode. */
  virtual bool getAntiFlickerMode(uint8_t& value) = 0;

  /** @brief Sets set anti flicker mode. */
  virtual bool setAntiFlickerMode(AntiFlickerCU31 value) = 0;

  /** @brief Performs get camera mode. */
  virtual bool getCameraMode(uint8_t& value) = 0;

  /** @brief Sets set camera mode. */
  virtual bool setCameraMode(CameraModeCU31 value) = 0;

  /** @brief Retrieves get aewindow overlay. */
  virtual bool getAEWindowOverlay(uint8_t& value) = 0;

  /** @brief Performs set aewindow overlay. */
  virtual bool setAEWindowOverlay(uint8_t value) = 0;

  /** @brief Retrieves get aewindow dimensions. */
  virtual bool getAEWindowDimensions(WindowDimensionsCU31& value) = 0;

  /** @brief Sets set aewindow dimensions. */
  virtual bool setAEWindowDimensions(uint16_t width, uint16_t height, uint16_t xStart, uint16_t yStart) = 0;

  /** @brief Performs get aemask overlay. */
  virtual bool getAEMaskOverlay(uint8_t& value) = 0;

  /** @brief Sets set aemask overlay. */
  virtual bool setAEMaskOverlay(uint8_t value) = 0;

  /** @brief Retrieves get aemask dimensions. */
  virtual bool getAEMaskDimensions(uint8_t maskId, MaskDimensionsCU31& value) = 0;

  /** @brief Performs set aemask dimensions. */
  virtual bool setAEMaskDimensions(uint8_t maskId, uint8_t state, uint16_t width, uint16_t height, uint16_t xStart,
                           uint16_t yStart) = 0;

  /** @brief Retrieves get awbwindow overlay. */
  virtual bool getAWBWindowOverlay(uint8_t& value) = 0;

  /** @brief Performs set awbwindow overlay. */
  virtual bool setAWBWindowOverlay(uint8_t value) = 0;

  /** @brief Retrieves get awbwindow dimensions. */
  virtual bool getAWBWindowDimensions(WindowDimensionsCU31& value) = 0;

  /** @brief Sets set awbwindow dimensions. */
  virtual bool setAWBWindowDimensions(uint16_t width, uint16_t height, uint16_t xStart, uint16_t yStart) = 0;

  /** @brief Performs get awbmask overlay. */
  virtual bool getAWBMaskOverlay(uint8_t& value) = 0;

  /** @brief Sets set awbmask overlay. */
  virtual bool setAWBMaskOverlay(uint8_t value) = 0;

  /** @brief Retrieves get awbmask dimensions. */
  virtual bool getAWBMaskDimensions(uint8_t maskId, MaskDimensionsCU31& value) = 0;

  /** @brief Performs set awbmask dimensions. */
  virtual bool setAWBMaskDimensions(uint8_t maskId, uint8_t state, uint16_t width, uint16_t height, uint16_t xStart,
                            uint16_t yStart) = 0;

  /** @brief Retrieves get embedded data. */
  virtual bool getEmbeddedData(uint8_t& value) = 0;

  /** @brief Performs set embedded data. */
  virtual bool setEmbeddedData(uint8_t value) = 0;

  /** @brief Retrieves get preset mode. */
  virtual bool getPresetMode(PresetPropertiesCU31& value) = 0;

  /** @brief Sets set preset mode. */
  virtual bool setPresetMode(PresetModeCU31 mode, PresetOperationCU31 operation) = 0;

  /** @brief Performs get uvccontrols. */
  virtual bool getUVCControls(UVCControlValuesCU31& value) = 0;

  /** @brief Sets set properties for cross still. */
  virtual bool setPropertiesForCrossStill() = 0;

  /** @brief Sets set to default values. */
  virtual bool setToDefaultValues() = 0;

  /** @brief Performs get64 bit serial number. */
  virtual bool get64BitSerialNumber(uint64_t& value) = 0;

  /** @brief Retrieves read ispfirmware version. */
  virtual bool readISPFirmwareVersion(ISPFirmwareVersionCU31& value) = 0;
};

}  // namespace eCamSDK
