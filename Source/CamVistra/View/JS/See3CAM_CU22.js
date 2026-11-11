var see3camcu22Hidroperty = [];

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To cache the JSON property model (HID accordion sections and
//					their child controls) loaded by UsbcamHidSettings.qml in
//					see3camcu22Hidroperty, so the other functions can read and
//					update it.
//
//	ARGUMENTS	:	jsonArray - Array of section objects parsed from the camera's
//					  JSON file
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3camcu22Hidroperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the cached JSON property model
//					(see3camcu22Hidroperty) so UsbcamHidSettings.qml can bind it
//					to the HID accordion.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current property model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return see3camcu22Hidroperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To empty the cached property model (see3camcu22Hidroperty)
//					when the device is closed or switched.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    see3camcu22Hidroperty = [];
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To start the QML delayedControlsTimer, whose handler calls
//					getDelayedCameraControls() so the See3CAM_CU22 HID values are
//					queried only after the UI is ready.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getCameraControls() {
    delayedControlsTimer.start();
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDelayedCameraControls()
//
//  PURPOSE		:	To request all HID control values from the See3CAM_CU22
//					(sensor mode, camera mode, special effects, AE ROI, flip,
//					color kill, burst length, anti-flicker, denoise and lens
//					shading correction). Results arrive via controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
    see3camcu22Controller.getSensorMode();
    see3camcu22Controller.getCameraMode();
    see3camcu22Controller.getSpecialEffects();
    see3camcu22Controller.getAutoExpROIMode();
    see3camcu22Controller.getFlipMode();
    see3camcu22Controller.getColorKillValue();
    see3camcu22Controller.getBurstLength();
    see3camcu22Controller.getAntiFlickerMode();
    see3camcu22Controller.getDenoiseMode();
    see3camcu22Controller.getLSCMode();
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSensorMode(value)
//
//  PURPOSE		:	To check the "sensorStandard" (0x01) or "sensorHdr" (0x03)
//					radio button according to the sensor mode read from the
//					camera.
//
//	ARGUMENTS	:	value - Sensor mode: 0x01 = standard, 0x03 = HDR
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateSensorMode(value) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "sensorMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "sensorStandard") {
                    child.checked = (value === 0x01);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "sensorHdr") {
                    child.checked = (value === 0x03);
                    changedFields.push({ id: child.id, checked: child.checked });
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCameraMode(value)
//
//  PURPOSE		:	To check the "masterMode" (0x01) or "triggerMode" (0x02) radio
//					button according to the camera mode read from the camera.
//
//	ARGUMENTS	:	value - Camera mode: 0x01 = master, 0x02 = trigger
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateCameraMode(value) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "cameraMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "masterMode") {
                    child.checked = (value === 0x01);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "triggerMode") {
                    child.checked = (value === 0x02);
                    changedFields.push({ id: child.id, checked: child.checked });
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSpecialEffects(value)
//
//  PURPOSE		:	To check the "normalEffect" (0x01) or "grayScale" (0x02) radio
//					button according to the effect read from the camera.
//
//	ARGUMENTS	:	value - Effect: 0x01 = normal, 0x02 = greyscale
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateSpecialEffects(value) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "specialEffect" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "normalEffect") {
                    child.checked = (value === 0x01);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "grayScale") {
                    child.checked = (value === 0x02);
                    changedFields.push({ id: child.id, checked: child.checked });
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlipMode(value)
//
//  PURPOSE		:	To set the "horizontal" and "vertical" flip check boxes from
//					the flip mode read from the camera.
//
//	ARGUMENTS	:	value - Flip mode: 0x02 = vertical, 0x03 = horizontal, 0x04 =
//					  both
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateFlipMode(value) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "flipControl" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "horizontal") {
                    child.checked = (value === 0x03 || value === 0x04);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "vertical") {
                    child.checked = (value === 0x02 || value === 0x04);
                    changedFields.push({ id: child.id, checked: child.checked });
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateROIAEMode(roiMode, winSize)
//
//  PURPOSE		:	To check the centered (0x01) or manual (0x02) AE ROI radio
//					button and select the window size in the "manualAE" drop box.
//
//	ARGUMENTS	:	roiMode - ROI mode: 0x01 = centered, 0x02 = manual
//					winSize - AE window size reported by the camera
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateROIAEMode(roiMode, winSize) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "roiAE" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "centeredROIAE") {
                    child.checked = (roiMode === 0x01);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "manualROIAE") {
                    child.checked = (roiMode === 0x02);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "manualAE") {
                    child.selected = winSize;
                    child.currentValue = winSize;
                    changedFields.push({ id: child.id, selected: child.selected });
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateColorKillValue(value)
//
//  PURPOSE		:	To set the "colorKillValue" slider in the "colorKill" section
//					to the color kill value read from the camera.
//
//	ARGUMENTS	:	value - Color kill value from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateColorKillValue(value) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "colorKill" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "colorKillValue") {
                    child.currentValue = value;
                    changedFields.push({ id: child.id, currentValue: child.currentValue });
                    break;
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBurstLength(burstLength)
//
//  PURPOSE		:	To select the burst length read from the camera in the
//					"burstLen" drop box of the "imageCapture" section.
//
//	ARGUMENTS	:	burstLength - Burst length (number of images per still
//					  capture)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateBurstLength(burstLength) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "imageCapture" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "burstLen") {
                    child.selected = burstLength;
                    child.currentValue = burstLength;
                    changedFields.push({ id: child.id, selected: child.selected });
                    break;
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDenoiseMode(value)
//
//  PURPOSE		:	To check the denoise enable (0x01) or disable (0x02) radio
//					button according to the mode read from the camera.
//
//	ARGUMENTS	:	value - Denoise mode: 0x01 = enable, 0x02 = disable
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateDenoiseMode(value) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "denoise" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "denosieEnable") {
                    child.checked = (value === 0x01);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "denoiseDisable") {
                    child.checked = (value === 0x02);
                    changedFields.push({ id: child.id, checked: child.checked });
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateLSCMode(value)
//
//  PURPOSE		:	To check the lens shading correction radio button (warm white
//					0x01, bright white 0x02, daylight 0x03) matching the mode read
//					from the camera.
//
//	ARGUMENTS	:	value - LSC mode: 0x01 warm white, 0x02 bright white, 0x03
//					  daylight
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateLSCMode(value) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "lensCorrection" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "lensCorrectionWarmWhite") {
                    child.checked = (value === 0x01);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "lensCorrectionBrightWhite") {
                    child.checked = (value === 0x02);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "lensCorrectionDaylight") {
                    child.checked = (value === 0x03);
                    changedFields.push({ id: child.id, checked: child.checked });
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAntiFlickerMode(value)
//
//  PURPOSE		:	To check the off (0x00), auto (0x01) or manual (0x02/0x03)
//					anti-flicker radio button and select "50 Hz" or "60 Hz" in the
//					frequency drop box for manual modes.
//
//	ARGUMENTS	:	value - Mode: 0x00 off, 0x01 auto, 0x02 50 Hz, 0x03 60 Hz
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateAntiFlickerMode(value) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "offMode") {
                    child.checked = (value === 0x00);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "autoMode") {
                    child.checked = (value === 0x01);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "manualMode") {
                    child.checked = (value === 0x02 || value === 0x03);
                    changedFields.push({ id: child.id, checked: child.checked });
                } else if (child.id === "frequency") {
                    child.selected = (value === 0x02) ? "50 Hz" : (value === 0x03 ? "60 Hz" : child.selected);
                    child.currentValue = child.selected;
                    changedFields.push({ id: child.id, selected: child.selected });
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSerialNumber(serialNum)
//
//  PURPOSE		:	To show the 64-bit serial number reported by the controller in
//					the "serialNumber" text field of the "serialNum" section of
//					see3camcu22Hidroperty.
//
//	ARGUMENTS	:	serialNum - Serial number string received from the controller
//					  signal
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateSerialNumber(serialNum) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "serialNum" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "serialNumber") {
                    child.text = serialNum;
                    changedFields.push({ id: child.id, text: child.text });
                    break;
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFirmwareVersioninUI(firmwareVer)
//
//  PURPOSE		:	To show the firmware version reported by the controller in the
//					"firmwareVer" text field of the "firmwareVersion" section.
//
//	ARGUMENTS	:	firmwareVer - Firmware version string from the controller
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function updateFirmwareVersioninUI(firmwareVer) {
    var changedFields = [];
    for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
        var group = see3camcu22Hidroperty[i];
        if (group.id === "firmwareVersion" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j];
                if (child.id === "firmwareVer") {
                    child.text = firmwareVer;
                    changedFields.push({ id: child.id, text: child.text });
                    break;
                }
            }
            break;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(groupId, id, checked)
//
//  PURPOSE		:	To send the command for the clicked radio button to
//					see3camcu22Controller based on its id (sensor mode, camera
//					mode, effect, AE ROI mode, denoise, LSC or anti-flicker). The
//					model is not updated here.
//
//	ARGUMENTS	:	groupId - Radio group name (unused)
//					id - JSON id of the clicked radio button
//					checked - New checked state (unused)
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(groupId, id, checked) {
    var changedFields = [];
    if (id === "sensorStandard") {
        see3camcu22Controller.setSensorMode(0x01);
    } else if (id === "sensorHdr") {
        see3camcu22Controller.setSensorMode(0x03);
    } else if (id === "masterMode") {
        see3camcu22Controller.setCameraMode(0x01);
    } else if (id === "triggerMode") {
        see3camcu22Controller.setCameraMode(0x02);
    } else if (id === "normalEffect") {
        see3camcu22Controller.setSpecialEffects(0x01);
    } else if (id === "grayScale") {
        see3camcu22Controller.setSpecialEffects(0x02);
    } else if (id === "centeredROIAE") {
        see3camcu22Controller.setAutoExpROIMode(0x01, 0, 0, 0, 0, 0);
    } else if (id === "manualROIAE") {
        see3camcu22Controller.setAutoExpROIMode(0x02, 0, 0, 0, 0, 0);
    } else if (id === "denosieEnable") {
        see3camcu22Controller.setDenoiseMode(0x01);
    } else if (id === "denoiseDisable") {
        see3camcu22Controller.setDenoiseMode(0x02);
    } else if (id === "lensCorrectionWarmWhite") {
        see3camcu22Controller.setLSCMode(0x01);
    } else if (id === "lensCorrectionBrightWhite") {
        see3camcu22Controller.setLSCMode(0x02);
    } else if (id === "lensCorrectionDaylight") {
        see3camcu22Controller.setLSCMode(0x03);
    } else if (id === "offMode") {
        see3camcu22Controller.setAntiFlickerMode(0x00);
    } else if (id === "autoMode") {
        see3camcu22Controller.setAntiFlickerMode(0x01);
    } else if (id === "manualMode") {
        see3camcu22Controller.setAntiFlickerMode(0x02);
    }

    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To apply a drop box selection: manualAE sets the manual AE ROI
//					window size, burstLen sets the burst length, frequency sets
//					50/60 Hz anti-flicker.
//
//	ARGUMENTS	:	id - JSON id of the drop box
//					value - Selected value
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value) {
    var changedFields = [];
    if (id === "manualAE") {
        see3camcu22Controller.setAutoExpROIMode(0x02, 0, 0, 0, 0, parseInt(value));
        changedFields.push({ id: id, selected: value });
    } else if (id === "burstLen") {
        see3camcu22Controller.setBurstLength(parseInt(value));
        changedFields.push({ id: id, selected: value });
    } else if (id === "frequency") {
        var modeValue = (value === "50 Hz") ? 0x02 : 0x03;
        see3camcu22Controller.setAntiFlickerMode(modeValue);
        changedFields.push({ id: id, selected: value });
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, value)
//
//  PURPOSE		:	To send the new color kill value to the camera with
//					setColorKillValue() when the "colorKillValue" slider changes.
//
//	ARGUMENTS	:	id - JSON id of the slider
//					value - New slider value
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id, value) {
    if (id === "colorKillValue") {
        see3camcu22Controller.setColorKillValue(parseInt(value));
    }
    return [];
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To apply a flip check box change by calling setFlipMode() with
//					the horizontal/vertical checked states currently stored in the
//					"flipControl" section of the model.
//
//	ARGUMENTS	:	id - JSON id of the check box (horizontal or vertical)
//					checked - New checked state
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked) {
    if (id === "horizontal" || id === "vertical") {
        var hFlip = false;
        var vFlip = false;
        if (id === "horizontal") {
            hFlip = checked;
        } else if (id === "vertical") {
            vFlip = checked;
        }
        if (see3camcu22Hidroperty.length > 0) {
            var group = null;
            for (var i = 0; i < see3camcu22Hidroperty.length; i++) {
                if (see3camcu22Hidroperty[i].id === "flipControl") {
                    group = see3camcu22Hidroperty[i];
                    break;
                }
            }
            if (group) {
                var hChecked = false;
                var vChecked = false;
                for (var j = 0; j < group.children.length; j++) {
                    if (group.children[j].id === "horizontal") {
                        hChecked = group.children[j].checked;
                    } else if (group.children[j].id === "vertical") {
                        vChecked = group.children[j].checked;
                    }
                }
                see3camcu22Controller.setFlipMode(hChecked, vChecked);
            }
        }
    }
    return [];
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, text)
//
//  PURPOSE		:	To satisfy the common module interface; this camera has no
//					text box controls, so it does nothing.
//
//	ARGUMENTS	:	id - JSON id of the text box (unused)
//					text - New text (unused)
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(id, text) {
    return [];
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle HID button clicks: "updateDefault" restores camera
//					defaults via see3camcu22Controller.restoreDefault().
//
//	ARGUMENTS	:	id - JSON id of the clicked button
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {
    if (id === "updateDefault") {
        see3camcu22Controller.restoreDefault();
    }
    return [];
}
