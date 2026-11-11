var densiCAMHidProperty = [];
var isUvcExposureAuto = false;
var isVerticalFlip = false;
var isHorizontalFlip = false;

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To store the HID extension settings JSON array (read by
//					prevController) as the module's model (densiCAMHidProperty),
//					which all update/handle functions then edit in place.
//
//	ARGUMENTS	:	jsonArray - array of control groups (each with id and
//					            children) describing the HID settings UI
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    densiCAMHidProperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDensiCAMHidModelData()
//
//  PURPOSE		:	To return the current DensiCAM HID settings model so
//					UsbcamHidSettings.qml can rebind its usbcamHidProperty to
//					the latest values.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the densiCAMHidProperty JSON model
///////////////////////////////////////////////////////////////////////////
function getDensiCAMHidModelData() {
    return densiCAMHidProperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	callSupportFunctions()
//
//  PURPOSE		:	To re-apply the exposure-mode dependent enable state
//					(exposureTime slider enabled only in manual exposure) using
//					the cached isUvcExposureAuto flag and push the changes to
//					the UI via triggerUpdateSignal().
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
//  PURPOSE		:	To start reading all DensiCAM control values by starting the
//					QML delayedControlsTimer (500 ms, single shot), which then
//					calls getDelayedCameraControls().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getCameraControls() {
    delayedControlsTimer.start()
}

// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To reset the cached flags (clearData) and request every
//					DensiCAM control value via densicamController (LED, scene
//					mode, denoise, pixel target, brightness, contrast,
//					saturation, sharpness, gamma, gain, auto/manual exposure,
//					manual/auto white balance, image capture mode, orientation,
//					unique ID, firmware version). Values come back through the
//					controller's signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    clearData();
    densicamController.getLED()
    densicamController.getSceneMode()
    densicamController.getDenoiseValue()
    densicamController.getPixelTargetValue()
    densicamController.getBrightness()
    densicamController.getContrast()
    densicamController.getSaturation()
    densicamController.getSharpness()
    densicamController.getGamma()
    densicamController.getGain()
    densicamController.getAutoExposure()
    densicamController.getManualExposure()
    densicamController.getManualWhiteBalance()
    densicamController.getAutoWhiteBalance()
    densicamController.getImageCaptureMode()
    densicamController.getOrientation()
    densicamController.getUniqueID()
    densicamController.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached state flags (UVC auto exposure,
//					horizontal / vertical flip) to false.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    isUvcExposureAuto = false;
    isVerticalFlip = false;
    isHorizontalFlip = false;
}

// ================================================================
// UPDATE FUNCTIONS — called from Connections block
// Each returns a changedFields array for triggerUpdateSignal()
// ================================================================

// ----------------------------------------------------------------
// Firmware Version
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFirmwareVersioninUI(firmwareVersion)
//
//  PURPOSE		:	To show the firmware version read from the camera in the
//					firmwareVer field of the firmwareVersion group.
//
//	ARGUMENTS	:	firmwareVersion - firmware version string reported by
//					                  densicamController
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFirmwareVersioninUI(firmwareVersion) {
    var changedFields = []
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "firmwareVersion" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "firmwareVer") {
                    group.children[j].text = firmwareVersion.toString()
                    changedFields.push({ id: group.children[j].id, text: group.children[j].text })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Unique ID  (shown in serialNum group)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateUniqueID(uniqueID)
//
//  PURPOSE		:	To show the camera's unique ID in the serialNumber field of
//					the serialNum group.
//
//	ARGUMENTS	:	uniqueID - unique ID string reported by densicamController
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateUniqueID(uniqueID) {
    var changedFields = []
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "serialNum" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "serialNumber") {
                    group.children[j].text = uniqueID
                    changedFields.push({ id: group.children[j].id, text: uniqueID })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// LED  (ledOn / ledOff radio buttons)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateLED(value, status)
//
//  PURPOSE		:	To check the ledOn / ledOff radio button of the led group
//					from the LED state read from the camera and enable both
//					unless the status is DensiCAM.DISABLE.
//
//	ARGUMENTS	:	value - LED state - 1 = on, 2 = off
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateLED(value, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "led" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "ledOn") {
                    child.checked = (value === 1)
                    child.enabled = isEnabled
                    changedFields.push({ id: child.id, checked: child.checked, enabled: child.enabled })
                } else if (child.id === "ledOff") {
                    child.checked = (value === 2)
                    child.enabled = isEnabled
                    changedFields.push({ id: child.id, checked: child.checked, enabled: child.enabled })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Scene Mode  (intraOralMode / faceMode radio buttons)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSceneMode(value, status)
//
//  PURPOSE		:	To check the intraOralMode / faceMode radio button of the
//					sceneMode group from the scene mode read from the camera and
//					enable both unless the status is DensiCAM.DISABLE.
//
//	ARGUMENTS	:	value - scene mode (DensiCAM.SCENE_INTRAORAL or SCENE_FACE)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSceneMode(value, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "sceneMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "intraOralMode") {
                    child.checked = (value === DensiCAM.SCENE_INTRAORAL)
                    child.enabled = isEnabled
                    changedFields.push({ id: child.id, checked: child.checked, enabled: child.enabled })
                } else if (child.id === "faceMode") {
                    child.checked = (value === DensiCAM.SCENE_FACE)
                    child.enabled = isEnabled
                    changedFields.push({ id: child.id, checked: child.checked, enabled: child.enabled })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Image Capture Mode  (buttonSw / twainOrCamVistra radio buttons)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateImageCapture(value, status)
//
//  PURPOSE		:	To check the buttonSw / twainOrCamVistra radio button of the
//					imageCapture group from the capture mode read from the
//					camera and enable both unless the status is
//					DensiCAM.DISABLE.
//
//	ARGUMENTS	:	value - capture mode (DensiCAM.CAPTURE_BUTTON_SOFTWARE or
//					        CAPTURE_TWAIN_CAMVISTRA)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateImageCapture(value, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "imageCapture" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "buttonSw") {
                    child.checked = (value === DensiCAM.CAPTURE_BUTTON_SOFTWARE)
                    child.enabled = isEnabled
                    changedFields.push({ id: child.id, checked: child.checked, enabled: child.enabled })
                } else if (child.id === "twainOrCamVistra") {
                    child.checked = (value === DensiCAM.CAPTURE_TWAIN_CAMVISTRA)
                    child.enabled = isEnabled
                    changedFields.push({ id: child.id, checked: child.checked, enabled: child.enabled })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Flip Mode  (horizontal / vertical checkboxes)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlipMode(flipMode, status)
//
//  PURPOSE		:	To set the horizontal / vertical check boxes of the
//					flipControl group from the orientation read from the camera,
//					cache them in isHorizontalFlip / isVerticalFlip and enable
//					them unless the status is DensiCAM.DISABLE.
//
//	ARGUMENTS	:	flipMode - orientation - 0 = none, 1 = horizontal, 2 =
//					           vertical, 3 = both
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFlipMode(flipMode, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horizontal") {
                    child.checked = (flipMode === 1 || flipMode === 3)
                    child.enabled = isEnabled
                    isHorizontalFlip = child.checked
                    changedFields.push({ id: child.id, checked: child.checked, enabled: child.enabled })
                } else if (child.id === "vertical") {
                    child.checked = (flipMode === 2 || flipMode === 3)
                    child.enabled = isEnabled
                    isVerticalFlip = child.checked
                    changedFields.push({ id: child.id, checked: child.checked, enabled: child.enabled })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Denoise  (denoise slider, group id: denoiseStrength)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDenoiseValue(value, status)
//
//  PURPOSE		:	To set the denoise slider of the denoiseStrength group to
//					the value read from the camera and enable it unless the
//					status is DensiCAM.DISABLE.
//
//	ARGUMENTS	:	value - denoise strength reported by densicamController
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateDenoiseValue(value, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "denoiseStrength" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "denoise") {
                    group.children[j].currentValue = value
                    group.children[j].enabled = isEnabled
                    changedFields.push({ id: group.children[j].id, currentValue: value, enabled: isEnabled })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Pixel Target Value  (pixelTargetVal slider, group id: pixelTarget)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updatePixelTargetValue(value, status)
//
//  PURPOSE		:	To set the pixelTargetVal slider of the pixelTarget group to
//					the value read from the camera and enable it unless the
//					status is DensiCAM.DISABLE.
//
//	ARGUMENTS	:	value - pixel target value reported by densicamController
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updatePixelTargetValue(value, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "pixelTarget" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "pixelTargetVal") {
                    group.children[j].currentValue = value
                    group.children[j].enabled = isEnabled
                    changedFields.push({ id: group.children[j].id, currentValue: value, enabled: isEnabled })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Brightness  (brightness_s slider, group id: brightness)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBrightness(minVal, maxVal, defVal, curVal, resVal, status)
//
//  PURPOSE		:	To apply the brightness range read from the camera to the
//					brightness_s slider of the brightness group: sets min, max
//					and current value and enables it unless the status is
//					DensiCAM.DISABLE.
//
//	ARGUMENTS	:	minVal - minimum value
//					maxVal - maximum value
//					defVal - default value (not used)
//					curVal - current value
//					resVal - step / resolution (not used)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateBrightness(minVal, maxVal, defVal, curVal, resVal, status) {
    var changedFields = []
    var isEnabled = (status != DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "brightness" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "brightness_s") {
                    group.children[j].min = minVal
                    group.children[j].max = maxVal
                    group.children[j].currentValue = curVal
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        min: minVal,
                        max: maxVal,
                        currentValue: curVal,
                        enabled: isEnabled
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Contrast  (contrast_s slider, group id: contrast)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateContrast(minVal, maxVal, defVal, curVal, resVal, status)
//
//  PURPOSE		:	To apply the contrast range read from the camera to the
//					contrast_s slider of the contrast group: sets min, max and
//					current value and enables it unless the status is
//					DensiCAM.DISABLE.
//
//	ARGUMENTS	:	minVal - minimum value
//					maxVal - maximum value
//					defVal - default value (not used)
//					curVal - current value
//					resVal - step / resolution (not used)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateContrast(minVal, maxVal, defVal, curVal, resVal, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "contrast" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "contrast_s") {
                    group.children[j].min = minVal
                    group.children[j].max = maxVal
                    group.children[j].currentValue = curVal
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        min: minVal,
                        max: maxVal,
                        currentValue: curVal,
                        enabled: isEnabled
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Saturation  (saturation slider, group id: c_saturation)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSaturation(minVal, maxVal, defVal, curVal, resVal, status)
//
//  PURPOSE		:	To apply the saturation range read from the camera to the
//					saturation slider of the c_saturation group: sets min, max
//					and current value and enables it unless the status is
//					DensiCAM.DISABLE.
//
//	ARGUMENTS	:	minVal - minimum value
//					maxVal - maximum value
//					defVal - default value (not used)
//					curVal - current value
//					resVal - step / resolution (not used)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSaturation(minVal, maxVal, defVal, curVal, resVal, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "c_saturation" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "saturation") {
                    group.children[j].min = minVal
                    group.children[j].max = maxVal
                    group.children[j].currentValue = curVal
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        min: minVal,
                        max: maxVal,
                        currentValue: curVal,
                        enabled: isEnabled
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Sharpness  (sharpness_s slider, group id: sharpness)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSharpness(minVal, maxVal, defVal, curVal, resVal, status)
//
//  PURPOSE		:	To apply the sharpness range read from the camera to the
//					sharpness_s slider of the sharpness group: sets min, max and
//					current value and enables it unless the status is
//					DensiCAM.DISABLE.
//
//	ARGUMENTS	:	minVal - minimum value
//					maxVal - maximum value
//					defVal - default value (not used)
//					curVal - current value
//					resVal - step / resolution (not used)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSharpness(minVal, maxVal, defVal, curVal, resVal, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "sharpness" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "sharpness_s") {
                    group.children[j].min = minVal
                    group.children[j].max = maxVal
                    group.children[j].currentValue = curVal
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        min: minVal,
                        max: maxVal,
                        currentValue: curVal,
                        enabled: isEnabled
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Gamma  (gamma_s slider, group id: gamma)  — 16-bit
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGamma(minVal, maxVal, defVal, curVal, resVal, status)
//
//  PURPOSE		:	To apply the gamma range read from the camera to the gamma_s
//					slider of the gamma group: sets min, max and current value
//					and enables it unless the status is DensiCAM.DISABLE.
//
//	ARGUMENTS	:	minVal - minimum value
//					maxVal - maximum value
//					defVal - default value (not used)
//					curVal - current value
//					resVal - step / resolution (not used)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateGamma(minVal, maxVal, defVal, curVal, resVal, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "gamma" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "gamma_s") {
                    group.children[j].min = minVal
                    group.children[j].max = maxVal
                    group.children[j].currentValue = curVal
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        min: minVal,
                        max: maxVal,
                        currentValue: curVal,
                        enabled: isEnabled
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Gain  (gain_s slider, group id: gain)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGain(minVal, maxVal, defVal, curVal, resVal, status)
//
//  PURPOSE		:	To apply the gain range read from the camera to the gain_s
//					slider of the gain group: sets min, max and current value
//					and enables it unless the status is DensiCAM.DISABLE.
//
//	ARGUMENTS	:	minVal - minimum value
//					maxVal - maximum value
//					defVal - default value (not used)
//					curVal - current value
//					resVal - step / resolution (not used)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateGain(minVal, maxVal, defVal, curVal, resVal, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "gain" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "gain_s") {
                    group.children[j].min = minVal
                    group.children[j].max = maxVal
                    group.children[j].currentValue = curVal
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        min: minVal,
                        max: maxVal,
                        currentValue: curVal,
                        enabled: isEnabled
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Auto Exposure  (group id: exposure → exposureMode dropBox)
//   value: 1 = AUTO, 0 = MANUAL
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAutoExposure(value, status)
//
//  PURPOSE		:	To reflect the exposure mode read from the camera: caches it
//					in isUvcExposureAuto, selects "AUTO" / "MANUAL" in the
//					exposureMode drop-down (enabled unless status is
//					DensiCAM.DISABLE) and appends the exposureTime enable change
//					from handleOnExposureModeChange().
//
//	ARGUMENTS	:	value - exposure mode - 1 = AUTO, 0 = MANUAL
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAutoExposure(value, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    isUvcExposureAuto = (value === 1)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "exposure" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "exposureMode") {
                    group.children[j].selected = isUvcExposureAuto ? "AUTO" : "MANUAL"
                    group.children[j].currentValue = isUvcExposureAuto ? "AUTO" : "MANUAL"
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        selected: group.children[j].selected,
                        currentValue: group.children[j].currentValue,
                        enabled: isEnabled
                    })
                }
            }
            break
        }
    }
    var modeFields = handleOnExposureModeChange(isUvcExposureAuto)
    for (var k = 0; k < modeFields.length; k++) changedFields.push(modeFields[k])
    return changedFields
}

// ----------------------------------------------------------------
// Manual Exposure  (exposureTime slider, group id: exposure)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateManualExposure(minVal, maxVal, defVal, curVal, resVal, status)
//
//  PURPOSE		:	To apply the manual exposure range read from the camera to
//					the exposureTime slider of the exposure group: sets min, max
//					and current value and enables it only when not disabled and
//					exposure is manual.
//
//	ARGUMENTS	:	minVal - minimum value
//					maxVal - maximum value
//					defVal - default value (not used)
//					curVal - current value
//					resVal - step / resolution (not used)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateManualExposure(minVal, maxVal, defVal, curVal, resVal, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "exposure" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "exposureTime") {
                    group.children[j].min = minVal
                    group.children[j].max = maxVal
                    group.children[j].currentValue = curVal
                    group.children[j].enabled = isEnabled && !isUvcExposureAuto
                    changedFields.push({
                        id: group.children[j].id,
                        min: minVal,
                        max: maxVal,
                        currentValue: curVal,
                        enabled: isEnabled && !isUvcExposureAuto
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Auto White Balance  (group id: whiteBalance → wbMode dropBox)
//   value: 1 = AUTO, 0 = MANUAL
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAutoWhiteBalance(value, status)
//
//  PURPOSE		:	To reflect the white balance mode read from the camera:
//					selects "AUTO" / "MANUAL" in the wbMode drop-down (enabled
//					unless status is DensiCAM.DISABLE) and enables the wbValue
//					slider only in manual mode.
//
//	ARGUMENTS	:	value - white balance mode - 1 = AUTO, 0 = MANUAL
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAutoWhiteBalance(value, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "whiteBalance" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "wbMode") {
                    var isAutoWB = (value === 1)
                    group.children[j].selected = isAutoWB ? "AUTO" : "MANUAL"
                    group.children[j].currentValue = isAutoWB ? "AUTO" : "MANUAL"
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        selected: group.children[j].selected,
                        currentValue: group.children[j].currentValue,
                        enabled: isEnabled
                    })
                } else if (group.children[j].id === "wbValue") {
                    // Manual WB slider: enable only in MANUAL mode and not disabled
                    group.children[j].enabled = isEnabled && (value === 0)
                    changedFields.push({
                        id: group.children[j].id,
                        enabled: group.children[j].enabled
                    })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Manual White Balance  (wbValue slider, group id: whiteBalance)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateManualWhiteBalance(minVal, maxVal, defVal, curVal, resVal, status)
//
//  PURPOSE		:	To apply the manual white balance range read from the camera
//					to the wbValue slider of the whiteBalance group: sets min,
//					max and current value and enables it unless the status is
//					DensiCAM.DISABLE.
//
//	ARGUMENTS	:	minVal - minimum value
//					maxVal - maximum value
//					defVal - default value (not used)
//					curVal - current value
//					resVal - step / resolution (not used)
//					status - control status from the camera; the control is
//					         disabled when it equals DensiCAM.DISABLE
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateManualWhiteBalance(minVal, maxVal, defVal, curVal, resVal, status) {
    var changedFields = []
    var isEnabled = (status !== DensiCAM.DISABLE)
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]
        if (group.id === "whiteBalance" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "wbValue") {
                    group.children[j].min = minVal
                    group.children[j].max = maxVal
                    group.children[j].currentValue = curVal
                    group.children[j].enabled = isEnabled
                    changedFields.push({
                        id: group.children[j].id,
                        min: minVal,
                        max: maxVal,
                        currentValue: curVal,
                        enabled: isEnabled
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

// ================================================================
// EXPOSURE MODE ENABLE / DISABLE
// isAuto: true = AUTO, false = MANUAL
// exposureTime slider is enabled only in MANUAL mode
// ================================================================
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleOnExposureModeChange(isAuto)
//
//  PURPOSE		:	To enable the exposureTime slider of the exposure group only
//					in manual exposure and cache the mode in isUvcExposureAuto.
//
//	ARGUMENTS	:	isAuto - true = AUTO exposure, false = MANUAL
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function handleOnExposureModeChange(isAuto) {
    isUvcExposureAuto = isAuto
    var changedFields = []

    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var section = densiCAMHidProperty[i]

        // exposureTime slider — enable only in MANUAL mode
        if (section.id === "exposure") {
            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
                    if (child.id === "exposureTime") {
                        child.enabled = !isUvcExposureAuto
                        changedFields.push({ id: child.id, enabled: child.enabled })
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
//  PURPOSE		:	To handle a UVC exposure mode change: updates the
//					exposureTime slider enable state, pushes it via
//					triggerUpdateSignal() and sends the mode to the camera with
//					densicamController.setAutoExposure(1 / 0).
//
//	ARGUMENTS	:	mode - exposure mode - true/1 = Auto, false/0 = Manual
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setExposureMode(mode) {
    isUvcExposureAuto = mode
    var changedFields = handleOnExposureModeChange(isUvcExposureAuto)
    triggerUpdateSignal(changedFields)
    densicamController.setAutoExposure(isUvcExposureAuto ? 1 : 0)
}

// ================================================================
// HANDLE RADIO BUTTON CHANGES
// ================================================================
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle a radio button toggle: checks it and unchecks the
//					rest of its group in the model and, when checked, calls
//					densicamController - setLED (1 = on, 2 = off), setSceneMode
//					(then re-reads all controls via getDelayedCameraControls) or
//					setImageCaptureMode.
//
//	ARGUMENTS	:	identification - radio group identification ("ledMode",
//					                 "sceneModes" or "captureMode")
//					id - id of the radio button that changed
//					checked - new checked state of that radio button
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []

    var identificationToGroupId = {
        "ledMode": "led",
        "sceneModes": "sceneMode",
        "captureMode": "imageCapture"
    }

    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var section = densiCAMHidProperty[i]

        if (section.id === groupId && section.children) {
            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]

                if (radio.id === id) {
                    // Selected radio button
                    radio.checked = checked
                    changedFields.push({ id: radio.id, checked: checked })

                    if (checked) {
                        if (groupId === "led") {
                            densicamController.setLED(id === "ledOn" ? 1 : 2)

                        } else if (groupId === "sceneMode") {
                            var sceneMap = {
                                "intraOralMode": DensiCAM.SCENE_INTRAORAL,
                                "faceMode": DensiCAM.SCENE_FACE
                            }
                            if (sceneMap[id] !== undefined)
                                densicamController.setSceneMode(sceneMap[id])
                                getDelayedCameraControls()
                        } else if (groupId === "imageCapture") {
                            var sceneMap = {
                                "buttonSw": DensiCAM.CAPTURE_BUTTON_SOFTWARE,
                                "twainOrCamVistra": DensiCAM.CAPTURE_TWAIN_CAMVISTRA
                            }
                            if (sceneMap[id] !== undefined)
                                densicamController.setImageCaptureMode(sceneMap[id])

                        }
                    }

                } else if (radio.identification === identification) {
                    // Uncheck all other radio buttons in the same group
                    radio.checked = false
                    changedFields.push({ id: radio.id, checked: false })
                }
            }
            break
        }
    }

    return changedFields
}

// ================================================================
// HANDLE BUTTON CLICKS
// ================================================================
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle HID button clicks: updateDefault calls
//					restoreDefaults() and re-reads all controls; saveConfig
//					calls saveConfiguration().
//
//	ARGUMENTS	:	id - id of the clicked button
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {
    if (id === "updateDefault") {
        densicamController.restoreDefaults()
        getCameraControls()
    } else if (id === "saveConfig") {
        densicamController.saveConfiguration()
    }
}

// ================================================================
// HANDLE SLIDER VALUE CHANGES
// ================================================================
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider change in the model (returning early if
//					the value is unchanged) and send it to the camera through
//					the matching densicamController setter (denoise, pixel
//					target, brightness, contrast, saturation, sharpness, gamma,
//					gain, manual exposure, manual white balance).
//
//	ARGUMENTS	:	id - id of the slider control
//					currentVal - new slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id, currentVal) {
    // Keep JSON in sync
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var section = densiCAMHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].currentValue == currentVal && section.children[j].id === id) {
                    return
                }
                if (section.children[j].id === id) {
                    section.children[j].currentValue = currentVal
                    break
                }
            }
        }
    }

    if (id === "denoise") {
        densicamController.setDenoiseValue(currentVal)
    } else if (id === "pixelTargetVal") {
        densicamController.setPixelTargetValue(currentVal)
    } else if (id === "brightness_s") {
        densicamController.setBrightness(currentVal)
    } else if (id === "contrast_s") {
        densicamController.setContrast(currentVal)
    } else if (id === "saturation") {
        densicamController.setSaturation(currentVal)
    } else if (id === "sharpness_s") {
        densicamController.setSharpness(currentVal)
    } else if (id === "gamma_s") {
        densicamController.setGamma(currentVal)
    } else if (id === "gain_s") {
        densicamController.setGain(currentVal)
    } else if (id === "exposureTime") {
        densicamController.setManualExposure(currentVal)
    } else if (id === "wbValue") {
        densicamController.setManualWhiteBalance(currentVal)
    }
}

// ================================================================
// HANDLE DROPBOX VALUE CHANGES
// ================================================================
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a drop-down change in the model and apply it:
//					exposureMode calls setAutoExposure() and updates the
//					exposureTime enable state; wbMode calls
//					setAutoWhiteBalance() and enables the wbValue slider only in
//					manual mode. UI changes are pushed via
//					triggerUpdateSignal().
//
//	ARGUMENTS	:	id - id of the drop-down control
//					value - selected value ("AUTO" / "MANUAL")
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value) {
    // Keep JSON in sync
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var section = densiCAMHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = value
                    section.children[j].selected = value
                    break
                }
            }
        }
    }

    if (id === "exposureMode") {
        var isAuto = (value === "AUTO")
        isUvcExposureAuto = isAuto
        densicamController.setAutoExposure(isAuto ? 1 : 0)
        var changedFields = handleOnExposureModeChange(isAuto)
        triggerUpdateSignal(changedFields)

    } else if (id === "wbMode") {
        var isAutoWB = (value === "AUTO")
        densicamController.setAutoWhiteBalance(isAutoWB ? 1 : 0)
        // Enable/disable manual WB slider
        var changedFields = []
        for (var i = 0; i < densiCAMHidProperty.length; i++) {
            var section = densiCAMHidProperty[i]
            if (section.id === "whiteBalance" && section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    if (section.children[j].id === "wbValue") {
                        section.children[j].enabled = !isAutoWB
                        changedFields.push({ id: "wbValue", enabled: !isAutoWB })
                    }
                }
                break
            }
        }
        triggerUpdateSignal(changedFields)
    }
}

// ================================================================
// HANDLE CHECKBOX VALUE CHANGES
// ================================================================
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a flip check box change in the model and send the
//					combined orientation to the camera with
//					densicamController.setOrientation() (0 = none, 1 =
//					horizontal, 2 = vertical, 3 = both).
//
//	ARGUMENTS	:	id - id of the check box ("horizontal" or "vertical")
//					checked - new checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked) {
    // Keep JSON in sync
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var section = densiCAMHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].checked = checked
                    break
                }
            }
        }
    }

    if (id === "horizontal") {
        isHorizontalFlip = checked
        densicamController.setOrientation(
            isHorizontalFlip && isVerticalFlip ? 3 :
                isHorizontalFlip ? 1 :
                    isVerticalFlip ? 2 : 0
        )
    } else if (id === "vertical") {
        isVerticalFlip = checked
        densicamController.setOrientation(
            isHorizontalFlip && isVerticalFlip ? 3 :
                isHorizontalFlip ? 1 :
                    isVerticalFlip ? 2 : 0
        )
    }
}

// ================================================================
// HANDLE TEXT BOX VALUE CHANGES
// ================================================================
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, text)
//
//  PURPOSE		:	To keep the JSON model in sync with a text box edit by
//					storing the new text on the child control with the given id.
//					Does not send anything to the camera.
//
//	ARGUMENTS	:	id - id of the text box control
//					text - new text entered by the user
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(id, text) {
    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var section = densiCAMHidProperty[i]
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
//  FUNCTION	:	updateUVCSliderValue(sliderId, value)
//
//  PURPOSE		:	To set the current value of the slider with the given id in
//					the model and report the change for the UI, without
//					sending anything to the camera.
//
//	ARGUMENTS	:	sliderId - id of the slider control
//					value - new slider value
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateUVCSliderValue(sliderId, value) {
    var changedFields = []

    for (var i = 0; i < densiCAMHidProperty.length; i++) {
        var group = densiCAMHidProperty[i]

        if (group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === sliderId) {
                    child.currentValue = value

                    changedFields.push({
                        id: child.id,
                        currentValue: child.currentValue
                    })

                    return changedFields
                }
            }
        }
    }

    return changedFields
}

/*function setUvcGainValue(value) {
    return updateSliderValue("gain_s", value)
}

function setUvcGammaValue(value) {
    return updateSliderValue("gamma_s", value)
}

function setUvcSaturationValue(value) {
    return updateSliderValue("saturation", value)
}

function setUvcSharpnessValue(value) {
    return updateSliderValue("sharpness_s", value)
}

function setUvcBrightnessValue(value) {
    return updateSliderValue("brightness_s", value)
}

function setUvcContrastValue(value) {
    return updateSliderValue("contrast_s", value)
}

function setUvcWBValue(value) {
    return updateSliderValue("wbValue", value)
}

function setUvcExposureTimeValue(value) {
    return updateSliderValue("exposureTime", value)
}*/
