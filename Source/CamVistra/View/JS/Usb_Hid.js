var usbcamExtensionProperty = [];
var isUvcExposureAuto = false;
var isUvcExtExposureAuto = false;

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To replace the USB camera extension-unit property model
//					(usbcamExtensionProperty) with the JSON array loaded for the
//					selected camera.
//
//	ARGUMENTS	:	jsonArray - array of extension control groups (with children)
//					  for the camera
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    usbcamExtensionProperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getUsbcamExtensionModelData()
//
//  PURPOSE		:	To return the current USB camera extension-unit property model
//					used to build the extension controls UI.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the usbcamExtensionProperty model
///////////////////////////////////////////////////////////////////////////
function getUsbcamExtensionModelData() {
    return usbcamExtensionProperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To request the current extension-unit values from the selected
//					camera: for e-CAM212_USB reads firmware version, AE mode,
//					exposure compensation min/max, flips and HDR; for e-CAM16_USB
//					/ e-CAM82_USB reads only the firmware version. Results arrive
//					via controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getCameraControls() {
    if (controlSelectedDevName == "e-CAM212_USB") {
        ecam212usbUvcextController.readFirmwareVersion();
        ecam212usbUvcextController.getAEMode()
        ecam212usbUvcextController.readExposureCompensationMin()
        ecam212usbUvcextController.readExposureCompensationMax()
        ecam212usbUvcextController.getHorizontalFlip()
        ecam212usbUvcextController.getVerticalFlip()
        ecam212usbUvcextController.getHDR()
    }
    else if (controlSelectedDevName == "e-CAM16_USB") {
        ecam16usbController.readFirmwareVersion()
    }
    else if (controlSelectedDevName == "e-CAM82_USB") {
        ecam82usbController.readFirmwareVersion()
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFieldById(data, targetId, newText)
//
//  PURPOSE		:	To search the model tree (top-level items, their children and
//					each child's children_drop list) for the entry with targetId
//					and set its text to newText.
//
//	ARGUMENTS	:	data - array of model items to search
//					targetId - id of the item to update
//					newText - text to assign
//
//	RETURN		:	Boolean - true if the id was found and updated, false
//					otherwise
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Generic helper - traverse JSON tree and update text by id
// ----------------------------------------------------------------
function updateFieldById(data, targetId, newText) {
    for (var i = 0; i < data.length; i++) {
        var item = data[i]

        // Check top-level item
        if (item.id === targetId) {
            item.text = newText
            return true
        }

        // Check children array
        if (item.children) {
            for (var j = 0; j < item.children.length; j++) {
                var child = item.children[j]
                if (child.id === targetId) {
                    child.text = newText
                    return true
                }
                // Check children_drop if present
                if (child.children_drop) {
                    for (var k = 0; k < child.children_drop.length; k++) {
                        if (child.children_drop[k].id === targetId) {
                            child.children_drop[k].text = newText
                            return true
                        }
                    }
                }
            }
        }
    }
    return false  // id not found
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFirmwareVersioninUI(firmwareVersion)
//
//  PURPOSE		:	To show the camera firmware version in the extension model:
//					sets the first child of the first group for
//					e-CAM212/16/82_USB, or the "firmwareVer" entry for
//					See3CAM_130E.
//
//	ARGUMENTS	:	firmwareVersion - firmware version string read from the camera
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateFirmwareVersioninUI(firmwareVersion) {
    if (controlSelectedDevName == "e-CAM212_USB" || controlSelectedDevName == "e-CAM16_USB" || controlSelectedDevName == "e-CAM82_USB"){
        if (usbcamExtensionProperty.length > 0 && usbcamExtensionProperty[0].children.length > 0) {
            usbcamExtensionProperty[0].children[0].text = firmwareVersion
        }
    } else if(controlSelectedDevName == "See3CAM_130E") {
        updateFieldById(usbcamExtensionProperty, "firmwareVer", firmwareVersion);
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateHDRMode(value)
//
//  PURPOSE		:	To update the HDR mode dropdown (group 2, first child) in the
//					extension model to "ON" or "OFF" from the value read from the
//					camera.
//
//	ARGUMENTS	:	value - HDR value from the camera (1 = ON, otherwise OFF)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateHDRMode(value) {
    if (usbcamExtensionProperty && usbcamExtensionProperty.length > 2 && usbcamExtensionProperty[2].children && usbcamExtensionProperty[2].children.length > 0) {
        usbcamExtensionProperty[2].children[0].selected = (value == 1) ? "ON" : "OFF";
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAEMode(value)
//
//  PURPOSE		:	To update the AE mode dropdown (group 3) to AUTO /
//					ANTI-FLICKER / MANUAL, record whether extension exposure is
//					auto, and enable the exposure compensation min/max sliders
//					only in AUTO mode (group also needs UVC auto exposure).
//
//	ARGUMENTS	:	value - AE mode from the camera (0 = AUTO, 1 = MANUAL, 2 =
//					  ANTI-FLICKER)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateAEMode(value) {
    if (usbcamExtensionProperty && usbcamExtensionProperty.length > 3 && usbcamExtensionProperty[3].children && usbcamExtensionProperty[3].children.length > 0) {
        usbcamExtensionProperty[3].children[0].selected = (value == 0) ? "AUTO" : (value == 2) ? "ANTI-FLICKER"  : "MANUAL";
    }
    isUvcExtExposureAuto = (value == 0);
    //if(value == 0){
        for (var i = 0; i < usbcamExtensionProperty.length; ++i) {
            var section = usbcamExtensionProperty[i];
            
            if (section.id === "exposureComp") {
                var enabled = (value == 0);
                section.enabled = (enabled && isUvcExposureAuto);
                // Loop inside "exposure" children
                for (var k = 0; k < section.children.length; ++k) {
                    var child = section.children[k];

                    // --- Enable/disable exposureTime ---
                    if (child.id === "expComMax" || child.id === "expComMin") {
                        if (child.enabled !== enabled) {
                            child.enabled = enabled;
                        }
                    }
                }
            }
        }
   // } 
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExpCompMinRange(min, max, value)
//
//  PURPOSE		:	To set the range, current value and step (1) of the minimum
//					exposure compensation slider (group 1, child 0) in the
//					extension model.
//
//	ARGUMENTS	:	min - minimum slider value
//					max - maximum slider value
//					value - current value read from the camera
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateExpCompMinRange(min, max, value) {
    if (usbcamExtensionProperty && usbcamExtensionProperty.length > 1 && usbcamExtensionProperty[1].children && usbcamExtensionProperty[1].children.length > 0) {
        usbcamExtensionProperty[1].children[0].min = min;
        usbcamExtensionProperty[1].children[0].max = max;
        usbcamExtensionProperty[1].children[0].currentValue = value;
        usbcamExtensionProperty[1].children[0].step = 1;
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExpCompMaxRange(min, max, value)
//
//  PURPOSE		:	To set the range, current value and step (1) of the maximum
//					exposure compensation slider (group 1, child 1) in the
//					extension model.
//
//	ARGUMENTS	:	min - minimum slider value
//					max - maximum slider value
//					value - current value read from the camera
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateExpCompMaxRange(min, max, value) {
    if (usbcamExtensionProperty && usbcamExtensionProperty.length > 1 && usbcamExtensionProperty[1].children && usbcamExtensionProperty[1].children.length > 0) {
        usbcamExtensionProperty[1].children[1].min = min;
        usbcamExtensionProperty[1].children[1].max = max;
        usbcamExtensionProperty[1].children[1].currentValue = value;
        usbcamExtensionProperty[1].children[1].step = 1;
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderVal(label, sliderId, newValue, controlSelectedDevName)
//
//  PURPOSE		:	To apply an exposure compensation slider change for
//					e-CAM212_USB: clamps min <= max (showing a message), stores
//					the value in the model and calls setExposureCompMin/Max on
//					ecam212usbUvcextController.
//
//	ARGUMENTS	:	label - slider label (unused)
//					sliderId - "expComMin" or "expComMax"
//					newValue - value chosen by the user
//					controlSelectedDevName - name of the selected camera
//
//	RETURN		:	Array - fields whose value was clamped, as {id, currentValue,
//					value}
///////////////////////////////////////////////////////////////////////////
function updateSliderVal(label, sliderId, newValue, controlSelectedDevName) {
    let changedFields = [];

    if (controlSelectedDevName !== "e-CAM212_USB")
        return changedFields;

    const exposureCompensation = usbcamExtensionProperty.find(item => item.id === "exposureComp");
    if (!exposureCompensation || !exposureCompensation.children)
        return changedFields;

    const sliders = exposureCompensation.children;

    const slider = sliders.find(child => child.id === sliderId);
    if (!slider)
        return changedFields;

    const minSlider = sliders.find(child => child.id === "expComMin");
    const maxSlider = sliders.find(child => child.id === "expComMax");

    // ── Cross validation ──
    if (sliderId === "expComMin" && maxSlider) {
        if (newValue > maxSlider.currentValue) {
            setTextMessage("Minimum exposure compensation should be less than or equal to maximum exposure compensation");
            newValue = maxSlider.currentValue;

            changedFields.push({
                id: "expComMin",
                currentValue: newValue,
                value: newValue
            });
        }
    }
    else if (sliderId === "expComMax" && minSlider) {
        if (newValue < minSlider.currentValue) {
            setTextMessage("Maximum exposure compensation should be greater than or equal to minimum exposure compensation");
            newValue = minSlider.currentValue;

            changedFields.push({
                id: "expComMax",
                currentValue: newValue,
                value: newValue
            });
        }
    }
    // ─────────────────────

    // Apply value
    if (slider.currentValue !== newValue) {
        slider.currentValue = newValue;

        const actionMap = {
            expComMin: (v) => ecam212usbUvcextController.setExposureCompMin(v),
            expComMax: (v) => ecam212usbUvcextController.setExposureCompMax(v)
        };

        if (actionMap[sliderId]) {
            actionMap[sliderId](newValue);
        }
    }
    
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValChanged(label, id, selectedValue, deviceName)
//
//  PURPOSE		:	To store a dropdown selection in the extension model and, for
//					e-CAM212_USB, apply it: HDR ON/OFF via setHDR(), or AE mode
//					via setAEMode() while enabling/disabling the exposure
//					compensation group for AUTO.
//
//	ARGUMENTS	:	label - dropdown label (unused)
//					id - dropdown id, e.g. "hdrMode_d" or "aeControlMode_d"
//					selectedValue - text of the selected option
//					deviceName - name of the selected camera
//
//	RETURN		:	Array - list of {id, ...} objects describing the model fields
//					that changed, for targeted UI updates
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValChanged(label, id, selectedValue, deviceName) {
    var changedFields = [];  // Track what actually changed

    // --- Traverse the model and update matching dropdown ---
    for (var i = 0; i < usbcamExtensionProperty.length; ++i) {
        var group = usbcamExtensionProperty[i];
        if (group.children) {
            for (var j = 0; j < group.children.length; ++j) {
                var child = group.children[j];

                if (child.id === id) {
                    //  update the selected value in the JSON model
                    child.selected = selectedValue;
                    child.currentValue = selectedValue;
                }

                // -------- CASE 2: Inner child matches --------
                if (child.children && child.children.length > 0) {
                    for (var k = 0; k < child.children.length; ++k) {
                        var innerChild = child.children[k];

                        if (innerChild.id === id) {
                            innerChild.selected = selectedValue;
                            innerChild.currentValue = selectedValue;

                        }
                    }
                }
            }
        }
    }

    if (deviceName == "e-CAM212_USB") {
        if (id == "hdrMode_d") {
            if (selectedValue === "ON") {
                ecam212usbUvcextController.setHDR(1);
            } else {
                ecam212usbUvcextController.setHDR(0);
            }

            // Add to changed fields to update parent label
            changedFields.push({
                id: id,
                selected: selectedValue
            });
        } else if (id == "aeControlMode_d") {
            for (var i = 0; i < usbcamExtensionProperty.length; ++i) {
                var section = usbcamExtensionProperty[i];
                if (section.id === "exposureComp") {
                    var enabled = (selectedValue === "AUTO") && isUvcExposureAuto;
                    section.enabled = enabled;
                    changedFields.push({
                        id: "exposureComp",
                        enabled: enabled
                    });
                    // Loop inside "exposure" children
                    for (var k = 0; k < section.children.length; ++k) {
                        var child = section.children[k];

                        // --- Enable/disable exposureTime ---
                        if (child.id === "expComMax" || child.id === "expComMin") {
                            if (child.enabled !== enabled) {
                                child.enabled = enabled;
                                changedFields.push({
                                    id: child.id,
                                    enabled: enabled
                                });
                            }
                        }
                    }
                }
            }
            if (selectedValue === "AUTO") {
                ecam212usbUvcextController.setAEMode(0);
            } else if (selectedValue === "MANUAL") {
                ecam212usbUvcextController.setAEMode(1);
            } else if (selectedValue === "ANTI-FLICKER") {
                ecam212usbUvcextController.setAEMode(2);
            }

            // Add to changed fields to update parent label
            changedFields.push({
                id: id,
                selected: selectedValue
            });
        }
    }
    return changedFields;  // Return what changed for targeted updates
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	enableOrDisableExposureComp(mode)
//
//  PURPOSE		:	To record the UVC auto exposure state and enable the exposure
//					compensation group and its min/max sliders only when both UVC
//					and extension AE mode are auto.
//
//	ARGUMENTS	:	mode - true if UVC exposure is in auto mode
//
//	RETURN		:	Array - list of {id, ...} objects describing the model fields
//					that changed, for targeted UI updates
///////////////////////////////////////////////////////////////////////////
function enableOrDisableExposureComp(mode){
    isUvcExposureAuto = mode;
    var changedFields = []; 
    for (var i = 0; i < usbcamExtensionProperty.length; ++i) {
        var section = usbcamExtensionProperty[i];
        if (section.id === "exposureComp") {
            var enabled = mode && isUvcExtExposureAuto;
            section.enabled = enabled;
            changedFields.push({
                id: "exposureComp",
                enabled: enabled
            });
            // Loop inside "exposure" children
            for (var k = 0; k < section.children.length; ++k) {
                var child = section.children[k];

                // --- Enable/disable exposureTime ---
                if (child.id === "expComMax" || child.id === "expComMin") {
                    if (child.enabled !== enabled) {
                        child.enabled = enabled;
                        changedFields.push({
                            id: child.id,
                            enabled: enabled
                        });
                    }
                }
            }
        }
    }
    return changedFields; 
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateHorizontalFlip(value)
//
//  PURPOSE		:	To update the "horizontal" flip checkbox in the extension
//					model from the value read from the camera.
//
//	ARGUMENTS	:	value - horizontal flip state (1 = enabled)
//
//	RETURN		:	Array - [{id, checked}] if the checkbox was found, else empty
///////////////////////////////////////////////////////////////////////////
function updateHorizontalFlip(value) {
    return updateCheckBoxField("horizontal", value == 1);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateVerticalFlip(value)
//
//  PURPOSE		:	To update the "vertical" flip checkbox in the extension model
//					from the value read from the camera.
//
//	ARGUMENTS	:	value - vertical flip state (1 = enabled)
//
//	RETURN		:	Array - [{id, checked}] if the checkbox was found, else empty
///////////////////////////////////////////////////////////////////////////
function updateVerticalFlip(value) {
    return updateCheckBoxField("vertical", value == 1);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxField(targetId, checked)
//
//  PURPOSE		:	To find the checkbox with targetId among the children of the
//					extension model groups and set its checked state (model only,
//					no camera call).
//
//	ARGUMENTS	:	targetId - id of the checkbox entry
//					checked - new checked state
//
//	RETURN		:	Array - [{id, checked}] if the checkbox was found, else empty
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxField(targetId, checked) {
    for (var i = 0; i < usbcamExtensionProperty.length; ++i) {
        var section = usbcamExtensionProperty[i];
        if (!section.children)
            continue;
        for (var j = 0; j < section.children.length; ++j) {
            var child = section.children[j];
            if (child.id === targetId) {
                child.checked = checked;
                return [{ id: targetId, checked: checked }];
            }
        }
    }
    return [];
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To handle a user checkbox toggle: updates the model and, for
//					e-CAM212_USB, calls setHorizontalFlip() or setVerticalFlip()
//					on ecam212usbUvcextController.
//
//	ARGUMENTS	:	id - checkbox id ("horizontal" or "vertical")
//					checked - new checked state
//
//	RETURN		:	Array - [{id, checked}] if the checkbox was found, else empty
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked) {
    var changedFields = updateCheckBoxField(id, checked);
    if (controlSelectedDevName == "e-CAM212_USB") {
        if (id === "horizontal") {
            ecam212usbUvcextController.setHorizontalFlip(checked);
        } else if (id === "vertical") {
            ecam212usbUvcextController.setVerticalFlip(checked);
        }
    }
    return changedFields;
}
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(groupId, id, checked)
//
//  PURPOSE		:	To handle a radio button change in the extension controls.
//					Currently a placeholder that makes no model or camera changes.
//
//	ARGUMENTS	:	groupId - id of the radio group
//					id - id of the selected radio button
//					checked - new checked state
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(groupId, id, checked) {
    var changedFields = [];
        
    return changedFields;
}
