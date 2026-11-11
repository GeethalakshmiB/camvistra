///////////////////////////////////////////////////////////////////////////////
//
//  File      : INetworkDevices.h
//  Library   : libNetworkDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Discovers ONVIF-compatible network cameras on the LAN.
//
//  Usage:
//    auto net = NetworkDeviceEnumeration::createNetworkDeviceEnumerator();
//    net->getAvailableDevices(devs, &count);
//
//

#pragma once

#include <memory>
#include <list>
#include "ILogger.h"
#include "NetworkDeviceEnumeration_Exports.h"

namespace NetworkDeviceEnumeration
{
	/**
	 * @file INetworkDevices.h
	 * @brief Defines the abstract contract for network device enumeration.
	 */

	/**
	 * @class INetworkDevices
	 * @brief Abstract interface for enumerating network-capable devices.
	 */
	class INetworkDevices {
	public:
		/**
		 * @brief Destroys the interface and any derived implementation.
		 */
		virtual ~INetworkDevices() = default;

		/**
		 * @brief Retrieves the available network devices discovered on the local network.
		 * @param deviceList [out] List that receives the detected device details.
		 * @param iDeviceCount [out] Number of devices reported in deviceList.
		 * @return Result code indicating whether discovery succeeded.
		 */
		virtual Result getAvailableDevices(std::list<DeviceDetails>& deviceList,
			int* iDeviceCount) = 0;
	};

	/**
	 * @brief Creates a concrete network device enumerator instance.
	 * @return Unique pointer to the implementation of INetworkDevices.
	 */
	NETWORKDEVICEENUMERATION std::unique_ptr<INetworkDevices> createNetworkDeviceEnumerator();
}
