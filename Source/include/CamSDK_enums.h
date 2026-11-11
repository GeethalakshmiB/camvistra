///////////////////////////////////////////////////////////////////////////////
//
//  File      : CamSDK_enums.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Standard UVC camera properties and pixel formats.
//
//  Usage:
//    Pass UsbCameraProperty values to IV4L2::Get/SetCameraControlProperty.
//
//

/** @file CamSDK_enums.h
 * @brief Defines common USB camera properties and pixel formats. */
#ifndef ENUMS_H
#define ENUMS_H
#include "ILogger.h"
#include <map>

enum UsbCameraProperty {
  UvcPropertyBrightness = 0,
  UvcPropertyContrast,
  UvcPropertyHue,
  UvcPropertySaturation,
  UvcPropertySharpness,
  UvcPropertyGamma,
  UvcPropertyWhiteBalanceAuto,
  UvcPropertyWhiteBalanceManual,
  UvcPropertyBacklightCompensation,
  UvcPropertyGain,
  UvcPropertyPowerLineFrequency ,
  UvcPropertyPan,
  UvcPropertyTilt,
  UvcPropertyRoll,
  UvcPropertyZoom,
  UvcPropertyExposureAuto,
  UvcPropertyExposureManual,
  UvcPropertyFocusAuto,
  UvcPropertyFocusManual
};

struct  CameraControlDefaultValues {
	std::map<UsbCameraProperty, int> defaultCameraPropertyValues;
};

typedef enum {
  PIX_FMT_UYVY,
  PIX_FMT_Y16,
  PIX_FMT_RGB,
  PIX_FMT_Y12,
  PIX_FMT_Y10,
} PixFormat;


#endif /* ENUMS_H */
