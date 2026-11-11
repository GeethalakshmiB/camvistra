var model = []
var horizontal = false
var vertical = false

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(data)
//
//  PURPOSE		:	To store the HID settings JSON model (array of sections with
//					children controls) used by all lookups in this
//					See3CAM_37CUG module.
//
//	ARGUMENTS	:	data - Array of control sections loaded by UsbcamHidSettings.qml
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(data) {
    model = data
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the See3CAM_37CUG HID settings JSON model held by
//					this module, including values updated from the camera.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current HID settings model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return model
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached horizontal and vertical flip states to
//					false when the device is closed or switched.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    horizontal = false
    vertical = false
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To schedule reading of all See3CAM_37CUG HID controls by
//					starting the QML delayedControlsTimer, which later calls
//					getDelayedCameraControls().
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
//  PURPOSE		:	To query the camera via see3cam37cugController for camera
//					mode, orientation, gain, strobe, burst length, exposure, target
//					brightness, anti-flicker, fast AE, self trigger, exposure
//					compensation, FAE target brightness/frames and ISP firmware
//					version. Results arrive through controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    see3cam37cugController.getCameraMode()
    see3cam37cugController.getOrientation()
    see3cam37cugController.getGainMode()
    see3cam37cugController.getStrobeMode()
    see3cam37cugController.getBurstLength()
    see3cam37cugController.getExposureMode()
    see3cam37cugController.getTargetBrightness()
    see3cam37cugController.getAntiFlickerMode()
    see3cam37cugController.getFastAutoExposure()
    see3cam37cugController.getSelfTrigger()
    see3cam37cugController.getExposureCompensation()
    see3cam37cugController.getFAETargetBrightness()
    see3cam37cugController.getFAEExecutionFrames()
    see3cam37cugController.readISPFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	child(id)
//
//  PURPOSE		:	To find a control in the HID model by id by searching the
//					children of every section.
//
//	ARGUMENTS	:	id - Control id to look up
//
//	RETURN		:	Object - the matching child control, or null if not found
///////////////////////////////////////////////////////////////////////////
function child(id) {
    for (var index = 0; index < model.length; ++index) {
        var children = model[index].children
        if (!children) {
            continue
        }
        for (var childIndex = 0; childIndex < children.length; ++childIndex) {
            if (children[childIndex].id === id) {
                return children[childIndex]
            }
        }
    }
    return null
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateField(id, property, value)
//
//  PURPOSE		:	To set one property of a model control and build the matching
//					change object for the QML view.
//
//	ARGUMENTS	:	id - Control id
//					property - Property name to set (e.g. 'checked', 'text')
//					value - New property value
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function updateField(id, property, value) {
    var item = child(id)
    if (!item) {
        return []
    }
    item[property] = value
    var change = {id: id}
    change[property] = value
    return [change]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRadioButtons(values, current)
//
//  PURPOSE		:	To check the radio button whose mapped value equals current
//					and uncheck the others in the given id-to-value map.
//
//	ARGUMENTS	:	values - Object mapping radio button id to its mode value
//					current - Current mode value reported by the camera
//
//	RETURN		:	Array - {id, checked} change objects for each radio found
///////////////////////////////////////////////////////////////////////////
function updateRadioButtons(values, current) {
    var changes = []
    for (var id in values) {
        var item = child(id)
        if (item) {
            item.checked = values[id] === current
            changes.push({id: id, checked: item.checked})
        }
    }
    return changes
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSlider(id, minimum, maximum, step, current)
//
//  PURPOSE		:	To update a slider's range, step and current value in the
//					model.
//
//	ARGUMENTS	:	id - Slider control id
//					minimum - Minimum slider value
//					maximum - Maximum slider value
//					step - Slider step size
//					current - Current slider value
//
//	RETURN		:	Array - {id, min, max, step, currentValue} change, or empty
///////////////////////////////////////////////////////////////////////////
function updateSlider(id, minimum, maximum, step, current) {
    var item = child(id)
    if (!item) {
        return []
    }
    item.min = minimum
    item.max = maximum
    item.step = step
    item.currentValue = current
    return [{
        id: id,
        min: minimum,
        max: maximum,
        step: step,
        currentValue: current
    }]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setText(id, value)
//
//  PURPOSE		:	To set a text control's text (value converted to string) using
//					updateField().
//
//	ARGUMENTS	:	id - Text control id
//					value - Value to display
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function setText(id, value) {
    return updateField(id, "text", value.toString())
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	numberValue(id)
//
//  PURPOSE		:	To read a control's text (or currentValue) from the model and
//					parse it as an integer for sending to the camera.
//
//	ARGUMENTS	:	id - Control id
//
//	RETURN		:	Number - parsed integer value, 0 if the control is missing
///////////////////////////////////////////////////////////////////////////
function numberValue(id) {
    var item = child(id)
    if (!item) {
        return 0
    }
    return parseInt(item.text || item.currentValue || 0)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	selectedValue(id)
//
//  PURPOSE		:	To read a combo box's selected (or currentValue) entry from
//					the model and parse it as an integer.
//
//	ARGUMENTS	:	id - Combo box control id
//
//	RETURN		:	Number - parsed integer value, 0 if the control is missing
///////////////////////////////////////////////////////////////////////////
function selectedValue(id) {
    var item = child(id)
    if (!item) {
        return 0
    }
    return parseInt(item.selected || item.currentValue || 0)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	checked(id)
//
//  PURPOSE		:	To read the checked state of a control from the model.
//
//	ARGUMENTS	:	id - Control id
//
//	RETURN		:	Boolean - checked state (falsy if the control is missing)
///////////////////////////////////////////////////////////////////////////
function checked(id) {
    var item = child(id)
    return item && item.checked
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCameraMode(mode)
//
//  PURPOSE		:	To reflect the camera mode in the master / triggerExposure
//					radio buttons.
//
//	ARGUMENTS	:	mode - See3CAM37CUG.MASTER or TRIGGER_EXPOSURE
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateCameraMode(mode) {
    return updateRadioButtons({
        master: See3CAM37CUG.MASTER,
        triggerExposure: See3CAM37CUG.TRIGGER_EXPOSURE
    }, mode)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateOrientation(orientation)
//
//  PURPOSE		:	To decode the orientation value into horizontal (3, 4) and
//					vertical (2, 4) flip states, cache them and update the
//					flipCtrlHorizotal / flipCtrlVertical checkboxes.
//
//	ARGUMENTS	:	orientation - Orientation value from the camera (2 = vertical,
//					  3 = horizontal, 4 = both, other = none)
//
//	RETURN		:	Array - {id, checked} change objects for the flip checkboxes
///////////////////////////////////////////////////////////////////////////
function updateOrientation(orientation) {
    horizontal = orientation === 3 || orientation === 4
    vertical = orientation === 2 || orientation === 4
    return updateField("flipCtrlHorizotal", "checked", horizontal)
        .concat(updateField("flipCtrlVertical", "checked", vertical))
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGain(mode, feature, minimum, maximum, current, step)
//
//  PURPOSE		:	To reflect the camera gain settings: auto/manual gain radios,
//					continuous/single-shot auto gain feature radios and the
//					gainSlider range and value.
//
//	ARGUMENTS	:	mode - Gain mode (AUTO_GAIN or MANUAL_GAIN)
//					feature - Auto gain feature (CONTINUOUS_GAIN or SINGLE_GAIN)
//					minimum - Minimum gain
//					maximum - Maximum gain
//					current - Current gain
//					step - Gain step size
//
//	RETURN		:	Array - change objects for the radios and gain slider
///////////////////////////////////////////////////////////////////////////
function updateGain(mode, feature, minimum, maximum, current, step) {
    var changes = updateRadioButtons({
        autoGain: See3CAM37CUG.AUTO_GAIN,
        manualGain: See3CAM37CUG.MANUAL_GAIN
    }, mode)
    changes = changes.concat(updateRadioButtons({
        gainContinious: See3CAM37CUG.CONTINUOUS_GAIN,
        gainSingleShot: See3CAM37CUG.SINGLE_GAIN
    }, feature))
    return changes.concat(
        updateSlider("gainSlider", minimum, maximum, step, current))
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStrobe(mode)
//
//  PURPOSE		:	To reflect the strobe mode in the strobeOff / strobeOn radio
//					buttons (0 = off, 1 = on).
//
//	ARGUMENTS	:	mode - Strobe mode value from the camera
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateStrobe(mode) {
    return updateRadioButtons({strobeOff: 0, strobeOn: 1}, mode)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBurst(length)
//
//  PURPOSE		:	To show the camera's burst length as the selected entry of
//					burstLengthCombo.
//
//	ARGUMENTS	:	length - Burst length value from the camera
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function updateBurst(length) {
    return updateField(
        "burstLengthCombo", "selected", length.toString())
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposure(mode, feature, seconds, milliSeconds, microSeconds)
//
//  PURPOSE		:	To reflect the camera exposure settings: auto/manual exposure
//					radios, continuous/single-shot feature radios and the
//					seconds/milliseconds/microseconds exposure text fields.
//
//	ARGUMENTS	:	mode - Exposure mode (AUTO_EXPOSURE or MANUAL_EXPOSURE)
//					feature - Auto exposure feature (CONTINUOUS_EXPOSURE or
//					  SINGLE_EXPOSURE_TRIGGER)
//					seconds - Exposure time seconds part
//					milliSeconds - Exposure time milliseconds part
//					microSeconds - Exposure time microseconds part
//
//	RETURN		:	Array - change objects for the radios and text fields
///////////////////////////////////////////////////////////////////////////
function updateExposure(mode, feature, seconds, milliSeconds, microSeconds) {
    var changes = updateRadioButtons({
        autoExposure: See3CAM37CUG.AUTO_EXPOSURE,
        manualExposure: See3CAM37CUG.MANUAL_EXPOSURE
    }, mode)
    changes = changes.concat(updateRadioButtons({
        exposureContinious: See3CAM37CUG.CONTINUOUS_EXPOSURE,
        exposureSingleShot: See3CAM37CUG.SINGLE_EXPOSURE_TRIGGER
    }, feature))
    return changes.concat(setText("expInSecondsTextField", seconds))
        .concat(setText("expInMilliSecTextField", milliSeconds))
        .concat(setText("expInMicroSecTextField", microSeconds))
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTargetBrightness(minimum, maximum, step, current)
//
//  PURPOSE		:	To update the targetBrightness slider's range, step and value.
//
//	ARGUMENTS	:	minimum - Minimum target brightness
//					maximum - Maximum target brightness
//					step - Step size
//					current - Current target brightness
//
//	RETURN		:	Array - slider change object, or empty
///////////////////////////////////////////////////////////////////////////
function updateTargetBrightness(minimum, maximum, step, current) {
    return updateSlider(
        "targetBrightness", minimum, maximum, step, current)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAntiFlicker(mode)
//
//  PURPOSE		:	To reflect the anti-flicker mode in the flicker50hz /
//					flicker60Hz / flickerDisable radio buttons.
//
//	ARGUMENTS	:	mode - FLICKER_50_HZ, FLICKER_60_HZ or FLICKER_DISABLE
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateAntiFlicker(mode) {
    return updateRadioButtons({
        flicker50hz: See3CAM37CUG.FLICKER_50_HZ,
        flicker60Hz: See3CAM37CUG.FLICKER_60_HZ,
        flickerDisable: See3CAM37CUG.FLICKER_DISABLE
    }, mode)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStatistics(seconds, milliSeconds, microSeconds, gain)
//
//  PURPOSE		:	To display the exposure time and gain statistics read from the
//					camera in their text fields.
//
//	ARGUMENTS	:	seconds - Exposure seconds part
//					milliSeconds - Exposure milliseconds part
//					microSeconds - Exposure microseconds part
//					gain - Current gain value
//
//	RETURN		:	Array - {id, text} change objects
///////////////////////////////////////////////////////////////////////////
function updateStatistics(seconds, milliSeconds, microSeconds, gain) {
    return setText("secondsStatistics", seconds)
        .concat(setText("milliSecondsStatistics", milliSeconds))
        .concat(setText("microSecondsStatistics", microSeconds))
        .concat(setText("gainStatistics", gain))
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTemperature(temperature)
//
//  PURPOSE		:	To display the sensor temperature read from the camera in
//					temperatureValue.
//
//	ARGUMENTS	:	temperature - Temperature value from the camera
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function updateTemperature(temperature) {
    return setText("temperatureValue", temperature)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFastAutoExposure(mode)
//
//  PURPOSE		:	To reflect the fast auto exposure state in the
//					disableFastAutoExp / enableFastAutoExp radios (0 / 1).
//
//	ARGUMENTS	:	mode - Fast auto exposure state from the camera
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateFastAutoExposure(mode) {
    return updateRadioButtons({
        disableFastAutoExp: 0,
        enableFastAutoExp: 1
    }, mode)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExposureCompensation(seconds, milliSeconds, microSeconds)
//
//  PURPOSE		:	To display the exposure compensation (seconds, milliseconds,
//					microseconds) read from the camera in its text fields.
//
//	ARGUMENTS	:	seconds - Compensation seconds part
//					milliSeconds - Compensation milliseconds part
//					microSeconds - Compensation microseconds part
//
//	RETURN		:	Array - {id, text} change objects
///////////////////////////////////////////////////////////////////////////
function updateExposureCompensation(seconds, milliSeconds, microSeconds) {
    return setText("exposureCompensationSeconds", seconds)
        .concat(setText("exposureCompensationMilliSeconds", milliSeconds))
        .concat(setText("exposureCompensationMicroSeconds", microSeconds))
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFAETargetBrightness(minimum, maximum, step, current)
//
//  PURPOSE		:	To update the faeTargetBrightnessSlider's range, step and
//					value from the fast auto exposure target brightness.
//
//	ARGUMENTS	:	minimum - Minimum value
//					maximum - Maximum value
//					step - Step size
//					current - Current value
//
//	RETURN		:	Array - slider change object, or empty
///////////////////////////////////////////////////////////////////////////
function updateFAETargetBrightness(minimum, maximum, step, current) {
    return updateSlider(
        "faeTargetBrightnessSlider", minimum, maximum, step, current)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFAEExecutionFrames(frames)
//
//  PURPOSE		:	To show the fast auto exposure execution frame count as the
//					selected entry of faeExecutionFrameCombo.
//
//	ARGUMENTS	:	frames - Execution frame count from the camera
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function updateFAEExecutionFrames(frames) {
    return updateField(
        "faeExecutionFrameCombo", "selected", frames.toString())
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateISPFirmwareVersion(version)
//
//  PURPOSE		:	To display the ISP firmware version in
//					ispFirmwareVersionValue.
//
//	ARGUMENTS	:	version - ISP firmware version string from the camera
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function updateISPFirmwareVersion(version) {
    return setText("ispFirmwareVersionValue", version)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, value)
//
//  PURPOSE		:	To update the cached horizontal/vertical flip state for the
//					toggled flip checkbox and apply both via
//					see3cam37cugController.setOrientation().
//
//	ARGUMENTS	:	id - Checkbox id (flipCtrlHorizotal or flipCtrlVertical)
//					value - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, value) {
    if (id === "flipCtrlHorizotal") {
        horizontal = value
    } else if (id === "flipCtrlVertical") {
        vertical = value
    }
    see3cam37cugController.setOrientation(horizontal, vertical)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, value)
//
//  PURPOSE		:	To send a slider change to the camera: gainSlider sets manual
//					continuous gain, targetBrightness and faeTargetBrightnessSlider
//					set the (FAE) target brightness via see3cam37cugController.
//
//	ARGUMENTS	:	id - Id of the slider that changed
//					value - New slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id, value) {
    if (id === "gainSlider") {
        see3cam37cugController.setGainMode(
            See3CAM37CUG.MANUAL_GAIN,
            See3CAM37CUG.CONTINUOUS_GAIN,
            value)
    } else if (id === "targetBrightness") {
        see3cam37cugController.setTargetBrightness(value)
    } else if (id === "faeTargetBrightnessSlider") {
        see3cam37cugController.setFAETargetBrightness(value)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, text)
//
//  PURPOSE		:	To store text typed by the user into the matching text field
//					control in the model (no camera call).
//
//	ARGUMENTS	:	id - Text field control id
//					text - Text entered by the user
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(id, text) {
    var item = child(id)
    if (item) {
        item.text = text
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To send a combo box change to the camera: burstLengthCombo
//					calls setBurstLength and faeExecutionFrameCombo calls
//					setFAEExecutionFrames.
//
//	ARGUMENTS	:	id - Combo box id
//					value - Selected value (parsed to int)
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value) {
    if (id === "burstLengthCombo") {
        see3cam37cugController.setBurstLength(parseInt(value))
    } else if (id === "faeExecutionFrameCombo") {
        see3cam37cugController.setFAEExecutionFrames(parseInt(value))
    }
    return []
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(groupId, id, isChecked)
//
//  PURPOSE		:	To apply a newly selected radio button: maps the group/id to a
//					value and calls the matching see3cam37cugController setter
//					(camera mode, gain mode, exposure mode, anti-flicker, strobe or
//					fast AE). Gain/exposure setters are built from the current
//					radio, slider and text field states. Then syncs the group.
//
//	ARGUMENTS	:	groupId - Radio group id (e.g. gainModeGroup, antiFlickerGroup)
//					id - Id of the radio button that changed
//					isChecked - true if the radio was checked; unchecks are ignored
//
//	RETURN		:	Array - {id, checked} change objects (empty if ignored)
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(groupId, id, isChecked) {
    if (!isChecked) {
        return []
    }

    var groups = {
        cameraModeGroup: {master: 1, triggerExposure: 2},
        gainModeGroup: {autoGain: 0, manualGain: 1},
        autoGainFeatureGroup: {gainContinious: 0, gainSingleShot: 1},
        autoExpStatusGroup: {autoExposure: 0, manualExposure: 1},
        autoExposureFeatureGroup: {
            exposureContinious: 0,
            exposureSingleShot: 1
        },
        antiFlickerGroup: {
            flicker50hz: 0,
            flicker60Hz: 1,
            flickerDisable: 2
        },
        strobeModeGroup: {strobeOff: 0, strobeOn: 1},
        fastAutoModeGroup: {
            disableFastAutoExp: 0,
            enableFastAutoExp: 1
        }
    }
    var group = groups[groupId]
    if (!group || group[id] === undefined) {
        return []
    }

    var value = group[id]
    if (groupId === "cameraModeGroup") {
        see3cam37cugController.setCameraMode(value)
    } else if (groupId === "gainModeGroup"
               || groupId === "autoGainFeatureGroup") {
        see3cam37cugController.setGainMode(
            checked("manualGain") ? 1 : 0,
            checked("gainSingleShot") ? 1 : 0,
            numberValue("gainSlider"))
    } else if (groupId === "autoExpStatusGroup"
               || groupId === "autoExposureFeatureGroup") {
        see3cam37cugController.setExposureMode(
            checked("manualExposure") ? 1 : 0,
            checked("exposureSingleShot") ? 1 : 0,
            numberValue("expInSecondsTextField"),
            numberValue("expInMilliSecTextField"),
            numberValue("expInMicroSecTextField"))
    } else if (groupId === "antiFlickerGroup") {
        see3cam37cugController.setAntiFlickerMode(value)
    } else if (groupId === "strobeModeGroup") {
        see3cam37cugController.setStrobeMode(value)
    } else if (groupId === "fastAutoModeGroup") {
        see3cam37cugController.setFastAutoExposure(value)
    }
    return updateRadioButtons(group, value)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle button presses: gain/exposure single-shot triggers,
//					manual exposure and exposure compensation set, statistics and
//					temperature read, ISP firmware version read, and restore
//					defaults (setToDefaultValues() followed by re-reading controls).
//
//	ARGUMENTS	:	id - Button id (e.g. triggerGainBtn, manualExpSetBtn,
//					  readTempBtn, defaultValue)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {
    if (id === "triggerGainBtn") {
        see3cam37cugController.setGainMode(
            See3CAM37CUG.AUTO_GAIN,
            See3CAM37CUG.TRIGGER_GAIN,
            numberValue("gainSlider"))
    } else if (id === "triggerExpBtn") {
        see3cam37cugController.setExposureMode(
            See3CAM37CUG.AUTO_EXPOSURE,
            See3CAM37CUG.SINGLE_EXPOSURE_TRIGGER,
            numberValue("expInSecondsTextField"),
            numberValue("expInMilliSecTextField"),
            numberValue("expInMicroSecTextField"))
    } else if (id === "manualExpSetBtn") {
        see3cam37cugController.setExposureMode(
            See3CAM37CUG.MANUAL_EXPOSURE,
            See3CAM37CUG.CONTINUOUS_EXPOSURE,
            numberValue("expInSecondsTextField"),
            numberValue("expInMilliSecTextField"),
            numberValue("expInMicroSecTextField"))
    } else if (id === "exposureCompensationSetBtn") {
        see3cam37cugController.setExposureCompensation(
            numberValue("exposureCompensationSeconds"),
            numberValue("exposureCompensationMilliSeconds"),
            numberValue("exposureCompensationMicroSeconds"))
    } else if (id === "getStatisticsBtn") {
        see3cam37cugController.readStatistics()
    } else if (id === "readTempBtn") {
        see3cam37cugController.readTemperature()
    } else if (id === "defaultValue") {
        see3cam37cugController.setToDefaultValues()
        getCameraControls()
    } else if (id === "ispFirmwareVersion") {
        see3cam37cugController.readISPFirmwareVersion()
    }
}
