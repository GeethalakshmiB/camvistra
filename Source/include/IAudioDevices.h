///////////////////////////////////////////////////////////////////////////////
//
//  File      : IAudioDevices.h
//  Library   : libAudioDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Lists the audio capture devices (camera microphones) on the host.
//
//  Usage:
//    auto aud = AudioDeviceEnumeration::createAudioDeviceEnumerator();
//    aud->getAvailableDevices(devs, &count);
//
//

#ifndef IAUDIODEVICES_H
#define IAUDIODEVICES_H

#include <memory>
#include <list>
#include "ILogger.h"
#include "AudioDeviceEnumeration_Exports.h"

namespace AudioDeviceEnumeration
{
	/**
	 * @file IAudioDevices.h
	 * @brief Declares the abstract interface for audio device enumeration.
	 */

	/**
	 * @class IAudioDevices
	 * @brief Abstract interface for audio device enumeration.
	 */
	class IAudioDevices
	{
	public:
		/**
		 * @brief Destroys the interface and any derived implementation.
		 */
		virtual ~IAudioDevices() = default;

		/**
		 * @brief Retrieve all active audio endpoints (capture + render).
		 *
		 * Fills the following DeviceDetails fields:
		 *   - deviceIndex  : zero-based position in the returned list
		 *   - DeviceName   : PKEY_Device_FriendlyName (UTF-8)
		 *   - devicePath   : MMDevice endpoint ID string (UTF-8)
		 *   - type         : "Capture" or "Render"
		 *   - vid / pid    : populated only for USB UAC endpoints
		 *
		 * Fields not applicable to audio (DeviceIP, serialNo) are left empty.
		 *
		 * @param deviceList  [out] Populated with one entry per active endpoint.
		 * @param deviceCount [out] Number of devices found.
		 * @return Result::SUCCESS or an appropriate error code.
		 */
		virtual Result getAvailableDevices(std::list<DeviceDetails>& deviceList,
			int* deviceCount) = 0;
	};

	/**
	 * @brief Creates a concrete audio device enumerator instance.
	 * @return Unique pointer to the implementation of the audio device enumerator.
	 */
	AUDIODEVICEENUMERATION std::unique_ptr<IAudioDevices> createAudioDeviceEnumerator();

}  // namespace AudioDeviceEnumeration

#endif  // IAUDIODEVICES_H
