var see3camcu84HidProperty = []
var isUvcExposureAuto = false
var isUvcFocusAuto = false
var aeWindowSize = 0
var isEmbedDataEnabled = false
var isOverlayRectEnabled = false
var isVerticalFlip = false
var isHorizontalFlip = false

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To cache the JSON property model (HID accordion sections and
//					their child controls) loaded by UsbcamHidSettings.qml in
//					see3camcu84HidProperty, so the other functions can read and
//					update it.
//
//	ARGUMENTS	:	jsonArray - Array of section objects parsed from the camera's
//					  JSON file
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camcu84HidProperty = jsonArray
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMCU84HidModelData()
//
//  PURPOSE		:	To return the cached JSON property model
//					(see3camcu84HidProperty) so UsbcamHidSettings.qml can bind it
//					to the HID accordion.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current property model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMCU84HidModelData() {
    return see3camcu84HidProperty
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	callSupportFunctions()
//
//  PURPOSE		:	To re-apply the exposure-mode dependent enable/disable state
//					of the ROI AE and exposure compensation sections using the
//					cached isUvcExposureAuto flag, and push the result to the UI
//					via triggerUpdateSignal().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function callSupportFunctions() {
    var changedFields = handleOnExposureModeChange(isUvcExposureAuto)
    triggerUpdateSignal(changedFields)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To start the QML delayedControlsTimer, whose handler calls
//					getDelayedCameraControls() so the See3CAM_CU84 HID values are
//					queried only after the UI is ready.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Get all camera controls on initialization
// ----------------------------------------------------------------
function getCameraControls() {
    delayedControlsTimer.start()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To request all HID control values from the See3CAM_CU84
//					(special effect, denoise, Q-factor, frame rate, exposure
//					compensation, AE ROI, stream mode, flip, anti-flicker, flash,
//					face detection, burst length, serial number and firmware
//					version). Results arrive via controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
function getDelayedCameraControls() {
    see3camcu84Controller.getSpecialEffect()
    see3camcu84Controller.getDenoiseValue()
    see3camcu84Controller.getQFactor()
    see3camcu84Controller.getFrameRateCtrl()
    see3camcu84Controller.getExposureCompensation()
    see3camcu84Controller.getAutoExpROIMode()
    see3camcu84Controller.getStreamMode()
    see3camcu84Controller.getFlipMode()
    see3camcu84Controller.getAntiFlickerMode()
    see3camcu84Controller.getFlashMode()
    see3camcu84Controller.getFaceDetection()
    see3camcu84Controller.getBurstLength()
    see3camcu84Controller.get64BitSerialNumber()
    see3camcu84Controller.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached UI state (exposure/focus auto flags, AE
//					window size, face-detect embed/overlay flags and flip flags)
//					to defaults when the device is closed or switched. The
//					property model itself is kept.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    isUvcExposureAuto = false
    isUvcFocusAuto = false
    aeWindowSize = 0
    isEmbedDataEnabled = false
    isOverlayRectEnabled = false
    isVerticalFlip = false
    isHorizontalFlip = false
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateEffectMode(value)
//
//  PURPOSE		:	To check the special-effect radio button (normal, black &
//					white, greyscale, negative or sketch) matching the mode read
//					from the camera and uncheck the others in the "specialEffect"
//					section.
//
//	ARGUMENTS	:	value - Effect mode value (See3CAMCU84.EFFECT_*) from the
//					  controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Special Effects
// ----------------------------------------------------------------
function updateEffectMode(value) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "specialEffect" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if      (child.id === "normalEffect")  child.checked = (value === See3CAMCU84.EFFECT_NORMAL)
                else if (child.id === "blackAndWhite") child.checked = (value === See3CAMCU84.EFFECT_BLACK_WHITE)
                else if (child.id === "grayScale")     child.checked = (value === See3CAMCU84.EFFECT_GREYSCALE)
                else if (child.id === "negative")      child.checked = (value === See3CAMCU84.EFFECT_NEGATIVE)
                else if (child.id === "sketch")        child.checked = (value === See3CAMCU84.EFFECT_SKETCH)
                changedFields.push({ id: child.id, checked: child.checked })
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDenoiseValue(value)
//
//  PURPOSE		:	To set the "denoise" slider in the "denoiseStrength" section
//					to the denoise value read from the camera.
//
//	ARGUMENTS	:	value - Denoise strength from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Denoise Strength
// ----------------------------------------------------------------
function updateDenoiseValue(value) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "denoiseStrength" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "denoise") {
                    group.children[j].currentValue = value
                    changedFields.push({ id: group.children[j].id, currentValue: value })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBurstLength(burstLength)
//
//  PURPOSE		:	To forward the burst length read from the camera to
//					prevController (so still capture takes that many frames) and
//					select it in the "burstLen" drop box of the "imageCapture"
//					section.
//
//	ARGUMENTS	:	burstLength - Burst length (number of images per still
//					  capture)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Burst Length
// ----------------------------------------------------------------
function updateBurstLength(burstLength) {
    prevController.setBurstLength(burstLength)
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "imageCapture" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "burstLen") {
                    group.children[j].currentValue = burstLength
                    group.children[j].selected     = burstLength
                    changedFields.push({
                        id:       group.children[j].id,
                        selected: burstLength
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlipMode(flipMode)
//
//  PURPOSE		:	To set the "horizontal" and "vertical" flip check boxes from
//					the flip mode read from the camera and cache the result in
//					isHorizontalFlip / isVerticalFlip for later setFlipMode()
//					calls.
//
//	ARGUMENTS	:	flipMode - Flip mode (See3CAMCU84.HORZ_ONLY, VERT_ONLY,
//					  BOTH_ENABLE or none)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Flip Mode
// ----------------------------------------------------------------
function updateFlipMode(flipMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horizontal") {
                    child.checked    = (flipMode === See3CAMCU84.HORZ_ONLY ||
                                        flipMode === See3CAMCU84.BOTH_ENABLE)
                    isHorizontalFlip = child.checked
                    if (flipMode === See3CAMCU84.BOTH_ENABLE) isVerticalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "vertical") {
                    child.checked  = (flipMode === See3CAMCU84.VERT_ONLY ||
                                      flipMode === See3CAMCU84.BOTH_ENABLE)
                    isVerticalFlip = child.checked
                    if (flipMode === See3CAMCU84.BOTH_ENABLE) isHorizontalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRoiAEMode(roiMode, winSize)
//
//  PURPOSE		:	To reflect the auto-exposure ROI mode read from the camera:
//					check full or manual ROI, and in manual mode enable the
//					"manualAE" drop box, select the window size and cache it in
//					aeWindowSize.
//
//	ARGUMENTS	:	roiMode - ROI mode (See3CAMCU84.FULL_ROI or MANUAL_ROI)
//					winSize - AE window size reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// ROI Auto-Exposure
// ----------------------------------------------------------------
function updateRoiAEMode(roiMode, winSize) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "roiAE" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "fullROIAE") {
                    child.checked = (roiMode === See3CAMCU84.FULL_ROI)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualROIAE") {
                    child.checked = (roiMode === See3CAMCU84.MANUAL_ROI)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualAE") {
                    child.enabled = (roiMode === See3CAMCU84.MANUAL_ROI)
                    if (roiMode === See3CAMCU84.MANUAL_ROI) {
                        aeWindowSize       = winSize
                        child.currentValue = winSize
                        child.selected     = winSize
                    }
                    changedFields.push({
                        id:           child.id,
                        enabled:      child.enabled,
                        currentValue: child.currentValue,
                        selected:     child.selected
                    })
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposureComp(expComp)
//
//  PURPOSE		:	To show the exposure compensation value read from the camera
//					in the "expCompValue" text box of the "exposureCompensation"
//					section.
//
//	ARGUMENTS	:	expComp - Exposure compensation value from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Exposure Compensation
// ----------------------------------------------------------------
function updateExposureComp(expComp) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "exposureCompensation" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "expCompValue") {
                    child.text = expComp.toString()
                    changedFields.push({ id: child.id, text: child.text })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFrameRate(frameRate)
//
//  PURPOSE		:	To set the "frameRate" slider in the "frameRateControl"
//					section to the frame rate control value read from the camera.
//
//	ARGUMENTS	:	frameRate - Frame rate value from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Frame Rate
// ----------------------------------------------------------------
function updateFrameRate(frameRate) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "frameRateControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "frameRate") {
                    group.children[j].currentValue = frameRate
                    changedFields.push({ id: group.children[j].id, currentValue: frameRate })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAntiFlickerMode(flickerMode)
//
//  PURPOSE		:	To reflect the anti-flicker mode read from the camera: check
//					the off/auto/manual radio button and, for 50/60 Hz, enable the
//					"frequency" drop box and select "50 Hz" or "60 Hz".
//
//	ARGUMENTS	:	flickerMode - Anti-flicker mode (See3CAMCU84.MODE_DISABLE,
//					  MODE_AUTO, MODE_50Hz or MODE_60Hz)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Anti-Flicker Mode
// ----------------------------------------------------------------
function updateAntiFlickerMode(flickerMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "offMode") {
                    child.checked = (flickerMode === See3CAMCU84.MODE_DISABLE)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoMode") {
                    child.checked = (flickerMode === See3CAMCU84.MODE_AUTO)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualMode") {
                    child.checked = (flickerMode === See3CAMCU84.MODE_50Hz ||
                                     flickerMode === See3CAMCU84.MODE_60Hz)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "frequency") {
                    child.enabled      = (flickerMode === See3CAMCU84.MODE_50Hz ||
                                          flickerMode === See3CAMCU84.MODE_60Hz)
                    child.currentValue = (flickerMode === See3CAMCU84.MODE_60Hz) ? "60 Hz" : "50 Hz"
                    child.selected     = (flickerMode === See3CAMCU84.MODE_60Hz) ? "60 Hz" : "50 Hz"
                    changedFields.push({
                        id:           child.id,
                        enabled:      child.enabled,
                        currentValue: child.currentValue,
                        selected:     child.selected
                    })
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStreamMode(streamMode)
//
//  PURPOSE		:	To check the "masterMode" or "triggerMode" radio button in the
//					"streamMode" section according to the stream mode read from
//					the camera.
//
//	ARGUMENTS	:	streamMode - Stream mode (See3CAMCU84.MASTER_MODE or
//					  TRIGGER_MODE)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Stream Mode
// ----------------------------------------------------------------
function updateStreamMode(streamMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "streamMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "masterMode") {
                    child.checked = (streamMode === See3CAMCU84.MASTER_MODE)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "triggerMode") {
                    child.checked = (streamMode === See3CAMCU84.TRIGGER_MODE)
                    changedFields.push({ id: child.id, checked: child.checked })
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlashMode(flashMode)
//
//  PURPOSE		:	To check the strobe off ("disableMode") or strobe on
//					("strobeMode") radio button in the "flashMode" section
//					according to the mode read from the camera.
//
//	ARGUMENTS	:	flashMode - Flash mode (See3CAMCU84.STROBE_OFF or STROBE_ON)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Flash Mode  (Strobe OFF / Strobe ON)
// ----------------------------------------------------------------
function updateFlashMode(flashMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "flashMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if      (child.id === "disableMode") child.checked = (flashMode === See3CAMCU84.STROBE_OFF)
                else if (child.id === "strobeMode")  child.checked = (flashMode === See3CAMCU84.STROBE_ON)
                changedFields.push({ id: child.id, checked: child.checked })
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateQFactor(qFactor)
//
//  PURPOSE		:	To set the "qFactorVal" slider in the "qFactor" section to the
//					JPEG Q-factor read from the camera.
//
//	ARGUMENTS	:	qFactor - Q-factor value from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Q Factor
// ----------------------------------------------------------------
function updateQFactor(qFactor) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "qFactor" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "qFactorVal") {
                    group.children[j].currentValue = qFactor
                    changedFields.push({ id: group.children[j].id, currentValue: qFactor })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFaceDetectMode(mode, embedData, overlayRect)
//
//  PURPOSE		:	To reflect the face detection settings read from the camera:
//					check enable/disable, and enable plus set the "embeddedData"
//					and "overlayRect" check boxes (cached in isEmbedDataEnabled /
//					isOverlayRectEnabled).
//
//	ARGUMENTS	:	mode - Face detect state (See3CAMCU84.FaceRectEnable /
//					  FaceRectDisable)
//					embedData - Embedded data state (See3CAMCU84.EmbedDataEnable
//					  or disable)
//					overlayRect - Overlay rectangle state
//					  (See3CAMCU84.OverlayRectEnable or disable)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Face Detection
// ----------------------------------------------------------------
function updateFaceDetectMode(mode, embedData, overlayRect) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "faceDetection" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "enableFaceDet") {
                    child.checked = (mode === See3CAMCU84.FaceRectEnable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "disableFaceDet") {
                    child.checked = (mode === See3CAMCU84.FaceRectDisable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "embeddedData") {
                    child.enabled      = (mode === See3CAMCU84.FaceRectEnable)
                    child.checked      = (embedData === See3CAMCU84.EmbedDataEnable)
                    isEmbedDataEnabled = child.checked
                    changedFields.push({
                        id:      child.id,
                        enabled: child.enabled,
                        checked: child.checked
                    })

                } else if (child.id === "overlayRect") {
                    child.enabled        = (mode === See3CAMCU84.FaceRectEnable)
                    child.checked        = (overlayRect === See3CAMCU84.OverlayRectEnable)
                    isOverlayRectEnabled = child.checked
                    changedFields.push({
                        id:      child.id,
                        enabled: child.enabled,
                        checked: child.checked
                    })
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSerialNumber(serialNum)
//
//  PURPOSE		:	To show the 64-bit serial number reported by the controller in
//					the "serialNumber" text field of the "serialNum" section of
//					see3camcu84HidProperty.
//
//	ARGUMENTS	:	serialNum - Serial number string received from the controller
//					  signal
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Serial Number
// ----------------------------------------------------------------
function updateSerialNumber(serialNum) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
        if (group.id === "serialNum" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "serialNumber") {
                    group.children[j].text = serialNum
                    changedFields.push({ id: group.children[j].id, text: serialNum })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFirmwareVersioninUI(firmwareVersion)
//
//  PURPOSE		:	To show the firmware version reported by the controller in the
//					"firmwareVer" text field of the "firmwareVersion" section of
//					see3camcu84HidProperty.
//
//	ARGUMENTS	:	firmwareVersion - Firmware version received from the
//					  controller signal
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Firmware Version
// ----------------------------------------------------------------
function updateFirmwareVersioninUI(firmwareVersion) {
    var changedFields = []
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var group = see3camcu84HidProperty[i]
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

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleOnExposureModeChange(mode)
//
//  PURPOSE		:	To enable or disable the "roiAE" and "exposureCompensation"
//					sections according to the UVC exposure mode. The "manualAE"
//					window-size drop box is enabled only when exposure is auto AND
//					the manual ROI radio button is checked.
//
//	ARGUMENTS	:	mode - true when UVC exposure is Auto, false when Manual
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Enable / Disable controls based on exposure mode
// ----------------------------------------------------------------
function handleOnExposureModeChange(mode) {
    isUvcExposureAuto = mode
    var changedFields = []

    for (var i = 0; i < see3camcu84HidProperty.length; ++i) {
        var section = see3camcu84HidProperty[i]

        // ----------------------------------------------------------------
        // ROI Auto-Exposure — enabled when Auto, disabled when Manual
        // ----------------------------------------------------------------
        if (section.id === "roiAE") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "roiAE", enabled: isUvcExposureAuto })

            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]

                    if (child.id === "manualAE") {
                        // manualAE dropdown enabled only when BOTH:
                        //   1. UVC exposure is Auto
                        //   2. manualROIAE radio is checked
                        var isManualROIChecked = false
                        for (var k = 0; k < section.children.length; k++) {
                            if (section.children[k].id === "manualROIAE") {
                                isManualROIChecked = section.children[k].checked
                                break
                            }
                        }
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
        // Exposure Compensation — enabled when Auto, disabled when Manual
        // ----------------------------------------------------------------
        else if (section.id === "exposureCompensation") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "exposureCompensation", enabled: isUvcExposureAuto })

            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
                    if (child.id === "expCompValue" || child.id === "setExpComp") {
                        child.enabled = isUvcExposureAuto
                        changedFields.push({ id: child.id, enabled: isUvcExposureAuto })
                    }
                }
            }
        }
    }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setExposureMode(mode)
//
//  PURPOSE		:	To handle a UVC exposure auto/manual change from the main
//					settings: cache the mode, update the dependent HID controls
//					via triggerUpdateSignal() and start the
//					getAutoExposureControlValues timer to re-read the ROI AE
//					settings.
//
//	ARGUMENTS	:	mode - true when UVC exposure is Auto, false when Manual
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setExposureMode(mode) {
    isUvcExposureAuto = mode
    var changedFields = handleOnExposureModeChange(isUvcExposureAuto)
    triggerUpdateSignal(changedFields)

    getAutoExposureControlValues.start()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle a radio button click: update the checked state in
//					the model (unchecking the rest of the group) and, when
//					checked, send the matching command to see3camcu84Controller
//					(effect, AE ROI, anti-flicker, stream mode, flash or face
//					detection). On non-Windows the anti-flicker choice is also
//					mirrored to the UVC control via
//					usbcamRect.setHidAntiFlicker().
//
//	ARGUMENTS	:	identification - Radio group name from JSON (specialEffects,
//					  roiAEMode, antiFlickerMode, streamModes, flashModes or
//					  faceDetectionMode)
//					id - JSON id of the clicked radio button
//					checked - New checked state
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Radio Button Changes
// ----------------------------------------------------------------
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []

    var identificationToGroupId = {
        "specialEffects":    "specialEffect",
        "roiAEMode":         "roiAE",
        "antiFlickerMode":   "antiFlicker",
        "streamModes":       "streamMode",
        "flashModes":        "flashMode",
        "faceDetectionMode": "faceDetection"
    }

    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var section = see3camcu84HidProperty[i]

        if (section.id === groupId && section.children) {

            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]

                if (radio.id === id) {
                    radio.checked = checked
                    changedFields.push({ id: radio.id, checked: checked })

                    if (checked) {
                        if (groupId === "specialEffect") {
                            var effectMap = {
                                "normalEffect":  See3CAMCU84.EFFECT_NORMAL,
                                "blackAndWhite": See3CAMCU84.EFFECT_BLACK_WHITE,
                                "grayScale":     See3CAMCU84.EFFECT_GREYSCALE,
                                "negative":      See3CAMCU84.EFFECT_NEGATIVE,
                                "sketch":        See3CAMCU84.EFFECT_SKETCH
                            }
                            if (effectMap[id] !== undefined){
                                see3camcu84Controller.setSpecialEffect(effectMap[id])
                            }

                        } else if (groupId === "roiAE") {
                            var isManual = (id === "manualROIAE")
                            var aeWinSize
                            for (var k = 0; k < section.children.length; k++) {
                                if (section.children[k].id === "manualAE") {
                                    section.children[k].enabled = isManual
                                    aeWinSize = section.children[k].currentValue
                                    changedFields.push({ id: "manualAE", enabled: isManual })
                                }
                            }
                            var roiAEMap = {
                                "fullROIAE":   See3CAMCU84.FULL_ROI,
                                "manualROIAE": See3CAMCU84.MANUAL_ROI
                            }
                            if (roiAEMap[id] !== undefined) {
                                if (id === "manualROIAE") {
                                    see3camcu84Controller.setAutoExpROIMode(roiAEMap[id], 0, 0, 0, 0, aeWinSize)
                                } else if (id === "fullROIAE") {
                                    see3camcu84Controller.setAutoExpROIMode(roiAEMap[id], 0, 0, 0, 0, 0)
                                }
                            }

                        } else if (groupId === "antiFlicker") {
                            var isManual = (id === "manualMode")
                            var frequency = ""
                            for (var k = 0; k < section.children.length; k++) {
                                if (section.children[k].id === "frequency") {
                                    section.children[k].enabled = isManual
                                    changedFields.push({ id: "frequency", enabled: isManual })
                                    frequency = section.children[k].currentValue
                                }
                            }
                            if (id === "offMode") {
                                see3camcu84Controller.setAntiFlickerMode(See3CAMCU84.MODE_DISABLE)
                                if (Qt.platform.os !== "windows")
                                    usbcamRect.setHidAntiFlicker("DISABLE")
                            } else if (id === "autoMode") {
                                see3camcu84Controller.setAntiFlickerMode(See3CAMCU84.MODE_AUTO)
                            } else if (id === "manualMode") {
                                if (frequency === "60 Hz") {
                                    see3camcu84Controller.setAntiFlickerMode(See3CAMCU84.MODE_60Hz)
                                } else {
                                    see3camcu84Controller.setAntiFlickerMode(See3CAMCU84.MODE_50Hz)
                                }
                                if (Qt.platform.os !== "windows")
                                    usbcamRect.setHidAntiFlicker(frequency)
                            }

                        } else if (groupId === "streamMode") {
                            var streamMap = {
                                "masterMode":  See3CAMCU84.MASTER_MODE,
                                "triggerMode": See3CAMCU84.TRIGGER_MODE
                            }
                            if (streamMap[id] !== undefined)
                                see3camcu84Controller.setStreamMode(streamMap[id])

                        } else if (groupId === "flashMode") {
                            var flashMap = {
                                "disableMode": See3CAMCU84.STROBE_OFF,
                                "strobeMode":  See3CAMCU84.STROBE_ON
                            }
                            if (flashMap[id] !== undefined)
                                see3camcu84Controller.setFlashMode(flashMap[id])

                        } else if (groupId === "faceDetection") {
                            var isFaceDetectEnabled = (id === "enableFaceDet")
                            for (var k = 0; k < section.children.length; k++) {
                                var faceChild = section.children[k]
                                if (faceChild.id === "embeddedData") {
                                    faceChild.enabled = isFaceDetectEnabled
                                    changedFields.push({ id: "embeddedData", enabled: isFaceDetectEnabled })
                                } else if (faceChild.id === "overlayRect") {
                                    faceChild.enabled = isFaceDetectEnabled
                                    changedFields.push({ id: "overlayRect", enabled: isFaceDetectEnabled })
                                }
                            }
                            see3camcu84Controller.setFaceDetection(
                                isFaceDetectEnabled,
                                isEmbedDataEnabled,
                                isOverlayRectEnabled
                            )
                        }
                    }

                } else if (radio.identification === identification) {
                    radio.checked = false
                    changedFields.push({ id: radio.id, checked: false })
                }
            }

            break
        }
    }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box state in the model and apply it:
//					embeddedData / overlayRect call setFaceDetection() with the
//					cached face-detect flags, horizontal / vertical call
//					setFlipMode() with the cached flip flags.
//
//	ARGUMENTS	:	id - JSON id of the check box
//					checked - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Checkbox Changes
// ----------------------------------------------------------------
function updateCheckBoxValue(id, checked) {
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var section = see3camcu84HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].checked = checked
                    break
                }
            }
        }
    }

    if (id === "embeddedData") {
        isEmbedDataEnabled = checked
        see3camcu84Controller.setFaceDetection(true, checked, isOverlayRectEnabled)

    } else if (id === "overlayRect") {
        isOverlayRectEnabled = checked
        see3camcu84Controller.setFaceDetection(true, isEmbedDataEnabled, checked)

    } else if (id === "horizontal") {
        isHorizontalFlip = checked
        see3camcu84Controller.setFlipMode(checked, isVerticalFlip)

    } else if (id === "vertical") {
        isVerticalFlip = checked
        see3camcu84Controller.setFlipMode(isHorizontalFlip, checked)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle HID button clicks: "setExpComp" parses the
//					"expCompValue" text box and calls setExposureCompensation();
//					"updateDefault" calls setToDefault() and re-reads all
//					controls.
//
//	ARGUMENTS	:	id - JSON id of the clicked button
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Button Click
// ----------------------------------------------------------------
function handleButtonClick(id) {
    if (id === "setExpComp") {
        var expCompText = ""
        for (var i = 0; i < see3camcu84HidProperty.length; i++) {
            var section = see3camcu84HidProperty[i]
            if (section.id === "exposureCompensation" && section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    if (section.children[j].id === "expCompValue") {
                        expCompText = section.children[j].text
                        break
                    }
                }
                break
            }
        }

        if (expCompText === "" || expCompText === undefined) {
            console.log("Exposure compensation value is empty")
            return
        }
        var expCompValue = parseInt(expCompText)
        if (isNaN(expCompValue)) {
            console.log("Invalid exposure compensation value:", expCompText)
            return
        }
        see3camcu84Controller.setExposureCompensation(expCompValue)

    } else if (id === "updateDefault") {
        see3camcu84Controller.setToDefault()
        getCameraControls()
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, text)
//
//  PURPOSE		:	To keep see3camcu84HidProperty in sync when the user edits a
//					text box by storing the new text on the matching child
//					control. No camera command is sent here; values are applied on
//					button click.
//
//	ARGUMENTS	:	id - JSON id of the edited text box
//					text - New text entered by the user
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Text Box Value Change
// ----------------------------------------------------------------
function updateTextBoxField(id, text) {
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var section = see3camcu84HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].text = text
                    return
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider's new value in the model and apply it on the
//					camera: denoise -> setDenoiseValue(), qFactorVal ->
//					setQFactor(), frameRate -> setFrameRateCtrl().
//
//	ARGUMENTS	:	id - JSON id of the slider
//					currentVal - New slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Slider Value Changes
// ----------------------------------------------------------------
function updateSliderValue(id, currentVal) {
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var section = see3camcu84HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = currentVal
                    break
                }
            }
        }
    }

    if (id === "denoise") {
        see3camcu84Controller.setDenoiseValue(currentVal)
    } else if (id === "qFactorVal") {
        see3camcu84Controller.setQFactor(currentVal)
    } else if (id === "frameRate") {
        see3camcu84Controller.setFrameRateCtrl(currentVal)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a drop box selection in the model and apply it:
//					manualAE sets the manual AE ROI window size, burstLen sets the
//					burst length on the camera and prevController, frequency sets
//					50/60 Hz anti-flicker (also mirrored to UVC on non-Windows).
//
//	ARGUMENTS	:	id - JSON id of the drop box
//					value - Selected value (window size, burst length or "50
//					  Hz"/"60 Hz")
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Dropdown Value Changes
// ----------------------------------------------------------------
function handleDropBoxValueChanged(id, value) {
    for (var i = 0; i < see3camcu84HidProperty.length; i++) {
        var section = see3camcu84HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = value
                    section.children[j].selected     = value
                    break
                }
            }
        }
    }

    if (id === "manualAE") {
        aeWindowSize = value
        see3camcu84Controller.setAutoExpROIMode(See3CAMCU84.MANUAL_ROI, 0, 0, 0, 0, value)
    } else if (id === "burstLen") {
        see3camcu84Controller.setBurstLength(value)
        prevController.setBurstLength(value)
    } else if (id === "frequency") {
        if (value === "50 Hz") {
            see3camcu84Controller.setAntiFlickerMode(See3CAMCU84.MODE_50Hz)
        } else if (value === "60 Hz") {
            see3camcu84Controller.setAntiFlickerMode(See3CAMCU84.MODE_60Hz)
        }
        if (Qt.platform.os !== "windows")
            usbcamRect.setHidAntiFlicker(value)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRightClick(x, y, width, height)
//
//  PURPOSE		:	To set a manual auto-exposure ROI at the point right-clicked
//					on the preview by calling
//					see3camcu84Controller.setAutoExpROIMode() with the cached
//					window size. Ignored unless UVC exposure is Auto.
//
//	ARGUMENTS	:	x - X coordinate of the click on the preview
//					y - Y coordinate of the click on the preview
//					width - Width of the preview area
//					height - Height of the preview area
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Right-Click (manual ROI set from preview)
// ----------------------------------------------------------------
function handleRightClick(x, y, width, height) {
    if (isUvcExposureAuto) {
        see3camcu84Controller.setAutoExpROIMode(See3CAMCU84.MANUAL_ROI, x, y, width, height, aeWindowSize)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getAutoExposureControls()
//
//  PURPOSE		:	To query the auto-exposure ROI mode and window size from the
//					camera via see3camcu84Controller.getAutoExpROIMode(); called
//					by the getAutoExposureControlValues timer after an exposure
//					mode change.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Refresh auto-exposure related controls after mode change
// ----------------------------------------------------------------
function getAutoExposureControls() {
    see3camcu84Controller.getAutoExpROIMode()
}