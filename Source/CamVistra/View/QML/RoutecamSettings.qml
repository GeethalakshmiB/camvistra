import QtQuick 2.12
import QtQuick.Controls 2.12
import "../JS/Ethernet.js" as RoutecamModelData

RoutecamAccordion {
    id: routecamAcc
    anchors.margins: 10
    width: routecamRect.width - 20
	height : implicitHeight
	visible: true
    property var routecamProperty  
	property var result
	routecamProperty: RoutecamModelData.getRoutecamModelData()
	
	property int heightVal : 5 * 0.052 * screenHeight
	model: routecamProperty
	Connections{
		target: routecamOnvifController
		//newly added to load json
		// Handles routecamOnvifController.jsonArrayRead signal: stores the Routecam control JSON
		// and loads it into the Ethernet.js model (only for the selected camera).
		function onJsonArrayRead(jsonArray) {
			if (index !== routecamRect.selectedIndex) return;
            routecamProperty = jsonArray;
            RoutecamModelData.updateModelData(jsonArray);           
        }
		function onRoutecamOnvifInitialized(){
			// The controller now loads all properties on its worker thread.
		}

		// Handles routecamOnvifController.deviceInformationReady signal: fills the device
		// information fields in the model for the selected camera.
		function onDeviceInformationReady(deviceInfo) {
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.updateDeviceInformation(deviceInfo);
		}

		// Handles routecamOnvifController.routecamControlUnavailable signal: disables the given
		// control in the model when the camera does not support it.
		function onRoutecamControlUnavailable(groupId, controlId) {
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.disableControl(groupId, controlId);
		}

		// Handles routecamOnvifController.routecamLoadingFinished signal: rebinds the accordion to
		// the loaded model data and asks logController to read the control tooltip JSON.
		function onRoutecamLoadingFinished(success) {
			if (index !== routecamRect.selectedIndex) return;
			routecamAcc.model = [];
			routecamProperty = RoutecamModelData.getRoutecamModelData();
			routecamAcc.model = routecamProperty;
			logController.readControlJsonTooltipArrayFile();
		}

		// Handles routecamOnvifController.cameraControlProperty signal: unpacks [id, min, max,
		// current, step, auto/manual, enabled] and updates that control in the model.
		function onCameraControlProperty(propertyVal){
			if (index !== routecamRect.selectedIndex) return;
			var id =  propertyVal[0];
			var min = propertyVal[1];
			var max = propertyVal[2];
			var current = propertyVal[3];
			var step = propertyVal[4];
			var automan = propertyVal[5];
			var enabled = propertyVal[6];
        
			// Call a function to update the cameraProperty data model
			RoutecamModelData.updateProperty( id, min, max, current, step, automan, enabled);

		}
		
		// Handles routecamOnvifController.qualityControlProperty signal: unpacks [id, min, max,
		// current] and updates that quality (encoder) control in the model.
		function onQualityControlProperty(propertyVal){
			if (index !== routecamRect.selectedIndex) return;
			var id =  propertyVal[0];
			var min = propertyVal[1];
			var max = propertyVal[2];
			var current = propertyVal[3];
        
			// Call a function to update the cameraProperty data model
			RoutecamModelData.updateQualityProperty( id, min, max, current);
		}

		// Handles routecamOnvifController.networkInterfaceDetails signal: updates DHCP mode, IP
		// address, subnet mask and gateway fields in the model.
		function onNetworkInterfaceDetails(netInterfaceDetailsList){
			if (index !== routecamRect.selectedIndex) return;
			var dhcp = netInterfaceDetailsList[0]
			var ipAddress = netInterfaceDetailsList[1]
			var subnetMask = netInterfaceDetailsList[2]
			var gateway = netInterfaceDetailsList[3]
			RoutecamModelData.updateNetworkInterfaceDetails(dhcp, ipAddress, subnetMask, gateway);
		}
		// Handles routecamOnvifController.ntpIPAddress signal: updates the NTP server IP field.
		function onNtpIPAddress(ntpIp){		
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.updateNtpIp(ntpIp);
		}

		// Handles routecamOnvifController.imagePropertiesMapChanged signal: updates the available
		// format / resolution / FPS options in the model.
		function onImagePropertiesMapChanged(propertiesMap){
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.updateImagePropertiesMap(propertiesMap)
		}

		 // Handles routecamOnvifController.currentImagePropertyChanged signal: updates the current
		 // format, resolution and FPS selections in the model.
		 function onCurrentImagePropertyChanged(format, resolution, fps){
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.updateCurrentImageProperty(format, resolution, fps)
		}

		// Handles routecamOnvifController.defaultUiValues signal: applies default values to the
		// model and emits targeted field signals so only the changed rows refresh.
		function onDefaultUiValues(values){
			var changedFields = RoutecamModelData.setUiDefaultValues(values)
			 if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i];
                
					if (change.hasOwnProperty('enabled')) {
						// Notify specific field about enabled state change
						routecamAcc.fieldChanged(change.id, change.enabled);
					}
                
					if (change.hasOwnProperty('options')) {
						// Notify specific field about options change
						routecamAcc.fieldOptionsChanged(change.id, change.options, change.selected);
					}

					 if (change.hasOwnProperty('value')) {
						// Notify specific field about options change
						routecamAcc.fieldValueChanged(change.id, change.currentValue);
					}

					//if (change.hasOwnProperty('selected')) {
						// Notify about value change for label update
						routecamAcc.fieldValueChanged(change.id, change.selected);
					//}
				}
			}
		}
	}

	// Updates the expanded flag of the item with the given label (up to 4 levels deep) and
	// adjusts the accordion height and flickable content width for the visible rows.
	function setExpandedState(label, expanded){
		var length = 0
        var indexes = findLabelIndex(routecamProperty,label)
        if(indexes.length == 1){
			var lengthChild = 0
			var lengthGrandChild =0
            routecamProperty[indexes[0]].expanded = expanded
			length = routecamProperty[indexes[0]].children.length
			
			var children = routecamProperty[indexes[0]].children
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
			var item = routecamProperty[indexes[0]].children[indexes[1]]
			item.expanded = expanded
			routecamProperty[indexes[0]].children[indexes[1]].expanded = expanded

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
            routecamProperty[indexes[0]].children[indexes[1]].children[indexes[2]].expanded = expanded
			length = routecamProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children.length
		}  else if(indexes.length == 4){
            routecamProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children[indexes[3]].expanded = expanded
			length =  routecamProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children[indexes[3]].length
		} 

		var width = 0.0805 * MonitorHandler.screenResolution.width
		var scrollWidth;
		if(expanded == true){
			heightVal += length*  0.052 * screenHeight 
			if(heightVal > routecamRect.height){
				scrollWidth = 0.183 * MonitorHandler.screenResolution.width
			} else{
				scrollWidth = 0.183 * MonitorHandler.screenResolution.width
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
			if(routecamRect.width > 0 && routecamFlickable.contentWidth < scrollWidth + width){
				routecamFlickable.contentWidth = scrollWidth + width
			}
		} else{			
			heightVal = heightVal - length * 0.052 * screenHeight 
			var count =0
			for(i =0 ; i < routecamProperty.length ; i++){
				if(routecamProperty[i]. expanded == false){
					count ++
				}
				if(count == routecamProperty.length){
					routecamFlickable.contentWidth = 0
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
    // Updates a slider value in the model (sent to the camera by Ethernet.js) and emits
    // fieldValueChanged for every dependent field, or for this field if none changed.
    function handleSliderValChanged(label, id, currentVal){
		 var changedFields = RoutecamModelData.updateSliderVal(label,id,currentVal)

		  if (changedFields && changedFields.length > 0) {
            for (var i = 0; i < changedFields.length; i++) {
                var change = changedFields[i];
				 if (change.hasOwnProperty('value')) {
                    // Notify specific field about options change
                    routecamAcc.fieldValueChanged(change.id, change.currentValue);
                }
			}
		} else{
			// Emit signal to update the parent label text
			routecamAcc.fieldValueChanged(id, currentVal);
		}

    }

	// OPTIMIZED: No full reload, only targeted updates
    // Applies a drop-down selection in the model and emits targeted accordion signals
    // (enabled / options / range / value / selected) for each field it affected.
    function handleDropBoxValChanged(label, id, value) {
        
        // Get the list of changed fields from JS
        var changedFields = RoutecamModelData.handleDropBoxValChanged(label, id, value);
        
        // Emit targeted signals for only the changed fields
        if (changedFields && changedFields.length > 0) {
            for (var i = 0; i < changedFields.length; i++) {
                var change = changedFields[i];
                
                if (change.hasOwnProperty('enabled')) {
                    // Notify specific field about enabled state change
                    routecamAcc.fieldChanged(change.id, change.enabled);
                }
                
                if (change.hasOwnProperty('options')) {
                    // Notify specific field about options change
                    routecamAcc.fieldOptionsChanged(change.id, change.options, change.selected);
                }

				if (change.hasOwnProperty('min') && change.hasOwnProperty('max')) {
					routecamAcc.fieldRangeChanged(change.id, change.min, change.max, change.currentValue);
				}

				 if (change.hasOwnProperty('value')) {
                    // Notify specific field about options change
                    routecamAcc.fieldValueChanged(change.id, change.currentValue);
                }

				if (change.hasOwnProperty('selected')) {
					// Notify about value change for label update
					routecamAcc.fieldValueChanged(change.id, change.selected);
				}
            }
        }
    }

	// Stores a checkbox state in the model and sends it to the camera through
	// routecamOnvifController.setCameraControlProperty() (via Ethernet.js).
	function handleCheckBoxValChanged(label,id,checked){
		RoutecamModelData.updateCheckBoxValue(id, checked)
	}

	// Stores edited text-box text (network settings fields) in the model; applied on Set.
	function handleTextBoxValChanged(label, id, text){
		RoutecamModelData.updateTextBoxField(label, id, text); //textbox
	}

	// Sends the NTP server address from the model to the camera (routecamOnvifController.setNTP).
	function setNTPIp(){
		RoutecamModelData.setNtp()
	}

	// Sends the quality slider values to the camera (routecamOnvifController.setQualitySettings).
	function setQParameters(){
		RoutecamModelData.setQParameters()
	}

	// Sends the selected format/resolution/FPS/profile to the camera and emits range/value
	// signals for fields changed as a result. Returns the result code from Ethernet.js.
	function setCurrentImageProperty(){
		var response = RoutecamModelData.setCurrentImageProperty();
		var changedFields = response.changedFields;
		// Emit signals for changed fields
		if (changedFields && changedFields.length > 0) {
			for (var i = 0; i < changedFields.length; i++) {
				var change = changedFields[i];

				if (change.hasOwnProperty('min') && change.hasOwnProperty('max')) {
					routecamAcc.fieldRangeChanged(change.id, change.min, change.max, change.currentValue);
				}
            
				if (change.hasOwnProperty('currentValue')) {
					// Notify specific field about value change
					routecamAcc.fieldValueChanged(change.id, change.currentValue);
				}
			}
		}
		return response.result;
	}

	// Sends DHCP mode / IP / subnet / gateway from the model to the camera
	// (routecamOnvifController.setNetworkInterfaceDetails).
	function setNetworkSettings(){
		RoutecamModelData.setNetworkSettings()
	}

	// Sends the GOP size value to the camera (routecamOnvifController.setQualitySettings).
	function setGopSize(){
		RoutecamModelData.setGopSize()
	}

	// Sends the bitrate value to the camera (routecamOnvifController.setQualitySettings).
	function setBitrate(){
		RoutecamModelData.setBitrate()
	}
}
