// ----------------------------------------------------------------
// See3CAM_CU200 - JS glue module for the HID accordion (UsbcamHidAccordion.qml)
//
// This module exposes the same function names the generic dispatcher in
// UsbcamHidSettings.qml expects (mirroring See3CAM_24CUG.js): getCameraControls,
// getDelayedCameraControls, updateModelData, clearData, updateSliderValue,
// handleRadioButtonChange, handleDropBoxValueChanged, updateCheckBoxValue,
// updateTextBoxField, handleButtonClick, handleRightClick. The per-signal
// updateXxx() functions below are called directly from a dedicated
// `Connections { target: see3camcu200Controller ... }` block added to
// UsbcamHidSettings.qml.
// ----------------------------------------------------------------

var see3camcu200HidProperty = []

// Cached multi-field state - the SDK's setExposure/setWhiteBalanceMode/
// setRoiAutoExposure calls all require the *entire* set of fields on every
// call, so we track the last-known values here and resend them whenever any
// one field changes (mirrors the isUvcExposureAuto-style caching used by
// See3CAM_24CUG.js).
var currentExposureMode = See3CAMCU200.MANUAL_EXPOSURE
var currentExposureAutoFeature = See3CAMCU200.CONTINIOUS_EXPOSURE
var currentManualExposureValue = 30000

var currentWbMode = See3CAMCU200.MANUAL_WB
var currentWbAutoFeature = See3CAMCU200.WB_CONTINIOUS
var currentWbManualFeature = See3CAMCU200.WB_COLOR_TEMPERATURE
var currentWbPreset = See3CAMCU200.D65_6500K

var currentRoiMode = See3CAMCU200.FULL_ROI
var currentRoiWindowSize = 4

var isHorizontalFlip = false
var isVerticalFlip = false

var wbPresetLabels = ["HZ(2300K)", "A(2800K)", "U30(3000K)", "TL84(4000K)", "CWF(4100K)", "D50(5000K)", "D60(6000K)", "D65(6500K)"]

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To cache the JSON property model (HID accordion sections and
//					their child controls) loaded by UsbcamHidSettings.qml in
//					see3camcu200HidProperty, so the other functions can read and
//					update it.
//
//	ARGUMENTS	:	jsonArray - Array of section objects parsed from the camera's
//					  JSON file
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camcu200HidProperty = jsonArray
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the cached JSON property model
//					(see3camcu200HidProperty) so UsbcamHidSettings.qml can bind it
//					to the HID accordion.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current property model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return see3camcu200HidProperty
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To start the QML delayedControlsTimer, whose handler calls
//					getDelayedCameraControls() so the See3CAM_CU200 HID values are
//					queried only after the UI is ready.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getCameraControls() {
    delayedControlsTimer.start()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To request all HID control values from the See3CAM_CU200
//					(image controls, black level, target brightness, color
//					temperature, RB gain, CCM, exposure, exposure compensation,
//					gain limit, AE ROI, camera/strobe mode, orientation, anti-
//					flicker, white balance, denoise, ISP firmware, serial number
//					and firmware version). Results arrive via controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    see3camcu200Controller.getBrightness()
    see3camcu200Controller.getContrast()
    see3camcu200Controller.getSaturation()
    see3camcu200Controller.getGammaCorrection()
    see3camcu200Controller.getSharpnessStrength()
    see3camcu200Controller.getBlackLevel()
    see3camcu200Controller.getTargetBrightness()
    see3camcu200Controller.getColorTemperature()
    see3camcu200Controller.getRBGain()
    see3camcu200Controller.getColorCorrectionMatrix()
    see3camcu200Controller.getExposure()
    see3camcu200Controller.getExposureCompensation()
    see3camcu200Controller.getAutoGainUpperLimit()
    see3camcu200Controller.getAutoExpROIModeAndWindowSize()
    see3camcu200Controller.getCameraMode()
    see3camcu200Controller.getStrobeMode()
    see3camcu200Controller.getOrientation()
    see3camcu200Controller.getAntiFlickerMode()
    see3camcu200Controller.getWhiteBalanceMode()
    see3camcu200Controller.getDenoiseFlag()
    see3camcu200Controller.getDenoiseStrength()
        see3camcu200Controller.readISPFirmwareVersion()
    see3camcu200Controller.get64BitSerialNumber()
    see3camcu200Controller.getFirmwareVersion()

}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached exposure, white balance, AE ROI and flip
//					state to their defaults when the device is closed or switched.
//					The property model itself is kept.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    currentExposureMode = See3CAMCU200.MANUAL_EXPOSURE
    currentExposureAutoFeature = See3CAMCU200.CONTINIOUS_EXPOSURE
    currentManualExposureValue = 30000

    currentWbMode = See3CAMCU200.MANUAL_WB
    currentWbAutoFeature = See3CAMCU200.WB_CONTINIOUS
    currentWbManualFeature = See3CAMCU200.WB_COLOR_TEMPERATURE
    currentWbPreset = See3CAMCU200.D65_6500K

    currentRoiMode = See3CAMCU200.FULL_ROI
    currentRoiWindowSize = 4

    isHorizontalFlip = false
    isVerticalFlip = false
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	findSection(id)
//
//  PURPOSE		:	To look up a top-level section of the property model by its
//					JSON id.
//
//	ARGUMENTS	:	id - JSON id of the section
//
//	RETURN		:	Object - the matching section, or null if not found
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Generic helpers
// ----------------------------------------------------------------
function findSection(id) {
    for (var i = 0; i < see3camcu200HidProperty.length; i++) {
        if (see3camcu200HidProperty[i].id === id) {
            return see3camcu200HidProperty[i]
        }
    }
    return null
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	findChild(section, id)
//
//  PURPOSE		:	To look up a child control of a section by its JSON id.
//
//	ARGUMENTS	:	section - Section object (may be null)
//					id - JSON id of the child control
//
//	RETURN		:	Object - the matching child, or null if not found
///////////////////////////////////////////////////////////////////////////
function findChild(section, id) {
    if (!section || !section.children) return null
    for (var j = 0; j < section.children.length; j++) {
        if (section.children[j].id === id) return section.children[j]
    }
    return null
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	pushSliderUpdate(changedFields, sectionId, childId, min, max, step, current)
//
//  PURPOSE		:	To store min, max, step and current value on a slider child in
//					the model and append the corresponding change entry to
//					changedFields. Does nothing if the section or child is
//					missing.
//
//	ARGUMENTS	:	changedFields - Array the change entry is appended to
//					sectionId - JSON id of the section
//					childId - JSON id of the slider
//					min - Minimum slider value
//					max - Maximum slider value
//					step - Slider step size
//					current - Current slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function pushSliderUpdate(changedFields, sectionId, childId, min, max, step, current) {
    var section = findSection(sectionId)
    var child = findChild(section, childId)
    if (child) {
        child.min = min
        child.max = max
        child.step = step
        child.currentValue = current
        changedFields.push({ id: childId, currentValue: current, min: min, max: max, step: step })
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBrightness(min, max, step, current)
//
//  PURPOSE		:	To update the brightness slider ("brightnessSlider" in the
//					"brightness" section) with the range, step and current value
//					read from the camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Brightness / Contrast / Saturation / Gamma / Sharpness
// ----------------------------------------------------------------
function updateBrightness(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "brightness", "brightnessSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateContrast(min, max, step, current)
//
//  PURPOSE		:	To update the contrast slider ("contrastSlider" in the
//					"contrast" section) with the range, step and current value
//					read from the camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateContrast(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "contrast", "contrastSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSaturation(min, max, step, current)
//
//  PURPOSE		:	To update the saturation slider ("saturationSlider" in the
//					"saturation" section) with the range, step and current value
//					read from the camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateSaturation(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "saturation", "saturationSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGamma(min, max, step, current)
//
//  PURPOSE		:	To update the gamma correction slider ("gammaSlider" in the
//					"gamma" section) with the range, step and current value read
//					from the camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateGamma(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "gamma", "gammaSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSharpness(min, max, step, current)
//
//  PURPOSE		:	To update the sharpness strength slider ("sharpnessSlider" in
//					the "denoise" section) with the range, step and current value
//					read from the camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateSharpness(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "denoise", "sharpnessSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBlackLevel(min, max, step, current)
//
//  PURPOSE		:	To update the black level slider ("blackLevelSlider" in the
//					"blackLevel" section) with the range, step and current value
//					read from the camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Black Level / Target Brightness / Color Temperature
// ----------------------------------------------------------------
function updateBlackLevel(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "blackLevel", "blackLevelSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTargetBrightness(min, max, step, current)
//
//  PURPOSE		:	To update the target brightness slider
//					("targetBrightnessSlider" in the "targetBrightness" section)
//					with the range, step and current value read from the camera,
//					via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateTargetBrightness(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "targetBrightness", "targetBrightnessSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateColorTemperature(min, max, step, current)
//
//  PURPOSE		:	To update both color temperature sliders ("colorTempSlider" in
//					"colorTemp" and "colorTemperatureSlider" in
//					"manualWhiteBalance") with the range, step and current value
//					read from the camera.
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateColorTemperature(min, max, step, current) {
    var changedFields = []
    // Shared by two UI locations - see the comment on "colorTempSlider" / "colorTemperatureSlider" in See3CAM_CU200.json.
    pushSliderUpdate(changedFields, "colorTemp", "colorTempSlider", min, max, step, current)
    pushSliderUpdate(changedFields, "manualWhiteBalance", "colorTemperatureSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRGain(min, max, step, current)
//
//  PURPOSE		:	To update the red gain slider ("rGainSlider" in the "rgbGain"
//					section) with the range, step and current value read from the
//					camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// RGB Gain / Color Correction Matrix
// ----------------------------------------------------------------
function updateRGain(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "rgbGain", "rGainSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBGain(min, max, step, current)
//
//  PURPOSE		:	To update the blue gain slider ("bGainSlider" in the "rgbGain"
//					section) with the range, step and current value read from the
//					camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateBGain(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "rgbGain", "bGainSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateColorCorrectionMatrix(Rr, Rg, Rb, Gr, Gg, Gb, Br, Bg, Bb)
//
//  PURPOSE		:	To set the nine color correction matrix sliders (ccmRr ...
//					ccmBb) in the "colorCorrectionMatrix" section to the values
//					read from the camera.
//
//	ARGUMENTS	:	Rr - Red-from-red coefficient
//					Rg - Red-from-green coefficient
//					Rb - Red-from-blue coefficient
//					Gr - Green-from-red coefficient
//					Gg - Green-from-green coefficient
//					Gb - Green-from-blue coefficient
//					Br - Blue-from-red coefficient
//					Bg - Blue-from-green coefficient
//					Bb - Blue-from-blue coefficient
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateColorCorrectionMatrix(Rr, Rg, Rb, Gr, Gg, Gb, Br, Bg, Bb) {
    var changedFields = []
    var section = findSection("colorCorrectionMatrix")
    var values = { ccmRr: Rr, ccmRg: Rg, ccmRb: Rb, ccmGr: Gr, ccmGg: Gg, ccmGb: Gb, ccmBr: Br, ccmBg: Bg, ccmBb: Bb }
    for (var key in values) {
        var child = findChild(section, key)
        if (child) {
            child.currentValue = values[key]
            changedFields.push({ id: key, currentValue: values[key] })
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposure(mode, autoFeature, manualValue)
//
//  PURPOSE		:	To cache the exposure settings read from the camera and
//					reflect them in the "exposure" section: check auto/manual, set
//					continuous/single-shot (enabled only in auto) and set the
//					manual exposure slider (enabled only in manual).
//
//	ARGUMENTS	:	mode - Exposure mode (See3CAMCU200.AUTO_EXPOSURE or
//					  MANUAL_EXPOSURE)
//					autoFeature - Auto exposure feature (CONTINIOUS_EXPOSURE or
//					  SINGLE_SHOT_EXPOSURE)
//					manualValue - Manual exposure value
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Exposure
// ----------------------------------------------------------------
function updateExposure(mode, autoFeature, manualValue) {
    currentExposureMode = mode
    currentExposureAutoFeature = autoFeature
    currentManualExposureValue = manualValue

    var changedFields = []
    var section = findSection("exposure")
    if (!section) return changedFields

    var isAuto = (mode === See3CAMCU200.AUTO_EXPOSURE)

    var autoChild = findChild(section, "autoExposure")
    var manualChild = findChild(section, "manualExposure")
    if (autoChild) { autoChild.checked = isAuto; changedFields.push({ id: "autoExposure", checked: isAuto }) }
    if (manualChild) { manualChild.checked = !isAuto; changedFields.push({ id: "manualExposure", checked: !isAuto }) }

    var continuousChild = findChild(section, "continuousExposure")
    var singleShotChild = findChild(section, "singleShotExposure")
    if (continuousChild) {
        continuousChild.checked = (autoFeature === See3CAMCU200.CONTINIOUS_EXPOSURE)
        continuousChild.enabled = isAuto
        changedFields.push({ id: "continuousExposure", checked: continuousChild.checked, enabled: isAuto })
    }
    if (singleShotChild) {
        singleShotChild.checked = (autoFeature === See3CAMCU200.SINGLE_SHOT_EXPOSURE)
        singleShotChild.enabled = isAuto
        changedFields.push({ id: "singleShotExposure", checked: singleShotChild.checked, enabled: isAuto })
    }

    var manualSlider = findChild(section, "manualExposureSlider")
    if (manualSlider) {
        manualSlider.currentValue = manualValue
        manualSlider.enabled = !isAuto
        changedFields.push({ id: "manualExposureSlider", currentValue: manualValue, enabled: !isAuto })
    }

    return changedFields
}

// Bridges the generic usbcamRect.setExposureMode(bool) signal (used by a
// handful of other cameras for a UVC-level auto-exposure toggle outside the
// HID accordion) onto our own HID Exposure section, in case it is ever
// raised for this device type. true = Auto, false = Manual.
function setExposureMode(mode) {
    currentExposureMode = mode ? See3CAMCU200.AUTO_EXPOSURE : See3CAMCU200.MANUAL_EXPOSURE
    see3camcu200Controller.setExposure(currentExposureMode, currentExposureAutoFeature, currentManualExposureValue)
    return updateExposure(currentExposureMode, currentExposureAutoFeature, currentManualExposureValue)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposureCompensation(value)
//
//  PURPOSE		:	To show the exposure compensation value read from the camera
//					on both the "exposureCompensationSlider" slider and the
//					"expCompValue" text box.
//
//	ARGUMENTS	:	value - Exposure compensation value from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateExposureCompensation(value) {
    var changedFields = []
    var section = findSection("exposureCompensationCU200")
    var child = findChild(section, "exposureCompensationSlider")
    if (child) {
        child.currentValue = value
        changedFields.push({ id: "exposureCompensationSlider", currentValue: value })
    }

    var textSection = findSection("exposureCompensation")
    var textChild = findChild(textSection, "expCompValue")
    if (textChild) {
        textChild.text = value.toString()
        changedFields.push({ id: "expCompValue", text: textChild.text })
    }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAutoGainUpperLimit(min, max, step, current)
//
//  PURPOSE		:	To update the auto gain upper limit slider
//					("autoGainUpperLimitSlider" in the "autoGainUpperLimit"
//					section) with the range, step and current value read from the
//					camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateAutoGainUpperLimit(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "autoGainUpperLimit", "autoGainUpperLimitSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAutoExpROI(roiMode, winSize)
//
//  PURPOSE		:	To cache the AE ROI mode and window size read from the camera,
//					check full/manual ROI and enable and select the
//					"roiWindowSize" drop box only in manual mode.
//
//	ARGUMENTS	:	roiMode - ROI mode (See3CAMCU200.FULL_ROI or MANUAL_ROI)
//					winSize - ROI window size
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateAutoExpROI(roiMode, winSize) {
    currentRoiMode = roiMode
    currentRoiWindowSize = winSize

    var changedFields = []
    var section = findSection("autoExposureROI")
    if (!section) return changedFields

    var isManual = (roiMode === See3CAMCU200.MANUAL_ROI)

    var fullChild = findChild(section, "fullROI")
    var manualChild = findChild(section, "manualROI")
    if (fullChild) { fullChild.checked = !isManual; changedFields.push({ id: "fullROI", checked: !isManual }) }
    if (manualChild) { manualChild.checked = isManual; changedFields.push({ id: "manualROI", checked: isManual }) }

    var winSizeChild = findChild(section, "roiWindowSize")
    if (winSizeChild) {
        winSizeChild.enabled = isManual
        winSizeChild.currentValue = winSize
        winSizeChild.selected = winSize.toString()
        changedFields.push({ id: "roiWindowSize", enabled: isManual, selected: winSizeChild.selected })
    }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCameraMode(mode)
//
//  PURPOSE		:	To check the master or trigger camera mode radio button
//					according to the mode read from the camera.
//
//	ARGUMENTS	:	mode - Camera mode (See3CAMCU200.MASTER_MODE or TRIGGER_MODE)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Camera Mode / Strobe / Orientation / Anti-Flicker
// ----------------------------------------------------------------
function updateCameraMode(mode) {
    var changedFields = []
    var section = findSection("cameraMode")
    var masterChild = findChild(section, "masterCamMode")
    var triggerChild = findChild(section, "triggerCamMode")
    if (masterChild) { masterChild.checked = (mode === See3CAMCU200.MASTER_MODE); changedFields.push({ id: "masterCamMode", checked: masterChild.checked }) }
    if (triggerChild) { triggerChild.checked = (mode === See3CAMCU200.TRIGGER_MODE); changedFields.push({ id: "triggerCamMode", checked: triggerChild.checked }) }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStrobeMode(mode)
//
//  PURPOSE		:	To check the strobe off or strobe on radio button according to
//					the mode read from the camera.
//
//	ARGUMENTS	:	mode - Strobe mode (See3CAMCU200.STROBE_OFF or STROBE_ON)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateStrobeMode(mode) {
    var changedFields = []
    var section = findSection("strobeMode")
    var offChild = findChild(section, "strobeOff")
    var onChild = findChild(section, "strobeOn")
    if (offChild) { offChild.checked = (mode === See3CAMCU200.STROBE_OFF); changedFields.push({ id: "strobeOff", checked: offChild.checked }) }
    if (onChild) { onChild.checked = (mode === See3CAMCU200.STROBE_ON); changedFields.push({ id: "strobeOn", checked: onChild.checked }) }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateOrientation(flipMode)
//
//  PURPOSE		:	To derive horizontal/vertical flip from the orientation read
//					from the camera (ROTATE_180 sets both), cache them in
//					isHorizontalFlip / isVerticalFlip and set the flip check
//					boxes.
//
//	ARGUMENTS	:	flipMode - Orientation (See3CAMCU200.HORIZONTAL, VERTICAL,
//					  ROTATE_180 or normal)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateOrientation(flipMode) {
    isHorizontalFlip = (flipMode === See3CAMCU200.HORIZONTAL || flipMode === See3CAMCU200.ROTATE_180)
    isVerticalFlip = (flipMode === See3CAMCU200.VERTICAL || flipMode === See3CAMCU200.ROTATE_180)

    var changedFields = []
    var section = findSection("orientation")
    var horzChild = findChild(section, "horizontal")
    var vertChild = findChild(section, "vertical")
    if (horzChild) { horzChild.checked = isHorizontalFlip; changedFields.push({ id: "horizontal", checked: isHorizontalFlip }) }
    if (vertChild) { vertChild.checked = isVerticalFlip; changedFields.push({ id: "vertical", checked: isVerticalFlip }) }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAntiFlickerMode(mode)
//
//  PURPOSE		:	To check the 50 Hz, 60 Hz or disable anti-flicker radio button
//					according to the mode read from the camera.
//
//	ARGUMENTS	:	mode - Anti-flicker mode (See3CAMCU200.MODE_50Hz, MODE_60Hz or
//					  MODE_DISABLE)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateAntiFlickerMode(mode) {
    var changedFields = []
    var section = findSection("antiFlicker")
    var c50 = findChild(section, "flicker50Hz")
    var c60 = findChild(section, "flicker60Hz")
    var cOff = findChild(section, "flickerDisable")
    if (c50) { c50.checked = (mode === See3CAMCU200.MODE_50Hz); changedFields.push({ id: "flicker50Hz", checked: c50.checked }) }
    if (c60) { c60.checked = (mode === See3CAMCU200.MODE_60Hz); changedFields.push({ id: "flicker60Hz", checked: c60.checked }) }
    if (cOff) { cOff.checked = (mode === See3CAMCU200.MODE_DISABLE); changedFields.push({ id: "flickerDisable", checked: cOff.checked }) }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateWhiteBalance(mode, autoFeature, manualFeature)
//
//  PURPOSE		:	To cache the white balance settings read from the camera and
//					reflect them: check auto/manual WB, enable the auto or manual
//					WB section, check the auto feature and manual feature radios,
//					and enable the color temperature slider or preset drop box for
//					the active manual feature.
//
//	ARGUMENTS	:	mode - WB mode (See3CAMCU200.AUTO_WB or MANUAL_WB)
//					autoFeature - Auto WB feature (WB_CONTINIOUS or
//					  WB_SINGLE_SHOT)
//					manualFeature - Manual WB feature (WB_COLOR_TEMPERATURE,
//					  WB_PRESET_MODE or WB_PRO_MODE)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// White Balance
// ----------------------------------------------------------------
function updateWhiteBalance(mode, autoFeature, manualFeature) {
    currentWbMode = mode
    currentWbAutoFeature = autoFeature
    currentWbManualFeature = manualFeature

    var changedFields = []
    var isAuto = (mode === See3CAMCU200.AUTO_WB)

    var wbSection = findSection("whiteBalance")
    var autoWbChild = findChild(wbSection, "autoWB")
    var manualWbChild = findChild(wbSection, "manualWb")
    if (autoWbChild) { autoWbChild.checked = isAuto; changedFields.push({ id: "autoWB", checked: isAuto }) }
    if (manualWbChild) { manualWbChild.checked = !isAuto; changedFields.push({ id: "manualWb", checked: !isAuto }) }

    var autoSection = findSection("autoWhiteBalance")
    if (autoSection) { autoSection.enabled = isAuto; changedFields.push({ id: "autoWhiteBalance", enabled: isAuto }) }
    var continuousChild = findChild(autoSection, "continuous")
    var oneShotChild = findChild(autoSection, "oneShot")
    if (continuousChild) { continuousChild.checked = (autoFeature === See3CAMCU200.WB_CONTINIOUS); changedFields.push({ id: "continuous", checked: continuousChild.checked }) }
    if (oneShotChild) { oneShotChild.checked = (autoFeature === See3CAMCU200.WB_SINGLE_SHOT); changedFields.push({ id: "oneShot", checked: oneShotChild.checked }) }

    var manualSection = findSection("manualWhiteBalance")
    if (manualSection) { manualSection.enabled = !isAuto; changedFields.push({ id: "manualWhiteBalance", enabled: !isAuto }) }

    var isColorTemp = (manualFeature === See3CAMCU200.WB_COLOR_TEMPERATURE)
    var isPreset = (manualFeature === See3CAMCU200.WB_PRESET_MODE)
    var isPro = (manualFeature === See3CAMCU200.WB_PRO_MODE)

    var ctChild = findChild(manualSection, "colorTemperature")
    var presetChild = findChild(manualSection, "presetManualWb")
    var proChild = findChild(manualSection, "proMode")
    if (ctChild) { ctChild.checked = isColorTemp; changedFields.push({ id: "colorTemperature", checked: isColorTemp }) }
    if (presetChild) { presetChild.checked = isPreset; changedFields.push({ id: "presetManualWb", checked: isPreset }) }
    if (proChild) { proChild.checked = isPro; changedFields.push({ id: "proMode", checked: isPro }) }

    var ctSlider = findChild(manualSection, "colorTemperatureSlider")
    var presetDrop = findChild(manualSection, "manualPreset")
    if (ctSlider) { ctSlider.enabled = !isAuto && isColorTemp; changedFields.push({ id: "colorTemperatureSlider", enabled: ctSlider.enabled }) }
    if (presetDrop) { presetDrop.enabled = !isAuto && isPreset; changedFields.push({ id: "manualPreset", enabled: presetDrop.enabled }) }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateWhiteBalancePreset(presetMode)
//
//  PURPOSE		:	To cache the WB preset read from the camera and select its
//					label (from wbPresetLabels) in the "manualPreset" drop box.
//					Out-of-range values are ignored.
//
//	ARGUMENTS	:	presetMode - Preset index into wbPresetLabels (See3CAMCU200
//					  preset enum)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateWhiteBalancePreset(presetMode) {
    currentWbPreset = presetMode
    var changedFields = []
    var manualSection = findSection("manualWhiteBalance")
    var presetDrop = findChild(manualSection, "manualPreset")
    if (presetDrop && presetMode >= 0 && presetMode < wbPresetLabels.length) {
        presetDrop.currentValue = wbPresetLabels[presetMode]
        presetDrop.selected = wbPresetLabels[presetMode]
        changedFields.push({ id: "manualPreset", selected: presetDrop.selected })
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDenoiseFlag(flag)
//
//  PURPOSE		:	To check the enable or disable denoise radio button according
//					to the denoise flag read from the camera.
//
//	ARGUMENTS	:	flag - true if denoising is enabled
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Denoise
// ----------------------------------------------------------------
function updateDenoiseFlag(flag) {
    var changedFields = []
    var section = findSection("denoise")
    var enableChild = findChild(section, "enableDenoise")
    var disableChild = findChild(section, "disableDenoise")
    if (enableChild) { enableChild.checked = flag; changedFields.push({ id: "enableDenoise", checked: flag }) }
    if (disableChild) { disableChild.checked = !flag; changedFields.push({ id: "disableDenoise", checked: !flag }) }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDenoiseStrength(min, max, step, current)
//
//  PURPOSE		:	To update the denoise strength slider ("denoiseStrengthSlider"
//					in the "denoise" section) with the range, step and current
//					value read from the camera, via pushSliderUpdate().
//
//	ARGUMENTS	:	min - Minimum value reported by the camera
//					max - Maximum value reported by the camera
//					step - Step size reported by the camera
//					current - Current value reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateDenoiseStrength(min, max, step, current) {
    var changedFields = []
    pushSliderUpdate(changedFields, "denoise", "denoiseStrengthSlider", min, max, step, current)
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStatistics(exposure, autoGain, rGain, bGain, Rr, Rg, Rb, Gr, Gg, Gb, Br, Bg, Bb)
//
//  PURPOSE		:	To show the statistics read by readStatistics() (exposure,
//					auto gain, R/B gain and the nine CCM coefficients) in the text
//					fields of the "statistics" section.
//
//	ARGUMENTS	:	exposure - Current exposure
//					autoGain - Current auto gain
//					rGain - Current red gain
//					bGain - Current blue gain
//					Rr - CCM red-from-red
//					Rg - CCM red-from-green
//					Rb - CCM red-from-blue
//					Gr - CCM green-from-red
//					Gg - CCM green-from-green
//					Gb - CCM green-from-blue
//					Br - CCM blue-from-red
//					Bg - CCM blue-from-green
//					Bb - CCM blue-from-blue
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Statistics
// ----------------------------------------------------------------
function updateStatistics(exposure, autoGain, rGain, bGain, Rr, Rg, Rb, Gr, Gg, Gb, Br, Bg, Bb) {
    var changedFields = []
    var section = findSection("statistics")
    var values = {
        statExposure: exposure, statAutoGain: autoGain, statRGain: rGain, statBGain: bGain,
        statCcmRr: Rr, statCcmRg: Rg, statCcmRb: Rb,
        statCcmGr: Gr, statCcmGg: Gg, statCcmGb: Gb,
        statCcmBr: Br, statCcmBg: Bg, statCcmBb: Bb
    }
    for (var key in values) {
        var child = findChild(section, key)
        if (child) {
            child.text = values[key].toString()
            changedFields.push({ id: key, text: child.text })
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateIspFirmwareVersion(version)
//
//  PURPOSE		:	To show the ISP firmware version read from the camera in the
//					"ispFirmwareVer" field of the "ispFirmwareVersion" section.
//
//	ARGUMENTS	:	version - ISP firmware version from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// ISP Firmware Version
// ----------------------------------------------------------------
function updateIspFirmwareVersion(version) {
    var changedFields = []
    var section = findSection("ispFirmwareVersion")
    var child = findChild(section, "ispFirmwareVer")
    if (child) {
        child.text = version.toString()
        changedFields.push({ id: "ispFirmwareVer", text: child.text })
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSerialNumber(serialNum)
//
//  PURPOSE		:	To show the 64-bit serial number reported by the controller in
//					the "serialNumber" text field of the "serialNum" section of
//					see3camcu200HidProperty.
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
    for (var i = 0; i < see3camcu200HidProperty.length; i++) {
        var group = see3camcu200HidProperty[i]
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
//					see3camcu200HidProperty.
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
    for (var i = 0; i < see3camcu200HidProperty.length; i++) {
        var group = see3camcu200HidProperty[i]
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
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider's new value in the model and send it to
//					see3camcu200Controller: image/ISP sliders call their setters,
//					R/B gain and CCM sliders resend the whole set, the manual
//					exposure slider resends setExposure() with the cached mode.
//
//	ARGUMENTS	:	id - JSON id of the slider
//					currentVal - New slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Slider changes
// ----------------------------------------------------------------
function updateSliderValue(id, currentVal) {
    for (var i = 0; i < see3camcu200HidProperty.length; i++) {
        var section = see3camcu200HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = currentVal
                    break
                }
            }
        }
    }

    if (id === "brightnessSlider") {
        see3camcu200Controller.setBrightness(currentVal)
    } else if (id === "contrastSlider") {
        see3camcu200Controller.setContrast(currentVal)
    } else if (id === "saturationSlider") {
        see3camcu200Controller.setSaturation(currentVal)
    } else if (id === "gammaSlider") {
        see3camcu200Controller.setGammaCorrection(currentVal)
    } else if (id === "sharpnessSlider") {
        see3camcu200Controller.setSharpnessStrength(currentVal)
    } else if (id === "blackLevelSlider") {
        see3camcu200Controller.setBlackLevel(currentVal)
    } else if (id === "targetBrightnessSlider") {
        see3camcu200Controller.setTargetBrightness(currentVal)
    } else if (id === "colorTempSlider" || id === "colorTemperatureSlider") {
        see3camcu200Controller.setColorTemperature(currentVal)
    } else if (id === "rGainSlider" || id === "bGainSlider") {
        setRBGainFromUi()
    } else if (id === "ccmRr" || id === "ccmRg" || id === "ccmRb" ||
               id === "ccmGr" || id === "ccmGg" || id === "ccmGb" ||
               id === "ccmBr" || id === "ccmBg" || id === "ccmBb") {
        setColorCorrectionMatrixFromUi()
    } else if (id === "manualExposureSlider") {
        currentManualExposureValue = currentVal
        see3camcu200Controller.setExposure(currentExposureMode, currentExposureAutoFeature, currentManualExposureValue)
    } else if (id === "exposureCompensationSlider") {
        see3camcu200Controller.setExposureCompensation(currentVal)
    } else if (id === "autoGainUpperLimitSlider") {
        see3camcu200Controller.setAutoGainUpperLimit(currentVal)
    } else if (id === "denoiseStrengthSlider") {
        see3camcu200Controller.setDenoiseStrength(currentVal)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setRBGainFromUi()
//
//  PURPOSE		:	To read the current red and blue gain slider values from the
//					model and send both to the camera with
//					see3camcu200Controller.setRBGain().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setRBGainFromUi() {
    var section = findSection("rgbGain")
    var rChild = findChild(section, "rGainSlider")
    var bChild = findChild(section, "bGainSlider")
    var rVal = rChild ? rChild.currentValue : 0
    var bVal = bChild ? bChild.currentValue : 0
    see3camcu200Controller.setRBGain(rVal, bVal)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setColorCorrectionMatrixFromUi()
//
//  PURPOSE		:	To read all nine CCM slider values from the model and send
//					them to the camera with
//					see3camcu200Controller.setColorCorrectionMatrix().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setColorCorrectionMatrixFromUi() {
    var section = findSection("colorCorrectionMatrix")
    function val(id) { var c = findChild(section, id); return c ? c.currentValue : 0 }
    see3camcu200Controller.setColorCorrectionMatrix(
        val("ccmRr"), val("ccmRg"), val("ccmRb"),
        val("ccmGr"), val("ccmGg"), val("ccmGb"),
        val("ccmBr"), val("ccmBg"), val("ccmBb")
    )
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle a radio button click: update checked states within
//					the group and, when checked, update the cached state and call
//					the controller (setWhiteBalanceMode, setExposure,
//					setROIAutoExposure, setCameraMode, setStrobeMode,
//					setAntiFlickerMode or enableDisableDenoising), enabling
//					dependent controls.
//
//	ARGUMENTS	:	identification - Radio group name from JSON (e.g. wbMode,
//					  exposureModeGroup, autoExpRoiModeGroup, denoiseMode)
//					id - JSON id of the clicked radio button
//					checked - New checked state
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Radio buttons
// ----------------------------------------------------------------
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []

    var identificationToGroupId = {
        "wbMode": "whiteBalance",
        "autoWhiteBalanceModes": "autoWhiteBalance",
        "manualWhiteBalanceModes": "manualWhiteBalance",
        "exposureModeGroup": "exposure",
        "autoExposureFeatureGroup": "exposure",
        "autoExpRoiModeGroup": "autoExposureROI",
        "cameraModeGroup": "cameraMode",
        "strobeModeGroup": "strobeMode",
        "antiFlickerModeGroup": "antiFlicker",
        "denoiseMode": "denoise"
    }

    var groupId = identificationToGroupId[identification]
    if (!groupId) return changedFields

    var section = findSection(groupId)
    if (!section || !section.children) return changedFields

    for (var j = 0; j < section.children.length; j++) {
        var radio = section.children[j]
        if (radio.identification !== identification) continue

        if (radio.id === id) {
            radio.checked = checked
            changedFields.push({ id: radio.id, checked: checked })
        } else {
            radio.checked = false
            changedFields.push({ id: radio.id, checked: false })
        }
    }

    if (!checked) return changedFields

    if (identification === "wbMode") {
        currentWbMode = (id === "autoWB") ? See3CAMCU200.AUTO_WB : See3CAMCU200.MANUAL_WB
        see3camcu200Controller.setWhiteBalanceMode(currentWbMode, currentWbAutoFeature, currentWbManualFeature, currentWbPreset)
    } else if (identification === "autoWhiteBalanceModes") {
        currentWbAutoFeature = (id === "continuous") ? See3CAMCU200.WB_CONTINIOUS : See3CAMCU200.WB_SINGLE_SHOT
        see3camcu200Controller.setWhiteBalanceMode(currentWbMode, currentWbAutoFeature, currentWbManualFeature, currentWbPreset)
    } else if (identification === "manualWhiteBalanceModes") {
        if (id === "colorTemperature") currentWbManualFeature = See3CAMCU200.WB_COLOR_TEMPERATURE
        else if (id === "presetManualWb") currentWbManualFeature = See3CAMCU200.WB_PRESET_MODE
        else if (id === "proMode") currentWbManualFeature = See3CAMCU200.WB_PRO_MODE
        see3camcu200Controller.setWhiteBalanceMode(currentWbMode, currentWbAutoFeature, currentWbManualFeature, currentWbPreset)

        var manualSection = findSection("manualWhiteBalance")
        var ctSlider = findChild(manualSection, "colorTemperatureSlider")
        var presetDrop = findChild(manualSection, "manualPreset")
        if (ctSlider) { ctSlider.enabled = (id === "colorTemperature"); changedFields.push({ id: "colorTemperatureSlider", enabled: ctSlider.enabled }) }
        if (presetDrop) { presetDrop.enabled = (id === "presetManualWb"); changedFields.push({ id: "manualPreset", enabled: presetDrop.enabled }) }
    } else if (identification === "exposureModeGroup") {
        currentExposureMode = (id === "autoExposure") ? See3CAMCU200.AUTO_EXPOSURE : See3CAMCU200.MANUAL_EXPOSURE
        see3camcu200Controller.setExposure(currentExposureMode, currentExposureAutoFeature, currentManualExposureValue)

        var isAuto = (id === "autoExposure")
        var continuousChild = findChild(section, "continuousExposure")
        var singleShotChild = findChild(section, "singleShotExposure")
        var manualSlider = findChild(section, "manualExposureSlider")
        if (continuousChild) { continuousChild.enabled = isAuto; changedFields.push({ id: "continuousExposure", enabled: isAuto }) }
        if (singleShotChild) { singleShotChild.enabled = isAuto; changedFields.push({ id: "singleShotExposure", enabled: isAuto }) }
        if (manualSlider) { manualSlider.enabled = !isAuto; changedFields.push({ id: "manualExposureSlider", enabled: !isAuto }) }
    } else if (identification === "autoExposureFeatureGroup") {
        currentExposureAutoFeature = (id === "continuousExposure") ? See3CAMCU200.CONTINIOUS_EXPOSURE : See3CAMCU200.SINGLE_SHOT_EXPOSURE
        see3camcu200Controller.setExposure(currentExposureMode, currentExposureAutoFeature, currentManualExposureValue)
    } else if (identification === "autoExpRoiModeGroup") {
        currentRoiMode = (id === "manualROI") ? See3CAMCU200.MANUAL_ROI : See3CAMCU200.FULL_ROI
        var isManual = (id === "manualROI")
        var winSizeChild = findChild(section, "roiWindowSize")
        if (winSizeChild) { winSizeChild.enabled = isManual; changedFields.push({ id: "roiWindowSize", enabled: isManual }) }
        see3camcu200Controller.setROIAutoExposure(currentRoiMode, 0, 0, 0, 0, currentRoiWindowSize.toString())
    } else if (identification === "cameraModeGroup") {
        var camMode = (id === "triggerCamMode") ? See3CAMCU200.TRIGGER_MODE : See3CAMCU200.MASTER_MODE
        see3camcu200Controller.setCameraMode(camMode)
    } else if (identification === "strobeModeGroup") {
        var strobeMode = (id === "strobeOn") ? See3CAMCU200.STROBE_ON : See3CAMCU200.STROBE_OFF
        see3camcu200Controller.setStrobeMode(strobeMode)
    } else if (identification === "antiFlickerModeGroup") {
        var flickerMode = See3CAMCU200.MODE_DISABLE
        if (id === "flicker50Hz") flickerMode = See3CAMCU200.MODE_50Hz
        else if (id === "flicker60Hz") flickerMode = See3CAMCU200.MODE_60Hz
        see3camcu200Controller.setAntiFlickerMode(flickerMode)
    } else if (identification === "denoiseMode") {
        see3camcu200Controller.enableDisableDenoising(id === "enableDenoise")
    }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a drop box selection in the model and apply it:
//					"manualPreset" switches manual WB to preset mode with the
//					chosen preset, "roiWindowSize" caches the size and calls
//					setROIAutoExposure().
//
//	ARGUMENTS	:	id - JSON id of the drop box
//					value - Selected value (preset label or window size string)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Drop boxes
// ----------------------------------------------------------------
function handleDropBoxValueChanged(id, value) {
    for (var i = 0; i < see3camcu200HidProperty.length; i++) {
        var section = see3camcu200HidProperty[i]
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

    if (id === "manualPreset") {
        var index = wbPresetLabels.indexOf(value)
        if (index >= 0) {
            currentWbPreset = index
            currentWbManualFeature = See3CAMCU200.WB_PRESET_MODE
            see3camcu200Controller.setWhiteBalanceMode(currentWbMode, currentWbAutoFeature, currentWbManualFeature, currentWbPreset)
        }
    } else if (id === "roiWindowSize") {
        currentRoiWindowSize = parseInt(value)
        see3camcu200Controller.setROIAutoExposure(currentRoiMode, 0, 0, 0, 0, value)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box state in the model; for "horizontal" /
//					"vertical" it updates the cached flip flag and calls
//					setOrientation() with both flags.
//
//	ARGUMENTS	:	id - JSON id of the check box
//					checked - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Checkboxes
// ----------------------------------------------------------------
function updateCheckBoxValue(id, checked) {
    for (var i = 0; i < see3camcu200HidProperty.length; i++) {
        var section = see3camcu200HidProperty[i]
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
        see3camcu200Controller.setOrientation(isHorizontalFlip, isVerticalFlip)
    } else if (id === "vertical") {
        isVerticalFlip = checked
        see3camcu200Controller.setOrientation(isHorizontalFlip, isVerticalFlip)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, text)
//
//  PURPOSE		:	To keep see3camcu200HidProperty in sync when the user edits a
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
// Text boxes
// ----------------------------------------------------------------
function updateTextBoxField(id, text) {
    for (var i = 0; i < see3camcu200HidProperty.length; i++) {
        var section = see3camcu200HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].text = text
                    break
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle HID button clicks: WB one-shot trigger, save user
//					configuration, reset device, read ISP firmware version, read
//					statistics, restore defaults (setToDefault or save default
//					configuration, then re-read controls), single-shot exposure
//					trigger, and set exposure compensation from the text box.
//
//	ARGUMENTS	:	id - JSON id of the clicked button
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------
function handleButtonClick(id) {
    if (id === "trigger") {
        currentWbAutoFeature = See3CAMCU200.WB_SINGLE_SHOT
        see3camcu200Controller.setWhiteBalanceMode(currentWbMode, currentWbAutoFeature, currentWbManualFeature, currentWbPreset)
    } else if (id === "saveConfiguration") {
        see3camcu200Controller.saveConfiguration(See3CAMCU200.SAVE_USER_DEFINED)
    } else if (id === "resetDeviceBtn") {
        see3camcu200Controller.resetDevice()
    } else if (id === "readIspFwVersionBtn") {
        see3camcu200Controller.readISPFirmwareVersion()
    } else if (id === "readStatisticsBtn") {
        see3camcu200Controller.readStatistics()
    } else if (id === "updateDefault") {
        see3camcu200Controller.setToDefault()
        getCameraControls()
    } else if (id === "defaultConfig") {
        see3camcu200Controller.saveConfiguration(See3CAMCU200.SAVE_DEFAULT)
        getCameraControls()
    }else if (id === "triggerSingleShot") {
        currentExposureAutoFeature = See3CAMCU200.SINGLE_SHOT_EXPOSURE
        see3camcu200Controller.setExposure(currentExposureMode, currentExposureAutoFeature, currentManualExposureValue)
    } else if (id === "setExpComp") {
        var section = findSection("exposureCompensation")
        var child = findChild(section, "expCompValue")
        var value = child ? parseInt(child.text, 10) : NaN
        if (!isNaN(value)) {
            see3camcu200Controller.setExposureCompensation(value)
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRightClick(x, y, width, height)
//
//  PURPOSE		:	To set the manual AE ROI at the point right-clicked on the
//					preview via setROIAutoExposure() with the cached window size.
//					Ignored unless the ROI mode is manual.
//
//	ARGUMENTS	:	x - X coordinate of the click on the preview
//					y - Y coordinate of the click on the preview
//					width - Width of the preview area
//					height - Height of the preview area
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Auto Exposure ROI - right click on preview
// ----------------------------------------------------------------
function handleRightClick(x, y, width, height) {
    if (currentRoiMode === See3CAMCU200.MANUAL_ROI) {
        see3camcu200Controller.setROIAutoExposure(See3CAMCU200.MANUAL_ROI, width, height, x, y, currentRoiWindowSize.toString())
    }
}
