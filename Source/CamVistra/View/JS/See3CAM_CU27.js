var see3camcu27HidProperty = []

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To cache the JSON property model (HID accordion sections and
//					their child controls) loaded by UsbcamHidSettings.qml in
//					see3camcu27HidProperty, so the other functions can read and
//					update it.
//
//	ARGUMENTS	:	jsonArray - Array of section objects parsed from the camera's
//					  JSON file
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camcu27HidProperty = jsonArray
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the cached JSON property model
//					(see3camcu27HidProperty) so UsbcamHidSettings.qml can bind it
//					to the HID accordion.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current property model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return see3camcu27HidProperty
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To start the QML delayedControlsTimer, whose handler calls
//					getDelayedCameraControls() so the See3CAM_CU27 HID values are
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
//  PURPOSE		:	To request all HID control values from the See3CAM_CU27 (AWB
//					preset/lock, AE metering/lock, flicker mode, Q-factor, burst
//					length, denoise, roll, ISP firmware, serial number and
//					firmware version). Results arrive via controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
function getDelayedCameraControls() {
    see3camcu27Controller.getAWBPresetMode()
    see3camcu27Controller.getAWBLockStatus()
    see3camcu27Controller.getAEMeteringMode()
    see3camcu27Controller.getAELockStatus()
    see3camcu27Controller.getFlickerMode()
    see3camcu27Controller.getQFactor()
    see3camcu27Controller.getBurstLength()
    see3camcu27Controller.getDenoiseMode()
    see3camcu27Controller.getRollValue()
    see3camcu27Controller.readISPFirmwareVersion()
    see3camcu27Controller.get64BitSerialNumber()
    see3camcu27Controller.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To satisfy the common module interface used by
//					UsbcamHidSettings.qml; this camera keeps no extra cached
//					state, so it does nothing.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAWBLockStatus(lockStatus)
//
//  PURPOSE		:	To set the "awbLock" check box in the "awbPresets" section
//					from the AWB lock status read from the camera (checked =
//					locked).
//
//	ARGUMENTS	:	lockStatus - AWB lock status (See3CAMCU27.AWB_LOCK_ON or
//					  AWB_LOCK_OFF)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// AWB Lock Status  (checkbox: awbLock — checked = locked)
// ----------------------------------------------------------------
function updateAWBLockStatus(lockStatus) {
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
        if (group.id === "awbPresets" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "awbLock") {
                    child.checked = (lockStatus === See3CAMCU27.AWB_LOCK_ON)
                    changedFields.push({ id: child.id, checked: child.checked })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAWBPresetMode(awbMode)
//
//  PURPOSE		:	To map the AWB preset read from the camera to its display
//					label (Cloudy, DayLight, ... Auto) and select it in the
//					"awbPresetsCombo" drop box. Unknown values are ignored.
//
//	ARGUMENTS	:	awbMode - AWB preset mode (See3CAMCU27.AWB_PRESET_*)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// AWB Preset Mode  (dropBox: awbPresetsCombo)
// ----------------------------------------------------------------
function updateAWBPresetMode(awbMode) {
    var changedFields = []

    var awbPresetLabelMap = {}
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_CLOUDY]           = "Cloudy"
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_DAYLIGHT]         = "DayLight"
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_FLASH]            = "Flash"
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_COOLWHITE_FLUOR]  = "Cool White Fluorescent"
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_TUNGSTEN]         = "Tungsten"
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_CANDLELIGHT]      = "CandleLight"
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_HORIZON]          = "Horizon"
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_CUSTOM]           = "Custom"
    awbPresetLabelMap[See3CAMCU27.AWB_PRESET_AUTO]             = "Auto"

    var label = awbPresetLabelMap[awbMode]
    if (label === undefined) return changedFields

    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
        if (group.id === "awbPresets" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "awbPresetsCombo") {
                    child.currentValue = label
                    child.selected     = label
                    changedFields.push({
                        id:           child.id,
                        currentValue: label,
                        selected:     label
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
//  FUNCTION	:	updateAELockStatus(lockStatus)
//
//  PURPOSE		:	To set the "aeLock" check box in the "aeMetering mode" section
//					from the AE lock status read from the camera (checked =
//					locked).
//
//	ARGUMENTS	:	lockStatus - AE lock status (See3CAMCU27.AE_LOCK_ON or
//					  AE_LOCK_OFF)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// AE Lock Status  (checkbox: aeLock — checked = locked)
// ----------------------------------------------------------------
function updateAELockStatus(lockStatus) {
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
        if (group.id === "aeMetering mode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "aeLock") {
                    child.checked = (lockStatus === See3CAMCU27.AE_LOCK_ON)
                    changedFields.push({ id: child.id, checked: child.checked })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAEMeteringMode(meterMode)
//
//  PURPOSE		:	To map the AE metering mode read from the camera to its label
//					(Manual, Center-Weighted average, All block integral, Spot1,
//					Spot2) and select it in the "aeMeteringMode" drop box. Unknown
//					values are ignored.
//
//	ARGUMENTS	:	meterMode - AE metering mode (See3CAMCU27.AE_*)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// AE Metering Mode  (dropBox: aeMeteringMode)
// ----------------------------------------------------------------
function updateAEMeteringMode(meterMode) {
    var changedFields = []

    var aeMeterLabelMap = {}
    aeMeterLabelMap[See3CAMCU27.AE_OFF]                 = "Manual"
    aeMeterLabelMap[See3CAMCU27.AE_CENTER_WEIGHTED_AVG] = "Center-Weighted average"
    aeMeterLabelMap[See3CAMCU27.AE_ALL_BLOCK_INTEGRAL]  = "All block integral"
    aeMeterLabelMap[See3CAMCU27.AE_SMALL_AREA]          = "Spot1(small area)"
    aeMeterLabelMap[See3CAMCU27.AE_LARGE_AREA]          = "Spot2(large area)"

    var label = aeMeterLabelMap[meterMode]
    if (label === undefined) return changedFields

    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
        if (group.id === "aeMetering mode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "aeMeteringMode") {
                    child.currentValue = label
                    child.selected     = label
                    changedFields.push({
                        id:           child.id,
                        currentValue: label,
                        selected:     label
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
// Q-Factor  (slider: qFactorVal)
// ----------------------------------------------------------------
function updateQFactor(qFactor) {
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
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
//					select it in the "burstLen" drop box.
//
//	ARGUMENTS	:	burstLength - Burst length (number of images per still
//					  capture)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Burst Length  (dropBox: burstLen)
// ----------------------------------------------------------------
function updateBurstLength(burstLength) {
    prevController.setBurstLength(burstLength)
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
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
//  FUNCTION	:	updateAntiFlickerMode(flickerMode)
//
//  PURPOSE		:	To reflect the flicker mode read from the camera: check the
//					off/auto/manual radio button and, for 50/60 Hz, enable the
//					"frequency" drop box and select "50 Hz" or "60 Hz".
//
//	ARGUMENTS	:	flickerMode - Flicker mode (See3CAMCU27.FLICKER_OFF,
//					  FLICKER_AUTO, FLICKER_50HZ or FLICKER_60HZ)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Anti-Flicker Mode  (radioButtons: offMode, autoMode, manualMode + dropBox: frequency)
// ----------------------------------------------------------------
function updateAntiFlickerMode(flickerMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "offMode") {
                    child.checked = (flickerMode === See3CAMCU27.FLICKER_OFF)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoMode") {
                    child.checked = (flickerMode === See3CAMCU27.FLICKER_AUTO)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualMode") {
                    child.checked = (flickerMode === See3CAMCU27.FLICKER_50HZ ||
                                     flickerMode === See3CAMCU27.FLICKER_60HZ)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "frequency") {
                    child.enabled      = (flickerMode === See3CAMCU27.FLICKER_50HZ ||
                                          flickerMode === See3CAMCU27.FLICKER_60HZ)
                    child.currentValue = (flickerMode === See3CAMCU27.FLICKER_60HZ) ? "60 Hz" : "50 Hz"
                    child.selected     = (flickerMode === See3CAMCU27.FLICKER_60HZ) ? "60 Hz" : "50 Hz"
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
//  FUNCTION	:	setUvcAntiFlickerMode(value)
//
//  PURPOSE		:	To mirror a change of the UVC Power Line Frequency control
//					into the HID anti-flicker radios and frequency drop box so
//					both views stay consistent. Only the UI model is updated; no
//					HID command is sent.
//
//	ARGUMENTS	:	value - UVC value string: "DISABLE", "AUTO", "50 Hz" or "60
//					  Hz"
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Anti-Flicker Mode reverse-sync from the standard UVC Power Line
// Frequency control (main Camera Settings tab), so both UI representations
// stay consistent - mirrors See3CAM_24CUG's setUvcAntiFlickerMode.
// ----------------------------------------------------------------
function setUvcAntiFlickerMode(value) {
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
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

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDenoiseMode(denoiseMode)
//
//  PURPOSE		:	To set the "denoise" slider in the "denoiseStrength" section
//					to the denoise value read from the camera (0 = disabled).
//
//	ARGUMENTS	:	denoiseMode - Denoise value from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Denoise Mode  (slider: denoise — 0 = disabled, >0 = enabled)
// ----------------------------------------------------------------
function updateDenoiseMode(denoiseMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
        if (group.id === "denoiseStrength" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "denoise") {
                    group.children[j].currentValue = denoiseMode
                    changedFields.push({ id: group.children[j].id, currentValue: denoiseMode })
                    break
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRollValue(rollValue)
//
//  PURPOSE		:	To set the "rollValue" slider in the "roll" section to the
//					roll value read from the camera.
//
//	ARGUMENTS	:	rollValue - Roll value from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Roll Value  (slider: rollValue)
// ----------------------------------------------------------------
function updateRollValue(rollValue) {
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
        if (group.id === "roll" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                if (group.children[j].id === "rollValue") {
                    group.children[j].currentValue = rollValue
                    changedFields.push({ id: group.children[j].id, currentValue: rollValue })
                    break
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
//					see3camcu27HidProperty.
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
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
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
//					see3camcu27HidProperty.
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
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
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
//  FUNCTION	:	updateISPFirmwareVersioninUI(ispFirmwareVersion)
//
//  PURPOSE		:	To show the ISP firmware version read from the camera in the
//					"ispFirmwareVer" field of the "ispFirmwareVersion" section.
//
//	ARGUMENTS	:	ispFirmwareVersion - ISP firmware version from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// ISP Firmware Version  (label: ispFirmwareVer)
// ----------------------------------------------------------------
function updateISPFirmwareVersioninUI(ispFirmwareVersion) {
    var changedFields = []
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var group = see3camcu27HidProperty[i]
        if (group.id === "ispFirmwareVersion" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "ispFirmwareVer") {
                    child.text = ispFirmwareVersion.toString()
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
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box state in the model and apply it: awbLock
//					calls setAWBLockStatus(), aeLock calls setAELockStatus().
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
    // Keep JSON model in sync
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var section = see3camcu27HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].checked = checked
                    break
                }
            }
        }
    }

    if (id === "awbLock") {
        see3camcu27Controller.setAWBLockStatus(
            checked ? See3CAMCU27.AWB_LOCK_ON : See3CAMCU27.AWB_LOCK_OFF
        )
    } else if (id === "aeLock") {
        see3camcu27Controller.setAELockStatus(
            checked ? See3CAMCU27.AE_LOCK_ON : See3CAMCU27.AE_LOCK_OFF
        )
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle an anti-flicker radio click: update checked states,
//					enable the frequency drop box only in manual, call
//					setFlickerMode() and, on non-Windows, mirror the choice to the
//					UVC control via usbcamRect.setHidAntiFlicker().
//
//	ARGUMENTS	:	identification - Radio group name from JSON (antiFlickerMode)
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
        "antiFlickerMode": "antiFlicker"
    }

    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var section = see3camcu27HidProperty[i]

        if (section.id === groupId && section.children) {
            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]

                if (radio.id === id) {
                    radio.checked = checked
                    changedFields.push({ id: radio.id, checked: checked })

                    if (checked) {
                        if (groupId === "antiFlicker") {
                            var isManual = (id === "manualMode")
                            var frequency = ""

                            // Enable / disable frequency dropdown
                            for (var k = 0; k < section.children.length; k++) {
                                if (section.children[k].id === "frequency") {
                                    section.children[k].enabled = isManual
                                    changedFields.push({ id: "frequency", enabled: isManual })
                                    frequency = section.children[k].currentValue
                                }
                            }

                            if (id === "offMode") {
                                see3camcu27Controller.setFlickerMode(See3CAMCU27.FLICKER_OFF)
                                if (Qt.platform.os !== "windows")
                                    usbcamRect.setHidAntiFlicker("DISABLE")
                            } else if (id === "autoMode") {
                                see3camcu27Controller.setFlickerMode(See3CAMCU27.FLICKER_AUTO)
                            } else if (id === "manualMode") {
                                if (frequency === "60 Hz") {
                                    see3camcu27Controller.setFlickerMode(See3CAMCU27.FLICKER_60HZ)
                                } else {
                                    see3camcu27Controller.setFlickerMode(See3CAMCU27.FLICKER_50HZ)
                                }
                                if (Qt.platform.os !== "windows")
                                    usbcamRect.setHidAntiFlicker(frequency)
                            }
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
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To store a drop box selection in the model and apply it: AWB
//					preset and AE metering labels are mapped to enums and sent,
//					burstLen sets the burst length on the camera and
//					prevController, frequency sets 50/60 Hz flicker mode.
//
//	ARGUMENTS	:	id - JSON id of the drop box
//					value - Selected label/value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Dropdown Value Changes
// ----------------------------------------------------------------
function handleDropBoxValueChanged(id, value) {
    // Keep JSON model in sync
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var section = see3camcu27HidProperty[i]
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

    if (id === "awbPresetsCombo") {
        var awbPresetValueMap = {
            "Cloudy":                 See3CAMCU27.AWB_PRESET_CLOUDY,
            "DayLight":               See3CAMCU27.AWB_PRESET_DAYLIGHT,
            "Flash":                  See3CAMCU27.AWB_PRESET_FLASH,
            "Cool White Fluorescent": See3CAMCU27.AWB_PRESET_COOLWHITE_FLUOR,
            "Tungsten":               See3CAMCU27.AWB_PRESET_TUNGSTEN,
            "CandleLight":            See3CAMCU27.AWB_PRESET_CANDLELIGHT,
            "Horizon":                See3CAMCU27.AWB_PRESET_HORIZON,
            "Custom":                 See3CAMCU27.AWB_PRESET_CUSTOM,
            "Auto":                   See3CAMCU27.AWB_PRESET_AUTO
        }
        if (awbPresetValueMap[value] !== undefined)
            see3camcu27Controller.setAWBPresetMode(awbPresetValueMap[value])

    } else if (id === "aeMeteringMode") {
        var aeMeterValueMap = {
            "Manual":                  See3CAMCU27.AE_OFF,
            "Center-Weighted average": See3CAMCU27.AE_CENTER_WEIGHTED_AVG,
            "All block integral":      See3CAMCU27.AE_ALL_BLOCK_INTEGRAL,
            "Spot1(small area)":       See3CAMCU27.AE_SMALL_AREA,
            "Spot2(large area)":       See3CAMCU27.AE_LARGE_AREA
        }
        if (aeMeterValueMap[value] !== undefined)
            see3camcu27Controller.setAEMeteringMode(aeMeterValueMap[value])

    } else if (id === "burstLen") {
        see3camcu27Controller.setBurstLength(value)
        prevController.setBurstLength(value)
    } else if (id === "frequency") {
        if (value === "50 Hz") {
            see3camcu27Controller.setFlickerMode(See3CAMCU27.FLICKER_50HZ)
        } else if (value === "60 Hz") {
            see3camcu27Controller.setFlickerMode(See3CAMCU27.FLICKER_60HZ)
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider's new value in the model and apply it:
//					qFactorVal -> setQFactor(), denoise -> setDenoiseMode(),
//					rollValue -> setRollValue().
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
    for (var i = 0; i < see3camcu27HidProperty.length; i++) {
        var section = see3camcu27HidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = currentVal
                    break
                }
            }
        }
    }

    if (id === "qFactorVal") {
        see3camcu27Controller.setQFactor(currentVal)
    } else if (id === "denoise") {
        see3camcu27Controller.setDenoiseMode(currentVal)
    } else if (id === "rollValue") {
        see3camcu27Controller.setRollValue(currentVal)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle HID button clicks: "updateDefault" restores camera
//					defaults with setToDefault() and re-reads all controls.
//
//	ARGUMENTS	:	id - JSON id of the clicked button
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Button Click
// ----------------------------------------------------------------
function handleButtonClick(id) {
    if (id === "updateDefault") {
        see3camcu27Controller.setToDefault()
        getCameraControls()
    }
}