///////////////////////////////////////////////////////////////////////////////
//
//  File      : IDeviceEnumerator.h
//  Library   : libDeviceEnumerationSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Common enumerator that lists all supported cameras (USB, network,
//    audio, MIPI, GMSL, PCI) through one interface.
//
//  Usage:
//    auto en = DeviceManager::createDeviceEnumerator();
//    std::list<DeviceDetails> devs; int n = 0;
//    en->getAvailableDevices(devs, &n);
//
//

/**
 * @file IDeviceEnumerator.h
 * @brief Declares the common interface used by all device enumerator implementations.
 */

#pragma once

#include <list>
#include <memory>
#include "ILogger.h"  // Result, DeviceDetails (Common_Enums.h / Common_Structs.h)
#include "DeviceEnumeration_Exports.h"

namespace DeviceManager {

/**
 * @brief Abstract interface for all device enumerators.
 *
 * This interface defines the common structure that all device
 * enumeration classes (for example, network, USB, and audio) must follow.
 *
 * Each derived class must implement getAvailableDevices() to discover
 * devices of its respective type.
 */
class IDeviceEnumerator {
public:
    /**
     * @brief Virtual destructor for safe polymorphic cleanup.
     */
    virtual ~IDeviceEnumerator() = default;

    /**
     * @brief Retrieves a list of available devices for this enumerator type.
     *
     * @param deviceList [out] List that will be filled with discovered device details.
     * @param deviceCount [out] Number of devices found.
     * @return Result::SUCCESS if successful, otherwise an appropriate error code.
     */
    virtual Result getAvailableDevices(std::list<DeviceDetails>& deviceList,
                                       int* deviceCount) = 0;
};

/**
 * @brief Alias for a unique pointer to an enumerator implementation.
 */
using IDeviceEnumeratorPtr = std::unique_ptr<IDeviceEnumerator>;

/**
 * @brief Creates the enumerator that aggregates network, USB, and audio devices.
 *
 * getAvailableDevices() on the returned instance lists network devices first,
 * then USB, then audio. It returns Result::Ok when at least one device type
 * enumerated successfully and the total count is greater than zero.
 *
 * @return Owning pointer to the enumerator implementation.
 */
DEVICEENUMERATION IDeviceEnumeratorPtr createDeviceEnumerator();

} // namespace DeviceManager
