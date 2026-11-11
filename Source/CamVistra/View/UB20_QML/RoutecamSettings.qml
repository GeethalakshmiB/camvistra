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
		onJsonArrayRead: {
			if (index !== routecamRect.selectedIndex) return;
            routecamProperty = jsonArray;
            RoutecamModelData.updateModelData(jsonArray);           
        }
		onRoutecamOnvifInitialized: {
			// The controller now loads all properties on its worker thread.
		}

		onDeviceInformationReady: {
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.updateDeviceInformation(deviceInfo);
		}

		onRoutecamControlUnavailable: {
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.disableControl(groupId, controlId);
		}

		onRoutecamLoadingFinished: {
			if (index !== routecamRect.selectedIndex) return;
			routecamAcc.model = [];
			routecamProperty = RoutecamModelData.getRoutecamModelData();
			routecamAcc.model = routecamProperty;
			logController.readControlJsonTooltipArrayFile();
		}

		onCameraControlProperty: {
			if (index !== routecamRect.selectedIndex) return;
			var id =  propList[0];
			var min = propList[1];
			var max = propList[2];
			var current = propList[3];
			var step = propList[4];
			var automan = propList[5];
			var enabled = propList[6];
        
			// Call a function to update the cameraProperty data model
			RoutecamModelData.updateProperty( id, min, max, current, step, automan, enabled);

		}
		
		onQualityControlProperty: {
			if (index !== routecamRect.selectedIndex) return;
			var id =  propList[0];
			var min = propList[1];
			var max = propList[2];
			var current = propList[3];
        
			// Call a function to update the cameraProperty data model
			RoutecamModelData.updateQualityProperty( id, min, max, current);
		}

		onNetworkInterfaceDetails: {
			if (index !== routecamRect.selectedIndex) return;
			var dhcp = netInterfaceDetailsList[0]
			var ipAddress = netInterfaceDetailsList[1]
			var subnetMask = netInterfaceDetailsList[2]
			var gateway = netInterfaceDetailsList[3]
			RoutecamModelData.updateNetworkInterfaceDetails(dhcp, ipAddress, subnetMask, gateway);
		}
		onNtpIPAddress: {		
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.updateNtpIp(ntpIp);
		}

		onImagePropertiesMapChanged: {
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.updateImagePropertiesMap(propertiesMap)
		}

		 onCurrentImagePropertyChanged: {
			if (index !== routecamRect.selectedIndex) return;
			RoutecamModelData.updateCurrentImageProperty(format, resolution, fps)
		}

		onDefaultUiValues: {
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

	// Expands/collapses the accordion node with the given label (found via
	// findLabelIndex), counts the visible child rows it adds/removes, adjusts
	// heightVal and grows or resets the flickable contentWidth accordingly.
	// For a level-2 node, also notifies logController.expandedItem() for each
	// expanded child.
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

    // Updates a slider value in RoutecamModelData; emits fieldValueChanged for
    // every dependent field it reports changed, or for the slider itself if
    // nothing else changed.
	//Function for value update in the Slider   
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

    // Applies a drop-down selection via RoutecamModelData and emits targeted
    // routecamAcc signals (enabled/options/range/value) for only the fields it
    // reports changed.
	// OPTIMIZED: No full reload, only targeted updates
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

	function handleCheckBoxValChanged(label,id,checked){
		RoutecamModelData.updateCheckBoxValue(id, checked)
	}

	function handleTextBoxValChanged(label, id, text){
		RoutecamModelData.updateTextBoxField(label, id, text); //textbox
	}

	function setNTPIp(){
		RoutecamModelData.setNtp()
	}

	function setQParameters(){
		RoutecamModelData.setQParameters()
	}

	// Pushes the current image properties to the camera via RoutecamModelData,
	// emits range/value updates for the changed fields and returns the result.
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

	function setNetworkSettings(){
		RoutecamModelData.setNetworkSettings()
	}

	function setGopSize(){
		RoutecamModelData.setGopSize()
	}

	function setBitrate(){
		RoutecamModelData.setBitrate()
	}
}
