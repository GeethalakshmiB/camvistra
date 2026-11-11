var model = [], horizontal = false, vertical = false, faceEnabled = false, faceOverlay = false, faceEmbed = false
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(v)
//
//  PURPOSE		:	To store the HID settings JSON model (array of sections with
//					children controls) used by all lookups in this
//					See3CAM_CU83 module.
//
//	ARGUMENTS	:	v - Array of control sections loaded by UsbcamHidSettings.qml
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(v) {
  model = v
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSee3CAMHidModelData()
//
//  PURPOSE		:	To return the See3CAM_CU83 HID settings JSON model held by
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
//  PURPOSE		:	To reset the cached flip states and face detection flags
//					(enabled, overlay, embed data) to false.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
  horizontal = vertical = faceEnabled = faceOverlay = faceEmbed = false
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To schedule reading of all See3CAM_CU83 HID controls by
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
//  PURPOSE		:	To query the camera via see3camcu83Controller for special
//					effect, denoise, auto exposure ROI, orientation, exposure
//					compensation, frame rate, burst length, anti-flicker, wake on
//					motion, face detection, stream mode and flash mode. Results
//					arrive through controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
  see3camcu83Controller.getSpecialMode();
  see3camcu83Controller.getDenoiseValue();
  see3camcu83Controller.getAutoExpROI()
  see3camcu83Controller.getOrientation();
  see3camcu83Controller.getExposureCompensation();
  see3camcu83Controller.getFrameRateCtrlValue()
  see3camcu83Controller.getBurstLength();
  see3camcu83Controller.getAntiFlickerMode();
  see3camcu83Controller.getWakeOnMotion()
  see3camcu83Controller.getFaceDetection();
  see3camcu83Controller.getStreamMode();
  see3camcu83Controller.getFlashMode()
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
  return null
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	radios(map, v)
//
//  PURPOSE		:	To check the radio button whose mapped value equals v and
//					uncheck the others in the given id-to-value map.
//
//	ARGUMENTS	:	map - Object mapping radio button id to its mode value
//					v - Current mode value reported by the camera
//
//	RETURN		:	Array - {id, checked} change objects for each radio found
///////////////////////////////////////////////////////////////////////////
function radios(map, v) {
  var r = [];
  for (var id in map) {
    var c = child(id);
    if (c) {
      c.checked = map[id] === v;
      r.push({id: id, checked: c.checked})
    }
  }
  return r
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	slider(id, v, min, max)
//
//  PURPOSE		:	To set a slider's current value and, when given, its min/max
//					range in the model.
//
//	ARGUMENTS	:	id - Slider control id
//					v - Current value
//					min - Optional minimum value
//					max - Optional maximum value
//
//	RETURN		:	Array - {id, currentValue} change, or empty
///////////////////////////////////////////////////////////////////////////
function slider(id, v, min, max) {
  var c = child(id);
  if (!c) return [];
  c.currentValue = v;
  if (min !== undefined) c.min = min;
  if (max !== undefined) c.max = max;
  return [{id: id, currentValue: v}]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	text(id, v)
//
//  PURPOSE		:	To set a text control's text (value converted to string).
//
//	ARGUMENTS	:	id - Text control id
//					v - Value to display
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function text(id, v) {
  var c = child(id);
  if (!c) return [];
  c.text = v.toString();
  return [{id: id, text: c.text}]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	selected(id, v)
//
//  PURPOSE		:	To set a combo box's selected entry (and currentValue) in the
//					model.
//
//	ARGUMENTS	:	id - Combo box id
//					v - Entry to select
//
//	RETURN		:	Array - {id, selected} change, or empty
///////////////////////////////////////////////////////////////////////////
function selected(id, v) {
  var c = child(id);
  if (!c) return [];
  c.selected = v.toString();
  c.currentValue = c.selected;
  return [{id: id, selected: c.selected}]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSpecial(v)
//
//  PURPOSE		:	To reflect the special effect mode in the effect radio buttons
//					(1 normal, 4 B&W, 7 greyscale, 8 negative, 16 sketch).
//
//	ARGUMENTS	:	v - Special effect value from the camera
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateSpecial(v) {
  return radios(
      {rdoEffectNormal: 1, rdoEffectBW: 4, rdoEffectGreyScale: 7, rdoEffectNegative: 8, rdoEffectSketch: 16}, v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDenoise(v)
//
//  PURPOSE		:	To show the camera denoise value on deNoiseSlider.
//
//	ARGUMENTS	:	v - Denoise value
//
//	RETURN		:	Array - {id, currentValue} change, or empty
///////////////////////////////////////////////////////////////////////////
function updateDenoise(v) {
  return slider('deNoiseSlider', v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateROI(m, s)
//
//  PURPOSE		:	To reflect the auto exposure ROI mode in the expRoiFull /
//					expRoiManual radios and set autoExpoWinSizeCombo (enabled only
//					in manual mode) to the window size.
//
//	ARGUMENTS	:	m - ROI mode (1 = full, 2 = manual)
//					s - Window size
//
//	RETURN		:	Array - change objects for the radios and combo box
///////////////////////////////////////////////////////////////////////////
function updateROI(m, s) {
  var r = radios({expRoiFull: 1, expRoiManual: 2}, m), c = child('autoExpoWinSizeCombo');
  if (c) {
    c.enabled = m === 2;
    c.selected = s.toString();
    r.push({id: c.id, enabled: c.enabled, selected: c.selected})
  }
  return r
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateOrientation(v)
//
//  PURPOSE		:	To decode the orientation bit mask (bit 0 = horizontal,
//					bit 1 = vertical), cache the flip states and update the
//					flipCtrlHorizotal / flipCtrlVertical checkboxes.
//
//	ARGUMENTS	:	v - Orientation value from the camera
//
//	RETURN		:	Array - {id, checked} change objects for the flip checkboxes
///////////////////////////////////////////////////////////////////////////
function updateOrientation(v) {
  horizontal = (v & 1) !== 0;
  vertical = (v & 2) !== 0;
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
//  FUNCTION	:	updateExposure(v)
//
//  PURPOSE		:	To display the exposure compensation value in
//					exposureCompValue.
//
//	ARGUMENTS	:	v - Exposure compensation value from the camera
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function updateExposure(v) {
  return text('exposureCompValue', v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFrameRate(v, min, max)
//
//  PURPOSE		:	To update frameRateSlider's value and min/max range.
//
//	ARGUMENTS	:	v - Current frame rate
//					min - Minimum frame rate
//					max - Maximum frame rate
//
//	RETURN		:	Array - {id, currentValue} change, or empty
///////////////////////////////////////////////////////////////////////////
function updateFrameRate(v, min, max) {
  return slider('frameRateSlider', v, min, max)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateBurst(v)
//
//  PURPOSE		:	To show the burst length as the selected entry of
//					burstLengthCombo.
//
//	ARGUMENTS	:	v - Burst length from the camera
//
//	RETURN		:	Array - {id, selected} change, or empty
///////////////////////////////////////////////////////////////////////////
function updateBurst(v) {
  return selected('burstLengthCombo', v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlicker(v)
//
//  PURPOSE		:	To select the anti-flicker mode label (AUTO, 50 Hz, 60 Hz,
//					DISABLE) in antiFlickerCombo.
//
//	ARGUMENTS	:	v - Anti-flicker mode index 0-3
//
//	RETURN		:	Array - {id, selected} change, or empty
///////////////////////////////////////////////////////////////////////////
function updateFlicker(v) {
  return selected('antiFlickerCombo', ['AUTO', '50 Hz', '60 Hz', 'DISABLE'][v])
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateWake(v)
//
//  PURPOSE		:	To reflect the wake on motion state in the wakeOnDisable /
//					wakeOnEnable radio buttons (0 / 1).
//
//	ARGUMENTS	:	v - Wake on motion state
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateWake(v) {
  return radios({wakeOnDisable: 0, wakeOnEnable: 1}, v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStream(v)
//
//  PURPOSE		:	To reflect the stream mode in the masterMode / triggerMode
//					radio buttons (0 = master, 1 = trigger).
//
//	ARGUMENTS	:	v - Stream mode value
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateStream(v) {
  return radios({masterMode: 0, triggerMode: 1}, v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFlash(v)
//
//  PURPOSE		:	To reflect the flash mode in the strobeOff / strobeOn radio
//					buttons (0 = off, 1 = on).
//
//	ARGUMENTS	:	v - Flash mode value
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateFlash(v) {
  return radios({strobeOff: 0, strobeOn: 1}, v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateFace(e, o, d)
//
//  PURPOSE		:	To cache the face detection flags, update the faceRect
//					enable/disable radios and set the overlayRect and
//					faceDetectEmbedData checkboxes (enabled only when face
//					detection is on).
//
//	ARGUMENTS	:	e - Face detection enabled
//					o - Overlay rectangle enabled
//					d - Embed face data enabled
//
//	RETURN		:	Array - change objects for the radios and checkboxes
///////////////////////////////////////////////////////////////////////////
function updateFace(e, o, d) {
  faceEnabled = !!e;
  faceOverlay = !!o;
  faceEmbed = !!d;
  var r = radios({faceRectDisable: 0, faceRectEnable: 1}, e);
  ['overlayRect', 'faceDetectEmbedData'].forEach(function(id) {
    var c = child(id);
    if (c) {
      c.enabled = faceEnabled;
      c.checked = id === 'overlayRect' ? faceOverlay : faceEmbed;
      r.push({id: id, enabled: c.enabled, checked: c.checked})
    }
  });
  return r
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, v)
//
//  PURPOSE		:	To send a slider change to the camera: deNoiseSlider calls
//					setDenoiseValue and frameRateSlider calls setFrameRateCtrlValue.
//
//	ARGUMENTS	:	id - Id of the slider that changed
//					v - New slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id, v) {
  if (id === 'deNoiseSlider')
    see3camcu83Controller.setDenoiseValue(v);
  else if (id === 'frameRateSlider')
    see3camcu83Controller.setFrameRateCtrlValue(v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, v)
//
//  PURPOSE		:	To store text typed by the user into the matching text field
//					control in the model (no camera call).
//
//	ARGUMENTS	:	id - Text field control id
//					v - Text entered by the user
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(id, v) {
  var c = child(id);
  if (c) c.text = v
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, v)
//
//  PURPOSE		:	To update the cached flip or face detection flag for the
//					toggled checkbox and apply it via setOrientation() or
//					setFaceDetection() on see3camcu83Controller.
//
//	ARGUMENTS	:	id - Checkbox id (flipCtrlHorizotal, flipCtrlVertical,
//					  overlayRect, faceDetectEmbedData)
//					v - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, v) {
  if (id === 'flipCtrlHorizotal')
    horizontal = v;
  else if (id === 'flipCtrlVertical')
    vertical = v;
  else if (id === 'overlayRect')
    faceOverlay = v;
  else if (id === 'faceDetectEmbedData')
    faceEmbed = v;
  if (id.indexOf('flipCtrl') === 0)
    see3camcu83Controller.setOrientation(horizontal, vertical);
  else if (id === 'overlayRect' || id === 'faceDetectEmbedData')
    see3camcu83Controller.setFaceDetection(faceEnabled, faceOverlay, faceEmbed)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged(id, v)
//
//  PURPOSE		:	To send a combo box change to the camera: manual AE ROI window
//					size, burst length, or anti-flicker mode (label mapped to 0-3).
//
//	ARGUMENTS	:	id - Combo box id (autoExpoWinSizeCombo, burstLengthCombo,
//					  antiFlickerCombo)
//					v - Selected value
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged(id, v) {
  if (id === 'autoExpoWinSizeCombo')
    see3camcu83Controller.setAutoExpROI(2, 0, 0, 0, 0, parseInt(v));
  else if (id === 'burstLengthCombo')
    see3camcu83Controller.setBurstLength(parseInt(v));
  else if (id === 'antiFlickerCombo')
    see3camcu83Controller.setAntiFlickerMode({'AUTO': 0, '50 Hz': 1, '60 Hz': 2, 'DISABLE': 3}[v]);
  return []
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(g, id, checked)
//
//  PURPOSE		:	To apply a newly selected radio button: maps the group/id to a
//					value and calls the matching see3camcu83Controller setter
//					(special mode, AE ROI, wake on motion, stream, flash or face
//					detection), then syncs the group's radios.
//
//	ARGUMENTS	:	g - Radio group id (e.g. effectInputGroup, faceRectGroup)
//					id - Id of the radio button that changed
//					checked - true if the radio was checked; unchecks are ignored
//
//	RETURN		:	Array - {id, checked} change objects (empty if unchecked)
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(g, id, checked) {
  if (!checked) return [];
  var maps = {
    effectInputGroup:
        {rdoEffectNormal: 1, rdoEffectBW: 4, rdoEffectGreyScale: 7, rdoEffectNegative: 8, rdoEffectSketch: 16},
    roiExpogroup: {expRoiFull: 1, expRoiManual: 2},
    wakeOnGroup: {wakeOnDisable: 0, wakeOnEnable: 1},
    streamModeGroup: {masterMode: 0, triggerMode: 1},
    flashModeGroup: {strobeOff: 0, strobeOn: 1},
    faceRectGroup: {faceRectDisable: 0, faceRectEnable: 1}
  },
      m = maps[g], v = m ? m[id] : undefined
  if (v !== undefined) {
    if (g === 'effectInputGroup')
      see3camcu83Controller.setSpecialMode(v);
    else if (g === 'roiExpogroup')
      see3camcu83Controller.setAutoExpROI(v, 0, 0, 0, 0, 1);
    else if (g === 'wakeOnGroup')
      see3camcu83Controller.setWakeOnMotion(v);
    else if (g === 'streamModeGroup')
      see3camcu83Controller.setStreamMode(v);
    else if (g === 'flashModeGroup')
      see3camcu83Controller.setFlashMode(v);
    else if (g === 'faceRectGroup') {
      faceEnabled = !!v;
      see3camcu83Controller.setFaceDetection(faceEnabled, faceOverlay, faceEmbed)
    }
  }
  return radios(m || {}, v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle button presses: set exposure compensation from
//					exposureCompValue, or restore defaults via setToDefaultValues()
//					and re-read all controls.
//
//	ARGUMENTS	:	id - Button id (exposureCompSet or defaultValue)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {
  if (id === 'exposureCompSet')
    see3camcu83Controller.setExposureCompensation(parseInt(child('exposureCompValue').text));
  else if (id === 'defaultValue') {
    see3camcu83Controller.setToDefaultValues();
    getCameraControls()
  }
}
