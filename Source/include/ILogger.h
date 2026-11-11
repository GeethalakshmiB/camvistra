///////////////////////////////////////////////////////////////////////////////
//
//  File      : ILogger.h
//  Library   : libLogger.so
//  Author    : e-con Systems
//
//  Copyright (C) 2026 e-con Systems. All rights reserved.
//
//  Purpose:
//    Logging interface shared by all e-con SDK libraries.
//
//  Usage:
//    logSDK::ILogger* log = logSDK::createLoggerInstance();
//    log->setLogCallback([](int prio, const std::string& msg) { ... });
//    log->writeLog(DEBUG_INFO, "message");
//
//

#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <functional>
#include "Common_Enums.h"
#include "Common_Structs.h"

/**
 * @brief Log priority level used for informational messages.
 */
#define DEBUG_INFO 0
/**
 * @brief Log priority level used for verbose diagnostic messages.
 */
#define DEBUG_VERBOSE 1
/**
 * @brief Log priority level used for critical messages.
 */
#define DEBUG_CRITICAL 2

namespace logSDK {

/**
 * @file ILogger.h
 * @brief Defines the core logging interface exposed by the Logger library.
 */

/**
 * @brief Abstract interface for logger implementations.
 */
	class ILogger {
	public:
		/**
		 * @brief Registers the callback used to receive log records.
		 * @param callback Function invoked with the log priority and message text.
		 * @return Result value indicating whether the callback registration succeeded.
		 */
		virtual Result setLogCallback(const std::function<void(int, const std::string&)>& callback) = 0;

		/**
		 * @brief Writes a log entry with the specified priority.
		 * @param logPriority Severity level for the entry.
		 * @param message Message content to store or forward.
		 * @return Result value describing the outcome of the operation.
		 */
		virtual Result writeLog(int logPriority, const std::string& message) = 0;
	};

	/**
	 * @brief Creates the default logger instance.
	 * @return Pointer to the logger implementation.
	 */
	ILogger* createLoggerInstance();

} // namespace logSDK

#endif // LOGGER_HPP
