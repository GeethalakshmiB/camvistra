///////////////////////////////////////////////////////////////////////////////
//
//  File      : NetStreamEnums.h
//  Library   : libNetStreamSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Constants, timeouts and state types for the network streaming SDK.
//
//  Usage:
//    Included by INetStream.h; no functions to call.
//
//

#pragma once

#define ID_NOTIFY 1001
#define ID_CREATE_THREAD 1002
#define ID_DESTROY_THREAD 1003


#ifdef _WIN32
#define SLEEP_DELAY 500
#define TIME_OUT 7000
#elif __linux__
#define TIME_OUT 7000
#define SLEEP_DELAY 500
#define NANOSECOND_IN_SECOND 1000000000
#define MILLISECOND_TO_NANOSECOND 1000000
#define VOID void
#define INT int
#define BYTE uint8_t
#define LONG long
#endif

namespace NetStreamer
{

	/** @brief Image codec and dimensions negotiated for the active stream. */
	typedef struct {
		char Compression[8];
		int width;
		int height;
	} ImageMetadata;


	/** @brief Device states reported through the stream status callback. */
	enum DeviceState {
		Connected ,
		Disconnected ,
		Initiated,
		Started,
		Stopped
	};
	
} // namespace NetStreamer
