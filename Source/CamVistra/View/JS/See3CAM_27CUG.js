var model = [], h = false, v = false
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(x)
//
//  PURPOSE		:	To store the HID settings JSON model (array of sections with
//					children controls) used by all lookups in this
//					See3CAM_27CUG module.
//
//	ARGUMENTS	:	x - Array of control sections loaded by UsbcamHidSettings.qml
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(x) {
  model = x
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	clearData()
//
//  PURPOSE		:	To reset the cached horizontal/vertical flip states (h, v) to
//					false when the device is closed or switched.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function clearData() {
  h = v = false
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraControls()
//
//  PURPOSE		:	To schedule reading of all See3CAM_27CUG HID controls by
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
//  PURPOSE		:	To query the camera for stream mode, strobe mode, camera mode,
//					orientation, IR brightness/contrast/gain, min/max exposure
//					compensation and serial number via see3cam27cugController.
//					Results arrive asynchronously through controller signals.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDelayedCameraControls() {
  see3cam27cugController.getStreamMode();
  see3cam27cugController.getStrobeMode();
  see3cam27cugController.getCameraMode();
  see3cam27cugController.getOrientation();
  see3cam27cugController.getBrightnessForIR();
  see3cam27cugController.getContrastForIR();
  see3cam27cugController.getGainForIR();
  see3cam27cugController.getMinimumExposureCompensation();
  see3cam27cugController.getMaximumExposureCompensation();
  see3cam27cugController.getSerialNumber()
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	c(id)
//
//  PURPOSE		:	To find a control in the HID model by id by searching the
//					children of every section.
//
//	ARGUMENTS	:	id - Control id to look up (e.g. 'gainSlider')
//
//	RETURN		:	Object - the matching child control, or null if not found
///////////////////////////////////////////////////////////////////////////
function c(id) {
  for (var i = 0; i < model.length; i++)
    if (model[i].children)
      for (var j = 0; j < model[i].children.length; j++)
        if (model[i].children[j].id === id) return model[i].children[j];
  return null
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	radios(m, x)
//
//  PURPOSE		:	To check the radio button whose mapped value equals x and
//					uncheck the others in the given id-to-value map.
//
//	ARGUMENTS	:	m - Object mapping radio button id to its mode value
//					x - Current mode value reported by the camera
//
//	RETURN		:	Array - {id, checked} change objects for each radio found
///////////////////////////////////////////////////////////////////////////
function radios(m, x) {
  var r = [];
  for (var id in m) {
    var q = c(id);
    if (q) {
      q.checked = m[id] === x;
      r.push({id: id, checked: q.checked})
    }
  }
  return r
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	slider(id, x)
//
//  PURPOSE		:	To set the currentValue of a slider control in the model.
//
//	ARGUMENTS	:	id - Slider control id
//					x - New slider value
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function slider(id, x) {
  var q = c(id);
  if (!q) return [];
  q.currentValue = x;
  return [{id: id, currentValue: x}]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	text(id, x)
//
//  PURPOSE		:	To set the text of a text field control in the model
//					(value converted to string).
//
//	ARGUMENTS	:	id - Text field control id
//					x - Value to display
//
//	RETURN		:	Array - change objects ({id, ...}) to apply to the QML model;
//					empty array if the control is not found
///////////////////////////////////////////////////////////////////////////
function text(id, x) {
  var q = c(id);
  if (!q) return [];
  q.text = x.toString();
  return [{id: id, text: q.text}]
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStream(x)
//
//  PURPOSE		:	To reflect the camera stream mode in the masterMode /
//					triggerMode radio buttons (1 = master, 2 = trigger).
//
//	ARGUMENTS	:	x - Stream mode value received from the controller
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateStream(x) {
  return radios({masterMode: 1, triggerMode: 2}, x)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateStrobe(x)
//
//  PURPOSE		:	To reflect the camera strobe mode in the strobeOFF / strobeON
//					radio buttons (1 = off, 2 = on).
//
//	ARGUMENTS	:	x - Strobe mode value received from the controller
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateStrobe(x) {
  return radios({strobeOFF: 1, strobeON: 2}, x)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCamera(x)
//
//  PURPOSE		:	To reflect the camera mode in the irrgbMode / rgbMode / irMode
//					radio buttons (1 = IR-RGB, 2 = RGB, 3 = IR).
//
//	ARGUMENTS	:	x - Camera mode value received from the controller
//
//	RETURN		:	Array - {id, checked} change objects
///////////////////////////////////////////////////////////////////////////
function updateCamera(x) {
  return radios({irrgbMode: 1, rgbMode: 2, irMode: 3}, x)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateOrientation(x)
//
//  PURPOSE		:	To decode the orientation value into horizontal (3, 4) and
//					vertical (2, 4) flip states, cache them and update the
//					flipCtrlHorizotal / flipCtrlVertical checkboxes.
//
//	ARGUMENTS	:	x - Orientation value from the camera (2 = vertical,
//					  3 = horizontal, 4 = both, other = none)
//
//	RETURN		:	Array - {id, checked} change objects for the flip checkboxes
///////////////////////////////////////////////////////////////////////////
function updateOrientation(x) {
  h = x === 3 || x === 4;
  v = x === 2 || x === 4;
  var a = c('flipCtrlHorizotal'), b = c('flipCtrlVertical'), r = [];
  if (a) {
    a.checked = h;
    r.push({id: a.id, checked: h})
  }
  if (b) {
    b.checked = v;
    r.push({id: b.id, checked: v})
  }
  return r
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderValue(id, x)
//
//  PURPOSE		:	To send a slider change to the camera: brightnessSlider,
//					contrastSlider and gainSlider map to setBrightnessForIR,
//					setContrastForIR and setGainForIR respectively.
//
//	ARGUMENTS	:	id - Id of the slider that changed
//					x - New slider value
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSliderValue(id, x) {
  if (id === 'brightnessSlider')
    see3cam27cugController.setBrightnessForIR(x);
  else if (id === 'contrastSlider')
    see3cam27cugController.setContrastForIR(x);
  else if (id === 'gainSlider')
    see3cam27cugController.setGainForIR(x)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(id, x)
//
//  PURPOSE		:	To store text typed by the user into the matching text field
//					control in the model (no camera call).
//
//	ARGUMENTS	:	id - Text field control id
//					x - Text entered by the user
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(id, x) {
  var q = c(id);
  if (q) q.text = x
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCheckBoxValue(id, x)
//
//  PURPOSE		:	To update the cached horizontal/vertical flip state for the
//					toggled flip checkbox and apply both via
//					see3cam27cugController.setOrientation().
//
//	ARGUMENTS	:	id - Checkbox id (flipCtrlHorizotal or flipCtrlVertical)
//					x - New checked state
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCheckBoxValue(id, x) {
  if (id === 'flipCtrlHorizotal') h = x;
  if (id === 'flipCtrlVertical') v = x;
  see3cam27cugController.setOrientation(h, v)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleRadioButtonChange(g, id, on)
//
//  PURPOSE		:	To apply a newly selected radio button: maps the group/id to a
//					mode value, calls setStreamMode, setCameraMode or setStrobeMode
//					on see3cam27cugController and syncs the group's radio states.
//
//	ARGUMENTS	:	g - Radio group id (streamModeGroup, cameraModeGroup,
//					  strobeModeGroup)
//					id - Id of the radio button that changed
//					on - true if the radio was checked; unchecks are ignored
//
//	RETURN		:	Array - {id, checked} change objects (empty if unchecked)
///////////////////////////////////////////////////////////////////////////
function handleRadioButtonChange(g, id, on) {
  if (!on) return [];
  var maps = {
    streamModeGroup: {masterMode: 1, triggerMode: 2},
    cameraModeGroup: {irrgbMode: 1, rgbMode: 2, irMode: 3},
    strobeModeGroup: {strobeOFF: 1, strobeON: 2}
  },
      m = maps[g], x = m ? m[id] : undefined;
  if (x !== undefined) {
    if (g === 'streamModeGroup')
      see3cam27cugController.setStreamMode(x);
    else if (g === 'cameraModeGroup')
      see3cam27cugController.setCameraMode(x);
    else
      see3cam27cugController.setStrobeMode(x)
  }
  return radios(m || {}, x)
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValueChanged()
//
//  PURPOSE		:	To satisfy the common HID module interface; this camera has
//					no combo box controls, so nothing is done.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - always empty
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValueChanged() {
  return []
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleButtonClick(id)
//
//  PURPOSE		:	To handle button presses: sets min/max exposure compensation
//					from the text fields, or restores defaults via
//					setToDefaultValues() and re-reads all controls.
//
//	ARGUMENTS	:	id - Button id (minExpSetButton, maxExposureCompSet,
//					  defaultValue)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleButtonClick(id) {
  if (id === 'minExpSetButton')
    see3cam27cugController.setMinimumExposureCompensation(parseInt(c('minExpTextField').text));
  else if (id === 'maxExposureCompSet')
    see3cam27cugController.setMaximumExposureCompensation(parseInt(c('maxExpTextField').text));
  else if (id === 'defaultValue') {
    see3cam27cugController.setToDefaultValues();
    getCameraControls()
  }
}
