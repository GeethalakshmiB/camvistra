var model = [];
var horizontal = false;
var vertical = false;
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(data)
//
//  PURPOSE		:	To store the HID settings JSON model (array of sections with
//					children controls) used by all lookups in this
//					See3CAM_CU31 module.
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
//  PURPOSE		:	To return the See3CAM_CU31 HID settings JSON model held by
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
  horizontal = false;
  vertical = false
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To schedule reading of all See3CAM_CU31 HID controls by
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
//  PURPOSE		:	To query the camera via see3camcu31Controller for orientation,
//					raw noise reduction, trigger mode, AE speed/status, AWB status,
//					anti-flicker, camera mode, AE/AWB window and mask overlays and
//					dimensions (mask 1), preset mode, serial number and ISP
//					firmware version. Results arrive through controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
  see3camcu31Controller.getOrientation()
  see3camcu31Controller.getRawNoiseReductionStatus()
  see3camcu31Controller.getTriggerMode()
  see3camcu31Controller.getAEConvergenceSpeed()
  see3camcu31Controller.getAutoExposureStatus()
  see3camcu31Controller.getAWBStatus()
  see3camcu31Controller.getAntiFlickerMode()
  see3camcu31Controller.getCameraMode()
  see3camcu31Controller.getAEWindowOverlay()
  see3camcu31Controller.getAEWindowDimensions()
  see3camcu31Controller.getAEMaskOverlay()
  see3camcu31Controller.getAEMaskDimensions(true, 1)
  see3camcu31Controller.getAWBWindowOverlay()
  see3camcu31Controller.getAWBWindowDimensions()
  see3camcu31Controller.getAWBMaskOverlay()
  see3camcu31Controller.getAWBMaskDimensions(true, 1)
  see3camcu31Controller.getPresetMode()
  see3camcu31Controller.get64BitSerialNumber()
  see3camcu31Controller.readISPFirmwareVersion()
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
  for (var i = 0; i < model.length; i++)
    if (model[i].children)
      for (var j = 0; j < model[i].children.length; j++)
        if (model[i].children[j].id === id) return model[i].children[j];
  return null;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	changesFor(ids, value, property)
//
//  PURPOSE		:	To set the given boolean property on each control in the map
//					to true only where its mapped value equals value (radio
//					group selection).
//
//	ARGUMENTS	:	ids - Object mapping control id to its mode value
//					value - Current mode value reported by the camera
//					property - Property to set (always 'checked' in use)
//
//	RETURN		:	Array - {id, checked} change objects for each control found
///////////////////////////////////////////////////////////////////////////
function changesFor(ids, value, property) {
  var changes = [];
  for (var id in ids) {
    var c = child(id);
    if (c) {
      c[property] = (ids[id] === value);
      changes.push({id: id, checked: c[property]})
    }
  }
  return changes
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setText(id, value)
//
//  PURPOSE		:	To set a text control's text (value converted to string).
//
//	ARGUMENTS	:	id - Text control id
//					value - Value to display
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function setText(id, value) {
  var c = child(id);
  if (!c) return [];
  c.text = value.toString();
  return [{id: id, text: c.text}]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setValues(ids, values)
//
//  PURPOSE		:	To set the text of several text fields at once, pairing each
//					id with the value at the same index.
//
//	ARGUMENTS	:	ids - Array of text field ids
//					values - Array of values, same order as ids
//
//	RETURN		:	Array - {id, text} change objects for each field found
///////////////////////////////////////////////////////////////////////////
function setValues(ids, values) {
  var out = [];
  for (var i = 0; i < ids.length; i++) {
    var c = child(ids[i]);
    if (c) {
      c.text = values[i].toString();
      out.push({id: ids[i], text: c.text})
    }
  }
  return out
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateOrientation(v)
//
//  PURPOSE		:	To decode the orientation into horizontal (HORIZONTAL or
//					ROTATE_180) and vertical (VERTICAL or ROTATE_180) flip states,
//					cache them and update the flip checkboxes.
//
//	ARGUMENTS	:	v - See3CAMCU31 orientation value from the camera
//
//	RETURN		:	Array - {id, checked} change objects for the flip checkboxes
///////////////////////////////////////////////////////////////////////////
function updateOrientation(v) {
  horizontal = (v === See3CAMCU31.HORIZONTAL || v === See3CAMCU31.ROTATE_180)
  vertical = (v === See3CAMCU31.VERTICAL || v === See3CAMCU31.ROTATE_180)
  var a = child('flipCtrlHorizotal'), b = child('flipCtrlVertical'), r = [];
  if (a) {
    a.checked = horizontal;
    r.push({id: a.id, checked: a.checked})
  }
  if (b) {
    b.checked = vertical;
    r.push({id: b.id, checked: b.checked})
  }
  return r
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRNR(v)
//
//  PURPOSE		:	To reflect the raw noise reduction status in the disableRNR /
//					enableRNR radio buttons.
//
//	ARGUMENTS	:	v - RNR_DISABLE or RNR_ENABLE
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateRNR(v) {
  return changesFor({disableRNR: See3CAMCU31.RNR_DISABLE, enableRNR: See3CAMCU31.RNR_ENABLE}, v, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTrigger(v)
//
//  PURPOSE		:	To reflect the trigger mode in the triggerDisable /
//					triggerReadOut / triggerShutter radio buttons.
//
//	ARGUMENTS	:	v - DISABLE_TRIGGER, READOUT_TRIGGER or SHUTTER_TRIGGER
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateTrigger(v) {
  return changesFor(
      {
        triggerDisable: See3CAMCU31.DISABLE_TRIGGER,
        triggerReadOut: See3CAMCU31.READOUT_TRIGGER,
        triggerShutter: See3CAMCU31.SHUTTER_TRIGGER
      },
      v, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAESpeed(v)
//
//  PURPOSE		:	To show the auto exposure convergence speed on
//					convergenceSpeedSlider.
//
//	ARGUMENTS	:	v - Convergence speed value from the camera
//
//	RETURN		:	Array - {id, currentValue} change, or empty
///////////////////////////////////////////////////////////////////////////
function updateAESpeed(v) {
  var c = child('convergenceSpeedSlider');
  if (!c) return [];
  c.currentValue = v;
  return [{id: c.id, currentValue: v}]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAEStatus(v)
//
//  PURPOSE		:	To reflect the auto exposure release/hold status in the
//					autoExposure / autoExposureHold radio buttons.
//
//	ARGUMENTS	:	v - AE_RELEASE or AE_HOLD
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateAEStatus(v) {
  return changesFor({autoExposure: See3CAMCU31.AE_RELEASE, autoExposureHold: See3CAMCU31.AE_HOLD}, v, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAWBStatus(v)
//
//  PURPOSE		:	To reflect the auto white balance release/hold status in the
//					awbRelease / awbHold radio buttons.
//
//	ARGUMENTS	:	v - AWB_RELEASE or AWB_HOLD
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateAWBStatus(v) {
  return changesFor({awbRelease: See3CAMCU31.AWB_RELEASE, awbHold: See3CAMCU31.AWB_HOLD}, v, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlicker(v)
//
//  PURPOSE		:	To reflect the anti-flicker mode in the flickerAuto /
//					flicker50hz / flicker60hz / flickerDisable radio buttons.
//
//	ARGUMENTS	:	v - MODE_AUTO, MODE_50Hz, MODE_60Hz or MODE_DISABLE
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateFlicker(v) {
  return changesFor(
      {
        flickerAuto: See3CAMCU31.MODE_AUTO,
        flicker50hz: See3CAMCU31.MODE_50Hz,
        flicker60hz: See3CAMCU31.MODE_60Hz,
        flickerDisable: See3CAMCU31.MODE_DISABLE
      },
      v, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCameraMode(v)
//
//  PURPOSE		:	To reflect the camera mode in the autoCameraMode /
//					lowLightMode / ledMode radio buttons.
//
//	ARGUMENTS	:	v - AUTO, LOW_LIGHT or LED
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateCameraMode(v) {
  return changesFor(
      {autoCameraMode: See3CAMCU31.AUTO, lowLightMode: See3CAMCU31.LOW_LIGHT, ledMode: See3CAMCU31.LED}, v, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateOverlay(prefix, v)
//
//  PURPOSE		:	To reflect an enable/disable state in the 'disable<prefix>' /
//					'enable<prefix>' radio pair (used for AE/AWB window and mask
//					overlays and mask status).
//
//	ARGUMENTS	:	prefix - Radio id suffix, e.g. 'AEWindow', 'AWBMaskStatus'
//					v - 0 = disabled, 1 = enabled
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateOverlay(prefix, v) {
  var map = {};
  map['disable' + prefix] = 0;
  map['enable' + prefix] = 1;
  return changesFor(map, v, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAEWindow(w, h, x, y)
//
//  PURPOSE		:	To display the auto exposure window width, height and start
//					position in the AE window text fields.
//
//	ARGUMENTS	:	w - Window width
//					h - Window height
//					x - Window X start
//					y - Window Y start
//
//	RETURN		:	Array - {id, text} change objects
///////////////////////////////////////////////////////////////////////////
function updateAEWindow(w, h, x, y) {
  return setValues(['aeWidthTextField', 'aeHeightTextField', 'aeXStartTextField', 'aeYStartTextField'], [w, h, x, y])
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAWBWindow(w, h, x, y)
//
//  PURPOSE		:	To display the auto white balance window width, height and
//					start position in the AWB window text fields.
//
//	ARGUMENTS	:	w - Window width
//					h - Window height
//					x - Window X start
//					y - Window Y start
//
//	RETURN		:	Array - {id, text} change objects
///////////////////////////////////////////////////////////////////////////
function updateAWBWindow(w, h, x, y) {
  return setValues(
      ['awbWidthTextField', 'awbHeightTextField', 'awbXStartTextField', 'awbYStartTextField'], [w, h, x, y])
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAEMask(includeId, id, state, w, h, x, y)
//
//  PURPOSE		:	To display an AE mask's status and dimensions; also selects the
//					mask id in aeMaskIDCombo when includeId is true (the combo
//					change itself is not returned as a change object).
//
//	ARGUMENTS	:	includeId - true to also select the mask id in aeMaskIDCombo
//					  (echoed from getAEMaskDimensions)
//					id - Mask id
//					state - Mask status (0 disabled, 1 enabled)
//					w - Mask width
//					h - Mask height
//					x - Mask X start
//					y - Mask Y start
//
//	RETURN		:	Array - change objects for the status radios and text fields
///////////////////////////////////////////////////////////////////////////
function updateAEMask(includeId, id, state, w, h, x, y) {
  if (includeId) {
    var c = child('aeMaskIDCombo');
    if (c) c.selected = id.toString()
  }
  return updateOverlay('AEMaskStatus', state)
      .concat(setValues(
          ['aeMaskWidthTextField', 'aeMaskHeightTextField', 'aeMaskXStartTextField', 'aeMaskYStartTextField'],
          [w, h, x, y]))
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAWBMask(includeId, id, state, w, h, x, y)
//
//  PURPOSE		:	To display an AWB mask's status and dimensions; also selects
//					the mask id in awbMaskIDCombo when includeId is true (the
//					combo change itself is not returned as a change object).
//
//	ARGUMENTS	:	includeId - true to also select the mask id in awbMaskIDCombo
//					  (echoed from getAWBMaskDimensions)
//					id - Mask id
//					state - Mask status (0 disabled, 1 enabled)
//					w - Mask width
//					h - Mask height
//					x - Mask X start
//					y - Mask Y start
//
//	RETURN		:	Array - change objects for the status radios and text fields
///////////////////////////////////////////////////////////////////////////
function updateAWBMask(includeId, id, state, w, h, x, y) {
  if (includeId) {
    var c = child('awbMaskIDCombo');
    if (c) c.selected = id.toString()
  }
  return updateOverlay('AWBMaskStatus', state)
      .concat(setValues(
          ['awbMaskWidthTextField', 'awbMaskHeightTextField', 'awbMaskXStartTextField', 'awbMaskYStartTextField'],
          [w, h, x, y]))
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updatePreset(mode)
//
//  PURPOSE		:	To reflect the preset mode in the manualPreset / userPreset1 /
//					userPreset2 radio buttons.
//
//	ARGUMENTS	:	mode - MANUAL_PRESET, USER_PRESET_1 or USER_PRESET_2
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updatePreset(mode) {
  return changesFor(
      {
        manualPreset: See3CAMCU31.MANUAL_PRESET,
        userPreset1: See3CAMCU31.USER_PRESET_1,
        userPreset2: See3CAMCU31.USER_PRESET_2
      },
      mode, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, checked)
//
//  PURPOSE		:	To update the cached horizontal/vertical flip state for the
//					toggled flip checkbox and apply both via
//					see3camcu31Controller.setOrientation().
//
//	ARGUMENTS	:	id - Checkbox id (flipCtrlHorizotal or flipCtrlVertical)
//					checked - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, checked) {
  if (id === 'flipCtrlHorizotal') horizontal = checked;
  if (id === 'flipCtrlVertical') vertical = checked;
  see3camcu31Controller.setOrientation(horizontal, vertical)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, currentVal)
//
//  PURPOSE		:	To store a slider's new value in the model and, for
//					convergenceSpeedSlider, send it via setAEConvergenceSpeed().
//
//	ARGUMENTS	:	id - Id of the slider that changed
//					currentVal - New slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id, currentVal) {
  for (var i = 0; i < model.length; i++) {
        var section = model[i]
        if (section.children) {
            for (var j = 0; j < section.children.length; j++) {
                if (section.children[j].id === id) {
                    section.children[j].currentValue = currentVal
                    break
                }
            }
        }
    }
  if (id === 'convergenceSpeedSlider') see3camcu31Controller.setAEConvergenceSpeed(currentVal)
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
  var c = child(id);
  if (c) c.text = text
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, value)
//
//  PURPOSE		:	To read the dimensions of the newly selected AE or AWB mask
//					id from the camera (getAEMaskDimensions / getAWBMaskDimensions
//					with includeId false).
//
//	ARGUMENTS	:	id - Combo box id (aeMaskIDCombo or awbMaskIDCombo)
//					value - Selected mask id (parsed to int)
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, value) {
  if (id === 'aeMaskIDCombo') see3camcu31Controller.getAEMaskDimensions(false, parseInt(value));
  if (id === 'awbMaskIDCombo') see3camcu31Controller.getAWBMaskDimensions(false, parseInt(value));
  return []
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(group, id, checked)
//
//  PURPOSE		:	To apply a newly selected radio button: maps the group/id to a
//					value and calls the matching see3camcu31Controller setter (RNR,
//					trigger, AE/AWB status, anti-flicker, camera mode, AE/AWB
//					overlays, or preset select), then syncs the group's radios.
//					Mask status groups only update the UI.
//
//	ARGUMENTS	:	group - Radio group id (e.g. triggerModeGroup)
//					id - Id of the radio button that changed
//					checked - true if the radio was checked; unchecks are ignored
//
//	RETURN		:	Array - {id, checked} change objects (empty if unchecked)
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(group, id, checked) {
  if (!checked) return [];
  var maps = {
    rnrModeGroup: {disableRNR: 0, enableRNR: 1},
    triggerModeGroup: {triggerDisable: 0, triggerReadOut: 1, triggerShutter: 2},
    autoExpStatusGroup: {autoExposure: 0, autoExposureHold: 1},
    awbStatusGroup: {awbRelease: 0, awbHold: 1},
    antiFlickerGroup: {flickerAuto: 0, flicker50hz: 1, flicker60hz: 2, flickerDisable: 3},
    cameraModeGroup: {autoCameraMode: 0, lowLightMode: 1, ledMode: 2},
    aeWindowOverlayGroup: {disableAEWindow: 0, enableAEWindow: 1},
    aeMaskOverlayGroup: {disableAEMask: 0, enableAEMask: 1},
    aeMaskStatusGroup: {disableAEMaskStatus: 0, enableAEMaskStatus: 1},
    awbWindowOverlayGroup: {disableAWBWindow: 0, enableAWBWindow: 1},
    awbMaskOverlayGroup: {disableAWBMask: 0, enableAWBMask: 1},
    awbMaskStatusGroup: {disableAWBMaskStatus: 0, enableAWBMaskStatus: 1},
    presetModeGroup: {manualPreset: 0, userPreset1: 1, userPreset2: 2}
  }
  var m = maps[group];
  var v = m ? m[id] : undefined;
  if (v !== undefined) {
    if (group === 'rnrModeGroup')
      see3camcu31Controller.setRawNoiseReductionStatus(v)
      else if (group === 'triggerModeGroup') see3camcu31Controller.setTriggerMode(v)
      else if (group === 'autoExpStatusGroup') see3camcu31Controller.setAutoExposureStatus(v)
      else if (group === 'awbStatusGroup') see3camcu31Controller.setAWBStatus(v)
      else if (group === 'antiFlickerGroup') see3camcu31Controller.setAntiFlickerMode(v)
      else if (group === 'cameraModeGroup') see3camcu31Controller.setCameraMode(v)
      else if (group === 'aeWindowOverlayGroup') see3camcu31Controller.setAEWindowOverlay(v)
      else if (group === 'aeMaskOverlayGroup') see3camcu31Controller.setAEMaskOverlay(v)
      else if (group === 'awbWindowOverlayGroup') see3camcu31Controller.setAWBWindowOverlay(v)
      else if (group === 'awbMaskOverlayGroup') see3camcu31Controller.setAWBMaskOverlay(v)
      else if (group === 'presetModeGroup') see3camcu31Controller.setPresetMode(v, See3CAMCU31.PRESET_SELECT)
  }
  return changesFor(m || {}, v, 'checked')
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	num(id)
//
//  PURPOSE		:	To read a text field from the model and parse it as an integer.
//
//	ARGUMENTS	:	id - Text field id
//
//	RETURN		:	Number - parsed value, 0 if the control is missing
///////////////////////////////////////////////////////////////////////////
function num(id) {
  var c = child(id);
  return c ? parseInt(c.text) : 0
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	selected(id)
//
//  PURPOSE		:	To read a combo box's selected (or currentValue) entry from
//					the model as an integer.
//
//	ARGUMENTS	:	id - Combo box id
//
//	RETURN		:	Number - parsed value, 1 if missing or empty
///////////////////////////////////////////////////////////////////////////
function selected(id) {
  var c = child(id);
  return c ? parseInt(c.selected || c.currentValue || 1) : 1
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	enabled(id)
//
//  PURPOSE		:	To read a control's checked state as an integer flag.
//
//	ARGUMENTS	:	id - Control id
//
//	RETURN		:	Number - 1 if checked, else 0
///////////////////////////////////////////////////////////////////////////
function enabled(id) {
  var c = child(id);
  return c && c.checked ? 1 : 0
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle button presses: read temperature, set AE/AWB window
//					or mask dimensions from the text fields, save the selected user
//					preset, set the default preset, restore defaults (then re-read
//					controls), and read serial number or ISP firmware version.
//
//	ARGUMENTS	:	id - Button id (e.g. aeSetBtn, awbMaskSetBtn, savePreset,
//					  setDefaultPreset, defaultValue)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {
  if (id === 'readTempBtn')
    see3camcu31Controller.readTemperature()
    else if (id === 'aeSetBtn') see3camcu31Controller.setAEWindowDimensions(
        num('aeWidthTextField'), num('aeHeightTextField'), num('aeXStartTextField'), num('aeYStartTextField'))
    else if (id === 'aeMaskSetBtn') see3camcu31Controller.setAEMaskDimensions(
        selected('aeMaskIDCombo'), enabled('enableAEMaskStatus'), num('aeMaskWidthTextField'),
        num('aeMaskHeightTextField'), num('aeMaskXStartTextField'), num('aeMaskYStartTextField'))
    else if (id === 'awbSetBtn') see3camcu31Controller.setAWBWindowDimensions(
        num('awbWidthTextField'), num('awbHeightTextField'), num('awbXStartTextField'), num('awbYStartTextField'))
    else if (id === 'awbMaskSetBtn') see3camcu31Controller.setAWBMaskDimensions(
        selected('awbMaskIDCombo'), enabled('enableAWBMaskStatus'), num('awbMaskWidthTextField'),
        num('awbMaskHeightTextField'), num('awbMaskXStartTextField'), num('awbMaskYStartTextField'))
    else if (id === 'savePreset') {
      var p = enabled('userPreset1') ? 1 : 2;
      see3camcu31Controller.setPresetMode(p, See3CAMCU31.PRESET_SAVE)
    }
  else if (id === 'setDefaultPreset') {
    var d = enabled('userPreset1') ? 1 : (enabled('userPreset2') ? 2 : 0);
    see3camcu31Controller.setPresetMode(d, See3CAMCU31.PRESET_DEFAULT)
  } else if (id === 'defaultValue') {
    see3camcu31Controller.setToDefaultValues();
    getCameraControls()
  } else if (id === 'f_wversion_selected130')
    see3camcu31Controller.get64BitSerialNumber()
    else if (id === 'serial_no_selected') see3camcu31Controller.get64BitSerialNumber()
    else if (id === 'ispFirmwareVersion') see3camcu31Controller.readISPFirmwareVersion()
}
