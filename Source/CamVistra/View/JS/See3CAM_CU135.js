var see3cam130EHidroperty = [];
var isUvcExposureAuto = false;
var hdrVal = 0
var afWindowSize = 0
var aeWindowSize = 0
var isEmbedDataEnabled = false
var isOverlayRectEnabled = false
var isVerticalFlip = false
var isHorizontalFlip = false

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To store the HID settings JSON model (array of control
//					groups) loaded by UsbcamHidSettings.qml in the module-
//					level see3cam130EHidroperty array.
//
//	ARGUMENTS	:	jsonArray - Array of control group objects parsed from the
//					  camera's HID settings JSON
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3cam130EHidroperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the current HID settings model so the QML view
//					can render the controls.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the see3cam130EHidroperty model array
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    
    return see3cam130EHidroperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	callSupportFunctions()
//
//  PURPOSE		:	To re-apply the enable/disable state of exposure-dependent
//					controls from the cached UVC auto exposure flag and push
//					the result to the UI.
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
//  PURPOSE		:	To start the QML delayedControlsTimer, which then calls
//					getDelayedCameraControls() to read all HID control values
//					from the camera.
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
//  PURPOSE		:	To request the HID control values from the camera through
//					see3camcu135Controller (scene, effect, denoise, iHDR, Q
//					factor, exposure compensation, frame rate, AE ROI
//					mode/window, burst length, orientation, flicker detection,
//					face and smile detection, stream mode). Results arrive
//					through controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    see3camcu135Controller.getSceneMode()
    see3camcu135Controller.getEffectMode()
    see3camcu135Controller.getDenoiseValue()
    see3camcu135Controller.getiHDRMode()
    see3camcu135Controller.getQFactor()
    see3camcu135Controller.getExposureCompensation()
    see3camcu135Controller.getFrameRateCtrlValue()

     // ----------------------------------------------------------------
    // Immediate controls
    // ----------------------------------------------------------------

    see3camcu135Controller.getAutoExpROIModeAndWindowSize()
    see3camcu135Controller.getBurstLength()
    see3camcu135Controller.getOrientation()
    see3camcu135Controller.getFlickerDetection()
    see3camcu135Controller.getFaceDetectMode()
    see3camcu135Controller.getSmileDetectMode()
    see3camcu135Controller.getStreamMode()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached module state (UVC auto exposure flag,
//					HDR level, AF/AE window sizes, face-detect embed/overlay
//					flags, flip flags) to defaults. The model array is kept.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() 
{
    isUvcExposureAuto = false;
    hdrVal = 0
    afWindowSize = 0
    aeWindowSize = 0
    isEmbedDataEnabled = false
    isOverlayRectEnabled = false
    isVerticalFlip = false
    isHorizontalFlip = false
}

// ----------------------------------------------------------------
// Scene Mode  (SceneMode130E)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSceneMode(value)
//
//  PURPOSE		:	To check the Normal or Document radio button in the
//					"sceneMode" group to match the scene mode reported by the
//					camera.
//
//	ARGUMENTS	:	value - scene mode (See3CAM130E.SCENE_NORMAL or
//					  SCENE_DOCUMENT)
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSceneMode(value) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "sceneMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "normalMode") {
                    child.checked = (value === See3CAM130E.SCENE_NORMAL)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "documentMode") {
                    child.checked = (value === See3CAM130E.SCENE_DOCUMENT)
                    changedFields.push({ id: child.id, checked: child.checked })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Special Effects  (SpecialEffect130E)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateEffectMode(value)
//
//  PURPOSE		:	To check the matching radio button (normal, black & white,
//					grayscale, negative, sketch) in the "specialEffect" group
//					for the effect reported by the camera.
//
//	ARGUMENTS	:	value - special effect mode (See3CAM130E.EFFECT_*)
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateEffectMode(value) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "specialEffect" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if      (child.id === "normalEffect")  child.checked = (value === See3CAM130E.EFFECT_NORMAL)
                else if (child.id === "blackAndWhite") child.checked = (value === See3CAM130E.EFFECT_BLACK_WHITE)
                else if (child.id === "grayScale")     child.checked = (value === See3CAM130E.EFFECT_GREYSCALE)
                else if (child.id === "negative")      child.checked = (value === See3CAM130E.EFFECT_NEGATIVE)
                else if (child.id === "sketch")        child.checked = (value === See3CAM130E.EFFECT_SKETCH)
                changedFields.push({ id: child.id, checked: child.checked })
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// AF Mode  (AfMode130E)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAFMode(value)
//
//  PURPOSE		:	To check the Continuous or One-shot radio in the
//					"autoFocusMode" group for the reported AF mode, and enable
//					the Trigger button only in one-shot mode.
//
//	ARGUMENTS	:	value - AF mode (See3CAM130E.Continuous or OneShot)
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAFMode(value) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "autoFocusMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "continuous") {
                    child.checked = (value === See3CAM130E.Continuous)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "oneShot") {
                    child.checked = (value === See3CAM130E.OneShot)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "trigger") {
                    child.enabled = (value === See3CAM130E.OneShot)   // fix: = not ==
                    changedFields.push({ id: child.id, enabled: child.enabled })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// AF Rectangle  (enable/disable)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAFRectMode(value)
//
//  PURPOSE		:	To check the Enable or Disable radio in the "afRectangle"
//					group based on the reported AF rectangle overlay state.
//
//	ARGUMENTS	:	value - AF rectangle state (See3CAM130E.Enable or Disable)
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAFRectMode(value) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "afRectangle" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "enableAfRect") {
                    child.checked = (value === See3CAM130E.Enable)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "disableAfRect") {
                    child.checked = (value === See3CAM130E.Disable)
                    changedFields.push({ id: child.id, checked: child.checked })
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
//  PURPOSE		:	To show the exposure compensation value read from the
//					camera in the "expCompValue" text box.
//
//	ARGUMENTS	:	expComp - exposure compensation value
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateExposureComp(expComp) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
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
//  PURPOSE		:	To set the "qFactorVal" slider to the JPEG Q factor read
//					from the camera.
//
//	ARGUMENTS	:	qFactor - Q factor value
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateQFactor(qFactor) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
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
//  PURPOSE		:	To pass the burst length to prevController (used for still
//					capture) and select it in the "burstLen" dropdown of the
//					"imageCapture" group.
//
//	ARGUMENTS	:	burstLength - number of frames captured per still burst
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateBurstLength(burstLength) {

    prevController.setBurstLength(burstLength)
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
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
// Flip Mode  (FlipMode130E)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlipMode(flipMode)
//
//  PURPOSE		:	To check the Horizontal/Vertical flip check boxes from the
//					reported flip mode and cache the state in
//					isHorizontalFlip/isVerticalFlip for later flip requests.
//
//	ARGUMENTS	:	flipMode - flip mode (See3CAM130E.HORZ_ONLY, VERT_ONLY or
//					  BOTH_ENABLE; anything else means no flip)
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFlipMode(flipMode) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horizontal") {
                    child.checked    = (flipMode === See3CAM130E.HORZ_ONLY ||
                                        flipMode === See3CAM130E.BOTH_ENABLE)
                    isHorizontalFlip = child.checked
                    if (flipMode === See3CAM130E.BOTH_ENABLE) isVerticalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "vertical") {
                    child.checked  = (flipMode === See3CAM130E.VERT_ONLY ||
                                      flipMode === See3CAM130E.BOTH_ENABLE)
                    isVerticalFlip = child.checked
                    if (flipMode === See3CAM130E.BOTH_ENABLE) isHorizontalFlip = true
                    changedFields.push({ id: child.id, checked: child.checked })
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Auto Exposure
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAutoExposure(autoExposure)
//
//  PURPOSE		:	To display the current auto exposure value read from the
//					camera in the "autoAEValue" field of the "currentAE"
//					group.
//
//	ARGUMENTS	:	autoExposure - current auto exposure value
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAutoExposure(autoExposure) {
    var changedFields = []

    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "currentAE" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "autoAEValue") {
                    group.children[j].text = autoExposure.toString()
                    changedFields.push({
                        id:   group.children[j].id,
                        text: group.children[j].text
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
// Flash Mode  (FlashMode130E)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlashMode(flashMode)
//
//  PURPOSE		:	To check the Disable, Strobe or Torch radio in the
//					"flashMode" group to match the flash mode reported by the
//					camera.
//
//	ARGUMENTS	:	flashMode - flash mode (See3CAM130E.DISABLE, STROBE or
//					  TORCH)
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFlashMode(flashMode) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "flashMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if      (child.id === "disableMode") child.checked = (flashMode === See3CAM130E.DISABLE)
                else if (child.id === "strobeMode")  child.checked = (flashMode === See3CAM130E.STROBE)
                else if (child.id === "torchMode")   child.checked = (flashMode === See3CAM130E.TORCH)
                changedFields.push({ id: child.id, checked: child.checked })
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
//  PURPOSE		:	To update the "faceDetection" group from the camera: check
//					Enable/Disable, enable the Embedded Data and Overlay
//					Rectangle check boxes only when detection is on, set their
//					checked state and cache it in
//					isEmbedDataEnabled/isOverlayRectEnabled.
//
//	ARGUMENTS	:	mode - See3CAM130E.FDEnable or FDDisable
//					embedData - See3CAM130E.EmbedDataEnable when face data is
//					  embedded in frames
//					overlayRect - See3CAM130E.RectEnable when the face
//					  rectangle overlay is on
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFaceDetectMode(mode, embedData, overlayRect) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "faceDetection" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "enableFaceDet") {
                    child.checked = (mode === See3CAM130E.FDEnable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "disableFaceDet") {
                    child.checked = (mode === See3CAM130E.FDDisable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "embeddedData") {
                    child.enabled         = (mode === See3CAM130E.FDEnable)
                    child.checked         = (embedData === See3CAM130E.EmbedDataEnable)
                    isEmbedDataEnabled    = child.checked
                    changedFields.push({
                        id:      child.id,
                        enabled: child.enabled,
                        checked: child.checked
                    })

                } else if (child.id === "overlayRect") {
                    child.enabled        = (mode === See3CAM130E.FDEnable)
                    child.checked        = (overlayRect === See3CAM130E.RectEnable)
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

// ----------------------------------------------------------------
// Smile Detection
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSmileDetectMode(mode, embedData)
//
//  PURPOSE		:	To update the "smileDetection" group from the camera:
//					check Enable/Disable and enable the embedded smile-data
//					check box only when detection is on, setting its checked
//					state.
//
//	ARGUMENTS	:	mode - See3CAM130E.SmileDetectEnable or SmileDetectDisable
//					embedData - See3CAM130E.SmileDetectEmbedDataEnable when
//					  smile data is embedded in frames
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSmileDetectMode(mode, embedData) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "smileDetection" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "enableSmileDet") {
                    child.checked = (mode === See3CAM130E.SmileDetectEnable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "disableSmileDet") {
                    child.checked = (mode === See3CAM130E.SmileDetectDisable)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "embeddedSmileDetectData") {
                    child.enabled = (mode === See3CAM130E.SmileDetectEnable)
                    child.checked = (embedData === See3CAM130E.SmileDetectEmbedDataEnable)
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
// AF Position
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAFPosition(afPosition)
//
//  PURPOSE		:	To display the current auto focus lens position in the
//					"autoAFValue" field of the "currentAFPos" group.
//
//	ARGUMENTS	:	afPosition - current AF lens position
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAFPosition(afPosition) {
    var changedFields = []

    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "currentAFPos" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "autoAFValue") {
                    group.children[j].text = afPosition.toString()
                    changedFields.push({
                        id:   group.children[j].id,
                        text: group.children[j].text
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
// Frame Rate
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFrameRate(frameRate)
//
//  PURPOSE		:	To set the "frameRate" slider in the "frameRateControl"
//					group to the frame rate control value read from the
//					camera.
//
//	ARGUMENTS	:	frameRate - frame rate control value
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateFrameRate(frameRate) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
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
// Anti Flicker  (FlickerMode130E)
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAntiFlickerMode(flickerMode)
//
//  PURPOSE		:	To update the "antiFlicker" group: check the Off, Auto or
//					Manual radio and, for 50/60 Hz modes, enable the
//					"frequency" dropdown and select "50 Hz" or "60 Hz".
//
//	ARGUMENTS	:	flickerMode - See3CAM130E.MODE_DISABLE, MODE_AUTO,
//					  MODE_50Hz or MODE_60Hz
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAntiFlickerMode(flickerMode) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "offMode") {
                    child.checked = (flickerMode === See3CAM130E.MODE_DISABLE)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoMode") {
                    child.checked = (flickerMode === See3CAM130E.MODE_AUTO)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualMode") {
                    child.checked = (flickerMode === See3CAM130E.MODE_50Hz ||
                                     flickerMode === See3CAM130E.MODE_60Hz)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "frequency") {
                    child.enabled      = (flickerMode === See3CAM130E.MODE_50Hz ||
                                          flickerMode === See3CAM130E.MODE_60Hz)
                    child.currentValue = (flickerMode === See3CAM130E.MODE_60Hz) ? "60 Hz" : "50 Hz"
                    child.selected     = (flickerMode === See3CAM130E.MODE_60Hz) ? "60 Hz" : "50 Hz"
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
// Red Gain
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRedGain(minVal, maxVal, currentVal)
//
//  PURPOSE		:	To set the min, max and current value of the "redGain_s"
//					slider from the red gain reported by the camera.
//
//	ARGUMENTS	:	minVal - minimum red gain
//					maxVal - maximum red gain
//					currentVal - current red gain
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateRedGain(minVal, maxVal, currentVal) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "redGain" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "redGain_s") {
                    group.children[j].min          = minVal
                    group.children[j].max          = maxVal
                    group.children[j].currentValue = currentVal
                    changedFields.push({
                        id:           group.children[j].id,
                        min:          minVal,
                        max:          maxVal,
                        currentValue: currentVal
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
// Blue Gain
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBlueGain(minVal, maxVal, currentVal)
//
//  PURPOSE		:	To set the min, max and current value of the "blueGain_s"
//					slider from the blue gain reported by the camera.
//
//	ARGUMENTS	:	minVal - minimum blue gain
//					maxVal - maximum blue gain
//					currentVal - current blue gain
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateBlueGain(minVal, maxVal, currentVal) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "blueGain" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "blueGain_s") {
                    group.children[j].min          = minVal
                    group.children[j].max          = maxVal
                    group.children[j].currentValue = currentVal
                    changedFields.push({
                        id:           group.children[j].id,
                        min:          minVal,
                        max:          maxVal,
                        currentValue: currentVal
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
// Green Gain
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGreenGain(minVal, maxVal, currentVal)
//
//  PURPOSE		:	To set the min, max and current value of the "greenGain_s"
//					slider from the green gain reported by the camera.
//
//	ARGUMENTS	:	minVal - minimum green gain
//					maxVal - maximum green gain
//					currentVal - current green gain
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateGreenGain(minVal, maxVal, currentVal) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "greenGain" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "greenGain_s") {
                    group.children[j].min          = minVal
                    group.children[j].max          = maxVal
                    group.children[j].currentValue = currentVal
                    changedFields.push({
                        id:           group.children[j].id,
                        min:          minVal,
                        max:          maxVal,
                        currentValue: currentVal
                    })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

//-----------------------------------------------------------------
// Auto Save Configuration
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAutoSaveConfig(autoSaveMode)
//
//  PURPOSE		:	To check the "autoSave" check box when the camera reports
//					that auto-save configuration is enabled.
//
//	ARGUMENTS	:	autoSaveMode - See3CAM130E.AUTO_SAVE_ENABLE when enabled
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAutoSaveConfig(autoSaveMode) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "autoSaveConfig" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "autoSave") {
                    child.checked = (autoSaveMode === See3CAM130E.AUTO_SAVE_ENABLE)
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
//  PURPOSE		:	To show the 64-bit serial number read from the camera in
//					the "serialNumber" field.
//
//	ARGUMENTS	:	serialNum - serial number string
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateSerialNumber(serialNum) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
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
//  PURPOSE		:	To set the "denoise" slider in the "denoiseStrength" group
//					to the denoise value read from the camera.
//
//	ARGUMENTS	:	value - denoise strength
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateDenoiseValue(value) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
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
// ROI AF Mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRoiAFMode(roiMode, winSize)
//
//  PURPOSE		:	To update the "roiAutoFocus" group: check the Centered or
//					Manual radio, enable the "manualAF" window-size dropdown
//					only in manual mode, and select the reported window size
//					(cached in afWindowSize).
//
//	ARGUMENTS	:	roiMode - See3CAM130E.AF_Centered or AF_Manual
//					winSize - AF ROI window size
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateRoiAFMode(roiMode, winSize) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "roiAutoFocus" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "centeredRoiAF") {
                    child.checked = (roiMode === See3CAM130E.AF_Centered)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualRoiAF") {
                    child.checked = (roiMode === See3CAM130E.AF_Manual)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualAF") {
                    child.enabled = (roiMode === See3CAM130E.AF_Manual)
                   // if (roiMode === See3CAM130E.AF_Manual) {
                        afWindowSize       = winSize
                        child.currentValue = winSize
                        child.selected     = winSize
                   // }
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
// ROI AE Mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRoiAEMode(roiMode, winSize)
//
//  PURPOSE		:	To update the "roiAE" group: check the Full or Manual
//					radio, enable the "manualAE" window-size dropdown only in
//					manual mode and, in manual mode, select the window size
//					(cached in aeWindowSize).
//
//	ARGUMENTS	:	roiMode - See3CAM130E.AE_Full or AE_Manual
//					winSize - AE ROI window size
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateRoiAEMode(roiMode, winSize) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "roiAE" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "fullROIAE") {
                    child.checked = (roiMode === See3CAM130E.AE_Full)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualROIAE") {
                    child.checked = (roiMode === See3CAM130E.AE_Manual)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualAE") {
                    child.enabled = (roiMode === See3CAM130E.AE_Manual)
                    if (roiMode === See3CAM130E.AE_Manual) {
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
// Stream Mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStreamMode(streamMode)
//
//  PURPOSE		:	To check the Master or Trigger radio in the "streamMode"
//					group; in trigger mode also show a message that frames are
//					output only on external hardware pulses (PIN 5 of CN3).
//
//	ARGUMENTS	:	streamMode - See3CAM130E.STREAM_MASTER or STREAM_TRIGGER
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateStreamMode(streamMode) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "streamMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "masterMode") {
                    child.checked = (streamMode === See3CAM130E.STREAM_MASTER)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "triggerMode") {
                    child.checked = (streamMode === See3CAM130E.STREAM_TRIGGER)
                    changedFields.push({ id: child.id, checked: child.checked })
                    if(child.checked){
                        setTextMessage("Frames will be out only when external hardware pulses are given to PIN 5 of CN3.")
                    }
                }
            }
            break
        }
    }
    return changedFields
}

// ----------------------------------------------------------------
// Auto White Balance
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAWB(awbValue)
//
//  PURPOSE		:	To display the current auto white balance value in the
//					"autoWBValue" field of the "autoWB" group.
//
//	ARGUMENTS	:	awbValue - current auto white balance value
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateAWB(awbValue) {
    var changedFields = []

    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "autoWB" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "autoWBValue") {
                    child.text = awbValue.toString()
                    changedFields.push({
                        id:   child.id,
                        text: child.text
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
// Firmware Version
// ----------------------------------------------------------------
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
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
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
// HDR Mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateHDRMode(hdrMode, hdrValue)
//
//  PURPOSE		:	To update the "iHdr" group: check the Off, Auto or Manual
//					radio, enable the "hdrLevel" control only in manual mode,
//					and set its value/selection (as a string) to the HDR
//					level, cached in hdrVal.
//
//	ARGUMENTS	:	hdrMode - See3CAM130E.HdrOff, HdrAuto or HdrManual
//					hdrValue - iHDR level
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function updateHDRMode(hdrMode, hdrValue) {
    var changedFields = []
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var group = see3cam130EHidroperty[i]
        if (group.id === "iHdr" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]

                if (child.id === "offHdrMode") {
                    child.checked = (hdrMode === See3CAM130E.HdrOff)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "autoHdrMode") {
                    child.checked = (hdrMode === See3CAM130E.HdrAuto)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "manualHdrMode") {
                    child.checked = (hdrMode === See3CAM130E.HdrManual)
                    changedFields.push({ id: child.id, checked: child.checked })

                } else if (child.id === "hdrLevel") {
                    child.enabled      = (hdrMode === See3CAM130E.HdrManual)
                    hdrVal             = hdrValue
                    child.currentValue = hdrValue.toString()
                    child.selected     = hdrValue.toString()
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
// Enable / Disable controls based on the exposure mode
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleOnExposureModeChange(mode)
//
//  PURPOSE		:	To enable/disable controls that depend on the UVC exposure
//					mode: the ROI AE and exposure compensation groups are
//					enabled only in auto exposure (manualAE also needs Manual
//					ROI checked). Caches mode in isUvcExposureAuto.
//
//	ARGUMENTS	:	mode - true/1 for UVC auto exposure, false/0 for manual
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function handleOnExposureModeChange(mode) {
    // mode: 0 = Manual, 1 = Auto (adjust based on your actual enum values)
    isUvcExposureAuto = mode

    var changedFields = []

    for (var i = 0; i < see3cam130EHidroperty.length; ++i) {
        var section = see3cam130EHidroperty[i]

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
//  PURPOSE		:	To handle a radio button toggle: map the group
//					identification to its model group, update the checked
//					state (unchecking siblings), enable/disable dependent
//					controls and send scene, effect, iHDR (setiHDRMode),
//					stream, anti-flicker (setFlickerDetection) or face
//					detection (setFaceDetectionRect) to the camera via
//					see3camcu135Controller. AF mode, AF rectangle, ROI AF and
//					ROI AE selections are only logged as unsupported.
//
//	ARGUMENTS	:	identification - radio group identifier from the JSON
//					  (e.g. "sceneModes")
//					id - id of the toggled radio button
//					checked - new checked state
//
//	RETURN		:	Array - changed field objects ({id, ...}) for triggerUpdateSignal()
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []

    // Map identification → parent group id
    var identificationToGroupId = {
        "sceneModes":        "sceneMode",
        "specialEffects":    "specialEffect",
        "autoFocusModes":    "autoFocusMode",
        "afRect":            "afRectangle",
        "roiAF":             "roiAutoFocus",
        "iHdrMode":          "iHdr",
        "streamModes":       "streamMode",
        "roiAEMode":         "roiAE",
        "flashModes":        "flashMode",
        "faceDetectionMode": "faceDetection",
        "smileDetectionMode": "smileDetection",
        "antiFlickerMode":   "antiFlicker"
    }

    // Resolve parent group id from identification
    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    // Now find the section using resolved groupId
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var section = see3cam130EHidroperty[i]

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
                                "normalMode":   See3CAM130E.SCENE_NORMAL,
                                "documentMode": See3CAM130E.SCENE_DOCUMENT
                            }
                            if (sceneMap[id] !== undefined)
                                see3camcu135Controller.setSceneMode(sceneMap[id])

                        } else if (groupId === "specialEffect") {
                            var effectMap = {
                                "normalEffect":  See3CAM130E.EFFECT_NORMAL,
                                "blackAndWhite": See3CAM130E.EFFECT_BLACK_WHITE,
                                "grayScale":     See3CAM130E.EFFECT_GREYSCALE,
                                "negative":      See3CAM130E.EFFECT_NEGATIVE,
                                "sketch":        See3CAM130E.EFFECT_SKETCH
                            }
                            if (effectMap[id] !== undefined)
                                see3camcu135Controller.setEffectMode(effectMap[id])

                        } else if (groupId === "autoFocusMode") {
                            var isOneSHot = (id === "oneShot")
                            for (var k = 0; k < section.children.length; k++) {
                                if (section.children[k].id === "trigger") {
                                    section.children[k].enabled = isOneSHot
                                    changedFields.push({ id: "trigger", enabled: isOneSHot })
                                }
                            }
                            // Auto Focus is not supported in CU135 controller
                            console.log("Auto Focus mode control not implemented for See3CAM_CU135")

                        } else if (groupId === "afRectangle") {
                            // AF Rectangle is not supported in CU135 controller
                            console.log("AF Rectangle control not implemented for See3CAM_CU135")

                        } else if (groupId === "roiAutoFocus") {
                            // ROI Auto Focus is not supported in CU135 controller
                            console.log("ROI Auto Focus control not implemented for See3CAM_CU135")

                        } else if (groupId === "iHdr") {
                            var isManual = (id === "manualHdrMode")
                            for (var k = 0; k < section.children.length; k++) {
                                if (section.children[k].id === "hdrLevel") {
                                    section.children[k].enabled = isManual
                                    changedFields.push({ id: "hdrLevel", enabled: isManual })
                                }
                            }
                            var hdrMap = {
                                "offHdrMode":    See3CAM130E.HdrOff,
                                "autoHdrMode":   See3CAM130E.HdrAuto,
                                "manualHdrMode": See3CAM130E.HdrManual
                            }
                            if (hdrMap[id] !== undefined)
                                see3camcu135Controller.setiHDRMode(hdrMap[id], hdrVal)

                        } else if (groupId === "streamMode") {
                            var streamMap = {
                                "masterMode":  See3CAM130E.STREAM_MASTER,
                                "triggerMode": See3CAM130E.STREAM_TRIGGER
                            }
                            if (streamMap[id] !== undefined)
                                see3camcu135Controller.setStreamMode(streamMap[id])
                            if (id === "triggerMode"){               
                                setTextMessage("Frames will be out only when external hardware pulses are given to PIN 5 of CN3.")
                            }

                        } else if (groupId === "roiAE") {
                            // ROI Auto Exposure is not directly supported in CU135 controller
                            // This control may be handled through UVC or not available
                            console.log("ROI AE control not implemented for See3CAM_CU135")

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
                                "offMode":    See3CAM130E.MODE_DISABLE,
                                "autoMode":   See3CAM130E.MODE_AUTO,
                                "manualMode": See3CAM130E.MODE_50Hz
                            }
                            if (flickerMap[id] !== undefined)
                                if( id == "manualMode"){
                                    if (frequency === "60 Hz") {
                                        see3camcu135Controller.setFlickerDetection(See3CAM130E.MODE_60Hz)
                                    } else if (frequency === "50 Hz") {
                                        see3camcu135Controller.setFlickerDetection(See3CAM130E.MODE_50Hz)
                                    }
                                } else {
                                    see3camcu135Controller.setFlickerDetection(flickerMap[id])
                                }
                        } else if (groupId === "smileDetection") {
                            var isSmileDetectEnabled = (id === "enableSmileDet")
                            var isSmileEmbedChecked = false
                            for (var k = 0; k < section.children.length; k++) {
                                var smileChild = section.children[k]
                                if (smileChild.id === "embeddedSmileDetectData") {
                                    smileChild.enabled = isSmileDetectEnabled
                                    isSmileEmbedChecked = (smileChild.checked === true)
                                    changedFields.push({ id: smileChild.id, enabled: isSmileDetectEnabled })
                                }
                            }
                            see3camcu135Controller.setSmileDetection(isSmileDetectEnabled,
                                                                     isSmileDetectEnabled && isSmileEmbedChecked)
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
                            see3camcu135Controller.setFaceDetectionRect(
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
//  PURPOSE		:	To handle button clicks: "setExpComp" validates the
//					exposure compensation text and writes it, "updateDefault"
//					restores defaults via see3camcu135Controller and re-reads
//					all controls; "trigger", "getAutoWB", "getCurrentAE",
//					"getCurrentAFPos" and "saveConfig" are only logged as
//					unsupported on CU135.
//
//	ARGUMENTS	:	id - id of the clicked button
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id){

    if (id === "trigger") {
        // Auto Focus trigger is not supported in CU135 controller
        console.log("Auto Focus trigger not implemented for See3CAM_CU135")
    } else if (id === "setExpComp") {
        // ----------------------------------------------------------------
        // Find the expCompValue textbox in the JSON and read its text
        // ----------------------------------------------------------------
        var expCompText = ""
    
        for (var i = 0; i < see3cam130EHidroperty.length; i++) {
            var section = see3cam130EHidroperty[i]
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

        see3camcu135Controller.setExposureCompensation(expCompValue)
    } else if (id === "getAutoWB" ){
        // Auto White Balance is not supported in CU135 controller
        console.log("Auto White Balance not implemented for See3CAM_CU135")
    } else if (id === "getCurrentAE"){
        // Get Auto Exposure is not supported in CU135 controller
        console.log("Get Auto Exposure not implemented for See3CAM_CU135")
    } else if (id === "getCurrentAFPos"){
        // Get Auto Focus Position is not supported in CU135 controller
        console.log("Get Auto Focus Position not implemented for See3CAM_CU135")
    } else if ( id === "updateDefault"){
        see3camcu135Controller.setToDefault()
        getCameraControls()
    } else if (id === "saveConfig"){
        // Save Configuration is not supported in CU135 controller
        console.log("Save Configuration not implemented for See3CAM_CU135")
    }
}

// ----------------------------------------------------------------
// Handle Text box value change
// ----------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, text)
//
//  PURPOSE		:	To store text typed into a text box (e.g. exposure
//					compensation) in the matching model entry so it can be
//					read when its Set button is clicked.
//
//	ARGUMENTS	:	id - id of the text box control
//					text - new text
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(id, text){
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var section = see3cam130EHidroperty[i]
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
//  PURPOSE		:	To store a slider's new value in the model and write
//					denoise, Q factor or frame rate control values to the
//					camera via see3camcu135Controller.
//
//	ARGUMENTS	:	id - id of the slider control
//					currentVal - new slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id,currentVal){
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var section = see3cam130EHidroperty[i]
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
        see3camcu135Controller.setDenoiseValue(currentVal)
    } else if(id === "qFactorVal"){
        see3camcu135Controller.setQFactor(currentVal)
    } else if(id === "frameRate"){
        see3camcu135Controller.setFrameRateCtrlValue(currentVal)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a dropdown's new value in the model and apply it:
//					ROI window size (manualAF/manualAE, both sent as manual
//					ROI AE via setROIAutoExposure), burst length (camera and
//					prevController), anti-flicker frequency (50/60 Hz) or
//					manual iHDR level.
//
//	ARGUMENTS	:	id - id of the dropdown control
//					value - newly selected value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value){
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var section = see3cam130EHidroperty[i]
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
    if(id === "manualAF"){
        afWindowSize = value
        see3camcu135Controller.setROIAutoExposure(See3CAM130E.AE_Manual, 0, 0, 0, 0, value)
    } else if(id === "manualAE"){
        aeWindowSize = value
        see3camcu135Controller.setROIAutoExposure(See3CAM130E.AE_Manual, 0, 0, 0, 0, value)
    } else if(id === "burstLen"){
        see3camcu135Controller.setBurstLength(value)
        prevController.setBurstLength(value)
    } else if(id === "frequency"){
        if(value == "50 Hz"){
            see3camcu135Controller.setFlickerDetection(See3CAM130E.MODE_50Hz)
        } else if (value == "60 Hz"){
            see3camcu135Controller.setFlickerDetection(See3CAM130E.MODE_60Hz)
        }
    } else if(id === "hdrLevel"){
        var hdrLevelValue = parseInt(value)
        see3camcu135Controller.setiHDRMode(See3CAM130E.HdrManual, hdrLevelValue)
    }
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
function handleRightClick(x, y, width, height){
    if(isUvcExposureAuto){
        see3camcu135Controller.setROIAutoExposure(See3CAM130E.AE_Manual, x, y, width, height, aeWindowSize)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box state in the model and apply it via
//					see3camcu135Controller: face-detect embedded data /
//					overlay rectangle (setFaceDetectionRect),
//					horizontal/vertical flip (setOrientation) or embedded
//					smile-detect data (setSmileDetection).
//
//	ARGUMENTS	:	id - id of the check box
//					checked - new checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked){
    for (var i = 0; i < see3cam130EHidroperty.length; i++) {
        var section = see3cam130EHidroperty[i]
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
        see3camcu135Controller.setFaceDetectionRect(
            true,   // enable/disable determined by overlayRect state
            checked,    // embedData follows checkbox state
            isOverlayRectEnabled    // overlayRect follows its own checkbox state
        )
    } else if(id === "overlayRect"){
        isOverlayRectEnabled = checked
        see3camcu135Controller.setFaceDetectionRect(
            true,   // enable/disable determined by embeddedData state
            isEmbedDataEnabled,    // embedData follows its own checkbox state
            checked    // overlayRect follows checkbox state
        )
    } else if (id === "horizontal"){
        isHorizontalFlip = checked
        see3camcu135Controller.setOrientation(checked, isVerticalFlip)
    } else if (id === "vertical"){
        isVerticalFlip = checked
        see3camcu135Controller.setOrientation(isHorizontalFlip, checked)
    } else if (id === "embeddedSmileDetectData"){
        see3camcu135Controller.setSmileDetection(true, checked)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getAutoFocusControls()
//
//  PURPOSE		:	To satisfy the common module interface; auto focus is not
//					supported on CU135, so it only logs a message.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getAutoFocusControls(){
    // Auto Focus controls are not supported in CU135 controller
    console.log("Auto Focus controls not implemented for See3CAM_CU135")
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getAutoExposureControls()
//
//  PURPOSE		:	To satisfy the common module interface; CU135 has no AE
//					getter here, so it only logs a message (values arrive via
//					controller signals).
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getAutoExposureControls(){  
    // Auto Exposure getter is not supported in CU135 controller
    // Status updates come via signals from the controller
    console.log("Auto Exposure getter not implemented for See3CAM_CU135")
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getexposureCompFrameRateCtrl()
//
//  PURPOSE		:	To satisfy the common module interface; it only logs that
//					the exposure compensation / frame rate getters are not
//					implemented for CU135.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getexposureCompFrameRateCtrl() {
    // Getter methods not supported in CU135 controller
    // Status updates come via signals from the controller
    console.log("Exposure compensation and frame rate getter not implemented for See3CAM_CU135")
}
