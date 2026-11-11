.pragma library

var see3camcu55mhHidProperty = []

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To store the HID settings JSON model (array of sections with
//					children controls) used by all lookups in this
//					See3CAM_CU55MH module.
//
//	ARGUMENTS	:	jsonArray - Array of control sections loaded by UsbcamHidSettings.qml
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camcu55mhHidProperty = jsonArray
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the See3CAM_CU55MH HID settings JSON model held by
//					this module, including values updated from the camera.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current HID settings model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return see3camcu55mhHidProperty
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To query the camera via see3camcu55mhController for stream mode,
//					flash mode, orientation, 64-bit serial number and firmware
//					version. Results arrive through controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    see3camcu55mhController.getStreamMode()
    see3camcu55mhController.getFlashMode()
    see3camcu55mhController.getOrientation()
    see3camcu55mhController.get64BitSerialNumber()
    see3camcu55mhController.getFirmwareVersion()
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
//	ARGUMENTS	:	streamMode - See3CAMCU55MH master or trigger stream mode value
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateStreamMode(streamMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu55mhHidProperty.length; i++) {
        var group = see3camcu55mhHidProperty[i]
        if (group.id === "streamMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "masterMode") {
                    child.checked = (streamMode === See3CAMCU55MH.STREAM_MODE_MASTER)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "triggerMode") {
                    child.checked = (streamMode === See3CAMCU55MH.STREAM_MODE_TRIGGER)
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
//  PURPOSE		:	To reflect the flash mode in the disableMode / strobeMode /
//					torchMode radio buttons of the 'flashMode' section.
//
//	ARGUMENTS	:	flashMode - See3CAMCU55MH flash mode value from the camera
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateFlashMode(flashMode) {
    var changedFields = []
    for (var i = 0; i < see3camcu55mhHidProperty.length; i++) {
        var group = see3camcu55mhHidProperty[i]
        if (group.id === "flashMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "disableMode") {
                    child.checked = (flashMode === See3CAMCU55MH.FLASH_MODE_OFF)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "strobeMode") {
                    child.checked = (flashMode === See3CAMCU55MH.FLASH_MODE_STROBE)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "torchMode") {
                    child.checked = (flashMode === See3CAMCU55MH.FLASH_MODE_TORCH)
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
//  PURPOSE		:	To set the horizontal / vertical checkboxes of the 'flipControl'
//					section from the camera flip mode (both checked for
//					rotate 180 / both).
//
//	ARGUMENTS	:	flipMode - See3CAMCU55MH flip mode value from the camera
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateOrientation(flipMode) {
    var changedFields = []
    var horzChecked = (flipMode === See3CAMCU55MH.FLIP_MODE_HORIZONTAL || flipMode === See3CAMCU55MH.FLIP_MODE_BOTH)
    var vertChecked = (flipMode === See3CAMCU55MH.FLIP_MODE_VERTICAL || flipMode === See3CAMCU55MH.FLIP_MODE_BOTH)

    for (var i = 0; i < see3camcu55mhHidProperty.length; i++) {
        var group = see3camcu55mhHidProperty[i]
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "horizontal") {
                    child.checked = horzChecked
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "vertical") {
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
function updateSerialNumber(serialNum) {
    var changedFields = []
    for (var i = 0; i < see3camcu55mhHidProperty.length; i++) {
        var group = see3camcu55mhHidProperty[i]
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
function updateFirmwareVersioninUI(firmwareVersion) {
    var changedFields = []
    for (var i = 0; i < see3camcu55mhHidProperty.length; i++) {
        var group = see3camcu55mhHidProperty[i]
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
//					horizontal / vertical flip checkboxes, read both flip states and
//					apply them via see3camcu55mhController.setOrientation().
//
//	ARGUMENTS	:	id - Checkbox id
//					checked - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked) {
    for (var i = 0; i < see3camcu55mhHidProperty.length; i++) {
        var section = see3camcu55mhHidProperty[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].checked = checked
                    break
                }
            }
        }
    }

    if (id === "horizontal" || id === "vertical") {
        var horzFlip = false
        var vertFlip = false
        for (var i = 0; i < see3camcu55mhHidProperty.length; i++) {
            var section = see3camcu55mhHidProperty[i]
            if (section.id === "flipControl" && section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    if (section.children[j].id === "horizontal") horzFlip = section.children[j].checked
                    if (section.children[j].id === "vertical") vertFlip = section.children[j].checked
                }
                break
            }
        }
        see3camcu55mhController.setOrientation(horzFlip, vertFlip)
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To update the clicked radio in the stream or flash mode
//					section, uncheck its siblings with the same identification,
//					and when checked call setStreamMode() or setFlashMode() on
//					see3camcu55mhController.
//
//	ARGUMENTS	:	identification - Radio group identification ('streamModes'
//					  or 'flashModes')
//					id - Id of the radio button that changed
//					checked - New checked state
//
//	RETURN		:	Array - {id, checked} change objects (empty if group unknown)
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(identification, id, checked) {
    var changedFields = []
    var groupId = null

    if (identification === "streamModes") {
        groupId = "streamMode"
    } else if (identification === "flashModes") {
        groupId = "flashMode"
    }

    if (!groupId) return changedFields

    for (var i = 0; i < see3camcu55mhHidProperty.length; i++) {
        var section = see3camcu55mhHidProperty[i]
        if (section.id === groupId && section.children) {
            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]
                if (radio.id === id) {
                    radio.checked = checked
                    changedFields.push({ id: radio.id, checked: checked })
                    if (checked) {
                        if (groupId === "streamMode") {
                            var streamMap = {
                                "masterMode": See3CAMCU55MH.STREAM_MODE_MASTER,
                                "triggerMode": See3CAMCU55MH.STREAM_MODE_TRIGGER
                            }
                            if (streamMap[id] !== undefined) {
                                see3camcu55mhController.setStreamMode(streamMap[id])
                            }
                        } else if (groupId === "flashMode") {
                            var flashMap = {
                                "disableMode": See3CAMCU55MH.FLASH_MODE_OFF,
                                "strobeMode": See3CAMCU55MH.FLASH_MODE_STROBE,
                                "torchMode": See3CAMCU55MH.FLASH_MODE_TORCH
                            }
                            if (flashMap[id] !== undefined) {
                                see3camcu55mhController.setFlashMode(flashMap[id])
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
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To restore camera defaults when updateDefault is pressed
//					(see3camcu55mhController.restoreDefault()) and then
//					re-read controls via getDelayedCameraControls().
//
//	ARGUMENTS	:	id - Button id (only updateDefault is handled)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {
    if (id === "updateDefault") {
        see3camcu55mhController.restoreDefault()
        getDelayedCameraControls()
    }
}
