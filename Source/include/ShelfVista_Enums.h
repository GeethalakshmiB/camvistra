///////////////////////////////////////////////////////////////////////////////
//
//  File      : ShelfVista_Enums.h
//  Library   : libShelfVistaSDK.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Data structures (date/time, network, image settings, ...) used by
//    the ShelfVista ONVIF API.
//
//  Usage:
//    Included by IShelfVistaOnvif.h; no functions to call.
//
//

#pragma once
#define MAX_PATH 260

#define BYTE uint8_t
#include <array>
#include <string>
#include <map>
#include <vector>

// Structure to store date and time settings for an Onvif-compliant device.
struct DateTime {
	char hour[100];            // Stores the hour component of the time (in 24-hour format).
	char minute[100];          // Stores the minute component of the time.
	char second[100];          // Stores the second component of the time.
	char year[100];            // Stores the year component of the date.
	char month[100];           // Stores the month component of the date.
	char day[100];             // Stores the day component of the date.
	bool daylightSavings;      // Boolean flag to indicate whether daylight savings is enabled.
	char timeZone[100];        // Stores the time zone information (e.g., "UTC+5:30").
};


// Structure to store Device information Onvif-compliant device.
struct DeviceInformation {
	char manufacturer[128];      // Manufacturer of the device
	char model[128];             // Model of the device
	char firmwareVersion[128];   // Firmware version of the device
	char serialNumber[128];      // Serial number of the device
	char hardwareId[128];        // Hardware ID of the device
	char last_error[256];        // To store any error messages
};

// Structure to store STA Data Onvif-compliant device.
struct STAData {
	char SSID[128];        // Wi-Fi SSID
	char password[128];    // Wi-Fi Password
	char ipConfig[32];     // IP Configuration (e.g., DHCP, Static)
	char ipAddress[32];    // Static IP Address
	char subnetMask[32];   // Subnet Mask
	char gateway[32];      // Default Gateway
	char primaryDNS[32];   // Primary DNS Server
};

// Structure to store AP Data Onvif-compliant device.
struct APData {
	char SSID[128];          // WiFi SSID (Network Name)
	char password[128];      // WiFi Password
	char securityMode[32];   // Security Mode (e.g., WPA2, WPA3, etc.)
	int band;                // WiFi Band (e.g., 2.4 GHz or 5 GHz)
	int channel;			// Channel
};

// Structure to represent time in hours, minutes, and seconds.
struct Time {
	int hours;    // Hour component of the time (0-23).
	int minutes;  // Minute component of the time (0-59).
	int seconds;  // Second component of the time (0-59).
};

// Structure to store timer-related configuration data.
struct TimerData {
	Time startTime;  // Start time for the timer (hours, minutes, seconds).
	Time endTime;    // End time for the timer (hours, minutes, seconds).
	Time duration;   // Duration time (how long the timer runs) in hours, minutes, and seconds.
	int imageType;   // Image type identifier (integer value representing different image formats or purposes).
};

// Structure to store local server configuration data.
struct LocalConfig {
	std::array <char, 256> IP; // IP address of the local server.
	int Port;                 // Port number used to communicate with the local server.
};

// Structure to store cloud server configuration data.
struct CloudConfig {
	std::array <char, 256> AccountName; // Name of the cloud account.
	std::array <char, 256> AccountType; // Type of cloud account (e.g., "HMAC", "ServiceAccount").
	std::array <char, 256> Provider; // Name of the cloud service provider (e.g., AWS, Azure).
	std::array <char, 256> AccessKey; // Access key for authentication with the cloud provider.
	std::array <char, 256> SecretKey; // Secret key for secure access to the cloud.
	std::array <char, 256> Region; // Cloud region (e.g., "	us-west-1").
	std::array <char, 256> BucketName; // Name of the storage bucket used.
	std::array <char, 256> BucketNameHMAC; // Name of the storage bucket used with HMAC credentials.
	std::array <char, 256> BucketNameSA; // Name of the storage bucket used with service account credentials.
	std::array <char, 256> ServiceAccountJsonFileName; // File name of the service account JSON file.
	std::array <char, 4096> ServiceAccountJsonFile; // Full contents of the service account JSON key file.
	std::array <char, 256> AzureAccountName;
	std::array <char, 256> AzureContainerName;
	std::array <char, 256> AzureAccountKey;
};

// Structure to store server-related configuration settings.
struct ServerData {
	bool mode;                // Mode selection: false = Local, true = Cloud.
	LocalConfig localConfig;  // Configuration for local server settings.
	CloudConfig cloudConfig;  // Configuration for cloud server settings.
};

// Structure to store camera configuration settings.
struct CameraConfig {
	int qFactor;            // Image quality factor (e.g., JPEG compression ratio).
	int antibanding;        // Anti-banding setting to reduce flickering (e.g., 50Hz or 60Hz).
};

// Structure to store battery status information.
struct BatteryStatus {
	char batteryStatus[128];   // Battery status as a string (e.g., "85%" for percentage).
	char chargingStatus[128];  // Charging status, describing if the battery is charging or its health (e.g., "Charging" or "Good").
};

 struct SnapshotData {
	std::vector<uint8_t> bufferData;  // snapshot bytes   
 	long bufferDataSize;  // Size of the buffer
 	int imageType;        // 1 = JPG, 0 = RAW, -1 = error
 };


/** @brief Feature flags reported by the ShelfVista device. */
struct Capabilities {
	bool HMAC;
	bool ServiceAccount;
	bool Azure; // To check whether the device supports Azure server configuration
	bool SASToken;
	bool OEM;
	bool Brightness;
	bool Contrast;
	bool ExposureMode;
	bool Pan;
	bool FPS;
	bool Sharpness;
	bool Saturation;
	bool WhiteBalanceMode;
	bool Tilt;
	bool Zoom;
	bool Trigger;
	bool BatteryStatus;
};


/** @brief Image resolution represented by width and height in pixels. */
struct Resolution {
	int width = 0;
	int height = 0;
};

/** @brief Camera property identifiers accepted by the configuration APIs. */
enum CameraConfigProperty {
	Brightness,
	Contrast,
	FrameRate,
	Saturation,
	Sharpness,
	ExposureMode,
	Exposure,
	Gain,
	Zoom,
	WBMode,
	AntiBanding,
	QFactor
}; 

/** @brief Minimum, maximum, current, and default values for a camera property. */
struct Range {
	int min;
	int max;
	int current;
	int defaultValue;
};

/** @brief Range values indexed by camera property identifier. */
struct CameraConfigRange {
	std::map<CameraConfigProperty, Range> property;
};

/** @brief SD-card capacity, state, and device message. */
struct SDCardInfo {
	char totlGB[128];
	char freeGb[128];
	char usedGb[128];
	char status[128];
	char Message[128];
};

/** @brief Recording enablement and event-duration settings. */
struct RecordingConfig {
	int recordingDuration = 0;
	bool isCircularRecordingEnable = false;
	bool isEventRecordingEnable = false;
	int preEventDuration = 0;
	int postEventDuration = 0;
};

/** @brief Default camera property values applied during initialization. */
struct CameraConfigDefaultValues {
	std::map<CameraConfigProperty, int> defaultCameraConfigValues;
};