var usbcamProperty = [];
var videoPropertyId = 1;
var stillPropertyId = 2;
var exposureId = 4;
var whiteBalanceId = 5;
var isExposureAuto = false
var isWbAuto = false
var isFocusAuto = false
// True while the 130E/130E_H02R1/1318_TC HID anti-flicker mode is AUTO.
// UVC hardware has no mirrored AUTO value on Linux, so re-polling
// powerLineFreq_d must not replace the blank placeholder with stale data.
var isAntiFlickerHidAuto = false
var currentResolution = ""
var currentFormat = ""
var currentFps = ""
var currentStillFmt = ""
var currentStillResn = ""
var currentStillFps = ""
var currentFileFmt = ""
var cameraSettingsNode = null;
var cameraUiIndex = {};
// Declare the property at the top of the file
var imagePropertiesMap = {}
var readStillProperty = false;


///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To replace the USB camera UVC property model (usbcamProperty:
//					camera settings, video properties, still capture) with the
//					JSON array loaded for the selected camera.
//
//	ARGUMENTS	:	jsonArray - array of property groups for the camera
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    usbcamProperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getUsbcamModelData()
//
//  PURPOSE		:	To return the current USB camera UVC property model used to
//					build the camera settings UI.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the usbcamProperty model
///////////////////////////////////////////////////////////////////////////
function getUsbcamModelData() {
    return usbcamProperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	hasChildren(node, count)
//
//  PURPOSE		:	To check that a model node exists and has a children array
//					with at least the given number of entries, so callers can
//					index it safely.
//
//	ARGUMENTS	:	node - model node to check
//					count - minimum number of children required
//
//	RETURN		:	Boolean - true if node has at least count children
///////////////////////////////////////////////////////////////////////////
function hasChildren(node, count) {
    return node !== undefined && node !== null
        && node.children !== undefined && node.children !== null
        && node.children.length >= count;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	imagePropertyModelReady()
//
//  PURPOSE		:	To check that the video properties and still capture groups
//					are loaded and each has at least the format, resolution and
//					FPS children.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Boolean - true if the image property model can be indexed
///////////////////////////////////////////////////////////////////////////
function imagePropertyModelReady() {
    return usbcamProperty !== undefined && usbcamProperty !== null
        && hasChildren(usbcamProperty[videoPropertyId], 3)
        && hasChildren(usbcamProperty[stillPropertyId], 3);
}

// Re-applies the last confirmed (applied) Still Capture values to the UI
// model, discarding any dropdown selection the user made but never applied
// (e.g. via Apply/Update). Mirrors what the Video Properties "get" already
// does on every Camera Settings tab load, so Still Capture stops showing
// stale unapplied selections after switching tabs.
function resyncStillProperties() {
    if (!imagePropertyModelReady()) return

    if (currentStillFmt) {
        usbcamProperty[stillPropertyId].children[0].selected = currentStillFmt
    }
    if (currentStillResn) {
        usbcamProperty[stillPropertyId].children[1].selected = currentStillResn
    }
    if (currentStillFps) {
        usbcamProperty[stillPropertyId].children[2].selected = currentStillFps
    }
    // currentFileFmt stays "" until the user actually applies a still
    // capture update at least once; until then the true current value is
    // the backend's own default ("BMP" - see PreviewController::resetStillCaptureState).
    usbcamProperty[stillPropertyId].children[3].selected = currentFileFmt || "BMP"
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearValues()
//
//  PURPOSE		:	To reset the cached current/still format, resolution, FPS and
//					file format, the image properties map, the still-read flag and
//					the HID anti-flicker AUTO flag, typically when the camera
//					changes.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearValues() {
    readStillProperty = false;
    currentResolution = "";
    currentFormat = "";
    currentFps = "";
    currentStillFmt = "";
    currentStillResn = "";
    currentStillFps = "";
    currentFileFmt = "";
    imagePropertiesMap = {};
    isAntiFlickerHidAuto = false;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setAntiFlickerHidAuto(isAuto)
//
//  PURPOSE		:	To record whether the HID (extension) anti-flicker mode is
//					AUTO, so updateProperty() ignores UVC powerLineFreq polls
//					while it is.
//
//	ARGUMENTS	:	isAuto - true if HID anti-flicker is in AUTO mode
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setAntiFlickerHidAuto(isAuto) {
    isAntiFlickerHidAuto = isAuto;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached auto exposure and auto white balance
//					flags.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    isExposureAuto = false;
    isWbAuto = false;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	disableControl(parent, index)
//
//  PURPOSE		:	To disable a control the camera does not support: for
//					"cameraSettings" maps the UVC control index to a model id
//					(e.g. 9 = gain, 15 = exposure) and sets that node's enabled to
//					false (index 18 also disables the focus group if focusMode is
//					disabled); for "vidProperties" disables the whole video
//					properties group.
//
//	ARGUMENTS	:	parent - "cameraSettings" or "vidProperties"
//					index - UVC control index reported as unsupported
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function disableControl(parent, index) {

    if (parent == "cameraSettings") {
        // Map of indices to their corresponding IDs in cameraSettings
        const cameraSettingsMap = {
            0: "brightness",
            1: "contrast",
            2: "hue",
            3: "c_saturation",
            4: "sharpness",
            5: "gamma",
            6: "whiteBalance",
            8: "backlightCompensation",
            9: "gain",
            10: "powerLineFreq",
            11: "pan",
            12: "tilt",
            13: "roll",
            14: "zoom",
            15: "exposure",
            17: "focusMode",
            18: "focusValue"
        };

        // Find the cameraSettings object (first item in usbcamProperty)
        const cameraSettings = usbcamProperty.find(item => item.id === parent);

        if (!cameraSettings) {
            return;
        }

        // Get the ID to disable based on index
        const idToDisable = cameraSettingsMap[index];

        if (!idToDisable) {
            logController.displayMessage(verboseLogPriority, "UI: Invalid index or ID not mapped for USB Camera Controls\n");	
            return;
        }
        // 🔍 Recursive search function
        ///////////////////////////////////////////////////////////////////////////
        //  FUNCTION	:	findChildById(node, id)
        //
        //  PURPOSE		:	To recursively search the children of a model node for the
        //					entry with the given id.
        //
        //	ARGUMENTS	:	node - model node to search under
        //					id - id of the entry to find
        //
        //	RETURN		:	Object - the matching node, or null if not found
        ///////////////////////////////////////////////////////////////////////////
        function findChildById(node, id) {
            if (!node || !node.children) return null;

            for (let child of node.children) {
                if (child.id === id) {
                    return child;
                }
                // Search nested children (recursive)
                const found = findChildById(child, id);
                if (found) return found;
            }
            return null;
        }

        if (index == 18) {
            const focusMode = findChildById(cameraSettings, "focusMode");
            if (focusMode.enabled == false) {
                const focusToDisable = findChildById(cameraSettings, "focus");
                if (focusToDisable) {
                    focusToDisable.enabled = false;
                } else {
                    console.log(`Control with id ${idToDisable} not found`);
                }

            }
        }

        // Find and disable
        const childToDisable = findChildById(cameraSettings, idToDisable);

        if (childToDisable) {
            childToDisable.enabled = false;
        } else {
            console.log(`Control with id ${idToDisable} not found`);
        }
    }
    else if (parent == "vidProperties") {
        usbcamProperty[1].enabled = false
    } 
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderVal(label, sliderId, newValue)
//
//  PURPOSE		:	To apply a camera settings slider change: stores the new value
//					in the model, sends it to the camera via
//					prevController.setCameraControlProperty() and, for gain,
//					mirrors it to usbcamRect.setUvcGainValue().
//
//	ARGUMENTS	:	label - slider label (unused)
//					sliderId - id of the slider, e.g. "gain_s"
//					newValue - value chosen by the user
//
//	RETURN		:	Boolean - true if the slider was found, false otherwise
///////////////////////////////////////////////////////////////////////////
function updateSliderVal(label, sliderId, newValue) {
    const camSettingConfig = usbcamProperty.find(item => item.id === "cameraSettings");

    if (!camSettingConfig || !camSettingConfig.children) return false;

    // Search through all parent fields
    for (let parentField of camSettingConfig.children) {
        if (parentField.children) {
            const slider = parentField.children.find(child => child.id === sliderId);
            if (slider) {
                if (slider.currentValue != newValue) {
                    slider.currentValue = newValue;
                    prevController.setCameraControlProperty(selectedIndex, sliderId, newValue);
                    if (slider.id == "gain_s") {
                        usbcamRect.setUvcGainValue(newValue)
                    } 
                }
                return true;
            }
        }
    }
    return false;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValChanged(label, id, selectedValue)
//
//  PURPOSE		:	To store a dropdown selection in the model and apply it:
//					backlight, power line frequency, exposure, focus and white
//					balance modes are sent via
//					prevController.setCameraControlProperty() (enabling/disabling
//					dependent sliders), while format/resolution changes repopulate
//					the resolution and FPS dropdowns for video or still capture.
//
//	ARGUMENTS	:	label - dropdown label (unused)
//					id - dropdown id, e.g. "format", "stillResolution",
//					  "exposureMode"
//					selectedValue - text of the selected option
//
//	RETURN		:	Array - list of {id, ...} objects describing the model fields
//					that changed, for targeted UI updates
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValChanged(label, id, selectedValue) {

    var changedFields = [];  // Track what actually changed

    // --- Traverse the model and update matching dropdown ---
    for (var i = 0; i < usbcamProperty.length; ++i) {
        var group = usbcamProperty[i];
        if (group.children) {
            for (var j = 0; j < group.children.length; ++j) {
                var child = group.children[j];

                if (child.id === id) {
                    // ✅ update the selected value in the JSON model
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

    if (id == "backlightCompensation_d") {
        if (selectedValue === "ON") {
            prevController.setCameraControlProperty(selectedIndex, id, 1)
        } else {
            prevController.setCameraControlProperty(selectedIndex, id, 0)
        }

        // Add to changed fields to update parent label
        changedFields.push({
            id: id,
            selected: selectedValue
        });
    } if (id == "powerLineFreq_d") {
        // A concrete UVC selection always exits the HID-only AUTO display state.
        setAntiFlickerHidAuto(false)
        if (selectedValue === "DISABLE") {
            prevController.setCameraControlProperty(selectedIndex, id, 0)
        } else if (selectedValue === "50 Hz") {
            prevController.setCameraControlProperty(selectedIndex, id, 1)
        } else if (selectedValue === "60 Hz") {
            prevController.setCameraControlProperty(selectedIndex, id, 2)
        }
        usbcamRect.setUvcAntiFlicker(selectedValue)

        var updatedOptions = [];  // To hold the cleaned children_drop

        // --- Remove "" from children_drop if a valid value is selected ---
        const validValues = ["DISABLE", "50 Hz", "60 Hz"];
        if (validValues.includes(selectedValue)) {
            for (var i = 0; i < usbcamProperty.length; ++i) {
                var group = usbcamProperty[i];
                if (group.children) {
                    for (var j = 0; j < group.children.length; ++j) {
                        var child = group.children[j];
                        if (child.children) {
                            for (var k = 0; k < child.children.length; ++k) {
                                var innerChild = child.children[k];
                                if (innerChild.id === id && innerChild.children_drop) {
                                    // Remove empty label1 entries
                                    innerChild.children_drop = innerChild.children_drop.filter(
                                        item => item.label1 !== " "
                                    );
                                    // Extract label1 values from cleaned children_drop
                                    updatedOptions = innerChild.children_drop.map(item => ({ label1: item.label1 }));
                                }
                            }
                        }
                    }
                }
            }
        }

        // Add to changed fields with updated options from children_drop
        changedFields.push({
            id: id,
            selected: selectedValue,
            options: updatedOptions  // ["DISABLE", "50 Hz", "60 Hz"]
        });
    }
    // Handle Video Properties dropdowns
    if (id === "format") {
        for (var i = 0; i < usbcamProperty.length; ++i) {
            var group = usbcamProperty[i];
            if (group.id === "vidProperties") {
                if (imagePropertiesMap && imagePropertiesMap[selectedValue]) {
                    var keys = Object.keys(imagePropertiesMap[selectedValue]);
                    var resolutions = keys.filter(function (key) {
                        return key !== "profiles" && key !== "currentProfile";
                    });

                    resolutions.sort(function (a, b) {
                        var partsA = a.split('x');
                        var partsB = b.split('x');
                        if (partsA.length === 2 && partsB.length === 2) {
                            var wA = parseInt(partsA[0]), hA = parseInt(partsA[1]);
                            var wB = parseInt(partsB[0]), hB = parseInt(partsB[1]);
                            if (wA !== wB) return wB - wA;
                            return hB - hA;
                        }
                        return b.localeCompare(a);
                    });

                    for (var j = 0; j < group.children.length; ++j) {
                        var child = group.children[j];
                        if (child.id === "resolution") {
                            var resolutionOpts = resolutions.map(function (r) {
                                return { label1: r };
                            });

                            child.children_drop = resolutionOpts;

                            if (resolutionOpts.length > 0) {
                                // Prefer currentResolution if it exists in the list
                                var selectedResolution = resolutionOpts[0].label1;
                                if (typeof currentResolution !== "undefined") {
                                    for (var m = 0; m < resolutionOpts.length; m++) {
                                        if (resolutionOpts[m].label1 === currentResolution) {
                                            selectedResolution = currentResolution;
                                            break;
                                        }
                                    }
                                }
                                child.selected = selectedResolution;

                                changedFields.push({
                                    id: "resolution",
                                    options: resolutionOpts,
                                    selected: child.selected
                                });

                                var fpsUpdated = updateFpsForResolution(group, selectedValue, child.selected);
                                if (fpsUpdated) {
                                    changedFields.push(fpsUpdated);
                                }
                            }
                        }
                    }
                }
                break;
            }
        }
    }

    if (id === "resolution") {

        // Find video properties section and current format
        for (var i = 0; i < usbcamProperty.length; ++i) {
            var group = usbcamProperty[i];
            if (group.id === "vidProperties") {

                // Get current format
                var currentFormat = null;
                for (var j = 0; j < group.children.length; ++j) {
                    if (group.children[j].id === "format") {
                        currentFormat = group.children[j].selected;
                        break;
                    }
                }

                // Update FPS dropdown
                if (currentFormat) {
                    var fpsUpdated = updateFpsForResolution(group, currentFormat, selectedValue);
                    if (fpsUpdated) {
                        changedFields.push(fpsUpdated);
                    }
                }

                break;
            }
        }
    }

    if (id === "FPS") {
        changedFields.push({
            id: "FPS",
            selected: selectedValue
        });
    }

    //Handle Still Properties dropdowns
    if (id === "stillFormat") {

        // Find video properties section
        for (var i = 0; i < usbcamProperty.length; ++i) {
            var group = usbcamProperty[i];
            if (group.id === "stillCapture") {

                // Update resolution dropdown based on selected format
                if (imagePropertiesMap && imagePropertiesMap[selectedValue]) {
                    var keys = Object.keys(imagePropertiesMap[selectedValue]);
                    var resolutions = keys.filter(function (key) {
                        return key !== "profiles" && key !== "currentProfile";
                    });

                    // Sort resolutions in descending order
                    resolutions.sort(function (a, b) {
                        var partsA = a.split('x');
                        var partsB = b.split('x');
                        if (partsA.length === 2 && partsB.length === 2) {
                            var wA = parseInt(partsA[0]);
                            var hA = parseInt(partsA[1]);
                            var wB = parseInt(partsB[0]);
                            var hB = parseInt(partsB[1]);
                            if (wA !== wB) return wB - wA;
                            return hB - hA;
                        }
                        return b.localeCompare(a);
                    });

                    // Update resolution dropdown
                    for (var j = 0; j < group.children.length; ++j) {
                        var child = group.children[j];
                        if (child.id === "stillResolution") {
                            var resolutionOpts = [];
                            for (var k = 0; k < resolutions.length; k++) {
                                resolutionOpts.push({ "label1": resolutions[k] });
                            }
                            child.children_drop = resolutionOpts;

                            if (resolutionOpts.length > 0) {

                                var selectedResolution = resolutionOpts[0].label1; // default

                                // Check if currentResolution exists in the options
                                if (typeof currentResolution !== "undefined") {
                                    for (var m = 0; m < resolutionOpts.length; m++) {
                                        if (resolutionOpts[m].label1 === currentStillResn) {
                                            selectedResolution = currentStillResn;
                                            break;
                                        }
                                    }
                                }

                                child.selected = selectedResolution;

                                changedFields.push({
                                    id: "stillResolution",
                                    options: resolutionOpts,
                                    selected: child.selected
                                });

                                // Trigger resolution change to update FPS
                                var fpsUpdated = updateFpsForResolution(group, selectedValue, child.selected);
                                if (fpsUpdated) {
                                    changedFields.push(fpsUpdated);
                                }

                            }
                        }
                    }
                }
                break;
            }
        }
    }

    if (id === "stillResolution") {

        // Find video properties section and current format
        for (var i = 0; i < usbcamProperty.length; ++i) {
            var group = usbcamProperty[i];
            if (group.id === "stillCapture") {

                // Get current format
                var currentFormat = null;
                for (var j = 0; j < group.children.length; ++j) {
                    if (group.children[j].id === "stillFormat") {
                        currentFormat = group.children[j].selected;
                        break;
                    }
                }
                // Update FPS dropdown
                if (currentFormat) {
                    var fpsUpdated = updateFpsForResolution(group, currentFormat, selectedValue);
                    if (fpsUpdated) {
                        changedFields.push(fpsUpdated);
                    }
                }

                break;
            }
        }
    }

    // Handle Exposure Mode
    if (id === "exposureMode") {
        var newEnabledState = (selectedValue === "MANUAL");
        usbcamRect.setExposureMode(!newEnabledState)
        // Find exposure section
        for (var i = 0; i < usbcamProperty.length; ++i) {
            var group = usbcamProperty[i];
            if (group.id === "cameraSettings") {
                for (var j = 0; j < group.children.length; ++j) {
                    var section = group.children[j];
                    if (section.id === "exposure") {

                        // Loop inside "exposure" children
                        for (var k = 0; k < section.children.length; ++k) {
                            var child = section.children[k];

                            // --- Enable/disable exposureTime ---
                            if (child.id === "exposureTime") {
                                if (child.enabled !== newEnabledState) {
                                    child.enabled = newEnabledState;
                                    changedFields.push({
                                        id: "exposureTime",
                                        enabled: newEnabledState
                                    });
                                }
                            }

                            // --- Add more fields here as needed ---
                            if (child.id === "min_exposure_s" || child.id === "max_exposure_s" || child.id === "gain_s" || child.id === "antiFlicker") {
                                var shouldEnable = (selectedValue === "AUTO");
                                if (child.enabled !== shouldEnable) {
                                    child.enabled = shouldEnable;
                                    changedFields.push({
                                        id: child.id,
                                        enabled: shouldEnable
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
        if (selectedValue === "AUTO") {
            prevController.setCameraControlProperty(selectedIndex, id, 1)
        } else {
            prevController.setCameraControlProperty(selectedIndex, id, 0)
        }
        // Add to changed fields to update parent label
        changedFields.push({
            id: id,
            selected: selectedValue
        });
    }

     // Handle Exposure Mode
     if (id === "focusMode") {
        var newEnabledState = (selectedValue === "MANUAL");
        usbcamRect.setFocusMode(!newEnabledState)
        // Find exposure section
        for (var i = 0; i < usbcamProperty.length; ++i) {
            var group = usbcamProperty[i];
            if (group.id === "cameraSettings") {
                for (var j = 0; j < group.children.length; ++j) {
                    var section = group.children[j];
                    if (section.id === "focus") {

                        // Loop inside "exposure" children
                        for (var k = 0; k < section.children.length; ++k) {
                            var child = section.children[k];

                            // --- Enable/disable exposureTime ---
                            if (child.id === "focusValue") {
                                if (child.enabled !== newEnabledState) {
                                    child.enabled = newEnabledState;
                                    changedFields.push({
                                        id: "focusValue",
                                        enabled: newEnabledState
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
        if (selectedValue === "AUTO") {
            prevController.setCameraControlProperty(selectedIndex, id, 1)
        } else {
            prevController.setCameraControlProperty(selectedIndex, id, 0)
        }
        // Add to changed fields to update parent label
        changedFields.push({
            id: id,
            selected: selectedValue
        });
    }

    // Handle White Balance Mode
    if (id === "wbMode") {
        for (var i = 0; i < usbcamProperty.length; ++i) {
            var group = usbcamProperty[i];
            if (group.id === "cameraSettings") {
                for (var j = 0; j < group.children.length; ++j) {
                    var section = group.children[j];
                    if (section.id === "whiteBalance") {

                        // Loop inside "whiteBalance" children
                        for (var k = 0; k < section.children.length; ++k) {
                            var child = section.children[k];

                            // --- Enable/disable wbValue ---
                            if (child.id === "wbValue") {
                                var newEnabledState = (selectedValue === "MANUAL");
                                if (child.enabled !== newEnabledState) {
                                    child.enabled = newEnabledState;
                                    changedFields.push({
                                        id: child.id,
                                        enabled: newEnabledState,
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
        if (selectedValue === "AUTO") {
            prevController.setCameraControlProperty(selectedIndex, id, 1)
        } else {
            prevController.setCameraControlProperty(selectedIndex, id, 0)
        }
        // Add to changed fields to update parent label
        changedFields.push({
            id: id,
            selected: selectedValue
        });
    }
    return changedFields;  // Return what changed for targeted updates
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFpsForResolution(group, format, resolution)
//
//  PURPOSE		:	To fill the FPS dropdown of the given group with the frame
//					rates listed in imagePropertiesMap for the format and
//					resolution, keeping currentFps selected if available.
//
//	ARGUMENTS	:	group - video or still property group containing the "FPS"
//					  dropdown
//					format - selected pixel format
//					resolution - selected resolution, e.g. "1920x1080"
//
//	RETURN		:	Object - {id, options, selected} for the FPS dropdown, or null
//					if not updated
///////////////////////////////////////////////////////////////////////////
// Helper function to update FPS dropdown based on format and resolution
function updateFpsForResolution(group, format, resolution) {
    for (var j = 0; j < group.children.length; ++j) {
        var child = group.children[j];
        if (child.id === "FPS") {
           // var fpsData = imagePropertiesMap[format][resolution]; // array of fps values
            var fpsData = imagePropertiesMap[format][resolution].fps; // ← add .fps
            var fpsOpts = fpsData.map(function (f) {
                return { label1: String(f) };
            });

            child.children_drop = fpsOpts;

            if (fpsOpts.length > 0) {
                // Prefer currentFps if it exists in the list
                var selectedFps = fpsOpts[0].label1;
                if (typeof currentFps !== "undefined") {
                    for (var m = 0; m < fpsOpts.length; m++) {
                        if (fpsOpts[m].label1 === String(currentFps)) {
                            selectedFps = String(currentFps);
                            break;
                        }
                    }
                }
                child.selected = selectedFps;

                return {
                    id: "FPS",
                    options: fpsOpts,
                    selected: child.selected
                };
            }
        }
    }
    return null;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateProperty(id, min, max, current, step, automan, enabled)
//
//  PURPOSE		:	To update the camera settings model from a UVC control value
//					read from the camera: sets slider range/value, mode dropdowns
//					(white balance, exposure, focus, backlight, power line
//					frequency) and dependent slider enable states for the control
//					index.
//
//	ARGUMENTS	:	id - UVC control index (0-18)
//					min - minimum value
//					max - maximum value
//					current - current value
//					step - step size
//					automan - auto/manual flag (unused)
//					enabled - enabled flag (unused)
//
//	RETURN		:	Array - list of {id, ...} objects describing the model fields
//					that changed, for targeted UI updates
///////////////////////////////////////////////////////////////////////////
function updateProperty(id, min, max, current, step, automan, enabled) {
    var changedFields = [];

    // Camera-control replies can arrive before the asynchronous JSON model is
    // installed, or after selection has moved to a camera with a different
    // control schema. Never index into a hierarchy that does not exist.
    if (!hasChildren(usbcamProperty[0], 1)) return changedFields;
    var parentIndex = id;
    if (id == 7) parentIndex = 6;
    else if (id >= 8 && id <= 14) parentIndex = id - 1;
    else if (id == 15 || id == 16) parentIndex = 14;
    else if (id == 17 || id == 18) parentIndex = 15;
    var requiredChildren = (id == 6 || id == 7 || id == 15
        || id == 16 || id == 17 || id == 18) ? 2 : 1;
    if (parentIndex < 0
            || !hasChildren(usbcamProperty[0].children[parentIndex], requiredChildren)) {
        return changedFields;
    }

    ///////////////////////////////////////////////////////////////////////////
    //  FUNCTION	:	addChangedField(node)
    //
    //  PURPOSE		:	To append a change entry for the node (its id plus any defined
    //					min, max, step, currentValue, enabled, selected and options)
    //					to updateProperty()'s changedFields list.
    //
    //	ARGUMENTS	:	node - model node that was updated
    //
    //	RETURN		:	None
    ///////////////////////////////////////////////////////////////////////////
    function addChangedField(node) {
        if (!node) return;

        var change = { id: node.id };
        if (node.min !== undefined) change.min = node.min;
        if (node.max !== undefined) change.max = node.max;
        if (node.step !== undefined) change.step = node.step;
        if (node.currentValue !== undefined) change.currentValue = node.currentValue;
        if (node.enabled !== undefined) change.enabled = node.enabled;
        if (node.selected !== undefined) change.selected = node.selected;
        if (node.children_drop !== undefined) change.options = node.children_drop;
        changedFields.push(change);
    }

    if (id >= 0 && id <= 5){
        usbcamProperty[0].children[id].children[0].min = min;
        usbcamProperty[0].children[id].children[0].max = max;
        usbcamProperty[0].children[id].children[0].currentValue = current;
        usbcamProperty[0].children[id].children[0].step = step;
    }
    if (id == 6) {
        usbcamProperty[0].children[id].children[0].selected = (current == 1) ? "AUTO" : "MANUAL";
        if (current == 1) {
            isWbAuto = true
            usbcamProperty[0].children[id].children[1].enabled = false
        }
        usbcamProperty[0].children[id].children[0].currentValue = usbcamProperty[0].children[id].children[0].selected
    }
    if (id == 7) {
        usbcamProperty[0].children[id -1].children[1].min = min;
        usbcamProperty[0].children[id -1].children[1].max = max;
        usbcamProperty[0].children[id -1].children[1].currentValue = current;
        usbcamProperty[0].children[id -1].children[1].step = step;
        usbcamProperty[0].children[id -1].children[1].enabled = !isWbAuto

    } 
    if (id == 8) {
        usbcamProperty[0].children[id -1].children[0].selected = (current == 1) ? "ON" : "OFF";
        usbcamProperty[0].children[id - 1].children[0].currentValue = usbcamProperty[0].children[id -1].children[0].selected
    } 
    if (id == 9) {
        usbcamProperty[0].children[id -1].children[0].min = min;
        usbcamProperty[0].children[id - 1].children[0].max = max;
        usbcamProperty[0].children[id -1].children[0].currentValue = current;
        usbcamProperty[0].children[id -1].children[0].step = step;
    }
    if (id == 10 && isAntiFlickerHidAuto) {
        // Extension Settings anti-flicker is AUTO. UVC hardware always
        // reports a concrete value (0/1/2) for this control on Linux since
        // AUTO isn't mirrored into it, so ignore this poll rather than
        // clobbering the blank placeholder set by the HID flow.
    } else if (id == 10) {
        const validValues = [0, 1, 2];
		const powerLineNode = usbcamProperty[0].children[id - 1].children[0];
		if (powerLineNode.children_drop === undefined
				|| powerLineNode.children_drop === null) {
			powerLineNode.children_drop = [];
		}

        if (!validValues.includes(current)) {
            // Add empty label1 to children_drop if not already present
            const childrenDrop = powerLineNode.children_drop;

            // Check if empty label already exists to avoid duplicates
            const emptyExists = childrenDrop.some(item => item.label1 === " ");
            if (!emptyExists) {
                childrenDrop.unshift({ label1: " " }); 
            }
        } else {
            // Remove any previously-added empty option once the value is valid.
            const childrenDrop = powerLineNode.children_drop;
            for (let i = childrenDrop.length - 1; i >= 0; --i) {
                if (childrenDrop[i].label1 === " ") {
                    childrenDrop.splice(i, 1);
                }
            }
        }

        powerLineNode.selected =
            (current == 0) ? "DISABLE" :
                (current == 1) ? "50 Hz" :
                    (current == 2) ? "60 Hz" : " ";

        powerLineNode.currentValue = powerLineNode.selected;
    }
    if (id >= 11 && id <= 14) {
        usbcamProperty[0].children[id - 1].children[0].min = min;
        usbcamProperty[0].children[id - 1].children[0].max = max;
        usbcamProperty[0].children[id - 1].children[0].currentValue = current;
        usbcamProperty[0].children[id - 1].children[0].step = step;
    }
    if (id == 15) {
        usbcamProperty[0].children[id -1].children[0].selected = (current == 1) ? "AUTO" : "MANUAL";
        if (current == 1) {
            isExposureAuto = true
            usbcamProperty[0].children[id -1].children[1].enabled = false
        }
        usbcamRect.setExposureMode(isExposureAuto)
        usbcamProperty[0].children[id - 1].children[0].currentValue = usbcamProperty[0].children[id -1].children[0].selected
    }
    if (id == 16) {
        usbcamProperty[0].children[id -2].children[1].min = min;
        usbcamProperty[0].children[id -2].children[1].max = max;
        usbcamProperty[0].children[id -2].children[1].currentValue = current;
        usbcamProperty[0].children[id - 2].children[1].step = step;
        usbcamProperty[0].children[id -2].children[1].enabled = !isExposureAuto
    } 
    if (id == 17) {
        usbcamProperty[0].children[id - 2].children[0].selected = (current == 1) ? "AUTO" : "MANUAL";
        if (current == 1) {
            isFocusAuto = true
            usbcamProperty[0].children[id - 3].children[1].enabled = false
        }
        usbcamRect.setFocusMode(isFocusAuto)
        usbcamProperty[0].children[id - 2].children[0].currentValue = usbcamProperty[0].children[id - 2].children[0].selected
    }
    if(id == 18){
        usbcamProperty[0].children[id -3].children[1].min = min;
        usbcamProperty[0].children[id -3].children[1].max = max;
        usbcamProperty[0].children[id -3].children[1].currentValue = current;
        usbcamProperty[0].children[id - 3].children[1].step = step;
        if (isFocusAuto) {
            usbcamProperty[0].children[id -3].children[1].enabled = false
        }
    }

    if (id >= 0 && id <= 5) {
        addChangedField(usbcamProperty[0].children[id].children[0]);
    } else if (id == 6) {
        addChangedField(usbcamProperty[0].children[id].children[0]);
        addChangedField(usbcamProperty[0].children[id].children[1]);
    } else if (id == 7) {
        addChangedField(usbcamProperty[0].children[id - 1].children[1]);
    } else if (id >= 8 && id <= 14) {
        addChangedField(usbcamProperty[0].children[id - 1].children[0]);
    } else if (id == 15 || id == 17) {
        var parentOffset = (id == 15) ? 1 : 2;
        addChangedField(usbcamProperty[0].children[id - parentOffset].children[0]);
        addChangedField(usbcamProperty[0].children[id - parentOffset].children[1]);
    } else if (id == 16) {
        addChangedField(usbcamProperty[0].children[id - 2].children[1]);
    } else if (id == 18) {
        addChangedField(usbcamProperty[0].children[id - 3].children[1]);
    }

    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateImagePropertiesMap(propertiesMap)
//
//  PURPOSE		:	To store the camera's format -> resolution -> fps map and fill
//					the format, resolution and FPS dropdowns of both video
//					properties and still capture, keeping existing selections when
//					still valid or falling back to the first option.
//
//	ARGUMENTS	:	propertiesMap - object keyed by format, each keyed by
//					  resolution with an fps list
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateImagePropertiesMap(propertiesMap) {
    if (!propertiesMap || !imagePropertyModelReady()) return

    // Store the map for later use
    imagePropertiesMap = propertiesMap

    // 1. Update format dropdown with all available formats
    var formatOpts = []
    var formats = Object.keys(propertiesMap)
	if (formats.length === 0) return
    for (var i = 0; i < formats.length; i++) {
        formatOpts.push({ "label1": formats[i] })
    }
    usbcamProperty[videoPropertyId].children[0].children_drop = formatOpts
    usbcamProperty[stillPropertyId].children[0].children_drop = formatOpts

    // 2. Get currently selected format (or use first format if none selected)
    var currentFormat = usbcamProperty[videoPropertyId].children[0].selected
    if (!currentFormat || !propertiesMap[currentFormat]) {
        currentFormat = formats[0]
        usbcamProperty[videoPropertyId].children[0].selected = currentFormat
        usbcamProperty[stillPropertyId].children[0].selected = currentFormat
    }

    // 3. Update resolution dropdown - resolutions are the KEYS (excluding 'profiles' and 'currentProfile')
    var resolutionOpts = []
    if (propertiesMap[currentFormat]) {
        var keys = Object.keys(propertiesMap[currentFormat])
        var resolutions = keys.filter(function (key) {
            return key !== "profiles" && key !== "currentProfile"
        })

        // Sort resolutions in descending order
        resolutions.sort(function (a, b) {
            var partsA = a.split('x')
            var partsB = b.split('x')
            if (partsA.length === 2 && partsB.length === 2) {
                var wA = parseInt(partsA[0])
                var hA = parseInt(partsA[1])
                var wB = parseInt(partsB[0])
                var hB = parseInt(partsB[1])
                if (wA !== wB) return wB - wA
                return hB - hA
            }
            return b.localeCompare(a)
        })

        for (var j = 0; j < resolutions.length; j++) {
            resolutionOpts.push({ "label1": resolutions[j] })
        }
    }
    usbcamProperty[videoPropertyId].children[1].children_drop = resolutionOpts
    usbcamProperty[stillPropertyId].children[1].children_drop = resolutionOpts

    // 4. Get currently selected resolution
    var currentResolution = usbcamProperty[videoPropertyId].children[1].selected
    if (!currentResolution || resolutionOpts.length === 0 ||
        !resolutionOpts.some(function (opt) { return opt.label1 === currentResolution })) {
        currentResolution = resolutionOpts.length > 0 ? resolutionOpts[0].label1 : ""
        usbcamProperty[videoPropertyId].children[1].selected = currentResolution
        usbcamProperty[stillPropertyId].children[1].selected = currentResolution
    }

    // 5. Update fps dropdown
    var fpsOpts = []
    if (propertiesMap[currentFormat] &&
        propertiesMap[currentFormat][currentResolution] &&
        propertiesMap[currentFormat][currentResolution].fps) {
        var fpsList = propertiesMap[currentFormat][currentResolution].fps
        for (var k = 0; k < fpsList.length; k++) {
            fpsOpts.push({ "label1": fpsList[k] })
        }
    }
    usbcamProperty[videoPropertyId].children[2].children_drop = fpsOpts
    usbcamProperty[stillPropertyId].children[2].children_drop = fpsOpts

    // 6. Update selected fps
    var currentFps = usbcamProperty[videoPropertyId].children[2].selected
    if (!currentFps || fpsOpts.length === 0 ||
        !fpsOpts.some(function (opt) { return opt.label1 === currentFps })) {
        currentFps = fpsOpts.length > 0 ? fpsOpts[0].label1 : ""
        usbcamProperty[videoPropertyId].children[2].selected = currentFps
        usbcamProperty[stillPropertyId].children[2].selected = currentFps
    }

}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	onFormatChanged(newFormat)
//
//  PURPOSE		:	To repopulate the video resolution dropdown (sorted largest
//					first) for a newly selected format, select the first
//					resolution and update the FPS list via onResolutionChanged().
//
//	ARGUMENTS	:	newFormat - newly selected pixel format
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// Helper function when format changes
function onFormatChanged(newFormat) {
    if (!imagePropertiesMap || !imagePropertiesMap[newFormat]
            || !imagePropertyModelReady()) return

    // Get resolutions (exclude profiles and currentProfile keys)
    var keys = Object.keys(imagePropertiesMap[newFormat])
    var resolutions = keys.filter(function (key) {
        return key !== "profiles" && key !== "currentProfile"
    })

    // Sort resolutions in descending order
    resolutions.sort(function (a, b) {
        var partsA = a.split('x')
        var partsB = b.split('x')
        if (partsA.length === 2 && partsB.length === 2) {
            var wA = parseInt(partsA[0])
            var hA = parseInt(partsA[1])
            var wB = parseInt(partsB[0])
            var hB = parseInt(partsB[1])
            if (wA !== wB) return wB - wA
            return hB - hA
        }
        return b.localeCompare(a)
    })

    var resolutionOpts = []
    for (var i = 0; i < resolutions.length; i++) {
        resolutionOpts.push({ "label1": resolutions[i] })
    }
    usbcamProperty[videoPropertyId].children[1].children_drop = resolutionOpts

    // Set first resolution as default
    if (resolutionOpts.length > 0) {
        var newResolution = resolutionOpts[0].label1
        usbcamProperty[videoPropertyId].children[1].selected = newResolution
        onResolutionChanged(newFormat, newResolution)
    }

    // Update profiles for the new format
    var profileOpts = []
    if (imagePropertiesMap[newFormat].profiles) {
        var profiles = imagePropertiesMap[newFormat].profiles
        for (var p = 0; p < profiles.length; p++) {
            profileOpts.push({ "label1": profiles[p] })
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	onResolutionChanged(format, newResolution)
//
//  PURPOSE		:	To repopulate the video FPS dropdown with the frame rates for
//					the format and resolution and select the first one.
//
//	ARGUMENTS	:	format - selected pixel format
//					newResolution - newly selected resolution
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// Helper function when resolution changes
function onResolutionChanged(format, newResolution) {
    if (!imagePropertiesMap || !imagePropertiesMap[format] ||
        !imagePropertiesMap[format][newResolution]
        || !imagePropertyModelReady()) return

    // Get fps list
    var fpsList = imagePropertiesMap[format][newResolution].fps || []

    var fpsOpts = []
    for (var i = 0; i < fpsList.length; i++) {
        fpsOpts.push({ "label1": fpsList[i] })
    }
    usbcamProperty[videoPropertyId].children[2].children_drop = fpsOpts

    // Set first fps as default
    if (fpsOpts.length > 0) {
        usbcamProperty[videoPropertyId].children[2].selected = fpsOpts[0].label1
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCurrentImageProperty(format, resolution, fps)
//
//  PURPOSE		:	To record the format, resolution and FPS currently streaming
//					and select them in the video properties dropdowns; on the
//					first call also seeds the still capture values and dropdowns.
//
//	ARGUMENTS	:	format - current pixel format
//					resolution - current resolution
//					fps - current frame rate
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCurrentImageProperty(format, resolution, fps) {
    currentFormat = format
    currentResolution = resolution
    currentFps = fps
    if (!readStillProperty) {
        currentStillFmt = format
        currentStillResn = resolution
        currentStillFps = fps
    }

	// The controller may emit this while the Loader is switching between
	// cameras. The next property poll will populate the newly loaded model.
	if (!imagePropertyModelReady()) return

    // Set the selected format
    if (format) {
        usbcamProperty[videoPropertyId].children[0].selected = format
        if (!readStillProperty) {
            usbcamProperty[stillPropertyId].children[0].selected = format
        }
    }

    // Update resolutions for the selected format
    if (imagePropertiesMap && imagePropertiesMap[format]) {
        var keys = Object.keys(imagePropertiesMap[format])
        var resolutions = keys.filter(function (key) {
            return key !== "profiles" && key !== "currentProfile"
        })

        // Sort resolutions in descending order
        resolutions.sort(function (a, b) {
            var partsA = a.split('x')
            var partsB = b.split('x')
            if (partsA.length === 2 && partsB.length === 2) {
                var wA = parseInt(partsA[0])
                var hA = parseInt(partsA[1])
                var wB = parseInt(partsB[0])
                var hB = parseInt(partsB[1])
                if (wA !== wB) return wB - wA
                return hB - hA
            }
            return b.localeCompare(a)
        })

        var resolutionOpts = []
        for (var i = 0; i < resolutions.length; i++) {
            resolutionOpts.push({ "label1": resolutions[i] })
        }
        usbcamProperty[videoPropertyId].children[1].children_drop = resolutionOpts
        if (!readStillProperty) {
            usbcamProperty[stillPropertyId].children[1].children_drop = resolutionOpts
        }
    }

    // Set the selected resolution
    if (resolution) {
        usbcamProperty[videoPropertyId].children[1].selected = resolution
        if (!readStillProperty) {
            usbcamProperty[stillPropertyId].children[1].selected = resolution
        }
    }

    // Update fps for the selected format and resolution
    if (imagePropertiesMap && imagePropertiesMap[format] &&
        imagePropertiesMap[format][resolution] &&
        imagePropertiesMap[format][resolution].fps) {
        var fpsList = imagePropertiesMap[format][resolution].fps

        var fpsOpts = []
        for (var i = 0; i < fpsList.length; i++) {
            fpsOpts.push({ "label1": fpsList[i] })
        }
        usbcamProperty[videoPropertyId].children[2].children_drop = fpsOpts
    }

    // Set the selected fps
    if (fps) {
        usbcamProperty[videoPropertyId].children[2].selected = fps
    }

    if (!readStillProperty) {
        readStillProperty = true;
    }

}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setCurrentImageProperty()
//
//  PURPOSE		:	To read the selected video format, resolution and FPS from the
//					model and, if they differ from the current ones, apply them
//					via prevController.setCurrentImageProperty().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - always empty (kept for the common changedFields
//					interface)
///////////////////////////////////////////////////////////////////////////
function setCurrentImageProperty() {
    var changedFields = [];
    const vidPropertyConfig = usbcamProperty.find(item => item.id === "vidProperties");
    if (!vidPropertyConfig || !vidPropertyConfig.children) {
        console.error("Video Properties not found!");
        return changedFields;
    }

    let selectedFormat = null;
    let selectedResolution = null;
    let selectedFPS = null;

    for (let child of vidPropertyConfig.children) {
        // Check dropdowns
        if (child.value === "dropBox" && child.children_drop && child.children_drop.length > 0) {

            let selectedLabel = child.selected

            switch (child.id) {
                case "format":
                    selectedFormat = selectedLabel;
                    break;
                case "resolution":
                    selectedResolution = selectedLabel;
                    break;
                case "FPS":
                    selectedFPS = selectedLabel;
                    break;
            }
        }
    }

    // Send all values to your Prev controller
    if (selectedFormat && selectedResolution && selectedFPS) {
        if (currentFormat == selectedFormat && currentResolution == selectedResolution && currentFps == selectedFPS ) {
            return changedFields;
        } else {

            // Update current values
            currentFormat = selectedFormat;
            currentResolution = selectedResolution;
            currentFps = selectedFPS;
            
            prevController.setCurrentImageProperty(
                selectedIndex,
                selectedFormat,
                selectedResolution,
                selectedFPS
            );

        }

    } else {
        console.warn("Incomplete video property selections — not sending ONVIF request.");
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setCurrentStillProperty()
//
//  PURPOSE		:	To read the selected still format, resolution, FPS and file
//					format, replace an FPS unsupported by the resolution with the
//					first valid one, and apply them via
//					prevController.setCurrentStillProperty() if anything changed.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - always empty (kept for the common changedFields
//					interface)
///////////////////////////////////////////////////////////////////////////
function setCurrentStillProperty() {
    var changedFields = [];

    const stillPropertyConfig =
        usbcamProperty.find(item => item.id === "stillCapture");

    if (!stillPropertyConfig || !stillPropertyConfig.children) {
        console.error("Still Properties not found!");
        return changedFields;
    }

    let selectedFormat = null;
    let selectedResolution = null;
    let selectedFPS = null;
    let selectedFileFmt = null;

    // Read selected values from UI
    for (let child of stillPropertyConfig.children) {

        if (child.value === "dropBox" &&
            child.children_drop &&
            child.children_drop.length > 0) {

            let selectedLabel = child.selected;

            switch (child.id) {

                case "stillFormat":
                    selectedFormat = selectedLabel;
                    break;

                case "stillResolution":
                    selectedResolution = selectedLabel;
                    break;

                case "stillFps":
                    selectedFPS = selectedLabel;
                    break;

                case "fileFormat":
                    selectedFileFmt =
                        selectedLabel !== undefined
                            ? selectedLabel
                            : "BMP";
                    break;
            }
        }
    }

    // Validate FPS for selected format + resolution
    if (imagePropertiesMap &&
        selectedFormat &&
        selectedResolution &&
        imagePropertiesMap[selectedFormat] &&
        imagePropertiesMap[selectedFormat][selectedResolution]) {

        let validFpsList =
            imagePropertiesMap[selectedFormat]
            [selectedResolution]
                .fps || [];

        // If current selected FPS is invalid,
        // choose first supported FPS
        if (validFpsList.indexOf(selectedFPS) === -1) {

            selectedFPS =
                validFpsList.length > 0
                    ? validFpsList[0]
                    : null;

            // Update dropdown selection in UI
            usbcamProperty[stillPropertyId]
                .children[2]
                .selected = selectedFPS;

            console.log(
                "Invalid FPS detected. Updated FPS:",
                selectedFPS
            );
        }
    }

    // Send values
    if (selectedFormat &&
        selectedResolution &&
        selectedFPS &&
        selectedFileFmt) {

        // No change check
        if (currentStillFmt === selectedFormat &&
            currentStillResn === selectedResolution &&
            currentStillFps === selectedFPS &&
            currentFileFmt === selectedFileFmt) {

            logController.displayMessage(
                verboseLogPriority,
                "Still properties update selected but no changes detected.\n"
            );

            return changedFields;
        }

        // Update current values
        currentStillFmt = selectedFormat;
        currentStillResn = selectedResolution;
        currentStillFps = selectedFPS;
        currentFileFmt = selectedFileFmt;

        prevController.setCurrentStillProperty(
            selectedIndex,
            selectedFormat,
            selectedResolution,
            selectedFPS,
            selectedFileFmt
        );

    } else {
        console.warn("Incomplete still property selections.");
    }

    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	buildCameraIndex(cameraNode)
//
//  PURPOSE		:	To recursively add the node and all its descendants to the
//					cameraUiIndex id -> node map.
//
//	ARGUMENTS	:	cameraNode - model node to index
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function buildCameraIndex(cameraNode) {
    if (!cameraNode || typeof cameraNode !== "object")
        return;

    if (cameraNode.id)
        cameraUiIndex[cameraNode.id] = cameraNode;

    if (cameraNode.children) {
        cameraNode.children.forEach(buildCameraIndex);
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	findCameraSettingsRoot()
//
//  PURPOSE		:	To find the "cameraSettings" group in the usbcamProperty
//					model.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Object - the cameraSettings node, or null if not found
///////////////////////////////////////////////////////////////////////////
/* 🔹 Find cameraSettings root */
function findCameraSettingsRoot() {
    if (!Array.isArray(usbcamProperty))
        return null;

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (usbcamProperty[i].id === "cameraSettings")
            return usbcamProperty[i];
    }
    return null;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	buildCameraUiIndex(node)
//
//  PURPOSE		:	To recursively add the node and its descendants to the
//					cameraUiIndex id -> node map, defaulting missing slider values
//					to min (or 0) and checkbox values to false.
//
//	ARGUMENTS	:	node - model node to index
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
/* Build id → node map */
function buildCameraUiIndex(node) {
    if (!node || typeof node !== "object")
        return;

    if (node.id) {
        if (node.value === "slider" && node.currentValue === undefined) {
            node.currentValue = (node.min !== null && node.min !== undefined)
                ? node.min
                : 0;
        }

        if (node.value === "checkbox" && node.currentValue === undefined)
            node.currentValue = false;

        cameraUiIndex[node.id] = node;
    }

    if (node.children)
        node.children.forEach(buildCameraUiIndex);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	initCameraUiIndex()
//
//  PURPOSE		:	To locate the cameraSettings group and rebuild cameraUiIndex
//					from it.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
/* 🔹 Initialize */
function initCameraUiIndex() {
    cameraSettingsNode = findCameraSettingsRoot();

    if (!cameraSettingsNode) {
        console.error("cameraSettings node not found");
        return;
    }

    cameraUiIndex = {};
    buildCameraUiIndex(cameraSettingsNode);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setUiDefaultValues(values)
//
//  PURPOSE		:	To apply a set of default values (e.g. after loading defaults)
//					to the camera settings model: updates sliders, checkboxes and
//					dropdowns by id, mirrors gain/anti-flicker to usbcamRect, and
//					applies exposure, focus and white balance mode rules.
//
//	ARGUMENTS	:	values - object mapping control id to its new value
//
//	RETURN		:	Array - list of {id, ...} objects describing the model fields
//					that changed, for targeted UI updates
///////////////////////////////////////////////////////////////////////////
function setUiDefaultValues(values) {
    initCameraUiIndex();
    var changedFields = [];

    if (!values || !cameraSettingsNode)
        return changedFields;

    Object.keys(values).forEach(function (id) {

        var node = cameraUiIndex[id];
        if (!node)
            return;

        var newValue = values[id];
        var changed = { id: id };

        /* ---------- SLIDER ---------- */
        if (node.value === "slider") {
            if (node.currentValue !== newValue) {
                node.currentValue = newValue;
                changed.value = newValue;
                changed.currentValue = newValue;
                if (node.id == "gain_s") {
                    usbcamRect.setUvcGainValue(newValue)
                }
            }
        }

        /* ---------- CHECKBOX ---------- */
        else if (node.value === "checkbox") {
            var boolVal = (newValue === true || newValue === 1);
                node.currentValue = boolVal;
                changed.value = boolVal;
                changed.currentValue = boolVal;
        }

        /* ---------- DROPBOX ---------- */
        else if (node.value === "dropBox" && node.children_drop) {

            var selectedIndex = -1;
            if (id == "powerLineFreq_d") {
                if (newValue == "0") {
                    newValue = "DISABLE"
                } else if (newValue == "1") {
                    newValue = "50 Hz"
                } else if (newValue == "2") {
                    newValue = "60 Hz"
                }
                usbcamRect.setUvcAntiFlicker(newValue)
            }
            for (var i = 0; i < node.children_drop.length; i++) {
                if (node.children_drop[i].label1 === newValue) {
                    selectedIndex = i;
                    break;
                }
            }

            if (selectedIndex !== -1 && node.selected !== selectedIndex) {
                
                node.selected = selectedIndex;
                node.currentValue = newValue;

                changed.options = node.children_drop;
                changed.selected = newValue;
            }
        }

        /* ---------- EXPOSURE RULE ---------- */
        if (id === "exposureMode") {
            applyExposureRules(newValue , changedFields);
        }

        /* ---------- FOCUS RULE ---------- */
        if (id === "focusMode"){
            applyFocusRules(newValue, changedFields)
        }

        /* ---------- WHITE BALANCE RULE ---------- */
        if (id === "wbMode") {
            applyWhiteBalanceRules(newValue === "MANUAL", changedFields);
        }

        if (Object.keys(changed).length > 1)
            changedFields.push(changed);
    });
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	applyExposureRules(exposureMode, changedFields)
//
//  PURPOSE		:	To enable the exposure time slider in MANUAL mode and the
//					other exposure sliders in AUTO mode, and notify usbcamRect of
//					the exposure mode.
//
//	ARGUMENTS	:	exposureMode - "AUTO" or "MANUAL"
//					changedFields - array to which enable-state changes are
//					  appended
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function applyExposureRules(exposureMode, changedFields) {
    var exposureNode = cameraUiIndex["exposure"];
    if (!exposureNode || !exposureNode.children)
        return;

    var isManual = (exposureMode === "MANUAL");
    usbcamRect.setExposureMode(!isManual)

    exposureNode.children.forEach(function (child) {

        var shouldEnable;

        if (child.value === "slider") {
            if (child.id === "exposureTime") {
                shouldEnable = isManual;   // MANUAL → enable, AUTO → disable
            } else {
                shouldEnable = !isManual;  // MANUAL → disable, AUTO → enable
            }
        }
        else {
            return; // skip other types
        }

        if (child.enabled !== shouldEnable) {
            child.enabled = shouldEnable;

            changedFields.push({
                id: child.id,
                enabled: shouldEnable
            });
        }
    });
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	applyFocusRules(focusMode, changedFields)
//
//  PURPOSE		:	To enable the focus value slider in MANUAL mode and the other
//					focus sliders in AUTO mode, and notify usbcamRect of the focus
//					mode.
//
//	ARGUMENTS	:	focusMode - "AUTO" or "MANUAL"
//					changedFields - array to which enable-state changes are
//					  appended
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function applyFocusRules(focusMode, changedFields) {
    var focusNode = cameraUiIndex["focus"];
    if (!focusNode || !focusNode.children)
        return;

    var isManual = (focusMode === "MANUAL");
    usbcamRect.setFocusMode(!isManual)

    focusNode.children.forEach(function (child) {

        var shouldEnable;
        if (child.value === "slider") {
            if (child.id === "focusValue") {
                shouldEnable = isManual;   // MANUAL → enable, AUTO → disable
            } else {
                shouldEnable = !isManual;  // MANUAL → disable, AUTO → enable
            }
        }
        else {
            return; // skip other types
        }

        if (child.enabled !== shouldEnable) {
            child.enabled = shouldEnable;

            changedFields.push({
                id: child.id,
                enabled: shouldEnable
            });
        }
    });
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	applyWhiteBalanceRules(enable, changedFields)
//
//  PURPOSE		:	To enable or disable all sliders in the white balance group
//					(enabled in MANUAL mode).
//
//	ARGUMENTS	:	enable - true to enable the white balance sliders
//					changedFields - array to which enable-state changes are
//					  appended
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function applyWhiteBalanceRules(enable, changedFields) {

    var wbNode = cameraUiIndex["whiteBalance"];
    if (!wbNode || !wbNode.children)
        return;

    wbNode.children.forEach(function (child) {
        if (child.value === "slider") {
            if (child.enabled !== enable) {
                child.enabled = enable;
                changedFields.push({
                    id: child.id,
                    enabled: enable
                });
            }
        }
    });
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setHidGainValue(value)
//
//  PURPOSE		:	To update the UVC gain slider ("gain_s") in the model with a
//					gain value set through the HID extension controls.
//
//	ARGUMENTS	:	value - new gain value
//
//	RETURN		:	Array - [{id, currentValue}] if the slider was found, else
//					empty
///////////////////////////////////////////////////////////////////////////
function setHidGainValue(value) {
    var changedFields = [];

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (findAndUpdate(usbcamProperty[i], "gain_s", value, changedFields)) {
            break;
        }
    }

    return changedFields;
}

/*function setHidBrightnessValue(value) {
    var changedFields = [];

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (findAndUpdate(usbcamProperty[i], "brightness_s", value, changedFields)) {
            break;
        }
    }

    return changedFields;
}

function setHidContrastValue(value) {
    var changedFields = [];

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (findAndUpdate(usbcamProperty[i], "contrast_s", value, changedFields)) {
            break;
        }
    }

    return changedFields;
}

function setHidSaturationValue(value) {
    var changedFields = [];

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (findAndUpdate(usbcamProperty[i], "saturation", value, changedFields)) {
            break;
        }
    }

    return changedFields;
}

function setHidSharpnessValue(value) {
    var changedFields = [];

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (findAndUpdate(usbcamProperty[i], "sharpness_s", value, changedFields)) {
            break;
        }
    }

    return changedFields;
}

function setHidGammaValue(value) {
    var changedFields = [];

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (findAndUpdate(usbcamProperty[i], "gamma_s", value, changedFields)) {
            break;
        }
    }

    return changedFields;
}

function setHidExposureTimeValue(value) {
    var changedFields = [];

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (findAndUpdate(usbcamProperty[i], "exposureTime", value, changedFields)) {
            break;
        }
    }

    return changedFields;
}

function setHidWBValue(value) {
    var changedFields = [];

    for (var i = 0; i < usbcamProperty.length; i++) {
        if (findAndUpdate(usbcamProperty[i], "wbValue", value, changedFields)) {
            break;
        }
    }

    return changedFields;
}*/

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	findAndUpdate(node, targetId, value, changedFields)
//
//  PURPOSE		:	To recursively search the node tree for targetId, set its
//					currentValue and record the change.
//
//	ARGUMENTS	:	node - model node to search from
//					targetId - id of the entry to update
//					value - new value
//					changedFields - array to which {id, currentValue} is appended
//
//	RETURN		:	Boolean - true if the entry was found and updated
///////////////////////////////////////////////////////////////////////////
// Function to update and return changed fields
function findAndUpdate(node, targetId, value, changedFields) {
    if (!node) return false;

    if (node.id === targetId) {
        node.currentValue = value;

        changedFields.push({
            id: node.id,
            currentValue: value
        });

        return true;
    }

    if (node.children) {
        for (var i = 0; i < node.children.length; i++) {
            if (findAndUpdate(node.children[i], targetId, value, changedFields)) {
                return true;
            }
        }
    }

    return false;
}
