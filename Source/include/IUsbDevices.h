///////////////////////////////////////////////////////////////////////////////
//
//  File      : IUsbDevices.h
//  Library   : libUsbDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Lists the e-con USB (UVC) cameras connected to the host.
//
//  Usage:
//    auto usb = UsbDeviceEnumeration::createUsbDeviceEnumerator();
//    usb->getAvailableDevices(devs, &count);
//
//

#ifndef IUSBDEVICES_H
#define IUSBDEVICES_H

#include <memory>
#include <list>
#include "ILogger.h"
#include "UsbDeviceEnumeration_Exports.h"

namespace UsbDeviceEnumeration
{
	/**
	 * @brief Defines the interface for enumerating USB devices.
	 */
	class IUsbDevices {
	public:
		/**
		 * @brief Destroys the interface and derived implementations.
		 */
		virtual ~IUsbDevices() {}

		/**
		 * @brief Enumerates all currently available USB devices.
		 * @param deviceList [out] List that receives the discovered device details.
		 * @param iDeviceCount [out] Number of devices returned in the list.
		 * @return Result code indicating the outcome of the enumeration.
		 */
		virtual Result getAvailableDevices(std::list<DeviceDetails>& deviceList, int* iDeviceCount) = 0;
	};

	/**
	 * @brief Creates an instance of the USB device enumerator implementation.
	 * @return Pointer to a concrete enumerator implementation.
	 */
	USBDEVICEENUMERATION std::unique_ptr<IUsbDevices> createUsbDeviceEnumerator();
}

#endif  // IUSBDEVICES_H
