///////////////////////////////////////////////////////////////////////////////
//
//  File      : IShelfVistaOnvif.h
//  Library   : libShelfVistaSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    ONVIF client for ShelfVista cameras: device setup, system and
//    network settings, camera and stream configuration.
//
//  Usage:
//    auto cam = ShelfVistaOnvifSDK::getShelfVistaOnvifInstance();
//    cam->initialize(ipAddress);
//    cam->Get...() / cam->Set...()
//
//

#pragma once

#include <list>
#include <memory>
#include "ILogger.h"
#include "ShelfVista_Exports.h"
#include "ShelfVista_Enums.h"

namespace ShelfVistaOnvifSDK  
{  
	class IShelfVistaOnvifClient  
	{  
	public:  
		/** @brief Releases the client through the interface. */
		virtual ~IShelfVistaOnvifClient() = default;

		/** @brief Initializes the client for an ONVIF device. 
           * @param ipAddress Device IP address.
           *  @return Operation result. */
		virtual Result initialize(char* ipAddress) = 0;

		/** @brief Retrieves the RTSP stream URL.
           *  @param rtspURL Output buffer for the URL. 
           * @return Operation result. */
		virtual Result getRTSPStreamURL(char* rtspURL) = 0;

		/** @brief Reboots the device.
           *  @return Operation result. */
		virtual Result systemReboot() = 0;

		/** @brief Reads the access-point configuration.
           *  @param apData Output configuration.
           *  @return Operation result. */
		virtual Result getAPConfig(struct APData *apData) = 0;

		/** @brief Writes the access-point configuration.
           *  @param apData Configuration to apply.
           *  @return Operation result. */
		virtual Result setAPConfig(struct APData *apData) = 0;

		/** @brief Reads the station configuration.
           *  @param staData Output configuration.
           *  @return Operation result. */
		virtual Result getSTAConfig(struct STAData *staData) = 0;

		/** @brief Writes the station configuration.
           *  @param staData Configuration to apply.
           *  @return Operation result. */
		virtual Result setSTAConfig(struct STAData *staData) = 0;

		/** @brief Reads the server configuration.
           *  @param serverData Output configuration.
           *  @return Operation result. */
		virtual Result getServerConfig(struct ServerData *serverData) = 0;

		/** @brief Writes the server configuration.
           *  @param serverData Configuration to apply.
           *  @return Operation result. */
		virtual Result setServerConfig(struct ServerData *serverData) = 0;

		/** @brief Reads timer settings.
           *  @param timerData Output configuration.
           *  @return Operation result. */
		virtual Result getTimerConfig(struct TimerData *timerData) = 0;

		/** @brief Writes timer settings.
           *  @param timerData Configuration to apply.
           *  @return Operation result. */
		virtual Result setTimerConfig(struct TimerData *timerData) = 0;

		/** @brief Retrieves device information.
           *  @param deviceInfo Output information.
           *  @return Operation result. */
		virtual Result getDeviceInformation(struct DeviceInformation* deviceInfo) = 0;

		/** @brief Retrieves battery status.
           *  @param status Output battery status.
           *  @return Operation result. */
		virtual Result getBatteryStatus(struct BatteryStatus *status) = 0;

		/** @brief Writes camera configuration.
           *  @param config Configuration to apply.
           *  @return Operation result. */
		virtual Result setCameraConfig(struct CameraConfig* config) = 0;

		/** @brief Writes snapshot configuration.
           *  @param result Configuration to apply.
           *  @return Operation result. */
		virtual Result setSnapshotConfig(struct SnapshotData* result) = 0;

		/** @brief Retrieves device capabilities.
           *  @param capabilities Output capabilities.
           *  @return Operation result. */
		virtual Result getCapabilities(struct Capabilities* capabilities) = 0;

		/** @brief Starts recording.
           *  @return Operation result. */
		virtual Result startRecording() = 0;

		/** @brief Stops recording. 
           * @return Operation result. */
		virtual Result stopRecording() = 0;

		/** @brief Powers off the device.
           *  @return Operation result. */
		virtual Result systemPowerOff() = 0;

		/** @brief Writes the active resolution.
           *  @param resolution Resolution to apply.
           *  @return Operation result. */
		virtual Result setResolution(struct Resolution* resolution) = 0;

		/** @brief Retrieves supported resolutions.
           *  @param resolutions Output resolution list.
           *  @return Operation result. */
		virtual Result getAvailableResolutions(std::list<Resolution>& resolutions) = 0;

		/** @brief Retrieves the active resolution.
           *  @param resolution Output resolution. 
           * @return Operation result. */
		virtual Result getResolution(struct Resolution* resolution) = 0;

		/** @brief Retrieves camera configuration ranges.
           *  @param config Output ranges.
           *  @return Operation result. */
		virtual Result getCameraConfig(CameraConfigRange* config) = 0;

		/** @brief Updates one camera property.
           *  @param camProperty Property to update.
           *  @param value New value.
           *  @return Operation result. */
		virtual Result setCamConfig(CameraConfigProperty camProperty, int value) = 0;

		/** @brief Ejects the SD card.
           *  @param outMessages Output status message.
           *  @return Operation result. */
		virtual Result ejectSDCard(std::string& outMessages) = 0;

		/** @brief Reads SD-card information.
           *  @param info Output card information.
           *  @return Operation result. */
		virtual Result readSDCardInfo(struct SDCardInfo* info) = 0;

		/** @brief Restores default configuration.
           *  @param defaultValues Defaults to apply.
           *  @return Operation result. */
		virtual Result setDefaultConfiguration(CameraConfigDefaultValues* defaultValues) = 0;

		/** @brief Writes recording configuration.
           *  @param recordConfig Configuration to apply.
           *  @return Operation result. */
		virtual Result setRecordingConfig(RecordingConfig* recordConfig) = 0;

		/** @brief Retrieves recording configuration.
           *  @param recordConfig Output configuration.
           *  @return Operation result. */
		virtual Result getRecordingConfig(RecordingConfig* recordConfig) = 0;

		/** @brief Writes the default resolution.
           *  @param resolution Resolution to apply.
           *  @return Operation result. */
		virtual Result setDefaultResolution(struct Resolution* resolution) = 0;

		/** @brief Retrieves white-balance settings.
           *  @param whiteBalance Output current mode.
           *  @param defaultWb Output default mode.
           *  @return Operation result. */
		virtual Result getWhiteBalance(std::string& whiteBalance, std::string& defaultWb) = 0;

		/** @brief Writes the white-balance mode.
           *  @param whiteBalance Mode to apply.
           *  @return Operation result. */
		virtual Result setWhiteBalance(std::string& whiteBalance) = 0;
          
		/** @brief Retrieves recording status.
           *  @param recordingStatus Output status.
           *  @param outMessage Output message. @return Operation result. */
		virtual Result getRecordingStatus(std::string& recordingStatus, std::string& outMessage) = 0;

		/** @brief Sets the pan position. 
           * @param pan Pan value.
           *  @param outMessage Output status message. 
           * @return Operation result. */
		virtual Result setPan(int pan, std::string& outMessage) = 0;

		/** @brief Sets the tilt position.
           *  @param tilt Tilt value.
           *  @param outMessage Output status message.
           *  @return Operation result. */
		virtual Result setTilt(int tilt, std::string& outMessage) = 0;

		/** @brief Sets the device date and time (manual mode).
           *  @param settings UTC date/time fields, daylight-savings flag and time zone.
           *  @return Operation result. */
		virtual Result setDateTime(struct DateTime* settings) = 0;
	
	};  

	SHELFVISTAONVIFSDK std::unique_ptr<IShelfVistaOnvifClient> getShelfVistaOnvifInstance();
}  
