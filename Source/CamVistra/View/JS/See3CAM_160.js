var see3cam160HidProperty = []
var isUvcExposureAuto = false
var isUvcFocusAuto = false
var afWindowSize = 0
var aeWindowSize = 0

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To cache the JSON property model (HID accordion sections and
//					their child controls) loaded by UsbcamHidSettings.qml in
//					see3cam160HidProperty, so the other functions can read and
//					update it.
//
//	ARGUMENTS	:	jsonArray - Array of section objects parsed from the camera's
//					  JSON file
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    see3cam160HidProperty = jsonArray
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the cached JSON property model
//					(see3cam160HidProperty) so UsbcamHidSettings.qml can bind it
//					to the HID accordion.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the current property model
///////////////////////////////////////////////////////////////////////////
function getSee3CAMHidModelData() {
    return see3cam160HidProperty
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	callSupportFunctions()
//
//  PURPOSE		:	To re-apply the exposure-mode and focus-mode dependent
//					enable/disable state of the HID controls using the cached
//					isUvcExposureAuto / isUvcFocusAuto flags and push both results
//					to the UI via triggerUpdateSignal().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function callSupportFunctions() {
    var changedFields = handleOnExposureModeChange(isUvcExposureAuto)
    triggerUpdateSignal(changedFields)
    var changedFields = handleOnFocusModeChange(isUvcFocusAuto)
    triggerUpdateSignal(changedFields)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To start the QML delayedControlsTimer, whose handler calls
//					getDelayedCameraControls() so the See3CAM_160 HID values are
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
//  PURPOSE		:	To request all HID control values from the See3CAM_160 (AF
//					mode, Q-factor, anti-flicker, AWB lock/preset, AE
//					lock/metering, AF status, lens position, AF lock, CAF scan
//					range, burst length, serial number, ISP and firmware
//					versions). Results arrive via controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Delayed controls — called by Timer from QML
// ----------------------------------------------------------------
function getDelayedCameraControls() {
    see3cam160Controller.getAutoFocusMode()
    see3cam160Controller.getQFactor()
    see3cam160Controller.getFlickerMode()
    see3cam160Controller.getAWBlockstatus()
    see3cam160Controller.getAWBpresetMode()
    see3cam160Controller.getAElockstatus()
    see3cam160Controller.getAEMeterMode()
    see3cam160Controller.getAFstatus()
    see3cam160Controller.getManualLensPositionMode()
    see3cam160Controller.getAFlockstatus()
    see3cam160Controller.getCAFScanRangeMode()
    see3cam160Controller.getBurstLength()
    see3cam160Controller.get64BitSerialNumber()
    // The controller has no getISPFirmwareVersion(); calling it threw a TypeError
    // that also skipped getFirmwareVersion().
    see3cam160Controller.getFirmwareVersion()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached exposure/focus auto flags and AF/AE window
//					sizes when the device is closed or switched. The property
//					model itself is kept.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
    isUvcExposureAuto = false
    isUvcFocusAuto = false
    afWindowSize = 0
    aeWindowSize = 0
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAWBLockStatus(lockStatus)
//
//  PURPOSE		:	To set the "awbLock" check box in the "awbPresets" section
//					from the AWB lock status read from the camera (checked =
//					locked).
//
//	ARGUMENTS	:	lockStatus - AWB lock status (See3CAM160.AWB_LOCK_ON or
//					  AWB_LOCK_OFF)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// AWB Lock Status  (checkbox: checked = locked)
// ----------------------------------------------------------------
function updateAWBLockStatus(lockStatus) {
    var changedFields = []
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
        if (group.id === "awbPresets" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "awbLock") {
                    child.checked = (lockStatus === See3CAM160.AWB_LOCK_ON)
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
//	ARGUMENTS	:	awbMode - AWB preset mode (See3CAM160.AWB_PRESET_*)
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
    awbPresetLabelMap[See3CAM160.AWB_PRESET_CLOUDY]                  = "Cloudy"
    awbPresetLabelMap[See3CAM160.AWB_PRESET_DAYLIGHT]                = "DayLight"
    awbPresetLabelMap[See3CAM160.AWB_PRESET_FLASH]                   = "Flash"
    awbPresetLabelMap[See3CAM160.AWB_PRESET_COOLWHITE_FLOURECENT]    = "Cool White Fluorescent"
    awbPresetLabelMap[See3CAM160.AWB_PRESET_TUNGSTEN]                = "Tungsten"
    awbPresetLabelMap[See3CAM160.AWB_PRESET_CANDLELIGHT]             = "CandleLight"
    awbPresetLabelMap[See3CAM160.AWB_PRESET_HORIZON]                 = "Horizon"
    awbPresetLabelMap[See3CAM160.AWB_PRESET_CUSTOM]                  = "Custom"
    awbPresetLabelMap[See3CAM160.AWB_PRESET_AUTO]                    = "Auto"

    var label = awbPresetLabelMap[awbMode]
    if (label === undefined) return changedFields

    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
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
//  FUNCTION	:	updateAFStatus(afStatus)
//
//  PURPOSE		:	To set the "afOff" check box in the "focusModeCtrlsText"
//					section from the AF status read from the camera (checked = AF
//					off).
//
//	ARGUMENTS	:	afStatus - AF status (See3CAM160.AF_OFF or AF_ON)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// AF Status  (checkbox: afOff — checked means AF is OFF)
// ----------------------------------------------------------------
function updateAFStatus(afStatus) {
    var changedFields = []
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
        if (group.id === "focusModeCtrlsText" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "afOff") {
                    child.checked = (afStatus === See3CAM160.AF_OFF)
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
//  FUNCTION	:	updateManualLensPosition(lensPosition)
//
//  PURPOSE		:	To map the manual lens position read from the camera to its
//					label (INF, Normal, Bar code, Macro, Initial DAC or Custom)
//					and select it in the "lensPos" drop box. Unknown values are
//					ignored.
//
//	ARGUMENTS	:	lensPosition - Lens position (See3CAM160.LENS_*)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Manual Lens Position  (dropBox: lensPos)
// ----------------------------------------------------------------
function updateManualLensPosition(lensPosition) {
    var changedFields = []

    var lensPosLabelMap = {}
    lensPosLabelMap[See3CAM160.LENS_POS_INF]       = "INF position"
    lensPosLabelMap[See3CAM160.LENS_POS_NORMAL]    = "Normal Position"
    lensPosLabelMap[See3CAM160.LENS_BARCODE_POS]   = "Bar code position"
    lensPosLabelMap[See3CAM160.LENS_MACRO_POS]     = "Macro position"
    lensPosLabelMap[See3CAM160.LENS_INITIAL_DAC_POS] = "Initial DAC position"
    lensPosLabelMap[See3CAM160.LENS_CUSTOM_POS]    = "Custom Position"

    var label = lensPosLabelMap[lensPosition]
    if (label === undefined) return changedFields

    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
        if (group.id === "focusModeCtrlsText" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "lensPos") {
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
//  FUNCTION	:	updateAFLockStatus(lockStatus)
//
//  PURPOSE		:	To set the "afLockCheckbox" check box from the AF lock status
//					read from the camera (checked = locked).
//
//	ARGUMENTS	:	lockStatus - AF lock status (See3CAM160.AF_LOCK_ON or
//					  AF_LOCK_OFF)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// AF Lock Status  (checkbox: afLockCheckbox — checked = locked)
// ----------------------------------------------------------------
function updateAFLockStatus(lockStatus) {
    var changedFields = []
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
        if (group.id === "focusModeCtrlsText" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "afLockCheckbox") {
                    child.checked = (lockStatus === See3CAM160.AF_LOCK_ON)
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
//  FUNCTION	:	updateCAFScanRangeMode(scanRangeMode)
//
//  PURPOSE		:	To map the continuous-AF scan range read from the camera to
//					its label (Macro, Normal, Full, Infinity or Hyperfocal) and
//					select it in the "cafScanRangeCombo" drop box. Unknown values
//					are ignored.
//
//	ARGUMENTS	:	scanRangeMode - CAF scan range mode
//					  (See3CAM160.CAF_*_RANGE_MODE)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// CAF Scan Range Mode  (dropBox: cafScanRangeCombo)
// ----------------------------------------------------------------
function updateCAFScanRangeMode(scanRangeMode) {
    var changedFields = []

    var cafLabelMap = {}
    cafLabelMap[See3CAM160.CAF_MACRO_RANGE_MODE]      = "Macro Range Mode"
    cafLabelMap[See3CAM160.CAF_NORMAL_RANGE_MODE]     = "Normal Range Mode"
    cafLabelMap[See3CAM160.CAF_FULL_RANGE_MODE]       = "Full Range Mode"
    cafLabelMap[See3CAM160.CAF_INFINITY_RANGE_MODE]   = "Infinity Range Mode"
    cafLabelMap[See3CAM160.CAF_HYPERFOCAL_RANGE_MODE] = "Hyperfocal Range Mode"

    var label = cafLabelMap[scanRangeMode]
    if (label === undefined) return changedFields

    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
        if (group.id === "focusModeCtrlsText" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "cafScanRangeCombo") {
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
//  FUNCTION	:	updateAFMode(value)
//
//  PURPOSE		:	To check the "continuous" or "oneShot" auto-focus radio button
//					according to the AF mode read from the camera.
//
//	ARGUMENTS	:	value - AF mode (See3CAM160.AF_CONTINUOUS or AF_ONESHOT)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Auto Focus Mode  (radioButtons: continuous, oneShot)
// ----------------------------------------------------------------
function updateAFMode(value) {
    var changedFields = []
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
        if (group.id === "focusModeCtrlsText" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "continuous") {
                    child.checked = (value === See3CAM160.AF_CONTINUOUS)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "oneShot") {
                    child.checked = (value === See3CAM160.AF_ONESHOT)
                    changedFields.push({ id: child.id, checked: child.checked })
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
// Q Factor
// ----------------------------------------------------------------
function updateQFactor(qFactor) {
    var changedFields = []
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
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
//  FUNCTION	:	updateAELockStatus(lockStatus)
//
//  PURPOSE		:	To set the "aeLock" check box from the AE lock status read
//					from the camera (checked = locked). Note: it searches the
//					section with id "aeMeteringMode".
//
//	ARGUMENTS	:	lockStatus - AE lock status (See3CAM160.AE_LOCK_ON or
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
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
        if (group.id === "aeMeteringMode" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "aeLock") {
                    child.checked = (lockStatus === See3CAM160.AE_LOCK_ON)
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
//	ARGUMENTS	:	meterMode - AE metering mode (See3CAM160.AE_*)
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
    aeMeterLabelMap[See3CAM160.AE_OFF]                  = "Manual"
    aeMeterLabelMap[See3CAM160.AE_CENTER_WEIGHTED_AVG]  = "Center-Weighted average"
    aeMeterLabelMap[See3CAM160.AE_ALL_BLOCK_INTEGRAL]   = "All block integral"
    aeMeterLabelMap[See3CAM160.AE_SMALL_AREA]           = "Spot1(small area)"
    aeMeterLabelMap[See3CAM160.AE_LARGE_AREA]           = "Spot2(large area)"

    var label = aeMeterLabelMap[meterMode]
    if (label === undefined) return changedFields

    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
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
// ----------------------------------------------------------------
// Burst Length
// ----------------------------------------------------------------
function updateBurstLength(burstLength) {
    var changedFields = []
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
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
//  PURPOSE		:	To reflect the anti-flicker mode read from the camera: check
//					the off/auto/manual radio button and, for 50/60 Hz, enable the
//					"frequency" drop box and select "50 Hz" or "60 Hz".
//
//	ARGUMENTS	:	flickerMode - Anti-flicker mode (See3CAM160.FLICKER_OFF,
//					  FLICKER_AUTO_DETECTION, FLICKER_50HZ or FLICKER_60HZ)
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Anti-Flicker Mode
// ----------------------------------------------------------------
function updateAntiFlickerMode(flickerMode) {
    var changedFields = []
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
        if (group.id === "antiFlicker" && group.children) {
            for (var j = 0; j < group.children.length; j++) {
                var child = group.children[j]
                if (child.id === "offMode") {
                    child.checked = (flickerMode === See3CAM160.FLICKER_OFF)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "autoMode") {
                    child.checked = (flickerMode === See3CAM160.FLICKER_AUTO_DETECTION)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "manualMode") {
                    child.checked = (flickerMode === See3CAM160.FLICKER_50HZ ||
                                     flickerMode === See3CAM160.FLICKER_60HZ)
                    changedFields.push({ id: child.id, checked: child.checked })
                } else if (child.id === "frequency") {
                    child.enabled      = (flickerMode === See3CAM160.FLICKER_50HZ ||
                                          flickerMode === See3CAM160.FLICKER_60HZ)
                    child.currentValue = (flickerMode === See3CAM160.FLICKER_60HZ) ? "60 Hz" : "50 Hz"
                    child.selected     = (flickerMode === See3CAM160.FLICKER_60HZ) ? "60 Hz" : "50 Hz"
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
//  FUNCTION	:	updateSerialNumber(serialNum)
//
//  PURPOSE		:	To show the 64-bit serial number reported by the controller in
//					the "serialNumber" text field of the "serialNum" section of
//					see3cam160HidProperty.
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
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
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
//					see3cam160HidProperty.
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
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
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
// ISP Firmware Version
// ----------------------------------------------------------------
function updateISPFirmwareVersioninUI(ispFirmwareVersion) {
    var changedFields = []
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var group = see3cam160HidProperty[i]
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
//  FUNCTION	:	handleOnExposureModeChange(mode)
//
//  PURPOSE		:	To cache the UVC exposure mode and enable the "aeMetering
//					mode" section (AE lock and AE metering controls) only when
//					exposure is Auto.
//
//	ARGUMENTS	:	mode - true when UVC exposure is Auto, false when Manual
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Enable / Disable controls based on exposure mode
// ----------------------------------------------------------------
function handleOnExposureModeChange(mode) {
    isUvcExposureAuto = mode
    var changedFields = []

    for (var i = 0; i < see3cam160HidProperty.length; ++i) {
        var section = see3cam160HidProperty[i]

        // AE Lock checkbox and AE Metering Mode dropbox — enabled only when Auto exposure
        if (section.id === "aeMetering mode") {
            section.enabled = isUvcExposureAuto
            changedFields.push({ id: "aeMetering mode", enabled: isUvcExposureAuto })

            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]
                    child.enabled = isUvcExposureAuto
                    changedFields.push({ id: child.id, enabled: isUvcExposureAuto })
                }
            }
        }
    }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleOnFocusModeChange(mode)
//
//  PURPOSE		:	To cache the focus mode and update the focus controls: "afOff"
//					stays enabled, the manual lens position controls are enabled
//					only in manual focus, and the other AF controls only in auto
//					focus.
//
//	ARGUMENTS	:	mode - true when focus is Auto, false when Manual
//
//	RETURN		:	Array - changed fields ({id, ...}) for triggerUpdateSignal()
//					to push to the HID accordion
///////////////////////////////////////////////////////////////////////////
// ----------------------------------------------------------------
// Enable / Disable controls based on focus mode
// ----------------------------------------------------------------
function handleOnFocusModeChange(mode) {
    isUvcFocusAuto = mode
    var changedFields = []

    for (var i = 0; i < see3cam160HidProperty.length; ++i) {
        var section = see3cam160HidProperty[i]

        if (section.id === "focusModeCtrlsText") {
            // Walk children selectively
            if (section.children) {
                for (var j = 0; j < section.children.length; j++) {
                    var child = section.children[j]

                    if (child.id === "afOff") {
                        // Always enabled — it is the toggle itself
                        child.enabled = true
                        changedFields.push({ id: child.id, enabled: true })

                    } else if (child.id === "lensPos") {
                        // Manual lens position — enabled only when focus is MANUAL (not auto)
                        child.enabled = !isUvcFocusAuto
                        changedFields.push({ id: child.id, enabled: !isUvcFocusAuto })

                    } else if (child.id === "manualLensPositionText") {
                        child.enabled = !isUvcFocusAuto
                        changedFields.push({ id: child.id, enabled: !isUvcFocusAuto })

                    } else {
                        // afLockCheckbox, cafScanRangeCombo, autoFocusMode label,
                        // continuous, oneShot — enabled only when Auto focus
                        child.enabled = isUvcFocusAuto
                        changedFields.push({ id: child.id, enabled: isUvcFocusAuto })
                    }
                }
            }
        }
    }

    return changedFields
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setFocusMode(mode)
//
//  PURPOSE		:	To handle a UVC focus auto/manual change: cache the mode and
//					push the focus-dependent enable/disable changes to the UI via
//					triggerUpdateSignal().
//
//	ARGUMENTS	:	mode - true when focus is Auto, false when Manual
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setFocusMode(mode) {
    isUvcFocusAuto = mode
    var changedFields = handleOnFocusModeChange(isUvcFocusAuto)
    triggerUpdateSignal(changedFields)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setExposureMode(mode)
//
//  PURPOSE		:	To handle a UVC exposure auto/manual change: cache the mode
//					and push the exposure-dependent enable/disable changes to the
//					UI via triggerUpdateSignal().
//
//	ARGUMENTS	:	mode - true when UVC exposure is Auto, false when Manual
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setExposureMode(mode) {
    isUvcExposureAuto = mode
    var changedFields = handleOnExposureModeChange(isUvcExposureAuto)
    triggerUpdateSignal(changedFields)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To store a check box state in the model and apply it: awbLock
//					/ aeLock / afLockCheckbox set the corresponding lock, afOff
//					sets AF status and re-evaluates the focus-dependent controls.
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
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var section = see3cam160HidProperty[i]
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
        see3cam160Controller.setAWBlockstatus(
            checked ? See3CAM160.AWB_LOCK_ON : See3CAM160.AWB_LOCK_OFF
        )

    } else if (id === "aeLock") {
        see3cam160Controller.setAElockstatus(
            checked ? See3CAM160.AE_LOCK_ON : See3CAM160.AE_LOCK_OFF
        )

    } else if (id === "afOff") {
        // checked = AF disabled; unchecked = AF enabled
        var afStatus = checked ? See3CAM160.AF_OFF : See3CAM160.AF_ON
        see3cam160Controller.setAFstatus(afStatus)

        // When AF is turned off, disable all auto-focus dependent controls
        isUvcFocusAuto = !checked
        var changedFields = handleOnFocusModeChange(isUvcFocusAuto)
        triggerUpdateSignal(changedFields)

    } else if (id === "afLockCheckbox") {
        see3cam160Controller.setAFlockstatus(
            checked ? See3CAM160.AF_LOCK_ON : See3CAM160.AF_LOCK_OFF
        )
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(identification, id, checked)
//
//  PURPOSE		:	To handle a radio button click: update checked states in the
//					group and, when checked, call setAutoFocusMode() for the AF
//					radios or setAntiFlickerMode() for the anti-flicker radios
//					(enabling the frequency drop box only in manual).
//
//	ARGUMENTS	:	identification - Radio group name from JSON (autoFocusModes or
//					  antiFlickerMode)
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
        "autoFocusModes":  "focusModeCtrlsText",
        "antiFlickerMode": "antiFlicker"
    }

    var groupId = identificationToGroupId[identification]
    if (!groupId) {
        console.log("Unknown identification:", identification)
        return changedFields
    }

    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var section = see3cam160HidProperty[i]

        if (section.id === groupId && section.children) {

            for (var j = 0; j < section.children.length; j++) {
                var radio = section.children[j]

                if (radio.id === id) {
                    radio.checked = checked
                    changedFields.push({ id: radio.id, checked: checked })

                    if (checked) {
                        if (groupId === "focusModeCtrlsText") {
                            // Auto-focus mode: continuous / oneShot
                            var afMap = {
                                "continuous": See3CAM160.AF_CONTINUOUS,
                                "oneShot":    See3CAM160.AF_ONESHOT
                            }
                            if (afMap[id] !== undefined)
                                see3cam160Controller.setAutoFocusMode(afMap[id])

                        } else if (groupId === "antiFlicker") {
                            var isManual = (id === "manualMode")
                            var frequency = ""

                            // Enable/disable frequency dropdown
                            for (var k = 0; k < section.children.length; k++) {
                                if (section.children[k].id === "frequency") {
                                    section.children[k].enabled = isManual
                                    changedFields.push({ id: "frequency", enabled: isManual })
                                    frequency = section.children[k].currentValue
                                }
                            }

                            if (id === "offMode") {
                                see3cam160Controller.setFlickerMode(See3CAM160.FLICKER_OFF)
                            } else if (id === "autoMode") {
                                see3cam160Controller.setFlickerMode(See3CAM160.FLICKER_AUTO_DETECTION)
                            } else if (id === "manualMode") {
                                if (frequency === "60 Hz") {
                                    see3cam160Controller.setFlickerMode(See3CAM160.FLICKER_60HZ)
                                } else {
                                    see3cam160Controller.setFlickerMode(See3CAM160.FLICKER_50HZ)
                                }
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
//  PURPOSE		:	To store a drop box selection in the model and send it to
//					see3cam160Controller: AWB preset, manual lens position, CAF
//					scan range, AE metering mode (labels mapped to enums), burst
//					length, or 50/60 Hz anti-flicker frequency.
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
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var section = see3cam160HidProperty[i]
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
            "Cloudy":                  See3CAM160.AWB_PRESET_CLOUDY,
            "DayLight":                See3CAM160.AWB_PRESET_DAYLIGHT,
            "Flash":                   See3CAM160.AWB_PRESET_FLASH,
            "Cool White Fluorescent":  See3CAM160.AWB_PRESET_COOLWHITE_FLOURECENT,
            "Tungsten":                See3CAM160.AWB_PRESET_TUNGSTEN,
            "CandleLight":             See3CAM160.AWB_PRESET_CANDLELIGHT,
            "Horizon":                 See3CAM160.AWB_PRESET_HORIZON,
            "Custom":                  See3CAM160.AWB_PRESET_CUSTOM,
            "Auto":                    See3CAM160.AWB_PRESET_AUTO
        }
        if (awbPresetValueMap[value] !== undefined)
            see3cam160Controller.setAWBpresetMode(awbPresetValueMap[value])

    } else if (id === "lensPos") {
        var lensPosValueMap = {
            "INF position":          See3CAM160.LENS_POS_INF,
            "Normal Position":       See3CAM160.LENS_POS_NORMAL,
            "Bar code position":     See3CAM160.LENS_BARCODE_POS,
            "Macro position":        See3CAM160.LENS_MACRO_POS,
            "Initial DAC position":  See3CAM160.LENS_INITIAL_DAC_POS,
            "Custom Position":       See3CAM160.LENS_CUSTOM_POS
        }
        if (lensPosValueMap[value] !== undefined)
            see3cam160Controller.setManualLensPositionMode(lensPosValueMap[value])

    } else if (id === "cafScanRangeCombo") {
        var cafValueMap = {
            "Macro Range Mode":      See3CAM160.CAF_MACRO_RANGE_MODE,
            "Normal Range Mode":     See3CAM160.CAF_NORMAL_RANGE_MODE,
            "Full Range Mode":       See3CAM160.CAF_FULL_RANGE_MODE,
            "Infinity Range Mode":   See3CAM160.CAF_INFINITY_RANGE_MODE,
            "Hyperfocal Range Mode": See3CAM160.CAF_HYPERFOCAL_RANGE_MODE
        }
        if (cafValueMap[value] !== undefined)
            see3cam160Controller.setCAFScanRangeMode(cafValueMap[value])

    } else if (id === "aeMeteringMode") {
        var aeMeterValueMap = {
            "Manual":                   See3CAM160.AE_OFF,
            "Center-Weighted average":  See3CAM160.AE_CENTER_WEIGHTED_AVG,
            "All block integral":       See3CAM160.AE_ALL_BLOCK_INTEGRAL,
            "Spot1(small area)":        See3CAM160.AE_SMALL_AREA,
            "Spot2(large area)":        See3CAM160.AE_LARGE_AREA
        }
        if (aeMeterValueMap[value] !== undefined)
            see3cam160Controller.setAEMeterMode(aeMeterValueMap[value])

    } else if (id === "burstLen") {
        see3cam160Controller.setBurstLength(value)

    } else if (id === "frequency") {
        if (value === "50 Hz") {
            see3cam160Controller.setFlickerMode(See3CAM160.FLICKER_50HZ)
        } else if (value === "60 Hz") {
            see3cam160Controller.setFlickerMode(See3CAM160.FLICKER_60HZ)
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider's new value in the model and, for
//					"qFactorVal", send it to the camera with setQFactor().
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
    for (var i = 0; i < see3cam160HidProperty.length; i++) {
        var section = see3cam160HidProperty[i]
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
        see3cam160Controller.setQFactor(currentVal)
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
        see3cam160Controller.setToDefault()
        getCameraControls()
    }
}