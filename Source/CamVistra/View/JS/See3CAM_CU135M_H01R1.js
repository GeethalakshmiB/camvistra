var see3camcu135mHidProperty = [];
var isUvcExposureAuto = false;
var aeWindowSize = 0
var isVerticalFlip = false
var isHorizontalFlip = false

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To store the HID settings JSON model (array of control
//					groups) loaded by UsbcamHidSettings.qml in the module-
//					level see3camcu135mHidProperty array.
//
//	ARGUMENTS	:	jsonArray - Array of control group objects parsed from the
//					  camera's HID settings JSON
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camcu135mHidProperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the current HID settings model so the QML view
//					can render the controls.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the see3camcu135mHidProperty model array
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return see3camcu135mHidProperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	callSupportFunctions()
//
//  PURPOSE		:	To re-apply the enable/disable state of exposure-dependent
//					controls from the cached UVC auto exposure flag and push
//					the result to the UI. Called after the firmware version is
//					received.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function callSupportFunctions() {
    var changedFields = handleOnExposureModeChange(isUvcExposureAuto);
    triggerUpdateSignal(changedFields)
}
// ----------------------------------------------------------------
// Get all camera controls on initialization
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To read the anti-flicker mode from the camera and start
//					the QML delayedControlsTimer, which then calls
//					getDelayedCameraControls().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getCameraControls() {
    // Trigger the QML timer for delayed controls
    see3camcu135mh01r1Controller.getAntiFlickerMode()
    delayedControlsTimer.start()
}

// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To request the HID control values from the camera through
//					see3camcu135mh01r1Controller (flash state, stream mode,
//					flip, gain mode and limits, black level, target
//					brightness, exposure mode, anti-flicker, AE ROI, exposure
//					limits, statistics, serial number, firmware). Results
//					arrive through controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    see3camcu135mh01r1Controller.getFlashState()
    see3camcu135mh01r1Controller.getStreamMode()
    see3camcu135mh01r1Controller.getFlipCtrlValue()
    see3camcu135mh01r1Controller.getGainMode()
    see3camcu135mh01r1Controller.getGainLimit()
    see3camcu135mh01r1Controller.getBlackLevelAdjustment()
    see3camcu135mh01r1Controller.getTargetBrightness()
    see3camcu135mh01r1Controller.getExposureMode()
    see3camcu135mh01r1Controller.getAntiFlickerMode()
    see3camcu135mh01r1Controller.getAutoExpROIModeAndWindowSize()
    see3camcu135mh01r1Controller.getExposureLowerLimit()
    see3camcu135mh01r1Controller.getExposureUpperLimit()
    see3camcu135mh01r1Controller.readStatistics()
    see3camcu135mh01r1Controller.get64BitSerialNumber()
    see3camcu135mh01r1Controller.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached module state (UVC auto exposure flag,
//					AE window size, flip flags) to defaults. The model array
//					is kept.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    isUvcExposureAuto = false;
    aeWindowSize = 0
    isVerticalFlip = false
    isHorizontalFlip = false
}

// Firmware Version
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFirmwareVersioninUI(firmwareVersion)
//
//  PURPOSE		:	To show the firmware version read from the camera in the
//					"firmwareVer" field.
//
//	ARGUMENTS	:	firmwareVersion - firmware version string
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFirmwareVersioninUI(firmwareVersion) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "firmwareVersion" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "firmwareVer") {
                    child.text = firmwareVersion.toString()
                    changedFields.push({ id: child.id, text: child.text })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// Serial Number
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSerialNumber(serialNum)
//
//  PURPOSE		:	To show the serial number read from the camera in the
//					"serialNumber" field.
//
//	ARGUMENTS	:	serialNum - serial number
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSerialNumber(serialNum) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "serialNum" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "serialNumber") {
                    child.text = serialNum.toString()
                    changedFields.push({ id: child.id, text: child.text })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// Flash Mode
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlashMode(flashMode)
//
//  PURPOSE		:	To check the Off, Strobe or Torch radio in the "flashMode"
//					group to match the flash state reported by the camera
//					(others are unchecked).
//
//	ARGUMENTS	:	flashMode - See3CAMCU135M_H01R1.FLASHMODE_OFF,
//					  FLASHMODE_STROBE or FLASHMODE_TORCH
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFlashMode(flashMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "flashMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (flashMode === See3CAMCU135M_H01R1.FLASHMODE_OFF && child.id === "disableFlashMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (flashMode === See3CAMCU135M_H01R1.FLASHMODE_STROBE && child.id === "strobeMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (flashMode === See3CAMCU135M_H01R1.FLASHMODE_TORCH && child.id === "torchMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else {
                    child.checked = false
                }
            }
            break
        }
    }
    return changedFields
}

// Stream Mode
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStreamMode(streamMode)
//
//  PURPOSE		:	To check the Master or Trigger radio in the "streamMode"
//					group to match the stream mode reported by the camera.
//
//	ARGUMENTS	:	streamMode - See3CAMCU135M_H01R1.MODE_MASTER or
//					  MODE_TRIGGER
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateStreamMode(streamMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "streamMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (streamMode === See3CAMCU135M_H01R1.MODE_MASTER && child.id === "masterMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (streamMode === See3CAMCU135M_H01R1.MODE_TRIGGER && child.id === "triggerMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else {
                    child.checked = false
                }
            }
            break
        }
    }
    return changedFields
}

//Update statistics
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStatistics(exposureUs, gainValue)
//
//  PURPOSE		:	To show the exposure and gain statistics read from the
//					camera in the "exposure" and "gain" fields of the
//					"statisticsData" group.
//
//	ARGUMENTS	:	exposureUs - current exposure time in microseconds
//					gainValue - current gain
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateStatistics(exposureUs, gainValue) {
    var changedFields = []

    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]

        if (group.id === "statisticsData" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "exposure") {
                    child.text = exposureUs.toString()
                    changedFields.push({ id: child.id, text: child.text })
                } else if (child.id === "gain") {
                    child.text = gainValue.toString()
                    changedFields.push({ id: child.id, text: child.text })
                }
            }
            break
        }
    }

    return changedFields
}

// Flip Mode
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlipMode(flipValue)
//
//  PURPOSE		:	To check the Horizontal/Vertical flip check boxes from the
//					reported flip value and cache them in
//					isHorizontalFlip/isVerticalFlip for later
//					setFlipCtrlValue() calls.
//
//	ARGUMENTS	:	flipValue - See3CAMCU135M_H01R1.FLIP_HORIZONTAL,
//					  FLIP_VERTICAL or FLIP_BOTH; anything else means no flip
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFlipMode(flipValue) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horizontal") {
                    child.checked = (flipValue === See3CAMCU135M_H01R1.FLIP_HORIZONTAL || flipValue === See3CAMCU135M_H01R1.FLIP_BOTH)
                    isHorizontalFlip = child.checked
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "vertical") {
                    child.checked = (flipValue === See3CAMCU135M_H01R1.FLIP_VERTICAL || flipValue === See3CAMCU135M_H01R1.FLIP_BOTH)
                    isVerticalFlip = child.checked
                    changedFields.push({ id: child.id, checked: child.checked })
                }
            }
            break
        }
    }
    return changedFields
}

// ROI Auto Exposure
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRoiAEMode(roiMode, winSize)
//
//  PURPOSE		:	To update the "roiAE" group: check the Full or Manual
//					radio, enable the "manualAE" window-size dropdown only in
//					manual mode and select the reported window size.
//
//	ARGUMENTS	:	roiMode - See3CAMCU135M_H01R1.AE_Full or AE_Manual
//					winSize - AE ROI window size
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateRoiAEMode(roiMode, winSize) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "roiAE" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "fullROIAE") {
                    child.checked = (roiMode === See3CAMCU135M_H01R1.AE_Full)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualROIAE") {
                    child.checked = (roiMode === See3CAMCU135M_H01R1.AE_Manual)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualAE") {
                    child.enabled = (roiMode === See3CAMCU135M_H01R1.AE_Manual)
                    child.selected = winSize
                    child.currentValue = winSize
                    changedFields.push({ id: child.id, currentValue: child.currentValue, selected: child.selected, enabled: child.enabled })
                }
            }
            break
        }
    }
    return changedFields
}

// Black Level Adjustment
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBlackLevelAdjustment(blacklevel)
//
//  PURPOSE		:	To check the Enable or Disable radio in the
//					"blackLightCompensation" group to match the black level
//					adjustment state reported by the camera.
//
//	ARGUMENTS	:	blacklevel - See3CAMCU135M_H01R1.ENABLE or DISABLE
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateBlackLevelAdjustment(blacklevel) {
    var changedFields = []
    // Black level maps to BLC radio buttons: 0 = disable, 1 = enable
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "blackLightCompensation" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (blacklevel === See3CAMCU135M_H01R1.DISABLE && child.id === "disableBlc") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (blacklevel === See3CAMCU135M_H01R1.ENABLE && child.id === "enableBlc") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else {
                    child.checked = false
                }
            }
            break
        }
    }
    return changedFields
}

// Target Brightness
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTargetBrightness(brightness)
//
//  PURPOSE		:	To set the "brightness" slider in the "targetBrightness"
//					group to the target brightness read from the camera.
//
//	ARGUMENTS	:	brightness - target brightness value
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateTargetBrightness(brightness) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "targetBrightness" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "brightness") {
                    child.currentValue = brightness
                    changedFields.push({ id: child.id, currentValue: child.currentValue })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// Anti-Flicker Mode
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAntiFlickerMode(antiFlicker)
//
//  PURPOSE		:	To check the Disable, 50 Hz or 60 Hz radio in the
//					"antiFlicker" group to match the anti-flicker mode
//					reported by the camera.
//
//	ARGUMENTS	:	antiFlicker - See3CAMCU135M_H01R1.MODE_DISABLE, MODE_50Hz
//					  or MODE_60Hz
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAntiFlickerMode(antiFlicker) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (antiFlicker === See3CAMCU135M_H01R1.MODE_DISABLE && child.id === "disableMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (antiFlicker === See3CAMCU135M_H01R1.MODE_50Hz && child.id === "50HzMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (antiFlicker === See3CAMCU135M_H01R1.MODE_60Hz && child.id === "60HzMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else {
                    child.checked = false
                }
            }
            break
        }
    }
    return changedFields
}

// Gain Mode
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGainMode(gainMode, autoGainMode, gainValue)
//
//  PURPOSE		:	To update the "gainControl" group: check Auto/Manual gain,
//					enable the auto fields (continuous/single-shot radios,
//					trigger only in single-shot) or the manual fields and
//					slider, and set the manual gain value.
//
//	ARGUMENTS	:	gainMode - See3CAMCU135M_H01R1.AUTO_GAIN or MANUAL_GAIN
//					autoGainMode - See3CAMCU135M_H01R1.CONTINUOUS or
//					  SINGLE_SHOT
//					gainValue - manual gain value
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateGainMode(gainMode, autoGainMode, gainValue) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "gainControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (gainMode === See3CAMCU135M_H01R1.AUTO_GAIN && child.id === "autoGainMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (gainMode === See3CAMCU135M_H01R1.MANUAL_GAIN && child.id === "manualGainMode") {
                    child.checked = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoField"){
                    child.enabled = (gainMode === See3CAMCU135M_H01R1.AUTO_GAIN)
                    changedFields.push({ id: child.id, enabled: child.enabled })
                } else if (child.id === "continuousGain"){
                    child.enabled = (gainMode === See3CAMCU135M_H01R1.AUTO_GAIN)
                    child.checked = (autoGainMode === See3CAMCU135M_H01R1.CONTINUOUS)
                    changedFields.push({ id: child.id, enabled: child.enabled, checked: child.checked })
                } else if (child.id === "singleShotGain"){
                    child.enabled = (gainMode === See3CAMCU135M_H01R1.AUTO_GAIN)
                    child.checked = (autoGainMode === See3CAMCU135M_H01R1.SINGLE_SHOT)
                    changedFields.push({ id: child.id, enabled: child.enabled, checked: child.checked })
                } else if (child.id === "autoGaintrigger"){
                    child.enabled = (gainMode === See3CAMCU135M_H01R1.AUTO_GAIN && autoGainMode === See3CAMCU135M_H01R1.SINGLE_SHOT)
                    changedFields.push({ id: child.id, enabled: child.enabled, checked: child.checked })
                } else if( child.id === "manualField"){
                    child.enabled = (gainMode === See3CAMCU135M_H01R1.MANUAL_GAIN)
                    changedFields.push({ id: child.id, enabled: child.enabled })
                } else if (child.id === "manualGain") {
                    child.enabled = (gainMode === See3CAMCU135M_H01R1.MANUAL_GAIN)
                    child.currentValue = gainValue
                    changedFields.push({ id: child.id, enabled: child.enabled, currentValue: child.currentValue })
                }
            }
            break
        }
    }
    return changedFields
}

// Exposure Mode
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposureMode(exposureMode)
//
//  PURPOSE		:	To check the Continuous or One-shot radio in the
//					"autoExpMode" group and enable the Trigger button only in
//					single-shot exposure mode.
//
//	ARGUMENTS	:	exposureMode - See3CAMCU135M_H01R1.CONTINUOUS_EXPOSURE or
//					  SINGLE_SHOT_EXPOSURE
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateExposureMode(exposureMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "autoExpMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "continuous") {
                    child.checked = (exposureMode === See3CAMCU135M_H01R1.CONTINUOUS_EXPOSURE)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if ( child.id === "oneShot") {
                    child.checked = (exposureMode === See3CAMCU135M_H01R1.SINGLE_SHOT_EXPOSURE )
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "trigger") {
                    child.enabled = (exposureMode === See3CAMCU135M_H01R1.SINGLE_SHOT_EXPOSURE)
                    changedFields.push({ id: child.id, enabled: child.enabled })
                }
            }
            break
        }
    }
    return changedFields
}

// Gain Lower Limit
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGainLowerLimit(lowerLimit)
//
//  PURPOSE		:	To set the "lowerLimit" slider in the "autoGainLimit"
//					group to the auto gain lower limit read from the camera.
//
//	ARGUMENTS	:	lowerLimit - auto gain lower limit
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateGainLowerLimit(lowerLimit) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "autoGainLimit" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "lowerLimit") {
                    child.currentValue = lowerLimit
                    changedFields.push({ id: child.id, currentValue: child.currentValue })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// Gains Upper Limit
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGainUpperLimit(upperLimit)
//
//  PURPOSE		:	To set the "upperLimit" slider in the "autoGainLimit"
//					group to the auto gain upper limit read from the camera.
//
//	ARGUMENTS	:	upperLimit - auto gain upper limit
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateGainUpperLimit(upperLimit) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "autoGainLimit" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "upperLimit") {
                    child.currentValue = upperLimit
                    changedFields.push({ id: child.id, currentValue: child.currentValue })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// Exposure Lower Limit
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposureLowerLimit(lowerLimit)
//
//  PURPOSE		:	To show the auto exposure lower limit read from the camera
//					in the "aeLowLimit" text box.
//
//	ARGUMENTS	:	lowerLimit - auto exposure lower limit
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateExposureLowerLimit(lowerLimit) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "autoExpLowLimit" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "aeLowLimit") {
                    child.text = lowerLimit.toString()
                    changedFields.push({ id: child.id, text: child.text })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// Exposure Upper Limit
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposureUpperLimit(upperLimit)
//
//  PURPOSE		:	To show the auto exposure upper limit read from the camera
//					in the "aeUpperLimit" text box.
//
//	ARGUMENTS	:	upperLimit - auto exposure upper limit
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateExposureUpperLimit(upperLimit) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "autoExpUpperLimit" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "aeUpperLimit") {
                    child.text = upperLimit.toString()
                    changedFields.push({ id: child.id, text: child.text })
                    break
                }
            }
            break
        }
    }
    return changedFields
}


// ----------------------------------------------------------------
// Enable / Disable controls based on the exposure mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleOnExposureModeChange(mode)
//
//  PURPOSE		:	To enable/disable the AE mode, ROI AE, anti-flicker and AE
//					upper/lower limit groups according to the UVC exposure
//					mode (enabled only in auto exposure); manualAE also needs
//					Manual ROI checked. Caches mode in isUvcExposureAuto.
//
//	ARGUMENTS	:	mode - true/1 for UVC auto exposure, false/0 for manual
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function handleOnExposureModeChange(mode) {
    // mode: 0 = Continuous, 1 = Single-shot
    isUvcExposureAuto = mode
    var changedFields = []

    for (var i = 0; i < see3camcu135mHidProperty.length; ++i) {
        var section = see3camcu135mHidProperty[i]

        // ----------------------------------------------------------------
        // Auto-Exposure Mode — disable/enable section and all children
        // ----------------------------------------------------------------
        if (section.id === "autoExpMode") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "autoExpMode", enabled: isUvcExposureAuto })
            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
                    child.enabled = isUvcExposureAuto
                    changedFields.push({ id: child.id, enabled: isUvcExposureAuto })
                }
            }
        }

        // ----------------------------------------------------------------
        // ROI Auto-Exposure — disable/enable section and all children
        // manualAE dropdown: enabled ONLY if Auto AND manualROIAE is checked
        // ----------------------------------------------------------------
        else if (section.id === "roiAE") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "roiAE", enabled: isUvcExposureAuto })
            if (section.children) {
                var isManualROIChecked = false
                for (var k = 0; k < section.children.length; k++) {
                    if (section.children[k].id === "manualROIAE") {
                        isManualROIChecked = section.children[k].checked
                        break
                    }
                }
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
                    if (child.id === "manualAE") {
                        var manualAEEnabled = isUvcExposureAuto && isManualROIChecked
                        child.enabled = manualAEEnabled
                        changedFields.push({ id: "manualAE", enabled: manualAEEnabled })
                    } else {
                        child.enabled = isUvcExposureAuto
                        changedFields.push({ id: child.id, enabled: isUvcExposureAuto })
                    }
                }
            }
        }

        // ----------------------------------------------------------------
        // Anti-Flicker — disable/enable section and all children
        // ----------------------------------------------------------------
        else if (section.id === "antiFlicker") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "antiFlicker", enabled: isUvcExposureAuto })
            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
                    child.enabled = isUvcExposureAuto
                    changedFields.push({ id: child.id, enabled: isUvcExposureAuto })
                }
            }
        }

        // ----------------------------------------------------------------
        // Exposure Upper Limit — disable/enable section and all children
        // ----------------------------------------------------------------
        else if (section.id === "autoExpUpperLimit") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "autoExpUpperLimit", enabled: isUvcExposureAuto })
            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
                    child.enabled = isUvcExposureAuto
                    changedFields.push({ id: child.id, enabled: isUvcExposureAuto })
                }
            }
        }

        // ----------------------------------------------------------------
        // Exposure Lower Limit — disable/enable section and all children
        // ----------------------------------------------------------------
        else if (section.id === "autoExpLowLimit") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "autoExpLowLimit", enabled: isUvcExposureAuto })
            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
                    child.enabled = isUvcExposureAuto
                    changedFields.push({ id: child.id, enabled: isUvcExposureAuto })
                }
            }
        }
    }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setExposureMode(mode)
//
//  PURPOSE		:	To handle a UVC exposure mode change: cache it, refresh
//					the exposure-dependent controls via
//					handleOnExposureModeChange() and triggerUpdateSignal(),
//					then start the getAutoExposureControlValues timer to re-
//					read AE values.
//
//	ARGUMENTS	:	mode - true/1 for UVC auto exposure, false/0 for manual
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setExposureMode(mode) {
    isUvcExposureAuto = mode

    var changedFields = handleOnExposureModeChange(isUvcExposureAuto);
    triggerUpdateSignal(changedFields)

    getAutoExposureControlValues.start()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setUvcGainValue(value)
//
//  PURPOSE		:	To keep the "manualGain" slider in sync when the gain is
//					changed from the UVC gain control
//					(usbcamRect.setUvcGainValue signal).
//
//	ARGUMENTS	:	value - new gain value
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function setUvcGainValue(value) {
    var changedFields = []
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var group = see3camcu135mHidProperty[i]
        if (group.id === "gainControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "manualGain") {
                    child.currentValue = value
                    changedFields.push({ id: child.id, currentValue: child.currentValue })
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRightClick(x, y, width, height)
//
//  PURPOSE		:	To set the manual AE ROI centred on the area right-clicked
//					in the preview (only in UVC auto exposure), using the
//					cached aeWindowSize.
//
//	ARGUMENTS	:	x - x coordinate of the click in the preview
//					y - y coordinate of the click in the preview
//					width - preview width
//					height - preview height
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleRightClick(x, y, width, height) {
    if (isUvcExposureAuto) {
        see3camcu135mh01r1Controller.setROIAutoExposure(See3CAMCU135M_H01R1.AE_Manual, x, y, width, height, aeWindowSize)
    }
}

// ----------------------------------------------------------------
// Handle Slider Value Changes
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider's new value in the model and apply it
//					via see3camcu135mh01r1Controller: target brightness,
//					manual gain (setGainMode, also mirrored to UVC via
//					usbcamRect.setHidGainValue) or the auto gain lower/upper
//					limit (setGainLimit).
//
//	ARGUMENTS	:	id - id of the slider control
//					currentVal - new slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id, currentVal) {
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var section = see3camcu135mHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = currentVal  // keep JSON in sync
                    break
                }
            }
        }
    }

    if (id === "brightness") {
        see3camcu135mh01r1Controller.setTargetBrightness(currentVal)
    } else if (id === "manualGain") {
        var isSingleShot = false
        for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
            var section = see3camcu135mHidProperty[i]
            if (section.id === "gainControl" && section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    if (section.children[j].id === "singleShotGain") {
                        isSingleShot = section.children[j].checked
                        break
                    }
                }
                break
            }
        }
        see3camcu135mh01r1Controller.setGainMode(See3CAMCU135M_H01R1.MANUAL_GAIN, isSingleShot ? See3CAMCU135M_H01R1.SINGLE_SHOT : See3CAMCU135M_H01R1.CONTINUOUS, currentVal)
        usbcamRect.setHidGainValue(currentVal)
    } else if (id === "lowerLimit") {
        see3camcu135mh01r1Controller.setGainLimit(currentVal, getUpperLimitCurrentValue())
    } else if (id === "upperLimit") {
        see3camcu135mh01r1Controller.setGainLimit(getLowerLimitCurrentValue(), currentVal)
    }
}

// ----------------------------------------------------------------
// Helper: read current slider values from JSON for gain limits
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getLowerLimitCurrentValue()
//
//  PURPOSE		:	To read the current auto gain lower limit from the
//					"lowerLimit" slider in the model, for use with
//					setGainLimit().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Number - slider value (its min if unset, 1 if not found)
///////////////////////////////////////////////////////////////////////////
function getLowerLimitCurrentValue() {
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var section = see3camcu135mHidProperty[i]
        if (section.id === "autoGainLimit" && section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === "lowerLimit")
                    return section.children[j].currentValue || section.children[j].min
            }
        }
    }
    return 1
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getUpperLimitCurrentValue()
//
//  PURPOSE		:	To read the current auto gain upper limit from the
//					"upperLimit" slider in the model, for use with
//					setGainLimit().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Number - slider value (its max if unset, 62 if not found)
///////////////////////////////////////////////////////////////////////////
function getUpperLimitCurrentValue() {
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var section = see3camcu135mHidProperty[i]
        if (section.id === "autoGainLimit" && section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === "upperLimit")
                    return section.children[j].currentValue || section.children[j].max
            }
        }
    }
    return 62
}

//------------------------------------------------------------
// HANDLE CHECKBOX CHANGES
// -----------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box state in the model and apply
//					horizontal/vertical flip via
//					see3camcu135mh01r1Controller.setFlipCtrlValue().
//
//	ARGUMENTS	:	id - id of the check box
//					checked - new checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked) {
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var section = see3camcu135mHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].checked = checked  // keep JSON in sync
                    break
                }
            }
        }
    }

    if (id === "horizontal") {
        isHorizontalFlip = checked
        see3camcu135mh01r1Controller.setFlipCtrlValue(checked, isVerticalFlip)
    } else if (id === "vertical") {
        isVerticalFlip = checked
        see3camcu135mh01r1Controller.setFlipCtrlValue(isHorizontalFlip, checked)
    }
}

// ----------------------------------------------------
// HANDLE DROP BOX VALUE CHANGE
//------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a dropdown's new value in the model; for
//					"manualAE" cache it in aeWindowSize and set the manual AE
//					ROI window size on the camera.
//
//	ARGUMENTS	:	id - id of the dropdown control
//					value - newly selected value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value) {
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var section = see3camcu135mHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = value   // keep JSON in sync
                    section.children[j].selected = value
                    break
                }
            }
        }
    }

    if (id === "manualAE") {
        aeWindowSize = value
        see3camcu135mh01r1Controller.setROIAutoExposure(See3CAMCU135M_H01R1.AE_Manual, 0, 0, 0, 0, aeWindowSize)
    }
}

// ----------------------------------------------------------------
// Handle Text box value change
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, text)
//
//  PURPOSE		:	To store text typed into a text box (e.g. AE limits) in
//					the matching model entry so it can be read when its Set
//					button is clicked.
//
//	ARGUMENTS	:	id - id of the text box control
//					text - new text
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(id, text) {
    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var section = see3camcu135mHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].text = text   // keep JSON in sync
                    return
                }
            }
        }
    }
}

// ----------------------------------------------------------------
// Handle Button Click 
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle button clicks via see3camcu135mh01r1Controller:
//					"trigger" runs single-shot exposure, "updateDefault"
//					restores defaults and re-reads controls, "autoGaintrigger"
//					runs single-shot auto gain,
//					"setAeUpperLimit"/"setAeLowLimit" validate and write the
//					AE limits, "readStatistics" reads exposure/gain
//					statistics.
//
//	ARGUMENTS	:	id - id of the clicked button
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {
    if (id === "trigger") {
        see3camcu135mh01r1Controller.setExposureMode(See3CAMCU135M_H01R1.SINGLE_SHOT_EXPOSURE)
    } else if (id === "setExpComp") {
       
    } else if (id === "updateDefault") {
        see3camcu135mh01r1Controller.setToDefault()
        getCameraControls()
    } else if (id === "autoGaintrigger") {
        var manualVal = ""

        for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
            var section = see3camcu135mHidProperty[i]
            if (section.id === "gainControl" && section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    if (section.children[j].id === "manualGain") {
                        manualVal = section.children[j].currentValue
                        break
                    }
                }
                break
            }
        }
        see3camcu135mh01r1Controller.setGainMode(See3CAMCU135M_H01R1.AUTO_GAIN, See3CAMCU135M_H01R1.SINGLE_SHOT, manualVal)
    } else if (id === "setAeUpperLimit") {
        // ----------------------------------------------------------------
        // Find the lowLimit textbox in the JSON and read its text
        // ----------------------------------------------------------------
        var upperLimit = ""

        for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
            var section = see3camcu135mHidProperty[i]
            if (section.id === "autoExpUpperLimit" && section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    if (section.children[j].id === "aeUpperLimit") {
                        upperLimit = section.children[j].text
                        break
                    }
                }
                break
            }
        }

        // Validate and call controller
        if (upperLimit === "" || upperLimit === undefined) {
            console.log("Low Limit exposure compensation value is empty")
            return
        }

        var upperLimitValue = parseInt(upperLimit)

        if (isNaN(upperLimitValue)) {
            console.log("Invalid exposure compensation value:", upperLimitValue)
            return
        }

        see3camcu135mh01r1Controller.setExposureUpperLimit(upperLimitValue)
    } else if (id === "setAeLowLimit") {
        // ----------------------------------------------------------------
        // Find the expCompValue textbox in the JSON and read its text
        // ----------------------------------------------------------------
        var lowLimit = ""

        for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
            var section = see3camcu135mHidProperty[i]
            if (section.id === "autoExpLowLimit" && section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    if (section.children[j].id === "aeLowLimit") {
                        lowLimit = section.children[j].text
                        break
                    }
                }
                break
            }
        }

        // Validate and call controller
        if (lowLimit === "" || lowLimit === undefined) {
            console.log("Low Limit exposure compensation value is empty")
            return
        }

        var lowLimitValue = parseInt(lowLimit)

        if (isNaN(lowLimitValue)) {
            console.log("Invalid exposure compensation value:", lowLimitValue)
            return
        }
        
        see3camcu135mh01r1Controller.setExposureLowerLimit(lowLimitValue)
    } else if (id === "readStatistics") {
        see3camcu135mh01r1Controller.readStatistics()
    }
}

//-----------------------------------------------------------------
// Handle radio button changes
//-----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle a radio button toggle: map the group
//					identification to its model group, update the checked
//					state (unchecking siblings), enable/disable dependent
//					controls (manualAE, AE trigger, auto/manual gain fields,
//					gain limits, auto gain trigger) and send stream, flash,
//					ROI AE, exposure mode, anti-flicker, gain mode or black
//					level setting via see3camcu135mh01r1Controller.
//
//	ARGUMENTS	:	identification - radio group identifier from the JSON
//					  (e.g. "gainMode")
//					id - id of the toggled radio button
//					checked - new checked state
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []

    // Map identification → parent group id
    var identificationToGroupId = {
        "streamModes": "streamMode",
        "flashModes": "flashMode",
        "roiAEMode": "roiAE",
        "autoExposureModes": "autoExpMode",
        "antiFlickerMode": "antiFlicker",
        "gainMode": "gainControl",
        "autoGainMode": "gainControl",
        "blcMode": "blackLightCompensation"
    }

    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    for (var i = 0; i < see3camcu135mHidProperty.length; i++) {
        var section = see3camcu135mHidProperty[i]

        if (section.id === groupId && section.children) {

            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]

                if (radio.id === id) {
                    // ===== SELECTED RADIO BUTTON =====
                    radio.checked = checked
                    changedFields.push({ id: radio.id, checked: checked })

                    if (checked) {

                        // ----------------------------------------------------------------
                        // Stream Mode
                        // ----------------------------------------------------------------
                        if (groupId === "streamMode") {
                            var streamMap = {
                                "masterMode": 0,
                                "triggerMode": 1
                            }
                            if (streamMap[id] !== undefined)
                                see3camcu135mh01r1Controller.setStreamMode(streamMap[id])

                            // ----------------------------------------------------------------
                            // Flash Mode
                            // ----------------------------------------------------------------
                        }
                        else if (groupId === "flashMode") {
                            var flashMap = {
                                "disableFlashMode": See3CAMCU135M_H01R1.FLASHMODE_OFF,
                                "strobeMode": See3CAMCU135M_H01R1.FLASHMODE_STROBE,
                                "torchMode": See3CAMCU135M_H01R1.FLASHMODE_TORCH
                            }
                            if (flashMap[id] !== undefined)
                                see3camcu135mh01r1Controller.setFlashState(flashMap[id])

                            // ----------------------------------------------------------------
                            // ROI Auto-Exposure
                            // manualAE dropdown enabled ONLY when manualROIAE is selected
                            // ----------------------------------------------------------------
                        }
                        else if (groupId === "roiAE") {
                            var isManual = (id === "manualROIAE")

                            for (var k = 0; k < section.children.length; k++) {
                                var roiChild = section.children[k]
                                if (roiChild.id === "manualAE") {
                                    roiChild.enabled = isManual
                                    changedFields.push({ id: "manualAE", enabled: isManual })
                                }
                            }

                            var roiAEMap = {
                                "fullROIAE": See3CAMCU135M_H01R1.AE_Full,
                                "manualROIAE": See3CAMCU135M_H01R1.AE_Manual
                            }
                            if (roiAEMap[id] !== undefined) {
                                if (id === "manualROIAE") {
                                    see3camcu135mh01r1Controller.setROIAutoExposure(
                                        roiAEMap[id], 0, 0, 0, 0, aeWindowSize
                                    )
                                } else {
                                    see3camcu135mh01r1Controller.setROIAutoExposure(
                                        roiAEMap[id], 0, 0, 0, 0, aeWindowSize
                                    )
                                }
                            }

                            // ----------------------------------------------------------------
                            // Auto-Exposure Mode
                            // trigger button enabled ONLY when single-shot is selected
                            // ----------------------------------------------------------------
                        }
                        else if (groupId === "autoExpMode") {
                            var isSingleShot = (id === "oneShot")

                            for (var k = 0; k < section.children.length; k++) {
                                var aeChild = section.children[k]
                                if (aeChild.id === "trigger") {
                                    aeChild.enabled = isSingleShot
                                    changedFields.push({ id: "trigger", enabled: isSingleShot })
                                }
                            }

                            var exposureMap = {
                                "continuous": 0,
                                "oneShot": 1
                            }
                            if (exposureMap[id] !== undefined)
                                see3camcu135mh01r1Controller.setExposureMode(exposureMap[id])

                            // ----------------------------------------------------------------
                            // Anti-Flicker Mode
                            // ----------------------------------------------------------------
                        }
                        else if (groupId === "antiFlicker") {
                            var flickerMap = {
                                "disableMode": See3CAMCU135M_H01R1.MODE_DISABLE,
                                "50HzMode": See3CAMCU135M_H01R1.MODE_50Hz,
                                "60HzMode": See3CAMCU135M_H01R1.MODE_60Hz
                            }
                            if (flickerMap[id] !== undefined)
                                see3camcu135mh01r1Controller.setAntiFlickerMode(flickerMap[id])
                        }
                        else if (groupId === "gainControl") {

                            if (identification === "gainMode") {
                                var isAutoGain = (id === "autoGainMode")
                                var isManualGain = (id === "manualGainMode")
                                var isContAutoGain = false
                                var isSingleShotAutoGain = false

                                // Toggle children inside gainControl section
                                for (var k = 0; k < section.children.length; k++) {
                                    var gainChild = section.children[k]

                                    if (gainChild.id === "continuousGain" || gainChild.id === "singleShotGain") {
                                        gainChild.enabled = isAutoGain
                                        if (gainChild.id === "continuousGain") {
                                            isContAutoGain = (gainChild.checked === true)
                                        } else if (gainChild.id === "singleShotGain") {
                                            isSingleShotAutoGain = (gainChild.checked === true)
                                        }
                                        changedFields.push({ id: gainChild.id, enabled: isAutoGain })
                                    } else if (gainChild.id === "trigger") {
                                        // trigger only active in auto+singleShot; disable on mode switch
                                        gainChild.enabled = false
                                        changedFields.push({ id: "trigger", enabled: false })
                                    } else if (gainChild.id === "manualGain") {
                                        gainChild.enabled = isManualGain
                                        changedFields.push({ id: "manualGain", enabled: isManualGain })
                                    }
                                }

                                // Toggle autoGainLimit section (lowerLimit / upperLimit sliders)
                                for (var m = 0; m < see3camcu135mHidProperty.length; m++) {
                                    var limitSection = see3camcu135mHidProperty[m]
                                    if (limitSection.id === "autoGainLimit") {
                                        limitSection.enabled = isAutoGain
                                        changedFields.push({ id: "autoGainLimit", enabled: isAutoGain })
                                        if (limitSection.children) {
                                            for (var n = 0; n < limitSection.children.length; n++) {
                                                var limitChild = limitSection.children[n]
                                                limitChild.enabled = isAutoGain
                                                changedFields.push({ id: limitChild.id, enabled: isAutoGain })
                                            }
                                        }
                                        break
                                    }
                                }

                                // Read current manualGain slider value
                                var manualVal = 1
                                for (var k = 0; k < section.children.length; k++) {
                                    if (section.children[k].id === "manualGain") {
                                        manualVal = section.children[k].currentValue || 1
                                        break
                                    }
                                }

                                // Build setGainMode call
                                if (isAutoGain) {
                                    if (isContAutoGain) {
                                        see3camcu135mh01r1Controller.setGainMode(See3CAMCU135M_H01R1.AUTO_GAIN, See3CAMCU135M_H01R1.CONTINUOUS, manualVal)
                                    } else if (isSingleShotAutoGain) {
                                        see3camcu135mh01r1Controller.setGainMode(See3CAMCU135M_H01R1.AUTO_GAIN, See3CAMCU135M_H01R1.SINGLE_SHOT, manualVal)
                                    }
                                } else if (isManualGain) {      
                                    see3camcu135mh01r1Controller.setGainMode(See3CAMCU135M_H01R1.MANUAL_GAIN, isSingleShotAutoGain ? See3CAMCU135M_H01R1.SINGLE_SHOT : See3CAMCU135M_H01R1.CONTINUOUS, manualVal)
                                 }
                      
                            }
                            else if (identification === "autoGainMode") {
                                // continuous / single-shot sub-selection inside Auto gain
                                var isSingleShot = (id === "singleShotGain")
                                var manualVal = 1
                                for (var k = 0; k < section.children.length; k++) {
                                    var gainChild = section.children[k]
                                    if (gainChild.id === "autoGaintrigger") {
                                        gainChild.enabled = isSingleShot
                                        changedFields.push({ id: "autoGaintrigger", enabled: isSingleShot })
                                    }
                                    if (section.children[k].id === "manualGain") {
                                        manualVal = section.children[k].currentValue || 1
                                        break
                                    }
                                }
                                

                                 see3camcu135mh01r1Controller.setGainMode(
                                     See3CAMCU135M_H01R1.AUTO_GAIN,
                                     isSingleShot ? See3CAMCU135M_H01R1.SINGLE_SHOT : See3CAMCU135M_H01R1.CONTINUOUS,
                                     manualVal
                                 )
                            }
                        }
                        else if (groupId === "blackLightCompensation") {
                            var blcMap = {
                                "disableBlc": See3CAMCU135M_H01R1.DISABLE,
                                "enableBlc": See3CAMCU135M_H01R1.ENABLE
                            }
                            if (blcMap[id] !== undefined)
                                see3camcu135mh01r1Controller.setBlackLevelAdjustment(blcMap[id])
                        }
                    }

                } else if (radio.identification === identification) {
                    // ===== UNCHECK ALL OTHER RADIO BUTTONS IN SAME GROUP =====
                    radio.checked = false
                    changedFields.push({ id: radio.id, checked: false })
                }
            }

            break  // found section, stop outer loop
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getAutoExposureControls()
//
//  PURPOSE		:	To re-read the exposure mode, anti-flicker mode, AE ROI
//					and AE lower/upper limits from the camera. Called by the
//					getAutoExposureControlValues timer after an exposure mode
//					change.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getAutoExposureControls(){
    see3camcu135mh01r1Controller.getExposureMode()
    see3camcu135mh01r1Controller.getAntiFlickerMode()
    see3camcu135mh01r1Controller.getAutoExpROIModeAndWindowSize()
    see3camcu135mh01r1Controller.getExposureLowerLimit()
    see3camcu135mh01r1Controller.getExposureUpperLimit()
}