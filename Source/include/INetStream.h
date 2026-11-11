///////////////////////////////////////////////////////////////////////////////
//
//  File      : INetStream.h
//  Library   : libNetStreamSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    RTSP/network stream player: open a stream, grab decoded frames,
//    read fps/format and record to file.
//
//  Usage:
//    auto s = NetStreamer::NetStreamingInfoInstance();
//    s->OpenCamera("rtsp://...");  s->GetFrame(&frame);
//    s->startVideoRecording("out.mp4");  s->close();
//
//

#ifndef NETSTREAM_H
#define NETSTREAM_H

#ifdef _WIN32
#include "ObjBase.h"
#elif __linux__
#include <cstdint>
#endif

#include <vector>
#include <memory>
#include <functional>
#include "NetStreamExport.h"
#include "NetStreamEnums.h"
#include "ILogger.h"
using namespace std;

namespace NetStreamer
{

	typedef std::function<int(DeviceState*)> FpDeviceStatusCB;
	typedef std::function<void(bool)> RecordingStartedCallback;
	typedef VOID(*Fp_GetFrame_CB)(BYTE* buf_data, LONG buf_size);

    class NetStreamingInfo
    {		
	public:
	   /** @brief Releases the streaming interface. */
	   virtual ~NetStreamingInfo() = default;
	   /** @brief Opens a camera or stream source. @param Source Source URI or device path. @return Operation result. */
	   virtual Result OpenCamera(const char* Source) = 0;
	   /** @brief Closes the active stream and releases resources. @return Operation result. */
	   virtual Result close()=0;
	   /** @brief Retrieves the next decoded frame. @param recvFrames Output frame structure. @return Operation result. */
	   virtual Result GetFrame(Frame* recvFrames) = 0;
	   /** @brief Registers a device-status callback. @param fpDeviceStatus Callback function. @return Operation result. */
	   virtual Result registerStateCallback(FpDeviceStatusCB fpDeviceStatus) = 0;
	   /** @brief Retrieves the current frame rate. @param fps Output frame rate. @return Operation result. */
	   virtual Result getCurrentFramerate(double* fps) = 0;
	   /** @brief Retrieves the current stream format. @param imgProp Output image metadata. @return Operation result. */
	   virtual Result getCurrentStreamFormat(ImageMetadata* imgProp) = 0;
	   /** @brief Starts recording to a file. @param filename Recording output path. @return Operation result. */
	   virtual Result startVideoRecording(const std::string filename) = 0;
	   /** @brief Stops the active recording. @return Operation result. */
	   virtual Result stopRecording() = 0;
	   /** @brief Registers a recording-state callback. @param callback Callback invoked on state changes. */
	   virtual void SetRecordingStartedCallback(RecordingStartedCallback callback) = 0;
	   /** @brief Requests stream shutdown and wakes worker threads. */
	   virtual void requestStop() {}
    };
	NETSTREAM_API std::unique_ptr<NetStreamingInfo> NetStreamingInfoInstance();  // Returns an instance of a class implementing NetStreamingInfo.  
} // namespace NetStreamer

#endif
