///////////////////////////////////////////////////////////////////////////////
//
//  File      : IRoutecamOnvif.h
//  Library   : libRoutecamSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    ONVIF client for Routecam network cameras: device info, network
//    and NTP settings, image/quality properties, profiles, stream URI.
//
//  Usage:
//    auto cam = RoutecamOnvifSDK::getRoutecamOnvifInstance();
//    cam->initialize(ipAddress);
//    cam->GetStreamUri(ipAddress, uri);  cam->Get...() / Set...()
//
//

/**
 * @file IRoutecamOnvif.h
 * @brief Declares the abstract interface for the Routecam ONVIF client.
 */

#pragma once

#include <list>
#include <memory>
#include <map>
#include <string>
#include <vector>
#include "ILogger.h"
#include "Routecam_Exports.h"
#include "Routecam_Enums.h"

namespace RoutecamOnvifSDK
{
	/**
	 * @class IRoutecamOnvifClient
	 * @brief Abstract API used to configure and query an ONVIF-compliant Routecam device.
	 */
	class IRoutecamOnvifClient
	{
	public:
		/**
		 * @brief Destroys the interface and any derived implementation.
		 */
		virtual ~IRoutecamOnvifClient() = default;

		/**
		 * @brief Initializes the ONVIF client with the target IP address.
		 * @param ipAddress Camera IP address used for subsequent requests.
		 * @return Result code indicating the initialization status.
		 */
		virtual Result initialize(char* ipAddress) = 0;

		/**
		 * @brief Retrieves image properties and optional bitrate ranges from the camera.
		 * @param imageProperties [out] Available image properties for the device.
		 * @param bitrateRanges [out] Optional bitrate constraints keyed by encoding type.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetImageProperty(
			std::list<ImageProperty>& imageProperties,
			std::map<std::string, QualitySettingsRange>* bitrateRanges = nullptr) = 0;

		/**
		 * @brief Reads the supported range for a quality setting from the camera.
		 * @param setting Quality setting to inspect.
		 * @param range [out] Range details returned by the device.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetQualityContolProperty(QualitySettings setting, QualitySettingsRange* range) = 0;

		/**
		 * @brief Reads the current imaging settings from the device.
		 * @param imgProp [out] Current image property values.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetCurrentImageProperty(ImageProperty* imgProp) = 0;

		/**
		 * @brief Reads the valid range and current value for a camera control property.
		 * @param gControlID Identifier of the camera property.
		 * @param gControlValue [out] Range and current state for the property.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetCameraControlProperty(CameraProperty gControlID, PropertyRange* gControlValue) = 0;

		/**
		 * @brief Reads the device identity information reported by the camera.
		 * @param deviceInfo [out] Device metadata structure.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetDeviceInformation(DeviceInfo* deviceInfo) = 0;

		/**
		 * @brief Reads the current network interface details from the device.
		 * @param netInterface [out] Network interface configuration.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetNetworkInterfaceDetails(NetworkInterface* netInterface) = 0;

		/**
		 * @brief Reads the configured NTP server address.
		 * @param ntpIp [out] NTP server IP string.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetNTP(std::string& ntpIp) = 0;

		/**
		 * @brief Reads the profile list and active profile information.
		 * @param allProfiles [out] Available profiles on the camera.
		 * @param currentProfile [out] Active profile name.
		 * @param currentFormat [out] Active media format.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetConfigProfile(std::vector<std::string>& allProfiles, std::string& currentProfile, std::string& currentFormat) = 0;

		/**
		 * @brief Updates the NTP server value on the device.
		 * @param ntpIp NTP server IP to configure.
		 * @return Result code describing the request outcome.
		 */
		virtual Result SetNTP(std::string& ntpIp) = 0;

		/**
		 * @brief Applies a new image configuration to the device.
		 * @param imgProp Camera image settings to write.
		 * @return Result code describing the request outcome.
		 */
		virtual Result SetCurrentImageProperty(ImageProperty* imgProp) = 0;

		/**
		 * @brief Applies a network interface configuration to the camera.
		 * @param netInterface Network interface settings to apply.
		 * @return Result code describing the request outcome.
		 */
		virtual Result SetNetworkInterfaceDetails(NetworkInterface* netInterface) = 0;

		/**
		 * @brief Selects the active profile on the device.
		 * @param currentProfile Profile name to activate.
		 * @return Result code describing the request outcome.
		 */
		virtual Result SetConfigProfile(std::string& currentProfile) = 0;

		/**
		 * @brief Sets a camera control property to a new value.
		 * @param gControlID Property identifier to update.
		 * @param currentValue New property value to apply.
		 * @return Result code describing the request outcome.
		 */
		virtual Result SetCameraControlProperty(CameraProperty gControlID, const std::string& currentValue) = 0;

		/**
		 * @brief Sets a quality control value on the camera.
		 * @param setting Quality setting to update.
		 * @param newValue New numeric value to apply.
		 * @return Result code describing the request outcome.
		 */
		virtual Result SetQualityControlProperty(QualitySettings setting, int newValue) = 0;

		/**
		 * @brief Applies the current quality parameter configuration to the camera.
		 * @return Result code describing the request outcome.
		 */
		virtual Result SetQualityParameters() = 0;

		/**
		 * @brief Applies a default camera configuration.
		 * @param defaultValues Default values to set on the device.
		 * @return Result code describing the request outcome.
		 */
		virtual Result setDefaultConfiguration(CameraConfigDefault* defaultValues) = 0;

		/**
		 * @brief Retrieves the stream URI for the target camera.
		 * @param ipAddress Camera IP address for the stream request.
		 * @param outUri [out] Stream URI returned by the device.
		 * @return Result code describing the request outcome.
		 */
		virtual Result GetStreamUri(const char* ipAddress, std::string& outUri) = 0;
	};

	/**
	 * @brief Creates an ONVIF Routecam client instance.
	 * @return Unique pointer to the concrete Routecam client implementation.
	 */
	ROUTECAMONVIFSDK std::unique_ptr<IRoutecamOnvifClient> getRoutecamOnvifInstance();
}
