var routecamProperty = [];
var videoPropertyId = 1;
var exposureId = 4;
var whiteBalanceId = 5;
var hdrID = 6; 
var qualityControlId = 2
var qpId = 3
var networkInterfaceID = 3
var isExposureAuto = false
var isWbAuto = false
var isDHCP = false
var firmwareVersion = ""
let isCu86 = ""
var cameraSettingsNode = null;
var cameraUiIndex = {};
var currentResolution = ""
var currentFormat = ""
var currentFps = ""
var currentProfile = ""

// Declare the property at the top of the file
var imagePropertiesMap = {}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getFirmware15BitrateRange(format)
//
//  PURPOSE		:	To look up the bitrate range reported for a format (matching
//					aliases such as MJPG/MJPEG/JPEG or H265/HEVC) in
//					imagePropertiesMap. Applies only to cameras running firmware
//					15.0.x.
//
//	ARGUMENTS	:	format - video format name, e.g. "H264" or "MJPG"
//
//	RETURN		:	Object - {min, max} bitrate range, or null if not firmware
//					15.0.x, not found or invalid
///////////////////////////////////////////////////////////////////////////
function getFirmware15BitrateRange(format) {
    if (!firmwareVersion.startsWith("15.0.") || !format) {
        return null
    }

    var normalizedFormat = String(format).toUpperCase()
    var aliases = {
        "JPEG": ["JPEG", "MJPG", "MJPEG"],
        "MJPG": ["MJPG", "MJPEG", "JPEG"],
        "MJPEG": ["MJPEG", "MJPG", "JPEG"],
        "H265": ["H265", "HEVC"],
        "HEVC": ["HEVC", "H265"],
        "H264": ["H264"]
    }
    var formatNames = aliases[normalizedFormat] || [normalizedFormat]
    var formatProperties = null

    for (var i = 0; i < formatNames.length; ++i) {
        if (imagePropertiesMap[formatNames[i]] &&
            imagePropertiesMap[formatNames[i]].bitrateRange) {
            formatProperties = imagePropertiesMap[formatNames[i]]
            break
        }
    }

    if (!formatProperties || !formatProperties.bitrateRange) {
        return null
    }

    var min = Number(formatProperties.bitrateRange.min)
    var max = Number(formatProperties.bitrateRange.max)
    if (!isFinite(min) || !isFinite(max) || min > max) {
        return null
    }

    return { min: min, max: max }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBitrateRangeForFormat(format, useMaximumValue)
//
//  PURPOSE		:	To apply the firmware 15.0.x bitrate range for the format to
//					the "bitrate_s" slider in quality settings, clamping its
//					current value into range or setting it to the maximum.
//
//	ARGUMENTS	:	format - video format name
//					useMaximumValue - true to set the slider to the range maximum
//					  instead of clamping
//
//	RETURN		:	Object - {id, min, max, currentValue} for the slider, or null
//					if not applied
///////////////////////////////////////////////////////////////////////////
function updateBitrateRangeForFormat(format, useMaximumValue) {
    var range = getFirmware15BitrateRange(format)
    if (!range) return null

    var qualitySettings = routecamProperty.find(function (item) {
        return item.id === "qualitySettings"
    })
    if (!qualitySettings || !qualitySettings.children) return null

    var bitrateSection = qualitySettings.children.find(function (item) {
        return item.id === "bitRate"
    })
    if (!bitrateSection || !bitrateSection.children) return null

    var slider = bitrateSection.children.find(function (item) {
        return item.id === "bitrate_s"
    })
    if (!slider) return null

    slider.min = range.min
    slider.max = range.max

    var currentValue = Number(slider.currentValue)
    if (useMaximumValue || !isFinite(currentValue)) {
        currentValue = range.max
    } else {
        currentValue = Math.max(range.min, Math.min(range.max, currentValue))
    }
    slider.currentValue = currentValue

    return {
        id: "bitrate_s",
        min: range.min,
        max: range.max,
        currentValue: currentValue
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBitrateAfterVideoProperty(format, changedFields)
//
//  PURPOSE		:	To reset the bitrate after the video format changes: picks the
//					default bitrate for the format (depends on firmware 15.0.x),
//					updates the bitrate range if applicable, stores it in the
//					"bitrate_s" slider and sends it via
//					routecamOnvifController.setQualitySettings().
//
//	ARGUMENTS	:	format - newly applied video format
//					changedFields - array to which the bitrate slider change is
//					  appended
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateBitrateAfterVideoProperty(format, changedFields) {
    var normalizedFormat = String(format || "").toUpperCase()
    var newBitrate
    var rangeChange = null

    if (firmwareVersion.startsWith("15.0.")) {
        if (normalizedFormat === "MJPG" || normalizedFormat === "MJPEG" || normalizedFormat === "JPEG") {
            newBitrate = 40000000
        } else if (normalizedFormat === "H264" || normalizedFormat === "H265" || normalizedFormat === "HEVC") {
            newBitrate = 6291000
        }
        rangeChange = updateBitrateRangeForFormat(format, false)
    } else if (normalizedFormat === "H264") {
        newBitrate = 8000000
    } else if (normalizedFormat === "H265" || normalizedFormat === "HEVC") {
        newBitrate = 6291000
    }

    if (newBitrate === undefined) return

    var bitrateSlider = findChildById(
        routecamProperty.find(function (item) { return item.id === "qualitySettings" }),
        "bitrate_s"
    )
    if (!bitrateSlider) return

    bitrateSlider.currentValue = newBitrate
    routecamOnvifController.setQualitySettings(bitrateSlider.id, newBitrate)

    if (rangeChange) {
        rangeChange.currentValue = newBitrate
        changedFields.push(rangeChange)
    } else {
        changedFields.push({
            id: "bitrate_s",
            currentValue: newBitrate
        })
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To replace the Ethernet (RouteCAM ONVIF) property model
//					(routecamProperty) with the JSON array loaded for the selected
//					camera.
//
//	ARGUMENTS	:	jsonArray - array of property groups (camera, video, quality,
//					  network settings, device info)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    routecamProperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getRoutecamModelData()
//
//  PURPOSE		:	To return the current Ethernet camera property model used to
//					build the settings UI.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the routecamProperty model
///////////////////////////////////////////////////////////////////////////
function getRoutecamModelData() {
    return routecamProperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	isValidIP(ip)
//
//  PURPOSE		:	To check whether a string is a valid dotted-decimal IPv4
//					address (each octet 0-255).
//
//	ARGUMENTS	:	ip - string to validate
//
//	RETURN		:	Boolean - true if ip is a valid IPv4 address
///////////////////////////////////////////////////////////////////////////
function isValidIP(ip) {
    const regex = /^(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)){3}$/;
    return regex.test(ip);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDeviceInformation(deviceInfo)
//
//  PURPOSE		:	To fill the device info group (manufacturer, firmware version,
//					name) from the ONVIF device information, cache the firmware
//					version, update the bitrate range, and disable the RC type and
//					I-frame QP controls on CU86 (firmware 9.0.x).
//
//	ARGUMENTS	:	deviceInfo - object with manufacturer, firmwareVersion and
//					  name
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateDeviceInformation(deviceInfo) {
    var updatedChildren = [];

    for (var i = 0; i < routecamProperty.length; i++) {
        var item = routecamProperty[i];

        if (item.id === "deviceInfo") {
            var deviceInfoChildren = [];

            for (var j = 0; j < item.children.length; j++) {
                var child = item.children[j];

                if (child.id === "manufacturer") {
                    child.text = deviceInfo.manufacturer || "";
                }
                if (child.id === "firmwareVersion") {
                    child.text = deviceInfo.firmwareVersion || "";
                    firmwareVersion = deviceInfo.firmwareVersion
                    var selectedFormat = routecamProperty[videoPropertyId] &&
                        routecamProperty[videoPropertyId].children[0].selected
                    updateBitrateRangeForFormat(selectedFormat, false)
                    // true if version starts with "9.0."
                    isCu86 = firmwareVersion.startsWith("9.0.");
                    if (isCu86) {
                        // Disable rcType group
                        setFieldEnabled(routecamProperty, "rcType", false);
                        setFieldEnabled(routecamProperty, "rcType_d", false);
                        setFieldEnabled(routecamProperty, "updateRcType", false);

                        // Disable iFrameQp group
                        setFieldEnabled(routecamProperty, "iFrameQp", false);
                        setFieldEnabled(routecamProperty, "iFrameQP_s", false);
                    }


                }
                if (child.id === "name") {
                    child.text = deviceInfo.name || "";
                }

                deviceInfoChildren.push(child);
            }

            item.children = deviceInfoChildren;
        }

        updatedChildren.push(item);
    }

    routecamProperty = updatedChildren;
}


///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	disableControl(parent, index)
//
//  PURPOSE		:	To disable a control the camera does not support: for
//					"cameraSettings" or "qualitySettings" maps the control index
//					to a model id and sets that node's enabled to false; for
//					"vidProperties" or "networkSettings" disables the whole group.
//
//	ARGUMENTS	:	parent - group id: "cameraSettings", "qualitySettings",
//					  "vidProperties" or "networkSettings"
//					index - control index reported as unsupported
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function disableControl(parent, index) {
    if (parent == "cameraSettings") {
        const cameraSettingsMap = {
            0: "brightness",
            1: "c_saturation",
            2: "contrast",
            3: "sharpness",
            4: "exposureMode",
            5: "exposureTime",
            6: "antiFlicker",
            7: "max_exposure_s",
            8: "min_exposure_s",
            9: "gain_s",
            10: "wbMode",
            11: "bGain",
            12: "rGain",
            13: "hdrMode",
            14: "backlightCompensation"
        };

        const cameraSettings = routecamProperty.find(item => item.id === parent);
        if (!cameraSettings) return;

        const idToDisable = cameraSettingsMap[index];
        if (!idToDisable) {
            logController.displayMessage(verboseLogPriority, "UI: Invalid index or ID not mapped for Ethernet cameras\n");
            return;
        }

        const childToDisable = findChildById(cameraSettings, idToDisable);
        if (childToDisable) {
            childToDisable.enabled = false;
        } else {
            console.log(`Control with id ${idToDisable} not found`);
        }

    } else if (parent == "qualitySettings") {
        const qualitySettingsMap = {
            0: "gopSize",
            1: "rcType",
            2: "bitRate",
            3: "qp",
            4: "iFrameQp",
            5: "minQp",
            6: "maxQp"
        };

        const qualitySettings = routecamProperty.find(item => item.id === parent);
        if (!qualitySettings) return;

        const idToDisable = qualitySettingsMap[index];
        if (!idToDisable) {
            logController.displayMessage(verboseLogPriority, "UI: Invalid index or ID not mapped for qualitySettings\n");
            return;
        }

        const childToDisable = findChildById(qualitySettings, idToDisable);
        if (childToDisable) {
            childToDisable.enabled = false;
            console.log(`Disabled quality control: ${idToDisable}`);
        } else {
            console.log(`Quality control with id ${idToDisable} not found`);
        }

    } else if (parent == "vidProperties") {
        routecamProperty[1].enabled = false;
    } else if (parent == "networkSettings") {
        routecamProperty[3].enabled = false;
    }
}

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
// 🔍 Moved to outer scope so both branches can use it
function findChildById(node, id) {
    if (!node || !node.children) return null;
    for (let child of node.children) {
        if (child.id === id) return child;
        const found = findChildById(child, id);
        if (found) return found;
    }
    return null;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderVal(label, sliderId, newValue)
//
//  PURPOSE		:	To apply a slider change: camera settings sliders are
//					cross-checked (min/max exposure), stored and sent via
//					routecamOnvifController.setCameraControlProperty(); quality
//					sliders (GOP, bitrate, QP with min/max QP validation) are only
//					stored in the model until applied.
//
//	ARGUMENTS	:	label - slider label (unused)
//					sliderId - id of the slider, e.g. "min_exposure_s", "maxQp_s"
//					newValue - value chosen by the user
//
//	RETURN		:	Array - fields whose value was clamped, as {id, currentValue,
//					value}
///////////////////////////////////////////////////////////////////////////
function updateSliderVal(label, sliderId, newValue) {
    var changedFields = [];
    const camSettingConfig = routecamProperty.find(item => item.id === "cameraSettings");

    if (!camSettingConfig || !camSettingConfig.children) return changedFields;

    // Search through all parent fields
    for (let parentField of camSettingConfig.children) {
        if (parentField.children) {
            const slider = parentField.children.find(child => child.id === sliderId);
            if (slider) {

                // ── Exposure min/max cross-validation (BEFORE applying the value) ──
                if (sliderId === "min_exposure_s") {
                    const maxSlider = parentField.children.find(child => child.id === "max_exposure_s");
                    if (maxSlider && newValue < maxSlider.currentValue) {
                        setTextMessage("Minimum exposure value should be greater than or equal to maximum exposure value")
                        newValue = maxSlider.currentValue;
                        changedFields.push({
                            id: "min_exposure_s",
                            currentValue: newValue,
                            value: newValue
                        });
                    }
                }
                else if (sliderId === "max_exposure_s") {
                    const minSlider = parentField.children.find(child => child.id === "min_exposure_s");
                    if (minSlider && newValue > minSlider.currentValue) {
                        setTextMessage("Maximum exposure value should be lesser than or equal to minimum exposure value")
                        newValue = minSlider.currentValue;
                        changedFields.push({
                            id: "max_exposure_s",
                            currentValue: newValue,
                            value: newValue
                        });
                    }
                }
                // ─────────────────────────────────────────────────────────────────

                // Now apply the (possibly clamped) value
                if (slider.currentValue != newValue) {
                    slider.currentValue = newValue;
                    routecamOnvifController.setCameraControlProperty(sliderId, newValue);
                }

                return changedFields;
            }
        }
    }

    const qualitySettingConfig = routecamProperty.find(item => item.id === "qualitySettings");

    if (!qualitySettingConfig || !qualitySettingConfig.children)
        return changedFields;

    // Loop through all children (e.g., "Brightness", "Quality Parameters", etc.)
    for (let parentField of qualitySettingConfig.children) {

        // 🔹 Case 1: Direct child sliders (not nested inside qp)
        if (parentField.children) {
            const directSlider = parentField.children.find(child => child.id === sliderId);
            if (directSlider) {
                if (directSlider.currentValue !== newValue) {
                    directSlider.currentValue = newValue;
                }
                return changedFields;
            }
        }

        // 🔹 Case 2: Quality Parameters (nested under "qp")
        if (parentField.id === "qp" && parentField.children) {
            for (let qpChild of parentField.children) {
                if (qpChild.children) {
                    const slider = qpChild.children.find(child => child.id === sliderId);
                    if (slider) {

                        if (sliderId === "maxQp_s") {
                            // Search inside each qpChild's children to find minQp_s
                            let minSlider = null;
                            for (let sibling of parentField.children) {
                                if (sibling.children) {
                                    const found = sibling.children.find(child => child.id === "minQp_s");
                                    if (found) { minSlider = found; break; }
                                }
                            }
                            if (minSlider && newValue < minSlider.currentValue) {
                                setTextMessage("Maximum QP value should be greater than\n or equal to Minimum QP value");
                                newValue = minSlider.currentValue;
                                changedFields.push({
                                    id: "maxQp_s",
                                    currentValue: newValue,
                                    value: newValue
                                });
                            }
                        }
                        else if (sliderId === "minQp_s") {
                            //  Search inside each qpChild's children to find maxQp_s
                            let maxSlider = null;
                            for (let sibling of parentField.children) {
                                if (sibling.children) {
                                    const found = sibling.children.find(child => child.id === "maxQp_s");
                                    if (found) { maxSlider = found; break; }
                                }
                            }
                            if (maxSlider && newValue > maxSlider.currentValue) {
                                setTextMessage("Minimum QP value should be lesser than\n or equal to maximum QP value");
                                newValue = maxSlider.currentValue;
                                changedFields.push({
                                    id: "minQp_s",
                                    currentValue: newValue,
                                    value: newValue
                                });
                            }
                        }

                        if (slider.currentValue !== newValue) {
                            slider.currentValue = newValue;
                        }
                        return changedFields;
                    }
                }
            }
        }
    }

    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValChanged(label, id, selectedValue)
//
//  PURPOSE		:	To store a dropdown selection in the model and apply it: HDR
//					(also resets contrast/saturation), exposure and white balance
//					modes are sent via
//					routecamOnvifController.setCameraControlProperty();
//					format/resolution repopulate resolution, FPS and codec profile
//					lists; DHCP and RC type toggle dependent network/QP/bitrate
//					controls.
//
//	ARGUMENTS	:	label - dropdown label (unused)
//					id - dropdown id, e.g. "hdrMode_d", "format", "dhcpMode",
//					  "rcType_d"
//					selectedValue - text of the selected option
//
//	RETURN		:	Array - list of {id, ...} objects describing the model fields
//					that changed, for targeted UI updates
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValChanged(label, id, selectedValue) {

    var changedFields = [];  // Track what actually changed

    // --- Traverse the model and update matching dropdown ---
    for (var i = 0; i < routecamProperty.length; ++i) {
        var group = routecamProperty[i];
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

    if (id == "hdrMode_d") {
        if (selectedValue === "ON") {
            routecamOnvifController.setCameraControlProperty(id, 1)

            // When HDR is turned ON, set contrast to 32 and saturation to 128
            for (var i = 0; i < routecamProperty.length; ++i) {
                var group = routecamProperty[i];
                if (group.id === "cameraSettings") {
                    for (var j = 0; j < group.children.length; ++j) {
                        var section = group.children[j];

                        // Update contrast to 32
                        if (section.id === "contrast" && section.children && section.children.length > 0) {
                            var contrastSlider = section.children[0];
                            if (contrastSlider.id === "contrast_s") {
                                routecamOnvifController.setCameraControlProperty(contrastSlider.id, 32)
                                contrastSlider.currentValue = 32;
                                changedFields.push({
                                    id: "contrast_s",
                                    currentValue: 32,
                                    value: 32
                                });
                            }
                        }

                        if (firmwareVersion.startsWith("15.0.")){
                            // Update saturation to 75 for Routecam_Cu22
                            if (section.id === "c_saturation" && section.children && section.children.length > 0) {
                                var saturationSlider = section.children[0];
                                if (saturationSlider.id === "saturation") {
                                    routecamOnvifController.setCameraControlProperty(saturationSlider.id, 75)
                                    saturationSlider.currentValue = 75;
                                    changedFields.push({
                                        id: "saturation",
                                        currentValue: 75,
                                        value: 75
                                    });
                                }
                            }
                        } else {
                            // Update saturation to 128
                            if (section.id === "c_saturation" && section.children && section.children.length > 0) {
                                var saturationSlider = section.children[0];
                                if (saturationSlider.id === "saturation") {
                                    routecamOnvifController.setCameraControlProperty(saturationSlider.id, 128)
                                    saturationSlider.currentValue = 128;
                                    changedFields.push({
                                        id: "saturation",
                                        currentValue: 128,
                                        value: 128
                                    });
                                }
                            }
                        }

                    }
                }
            }
        } else {
            routecamOnvifController.setCameraControlProperty(id, 0)

            // When HDR is turned OFF, set contrast to 64 and saturation to 128
            for (var i = 0; i < routecamProperty.length; ++i) {
                var group = routecamProperty[i];
                if (group.id === "cameraSettings") {
                    for (var j = 0; j < group.children.length; ++j) {
                        var section = group.children[j];

                        // Update contrast to 64
                        if (section.id === "contrast" && section.children && section.children.length > 0) {
                            var contrastSlider = section.children[0];
                            if (contrastSlider.id === "contrast_s") {
                                routecamOnvifController.setCameraControlProperty(contrastSlider.id, 64)
                                contrastSlider.currentValue = 64;
                                changedFields.push({
                                    id: "contrast_s",
                                    currentValue: 64,
                                    value : 64
                                });
                            }
                        }
                        if (firmwareVersion.startsWith("15.0.")){
                            // Update saturation to 175
                            if (section.id === "c_saturation" && section.children && section.children.length > 0) {
                                var saturationSlider = section.children[0];
                                if (saturationSlider.id === "saturation") {
                                    routecamOnvifController.setCameraControlProperty(saturationSlider.id, 175)
                                    saturationSlider.currentValue = 175;
                                    changedFields.push({
                                        id: "saturation",
                                        currentValue: 175, 
                                        value: 175
                                    });
                                }
                            }
                        } else {
                            // Update saturation to 128
                            if (section.id === "c_saturation" && section.children && section.children.length > 0) {
                                var saturationSlider = section.children[0];
                                if (saturationSlider.id === "saturation") {
                                    routecamOnvifController.setCameraControlProperty(saturationSlider.id, 128)
                                    saturationSlider.currentValue = 128;
                                    changedFields.push({
                                        id: "saturation",
                                        currentValue: 128, 
                                        value: 128
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        // Add to changed fields to update parent label
        changedFields.push({
            id: id,
            selected: selectedValue
        });
    }

    // Handle Video Properties dropdowns
    if (id === "format") {

        // Find video properties section
        for (var i = 0; i < routecamProperty.length; ++i) {
            var group = routecamProperty[i];
            if (group.id === "vidProperties") {

                // Update resolution dropdown based on selected format
                if (imagePropertiesMap && imagePropertiesMap[selectedValue]) {
                    var keys = Object.keys(imagePropertiesMap[selectedValue]);
                    var resolutions = keys.filter(function (key) {
                        return key !== "profiles" && key !== "currentProfile" && key !== "bitrateRange";
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

                         if (child.id === "resolution") {
                              var resolutionOpts = [];
                              for (var k = 0; k < resolutions.length; k++) {
                                   resolutionOpts.push({ "label1": resolutions[k] });
                              }
                              child.children_drop = resolutionOpts;

                              if (resolutionOpts.length > 0) {
                                   // Keep the current resolution selected if it's still valid for the
                                   // new format; otherwise fall back to the first (highest) resolution
                                   var previousResolution = child.selected;
                                   var resolutionStillValid = resolutionOpts.some(function (opt) {
                                        return opt.label1 === previousResolution;
                                   });

                                   child.selected = resolutionStillValid ? previousResolution : resolutionOpts[0].label1;

                                   changedFields.push({
                                        id: "resolution",
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

                        // Update codec profile dropdown
                        if (child.id === "codecProfile") {
                            var profileOpts = [];
                            if (imagePropertiesMap[selectedValue] && imagePropertiesMap[selectedValue].profiles) {
                                var profiles = imagePropertiesMap[selectedValue].profiles;
                                for (var p = 0; p < profiles.length; p++) {
                                    profileOpts.push({ "label1": profiles[p] });
                                }
                            }
                            child.children_drop = profileOpts;

                            // Set current profile or first as selected
                            if (imagePropertiesMap[selectedValue]) {
                                var currentProfile = imagePropertiesMap[selectedValue].currentProfile;
                                var profiles = imagePropertiesMap[selectedValue].profiles || [];

                                if (currentProfile && profiles.includes(currentProfile)) {
                                    child.selected = currentProfile;
                                } else if (profileOpts.length > 0) {
                                    child.selected = profileOpts[0].label1;
                                }
                            }
                            if (selectedValue != "H264") {
                                changedFields.push({
                                    id: "codecProfile",
                                    options: profileOpts,
                                    selected: child.selected,
                                    enabled: false
                                });
                            } else {
                                changedFields.push({
                                    id: "codecProfile",
                                    options: profileOpts,
                                    selected: child.selected,
                                    enabled: true
                                });
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
        for (var i = 0; i < routecamProperty.length; ++i) {
            var group = routecamProperty[i];
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

    if (id === "codecProfile") {
        changedFields.push({
            id: "codecProfile",
            selected: selectedValue
        });
    }

    // Handle Exposure Mode
    if (id === "exposureMode") {
        // Find exposure section
        for (var i = 0; i < routecamProperty.length; ++i) {
            var group = routecamProperty[i];
            if (group.id === "cameraSettings") {
                for (var j = 0; j < group.children.length; ++j) {
                    var section = group.children[j];
                    if (section.id === "exposure") {

                        // Loop inside "exposure" children
                        for (var k = 0; k < section.children.length; ++k) {
                            var child = section.children[k];

                            // --- Enable/disable exposureTime ---
                            if (child.id === "exposureTime") {
                                var newEnabledState = (selectedValue === "MANUAL");
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
            routecamOnvifController.setCameraControlProperty(id, 1)
        } else {
            routecamOnvifController.setCameraControlProperty(id, 0)
        }
        // Add to changed fields to update parent label
        changedFields.push({
            id: id,
            selected: selectedValue
        });
    }

    // Handle White Balance Mode
    if (id === "wbMode") {
        for (var i = 0; i < routecamProperty.length; ++i) {
            var group = routecamProperty[i];
            if (group.id === "cameraSettings") {
                for (var j = 0; j < group.children.length; ++j) {
                    var section = group.children[j];
                    if (section.id === "whiteBalance") {

                        // Loop inside "whiteBalance" children
                        for (var k = 0; k < section.children.length; ++k) {
                            var child = section.children[k];

                            // --- Enable/disable bGain and rGain ---
                            if (child.id === "bGain" || child.id === "rGain") {
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
            routecamOnvifController.setCameraControlProperty(id, 1)
        } else {
            routecamOnvifController.setCameraControlProperty(id, 0)
        }
        // Add to changed fields to update parent label
        changedFields.push({
            id: id,
            selected: selectedValue
        });
    }

    // Handle DHCP Mode
    if (id === "dhcpMode") {
        for (var i = 0; i < routecamProperty.length; ++i) {
            var group = routecamProperty[i];
            if (group.id === "networkSettings") {

                // Loop inside "networkSettings" children
                for (var k = 0; k < group.children.length; ++k) {
                    var child = group.children[k];

                    // --- Enable/disable networkSettings ---
                    if (child.id === "ipAddress" || child.id === "subnetMask" || child.id === "gateway") {
                        var newEnabledState = (selectedValue === "OFF");
                        if (child.enabled !== newEnabledState) {
                            child.enabled = newEnabledState;
                            changedFields.push({
                                id: child.id,
                                enabled: newEnabledState
                            });
                        }
                    }
                }
            }
        }
    }

    if (id === "rcType_d") {

        let isVBR = (selectedValue === "VBR");
        let isCBR = (selectedValue === "CBR");

        for (var i = 0; i < routecamProperty.length; ++i) {
            var group = routecamProperty[i];
            if (group.id === "qualitySettings") {

                for (var j = 0; j < group.children.length; ++j) {
                    var section = group.children[j];

                    // ---- Bitrate (parent + child) ----
                    if (section.id === "bitRate") {

                        let parentEnable = isVBR;

                        if (section.enabled !== parentEnable) {
                            section.enabled = parentEnable;
                            changedFields.push({
                                id: "bitRate",
                                enabled: parentEnable
                            });
                        }

                        // child slider
                        for (var k = 0; k < section.children.length; ++k) {
                            var child = section.children[k];
                            if (child.id === "bitrate_s") {
                                if (child.enabled !== parentEnable) {
                                    child.enabled = parentEnable;
                                    changedFields.push({
                                        id: "bitrate_s",
                                        enabled: parentEnable,
                                        currentValue: child.currentValue
                                    });
                                }
                            }
                            else if (child.id === "updateBitrate") {
                                if (child.enabled !== parentEnable) {
                                    child.enabled = parentEnable;
                                    changedFields.push({
                                        id: "updateBitrate",
                                        enabled: parentEnable
                                    });
                                }
                            }
                        }
                    }

                    // ---- QP Settings ----
                    if (section.id === "qp") {

                        for (var k = 0; k < section.children.length; ++k) {
                            var qpParent = section.children[k];

                            if (!qpParent.children || qpParent.children.length === 0)
                                continue;

                            var slider = qpParent.children[0];

                            // I-Frame QP → enable only in CBR
                            if (qpParent.id === "iFrameQp") {
                                let enableState = isCBR;

                                if (qpParent.enabled !== enableState) {
                                    qpParent.enabled = enableState;
                                    changedFields.push({
                                        id: "iFrameQp",
                                        enabled: enableState
                                    });
                                }

                                if (slider.enabled !== enableState) {
                                    slider.enabled = enableState;
                                    changedFields.push({
                                        id: "iFrameQP_s",
                                        enabled: enableState
                                    });
                                }
                            }

                            // Min QP → enable only in VBR
                            if (qpParent.id === "minQp") {
                                let enableState = isVBR;

                                if (qpParent.enabled !== enableState) {
                                    qpParent.enabled = enableState;
                                    changedFields.push({
                                        id: "minQp",
                                        enabled: enableState
                                    });
                                }

                                if (slider.enabled !== enableState) {
                                    slider.enabled = enableState;
                                    changedFields.push({
                                        id: "minQp_s",
                                        enabled: enableState,
                                        value: slider.currentValue
                                    });
                                }
                            }

                            // Max QP → enable only in VBR
                            if (qpParent.id === "maxQp") {
                                let enableState = isVBR;

                                if (qpParent.enabled !== enableState) {
                                    qpParent.enabled = enableState;
                                    changedFields.push({
                                        id: "maxQp",
                                        enabled: enableState
                                    });
                                }

                                if (slider.enabled !== enableState) {
                                    slider.enabled = enableState;
                                    changedFields.push({
                                        id: "maxQp_s",
                                        enabled: enableState
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        changedFields.push({
            id: id,
            selected: selectedValue
        });
    }

    return changedFields;  // Return what changed for targeted updates
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFpsForResolution(videoPropertiesGroup, format, resolution)
//
//  PURPOSE		:	To fill the FPS dropdown with the frame rates listed in
//					imagePropertiesMap for the format and resolution, keeping the
//					previous FPS selected if it is still valid.
//
//	ARGUMENTS	:	videoPropertiesGroup - video properties group containing the
//					  "FPS" dropdown
//					format - selected video format
//					resolution - selected resolution, e.g. "1920x1080"
//
//	RETURN		:	Object - {id, options, selected} for the FPS dropdown, or null
//					if not updated
///////////////////////////////////////////////////////////////////////////
// Helper function to update FPS dropdown based on format and resolution
function updateFpsForResolution(videoPropertiesGroup, format, resolution) {
    if (!imagePropertiesMap || !imagePropertiesMap[format] ||
        !imagePropertiesMap[format][resolution]) {
        return null;
    }

    var fpsList = imagePropertiesMap[format][resolution].fps || [];

    // Find and update FPS dropdown
    for (var i = 0; i < videoPropertiesGroup.children.length; ++i) {
        var child = videoPropertiesGroup.children[i];

        if (child.id === "FPS") {
            var fpsOpts = [];
            for (var j = 0; j < fpsList.length; j++) {
                fpsOpts.push({ "label1": fpsList[j] });
            }
            child.children_drop = fpsOpts;

            if (fpsOpts.length > 0) {
                // Keep the current FPS selected if it's still valid for the
                // new format/resolution; otherwise fall back to the first entry
                var previousFps = child.selected;
                var fpsStillValid = fpsOpts.some(function (opt) {
                    return opt.label1 === previousFps;
                });

                child.selected = fpsStillValid ? previousFps : fpsOpts[0].label1;
            }

            return {
                id: "FPS",
                options: fpsOpts,
                selected: child.selected
            };
        }
    }

    return null;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateProperty(id, min, max, current, step, automan, enabled)
//
//  PURPOSE		:	To update the camera settings model from an ONVIF imaging
//					value read from the camera: slider ranges/values (brightness,
//					exposure, gains), exposure and white balance mode,
//					anti-flicker and HDR, plus dependent enable states.
//
//	ARGUMENTS	:	id - camera control index (0-13)
//					min - minimum value
//					max - maximum value
//					current - current value
//					step - step size
//					automan - auto/manual flag (unused)
//					enabled - enabled flag (unused)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateProperty(id, min, max, current, step, automan, enabled) {
    if (id >= 0 && id <= 3){
        routecamProperty[0].children[id].children[0].min = min;
        routecamProperty[0].children[id].children[0].max = max;
        routecamProperty[0].children[id].children[0].currentValue = current;
        routecamProperty[0].children[id].children[0].step = step;
    }
    if (id == 4) {
        routecamProperty[0].children[id].children[0].selected = (current == 1) ? "AUTO" : "MANUAL";
        if (current) {
            isExposureAuto = true
            routecamProperty[0].children[id].children[2].enabled = false
        }
        routecamProperty[0].children[id].children[0].currentValue = routecamProperty[0].children[id].children[0].selected
    }
    if(id == 5){
        routecamProperty[0].children[exposureId].children[2].min = min;
        routecamProperty[0].children[exposureId].children[2].max = max;
        routecamProperty[0].children[exposureId].children[2].currentValue = current;
        routecamProperty[0].children[exposureId].children[2].step = step;
        if (isExposureAuto) {
            routecamProperty[0].children[id].children[2].enabled = false
        }
    } 
    if (id == 6) {
        // Update the anti-flicker checkbox value
        const antiFlicker = routecamProperty[0].children[exposureId].children[1];
        antiFlicker.currentValue = current === 1; // Ensure it's a boolean
        if (!isExposureAuto) {
            routecamProperty[0].children[exposureId].children[1].enabled = false
        }
    }
    if(id >= 7 &&  id <= 9){
        routecamProperty[0].children[exposureId].children[id - 4].min = min;
        routecamProperty[0].children[exposureId].children[id -4].max = max;
        routecamProperty[0].children[exposureId].children[id -4].currentValue = current;
        routecamProperty[0].children[exposureId].children[id - 4].step = step;
        if (!isExposureAuto) {
            routecamProperty[0].children[exposureId].children[id - 4].enabled = false
        }
    }
    if (id == 10){
        routecamProperty[0].children[whiteBalanceId].children[0].selected = (current == 1) ? "AUTO" : "MANUAL";
        if (current) {
            isWbAuto = true
        }
        routecamProperty[0].children[whiteBalanceId].children[0].currentValue = routecamProperty[0].children[whiteBalanceId].children[0].selected
    }
    if (id == 11 || id == 12){
        routecamProperty[0].children[whiteBalanceId].children[id - 10].min = min;
        routecamProperty[0].children[whiteBalanceId].children[id - 10].max = max;
        routecamProperty[0].children[whiteBalanceId].children[id - 10].currentValue = current;
        routecamProperty[0].children[whiteBalanceId].children[id - 10].step = step;
        if (isWbAuto) {
            routecamProperty[0].children[whiteBalanceId].children[id - 10].enabled = false
        } else {
            routecamProperty[0].children[whiteBalanceId].children[id - 10].enabled = true
        }
        
    }
    if(id == 13){
        routecamProperty[0].children[hdrID].children[0].selected = (current == 1) ? "ON" : "OFF";
        routecamProperty[0].children[hdrID].children[0].currentValue  = routecamProperty[0].children[hdrID].children[0].selected 
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateQualityProperty(id, min, max, current)
//
//  PURPOSE		:	To update the quality settings model from values read from the
//					camera: GOP size and bitrate sliders (refreshing the bitrate
//					range), RC type VBR/CBR with dependent QP/bitrate enable
//					states, and the QP sliders.
//
//	ARGUMENTS	:	id - quality control index (0 = GOP, 1 = RC type, 2 = bitrate,
//					  3+ = QP)
//					min - minimum value
//					max - maximum value
//					current - current value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateQualityProperty(id, min, max, current) {
    if (id == 0 || id == 2) {
        routecamProperty[qualityControlId].children[id].children[0].min = min;
        routecamProperty[qualityControlId].children[id].children[0].max = max;
        routecamProperty[qualityControlId].children[id].children[0].currentValue = current;
        if (id == 2) {
            var selectedFormat = routecamProperty[videoPropertyId] &&
                routecamProperty[videoPropertyId].children[0].selected
            updateBitrateRangeForFormat(selectedFormat, false)
        }
    } else if (id == 1) {
        if (current == 1) {
            routecamProperty[qualityControlId].children[id].children[0].selected = "VBR";
            routecamProperty[qualityControlId].children[qpId].children[0].enabled = false;
            routecamProperty[qualityControlId].children[qpId].children[1].enabled = true;
            routecamProperty[qualityControlId].children[qpId].children[2].enabled = true;
            routecamProperty[qualityControlId].children[2].enabled = true;
        } else {
            routecamProperty[qualityControlId].children[id].children[0].selected = "CBR";
            routecamProperty[qualityControlId].children[qpId].children[0].enabled = true;
            routecamProperty[qualityControlId].children[qpId].children[1].enabled = false;
            routecamProperty[qualityControlId].children[qpId].children[2].enabled = false;
            routecamProperty[qualityControlId].children[2].enabled = false;
        }
        routecamProperty[qualityControlId].children[id].children[0].currentValue = routecamProperty[qualityControlId].children[id].children[0].selected 
    }else {
        routecamProperty[qualityControlId].children[qpId].children[id - 3].children[0].min = min;
        routecamProperty[qualityControlId].children[qpId].children[id - 3].children[0].max = max;
        routecamProperty[qualityControlId].children[qpId].children[id - 3].children[0].currentValue = current;
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateNetworkInterfaceDetails(dhcp, ipAddress, subnetMask, gateway)
//
//  PURPOSE		:	To show the camera's network settings in the model: sets the
//					DHCP dropdown, the IP/subnet/gateway text fields, and disables
//					those fields when DHCP is on.
//
//	ARGUMENTS	:	dhcp - true if DHCP is enabled
//					ipAddress - camera IP address
//					subnetMask - subnet mask
//					gateway - default gateway
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateNetworkInterfaceDetails(dhcp, ipAddress, subnetMask, gateway) {
    routecamProperty[networkInterfaceID].children[0].selected = (dhcp == false) ? "OFF" : "ON";
    if (dhcp) {
        isDHCP = true
        routecamProperty[networkInterfaceID].children[1].enabled = false
        routecamProperty[networkInterfaceID].children[2].enabled = false
        routecamProperty[networkInterfaceID].children[3].enabled = false
    }
    routecamProperty[networkInterfaceID].children[1].text = ipAddress
    routecamProperty[networkInterfaceID].children[2].text = subnetMask
    routecamProperty[networkInterfaceID].children[3].text = gateway
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateNtpIp(ntpIp)
//
//  PURPOSE		:	To show the camera's NTP server address in the network
//					settings NTP field.
//
//	ARGUMENTS	:	ntpIp - NTP server IP address
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateNtpIp(ntpIp) {
    routecamProperty[networkInterfaceID].children[5].text = ntpIp
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFormatList(formats)
//
//  PURPOSE		:	To fill the video format dropdown with the given format names.
//
//	ARGUMENTS	:	formats - array of format names
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateFormatList(formats) {
    var opts = []
    for (var i = 0; i < formats.length; ++i) {
        opts.push({ "label1": formats[i] })
    }
    routecamProperty[videoPropertyId].children[0].children_drop = opts
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateResolutionList(resolutions)
//
//  PURPOSE		:	To fill the video resolution dropdown with the given
//					resolutions.
//
//	ARGUMENTS	:	resolutions - array of resolution strings
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateResolutionList(resolutions) {
    var opts = []
    for (var i = 0; i < resolutions.length; ++i) {
        opts.push({ "label1": resolutions[i] })
    }
    routecamProperty[videoPropertyId].children[1].children_drop = opts
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFpsList(fpsList)
//
//  PURPOSE		:	To fill the video FPS dropdown with the given frame rates.
//
//	ARGUMENTS	:	fpsList - array of frame rates
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateFpsList(fpsList) {
    if (!fpsList) return
    var opts = []
    for (var i = 0; i < fpsList.length; ++i) {
        opts.push({ "label1": fpsList[i] })
    }
    routecamProperty[videoPropertyId].children[2].children_drop = opts
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateImagePropertiesMap(propertiesMap)
//
//  PURPOSE		:	To store the camera's format -> resolution -> fps map and fill
//					the format, resolution, FPS and codec profile dropdowns,
//					keeping existing selections when still valid, then refresh the
//					bitrate range for the format.
//
//	ARGUMENTS	:	propertiesMap - object keyed by format, each with resolutions
//					  (fps lists), profiles, currentProfile and bitrateRange
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateImagePropertiesMap(propertiesMap) {
    if (!propertiesMap) return

    // Store the map for later use
    imagePropertiesMap = propertiesMap

    // 1. Update format dropdown with all available formats
    var formatOpts = []
    var formats = Object.keys(propertiesMap)
    for (var i = 0; i < formats.length; i++) {
        formatOpts.push({ "label1": formats[i] })
    }
    routecamProperty[videoPropertyId].children[0].children_drop = formatOpts

    // 2. Get currently selected format (or use first format if none selected)
    var currentFormat = routecamProperty[videoPropertyId].children[0].selected
    if (!currentFormat || !propertiesMap[currentFormat]) {
        currentFormat = formats[0]
        routecamProperty[videoPropertyId].children[0].selected = currentFormat
    }

    // 3. Update resolution dropdown - resolutions are the KEYS (excluding format metadata)
    var resolutionOpts = []
    if (propertiesMap[currentFormat]) {
        var keys = Object.keys(propertiesMap[currentFormat])
        var resolutions = keys.filter(function (key) {
            return key !== "profiles" && key !== "currentProfile" && key !== "bitrateRange"
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
    routecamProperty[videoPropertyId].children[1].children_drop = resolutionOpts

    // 4. Get currently selected resolution
    var currentResolution = routecamProperty[videoPropertyId].children[1].selected
    if (!currentResolution || resolutionOpts.length === 0 ||
        !resolutionOpts.some(function (opt) { return opt.label1 === currentResolution })) {
        currentResolution = resolutionOpts.length > 0 ? resolutionOpts[0].label1 : ""
        routecamProperty[videoPropertyId].children[1].selected = currentResolution
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
    routecamProperty[videoPropertyId].children[2].children_drop = fpsOpts

    // 6. Update selected fps
    var currentFps = routecamProperty[videoPropertyId].children[2].selected
    if (!currentFps || fpsOpts.length === 0 ||
        !fpsOpts.some(function (opt) { return opt.label1 === currentFps })) {
        currentFps = fpsOpts.length > 0 ? fpsOpts[0].label1 : ""
        routecamProperty[videoPropertyId].children[2].selected = currentFps
    }

    // 7. Update profiles dropdown for the selected format
    var profileOpts = []
    if (propertiesMap[currentFormat] && propertiesMap[currentFormat].profiles) {
        var profiles = propertiesMap[currentFormat].profiles
        for (var p = 0; p < profiles.length; p++) {
            profileOpts.push({ "label1": profiles[p] })
        }
    }
    routecamProperty[videoPropertyId].children[3].children_drop = profileOpts

    // 8. Set current profile as selected
    if (propertiesMap[currentFormat] && propertiesMap[currentFormat].currentProfile) {
        routecamProperty[videoPropertyId].children[3].selected = propertiesMap[currentFormat].currentProfile
    } else if (profileOpts.length > 0) {
        routecamProperty[videoPropertyId].children[3].selected = profileOpts[0].label1
    }

    updateBitrateRangeForFormat(currentFormat, false)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	onFormatChanged(newFormat)
//
//  PURPOSE		:	To repopulate the resolution dropdown (sorted largest first)
//					for a newly selected format, select the first resolution,
//					update FPS via onResolutionChanged(), and refresh the codec
//					profile list and selection.
//
//	ARGUMENTS	:	newFormat - newly selected video format
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// Helper function when format changes
function onFormatChanged(newFormat) {
    if (!imagePropertiesMap || !imagePropertiesMap[newFormat]) return

    // Get resolutions (exclude format metadata)
    var keys = Object.keys(imagePropertiesMap[newFormat])
    var resolutions = keys.filter(function (key) {
        return key !== "profiles" && key !== "currentProfile" && key !== "bitrateRange"
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
    routecamProperty[videoPropertyId].children[1].children_drop = resolutionOpts

    // Set first resolution as default
    if (resolutionOpts.length > 0) {
        var newResolution = resolutionOpts[0].label1
        routecamProperty[videoPropertyId].children[1].selected = newResolution
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
    routecamProperty[videoPropertyId].children[3].children_drop = profileOpts

    // Set current profile or first profile as default
    if (imagePropertiesMap[newFormat].currentProfile) {
        routecamProperty[videoPropertyId].children[3].selected = imagePropertiesMap[newFormat].currentProfile
    } else if (profileOpts.length > 0) {
        routecamProperty[videoPropertyId].children[3].selected = profileOpts[0].label1
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	onResolutionChanged(format, newResolution)
//
//  PURPOSE		:	To repopulate the FPS dropdown with the frame rates for the
//					format and resolution and select the first one.
//
//	ARGUMENTS	:	format - selected video format
//					newResolution - newly selected resolution
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// Helper function when resolution changes
function onResolutionChanged(format, newResolution) {
    if (!imagePropertiesMap || !imagePropertiesMap[format] ||
        !imagePropertiesMap[format][newResolution]) return

    // Get fps list
    var fpsList = imagePropertiesMap[format][newResolution].fps || []

    var fpsOpts = []
    for (var i = 0; i < fpsList.length; i++) {
        fpsOpts.push({ "label1": fpsList[i] })
    }
    routecamProperty[videoPropertyId].children[2].children_drop = fpsOpts

    // Set first fps as default
    if (fpsOpts.length > 0) {
        routecamProperty[videoPropertyId].children[2].selected = fpsOpts[0].label1
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCurrentImageProperty(format, resolution, fps)
//
//  PURPOSE		:	To record the format, resolution and FPS currently streaming
//					and select them in the video dropdowns, refresh the codec
//					profile list (enabled only for H264) and update the bitrate
//					range.
//
//	ARGUMENTS	:	format - current video format
//					resolution - current resolution
//					fps - current frame rate
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCurrentImageProperty(format, resolution, fps) {
    currentFormat = format
    currentResolution = resolution
    currentFps = fps

    // Set the selected format
    if (format) {
        routecamProperty[videoPropertyId].children[0].selected = format
    }

    // Update resolutions for the selected format
    if (imagePropertiesMap && imagePropertiesMap[format]) {
        var keys = Object.keys(imagePropertiesMap[format])
        var resolutions = keys.filter(function (key) {
            return key !== "profiles" && key !== "currentProfile" && key !== "bitrateRange"
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
        routecamProperty[videoPropertyId].children[1].children_drop = resolutionOpts
    }

    // Set the selected resolution
    if (resolution) {
        routecamProperty[videoPropertyId].children[1].selected = resolution
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
        routecamProperty[videoPropertyId].children[2].children_drop = fpsOpts
    }

    // Set the selected fps
    if (fps) {
        routecamProperty[videoPropertyId].children[2].selected = fps
    }

    // Update profiles for the selected format
    var profileOpts = []
    if (imagePropertiesMap[format] && imagePropertiesMap[format].profiles) {
        var profiles = imagePropertiesMap[format].profiles
        for (var p = 0; p < profiles.length; p++) {
            profileOpts.push({ "label1": profiles[p] })
        }
    }
    routecamProperty[videoPropertyId].children[3].children_drop = profileOpts

    // Set current profile
    if (imagePropertiesMap[format] && imagePropertiesMap[format].currentProfile) {
        routecamProperty[videoPropertyId].children[3].selected = imagePropertiesMap[format].currentProfile
        currentProfile = imagePropertiesMap[format].currentProfile
    } else if (profileOpts.length > 0) {
        routecamProperty[videoPropertyId].children[3].selected = profileOpts[0].label1
    }

    if( format !== "H264"){
        routecamProperty[videoPropertyId].children[3].enabled = false
    } else{
        routecamProperty[videoPropertyId].children[3].enabled = true
    }

    updateBitrateRangeForFormat(format, false)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To send a checkbox change (e.g. anti-flicker) to the camera
//					via routecamOnvifController.setCameraControlProperty().
//
//	ARGUMENTS	:	id - checkbox id
//					checked - new checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked) {
    routecamOnvifController.setCameraControlProperty(id, checked)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(label, id, newText)
//
//  PURPOSE		:	To store text typed into a network settings text box in the
//					model (applied later by setNetworkSettings() or setNtp()).
//
//	ARGUMENTS	:	label - label of the text box
//					id - id of the text box
//					newText - text entered by the user
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(label, id, newText) {
    const networkConfig = routecamProperty.find(item => item.id === "networkSettings");
    if (!networkConfig) {
        return;
    }
    
    const field = networkConfig.children.find(f =>
        f.label === label && f.id === id && f.value === "textBox"
    );
    if (field) {
        field.text = newText;
        return;
     }
    
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setNtp()
//
//  PURPOSE		:	To validate the NTP field and send it to the camera via
//					routecamOnvifController.setNTP(), or show a message if the IP
//					is invalid.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setNtp() {
    const networkConfig = routecamProperty.find(item => item.id === "networkSettings");
    if (!networkConfig) {
        return;
    }
    const field = networkConfig.children.find(f =>
        f.id === "ntpField"
    );
    if (field) {
        if (isValidIP(field.text)) {
            routecamOnvifController.setNTP(field.text)
        } else {
            setTextMessage("Please enter valid NTP IP")
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setQParameters()
//
//  PURPOSE		:	To apply the RC type (VBR = 1, CBR = 0) and every QP slider
//					value to the camera via
//					routecamOnvifController.setQualitySettings().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setQParameters() {
    const qualitySettingConfig = routecamProperty.find(item => item.id === "qualitySettings");
    if (!qualitySettingConfig || !qualitySettingConfig.children) {
        console.error("Quality settings not found!");
        return;
    }

    for (let parentField of qualitySettingConfig.children) {
        if (parentField.id === "rcType" && parentField.children && parentField.children.length > 0) {

            const dropBox = parentField.children[0];

             // Example: send to ONVIF controller
            if (dropBox.currentValue == "VBR") {
                routecamOnvifController.setQualitySettings(dropBox.id, 1);
            } else if (dropBox.currentValue == "CBR") {
                routecamOnvifController.setQualitySettings(dropBox.id,  0);
            }

        }
    }
    for (let parentField of qualitySettingConfig.children) {
        if (parentField.id === "qp" && parentField.children) {

            for (let qpChild of parentField.children) {
                if (qpChild.children && qpChild.children.length > 0) {
                    const slider = qpChild.children[0];  

                    // Example: send to ONVIF controller
                    routecamOnvifController.setQualitySettings(slider.id, slider.currentValue);
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setCurrentImageProperty()
//
//  PURPOSE		:	To read the selected format, resolution, FPS and codec profile
//					and, if changed, apply them via
//					routecamOnvifController.setCurrentImageProperty(); on success
//					caches them and resets the bitrate when the format changed.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Object - {result, changedFields}: result is the controller
//					result (1 = success), 0 if nothing changed, -1 on missing data
///////////////////////////////////////////////////////////////////////////
function setCurrentImageProperty() {
    var changedFields = [];
    const vidPropertyConfig = routecamProperty.find(item => item.id === "vidProperties");
    if (!vidPropertyConfig || !vidPropertyConfig.children) {
        console.error("Video Properties not found!");
        return { result: -1, changedFields: changedFields };
    }

    let selectedFormat = null;
    let selectedResolution = null;
    let selectedFPS = null;
    let selectedProfile = null;

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
                case "codecProfile":
                    selectedProfile = selectedLabel;
                    break;
            }
        }
    }

    //  Now send all values to your ONVIF controller
    if (selectedFormat && selectedResolution && selectedFPS ) {
        // Example ONVIF call (you adapt this as per your backend API)
        if (currentFormat == selectedFormat && currentResolution == selectedResolution && currentFps == selectedFPS && currentProfile == selectedProfile) {
            return { result: 0, changedFields: changedFields };
        } else {
            // Track if format changed
            var formatChanged = (currentFormat != selectedFormat);

            var result = routecamOnvifController.setCurrentImageProperty(
                selectedFormat,
                selectedResolution,
                selectedFPS,
                selectedProfile
            );

            if (result === 1) {
                currentFormat = selectedFormat;
                currentResolution = selectedResolution;
                currentFps = selectedFPS;
                currentProfile = selectedProfile;
                if (formatChanged) {
                    updateBitrateAfterVideoProperty(selectedFormat, changedFields);
                }
            }

            return { result: result, changedFields: changedFields };
        }

    } else {
        console.warn("Incomplete video property selections — not sending ONVIF request.");
    }
    return { result: -1, changedFields: changedFields };
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	ipToInt(ip)
//
//  PURPOSE		:	To convert a dotted-decimal IPv4 address to an unsigned 32-bit
//					integer.
//
//	ARGUMENTS	:	ip - IPv4 address string
//
//	RETURN		:	Number - the address as an unsigned 32-bit integer
///////////////////////////////////////////////////////////////////////////
function ipToInt(ip) {
    var parts = ip.split('.').map(Number);
    return ((parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]) >>> 0;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	isSameSubnet(ip1, ip2, mask)
//
//  PURPOSE		:	To check whether two IPv4 addresses fall in the same subnet
//					under the given mask.
//
//	ARGUMENTS	:	ip1 - first IPv4 address
//					ip2 - second IPv4 address
//					mask - subnet mask
//
//	RETURN		:	Boolean - true if both addresses are in the same subnet
///////////////////////////////////////////////////////////////////////////
function isSameSubnet(ip1, ip2, mask) {
    var ip1Int = ipToInt(ip1);
    var ip2Int = ipToInt(ip2);
    var maskInt = ipToInt(mask);
    return (ip1Int & maskInt) === (ip2Int & maskInt);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setNetworkSettings()
//
//  PURPOSE		:	To apply the network settings: with DHCP ON sends only the
//					DHCP flag; otherwise validates IP, subnet mask and gateway
//					(valid, different, same subnet) and calls
//					routecamOnvifController.setNetworkInterfaceDetails(), showing
//					a message on errors.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setNetworkSettings() {
    const networkSettingsConfig = routecamProperty.find(item => item.id === "networkSettings");
    if (!networkSettingsConfig || !networkSettingsConfig.children) {
        console.error("networkSettingsConfig not found!");
        return;
    }

    let isDHCP = null;
    let networkIP = null;
    let subnetMask = null;
    let gateway = null;

    for (let child of networkSettingsConfig.children) {
        // Check dropdowns
        if (child.value === "dropBox" && child.children_drop && child.children_drop.length > 0) {

            let selectedLabel = child.selected

            switch (child.id) {
                case "dhcpMode":
                    isDHCP = selectedLabel;
                    break;
            }
        }

        if (child.value === "textBox") {
            let value = child.text
            switch (child.id) {
                case "ipAddress":
                    networkIP = value;
                    break;
                case "subnetMask":
                    subnetMask = value;
                    break;
                case "gateway":
                    gateway = value;
                    break;
            }
        }
       
    }

    if (!isDHCP) {
        setTextMessage("Please enter valid details")
        return
    }

    if (isDHCP === "ON") {
        routecamOnvifController.setNetworkInterfaceDetails(isDHCP, "", "", "")
        return
    }

    if (networkIP && subnetMask && gateway) {
        var isValidNetworkIP = isValidIP(networkIP);
        var isValidSubnetMask = isValidIP(subnetMask);
        var isValidGateway = isValidIP(gateway);

        if (isValidNetworkIP && isValidSubnetMask && isValidGateway) {
            if (networkIP != gateway) {
                if (isSameSubnet(networkIP, gateway, subnetMask)) {
                    routecamOnvifController.setNetworkInterfaceDetails(
                        isDHCP,
                        networkIP,
                        subnetMask,
                        gateway
                    );
                } else {
                    setTextMessage("Network IP and Gateway must be in the same subnet.");
                }
            } else {
                setTextMessage("Network and Gateway IP should be different.");
            }
        } else {
            if (!isValidNetworkIP) {
                setTextMessage("Please enter a valid Network IP Address");
            } else if (!isValidSubnetMask) {
                setTextMessage("Please enter a valid Subnet Mask");
            } else if (!isValidGateway) {
                setTextMessage("Please enter a valid Gateway IP Address");
            }
        }

    } else {
        setTextMessage("Please enter valid details")
    } 

}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setGopSize()
//
//  PURPOSE		:	To send the GOP size slider value to the camera via
//					routecamOnvifController.setQualitySettings().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setGopSize() {
    const qualitySettingConfig = routecamProperty.find(item => item.id === "qualitySettings");
    if (!qualitySettingConfig || !qualitySettingConfig.children) {
        console.error("Quality settings not found!");
        return;
    }

    for (let parentField of qualitySettingConfig.children) {

        // --- Handle GOP SIZE section ---
        if (parentField.id === "gopSize" && parentField.children) {
            const slider = parentField.children.find(child => child.id === "gopSize_s");
            if (slider) {
                // Send to ONVIF controller
                routecamOnvifController.setQualitySettings(slider.id, slider.currentValue);
            } else {
                console.warn("GOP slider not found!");
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setBitrate()
//
//  PURPOSE		:	To send the bitrate slider value to the camera via
//					routecamOnvifController.setQualitySettings().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setBitrate() {
    const qualitySettingConfig = routecamProperty.find(item => item.id === "qualitySettings");
    if (!qualitySettingConfig || !qualitySettingConfig.children) {
        console.error("Quality settings not found!");
        return;
    }

    for (let parentField of qualitySettingConfig.children) {
        if (parentField.id === "bitRate" && parentField.children) {
            const slider = parentField.children.find(child => child.id === "bitrate_s");
            if (slider) {
                routecamOnvifController.setQualitySettings(slider.id, slider.currentValue);
            } else {
                console.warn("Bitrate slider not found!");
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setFieldEnabled(routecamProperty, fieldId, enabled)
//
//  PURPOSE		:	To set the enabled state of every entry with fieldId among the
//					children and grandchildren of the model groups.
//
//	ARGUMENTS	:	routecamProperty - property model to search
//					fieldId - id of the field(s) to update
//					enabled - new enabled state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setFieldEnabled(routecamProperty, fieldId, enabled) {
    for (let i = 0; i < routecamProperty.length; i++) {
        let group = routecamProperty[i];
        if (!group.children) continue;

        for (let j = 0; j < group.children.length; j++) {
            let child = group.children[j];

            // Case 1: direct match
            if (child.id === fieldId) {
                child.enabled = enabled;
            }

            // Case 2: inner child match
            if (child.children) {
                for (let k = 0; k < child.children.length; k++) {
                    let inner = child.children[k];
                    if (inner.id === fieldId) {
                        inner.enabled = enabled;
                    }
                }
            }
        }
    }
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
//  PURPOSE		:	To find the "cameraSettings" group in the routecamProperty
//					model.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Object - the cameraSettings node, or null if not found
///////////////////////////////////////////////////////////////////////////
/* 🔹 Find cameraSettings root */
function findCameraSettingsRoot() {
    if (!Array.isArray(routecamProperty))
        return null;

    for (var i = 0; i < routecamProperty.length; i++) {
        if (routecamProperty[i].id === "cameraSettings")
            return routecamProperty[i];
    }
    return null;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	buildCameraUiIndex(node)
//
//  PURPOSE		:	To recursively add the node and its descendants to the
//					cameraUiIndex id -> node map.
//
//	ARGUMENTS	:	node - model node to index
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
/* 🔹 Build id → node map */
function buildCameraUiIndex(node) {
    if (!node || typeof node !== "object")
        return;

    if (node.id)
        cameraUiIndex[node.id] = node;

    if (node.children) {
        node.children.forEach(buildCameraUiIndex);
    }
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
//  PURPOSE		:	To apply a set of default values to the camera settings model:
//					updates sliders, checkboxes and dropdowns by id and applies
//					the exposure and white balance mode rules.
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
//					other exposure sliders and anti-flicker checkbox in AUTO mode.
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

    exposureNode.children.forEach(function (child) {

        var shouldEnable;

        if (child.value === "slider") {
            if (child.id === "exposureTime") {
                shouldEnable = isManual;   // MANUAL → enable, AUTO → disable
            } else {
                shouldEnable = !isManual;  // MANUAL → disable, AUTO → enable
            }
        }
        else if (child.value === "checkbox" && child.id === "antiFlicker") {
            shouldEnable = !isManual; // Always enabled
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
