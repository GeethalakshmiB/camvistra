///////////////////////////////////////////////////////////////////////////////
//
//  File      : ISee3CAM_CU200.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    See3CAM_CU200 extension-unit (HID) controls:
//      camera mode, exposure, gain, white balance, colour matrix, gamma,
//      sharpness, denoise, AE ROI, strobe, statistics, config save
//
//  Usage:
//    auto cam = eCamSDK::ISee3CAM_CU200::create();
//    cam->initFromDevicePath(path);   // or cam->setHidFd(fd) on Linux
//    cam->get...() / cam->set...()    // returns true on success
//
//

/** @file ISee3CAM_CU200.h @brief Declares the ISee3CAM_CU200 interface and the public types used by it. */
#pragma once

#include <memory>

#include "ILogger.h"
#include "CamSDK_Exports.h"
#include <cstdint>
#include <string>

// ----------------------------------------------------------------
// Enumerations
// ----------------------------------------------------------------
enum class CameraModeCU200 : uint8_t {
    MASTER  = 0x00,
    TRIGGER = 0x01
};

enum class ExposureModeCU200 : uint8_t {
    AUTO   = 0x00,
    MANUAL = 0x01
};

enum class AutoExposureFeatureCU200 : uint8_t {
    CONTINUOUS  = 0x00,
    SINGLE_SHOT = 0x01
};

enum class StrobeModeCU200 : uint8_t {
    OFF = 0x00,
    ON  = 0x01
};

enum class FlipModeCU200 : uint8_t {
    NORMAL     = 0x00,
    HORIZONTAL = 0x01,
    VERTICAL   = 0x02,
    ROTATE_180 = 0x03
};

enum class SaveConfigurationCU200 : uint8_t {
    DEFAULT      = 0x00,
    USER_DEFINED = 0x01
};

enum class WhiteBalanceModeCU200 : uint8_t {
    AUTO   = 0x00,
    MANUAL = 0x01
};

enum class AutoWbFeatureCU200 : uint8_t {
    CONTINUOUS  = 0x00,
    SINGLE_SHOT = 0x01
};

enum class ManualWbModeCU200 : uint8_t {
    COLOR_TEMPERATURE = 0x00,
    PRESET            = 0x01,
    PRO_MODE          = 0x02
};

enum class WbPresetCU200 : uint8_t {
    HZ_2300K   = 0x00,
    A_2800K    = 0x01,
    U30_3000K  = 0x02,
    TL84_4000K = 0x03,
    CWF_4100K  = 0x04,
    D50_5000K  = 0x05,
    D60_6000K  = 0x06,
    D65_6500K  = 0x07
};

enum class AutoExpRoiModeCU200 : uint8_t {
    FULL_ROI   = 0x00,
    MANUAL_ROI = 0x01
};

enum class AntiFlickerModeCU200 : uint8_t {
    MODE_50Hz    = 0x00,
    MODE_60Hz    = 0x01,
    MODE_DISABLE = 0x02
};

// ----------------------------------------------------------------
// Value/range structs returned by the getters below
// ----------------------------------------------------------------
struct RangeF {
    float current = 0.0f; // Stores current.
    float min = 0.0f; // Stores min.
    float max = 0.0f; // Stores max.
    float step = 0.0f; // Stores step.
};

struct RangeU32 {
    uint32_t current = 0; // Stores current.
    uint32_t min = 0; // Stores min.
    uint32_t max = 0; // Stores max.
    uint32_t step = 0; // Stores step.
};

struct RangeU8 {
    uint8_t current = 0; // Stores current.
    uint8_t min = 0; // Stores min.
    uint8_t max = 0; // Stores max.
    uint8_t step = 0; // Stores step.
};

struct GainInfoCU200 {
    RangeF rGain; // Stores r gain.
    RangeF bGain; // Stores b gain.
};

struct ColorCorrectionMatrixCU200 {
    float Rr = 0.0f, Rg = 0.0f, Rb = 0.0f; // Stores rr and rg and rb.
    float Gr = 0.0f, Gg = 0.0f, Gb = 0.0f; // Stores gr and gg and gb.
    float Br = 0.0f, Bg = 0.0f, Bb = 0.0f; // Stores br and bg and bb.
};

struct ExposureInfoCU200 {
    uint8_t mode = 0; // Stores mode.
    uint8_t autoFeature = 0; // Stores auto feature.
    uint32_t manualExposure = 0; // Stores manual exposure.
};

struct WhiteBalanceInfoCU200 {
    uint8_t mode = 0; // Stores mode.
    uint8_t autoFeature = 0; // Stores auto feature.
    uint8_t manualFeature = 0; // Stores manual feature.
    uint8_t presetMode = 0; // Stores preset mode.
};

struct RoiInfoCU200 {
    uint8_t mode = 0; // Stores mode.
    uint8_t windowSize = 0; // Stores window size.
};

struct StatisticsInfoCU200 {
    uint32_t currentExposure = 0; // Stores current exposure.
    uint8_t autoGainStatus = 0; // Stores auto gain status.
    float rGain = 0.0f; // Stores r gain.
    float bGain = 0.0f; // Stores b gain.
    ColorCorrectionMatrixCU200 ccm; // Stores ccm.
};

namespace eCamSDK {

/**
 * @brief Abstract interface for the See3CAM_CU200 camera controls.
 *
 * Applications should hold the camera through this interface and obtain an
 * instance with ISee3CAM_CU200::create(), instead of using See3CAM_CU200 directly.
 */
class CAMSDK ISee3CAM_CU200 {
public:
    /** @brief Releases the camera controller. */
    virtual ~ISee3CAM_CU200() = default;

    /**
     * @brief Creates the See3CAM_CU200 implementation.
     * @return Owning pointer to a newly created See3CAM_CU200 instance.
     */
    static std::unique_ptr<ISee3CAM_CU200> create();

    /** @brief Sets set hid fd. */
    virtual bool setHidFd(int fd) = 0;

#ifdef _WIN32
    /** @brief Performs init from device path. */
    virtual bool initFromDevicePath(TCHAR *devicePath) = 0;
    /** @brief Performs deinit extension unit. */
    virtual void deinitExtensionUnit() = 0;
#endif

    /** @brief Retrieves get rbgain. */
    virtual bool getRBGain(GainInfoCU200 &outGain) = 0;
    /** @brief Performs set rbgain. */
    virtual bool setRBGain(float rGain, float bGain) = 0;

    /** @brief Retrieves get color correction matrix. */
    virtual bool getColorCorrectionMatrix(ColorCorrectionMatrixCU200 &outMatrix) = 0;
    /** @brief Sets set color correction matrix. */
    virtual bool setColorCorrectionMatrix(const ColorCorrectionMatrixCU200 &matrix) = 0;

    /** @brief Performs get black level. */
    virtual bool getBlackLevel(RangeU32 &outBlackLevel) = 0;
    /** @brief Sets set black level. */
    virtual bool setBlackLevel(uint16_t blackLevel) = 0;

    /** @brief Retrieves get brightness. */
    virtual bool getBrightness(RangeF &outBrightness) = 0;
    /** @brief Sets set brightness. */
    virtual bool setBrightness(float brightness) = 0;

    /** @brief Performs get target brightness. */
    virtual bool getTargetBrightness(RangeU32 &outTargetBrightness) = 0;
    /** @brief Sets set target brightness. */
    virtual bool setTargetBrightness(uint16_t targetBrightness) = 0;

    /** @brief Retrieves get contrast. */
    virtual bool getContrast(RangeU8 &outContrast) = 0;
    /** @brief Sets set contrast. */
    virtual bool setContrast(uint8_t contrast) = 0;

    /** @brief Performs get saturation. */
    virtual bool getSaturation(RangeF &outSaturation) = 0;
    /** @brief Sets set saturation. */
    virtual bool setSaturation(float saturation) = 0;

    /** @brief Retrieves get color temperature. */
    virtual bool getColorTemperature(RangeU32 &outColorTemperature) = 0;
    /** @brief Sets set color temperature. */
    virtual bool setColorTemperature(uint16_t colorTemperature) = 0;

    /** @brief Performs get gamma correction. */
    virtual bool getGammaCorrection(RangeF &outGamma) = 0;
    /** @brief Sets set gamma correction. */
    virtual bool setGammaCorrection(float gamma) = 0;

    /** @brief Retrieves get exposure. */
    virtual bool getExposure(ExposureInfoCU200 &outExposure) = 0;
    /** @brief Sets set exposure. */
    virtual bool setExposure(ExposureModeCU200 mode, AutoExposureFeatureCU200 autoFeature, uint32_t manualExposure) = 0;

    /** @brief Performs get exposure compensation. */
    virtual bool getExposureCompensation(uint32_t &outExposureCompensation) = 0;
    /** @brief Sets set exposure compensation. */
    virtual bool setExposureCompensation(uint32_t exposureCompensation) = 0;

    /** @brief Retrieves get auto gain upper limit. */
    virtual bool getAutoGainUpperLimit(RangeU8 &outUpperLimit) = 0;
    /** @brief Sets set auto gain upper limit. */
    virtual bool setAutoGainUpperLimit(uint8_t upperLimit) = 0;

    /** @brief Performs get auto exp roi mode and window size. */
    virtual bool getAutoExpRoiModeAndWindowSize(RoiInfoCU200 &outRoi) = 0;
    /** @brief Sets set roi auto exposure. */
    virtual bool setRoiAutoExposure(AutoExpRoiModeCU200 roiMode, uint32_t vidResolnWidth, uint32_t vidResolnHeight,
                             uint32_t xCord, uint32_t yCord, uint8_t winSize) = 0;

    /** @brief Retrieves get camera mode. */
    virtual bool getCameraMode(uint8_t &outCameraMode) = 0;
    /** @brief Performs set camera mode. */
    virtual bool setCameraMode(CameraModeCU200 camMode) = 0;

    /** @brief Retrieves get strobe mode. */
    virtual bool getStrobeMode(uint8_t &outStrobeMode) = 0;
    /** @brief Sets set strobe mode. */
    virtual bool setStrobeMode(StrobeModeCU200 strobeMode) = 0;

    /** @brief Performs get orientation. */
    virtual bool getOrientation(uint8_t &outFlipMode) = 0;
    /** @brief Sets set orientation. */
    virtual bool setOrientation(bool horzFlip, bool vertFlip) = 0;

    /** @brief Retrieves get white balance mode. */
    virtual bool getWhiteBalanceMode(WhiteBalanceInfoCU200 &outWhiteBalance) = 0;
    /** @brief Sets set white balance mode. */
    virtual bool setWhiteBalanceMode(WhiteBalanceModeCU200 mode, AutoWbFeatureCU200 autoFeature,
                              ManualWbModeCU200 manualMode, WbPresetCU200 presetMode) = 0;

    /** @brief Performs get anti flicker mode. */
    virtual bool getAntiFlickerMode(uint8_t &outAntiFlickerMode) = 0;
    /** @brief Sets set anti flicker mode. */
    virtual bool setAntiFlickerMode(AntiFlickerModeCU200 antiFlickerMode) = 0;

    // Denoise/sharpness are host-side-only settings on this camera (not sent over
    // HID by this SDK); they simply track the last value requested by the caller.
    /** @brief Performs get denoise flag. */
    virtual bool getDenoiseFlag(bool &outEnabled) = 0;
    /** @brief Performs enable disable denoising. */
    virtual bool enableDisableDenoising(bool enable) = 0;
    /** @brief Retrieves get denoise strength. */
    virtual bool getDenoiseStrength(RangeF &outStrength) = 0;
    /** @brief Sets set denoise strength. */
    virtual bool setDenoiseStrength(float strength) = 0;

    /** @brief Performs get sharpness strength. */
    virtual bool getSharpnessStrength(RangeF &outStrength) = 0;
    /** @brief Sets set sharpness strength. */
    virtual bool setSharpnessStrength(float strength) = 0;

    /** @brief Sets set properties for cross still. */
    virtual bool setPropertiesForCrossStill(bool isEnable) = 0;

    /** @brief Performs read statistics. */
    virtual bool readStatistics(StatisticsInfoCU200 &outStatistics) = 0;

    /** @brief Performs save configuration. */
    virtual bool saveConfiguration(SaveConfigurationCU200 configMode) = 0;

    /** @brief Performs reset device. */
    virtual bool resetDevice() = 0;

    /** @brief Performs read ispfirmware version. */
    virtual bool readISPFirmwareVersion(std::string &outVersion) = 0;

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

    /** @brief Sets set to default. */
    virtual bool setToDefault() = 0;
};

} // namespace eCamSDK
