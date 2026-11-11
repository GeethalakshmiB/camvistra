var see3camcu512mHidProperty = []

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To store the HID settings JSON model (array of sections with
//					children controls) used by all lookups in this
//					See3CAM_CU512M module.
//
//	ARGUMENTS	:	jsonArray - Array of control sections loaded by UsbcamHidSettings.qml
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camcu512mHidProperty = jsonArray
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the See3CAM_CU512M HID settings JSON model held by
//					this module, including values updated from the camera.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current HID settings model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return see3camcu512mHidProperty
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To schedule reading of all See3CAM_CU512M HID controls by
//					starting the QML delayedControlsTimer, which later calls
//					getDelayedCameraControls().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Get all camera controls on initialization
// ---------------------------------------------------------------
function getCameraControls() {
    delayedControlsTimer.start()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To query the camera via see3camcu512mController for stream mode,
//					flash mode, orientation, 64-bit serial number and firmware
//					version. Results arrive through controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
function getDelayedCameraControls() {
    see3camcu512mController.getStreamMode()
    see3camcu512mController.getFlashMode()
    see3camcu512mController.getOrientation()
    see3camcu512mController.get64BitSerialNumber()
    see3camcu512mController.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To satisfy the common HID module interface; this module keeps
//					no cached state, so nothing is reset.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStreamMode(streamMode)
//
//  PURPOSE		:	To reflect the stream mode in the masterMode / triggerMode
//					radio buttons of the 'streamMode' section.
//
//	ARGUMENTS	:	streamMode - See3CAM_CU512M master or trigger stream mode value
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Stream Mode  (radioButtons: masterMode, triggerMode)
// ----------------------------------------------------------------
function updateStreamMode(streamMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
        var group = see3camcu512mHidProperty[i]
        if (group.id === "streamMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "masterMode") {
                    child.checked = (streamMode === See3CAM_CU512M.MASTER)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "triggerMode") {
                    child.checked = (streamMode === See3CAM_CU512M.TRIGGER)
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
//  PURPOSE		:	To show the flash mode label (Disable, Strobe, Torch) as the
//					selected value of the flashMode combo box in the
//					'flashControl' section.
//
//	ARGUMENTS	:	flashMode - See3CAM_CU512M DISABLE, STROBE or TORCH value
//
//	RETURN		:	Array - {id, currentValue, selected} change, or empty
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Flash Mode  (radioButtons: disableMode, strobeMode, torchMode)
// ----------------------------------------------------------------
function updateFlashMode(flashMode) {
    var changedFields = []

    var flashIdMap = {}
    flashIdMap[See3CAM_CU512M.DISABLE] = "disableMode"
    flashIdMap[See3CAM_CU512M.STROBE]  = "strobeMode"
    flashIdMap[See3CAM_CU512M.TORCH]   = "torchMode"

    var selectedId = flashIdMap[flashMode]
    if (selectedId === undefined) return changedFields

    for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
        var group = see3camcu512mHidProperty[i]
        if (group.id === "flashMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.identification === "flashModes") {
                    child.checked = (child.id === selectedId)
                    changedFields.push({ id: child.id, checked: child.checked })
                }
            }
            break
        }
    }
    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateOrientation(flipMode)
//
//  PURPOSE		:	To set the horzFlip / vertFlip checkboxes of the 'imageOrientation'
//					section from the camera flip mode (both checked for
//					rotate 180 / both).
//
//	ARGUMENTS	:	flipMode - See3CAM_CU512M flip mode value from the camera
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Orientation / Flip  (checkboxes: horzFlip, vertFlip)
// ----------------------------------------------------------------
function updateOrientation(flipMode) {
    var changedFields = []

    var horzChecked = (flipMode === See3CAM_CU512M.HORIZONTAL ||
                       flipMode === See3CAM_CU512M.ROTATE_180)
    var vertChecked = (flipMode === See3CAM_CU512M.VERTICAL   ||
                       flipMode === See3CAM_CU512M.ROTATE_180)

    for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
        var group = see3camcu512mHidProperty[i]
        if (group.id === "imageOrientation" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horzFlip") {
                    child.checked = horzChecked
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "vertFlip") {
                    child.checked = vertChecked
                    changedFields.push({ id: child.id, checked: child.checked })
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
//  PURPOSE		:	To display the serial number in the serialNumber text field
//					of the 'serialNum' section.
//
//	ARGUMENTS	:	serialNum - Serial number string from the camera
//
//	RETURN		:	Array - {id, text} change, or empty
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Serial Number
// ----------------------------------------------------------------
function updateSerialNumber(serialNum) {
    var changedFields = []
    for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
        var group = see3camcu512mHidProperty[i]
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
//  PURPOSE		:	To display the firmware version in the firmwareVer text
//					field of the 'firmwareVersion' section.
//
//	ARGUMENTS	:	firmwareVersion - Firmware version from the camera
//
//	RETURN		:	Array - {id, text} change, or empty
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Firmware Version
// ----------------------------------------------------------------
function updateFirmwareVersioninUI(firmwareVersion) {
    var changedFields = []
    for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
        var group = see3camcu512mHidProperty[i]
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
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store the checkbox state in the model and, for the
//					horzFlip / vertFlip flip checkboxes, read both flip states and
//					apply them via see3camcu512mController.setOrientation().
//
//	ARGUMENTS	:	id - Checkbox id
//					checked - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Checkbox Changes
// ----------------------------------------------------------------
function updateCheckBoxValue(id, checked) {
    // Keep JSON model in sync
    for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
        var section = see3camcu512mHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].checked = checked
                    break
                }
            }
        }
    }

    if (id === "horzFlip" || id === "vertFlip") {
        var horzFlip = false
        var vertFlip = false

        // Read the current state of both flip checkboxes from the model
        for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
            var section = see3camcu512mHidProperty[i]
            if (section.id === "imageOrientation" && section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    if (section.children[j].id === "horzFlip") horzFlip = section.children[j].checked
                    if (section.children[j].id === "vertFlip")  vertFlip = section.children[j].checked
                }
                break
            }
        }
        see3camcu512mController.setOrientation(horzFlip, vertFlip)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To update the clicked radio in the 'streamMode' section,
//					uncheck its siblings with the same identification, and when
//					checked send the mode via see3camcu512mController.setStreamMode().
//
//	ARGUMENTS	:	identification - Radio group identification (only 'streamMode')
//					id - Id of the radio button that changed
//					checked - New checked state
//
//	RETURN		:	Array - {id, checked} change objects (empty if group unknown)
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Radio Button Changes
// ----------------------------------------------------------------
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []

    var identificationToGroupId = {
        "streamModes": "streamMode",
        "flashModes":  "flashMode"
    }

    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
        var section = see3camcu512mHidProperty[i]

        if (section.id === groupId && section.children) {
            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]

                if (radio.id === id) {
                    radio.checked = checked
                    changedFields.push({ id: radio.id, checked: checked })

                    if (checked) {
                        if (groupId === "streamMode") {
                            var streamMap = {
                                "masterMode":  See3CAM_CU512M.MASTER,
                                "triggerMode": See3CAM_CU512M.TRIGGER
                            }
                            if (streamMap[id] !== undefined)
                                see3camcu512mController.setStreamMode(streamMap[id])
                        } else if (groupId === "flashMode") {
                            var flashMap = {
                                "disableMode": See3CAM_CU512M.DISABLE,
                                "strobeMode":  See3CAM_CU512M.STROBE,
                                "torchMode":   See3CAM_CU512M.TORCH
                            }
                            if (flashMap[id] !== undefined)
                                see3camcu512mController.setFlashMode(flashMap[id])
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
//  PURPOSE		:	To store the combo box value in the model and, for flashMode,
//					map the label (Disable/Strobe/Torch) to a mode and call
//					see3camcu512mController.setFlashMode().
//
//	ARGUMENTS	:	id - Combo box id
//					value - Selected label
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Dropdown Value Changes
// ----------------------------------------------------------------
function handleDropBoxValueChanged(id, value) {
    // Keep JSON model in sync
    for (var i = 0; i < see3camcu512mHidProperty.length; i++) {
        var section = see3camcu512mHidProperty[i]
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
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To restore camera defaults when updateDefault is pressed
//					(see3camcu512mController.restoreDefault()) and then
//					re-read controls via getCameraControls().
//
//	ARGUMENTS	:	id - Button id (only updateDefault is handled)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Handle Button Click
// ----------------------------------------------------------------
function handleButtonClick(id) {
    if (id === "updateDefault") {
        see3camcu512mController.restoreDefault()
        getCameraControls()
    }
}