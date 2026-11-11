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
		onJsonArrayRead: {
			if (index !== usbcamRect.selectedIndex) return;
		    usbcamProperty = jsonArray;
		    UsbcamModelData.updateModelData(jsonArray);   			
		}

		onCameraClosed: {
			UsbcamModelData.clearValues();
		}

		onCameraControlProperty: {
			if (index !== usbcamRect.selectedIndex) return;
			var id =  propList[0];
			var min = propList[1];
			var max = propList[2];
			var current = propList[3];
			var step = propList[4];
			var automan = propList[5];
			var enabled = propList[6];
        
			// Call a function to update the cameraProperty data model
			var changedFields = UsbcamModelData.updateProperty(id, min, max, current, step, automan, enabled);
			triggerUpdateSignal(changedFields);

		}

		onImagePropertiesMapChanged: {
			if (index !== usbcamRect.selectedIndex) return;
			UsbcamModelData.updateImagePropertiesMap(propertiesMap)
		}

		 onCurrentImagePropertyChanged: {
			if (index !== usbcamRect.selectedIndex) return;
			UsbcamModelData.updateCurrentImageProperty(format, resolution, fps)
		}

		onDefaultUiValues: {
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
		onSetHidAntiFlicker: {
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

	// Mirrors a HID anti-flicker value into the UVC "powerLineFreq_d" drop-down:
	// persists the AUTO flag, rebuilds the option list (a blank " " entry stands
	// for AUTO) and emits fieldOptionsChanged so the UI refreshes.
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

	// Expands/collapses the accordion node with the given label (found via
	// findLabelIndex), counts the visible child rows it adds/removes, adjusts
	// heightVal/camSettingsScrollHeight and grows or resets the flickable width.
	// For a level-2 node, also notifies logController.expandedItem() for each
	// expanded child.
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

    // Recursively searches the property tree for labelToFind and returns the
    // index path to it (e.g. [section, group, item]), or null if not found.
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

    // Stores the new slider value in UsbcamModelData and emits fieldValueChanged
    // so the accordion updates the label.
	//Function for value update in the Slider   
    function handleSliderValChanged(label, id, currentVal){
		UsbcamModelData.updateSliderVal(label,id,currentVal)

		// Emit signal to update the parent label text
		usbcamAcc.fieldValueChanged(id, currentVal);
    }

    // Applies a drop-down selection via UsbcamModelData and emits targeted
    // usbcamAcc signals (enabled/options/selected) for only the changed fields.
	// OPTIMIZED: No full reload, only targeted updates
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

	function setCurrentImageProperty(){
		UsbcamModelData.setCurrentImageProperty()
	}

	function setCurrentStillProperty() {
		UsbcamModelData.setCurrentStillProperty()	
	}

	// Reloads UVC controls for the selected camera: clears the model, queries all
	// 19 camera-control properties and the image properties via prevController,
	// disables unsupported controls, resyncs still properties and refreshes
	// usbcamProperty.
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

	// Emits the matching usbcamAcc signal (enabled, options, selected, checked,
	// text, currentValue, range) for each entry of changedFields so only the
	// affected controls refresh.
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
