///////////////////////////////////////////////////////////////////////////////
//
//  File      : CAMSDK_types.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Shared camera, audio, frame and callback types used by the camera
//    SDK.
//
//  Usage:
//    Included by IV4l2.h; no functions to call.
//
//

/** @file CAMSDK_types.h
 * @brief Defines shared camera, audio, frame, and callback types. */
#pragma once
#ifndef CAMSDK_TYPES_H
#define CAMSDK_TYPES_H

#define DB_HIGH 0
#define DB_CRITICAL 0
#define DB_LOW 1

#define TIMEOUT             2000
#define READ_FIRMWARE_VERSION	0x40

#define OS_CODE			0x70
#define LINUX_OS		0x01

#define BUFFER_LENGTH		65

#define SET_FAIL		0x00
#define SET_SUCCESS		0x01

#include <functional>
#include <list>
#include <string>
#include <vector>
#include <map>
#include "CamSDK_enums.h"

#define LONG long
#define BYTE uint8_t
#define VOID void

struct AudioDeviceInfo {
  int deviceIndex = 0; // Stores device index.
  char deviceName[50]; // Stores device name.
  char devicePath[500]; // Stores device path.
};

#ifdef _WIN32
struct EncodingParameters {
  GUID subtype; // Stores subtype.
  UINT32 bitrate; // Stores bitrate.
};
#endif

typedef struct {
  float min; // Stores min.
  float max; // Stores max.
  float curVal; // Stores cur val.
} AudioProperty;

enum DeviceState { Arrival = 0, Removal, Interrupted, StreamingStarted, StreamingStopped, StreamingPaused, NoState };

enum GrabFrameOption {
  GRABFRAME_ON_STILLPIN = 0,
  GRABFRAME_ON_STILLPIN_NULLRENDER,
  GRABFRAME_ON_PREVIEWPIN,
  GRABFRAME_ON_PREVIEWPIN_NULLRENDER
};

typedef enum {
  MEDIA_MJPEG = 0,
  MEDIA_YUY2 = 1,
  MEDIA_UYVY = 2,
  MEDIA_Y16 = 3,
  MEDIA_Y8 = 4,
  MEDIA_Y10 = 5,
  MEDIA_Y12 = 6
} eMediaType;

typedef struct {
  uint8_t Blue; // Stores blue.
  uint8_t Green; // Stores green.
  uint8_t Red; // Stores red.
} RGB24;

enum CameraPin { VideoPin = 0, StillPin };

enum Method { CamDshow = 0, CamMediaFoundation = 1 };

typedef enum tagVideoProcampProperty {
  VideoProcamp_Brightness = 0,
  VideoProcamp_Contrast = (VideoProcamp_Brightness + 1),
  VideoProcamp_Hue = (VideoProcamp_Contrast + 1),
  VideoProcamp_Saturation = (VideoProcamp_Hue + 1),
  VideoProcamp_Sharpness = (VideoProcamp_Saturation + 1),
  VideoProcamp_Gamma = (VideoProcamp_Sharpness + 1),
  VideoProcamp_ColorEnable = (VideoProcamp_Gamma + 1),
  VideoProcamp_WhiteBalance = (VideoProcamp_ColorEnable + 1),
  VideoProcamp_BacklightCompensation = (VideoProcamp_WhiteBalance + 1),
  VideoProcamp_Gain = (VideoProcamp_BacklightCompensation + 1),
  // VideoProcamp_PowerLineFrequency = 13
} VideoProcampProperty;

typedef int (*ptrFrameCB)(char*, long*);

typedef VOID (*FuncptrDeviceStatusCB)(DeviceState* deviceStatus);

typedef int (*FuncptrGetStillFrameCB)(BYTE*, LONG*);

using RecordingStartedCallback = std::function<void(bool)>;

#endif /* CAMSDK_TYPES_H */
