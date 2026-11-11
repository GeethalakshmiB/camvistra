var see3cam24cugHidProperty = [];
var isUvcExposureAuto = false;
var aeWindowSize = 0
var isEmbedDataEnabled = false
var isOverlayRectEnabled = false
var isVerticalFlip = false
var isHorizontalFlip = false
var isAutoLockFuncChecked = false

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To store the HID extension settings JSON array (read by
//					prevController) as the module's model
//					(see3cam24cugHidProperty), which all update/handle functions
//					then edit in place.
//
//	ARGUMENTS	:	jsonArray - array of control groups (each with id and
//					            children) describing the HID settings UI
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3cam24cugHidProperty = jsonArray;
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
//	RETURN		:	Array - the see3cam24cugHidProperty JSON model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return see3cam24cugHidProperty;
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
//  PURPOSE		:	To start reading all HID control values from the camera by
//					starting the QML delayedControlsTimer (500 ms, single shot),
//					which then calls getDelayedCameraControls().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getCameraControls() {
    // Trigger the QML timer for delayed controls
    delayedControlsTimer.start()
}

// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To request every See3CAM_24CUG HID control value from the
//					camera via see3cam24cugController (effect, denoise, AE ROI
//					mode and window size, burst length, Q-factor, orientation,
//					frame rate, exposure compensation, face detection, flicker
//					detection, flash state, stream mode, 64-bit serial number,
//					firmware version). Values come back through the controller's
//					signals. Called by the QML delayedControlsTimer.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    see3cam24cugController.getEffectMode()
    see3cam24cugController.getDenoiseValue()
    see3cam24cugController.getAutoExpROIModeAndWindowSize()
    see3cam24cugController.getBurstLength()
    see3cam24cugController.getQFactor()
    see3cam24cugController.getOrientation()
    see3cam24cugController.getFrameRateCtrlValue()
    see3cam24cugController.getExposureCompensation()
    see3cam24cugController.getFaceDetectMode()
    see3cam24cugController.getFlickerDetection()
    see3cam24cugController.getFlashState()
    see3cam24cugController.getStreamMode()
    see3cam24cugController.get64BitSerialNumber()
    see3cam24cugController.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the module's cached state flags (UVC auto-exposure,
//					AE window size, embedded data / overlay, flip) to their
//					defaults, e.g. when the camera is changed.
//					isAutoLockFuncChecked is not reset.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    isUvcExposureAuto = false;
    aeWindowSize = 0
    isEmbedDataEnabled = false
    isOverlayRectEnabled = false
    isVerticalFlip = false
    isHorizontalFlip = false
}

// ----------------------------------------------------------------
// Special Effects  (SpecialEffect_24CUG)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateEffectMode(value)
//
//  PURPOSE		:	To check the special-effect radio button (normal, black &
//					white, grayscale, negative, sketch) in the specialEffect
//					group that matches the effect read from the camera.
//
//	ARGUMENTS	:	value - special effect value reported by
//					        see3cam24cugController (See3CAM24CUG.EFFECT_*)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateEffectMode(value) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "specialEffect" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "normalEffect") child.checked = (value === See3CAM24CUG.EFFECT_NORMAL)
                else if (child.id === "blackAndWhite") child.checked = (value === See3CAM24CUG.EFFECT_BLACK_WHITE)
                else if (child.id === "grayScale") child.checked = (value === See3CAM24CUG.EFFECT_GREYSCALE)
                else if (child.id === "negative") child.checked = (value === See3CAM24CUG.EFFECT_NEGATIVE)
                else if (child.id === "sketch") child.checked = (value === See3CAM24CUG.EFFECT_SKETCH)
                changedFields.push({ id: child.id, checked: child.checked })
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
//	ARGUMENTS	:	value - denoise strength reported by see3cam24cugController
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateDenoiseValue(value) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
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
//	ARGUMENTS	:	roiMode - ROI AE mode (See3CAM24CUG.AE_Full or
//					          See3CAM24CUG.AE_Manual)
//					winSize - AE window size, applied only when roiMode is
//					          AE_Manual
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateRoiAEMode(roiMode, winSize) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "roiAE" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "fullROIAE") {
                    child.checked = (roiMode === See3CAM24CUG.AE_Full)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualROIAE") {
                    child.checked = (roiMode === See3CAM24CUG.AE_Manual)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualAE") {
                    child.enabled = (roiMode === See3CAM24CUG.AE_Manual)
                    if (roiMode === See3CAM24CUG.AE_Manual) {
                        aeWindowSize = winSize
                        child.currentValue = winSize
                        child.selected = winSize
                    }
                    changedFields.push({
                        id: child.id,
                        enabled: child.enabled,
                        currentValue: child.currentValue,
                        selected: child.selected
                    })
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
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "imageCapture" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "burstLen") {
                    group.children[j].currentValue = burstLength
                    group.children[j].selected = burstLength
                    changedFields.push({
                        id: group.children[j].id,
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

// ----------------------------------------------------------------
// Q Factor
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateQFactor(qFactor)
//
//  PURPOSE		:	To set the qFactorVal slider of the qFactor group to the
//					JPEG Q-factor read from the camera.
//
//	ARGUMENTS	:	qFactor - Q-factor value reported by see3cam24cugController
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateQFactor(qFactor) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
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
// Flip Mode  (FlipMode_24CUG)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlipMode(flipMode)
//
//  PURPOSE		:	To check the horizontal / vertical flip check boxes of the
//					flipControl group from the orientation read from the camera
//					and cache them in isHorizontalFlip / isVerticalFlip.
//
//	ARGUMENTS	:	flipMode - orientation (See3CAM24CUG.FLIP_ON_MIRROR_OFF,
//					           FLIP_OFF_MIRROR_ON, FLIP_ON_MIRROR_ON or both
//					           off)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFlipMode(flipMode) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horizontal") {
                    child.checked = (flipMode === See3CAM24CUG.FLIP_ON_MIRROR_OFF ||
                        flipMode === See3CAM24CUG.FLIP_ON_MIRROR_ON)
                    isHorizontalFlip = child.checked
                    if (flipMode === See3CAM24CUG.FLIP_ON_MIRROR_ON) isVerticalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "vertical") {
                    child.checked = (flipMode === See3CAM24CUG.FLIP_OFF_MIRROR_ON ||
                        flipMode === See3CAM24CUG.FLIP_ON_MIRROR_ON)
                    isVerticalFlip = child.checked
                    if (flipMode === See3CAM24CUG.FLIP_ON_MIRROR_ON) isHorizontalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
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
//					            see3cam24cugController
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFrameRate(frameRate) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
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
//					          see3cam24cugController
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateExposureComp(expComp) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
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
//	ARGUMENTS	:	mode - face detection state (See3CAM24CUG.FaceRectEnable /
//					       FaceRectDisable)
//					embedData - embedded data state
//					            (See3CAM24CUG.FaceDetectEmbedDataEnable or
//					            disabled)
//					overlayRect - overlay rectangle state
//					              (See3CAM24CUG.FaceDetectOverlayRectEnable or
//					              disabled)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFaceDetectMode(mode, embedData, overlayRect) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "faceDetection" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "enableFaceDet") {
                    child.checked = (mode === See3CAM24CUG.FaceRectEnable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "disableFaceDet") {
                    child.checked = (mode === See3CAM24CUG.FaceRectDisable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "embeddedData") {
                    child.enabled = (mode === See3CAM24CUG.FaceRectEnable)
                    child.checked = (embedData === See3CAM24CUG.FaceDetectEmbedDataEnable)
                    isEmbedDataEnabled = child.checked
                    changedFields.push({
                        id: child.id,
                        enabled: child.enabled,
                        checked: child.checked
                    })

                } else if (child.id === "overlayRect") {
                    child.enabled = (mode === See3CAM24CUG.FaceRectEnable)
                    child.checked = (overlayRect === See3CAM24CUG.FaceDetectOverlayRectEnable)
                    isOverlayRectEnabled = child.checked
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
// Anti Flicker  (FlickerMode_24CUG)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAntiFlickerMode(flickerMode)
//
//  PURPOSE		:	To reflect the flicker detection mode read from the camera:
//					checks off / auto / manual and enables the frequency drop-
//					down ("50 Hz" / "60 Hz") only for the manual 50/60 Hz modes.
//
//	ARGUMENTS	:	flickerMode - flicker mode (See3CAM24CUG.MODE_DISABLE,
//					              MODE_AUTO, MODE_50Hz or MODE_60Hz)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAntiFlickerMode(flickerMode) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "offMode") {
                    child.checked = (flickerMode === See3CAM24CUG.MODE_DISABLE)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoMode") {
                    child.checked = (flickerMode === See3CAM24CUG.MODE_AUTO)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualMode") {
                    child.checked = (flickerMode === See3CAM24CUG.MODE_50Hz ||
                        flickerMode === See3CAM24CUG.MODE_60Hz)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "frequency") {
                    child.enabled = (flickerMode === See3CAM24CUG.MODE_50Hz ||
                        flickerMode === See3CAM24CUG.MODE_60Hz)
                    child.currentValue = (flickerMode === See3CAM24CUG.MODE_60Hz) ? "60 Hz" : "50 Hz"
                    child.selected = (flickerMode === See3CAM24CUG.MODE_60Hz) ? "60 Hz" : "50 Hz"
                    changedFields.push({
                        id: child.id,
                        enabled: child.enabled,
                        currentValue: child.currentValue,
                        selected: child.selected
                    })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Flash Mode  (FlashMode_24CUG)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlashMode(flashMode)
//
//  PURPOSE		:	To check the disableFlashMode or enableFlashMode radio
//					button of the flashMode group according to the flash state
//					read from the camera.
//
//	ARGUMENTS	:	flashMode - flash state (See3CAM24CUG.FLASHMODE_OFF or
//					            FLASHMODE_STROBE)
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFlashMode(flashMode) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "flashMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "disableFlashMode") child.checked = (flashMode === See3CAM24CUG.FLASHMODE_OFF)
                else if (child.id === "enableFlashMode") child.checked = (flashMode === See3CAM24CUG.FLASHMODE_STROBE)
                changedFields.push({ id: child.id, checked: child.checked })
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Stream Mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStreamMode(streamMode, autoLockFunc)
//
//  PURPOSE		:	To reflect the stream mode read from the camera: checks the
//					masterMode or triggerMode radio button and sets the
//					autoFuncLock check box, caching it in isAutoLockFuncChecked.
//
//	ARGUMENTS	:	streamMode - stream mode (See3CAM24CUG.MODE_MASTER or
//					             MODE_TRIGGER)
//					autoLockFunc - true if auto functions lock is enabled
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateStreamMode(streamMode, autoLockFunc) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "streamMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "masterMode") {
                    child.checked = (streamMode === See3CAM24CUG.MODE_MASTER)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "triggerMode") {
                    child.checked = (streamMode === See3CAM24CUG.MODE_TRIGGER)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoFuncLock") {
                    child.checked = autoLockFunc
                    isAutoLockFuncChecked = child.checked
                    changedFields.push({ id: child.id, checked: child.checked })
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
//					            see3cam24cugController
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSerialNumber(serialNum) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
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
// Firmware Version
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFirmwareVersioninUI(firmwareVersion)
//
//  PURPOSE		:	To show the firmware version read from the camera in the
//					firmwareVer field of the firmwareVersion group.
//
//	ARGUMENTS	:	firmwareVersion - firmware version string reported by
//					                  see3cam24cugController
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFirmwareVersioninUI(firmwareVersion) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
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

    for (var i = 0; i < see3cam24cugHidProperty.length; ++i) {
        var section = see3cam24cugHidProperty[i]

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
function setExposureMode(mode) {
    // mode: 0 = Manual, 1 = Auto (adjust based on your actual enum values)
    isUvcExposureAuto = mode

    var changedFields = handleOnExposureModeChange(isUvcExposureAuto);
    triggerUpdateSignal(changedFields)

    getAutoExposureControlValues.start()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setUvcAntiFlickerMode(value)
//
//  PURPOSE		:	To mirror an anti-flicker change made in the UVC power-line-
//					frequency control on the HID antiFlicker group: checks
//					off/auto/manual and enables and selects the frequency drop-
//					down for 50/60 Hz. Updates the model only (no camera call).
//
//	ARGUMENTS	:	value - UVC anti-flicker selection - "DISABLE", "AUTO", "50
//					        Hz" or "60 Hz"
//
//	RETURN		:	Array - changedFields list of {id, ...} objects to pass to
//					triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function setUvcAntiFlickerMode(value) {
    var changedFields = []
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var group = see3cam24cugHidProperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "offMode") {
                    child.checked = (value === "DISABLE")
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoMode") {
                    child.checked = (value === "AUTO")
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualMode") {
                    child.checked = (value === "50 Hz" ||
                        value === "60 Hz")
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "frequency") {
                    child.enabled = (value === "50 Hz" ||
                        value === "60 Hz")
                    child.currentValue = value
                    child.selected = value
                    changedFields.push({
                        id: child.id,
                        enabled: child.enabled,
                        currentValue: child.currentValue,
                        selected: child.selected
                    })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Handle Radio button changes
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle a radio button toggle: checks it and unchecks the
//					rest of its group in the model and, when checked, sends the
//					setting to see3cam24cugController - setEffectMode,
//					setStreamMode (with the auto-lock flag; shows a PIN 5 of CN3
//					hint for trigger mode), setROIAutoExposure (full or manual
//					with the selected window size), setFlashState,
//					setFlickerDetection (also usbcamRect.setHidAntiFlicker on
//					non-Windows) or setFaceDetectionRect (also enables the
//					embeddedData / overlayRect boxes).
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
        "specialEffects": "specialEffect",
        "streamModes": "streamMode",
        "roiAEMode": "roiAE",
        "flashModes": "flashMode",
        "faceDetectionMode": "faceDetection",
        "antiFlickerMode": "antiFlicker"
    }

    // Resolve parent group id from identification
    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    // Now find the section using resolved groupId
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var section = see3cam24cugHidProperty[i]

        if (section.id === groupId && section.children) {

            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]

                if (radio.id === id) {
                    // ===== SELECTED RADIO BUTTON =====
                    radio.checked = checked

                    changedFields.push({
                        id: radio.id,
                        checked: checked
                    })

                    // ----------------------------------------------------------------
                    // Call controller based on groupId + id
                    // ----------------------------------------------------------------
                    if (checked) {
                        if (groupId === "specialEffect") {
                            var effectMap = {
                                "normalEffect": See3CAM24CUG.EFFECT_NORMAL,
                                "blackAndWhite": See3CAM24CUG.EFFECT_BLACK_WHITE,
                                "grayScale": See3CAM24CUG.EFFECT_GREYSCALE,
                                "negative": See3CAM24CUG.EFFECT_NEGATIVE,
                                "sketch": See3CAM24CUG.EFFECT_SKETCH
                            }
                            if (effectMap[id] !== undefined)
                                see3cam24cugController.setEffectMode(effectMap[id])

                        }
                        else if (groupId === "streamMode") {
                            var streamMap = {
                                "masterMode": See3CAM24CUG.MODE_MASTER,
                                "triggerMode": See3CAM24CUG.MODE_TRIGGER
                            }
                            if (streamMap[id] !== undefined)
                                see3cam24cugController.setStreamMode(streamMap[id], isAutoLockFuncChecked)

                            if (id === "triggerMode"){               
                                setTextMessage("Frames will be out only when external hardware pulses are given to PIN 5 of CN3.")
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
                                "fullROIAE": See3CAM24CUG.AE_Full,
                                "manualROIAE": See3CAM24CUG.AE_Manual
                            }
                            if (roiAEMap[id] !== undefined)
                                if (id === "manualROIAE") {
                                    see3cam24cugController.setROIAutoExposure(roiAEMap[id], 0, 0, 0, 0, aeWinSize) // default to 1x1 centered when switching to manual
                                } else if (id === "fullROIAE") {
                                    see3cam24cugController.setROIAutoExposure(roiAEMap[id], 0, 0, 0, 0, 0)
                                }


                        } else if (groupId === "flashMode") {
                            var flashMap = {
                                "disableFlashMode": See3CAM24CUG.FLASHMODE_OFF,
                                "enableFlashMode": See3CAM24CUG.FLASHMODE_STROBE
                            }
                            if (flashMap[id] !== undefined)
                                see3cam24cugController.setFlashState(flashMap[id])

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
                                "offMode": See3CAM24CUG.MODE_DISABLE,
                                "autoMode": See3CAM24CUG.MODE_AUTO,
                                "manualMode": See3CAM24CUG.MODE_50Hz
                            }
                            if (flickerMap[id] !== undefined)
                                if (id == "manualMode") {
                                    if (frequency === "60 Hz") {
                                        see3cam24cugController.setFlickerDetection(See3CAM24CUG.MODE_60Hz)
                                    } else if (frequency === "50 Hz") {
                                        see3cam24cugController.setFlickerDetection(See3CAM24CUG.MODE_50Hz)
                                    }
                                    if (Qt.platform.os !== "windows")
                                        usbcamRect.setHidAntiFlicker(frequency)
                                } else {
                                    see3cam24cugController.setFlickerDetection(flickerMap[id])
                                    if (Qt.platform.os !== "windows" &&
                                            flickerMap[id] == See3CAM24CUG.MODE_DISABLE) {
                                        usbcamRect.setHidAntiFlicker("DISABLE")
                                    }
                                }
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
                            see3cam24cugController.setFaceDetectionRect(
                                isFaceDetectEnabled,
                                isEmbedDataEnabled,   // embedData default — actual value comes from checkbox state
                                isOverlayRectEnabled    // overlayRect default — actual value comes from checkbox state
                            )
                        }
                    }

                } else if (radio.identification === identification) {
                    // ===== UNCHECK ALL OTHER RADIO BUTTONS IN SAME GROUP =====
                    radio.checked = false

                    changedFields.push({
                        id: radio.id,
                        checked: false
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
//					expCompValue text (integer, 50 - 1000000, else shows a
//					message) and calls setExposureCompensation(); updateDefault
//					calls setToDefault() and re-reads all controls.
//
//	ARGUMENTS	:	id - id of the clicked button
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {

     if (id === "setExpComp") {
        // ----------------------------------------------------------------
        // Find the expCompValue textbox in the JSON and read its text
        // ----------------------------------------------------------------
        var expCompText = ""

        for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
            var section = see3cam24cugHidProperty[i]
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

        if (expCompValue < 50 || expCompValue > 1000000) {
            setTextMessage("Exposure compensation value must be between 50 and 1000000")
            return
        }

        see3cam24cugController.setExposureCompensation(expCompValue)
    } else if (id === "updateDefault") {
        see3cam24cugController.setToDefault()
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
function updateTextBoxField(id, text) {
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var section = see3cam24cugHidProperty[i]
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
function updateSliderValue(id, currentVal) {
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var section = see3cam24cugHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = currentVal   // keep JSON in sync
                    break
                }
            }
        }
    }
    if (id === "denoise") {
        see3cam24cugController.setDenoiseValue(currentVal)
    } else if (id === "qFactorVal") {
        see3cam24cugController.setQFactor(currentVal)
    } else if (id === "frameRate") {
        see3cam24cugController.setFrameRateCtrlValue(currentVal)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a drop-down change in the model and apply it:
//					manualAE sets the manual AE ROI window size
//					(setROIAutoExposure), burstLen sets the burst length on the
//					camera and prevController, frequency sets 50/60 Hz flicker
//					detection (and usbcamRect.setHidAntiFlicker on non-Windows).
//
//	ARGUMENTS	:	id - id of the drop-down control
//					value - newly selected value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value) {
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var section = see3cam24cugHidProperty[i]
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
        see3cam24cugController.setROIAutoExposure(See3CAM24CUG.AE_Manual, 0, 0, 0, 0, aeWindowSize)
    } else if (id === "burstLen") {
        see3cam24cugController.setBurstLength(value)
        prevController.setBurstLength(value)
    } else if (id === "frequency") {
        if (value == "50 Hz") {
            see3cam24cugController.setFlickerDetection(See3CAM24CUG.MODE_50Hz)
        } else if (value == "60 Hz") {
            see3cam24cugController.setFlickerDetection(See3CAM24CUG.MODE_60Hz)
        }
        if (Qt.platform.os !== "windows")
            usbcamRect.setHidAntiFlicker(value)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRightClick(x, y, width, height)
//
//  PURPOSE		:	To set a manual auto-exposure ROI at the right-clicked
//					preview position via
//					see3cam24cugController.setROIAutoExposure(AE_Manual, ...)
//					using the cached aeWindowSize. Done only while UVC exposure
//					is Auto.
//
//	ARGUMENTS	:	x - x coordinate of the ROI centre in the preview
//					y - y coordinate of the ROI centre in the preview
//					width - width of the preview area
//					height - height of the preview area
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleRightClick(x, y, width, height) {
    if (isUvcExposureAuto) {
        see3cam24cugController.setROIAutoExposure(See3CAM24CUG.AE_Manual, x, y, width, height, aeWindowSize)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box change in the model and apply it:
//					embeddedData / overlayRect call setFaceDetectionRect() with
//					the updated flags; horizontal / vertical call
//					setOrientation(); autoFuncLock re-sends setStreamMode() for
//					the currently checked master / trigger mode with the new
//					lock state.
//
//	ARGUMENTS	:	id - id of the check box control
//					checked - new checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked) {
    for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
        var section = see3cam24cugHidProperty[i]
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
        see3cam24cugController.setFaceDetectionRect(
            true,   // enable/disable determined by overlayRect state
            checked,    // embedData follows checkbox state
            isOverlayRectEnabled    // overlayRect follows its own checkbox state
        )
    } else if (id === "overlayRect") {
        isOverlayRectEnabled = checked
        see3cam24cugController.setFaceDetectionRect(
            true,   // enable/disable determined by embeddedData state
            isEmbedDataEnabled,    // embedData follows its own checkbox state
            checked    // overlayRect follows checkbox state
        )
    } else if (id === "horizontal") {
        isHorizontalFlip = checked
        see3cam24cugController.setOrientation(checked, isVerticalFlip)
    } else if (id === "vertical") {
        isVerticalFlip = checked
        see3cam24cugController.setOrientation(isHorizontalFlip, checked)
    } else if( id === "autoFuncLock"){
        isAutoLockFuncChecked = checked
        for (var i = 0; i < see3cam24cugHidProperty.length; i++) {
            var group = see3cam24cugHidProperty[i]
            if (group.id === "streamMode" && group.children) {
                for (var j = 0; j < group.children.length; j++) {
                    var child = group.children[j]

                    if (child.id === "masterMode" && child.checked) {
                        see3cam24cugController.setStreamMode(See3CAM24CUG.MODE_MASTER, checked)
                    } else if (child.id === "triggerMode" && child.checked) {
                        see3cam24cugController.setStreamMode(See3CAM24CUG.MODE_TRIGGER, checked)
                    }
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getAutoExposureControls()
//
//  PURPOSE		:	To re-read the auto-exposure ROI mode and window size from
//					the camera (getAutoExpROIModeAndWindowSize). Called by the
//					QML getAutoExposureControlValues timer after the UVC
//					exposure mode changes.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getAutoExposureControls() {
    see3cam24cugController.getAutoExpROIModeAndWindowSize()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getexposureCompFrameRateCtrl()
//
//  PURPOSE		:	To re-read the exposure compensation and frame-rate control
//					values from the camera
//					(see3cam24cugController.getExposureCompensation() /
//					getFrameRateCtrlValue()); results arrive through the
//					controller's signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getexposureCompFrameRateCtrl() {
    see3cam24cugController.getExposureCompensation()
    see3cam24cugController.getFrameRateCtrlValue()
}
