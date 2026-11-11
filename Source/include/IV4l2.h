///////////////////////////////////////////////////////////////////////////////
//
//  File      : IV4l2.h
//  Library   : libCAMSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Linux V4L2 streaming backend: open a camera, choose a format, grab
//    frames, record video, adjust UVC controls and camera audio.
//
//  Usage:
//    auto v4l2 = eCamSDK::createCamV4l2Instance();
//    v4l2->OpenCamera("/dev/video0");
//    v4l2->SetImageProperty(&prop);  v4l2->GetFrame(&frame);
//    v4l2->CloseCamera();
//
//

/** @file IV4l2.h @brief Declares the Linux V4L2 camera backend interface. */
#ifndef IV4L2_H
#define IV4L2_H

#include <string>
#include <memory>
#include "CAMSDK_types.h"

namespace eCamSDK {

class IV4L2 {
 public:
  /** @brief Releases the backend interface. */
  virtual ~IV4L2() = default;

  /** @brief Opens a video source. @param Source Source path or URI. @return Operation result. */
  virtual Result OpenCamera(const char* Source) = 0;

  /** @brief Registers a device-status callback. @param fp Callback function. @return Operation result. */
  virtual Result DeviceStatusCallback(FuncptrDeviceStatusCB fp) = 0;

  //virtual INT SetStillframecallback(FuncptrGetStillFrameCB cb) = 0;

  //virtual INT CaptureStillFrame() = 0;

  /** @brief Retrieves a frame. @param frames Output frame. @return Operation result. */
  virtual Result GetFrame(Frame* frames) = 0;

  /** @brief Retrieves supported image properties. @param imageProperties Output list. @return Operation result. */
  virtual Result GetImageProperty(std::list<ImageProperty>& imageProperties) = 0;

  /** @brief Applies an image property. @param Img_Prop Property to apply. @return Operation result. */
  virtual Result SetImageProperty(ImageProperty* Img_Prop) = 0;

  /** @brief Retrieves the current image property. @param Img_Prop Output property. @return Operation result. */
  virtual Result GetCurrentImageProperty(ImageProperty* Img_Prop) = 0;

  /** @brief Retrieves a camera-control range. @param gControlID Control identifier. @param gControlValue Output range. @return Operation result. */
  virtual Result GetCameraControlProperty(UsbCameraProperty gControlID, PropertyRange* gControlValue) = 0;

  /** @brief Sets a camera-control value. @param camProperty Control identifier. @param lPropVal Value to apply. @return Operation result. */
  virtual Result SetCameraControlProperty(UsbCameraProperty camProperty, int lPropVal) = 0;

  // virtual INT DeinitCapture() = 0;

  /** @brief Closes the camera device. @return Operation result. */
  virtual Result CloseCamera() = 0;

  /** @brief Retrieves the current frame rate. @param fps Output frame rate. @return Operation result. */
  virtual Result GetFramesPerSecond(int* fps) = 0;

  /** @brief Starts recording. @param filename Output path. @return Operation result. */
  virtual Result StartRecording(const char* filename) = 0;

  /** @brief Stops recording. @return Operation result. */
  virtual Result StopRecording() = 0;

  /** @brief Retrieves get file descriptor. */
  virtual Result GetFileDescriptor(int* fileDesc) = 0;

  /** @brief Sets set default configuration. */
  virtual Result setDefaultConfiguration(CameraControlDefaultValues* defaultValues) = 0;

  /** @brief Registers a recording-state callback. @param callback Callback function. */
  virtual void SetRecordingStartedCallback(RecordingStartedCallback callback) = 0;

  /** @brief Opens an audio device by index. @param deviceIndex Device index. @return Operation result. */
  virtual Result OpenAudioDevice(int deviceIndex) = 0;

  /** @brief Opens an audio device by path. @param devicePath Device path. @return Operation result. */
  virtual Result OpenAudioDevice(const char* devicePath) = 0;

  /** @brief Closes the audio device. @return Operation result. */
  virtual Result CloseAudioDevice() = 0;

  /** @brief Retrieves the audio range. @param Audio_prop Output range. @return Operation result. */
  virtual Result GetAudioRange(float* Audio_prop) = 0;

  /** @brief Sets the audio level. @param value Level to apply. @return Operation result. */
  virtual Result SetAudioRange(float value) = 0;

  /** @brief Retrieves mute state. @param muteFlag Output mute flag. @return Operation result. */
  virtual Result GetMute(bool* muteFlag) = 0;

  /** @brief Sets mute state. @param muteflag Mute flag to apply. @return Operation result. */
  virtual Result SetMute(bool muteflag) = 0;
};

/** @brief Creates a Linux V4L2 backend instance. @return Owning backend pointer. */
std::unique_ptr<IV4L2> createCamV4l2Instance();

}  // namespace eCamSDK

#endif  // IV4L2_H
