var see3camCU130HidProperty = [];
var isUvcExposureAuto = false;
var aeWindowSize = 0
var isEmbedDataEnabled = false
var isOverlayRectEnabled = false
var isSmileEmbedDataEnabled = false
var isVerticalFlip = false
var isHorizontalFlip = false

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To store the HID extension settings JSON array (read by
//					prevController) as the module's model
//					(see3camCU130HidProperty), which all update/handle functions
//					then edit in place.
//
//	ARGUMENTS	:	jsonArray - array of control groups (each with id and
//					            children) describing the HID settings UI
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camCU130HidProperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the current HID settings model so
//					UsbcamHidSettings.qml can rebind its usbcamHidProperty to
//					the latest values.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the see3camCU130HidProperty JSON model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {    
    return see3camCU130HidProperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	callSupportFunctions()
//
//  PURPOSE		:	To re-apply the exposure-mode dependent enable/disable state
//					of the HID controls using the cached isUvcExposureAuto flag
//					(handleOnExposureModeChange) and push the changes to the UI
//					via triggerUpdateSignal(). Called from QML once the firmware
//					version (last value in the init sequence) has been received.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function callSupportFunctions(){
    var changedFields = handleOnExposureModeChange(isUvcExposureAuto);
    triggerUpdateSignal(changedFields)
}
// ----------------------------------------------------------------
// Get all camera controls on initialization
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To start reading all HID control values from the camera:
//					requests the anti-flicker mode immediately, then starts the
//					QML delayedControlsTimer (500 ms, single shot), which calls
//					getDelayedCameraControls().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getCameraControls() {
    // Trigger the QML timer for delayed controls
    see3camcu130Controller.getAntiFlickerMode()
    delayedControlsTimer.start()
}

// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To request the remaining See3CAM_CU130 HID control values
//					from the camera via see3camcu130Controller (scene mode,
//					effect, denoise, Q-factor, exposure compensation, frame
//					rate, AE ROI, burst length, flip, face detection, smile
//					detection, 64-bit serial number, firmware version). Values
//					come back through the controller's signals. Called by the
//					QML delayedControlsTimer.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    see3camcu130Controller.getSceneMode()
    see3camcu130Controller.getEffectMode()
    see3camcu130Controller.getDenoiseValue()
    see3camcu130Controller.getQFactor()
    see3camcu130Controller.getExposureCompensation()
    see3camcu130Controller.getFrameRateCtrlValue()

     // ----------------------------------------------------------------
    // Immediate controls
    // ----------------------------------------------------------------
    see3camcu130Controller.getAutoExpROI()
    see3camcu130Controller.getBurstLength()
    see3camcu130Controller.getFlipMode()
    see3camcu130Controller.getFaceDetectMode()
    see3camcu130Controller.getSmileDetectMode()
    see3camcu130Controller.get64BitSerialNumber()
    see3camcu130Controller.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the module's cached state flags (UVC auto-exposure,
//					AE window size, face / smile embedded data, overlay, flip)
//					to their defaults, e.g. when the camera is changed.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() 
{
   // see3camCU130HidProperty = []
    isUvcExposureAuto = false;
    aeWindowSize = 0
    isEmbedDataEnabled = false
    isOverlayRectEnabled = false
    isSmileEmbedDataEnabled = false
    isVerticalFlip = false
    isHorizontalFlip = false
}

// ----------------------------------------------------------------
// Scene Mode  (SceneModeCU130)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSceneMode(value)
//
//  PURPOSE		:	To check the normalMode or documentMode radio button of the
//					sceneMode group according to the scene mode read from the
//					camera.
//
//	ARGUMENTS	:	value - scene mode (See3CAMCU130.SCENE_NORMAL or
//					        SCENE_DOCUMENT)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSceneMode(value) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
        if (group.id === "sceneMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "normalMode") {
                    child.checked = (value === See3CAMCU130.SCENE_NORMAL)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "documentMode") {
                    child.checked = (value === See3CAMCU130.SCENE_DOCUMENT)
                    changedFields.push({ id: child.id, checked: child.checked })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Special Effects  (SpecialEffectCU130)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateEffectMode(value)
//
//  PURPOSE		:	To check the special-effect radio button (normal, black &
//					white, grayscale, negative, sketch) in the specialEffect
//					group that matches the effect read from the camera.
//
//	ARGUMENTS	:	value - special effect value reported by
//					        see3camcu130Controller (See3CAMCU130.EFFECT_*)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateEffectMode(value) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
        if (group.id === "specialEffect" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if      (child.id === "normalEffect")  child.checked = (value === See3CAMCU130.EFFECT_NORMAL)
                else if (child.id === "blackAndWhite") child.checked = (value === See3CAMCU130.EFFECT_BLACK_WHITE)
                else if (child.id === "grayScale")     child.checked = (value === See3CAMCU130.EFFECT_GRAY)
                else if (child.id === "negative")      child.checked = (value === See3CAMCU130.EFFECT_NEGATIVE)
                else if (child.id === "sketch")        child.checked = (value === See3CAMCU130.EFFECT_SKETCH)
                changedFields.push({ id: child.id, checked: child.checked })
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Exposure Compensation
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposureComp(expComp)
//
//  PURPOSE		:	To show the exposure compensation value read from the camera
//					in the expCompValue text box of the exposureCompensation
//					group.
//
//	ARGUMENTS	:	expComp - exposure compensation value reported by
//					          see3camcu130Controller
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateExposureComp(expComp) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
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

// ----------------------------------------------------------------
// Q Factor
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateQFactor(qFactor)
//
//  PURPOSE		:	To set the qFactorVal slider of the qFactor group to the
//					JPEG Q-factor read from the camera.
//
//	ARGUMENTS	:	qFactor - Q-factor value reported by see3camcu130Controller
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateQFactor(qFactor) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
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

// ----------------------------------------------------------------
// Burst Length
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBurstLength(burstLength)
//
//  PURPOSE		:	To apply the burst length read from the camera: forwards it
//					to prevController.setBurstLength() so still capture takes
//					that many images, and selects it in the burstLen drop-down
//					of the imageCapture group.
//
//	ARGUMENTS	:	burstLength - number of images captured per still-capture
//					              trigger
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateBurstLength(burstLength) {
    prevController.setBurstLength(burstLength)
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
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

// ----------------------------------------------------------------
// Flip Mode  (FlipModeCU130)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlipMode(flipMode)
//
//  PURPOSE		:	To check the horizontal (mirror) / vertical (flip) check
//					boxes of the flipControl group from the flip mode read from
//					the camera and cache them in isHorizontalFlip /
//					isVerticalFlip.
//
//	ARGUMENTS	:	flipMode - flip mode (See3CAMCU130.FLIP_OFF_MIRROR_ON,
//					           FLIP_ON_MIRROR_OFF, FLIP_ON_MIRROR_ON or both
//					           off)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFlipMode(flipMode) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horizontal") {
                    child.checked = (flipMode === See3CAMCU130.FLIP_OFF_MIRROR_ON ||
                        flipMode === See3CAMCU130.FLIP_ON_MIRROR_ON)
                    isHorizontalFlip = child.checked
                    if (flipMode === See3CAMCU130.BOTH_ENABLE) isVerticalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "vertical") {
                    child.checked = (flipMode === See3CAMCU130.FLIP_ON_MIRROR_OFF ||
                        flipMode === See3CAMCU130.FLIP_ON_MIRROR_ON)
                    isVerticalFlip = child.checked
                    if (flipMode === See3CAMCU130.FLIP_ON_MIRROR_ON) isHorizontalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Face Detection
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFaceDetectMode(mode, embedData, overlayRect)
//
//  PURPOSE		:	To reflect the face detection settings read from the camera:
//					checks the enable / disable radio buttons and sets the
//					embeddedData and overlayRect check boxes (enabled only when
//					face detection is on), caching them in isEmbedDataEnabled /
//					isOverlayRectEnabled.
//
//	ARGUMENTS	:	mode - face detection state (See3CAMCU130.FaceRectEnable /
//					       FaceRectDisable)
//					embedData - embedded data state
//					            (See3CAMCU130.FaceDetectEmbedDataEnable or
//					            disabled)
//					overlayRect - overlay rectangle state
//					              (See3CAMCU130.FaceDetectOverlayRectEnable or
//					              disabled)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFaceDetectMode(mode, embedData, overlayRect) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
        if (group.id === "faceDetection" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "enableFaceDet") {
                    child.checked = (mode === See3CAMCU130.FaceRectEnable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "disableFaceDet") {
                    child.checked = (mode === See3CAMCU130.FaceRectDisable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "embeddedData") {
                    child.enabled =     (mode === See3CAMCU130.FaceRectEnable)
                    child.checked =     (embedData === See3CAMCU130.FaceDetectEmbedDataEnable)
                    isEmbedDataEnabled    = child.checked
                    changedFields.push({
                        id:      child.id,
                        enabled: child.enabled,
                        checked: child.checked
                    })

                } else if (child.id === "overlayRect") {
                    child.enabled       = (mode === See3CAMCU130.FaceRectEnable)
                    child.checked       = (overlayRect === See3CAMCU130.FaceDetectOverlayRectEnable)
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

//-----------------------------------------------------------------
// Smile Detection
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSmileDetectMode(mode, embedData)
//
//  PURPOSE		:	To reflect the smile detection settings read from the
//					camera: checks the enableSmileDet / disableSmileDet radio
//					buttons and sets the embeddedSmileDetectData check box
//					(enabled only when smile detection is on), caching it in
//					isSmileEmbedDataEnabled.
//
//	ARGUMENTS	:	mode - smile detection state
//					       (See3CAMCU130.SmileDetectEnable /
//					       SmileDetectDisable)
//					embedData - embedded data state
//					            (See3CAMCU130.SmileDetectEmbedDataEnable or
//					            disabled)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSmileDetectMode(mode, embedData) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
        if (group.id === "smileDetection" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "enableSmileDet") {
                    child.checked = (mode === See3CAMCU130.SmileDetectEnable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "disableSmileDet") {
                    child.checked = (mode === See3CAMCU130.SmileDetectDisable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "embeddedSmileDetectData") {
                    child.enabled = (mode === See3CAMCU130.SmileDetectEnable)
                    child.checked = (embedData === See3CAMCU130.SmileDetectEmbedDataEnable)
                    isSmileEmbedDataEnabled = child.checked
                    changedFields.push({
                        id: child.id,
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


// ----------------------------------------------------------------
// Frame Rate
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFrameRate(frameRate)
//
//  PURPOSE		:	To set the frameRate slider of the frameRateControl group to
//					the frame-rate control value read from the camera.
//
//	ARGUMENTS	:	frameRate - frame rate control value reported by
//					            see3camcu130Controller
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFrameRate(frameRate) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
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

// ----------------------------------------------------------------
// Anti Flicker  (FlickerModeCU130)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAntiFlickerMode(flickerMode)
//
//  PURPOSE		:	To reflect the anti-flicker mode read from the camera:
//					checks off / auto / manual and enables the frequency drop-
//					down ("50 Hz" / "60 Hz") only for the manual 50/60 Hz modes.
//
//	ARGUMENTS	:	flickerMode - anti-flicker mode (See3CAMCU130.MODE_DISABLE,
//					              MODE_AUTO, MODE_50Hz or MODE_60Hz)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAntiFlickerMode(flickerMode) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "offMode") {
                    child.checked = (flickerMode === See3CAMCU130.MODE_DISABLE)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoMode") {
                    child.checked = (flickerMode === See3CAMCU130.MODE_AUTO)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualMode") {
                    child.checked = (flickerMode === See3CAMCU130.MODE_50Hz ||
                    flickerMode === See3CAMCU130.MODE_60Hz)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "frequency") {
                    child.enabled      = (flickerMode === See3CAMCU130.MODE_50Hz ||
                                          flickerMode === See3CAMCU130.MODE_60Hz)
                    child.currentValue = (flickerMode === See3CAMCU130.MODE_60Hz) ? "60 Hz" : "50 Hz"
                    child.selected     = (flickerMode === See3CAMCU130.MODE_60Hz) ? "60 Hz" : "50 Hz"
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

// ----------------------------------------------------------------
// Serial Number
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSerialNumber(serialNum)
//
//  PURPOSE		:	To show the serial number read from the camera in the
//					serialNumber field of the serialNum group.
//
//	ARGUMENTS	:	serialNum - serial number string reported by
//					            see3camcu130Controller
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSerialNumber(serialNum) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
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

// ----------------------------------------------------------------
// Denoise Strength
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDenoiseValue(value)
//
//  PURPOSE		:	To set the denoise slider of the denoiseStrength group to
//					the denoise strength read from the camera.
//
//	ARGUMENTS	:	value - denoise strength reported by see3camcu130Controller
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateDenoiseValue(value) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
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

// ----------------------------------------------------------------
// ROI AE Mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRoiAEMode(roiMode, winSize)
//
//  PURPOSE		:	To reflect the auto-exposure ROI mode read from the camera:
//					checks the fullROIAE / manualROIAE radio button and enables
//					the manualAE window-size drop-down only in manual mode,
//					caching the window size in aeWindowSize.
//
//	ARGUMENTS	:	roiMode - ROI AE mode (See3CAMCU130.AE_Full or
//					          See3CAMCU130.AE_Manual)
//					winSize - AE window size, applied only when roiMode is
//					          AE_Manual
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateRoiAEMode(roiMode, winSize) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
        if (group.id === "roiAE" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "fullROIAE") {
                    child.checked = (roiMode === See3CAMCU130.AE_Full)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualROIAE") {
                    child.checked = (roiMode === See3CAMCU130.AE_Manual)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualAE") {
                    child.enabled = (roiMode === See3CAMCU130.AE_Manual)
                    if (roiMode === See3CAMCU130.AE_Manual) {
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
//					                  see3camcu130Controller
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFirmwareVersioninUI(firmwareVersion) {
    var changedFields = []
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var group = see3camCU130HidProperty[i]
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

// ----------------------------------------------------------------
// Enable / Disable controls based on the exposure mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleOnExposureModeChange(mode)
//
//  PURPOSE		:	To enable or disable the HID controls that only work in UVC
//					auto exposure: the roiAE group and its children (manualAE
//					only when manualROIAE is also checked) and the
//					exposureCompensation text box / Set button. Caches the mode
//					in isUvcExposureAuto.
//
//	ARGUMENTS	:	mode - UVC exposure mode - true/1 = Auto, false/0 = Manual
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function handleOnExposureModeChange(mode) {
    // mode: 0 = Manual, 1 = Auto (adjust based on your actual enum values)
    isUvcExposureAuto = mode

    var changedFields = []

    for (var i = 0; i < see3camCU130HidProperty.length; ++i) {
        var section = see3camCU130HidProperty[i]

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
//  PURPOSE		:	To handle a UVC exposure mode change from the UVC settings
//					panel: updates the dependent HID control states, pushes them
//					via triggerUpdateSignal() and starts the QML
//					getAutoExposureControlValues timer to re-read the AE values
//					(getAutoExposureControls()).
//
//	ARGUMENTS	:	mode - UVC exposure mode - true/1 = Auto, false/0 = Manual
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

// ----------------------------------------------------------------
// Handle Radio button changes
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle a radio button toggle: checks it and unchecks the
//					rest of its group in the model and, when checked, sends the
//					setting to see3camcu130Controller - setSceneMode,
//					setEffectMode, setAutoExpROI (full or manual with the
//					selected window size), setAntiFlickerMode,
//					setSmileDetectRect (also enables the embeddedSmileDetectData
//					box) or setFaceDetectRect (also enables the embeddedData /
//					overlayRect boxes).
//
//	ARGUMENTS	:	identification - radio group identification from the UI
//					                 (e.g. "specialEffects")
//					id - id of the radio button that changed
//					checked - new checked state of that radio button
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []

    // Map identification → parent group id
    var identificationToGroupId = {
        "sceneModes":        "sceneMode",
        "specialEffects":    "specialEffect",
        "smileDetectionMode":       "smileDetection",
        "roiAEMode":         "roiAE",
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
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var section = see3camCU130HidProperty[i]

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
                        if (groupId === "sceneMode") {
                            var sceneMap = {
                                "normalMode":   See3CAMCU130.SCENE_NORMAL,
                                "documentMode": See3CAMCU130.SCENE_DOCUMENT
                            }
                            if (sceneMap[id] !== undefined)
                                see3camcu130Controller.setSceneMode(sceneMap[id])

                        } else if (groupId === "specialEffect") {
                            var effectMap = {
                                "normalEffect":  See3CAMCU130.EFFECT_NORMAL,
                                "blackAndWhite": See3CAMCU130.EFFECT_BLACK_WHITE,
                                "grayScale":     See3CAMCU130.EFFECT_GRAY,
                                "negative":      See3CAMCU130.EFFECT_NEGATIVE,
                                "sketch":        See3CAMCU130.EFFECT_SKETCH
                            }
                            if (effectMap[id] !== undefined)
                                see3camcu130Controller.setEffectMode(effectMap[id])

                        }  else if (groupId === "roiAE") {
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
                                "fullROIAE": See3CAMCU130.AE_Full,
                                "manualROIAE":   See3CAMCU130.AE_Manual
                            }
                            if (roiAEMap[id] !== undefined)
                                if(id === "manualROIAE"){
                                    see3camcu130Controller.setAutoExpROI(roiAEMap[id], 0, 0, 0, 0, aeWinSize) // default to 1x1 centered when switching to manual
                                } else if (id === "fullROIAE"){
                                    see3camcu130Controller.setAutoExpROI(roiAEMap[id], 0, 0, 0, 0, 0)
                                }
                            

                        }  else if (groupId === "antiFlicker") {
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
                                "offMode":    See3CAMCU130.MODE_DISABLE,
                                "autoMode":   See3CAMCU130.MODE_AUTO,
                                "manualMode": See3CAMCU130.MODE_50Hz
                            }
                            if (flickerMap[id] !== undefined)
                                if( id == "manualMode"){
                                    if (frequency === "60 Hz") {
                                        see3camcu130Controller.setAntiFlickerMode(See3CAMCU130.MODE_60Hz)
                                    } else if (frequency === "50 Hz") {
                                        see3camcu130Controller.setAntiFlickerMode(See3CAMCU130.MODE_50Hz)
                                    }
                                } else {
                                    see3camcu130Controller.setAntiFlickerMode(flickerMap[id])
                                }
                        } else if (groupId === "smileDetection") {
                            var isSmileDetectEnabled = (id === "enableSmileDet")
                        
                            // Enable/disable embeddedData and overlayRect checkboxes
                            for (var k = 0; k < section.children.length; k++) {
                                var smileChild = section.children[k]
                        
                                if (smileChild.id === "embeddedSmileDetectData") {
                                    smileChild.enabled = isSmileDetectEnabled
                                    changedFields.push({
                                        id:      "embeddedSmileDetectData",
                                        enabled: isSmileDetectEnabled
                                    })
                                } 
                            }
                        
                            // Call controller
                            see3camcu130Controller.setSmileDetectRect(
                                isSmileDetectEnabled,
                                isSmileEmbedDataEnabled   // embedData default — actual value comes from checkbox state
                            )
                        } else if (groupId === "faceDetection") {
                            var isFaceDetectEnabled = (id === "enableFaceDet")

                            // Enable/disable embeddedData and overlayRect checkboxes
                            for (var k = 0; k < section.children.length; k++) {
                                var faceChild = section.children[k]

                                if (faceChild.id === "embeddedData") {
                                    faceChild.enabled = isFaceDetectEnabled
                                    // isEmbedDataEnable = faceChild.checked
                                    changedFields.push({
                                        id: "embeddedData",
                                        enabled: isFaceDetectEnabled
                                    })
                                } else if (faceChild.id === "overlayRect") {
                                    faceChild.enabled = isFaceDetectEnabled
                                    // isOverlayRectEnable = faceChild.checked
                                    changedFields.push({
                                        id: "overlayRect",
                                        enabled: isFaceDetectEnabled
                                    })
                                }
                            }

                            // Call controller
                            see3camcu130Controller.setFaceDetectRect(
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

// ----------------------------------------------------------------
// Handle Button Click 
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle HID button clicks: setExpComp validates the
//					expCompValue text (must be an integer) and calls
//					setExposureCompensation(); updateDefault calls
//					setToDefault() and re-reads all controls.
//
//	ARGUMENTS	:	id - id of the clicked button
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id){

    if (id === "setExpComp") {
        // ----------------------------------------------------------------
        // Find the expCompValue textbox in the JSON and read its text
        // ----------------------------------------------------------------
        var expCompText = ""
    
        for (var i = 0; i < see3camCU130HidProperty.length; i++) {
            var section = see3camCU130HidProperty[i]
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

        see3camcu130Controller.setExposureCompensation(expCompValue)
    }  else if ( id === "updateDefault"){
        see3camcu130Controller.setToDefault()
        getCameraControls()
    } 
}

// ----------------------------------------------------------------
// Handle Text box value change
// ----------------------------------------------------------------
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
function updateTextBoxField(id, text){
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var section = see3camCU130HidProperty[i]
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
// Handle Slider Value Changes
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider change in the model and send it to the
//					camera: denoise -> setDenoiseValue(), qFactorVal ->
//					setQFactor(), frameRate -> setFrameRateCtrlValue().
//
//	ARGUMENTS	:	id - id of the slider control
//					currentVal - new slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id,currentVal){
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var section = see3camCU130HidProperty[i]
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
        see3camcu130Controller.setDenoiseValue(currentVal)
    } else if(id === "qFactorVal"){
        see3camcu130Controller.setQFactor(currentVal)
    } else if(id === "frameRate"){
        see3camcu130Controller.setFrameRateCtrlValue(currentVal)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a drop-down change in the model and apply it:
//					manualAF sets the manual AF ROI window size
//					(setAutoFocusROI), manualAE sets the manual AE ROI window
//					size (setAutoExpROI), burstLen sets the burst length on the
//					camera and prevController, frequency sets 50/60 Hz anti-
//					flicker (setAntiFlickerMode).
//
//	ARGUMENTS	:	id - id of the drop-down control
//					value - newly selected value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value){
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var section = see3camCU130HidProperty[i]
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
    // See3CAM_CU130 has no auto focus (no AF control in the SDK or controller).
    if(id === "manualAE"){
        aeWindowSize = value
        see3camcu130Controller.setAutoExpROI(See3CAMCU130.AE_Manual, 0, 0, 0, 0, value)
    } else if(id === "burstLen"){
        see3camcu130Controller.setBurstLength(value)
        prevController.setBurstLength(value)
    } else if(id === "frequency"){
        if(value == "50 Hz"){
            see3camcu130Controller.setAntiFlickerMode(See3CAMCU130.MODE_50Hz)
        } else if (value == "60 Hz"){
            see3camcu130Controller.setAntiFlickerMode(See3CAMCU130.MODE_60Hz)
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRightClick(x, y, width, height)
//
//  PURPOSE		:	To set a manual ROI at the right-clicked preview position:
//					setAutoExpROI(AE_Manual, ...) with aeWindowSize while UVC
//					exposure is Auto, and setAutoFocusROI(AF_Manual, ...) with
//					afWindowSize while isUvcFocusAuto is set.
//
//	ARGUMENTS	:	x - x coordinate of the ROI centre in the preview
//					y - y coordinate of the ROI centre in the preview
//					width - width of the preview area
//					height - height of the preview area
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleRightClick(x, y, width, height){
    if(isUvcExposureAuto){
        see3camcu130Controller.setAutoExpROI(See3CAMCU130.AE_Manual, x, y, width, height, aeWindowSize)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box change in the model and apply it:
//					embeddedData / overlayRect call setFaceDetectRect() with the
//					updated flags; embeddedSmileDetectData calls
//					setSmileDetectRect(); horizontal / vertical call
//					setFlipMode() with the updated flip flags.
//
//	ARGUMENTS	:	id - id of the check box control
//					checked - new checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked){
    for (var i = 0; i < see3camCU130HidProperty.length; i++) {
        var section = see3camCU130HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].checked = checked   // keep JSON in sync
                   break
                }
            }
        }
    }
    if (id === "embeddedData") {
        isEmbedDataEnabled = checked
        see3camcu130Controller.setFaceDetectRect(
            true,   // enable/disable determined by overlayRect state
            checked,    // embedData follows checkbox state
            isOverlayRectEnabled    // overlayRect follows its own checkbox state
        )
    } else if (id === "overlayRect") {
        isOverlayRectEnabled = checked
        see3camcu130Controller.setFaceDetectRect(
            true,   // enable/disable determined by embeddedData state
            isEmbedDataEnabled,    // embedData follows its own checkbox state
            checked    // overlayRect follows checkbox state
        )
    } else if (id === "embeddedSmileDetectData") {
        isSmileEmbedDataEnabled = checked
        see3camcu130Controller.setSmileDetectRect(
            true,   // enable/disable determined by embeddedData state
            isSmileEmbedDataEnabled,    // embedData follows its own checkbox state
        )
    }else if (id === "horizontal") {
        isHorizontalFlip = checked
        see3camcu130Controller.setFlipMode(checked, isVerticalFlip)
    } else if (id === "vertical"){
        isVerticalFlip = checked
        see3camcu130Controller.setFlipMode(isHorizontalFlip, checked)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getAutoExposureControls()
//
//  PURPOSE		:	To re-read the auto-exposure ROI mode from the camera
//					(getAutoExpROI). Called by the QML
//					getAutoExposureControlValues timer after the UVC exposure
//					mode changes.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getAutoExposureControls(){
    see3camcu130Controller.getAutoExpROI()
}