import QtQuick 2.12
import QtQuick.Controls 2.12
import DeviceEnums 1.0
import "../JS/Usb.js" as UsbcamModelData

UsbcamAccordion {
    id: usbcamAcc
    anchors.margins: 10
    width: usbcamRect.width - 20
	height : implicitHeight
	visible: true
    property var usbcamProperty  
	property var result
	property var camSettingsScrollHeight : 0
	usbcamProperty: UsbcamModelData.getUsbcamModelData()
	signal initializeControls(int index)
	
	property int heightVal : 5 * 0.052 * screenHeight
	model: usbcamProperty

	Connections{
		target: prevController
		//newly added to load json
		// Handles prevController.jsonArrayRead signal: stores the UVC control JSON and loads it
		// into the Usb.js model (only for the selected camera).
		function onJsonArrayRead(jsonArray) {
			if (index !== usbcamRect.selectedIndex) return;
		    usbcamProperty = jsonArray;
		    UsbcamModelData.updateModelData(jsonArray);   			
		}

		function onCameraClosed(){
			UsbcamModelData.clearValues();
		}

		// Handles prevController.cameraControlProperty signal: unpacks [id, min, max, current,
		// step, auto/manual, enabled], updates the model and emits signals for changed fields.
		function onCameraControlProperty(propertyVal){
			if (index !== usbcamRect.selectedIndex) return;
			var id =  propertyVal[0];
			var min = propertyVal[1];
			var max = propertyVal[2];
			var current = propertyVal[3];
			var step = propertyVal[4];
			var automan = propertyVal[5];
			var enabled = propertyVal[6];
        
			// Call a function to update the cameraProperty data model
			var changedFields = UsbcamModelData.updateProperty(id, min, max, current, step, automan, enabled);
			triggerUpdateSignal(changedFields);

		}

		// Handles prevController.imagePropertiesMapChanged signal: updates the available
		// format / resolution / FPS options in the model for the selected camera.
		function onImagePropertiesMapChanged(propertiesMap){
			if (index !== usbcamRect.selectedIndex) return;
			UsbcamModelData.updateImagePropertiesMap(propertiesMap)
		}

		 // Handles prevController.currentImagePropertyChanged signal: updates the current
		 // format, resolution and FPS selections in the model for the selected camera.
		 function onCurrentImagePropertyChanged(format, resolution, fps){
			if (index !== usbcamRect.selectedIndex) return;
			UsbcamModelData.updateCurrentImageProperty(format, resolution, fps)
		}

		// Handles prevController.defaultUiValues signal: applies default values to the model and
		// emits targeted field signals so only the changed rows refresh.
		function onDefaultUiValues(values){
			var changedFields = UsbcamModelData.setUiDefaultValues(values)
			 if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i];
                
					if (change.hasOwnProperty('enabled')) {
						// Notify specific field about enabled state change
						usbcamAcc.fieldChanged(change.id, change.enabled);
					}
                
					if (change.hasOwnProperty('options')) {
						// Notify specific field about options change
						usbcamAcc.fieldOptionsChanged(change.id, change.options, change.selected);
					}

					 if (change.hasOwnProperty('value')) {
						// Notify specific field about options change
						usbcamAcc.fieldValueChanged(change.id, change.currentValue);
					}

					if (change.hasOwnProperty('selected')) {
						// Notify about value change for label update
						usbcamAcc.fieldValueChanged(change.id, change.selected);
					}
				}
			}
		}
	}

	Connections {
		target: usbcamRect
		// Handles usbcamRect.setHidAntiFlicker signal: for 1318_TC/130E/24CUG cameras, mirrors
		// the HID anti-flicker mode into the UVC power-line-frequency control and the UI.
		function onSetHidAntiFlicker(value) {
			if (index !== usbcamRect.selectedIndex)
				return
			var devType = DeviceEnumInstance.resolveDevice(controlSelectedVid, controlSelectedPid)
			if (devType !== DeviceEnums.See3CAM_1318_TC &&
				devType !== DeviceEnums.See3CAM_130E &&
				devType !== DeviceEnums.See3CAM_130E_H02R1 &&
				devType !== DeviceEnums.See3CAM_24CUG)
				return
			var uvcValue = { "DISABLE": 0, "50 Hz": 1, "60 Hz": 2 }[value]
			if (value !== "AUTO" && uvcValue === undefined)
				return

			// Linux does not mirror these cameras' HID anti-flicker command into the
			// standard UVC power-line-frequency control, so update it explicitly.
			// AUTO is HID-only and is represented by a temporary blank UI option.
			if (value !== "AUTO")
				prevController.setCameraControlProperty(index, "powerLineFreq_d", uvcValue)
			updateHidAntiFlickerInLiveModel(value)
		}
	}

	// Updates the power-line-frequency drop-down to show the HID anti-flicker value; for AUTO
	// it selects a blank placeholder option (persisted in Usb.js so re-polls keep it).
	function updateHidAntiFlickerInLiveModel(value) {
		// Persist AUTO state so a UVC control re-poll (e.g. from switching
		// back to this tab) doesn't clobber the blank placeholder below with
		// a stale concrete hardware reading.
		UsbcamModelData.setAntiFlickerHidAuto(value === "AUTO")

		var powerLineControl = null
		for (var i = 0; i < usbcamProperty.length && !powerLineControl; ++i) {
			var section = usbcamProperty[i]
			if (!section.children)
				continue
			for (var j = 0; j < section.children.length && !powerLineControl; ++j) {
				var group = section.children[j]
				if (!group.children)
					continue
				for (var k = 0; k < group.children.length; ++k) {
					if (group.children[k].id === "powerLineFreq_d") {
						powerLineControl = group.children[k]
						break
					}
				}
			}
		}
		if (!powerLineControl)
			return

		var options = []
		var hasBlank = false
		for (var optionIndex = 0; optionIndex < powerLineControl.children_drop.length; ++optionIndex) {
			var label = powerLineControl.children_drop[optionIndex].label1
			if (label === " ") {
				hasBlank = true
				if (value !== "AUTO")
					continue
			}
			options.push({ label1: label })
		}

		var selectedValue = value
		if (value === "AUTO") {
			selectedValue = " "
			if (!hasBlank)
				options.push({ label1: " " })
		}

		powerLineControl.children_drop = options
		powerLineControl.selected = selectedValue
		powerLineControl.currentValue = selectedValue
		usbcamAcc.fieldOptionsChanged("powerLineFreq_d", options, selectedValue)
	}

	// Updates the expanded flag of the item with the given label (up to 4 levels deep) and
	// adjusts the accordion height and flickable content width for the visible rows.
	function setExpandedState(label, expanded){
		var length = 0
        var indexes = findLabelIndex(usbcamProperty,label)
        if(indexes.length == 1){
			var lengthChild = 0
			var lengthGrandChild =0
            usbcamProperty[indexes[0]].expanded = expanded
			length = usbcamProperty[indexes[0]].children.length
			
			var children = usbcamProperty[indexes[0]].children
			length = children.length

			for (var i = 0; i < children.length; i++) {
				if (children[i].expanded === true) {
					lengthChild += children[i].children.length
					var grandchild = children[i].children
					for (var j = 0; j < grandchild.length; j++) {
						if (grandchild[j].expanded === true) {
							lengthGrandChild += grandchild[j].children.length
						}
					}
				}
			}
			length = length + lengthChild + lengthGrandChild
        }else if (indexes.length === 2) {
			var lengthChild = 0
			var lengthGrandChild = 0
			var item = usbcamProperty[indexes[0]].children[indexes[1]]
			item.expanded = expanded
			usbcamProperty[indexes[0]].children[indexes[1]].expanded = expanded

			var children = item.children
			length = children.length

			for (var i = 0; i < children.length; i++) {
				if (children[i].expanded === true) {
					lengthChild += children[i].children.length
					if(item.expanded == true){
						logController.expandedItem(children[i].id)
					}
				}
			}
			length = length + lengthChild + lengthGrandChild			
		} else if(indexes.length == 3){
            usbcamProperty[indexes[0]].children[indexes[1]].children[indexes[2]].expanded = expanded
			length = usbcamProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children.length
		}  else if(indexes.length == 4){
            usbcamProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children[indexes[3]].expanded = expanded
			length =  usbcamProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children[indexes[3]].length
		} 

		var width = 0.0805 * MonitorHandler.screenResolution.width
		var scrollWidth;
		if(expanded == true){
			heightVal += length*  0.052 * screenHeight 
			if(heightVal > usbcamRect.height){
				camSettingsScrollHeight = heightVal +  0.052 * screenHeight + selectedDeviceCount *  0.052 * screenHeight
				scrollWidth = 0.2 * MonitorHandler.screenResolution.width
			} else{
				scrollWidth = 0.2 * MonitorHandler.screenResolution.width
			}
			if(indexes.length == 1){
				if(indexes[0] != 0){
					width =  indexes.length* width
				} else{
					width = 0
				}
			} else{
				width = width *1.4
			}
			if(usbcamRect.width > 0 && usbcamFlickable.dynamicContentWidth < scrollWidth + width){
				usbcamFlickable.dynamicContentWidth = scrollWidth + width
			}
		} else{			
			heightVal = heightVal - length * 0.052 * screenHeight 
			camSettingsScrollHeight = heightVal + 2 *  0.052 * screenHeight + 80
			var count =0
			for(i =0 ; i < usbcamProperty.length ; i++){
				if(usbcamProperty[i]. expanded == false){
					count ++
				}
				if(count == usbcamProperty.length){
					usbcamFlickable.dynamicContentWidth = 0
				}
			}
		}
    }

    // Recursively searches data for an item with the given label and returns its index path
    // (e.g. [group, child]), or null if not found.
    function findLabelIndex(data, labelToFind) {
        // Iterate over the data
        for (let i = 0; i < data.length; i++) {
            const item = data[i];
            // If the current label matches the one we're looking for, return the path
            if (item.label === labelToFind) {
                return [i];
            }
            // If the current item has children, recurse through them
            if (item.children && item.children.length > 0) {
                const childResult = findLabelIndex(item.children, labelToFind);
                if (childResult) {
                    return [i, ...childResult]; // If found in children, return the full path
                }
            }
        }
        return null; // Return null if not found
    }

	//Function for value update in the Slider   
    // Updates a slider value in the model and on the camera (prevController.
    // setCameraControlProperty via Usb.js) and emits fieldValueChanged to refresh the label.
    function handleSliderValChanged(label, id, currentVal){
		UsbcamModelData.updateSliderVal(label,id,currentVal)

		// Emit signal to update the parent label text
		usbcamAcc.fieldValueChanged(id, currentVal);
    }

	// OPTIMIZED: No full reload, only targeted updates
    // Applies a drop-down selection in the model and on the camera, then emits targeted
    // accordion signals (enabled / options / selected) for each field it affected.
    function handleDropBoxValChanged(label, id, value) {
        
        // Get the list of changed fields from JS
        var changedFields = UsbcamModelData.handleDropBoxValChanged(label, id, value);
        
        // Emit targeted signals for only the changed fields
        if (changedFields && changedFields.length > 0) {
            for (var i = 0; i < changedFields.length; i++) {
                var change = changedFields[i];
                
                if (change.hasOwnProperty('enabled')) {
                    // Notify specific field about enabled state change
                    usbcamAcc.fieldChanged(change.id, change.enabled);
                }
                
                if (change.hasOwnProperty('options')) {
                    // Notify specific field about options change
                    usbcamAcc.fieldOptionsChanged(change.id, change.options, change.selected);
                }

				if (change.hasOwnProperty('selected')) {
					// Notify about value change for label update
					usbcamAcc.fieldValueChanged(change.id, change.selected);
				}
            }
        }
    }

	function handleCheckBoxValChanged(label,id,checked){
		UsbcamModelData.updateCheckBoxValue(id, checked)
	}

	function handleTextBoxValChanged(label, id, text){
		UsbcamModelData.updateTextBoxField(label, id, text); //textbox
	}

	// Applies the selected video format/resolution/FPS on the camera
	// (prevController.setCurrentImageProperty via Usb.js).
	function setCurrentImageProperty(){
		UsbcamModelData.setCurrentImageProperty()
	}

	// Applies the selected still-capture format/resolution on the camera
	// (prevController.setCurrentStillProperty via Usb.js).
	function setCurrentStillProperty() {
		UsbcamModelData.setCurrentStillProperty()	
	}

	// Reads all UVC control values and image properties for this camera from prevController,
	// disabling controls it fails to read, then refreshes the model bound to the accordion.
	function readCameraControls(){
		UsbcamModelData.clearData()
		//GET camera control properties
			for(var i = 0; i < 19; i++){
				result = prevController.getCameraControlProperty(index, i);
				if ( result != 1){
					UsbcamModelData.disableControl("cameraSettings", i)
				}
			}

			result = prevController.getImageProperty(index);
			if(!result){
				UsbcamModelData.disableControl("vidProperties", 0)
			}
			
			result = prevController.getCurrentImageProperty(index)
			if(!result){
				UsbcamModelData.disableControl("vidProperties", 0)
			}
			UsbcamModelData.resyncStillProperties()
			usbcamProperty = UsbcamModelData.getUsbcamModelData()
	}

	// Emits the accordion field signals (enabled, options, selected, checked, text, value,
	// range) for each change object returned by the Usb.js model.
	function triggerUpdateSignal(changedFields){
		if (!changedFields) return;

		for (var i = 0; i < changedFields.length; i++) {
			var change = changedFields[i];
			
			if (change.hasOwnProperty('enabled')) {
				usbcamAcc.fieldChanged (change.id, change.enabled);
			}

			if (change.hasOwnProperty('options')) {
				// Notify specific field about options change
				usbcamAcc.fieldOptionsChanged(change.id, change.options, change.selected);
			}
			
			if (change.hasOwnProperty('selected')) {
				// Notify about value change for label update
				usbcamAcc.fieldValueChanged(change.id, change.selected);
			}

			if (change.hasOwnProperty('checked')) {
				usbcamAcc.fieldCheckedChanged(change.id, change.checked);
			}

			if (change.hasOwnProperty('text')) {
				usbcamAcc.fieldTextChanged(change.id, change.text);
			}	

			if(change.hasOwnProperty('currentValue')) {
				usbcamAcc.fieldValueChanged(change.id, change.currentValue);
			}

			if (change.hasOwnProperty('min') && change.hasOwnProperty('max') &&
				change.hasOwnProperty('step')) {
				usbcamAcc.fieldRangeChanged(change.id, change.min, change.max,
					change.step, change.currentValue);
			}
		}
	}

}
