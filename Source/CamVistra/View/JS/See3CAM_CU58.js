var see3camCU58Hidroperty = [];
var isUvcExposureAuto = false;
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
//					see3camCU58Hidroperty, so the other functions can read and
//					update it.
//
//	ARGUMENTS	:	jsonArray - Array of section objects parsed from the camera's
//					  JSON file
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camCU58Hidroperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the cached JSON property model
//					(see3camCU58Hidroperty) so UsbcamHidSettings.qml can bind it
//					to the HID accordion.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current property model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    
    return see3camCU58Hidroperty;
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
function callSupportFunctions(){
    var changedFields = handleOnExposureModeChange(isUvcExposureAuto);
    triggerUpdateSignal(changedFields)
}
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To start the QML delayedControlsTimer, whose handler calls
//					getDelayedCameraControls() so the See3CAM_CU58 HID values are
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
    // Trigger the QML timer for delayed controls
    delayedControlsTimer.start()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To request all HID control values from the See3CAM_CU58
//					(effect, denoise, Q-factor, exposure compensation, frame rate,
//					AE ROI, burst length, flip, anti-flicker, face detection,
//					flash, serial number and firmware version). Results arrive via
//					controller signals handled in UsbcamHidSettings.qml.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
function getDelayedCameraControls() {
    see3camcu58Controller.getEffectMode()
    see3camcu58Controller.getDenoiseValue()
    see3camcu58Controller.getQFactor()
    see3camcu58Controller.getExposureCompensation()
    see3camcu58Controller.getFrameRateCtrlValue()

     // ----------------------------------------------------------------
    // Immediate controls
    // ----------------------------------------------------------------
  
    see3camcu58Controller.getAutoExpROI()
    see3camcu58Controller.getBurstLength()
    see3camcu58Controller.getFlipMode()
    see3camcu58Controller.getAntiFlickerMode()
    see3camcu58Controller.getFaceDetectMode()
    see3camcu58Controller.getFlashMode()
    see3camcu58Controller.get64BitSerialNumber()
    see3camcu58Controller.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached UI state (exposure auto flag, AE window
//					size, face-detect embed/overlay flags and flip flags) to
//					defaults when the device is closed or switched. The property
//					model itself is kept.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() 
{
   // see3camCU58Hidroperty = []
    isUvcExposureAuto = false;
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
//	ARGUMENTS	:	value - Effect mode value (See3CAMCU58.EFFECT_*) from the
//					  controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Special Effects  (SpecialEffectCU58)
// ----------------------------------------------------------------
function updateEffectMode(value) {
    var changedFields = []
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
        if (group.id === "specialEffect" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if      (child.id === "normalEffect")  child.checked = (value === See3CAMCU58.EFFECT_NORMAL)
                else if (child.id === "blackAndWhite") child.checked = (value === See3CAMCU58.EFFECT_BLACK_WHITE)
                else if (child.id === "grayScale")     child.checked = (value === See3CAMCU58.EFFECT_GREYSCALE)
                else if (child.id === "negative")      child.checked = (value === See3CAMCU58.EFFECT_NEGATIVE)
                else if (child.id === "sketch")        child.checked = (value === See3CAMCU58.EFFECT_SKETCH)
                changedFields.push({ id: child.id, checked: child.checked })
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
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
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
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
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
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
        if (group.id === "imageCapture" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "burstLen") {
                    group.children[j].currentValue = burstLength
                    group.children[j].selected     = burstLength
                    changedFields.push({
                        id:           group.children[j].id,
                        selected:     burstLength
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
//	ARGUMENTS	:	flipMode - Flip mode (See3CAMCU58.HORZ_ONLY, VERT_ONLY,
//					  BOTH_ENABLE or none)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Flip Mode  (FlipModeCU58)
// ----------------------------------------------------------------
function updateFlipMode(flipMode) {
    var changedFields = []
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horizontal") {
                    child.checked    = (flipMode === See3CAMCU58.HORZ_ONLY ||
                                        flipMode === See3CAMCU58.BOTH_ENABLE)
                    isHorizontalFlip = child.checked
                    if (flipMode === See3CAMCU58.BOTH_ENABLE) isVerticalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "vertical") {
                    child.checked  = (flipMode === See3CAMCU58.VERT_ONLY ||
                                      flipMode === See3CAMCU58.BOTH_ENABLE)
                    isVerticalFlip = child.checked
                    if (flipMode === See3CAMCU58.BOTH_ENABLE) isHorizontalFlip = true
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
//  PURPOSE		:	To check the flash mode radio button (disable, strobe or
//					torch) matching the mode read from the camera in the
//					"flashMode" section.
//
//	ARGUMENTS	:	flashMode - Flash mode (See3CAMCU58.DISABLE, STROBE or TORCH)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Flash Mode  (FlashModeCU58)
// ----------------------------------------------------------------
function updateFlashMode(flashMode) {
    var changedFields = []
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
        if (group.id === "flashMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if      (child.id === "disableMode") child.checked = (flashMode === See3CAMCU58.DISABLE)
                else if (child.id === "strobeMode")  child.checked = (flashMode === See3CAMCU58.STROBE)
                else if (child.id === "torchMode")   child.checked = (flashMode === See3CAMCU58.TORCH)
                changedFields.push({ id: child.id, checked: child.checked })
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
//	ARGUMENTS	:	mode - Face detect state (See3CAMCU58.FDEnable / FDDisable)
//					embedData - Embedded data state (See3CAMCU58.EmbedDataEnable
//					  or disable)
//					overlayRect - Overlay rectangle state (See3CAMCU58.RectEnable
//					  or disable)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Face Detection
// ----------------------------------------------------------------
function updateFaceDetectMode(mode, embedData, overlayRect) {
    var changedFields = []
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
        if (group.id === "faceDetection" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "enableFaceDet") {
                    child.checked = (mode === See3CAMCU58.FDEnable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "disableFaceDet") {
                    child.checked = (mode === See3CAMCU58.FDDisable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "embeddedData") {
                    child.enabled         = (mode === See3CAMCU58.FDEnable)
                    child.checked         = (embedData === See3CAMCU58.EmbedDataEnable)
                    isEmbedDataEnabled    = child.checked
                    changedFields.push({
                        id:      child.id,
                        enabled: child.enabled,
                        checked: child.checked
                    })

                } else if (child.id === "overlayRect") {
                    child.enabled        = (mode === See3CAMCU58.FDEnable)
                    child.checked        = (overlayRect === See3CAMCU58.RectEnable)
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
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
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
//	ARGUMENTS	:	flickerMode - Anti-flicker mode (See3CAMCU58.MODE_DISABLE,
//					  MODE_AUTO, MODE_50Hz or MODE_60Hz)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Anti Flicker  (FlickerModeCU58)
// ----------------------------------------------------------------
function updateAntiFlickerMode(flickerMode) {
    var changedFields = []
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "offMode") {
                    child.checked = (flickerMode === See3CAMCU58.MODE_DISABLE)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoMode") {
                    child.checked = (flickerMode === See3CAMCU58.MODE_AUTO)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualMode") {
                    child.checked = (flickerMode === See3CAMCU58.MODE_50Hz ||
                                     flickerMode === See3CAMCU58.MODE_60Hz)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "frequency") {
                    child.enabled      = (flickerMode === See3CAMCU58.MODE_50Hz ||
                                          flickerMode === See3CAMCU58.MODE_60Hz)
                    child.currentValue = (flickerMode === See3CAMCU58.MODE_60Hz) ? "60 Hz" : "50 Hz"
                    child.selected     = (flickerMode === See3CAMCU58.MODE_60Hz) ? "60 Hz" : "50 Hz"
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
//  FUNCTION	:	updateSerialNumber(serialNum)
//
//  PURPOSE		:	To show the 64-bit serial number reported by the controller in
//					the "serialNumber" text field of the "serialNum" section of
//					see3camCU58Hidroperty.
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
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
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
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
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
//  FUNCTION	:	updateRoiAEMode(roiMode, winSize)
//
//  PURPOSE		:	To reflect the auto-exposure ROI mode read from the camera:
//					check full or manual ROI, and in manual mode enable the
//					"manualAE" drop box, select the window size and cache it in
//					aeWindowSize.
//
//	ARGUMENTS	:	roiMode - ROI mode (See3CAMCU58.AE_Full or AE_Manual)
//					winSize - AE window size reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// ROI AE Mode
// ----------------------------------------------------------------
function updateRoiAEMode(roiMode, winSize) {
    var changedFields = []
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
        if (group.id === "roiAE" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "fullROIAE") {
                    child.checked = (roiMode === See3CAMCU58.AE_Full)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualROIAE") {
                    child.checked = (roiMode === See3CAMCU58.AE_Manual)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualAE") {
                    child.enabled = (roiMode === See3CAMCU58.AE_Manual)
                    if (roiMode === See3CAMCU58.AE_Manual) {
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
//  FUNCTION	:	updateFirmwareVersioninUI(firmwareVersion)
//
//  PURPOSE		:	To show the firmware version reported by the controller in the
//					"firmwareVer" text field of the "firmwareVersion" section of
//					see3camCU58Hidroperty.
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
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var group = see3camCU58Hidroperty[i]
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
// Enable / Disable controls based on the exposure mode
// ----------------------------------------------------------------
function handleOnExposureModeChange(mode) {
    // mode: 0 = Manual, 1 = Auto (adjust based on your actual enum values)
    isUvcExposureAuto = mode

    var changedFields = []

    for (var i = 0; i < see3camCU58Hidroperty.length; ++i) {
        var section = see3camCU58Hidroperty[i]

        // ----------------------------------------------------------------
        // ROI Auto-Exposure — disable when Manual, enable when Auto
        // ----------------------------------------------------------------
        if (section.id === "roiAE") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "roiAE", enabled: isUvcExposureAuto })
        
            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
        
                    if (child.id === "manualAE") {
                        // ----------------------------------------------------------------
                        // manualAE dropdown:
                        // enabled ONLY if both conditions are true:
                        //   1. UVC exposure is Auto (isUvcExposureAuto)
                        //   2. manualROIAE radio button is currently checked
                        // ----------------------------------------------------------------
                        var isManualROIChecked = false
        
                        // Check current state of manualROIAE radio button
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
                        // All other children follow isUvcExposureAuto directly
                        child.enabled = isUvcExposureAuto
                        changedFields.push({ id: child.id, enabled: isUvcExposureAuto })
                    }
                }
            }
        }

        // ----------------------------------------------------------------
        // Exposure Compensation — disable when Manual, enable when Auto
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
function setExposureMode(mode){
    // mode: 0 = Manual, 1 = Auto (adjust based on your actual enum values)
    isUvcExposureAuto = mode

    var changedFields = handleOnExposureModeChange(isUvcExposureAuto);
    triggerUpdateSignal(changedFields)

    getAutoExposureControlValues.start()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle a radio button click: update the checked state in
//					the model (unchecking the rest of the group) and, when
//					checked, send the matching command to see3camcu58Controller
//					(effect, AE ROI, flash, anti-flicker or face detection), also
//					enabling dependent controls.
//
//	ARGUMENTS	:	identification - Radio group name from JSON (specialEffects,
//					  roiAEMode, flashModes, faceDetectionMode or antiFlickerMode)
//					id - JSON id of the clicked radio button
//					checked - New checked state
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Radio button changes
// ----------------------------------------------------------------
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []

    // Map identification → parent group id
    var identificationToGroupId = {
        "specialEffects":    "specialEffect",
        "roiAEMode":         "roiAE",
        "flashModes":        "flashMode",
        "faceDetectionMode": "faceDetection",
        "antiFlickerMode":   "antiFlicker"
    }

    // Resolve parent group id from identification
    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    // Now find the section using resolved groupId
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var section = see3camCU58Hidroperty[i]

        if (section.id === groupId && section.children) {

            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]

                if (radio.id === id) {
                    // ===== SELECTED RADIO BUTTON =====
                    radio.checked  = checked

                    changedFields.push({
                        id:       radio.id,
                        checked:  checked
                    })

                    // ----------------------------------------------------------------
                    // Call controller based on groupId + id
                    // ----------------------------------------------------------------
                    if (checked) {
                        if (groupId === "specialEffect") {
                            var effectMap = {
                                "normalEffect":  See3CAMCU58.EFFECT_NORMAL,
                                "blackAndWhite": See3CAMCU58.EFFECT_BLACK_WHITE,
                                "grayScale":     See3CAMCU58.EFFECT_GREYSCALE,
                                "negative":      See3CAMCU58.EFFECT_NEGATIVE,
                                "sketch":        See3CAMCU58.EFFECT_SKETCH
                            }
                            if (effectMap[id] !== undefined)
                                see3camcu58Controller.setEffectMode(effectMap[id])

                        } 
                        else if (groupId === "roiAE") {
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
                                "fullROIAE": See3CAMCU58.AE_Full,
                                "manualROIAE":   See3CAMCU58.AE_Manual
                            }
                            if (roiAEMap[id] !== undefined)
                                if(id === "manualROIAE"){
                                    see3camcu58Controller.setAutoExpROI(roiAEMap[id], 0, 0, 0, 0, aeWinSize) // default to 1x1 centered when switching to manual
                                } else if (id === "fullROIAE"){
                                    see3camcu58Controller.setAutoExpROI(roiAEMap[id], 0, 0, 0, 0, 0)
                                }
                            

                        } else if (groupId === "flashMode") {
                            var flashMap = {
                                "disableMode": See3CAMCU58.DISABLE,
                                "strobeMode":  See3CAMCU58.STROBE,
                                "torchMode":   See3CAMCU58.TORCH
                            }
                            if (flashMap[id] !== undefined)
                                see3camcu58Controller.setFlashMode(flashMap[id])

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
                            var flickerMap = {
                                "offMode":    See3CAMCU58.MODE_DISABLE,
                                "autoMode":   See3CAMCU58.MODE_AUTO,
                                "manualMode": See3CAMCU58.MODE_50Hz
                            }
                            if (flickerMap[id] !== undefined)
                                if( id == "manualMode"){
                                    if (frequency === "60 Hz") {
                                        see3camcu58Controller.setAntiFlickerMode(See3CAMCU58.MODE_60Hz)
                                    } else if (frequency === "50 Hz") {
                                        see3camcu58Controller.setAntiFlickerMode(See3CAMCU58.MODE_50Hz)
                                    }
                                } else {
                                    see3camcu58Controller.setAntiFlickerMode(flickerMap[id])
                                }
                        } else if (groupId === "faceDetection") {
                            var isFaceDetectEnabled = (id === "enableFaceDet")
                            //var isEmbedDataEnable = false
                            //var isOverlayRectEnable = false
                        
                            // Enable/disable embeddedData and overlayRect checkboxes
                            for (var k = 0; k < section.children.length; k++) {
                                var faceChild = section.children[k]
                        
                                if (faceChild.id === "embeddedData") {
                                    faceChild.enabled = isFaceDetectEnabled
                                   // isEmbedDataEnable = faceChild.checked
                                    changedFields.push({
                                        id:      "embeddedData",
                                        enabled: isFaceDetectEnabled
                                    })
                                } else if (faceChild.id === "overlayRect") {
                                    faceChild.enabled = isFaceDetectEnabled
                                   // isOverlayRectEnable = faceChild.checked
                                    changedFields.push({
                                        id:      "overlayRect",
                                        enabled: isFaceDetectEnabled
                                    })
                                }
                            }
                        
                            // Call controller
                            see3camcu58Controller.setFaceDetectRect(
                                isFaceDetectEnabled,
                                isEmbedDataEnabled,   // embedData default — actual value comes from checkbox state
                                isFaceDetectEnabled    // overlayRect default — actual value comes from checkbox state
                            )
                        }
                    }

                } else if (radio.identification === identification) {
                    // ===== UNCHECK ALL OTHER RADIO BUTTONS IN SAME GROUP =====
                    radio.checked  = false

                    changedFields.push({
                        id:       radio.id,
                        checked:  false
                    })
                }
            }

            break  // found section, stop outer loop
        }
    }

    return changedFields
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
function handleButtonClick(id){

    if (id === "setExpComp") {
        // ----------------------------------------------------------------
        // Find the expCompValue textbox in the JSON and read its text
        // ----------------------------------------------------------------
        var expCompText = ""
    
        for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
            var section = see3camCU58Hidroperty[i]
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
    
        // Validate and call controller
        if (expCompText === "" || expCompText === undefined) {
            console.log("Exposure compensation value is empty")
            return
        }
    
        var expCompValue = parseInt(expCompText)
    
        if (isNaN(expCompValue)) {
            console.log("Invalid exposure compensation value:", expCompText)
            return
        }

        see3camcu58Controller.setExposureCompensation(expCompValue)
    } else if ( id === "updateDefault"){
        see3camcu58Controller.setToDefault()
        getCameraControls()
    } 
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, text)
//
//  PURPOSE		:	To keep see3camCU58Hidroperty in sync when the user edits a
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
// Handle Text box value change
// ----------------------------------------------------------------
function updateTextBoxField(id, text){
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var section = see3camCU58Hidroperty[i]
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

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider's new value in the model and apply it on the
//					camera: denoise -> setDenoiseValue(), qFactorVal ->
//					setQFactor(), frameRate -> setFrameRateCtrlValue().
//
//	ARGUMENTS	:	id - JSON id of the slider
//					currentVal - New slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Slider Value Changes
// ----------------------------------------------------------------
function updateSliderValue(id,currentVal){
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var section = see3camCU58Hidroperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = currentVal   // keep JSON in sync
                   break
                }
            }
        }
    }
    if(id === "denoise"){
        see3camcu58Controller.setDenoiseValue(currentVal)
    } else if(id === "qFactorVal"){
        see3camcu58Controller.setQFactor(currentVal)
    } else if(id === "frameRate"){
        see3camcu58Controller.setFrameRateCtrlValue(currentVal)
    } 
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a drop box selection in the model and apply it:
//					manualAE sets the manual AE ROI window size, burstLen sets the
//					burst length on the camera and prevController, frequency sets
//					50/60 Hz anti-flicker.
//
//	ARGUMENTS	:	id - JSON id of the drop box
//					value - Selected value (window size, burst length or "50
//					  Hz"/"60 Hz")
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value){
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var section = see3camCU58Hidroperty[i]
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
    if(id === "manualAE"){
        aeWindowSize = value
        see3camcu58Controller.setAutoExpROI(See3CAMCU58.AE_Manual, 0, 0, 0, 0, value)
    } else if(id === "burstLen"){
        see3camcu58Controller.setBurstLength(value)
        prevController.setBurstLength(value)
    } else if(id === "frequency"){
        if(value == "50 Hz"){
            see3camcu58Controller.setAntiFlickerMode(See3CAMCU58.MODE_50Hz)
        } else if (value == "60 Hz"){
            see3camcu58Controller.setAntiFlickerMode(See3CAMCU58.MODE_60Hz)
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRightClick(x, y, width, height)
//
//  PURPOSE		:	To set a manual auto-exposure ROI at the point right-clicked
//					on the preview by calling
//					see3camcu58Controller.setAutoExpROI() with the cached window
//					size. Ignored unless UVC exposure is Auto.
//
//	ARGUMENTS	:	x - X coordinate of the click on the preview
//					y - Y coordinate of the click on the preview
//					width - Width of the preview area
//					height - Height of the preview area
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleRightClick(x, y, width, height){
    if(isUvcExposureAuto){
        see3camcu58Controller.setAutoExpROI(See3CAMCU58.AE_Manual, x, y, width, height, aeWindowSize)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box state in the model and apply it:
//					embeddedData / overlayRect call setFaceDetectRect() with the
//					cached face-detect flags, horizontal / vertical call
//					setFlipMode() with the cached flip flags.
//
//	ARGUMENTS	:	id - JSON id of the check box
//					checked - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked){
    for (var i = 0; i < see3camCU58Hidroperty.length; i++) {
        var section = see3camCU58Hidroperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].checked = checked   // keep JSON in sync
                   break
                }
            }
        }
    }
    if(id === "embeddedData"){
        isEmbedDataEnabled = checked
        see3camcu58Controller.setFaceDetectRect(
            true,   // enable/disable determined by overlayRect state
            checked,    // embedData follows checkbox state
            isOverlayRectEnabled    // overlayRect follows its own checkbox state
        )
    } else if(id === "overlayRect"){
        isOverlayRectEnabled = checked
        see3camcu58Controller.setFaceDetectRect(
            true,   // enable/disable determined by embeddedData state
            isEmbedDataEnabled,    // embedData follows its own checkbox state
            checked    // overlayRect follows checkbox state
        )
    } else if (id === "horizontal"){
        isHorizontalFlip = checked
        see3camcu58Controller.setFlipMode(checked, isVerticalFlip)
    } else if (id === "vertical"){
        isVerticalFlip = checked
        see3camcu58Controller.setFlipMode(isHorizontalFlip, checked)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getAutoExposureControls()
//
//  PURPOSE		:	To query the auto-exposure ROI mode and window size from the
//					camera via see3camcu58Controller.getAutoExpROI(); called by
//					the getAutoExposureControlValues timer after an exposure mode
//					change.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getAutoExposureControls(){  
    see3camcu58Controller.getAutoExpROI()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getexposureCompFrameRateCtrl()
//
//  PURPOSE		:	To re-read the exposure compensation and frame rate control
//					values from the camera; called by the
//					getexposureCompFrameRateCtrlTimer in UsbcamHidSettings.qml.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getexposureCompFrameRateCtrl() {
    see3camcu58Controller.getExposureCompensation()
    see3camcu58Controller.getFrameRateCtrlValue()
}